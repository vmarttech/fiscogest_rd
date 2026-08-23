#!/bin/bash
set -e

echo "=================================================="
echo "     AUDITORÍA ESTRUCTURAL — RAÍZ DEL PROYECTO    "
echo "=================================================="
echo ""

# ─── [A] INTERFAZ DE REPOSITORIO ───
echo "--- [A] FIRMA DECLARADA EN INTERFAZ ---"
grep -n "listarVentas" lib/features/ventas/domain/repositories/i_ventas_repository.dart
echo ""

# ─── [B] ESTRUCTURA REAL DE VentaData ───
echo "--- [B] CAMPOS REALES DE VentaData ---"
grep -A 30 "class VentaData" lib/features/comercial/data/dao/ventas_dao.dart 2>/dev/null || \
grep -A 30 "VentaData" lib/features/comercial/data/dao/ventas_dao.g.dart 2>/dev/null || \
echo "⚠️  No se encontró VentaData — revisar tabla generada"
echo ""

# ─── [C] ENTIDAD Venta — CAMPOS CONFIRMADOS ───
echo "--- [C] CAMPOS REALES DE ENTIDAD Venta ---"
grep -E "final " lib/features/ventas/domain/entities/venta.dart
echo ""

# ─── [D] VERIFICAR EXISTENCIA DE TIPOS FALTANTES ───
echo "--- [D] BUSCAR DEFINICIÓN DE TIPOS FALTANTES ---"
for tipo in Devolucion Pago Descuento Oferta Apartado Cotizacion; do
  echo -n "   $tipo: "
  encontrado=$(grep -r "class $tipo\b\|enum $tipo\b" lib/features/ 2>/dev/null | head -1)
  if [ -n "$encontrado" ]; then echo "✅ $encontrado"; else echo "❌ NO DEFINIDO"; fi
done
echo ""

# ─── [E] PROVIDERS EXISTENTES — NOMBRES REALES ───
echo "--- [E] TODOS LOS PROVIDERS DECLARADOS EN VENTAS ---"
grep -r "^final.*Provider" lib/features/ventas/ 2>/dev/null
echo ""

# ─── [F] RUTAS DE IMPORTACIÓN EXISTENTES ───
echo "--- [F] VERIFICAR RUTAS DE IMPORTACIÓN ---"
echo "   core/providers.dart: $(test -f lib/core/providers.dart && echo "✅ EXISTE" || echo "❌ NO EXISTE")"
echo "   ventas_enums.dart:   $(test -f lib/features/ventas/presentation/contenedor/enums/ventas_enums.dart && echo "✅ EXISTE" || echo "❌ NO EXISTE")"
echo ""

# ─── [G] UI CONSTANTES ───
echo "--- [G] VERIFICAR CONSTANTES DE UI ---"
grep -E "paddingAllMedium|spacingMedium|titleLarge|bodyMediumBold" lib/core/ui/*.dart 2>/dev/null
echo ""

echo "=================================================="
echo "        FIN DE AUDITORÍA ESTRUCTURAL              "
echo "=================================================="
