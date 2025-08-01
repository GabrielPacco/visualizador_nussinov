# Visor web comparativo — Nussinov 3‑D Tiled (Monorepo)

Aplicación web para **ejecutar y visualizar** el algoritmo de Nussinov (plegado de ARN) en variantes **serial** y **paralelas** (`tstile`, `tilecorr`, `pluto`, `3D`). Permite comparar matrices **S**, ver **speed‑up**, elegir **escala de color** y **exportar CSV/JSON**.

## ✨ Características
- Métodos: `oryg` (serial), `tstile`, `tilecorr`, `pluto`, `3D`.
- Heatmap interactivo (triángulo superior) con escalas: `seq`, `div0`, `log`, `p98`.
- Comparación lado a lado (serial vs método) y **speed‑up**.
- Inspector por celda (`i, j, S[i,j]`) y exportación **CSV/JSON**.
- Datasets demo y generación de secuencias sintéticas para benchmark.

## 🧱 Estructura
```
backend/   # FastAPI + invocación binario C++
  app/     # API, servicios, runtime/jobs (ignorado en git)
  nuss3d/  # src/ (C++), build/
frontend/  # Vue 3 + Vite
  src/     # api/, components/, App.vue, types.ts
```

## ⚙️ Requisitos
- Linux, Python 3.10+, Node.js 18+, g++/clang++
- (Opcional) `jq` para depuración

## 🚀 Puesta en marcha

### Backend
```bash
cd backend
make init                 # crea venv e instala dependencias
# copia tu C++ a backend/nuss3d/src (main.cpp, headers…)
make build                # compila nuss3d en nuss3d/build/nuss3d
make run                  # API en http://localhost:8000
```
Variables (ver `backend/.env.example`):
```
NUSS_BIN=backend/nuss3d/build/nuss3d
JOBS_DIR=backend/app/runtime/jobs
CORS_ORIGINS=http://localhost:5173
```

### Frontend
```bash
cd frontend
npm install
# cp .env.example .env   (VITE_API_BASE=http://localhost:8000)
npm run dev              # http://localhost:5173
```

## 🧭 API mínima
- `GET /api/v1/health` → `{"status":"ok"}`
- `POST /api/v1/fold`  → ejecuta método y devuelve `{ job_id, meta }`
- `GET /api/v1/result/{job_id}` → `{ "S": number[][] }`

Ejemplo:
```bash
SEQ=$(awk 'FNR>1{printf "%s",$0}' tRNA_demo.fasta)
curl -s -X POST http://localhost:8000/api/v1/fold \
  -H 'Content-Type: application/json' \
  -d "{\"sequence\":\"$SEQ\",\"method\":\"3D\",\"threads\":4}"
```

## 🧪 Datasets demo
`tRNA_demo.fasta`:
```
>tRNA_demo
GCGGAUUUAGCUCAGUUGGGAGAGCGCCAGACUGAAGAUCUGGAGGUCCUGUGUUCGAUCCACAGAAUUCGCACCA
```
Sintéticos (300/800 nt):
```bash
python3 - << 'PY'
import random; comp={'A':'U','U':'A','C':'G','G':'C'}
r=lambda n: ''.join(random.choice('ACGU') for _ in range(n))
rc=lambda s: ''.join(comp[b] for b in s[::-1])
def mk(n,sp,name):
  core=r(n); seq=core+'A'*sp+rc(core)
  open(f"{name}.fasta","w").write(f">{name}\n"+'\n'.join(seq[i:i+60] for i in range(0,len(seq),60))+"\n")
mk(140,20,"rna_palindrome_300"); mk(390,20,"rna_palindrome_800")
PY
```

## 🖥️ Uso del visor
1. Abrir `http://localhost:5173`.
2. Cargar/pastear secuencia o usar “Datasets demo”.
3. Elegir método e hilos → **Ejecutar**.
4. **Comparar vs serial** para ver speed‑up.
5. Cambiar **escala** si necesitas más contraste.
6. Exportar **CSV/JSON** desde “Resultados”.

