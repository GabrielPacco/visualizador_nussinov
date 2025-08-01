#!/usr/bin/env bash
set -euo pipefail
BIN="backend/nuss3d/build/nuss3d"
[[ -x "$BIN" ]] || { echo "No existe $BIN. Ejecuta: make build"; exit 1; }
echo "> Smoke test serial"
$BIN backend/nuss3d/src/sequences/AY335714.1 oryg 1 || true
echo "> Smoke test 3D"
$BIN backend/nuss3d/src/sequences/AY335714.1 3D 8 || true
