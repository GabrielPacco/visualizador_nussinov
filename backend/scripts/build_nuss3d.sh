#!/usr/bin/env bash
set -euo pipefail

# Rutas absolutas robustas
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
ROOT="$(realpath "$SCRIPT_DIR/..")"
SRC="$ROOT/nuss3d/src"
BUILD="$ROOT/nuss3d/build"

mkdir -p "$BUILD"

echo "[i] SRC  = $SRC"
echo "[i] BUILD= $BUILD"

# ¿Hay fuentes .cpp?
shopt -s nullglob
SRCS=( "$SRC"/*.cpp )
shopt -u nullglob

if (( ${#SRCS[@]} == 0 )); then
  echo "[i] No se encontraron .cpp en $SRC"
  # Si ya tienes un binario en src/, lo copiamos a build/
  if [[ -x "$SRC/nuss3d" ]]; then
    cp "$SRC/nuss3d" "$BUILD/nuss3d"
    echo "[OK] Copiado binario existente a $BUILD/nuss3d"
    exit 0
  else
    echo "ERROR: no hay fuentes .cpp ni binario 'nuss3d' en $SRC"
    exit 1
  fi
fi

# Compilar todos los .cpp
echo "[*] Compilando: ${SRCS[*]}"
if ldconfig -p 2>/dev/null | grep -qi tbb; then
  echo "[*] OpenMP + TBB"
  g++ -O3 -march=native -fopenmp "${SRCS[@]}" -ltbb -o "$BUILD/nuss3d"
else
  echo "[*] Solo OpenMP"
  g++ -O3 -march=native -fopenmp "${SRCS[@]}" -o "$BUILD/nuss3d"
fi

echo "[OK] Binario listo: $BUILD/nuss3d"
