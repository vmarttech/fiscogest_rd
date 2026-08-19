#!/bin/bash
set -e

echo "============================================================"
echo "  DIAGNÓSTICO DE ERRORES — REGISTRAR VENTA"
echo "  Localiza la causa exacta de cada error de compilación"
echo "============================================================"
echo ""

echo "🔍 1. VERIFICAR ENTIDAD Venta — constructor y campos"
echo "------------------------------------------------------------"
grep -n "usuarioId" lib/features/ventas/domain/entities/venta.dart
echo ""

echo "🔍 2. VERIFICAR Companion de BD — VentasTableCompanion"
echo "------------------------------------------------------------"
grep -n "usuarioId" lib/core/database/app_database.dart 2>/dev/null || echo "⚠️ No hallado en app_database.dart — revisando tabla..."
grep -rn "usuarioId" lib/core/database/ 2>/dev/null | head -20
echo ""

echo "🔍 3. VERIFICAR ENTIDAD Cotizacion — nombre de campos"
echo "------------------------------------------------------------"
grep -n "fechaEmision\|fechaVencimiento\|fechaVigencia" lib/features/ventas/domain/entities/cotizacion.dart
echo ""

echo "🔍 4. VERIFICAR CotizacionTableCompanion"
echo "------------------------------------------------------------"
grep -n "fecha" lib/core/database/app_database.dart 2>/dev/null | grep -i cotizacion || echo "Buscando definición de tabla Cotizaciones..."
grep -rn "CotizacionesTable\|cotizacionesTable" lib/core/database/ 2>/dev/null | head -10
echo ""

echo "🔍 5. COMPROBAR ERRORES ACTUALES"
echo "------------------------------------------------------------"
dart analyze lib/features/ventas/ 2>&1 | grep -E "error •|missing_required_argument|undefined_named_parameter|argument_type_not_assignable"
echo ""

echo "============================================================"
echo "  FIN DIAGNÓSTICO — copia y pega el resultado aquí"
echo "============================================================"
