import os, json, uuid, subprocess, time
from pathlib import Path
from app.core.config import settings
from .storage import write_text


def convert_txt_to_json(txt_path: Path, json_path: Path):
    """
    Convierte .out.txt a JSON {'S': matriz}:
    - Extrae enteros por línea (ignora cabeceras).
    - Detecta bloque rectangular dominante (misma cantidad de columnas).
    - Para cada fila: recorta ceros a la izquierda y re-alinea de modo que
      el primer valor de esa fila quede en la columna i (triángulo superior).
    """
    import re
    from collections import Counter

    if not txt_path.exists():
        raise FileNotFoundError(txt_path)

    num_re = re.compile(r"-?\d+")
    rows = []
    with txt_path.open() as f:
        for raw in f:
            nums = [int(m.group()) for m in num_re.finditer(raw)]
            if nums:
                rows.append(nums)

    if not rows:
        raise RuntimeError(f"{txt_path} no contiene números.")

    # Toma el bloque rectangular más frecuente (evita cabeceras/filas atípicas)
    lens = [len(r) for r in rows if len(r) >= 2]
    if not lens:
        raise RuntimeError("No hay filas numéricas válidas (>=2 columnas).")
    mode_len, _ = Counter(lens).most_common(1)[0]
    block = [r for r in rows if len(r) == mode_len]
    if not block:
        ncols = max(len(r) for r in rows)
        block = [r + [0] * (ncols - len(r)) for r in rows]
        mode_len = ncols

    # n = min(#filas, #cols)
    n_rows = len(block)
    n = min(n_rows, mode_len)
    if n_rows < n:
        block += [[0] * mode_len for _ in range(n - n_rows)]

    # Construye matriz n×n y re-alinea cada fila:
    #  - recorta ceros a la izquierda
    #  - coloca trimmed[j] en S[i][i+j]
    S = [[0 for _ in range(n)] for _ in range(n)]
    for i in range(n):
        r = block[i]
        k = 0
        while k < len(r) and r[k] == 0:
            k += 1
        trimmed = r[k:]
        m = min(len(trimmed), n - i)
        for j in range(m):
            S[i][i + j] = trimmed[j]

    json_path.write_text(json.dumps({"S": S}))


def run_nuss3d(seq_text: str, method: str, threads: int):
    job_id = str(uuid.uuid4())
    job_dir = settings.JOBS_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=True)

    fasta = job_dir / "input.fasta"
    write_text(fasta, f">job\n{seq_text}\n")

    env = os.environ.copy()
    env["OMP_NUM_THREADS"] = str(threads)
    cmd = [str(settings.NUSS_BIN), str(fasta), method, str(threads)]

    t0 = time.perf_counter()
    cp = subprocess.run(
        cmd, cwd=job_dir, env=env,
        capture_output=True, text=True, timeout=600
    )
    t1 = time.perf_counter()
    elapsed_ms = round((t1 - t0) * 1000, 3)

    # Detecta salida .out.txt generada por tu binario
    out_txt: Path | None = None
    candidates = list(job_dir.glob("*.out.txt"))
    if candidates:
        out_txt = candidates[0]

    if not out_txt:
        # Fallback: guarda stdout para depurar
        (job_dir / "stdout.txt").write_text(cp.stdout)
        raise RuntimeError("No se encontró *.out.txt en " + str(job_dir))

    # Convierte a JSON usable por el front
    S_json = job_dir / "S.json"
    convert_txt_to_json(out_txt, S_json)

    meta = {
        "stdout": cp.stdout,
        "stderr": cp.stderr,
        "returncode": cp.returncode,
        "method": method,
        "threads": threads,
        "out_file": str(out_txt),
        "time_ms": elapsed_ms,
    }
    (job_dir / "meta.json").write_text(json.dumps(meta))

    return {
        "job_id": job_id,
        "files": {"json": str(S_json)},
        "meta": meta,
    }
