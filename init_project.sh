#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

echo "[1/8] Estructura backend…"
mkdir -p backend/{app/{api/v1/endpoints,core,models,schemas,services,runtime/{jobs,cache}},nuss3d/{src,build},scripts}

cat > backend/requirements.txt <<'EOF'
fastapi
uvicorn[standard]
pydantic
numpy
python-multipart
EOF

cat > backend/Makefile <<'EOF'
PY=python3
VENV=.venv

init:
	$(PY) -m venv $(VENV)
	./$(VENV)/bin/pip install -U pip -r requirements.txt
	chmod +x scripts/*.sh

build:
	bash scripts/build_nuss3d.sh

run:
	./$(VENV)/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	bash scripts/smoke_tests.sh || true
EOF

cat > backend/scripts/build_nuss3d.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(dirname "$0")/.."
SRC="$ROOT/nuss3d/src"
BUILD="$ROOT/nuss3d/build"
mkdir -p "$BUILD"
cd "$BUILD"

if [[ ! -f "$SRC/main.cpp" ]]; then
  echo ">> Copia tu código C++ en backend/nuss3d/src (main.cpp, headers, etc.)"
  exit 1
fi

if ldconfig -p 2>/dev/null | grep -qi tbb; then
  echo "[*] Compilando con TBB + OpenMP"
  g++ -O3 -march=native -fopenmp "$SRC/main.cpp" -ltbb -o nuss3d
else
  echo "[*] Compilando con OpenMP (sin TBB)"
  g++ -O3 -march=native -fopenmp "$SRC/main.cpp" -o nuss3d
fi

echo "[OK] Binario en $BUILD/nuss3d"
EOF
chmod +x backend/scripts/build_nuss3d.sh

cat > backend/scripts/smoke_tests.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BIN="backend/nuss3d/build/nuss3d"
[[ -x "$BIN" ]] || { echo "No existe $BIN. Ejecuta: make build"; exit 1; }
echo "> Smoke test serial"
$BIN backend/nuss3d/src/sequences/AY335714.1 oryg 1 || true
echo "> Smoke test 3D"
$BIN backend/nuss3d/src/sequences/AY335714.1 3D 8 || true
EOF
chmod +x backend/scripts/smoke_tests.sh

echo "[2/8] Backend: config y core…"
cat > backend/app/core/config.py <<'EOF'
from pathlib import Path
from pydantic import BaseSettings

class Settings(BaseSettings):
    PROJECT_ROOT: Path = Path(__file__).resolve().parents[2]
    BIN_DIR: Path = PROJECT_ROOT / "nuss3d" / "build"
    NUSS_BIN: Path = BIN_DIR / "nuss3d"
    RUNTIME_DIR: Path = PROJECT_ROOT / "app" / "runtime"
    JOBS_DIR: Path = RUNTIME_DIR / "jobs"
    CACHE_DIR: Path = RUNTIME_DIR / "cache"
    MAX_N: int = 6000
    ALLOWED_METHODS = ("oryg", "tstile", "tilecorr", "pluto", "3D")
    CORS_ORIGINS = ["http://localhost:5173"]

settings = Settings()
EOF

cat > backend/app/main.py <<'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.router import api_router

app = FastAPI(title="Nussinov 3D Tiled API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/v1/health")
def health():
    return {"status": "ok"}

app.include_router(api_router, prefix="/api/v1")
EOF

cat > backend/app/api/v1/router.py <<'EOF'
from fastapi import APIRouter
from .endpoints.fold import router as fold_router
from .endpoints.health import router as health_router

api_router = APIRouter()
api_router.include_router(health_router, prefix="", tags=["health"])
api_router.include_router(fold_router, prefix="/fold", tags=["fold"])
EOF

cat > backend/app/api/v1/endpoints/health.py <<'EOF'
from fastapi import APIRouter
router = APIRouter()

@router.get("/ping")
def ping():
    return {"pong": True}
EOF

cat > backend/app/schemas/fold.py <<'EOF'
from pydantic import BaseModel, Field
from typing import Literal

Method = Literal["oryg", "tstile", "tilecorr", "pluto", "3D"]

class FoldRequest(BaseModel):
    sequence: str = Field(..., min_length=10)
    method: Method
    threads: int = Field(ge=1, le=64)

class FoldResponse(BaseModel):
    job_id: str
    method: Method
    threads: int
    files: dict
    meta: dict
EOF

cat > backend/app/services/storage.py <<'EOF'
from pathlib import Path
import hashlib

def write_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

def calc_hash(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest()
EOF

cat > backend/app/services/nuss3d.py <<'EOF'
import os, json, uuid, subprocess
from pathlib import Path
from app.core.config import settings
from .storage import write_text

def convert_txt_to_json(txt_path: Path, json_path: Path):
    # Convierte una matriz triangular/tabla plana a JSON 2D simple (placeholder)
    if not txt_path.exists():
        raise FileNotFoundError(txt_path)
    rows = []
    with txt_path.open() as f:
        for line in f:
            line=line.strip()
            if not line: continue
            parts = [int(x) for x in line.split()]
            rows.append(parts)
    json_path.write_text(json.dumps({"S": rows}))

def run_nuss3d(seq_text: str, method: str, threads: int):
    job_id = str(uuid.uuid4())
    job_dir = settings.JOBS_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=True)

    fasta = job_dir / "input.fasta"
    write_text(fasta, f">job\n{seq_text}\n")

    env = os.environ.copy()
    env["OMP_NUM_THREADS"] = str(threads)
    cmd = [str(settings.NUSS_BIN), str(fasta), method, str(threads)]
    cp = subprocess.run(cmd, cwd=job_dir, env=env, capture_output=True, text=True, timeout=600)

    # Detecta salida .out.txt generada por tu binario (ajusta patrón si difiere)
    out_txt = None
    for p in job_dir.glob("*.out.txt"):
        out_txt = p; break
    if not out_txt:
        # como fallback, guarda stdout
        (job_dir / "stdout.txt").write_text(cp.stdout)
        raise RuntimeError("No se encontró *.out.txt en " + str(job_dir))

    S_json = job_dir / "S.json"
    convert_txt_to_json(out_txt, S_json)

    meta = {
        "stdout": cp.stdout, "stderr": cp.stderr,
        "returncode": cp.returncode,
        "method": method, "threads": threads
    }
    (job_dir / "meta.json").write_text(json.dumps(meta))
    return {"job_id": job_id, "files": {"json": str(S_json)}, "meta": meta}
EOF

cat > backend/app/api/v1/endpoints/fold.py <<'EOF'
from fastapi import APIRouter, HTTPException
from app.schemas.fold import FoldRequest, FoldResponse
from app.core.config import settings
from app.services.nuss3d import run_nuss3d

router = APIRouter()

@router.post("", response_model=FoldResponse)
def fold(req: FoldRequest):
    seq = req.sequence.replace("\n", "").replace("\r","").upper()
    if len(seq) > settings.MAX_N:
        raise HTTPException(status_code=400, detail=f"Secuencia demasiado larga (>{settings.MAX_N}) para demo.")
    if req.method not in settings.ALLOWED_METHODS:
        raise HTTPException(status_code=400, detail="Método no permitido.")
    result = run_nuss3d(seq, req.method, req.threads)
    return FoldResponse(job_id=result["job_id"], method=req.method, threads=req.threads,
                        files=result["files"], meta=result["meta"])
EOF

echo "[3/8] .gitignore y README…"
cat > .gitignore <<'EOF'
# Python
backend/.venv/
__pycache__/
*.pyc

# Node
frontend/node_modules/
frontend/dist/

# Builds
backend/nuss3d/build/
backend/app/runtime/jobs/
backend/app/runtime/cache/

# OS
.DS_Store
EOF

cat > README.md <<'EOF'
# Visor Nussinov 3D Tiled — Monorepo

## Backend
```bash
cd backend
make init
# copia tu código C++ a backend/nuss3d/src/
make build
make run
# API en http://localhost:8000/api/v1
