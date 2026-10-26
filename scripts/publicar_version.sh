#!/usr/bin/env bash
# Publicador seguro de versiones de FiscoGest.
# Publica el APK antes de actualizar update.json.

set -Eeuo pipefail
cd "$(dirname "$0")/.."

REPO="vmarttech/fiscogest_rd"
BRANCH="main"
UPDATE_FILE="update.json"
PUBSPEC="pubspec.yaml"
SCRIPT="scripts/publicar_version.sh"
APK="build/app/outputs/flutter-apk/app-release.apk"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/update.json"

fail() {
  echo
  echo "ERROR: $*" >&2
  echo "No se continuará con la publicación." >&2
  exit 1
}

command -v git >/dev/null || fail "Git no está instalado."
command -v flutter >/dev/null || fail "Flutter no está instalado."
command -v gh >/dev/null || fail "GitHub CLI (gh) no está instalado."
gh auth status >/dev/null 2>&1 || fail "Inicia sesión con gh auth login."

BRANCH_NOW=$(git branch --show-current)
[[ "$BRANCH_NOW" == "$BRANCH" ]] ||
  fail "Estás en la rama '$BRANCH_NOW', no en '$BRANCH'."

git diff --cached --quiet ||
  fail "Hay cambios preparados en Git. Revísalos antes de publicar."

# Permite que este propio script esté modificado, pero no otros archivos.
while IFS= read -r linea; do
  [[ -z "$linea" ]] && continue
  ruta="${linea:3}"
  ruta="${ruta#\"}"
  ruta="${ruta%\"}"

  [[ "$ruta" == "$SCRIPT" ]] && continue
  fail "Hay cambios ajenos pendientes en: $ruta. No se publicará hasta resolverlos."
done < <(git status --porcelain --untracked-files=all)

git fetch origin "$BRANCH" ||
  fail "No se pudo consultar GitHub."

LOCAL_HEAD=$(git rev-parse HEAD)
REMOTE_HEAD=$(git rev-parse "origin/$BRANCH")

[[ "$LOCAL_HEAD" == "$REMOTE_HEAD" ]] ||
  fail "La rama local y GitHub no están sincronizados. Revisa Git antes de publicar."

command -v python3 >/dev/null ||
  fail "Python 3 es necesario para validar update.json."

