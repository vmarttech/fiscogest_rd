#!/usr/bin/env bash
# ============================================================
# Publicar actualización de FiscoGest RD
# Uso simple:
#   ./scripts/publicar_version.sh
#   ./scripts/publicar_version.sh 3.0.1
#
# LO ÚNICO QUE PUEDES CAMBIAR (opcional):
#   el número de versión al final del comando (ej. 3.0.1)
# Todo lo demás es automático.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")/.."

NAME_ARG="${1:-}"

CURRENT=$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')
NAME="${CURRENT%%+*}"
CODE="${CURRENT##*+}"

if [[ -n "$NAME_ARG" ]]; then
  NAME="$NAME_ARG"
fi

NEW_CODE=$((CODE + 1))
NEW_VERSION="${NAME}+${NEW_CODE}"
TAG="v${NAME}"

echo ""
echo "  Versión actual : $CURRENT"
echo "  Nueva versión  : $NEW_VERSION"
echo "  Tag GitHub     : $TAG"
echo ""
read -r -p "  ¿Publicar? (s/N) " OK
[[ "$OK" == "s" || "$OK" == "S" ]] || { echo "  Cancelado."; exit 0; }

# 1) pubspec
sed -i "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml

# 2) APK — MISMA ruta que usas tú (STORE=direct)
echo ""
echo "  Compilando APK (STORE=direct)..."
flutter build apk --release \
  --dart-define=STORE=direct \
  --dart-define=PAYPAL_CLIENT_ID="${PAYPAL_CLIENT_ID:?Define PAYPAL_CLIENT_ID antes de publicar}" \
  --dart-define=PAYPAL_SECRET="${PAYPAL_SECRET:?Define PAYPAL_SECRET antes de publicar}" \
  --dart-define=PAYPAL_SANDBOX="${PAYPAL_SANDBOX:-true}"

APK="build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$APK" ]] || { echo "  ERROR: no se generó el APK"; exit 1; }

# 3) update.json (la app lo lee al abrir)
APK_URL="https://github.com/vmarttech/fiscogest_rd/releases/download/${TAG}/app-release.apk"
cat > update.json << JSON
{
  "versionName": "${NAME}",
  "versionCode": ${NEW_CODE},
  "apkUrl": "${APK_URL}",
  "changelog": "Actualización ${NAME} (build ${NEW_CODE}).",
  "forceUpdate": false
}
JSON

# 4) git (código + json)
git add pubspec.yaml update.json
git commit -m "Release ${NEW_VERSION}" || true
git push origin main

# 5) Release en GitHub con el APK
if gh release view "$TAG" &>/dev/null; then
  gh release upload "$TAG" "$APK" --clobber
else
  gh release create "$TAG" "$APK" \
    --title "FiscoGest RD ${NAME}" \
    --notes "Versión ${NAME} (build ${NEW_CODE})."
fi

echo ""
echo "  LISTO"
echo "  Descarga: $APK_URL"
echo "  JSON:     https://raw.githubusercontent.com/vmarttech/fiscogest_rd/main/update.json"
echo ""
