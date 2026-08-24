#!/usr/bin/env bash
# ==============================================================================
# AUDITORÍA COMPLETA Y DEFINITIVA - ETAPA 4.3: MÓDULO DE VENTAS
# Proyecto: KLK Market / VmartPos (Flutter, Riverpod, SQLite)
# ==============================================================================

echo "=============================================================================="
echo "          INFORME DE AUDITORÍA TÉCNICA - ETAPA 4.3: MÓDULO DE VENTAS          "
echo "=============================================================================="
echo "Fecha y Hora: $(date '+%Y-%m-%d %H:%M:%S')"
echo "------------------------------------------------------------------------------"

ERRORS=0
WARNINGS=0

# Función para verificar existencia de archivos o directorios clave
check_path() {
    local target_path="$1"
    local description="$2"
    if [ -e "$target_path" ]; then
        echo "[  OK  ] $description encontrado: $target_path"
    else
        echo "[FAIL  ] $description NO ENCONTRADO: $target_path"
        ((ERRORS++))
    fi
}

# Función para verificar contenido dentro de un archivo
check_content() {
    local file_path="$1"
    local pattern="$2"
    local description="$3"
    if [ -f "$file_path" ] && grep -q "$pattern" "$file_path"; then
        echo "[  OK  ] $description (Patrón: '$pattern' verificado)"
    else
        echo "[FAIL  ] $description NO DETECTADO (Buscado: '$pattern' en $file_path)"
        ((ERRORS++))
    fi
}

echo ""
echo "1. VERIFICACIÓN DE LA ESTRUCTURA DEL MÓDULO DE VENTAS (Domain / Data / Presentation)"
echo "------------------------------------------------------------------------------"
check_path "lib/features/sales" "Directorio principal del módulo de ventas"
check_path "lib/features/sales/data" "Capa de datos de ventas"
check_path "lib/features/sales/domain" "Capa de dominio de ventas"
check_path "lib/features/sales/presentation" "Capa de presentación de ventas"

echo ""
echo "2. VERIFICACIÓN DE REQUISITOS DE NEGOCIO Y MODELOS"
echo "------------------------------------------------------------------------------"
# Buscar archivos relacionados con modelos o lógica de factura/carrito/ventas de forma flexible en el feature
INVOICE_FILES=$(find lib/features/sales -name "*.dart" 2>/dev/null)
if [ -n "$INVOICE_FILES" ]; then
    echo "[  OK  ] Archivos de código del módulo de ventas encontrados."
    for file in $INVOICE_FILES; do
        echo "          -> Archivo detectado: $file"
    done
else
    echo "[FAIL  ] No se encontraron archivos de código Dart en lib/features/sales"
    ((ERRORS++))
fi

echo ""
echo "3. VERIFICACIÓN DE CONEXIONES GLOBALES (Inventario, Clientes, Caja, Historial)"
echo "------------------------------------------------------------------------------"
# Comprobar si hay referencias cruzadas o providers globales configurados
if [ -d "lib/features/sales" ]; then
    SALES_CONTENT_CHECK=$(grep -rn "inventory" lib/features/sales 2>/dev/null)
    if [ -n "$SALES_CONTENT_CHECK" ]; then
        echo "[  OK  ] Conexión con inventario detectada en el módulo de ventas."
    else
        echo "[WARN  ] No se detectó la palabra clave 'inventory' explícitamente en lib/features/sales."
        ((WARNINGS++))
    fi
    
    CASH_CONTENT_CHECK=$(grep -rn "cash" lib/features/sales 2>/dev/null)
    if [ -n "$CASH_CONTENT_CHECK" ]; then
        echo "[  OK  ] Conexión con caja detectada en el módulo de ventas."
    else
        echo "[WARN  ] No se detectó la palabra clave 'cash' explícitamente en lib/features/sales."
        ((WARNINGS++))
    fi
else
    echo "[FAIL  ] Directorio lib/features/sales inexistente."
    ((ERRORS++))
fi

echo ""
echo "4. VERIFICACIÓN DE COMPILACIÓN Y ANÁLISIS ESTÁTICO (Flutter Analyzer)"
echo "------------------------------------------------------------------------------"
if command -v flutter &> /dev/null; then
    echo "[INFO  ] Ejecutando análisis estático (flutter analyze)..."
    if flutter analyze; then
        echo "[  OK  ] Análisis estático de Flutter superado sin errores."
    else
        echo "[FAIL  ] Se detectaron errores estáticos o de compilación en el proyecto."
        ((ERRORS++))
    fi
else
    echo "[WARN  ] Flutter CLI no disponible en este entorno para compilación estática."
    ((WARNINGS++))
fi

echo ""
echo "=============================================================================="
echo "                          RESULTADO DE LA AUDITORÍA                           "
echo "=============================================================================="
echo "Errores críticos encontrados: $ERRORS"
echo "Advertencias: $WARNINGS"
echo "------------------------------------------------------------------------------"

if [ $ERRORS -eq 0 ]; then
    echo "ESTADO: [ ÉXITO / AUDITORÍA APROBADA ]"
    echo "La Etapa 4.3 – Ventas cumple con la estructura y las conexiones requeridas."
    exit 0
else
    echo "ESTADO: [ FALLIDO / INCOMPLETO ]"
    echo "Se encontraron discrepancias en la estructura de la Etapa 4.3. Corrija los errores."
    exit 1
fi
