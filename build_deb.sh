#!/bin/bash
set -e

APP_BIN="fiscogest_rd"        # nombre del binario (name: en pubspec.yaml)
PKG="fiscogest-rd"             # nombre del paquete (minusculas, sin guion bajo)
VERSION="1.0.0"                # cambia esto con cada release
ARCH="amd64"
BUNDLE="build/linux/x64/release/bundle"
STAGING="build/deb/${PKG}_${VERSION}_${ARCH}"

echo "==> Limpiando y creando estructura..."
rm -rf build/deb
mkdir -p "$STAGING/DEBIAN"
mkdir -p "$STAGING/opt/$PKG"
mkdir -p "$STAGING/usr/bin"
mkdir -p "$STAGING/usr/share/applications"
mkdir -p "$STAGING/usr/share/pixmaps"

echo "==> Copiando binarios..."
cp -r "$BUNDLE/"* "$STAGING/opt/$PKG/"

echo "==> Creando lanzador en /usr/bin..."
cat > "$STAGING/usr/bin/$PKG" << LAUNCHER
#!/bin/bash
exec /opt/$PKG/$APP_BIN "\$@"
LAUNCHER
chmod 755 "$STAGING/usr/bin/$PKG"

echo "==> Creando acceso directo (menu)..."
cat > "$STAGING/usr/share/applications/$PKG.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=FiscoGest RD
Comment=Sistema de gestion fiscal
Exec=/usr/bin/$PKG
Icon=$PKG
Terminal=false
Categories=Office;Finance;
DESKTOP
chmod 644 "$STAGING/usr/share/applications/$PKG.desktop"

echo "==> Icono (usa assets/icon.png si existe)..."
if [ -f "assets/icon.png" ]; then
  cp assets/icon.png "$STAGING/usr/share/pixmaps/$PKG.png"
else
  echo "    (no se encontro assets/icon.png — el menu se vera sin icono)"
fi

echo "==> Archivo control del paquete..."
cat > "$STAGING/DEBIAN/control" << CONTROL
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, liblzma5, libgstreamer1.0-0
Maintainer: Martin <tu@email.com>
Description: FiscoGest RD - Sistema de gestion fiscal
 Aplicacion de gestion y facturacion para negocios en Republica Dominicana.
CONTROL
chmod 644 "$STAGING/DEBIAN/control"
chmod 755 "$STAGING/DEBIAN"

echo "==> Construyendo .deb..."
dpkg-deb --build "$STAGING" "build/${PKG}_${VERSION}_${ARCH}.deb"

echo ""
echo "✅ Listo: build/${PKG}_${VERSION}_${ARCH}.deb"
echo "   Instalar:  sudo dpkg -i build/${PKG}_${VERSION}_${ARCH}.deb"
echo "   Desinstalar: sudo apt remove $PKG"
