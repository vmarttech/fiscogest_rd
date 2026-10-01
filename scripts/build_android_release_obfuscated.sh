#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   FISCO_SYMBOLS_DIR=/ruta/privada/fiscogest-symbols \
#     ./scripts/build_android_release_obfuscated.sh appbundle
#   FISCO_SYMBOLS_DIR=/ruta/privada/fiscogest-symbols \
#     ./scripts/build_android_release_obfuscated.sh apk
# Mantén los símbolos en una ubicación privada y fuera del repositorio.

TARGET="${1:-appbundle}"
case "$TARGET" in
  appbundle|apk) ;;
  *) echo "Uso: $0 [appbundle|apk]" >&2; exit 2 ;;
esac

if [[ -z "${FISCO_SYMBOLS_DIR:-}" ]]; then
  echo "Define FISCO_SYMBOLS_DIR con una ruta privada fuera del repositorio." >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SYMBOLS_DIR="$(mkdir -p "$FISCO_SYMBOLS_DIR" && cd "$FISCO_SYMBOLS_DIR" && pwd -P)"
case "$SYMBOLS_DIR/" in
  "$REPO_ROOT/"|"$REPO_ROOT/"*)
    echo "FISCO_SYMBOLS_DIR debe estar fuera del repositorio." >&2
    exit 2
    ;;
esac

cd "$REPO_ROOT"
flutter build "$TARGET" --release \
  --obfuscate \
  --split-debug-info="$SYMBOLS_DIR"