CURRENT=$(python3 -c '
import re
from pathlib import Path
s = Path("pubspec.yaml").read_text()
m = re.search(r"(?m)^version:\s*(\S+)", s)
if not m:
    raise SystemExit("No se encontró version en pubspec.yaml")
print(m.group(1))
') || fail "No se pudo leer la versión del proyecto."

if [[ "$CURRENT" != *"+"* ]]; then
  fail "La versión debe tener formato nombre+código, por ejemplo 3.0.6+8."
fi

CURRENT_NAME="${CURRENT%%+*}"
CURRENT_CODE="${CURRENT##*+}"

[[ "$CURRENT_CODE" =~ ^[0-9]+$ ]] ||
  fail "El código de versión no es numérico."

MANIFEST_CODE=$(python3 -c '
import json
from pathlib import Path
d = json.loads(Path("update.json").read_text())
print(int(d["versionCode"]))
') || fail "No se pudo leer update.json."

# Si pubspec ya avanzó pero update.json no, se retoma esa publicación.
if (( MANIFEST_CODE < CURRENT_CODE )); then
  NAME="$CURRENT_NAME"
  NEW_CODE="$CURRENT_CODE"
  echo "Se detectó una publicación pendiente: ${NAME}+${NEW_CODE}"
else
  (( MANIFEST_CODE == CURRENT_CODE )) ||
    fail "El código de update.json no coincide con pubspec.yaml."

  NAME="${1:-$CURRENT_NAME}"
  [[ "$NAME" =~ ^[0-9]+(\.[0-9]+){1,3}$ ]] ||
    fail "Nombre de versión inválido: $NAME"

  NEW_CODE=$((CURRENT_CODE + 1))
fi

NEW_VERSION="${NAME}+${NEW_CODE}"
TAG="v${NAME}"
APK_URL="https://github.com/${REPO}/releases/download/${TAG}/app-release.apk"

echo
echo "Versión actual del proyecto : $CURRENT"
echo "Versión que se publicará    : $NEW_VERSION"
echo "Etiqueta de GitHub          : $TAG"
echo "Enlace de descarga          : $APK_URL"
echo
read -r -p "¿Continuar? (s/N) " OK
[[ "$OK" == "s" || "$OK" == "S" ]] || {
  echo "Cancelado. No se publicó ninguna versión."
  exit 0
}

# Conserva una copia para restaurar pubspec si falla la compilación.
BACKUP=$(mktemp)
cp "$PUBSPEC" "$BACKUP"
PUBSPEC_COMMITTED=0

cleanup() {
  if (( PUBSPEC_COMMITTED == 0 )); then
    cp "$BACKUP" "$PUBSPEC"
  fi
  rm -f "$BACKUP"
}
trap cleanup EXIT

if [[ "$CURRENT" != "$NEW_VERSION" ]]; then
  sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
fi

echo
echo "Compilando APK de producción..."

flutter build apk --release \
  --dart-define=STORE=direct \
  --dart-define="PAYPAL_CLIENT_ID=${PAYPAL_CLIENT_ID:?Define PAYPAL_CLIENT_ID antes de publicar}" \
  --dart-define="PAYPAL_SECRET=${PAYPAL_SECRET:?Define PAYPAL_SECRET antes de publicar}" \
  --dart-define="PAYPAL_SANDBOX=${PAYPAL_SANDBOX:-true}" ||
  fail "Falló la compilación del APK."

[[ -s "$APK" ]] || fail "No se generó un APK válido."

# Publica primero el código de versión, para que el tag apunte al código
# que contiene esa versión. update.json todavía no anuncia la actualización.
if [[ "$CURRENT" != "$NEW_VERSION" ]]; then
  git add -- "$PUBSPEC"
  git commit -m "Preparar versión ${NEW_VERSION}" ||
    fail "No se pudo registrar la versión del proyecto."

  PUBSPEC_COMMITTED=1

  git push origin "$BRANCH" ||
    fail "No se pudo subir el commit de versión. Revisa Git antes de reintentar."
fi

# Sube el APK antes de anunciarlo a las aplicaciones instaladas.
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "$APK" --repo "$REPO" --clobber ||
    fail "No se pudo subir el APK a la publicación existente."
else
  gh release create "$TAG" "$APK" \
    --repo "$REPO" \
    --title "FiscoGest RD ${NAME}" \
    --notes "Versión ${NAME} (build ${NEW_CODE})." ||
    fail "No se pudo crear la publicación de GitHub."
fi

echo
echo "Verificando que GitHub tenga el APK publicado..."
gh release view "$TAG" --repo "$REPO" --json assets |
python3 -c '
import json, sys
d = json.load(sys.stdin)
assert any(a.get("name") == "app-release.apk" and
           a.get("state") == "uploaded" for a in d.get("assets", [])), \
       "GitHub no confirma el APK"
' || fail "GitHub no confirma que el APK esté disponible."

# Solo después de publicar el APK se actualiza el manifiesto.
python3 - "$UPDATE_FILE" "$NAME" "$NEW_CODE" "$APK_URL" <<'PY'
import json
import sys
from pathlib import Path

ruta, nombre, codigo, apk_url = sys.argv[1:]
datos = {
    "versionName": nombre,
    "versionCode": int(codigo),
    "apkUrl": apk_url,
    "changelog": f"Actualización {nombre} (build {codigo}).",
    "forceUpdate": False,
}
Path(ruta).write_text(json.dumps(datos, indent=2, ensure_ascii=False) + "\n")
PY

git add -- "$UPDATE_FILE"
git commit -m "Publicar actualización ${NEW_VERSION}" ||
  fail "No se pudo registrar update.json."

git push origin "$BRANCH" ||
  fail "No se pudo subir update.json. Revisa Git antes de reintentar."

echo
echo "PUBLICACIÓN COMPLETADA"
echo "Versión: ${NEW_VERSION}"
echo "APK: $APK_URL"
echo "Manifiesto: $BASE_URL"
echo
