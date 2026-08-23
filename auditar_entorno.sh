#!/bin/bash
set -e

echo "=================================================="
echo "           AUDITORÍA DEL ÁREA DE VENTAS           "
echo "=================================================="
echo ""

RUTA_BASE="lib/features/ventas"

echo "--- [1] INTERFAZ DE REPOSITORIO ---"
if [ -f "$RUTA_BASE/domain/repositories/i_ventas_repository.dart" ]; then
  echo "✅ Archivo existe: $RUTA_BASE/domain/repositories/i_ventas_repository.dart"
  echo "   Firmas declaradas:"
  grep -E "Future.*\(.*\)" "$RUTA_BASE/domain/repositories/i_ventas_repository.dart" | sed 's/^/   /'
else
  echo "❌ NO EXISTE: $RUTA_BASE/domain/repositories/i_ventas_repository.dart"
fi
echo ""

echo "--- [2] IMPLEMENTACIÓN DEL REPOSITORIO ---"
if [ -f "$RUTA_BASE/data/repositories/ventas_repository_impl.dart" ]; then
  echo "✅ Archivo existe"
  echo "   Firmas implementadas:"
  grep -E "override.*Future" "$RUTA_BASE/data/repositories/ventas_repository_impl.dart" | sed 's/^/   /'
  echo ""
  echo "   Métodos declarados en clase:"
  grep -E "  Future" "$RUTA_BASE/data/repositories/ventas_repository_impl.dart" | sed 's/^/   /'
else
  echo "❌ NO EXISTE"
fi
echo ""

echo "--- [3] DAO DE VENTAS ---"
RUTA_DAO="lib/features/comercial/data/dao/ventas_dao.dart"
if [ -f "$RUTA_DAO" ]; then
  echo "✅ Archivo existe: $RUTA_DAO"
  echo "   Métodos del DAO:"
  grep -E "Future " "$RUTA_DAO" | sed 's/^/   /'
  echo ""
  echo "   Campos de VentaData / tabla:"
  grep -E "final.*\w+.*\??;" "$RUTA_DAO" 2>/dev/null || grep -E "VentaData\b" "$RUTA_DAO" -A 50 | grep "final" | sed 's/^/   /' || echo "   (Revisando estructura toJson/fromJson...)"
else
  echo "❌ NO EXISTE"
fi
echo ""

echo "--- [4] ENTIDAD VENTA ---"
if [ -f "$RUTA_BASE/domain/entities/venta.dart" ]; then
  echo "✅ Archivo existe"
  echo "   Propiedades de la entidad:"
  grep -E "  (final|Venta\()" "$RUTA_BASE/domain/entities/venta.dart" | sed 's/^/   /'
else
  echo "❌ NO EXISTE"
fi
echo ""

echo "--- [5] PROVIDERS DECLARADOS ---"
if [ -f "$RUTA_BASE/presentation/providers/venta_providers.dart" ]; then
  echo "✅ Archivo existe"
  echo "   Providers:"
  grep -E "^final " "$RUTA_BASE/presentation/providers/venta_providers.dart" | sed 's/^/   /'
else
  echo "❌ NO EXISTE"
fi
echo ""

echo "--- [6] BUSCAR REFERENCIAS DE TIPOS UTILIZADOS ---"
echo "   Buscar: VentaData, numero, fecha, total, itbis, tipo_pago, formaPago"
grep -rE "numero|itbis|montoSubtotal|montoTotal|formaPago|descuento" lib/features/comercial/data/dao/ 2>/dev/null | head -30 | sed 's/^/   /'
echo ""

echo "--- [7] VERIFICAR PROVIDERS COMUNES / DEPENDENCIAS ---"
grep -r "ventasRepositoryProvider" lib/ 2>/dev/null | head -10 | sed 's/^/   /'
echo ""

echo "--- [8] COMPROBACIÓN DE SINTAXIS ---"
dart analyze "$RUTA_BASE" --fatal-infos 2>&1 | grep -E "^(info|warning|error)" | head -50 || echo "   Sin errores de análisis o ruta no analizable"
echo ""

echo "=================================================="
echo "           FIN DE LA AUDITORÍA                     "
echo "=================================================="
