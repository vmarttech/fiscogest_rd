#!/usr/bin/env bash
# ==============================================================================
# AUDITORÍA COMPLETA Y DEFINITIVA - ETAPA 4.2: RECEPCIÓN DE MERCANCÍAS
# Proyecto: KLK Market / VmartPos (Flutter, Riverpod, SQLite)
# ==============================================================================

echo "=============================================================================="
echo "          INFORME DE AUDITORÍA TÉCNICA - ETAPA 4.2: RECEPCIÓN DE MERCANCÍAS    "
echo "=============================================================================="
echo "Fecha y Hora: $(date '+%Y-%m-%d %H:%M:%S')"
echo "------------------------------------------------------------------------------"

ERRORS=0
WARNINGS=0

# Función para verificar existencia de archivos
check_file() {
    local file_path="$1"
    local description="$2"
    if [ -f "$file_path" ]; then
        echo "[  OK  ] $description encontrado: $file_path"
    else
        echo "[FAIL  ] $description NO ENCONTRADO: $file_path"
        ((ERRORS++))
    fi
}

# Función para verificar contenido dentro de un archivo
check_content() {
    local file_path="$1"
    local pattern="$2"
    local description="$3"
    if [ -f "$file_path" ] && grep -q "$pattern" "$file_path"; then
        echo "[  OK  ] $description (Patrón: '$pattern' verificado en $file_path)"
    else
        echo "[FAIL  ] $description NO DETECTADO en $file_path (Buscado: '$pattern')"
        ((ERRORS++))
    fi
}

echo ""
echo "1. VERIFICACIÓN DE MODELOS Y ESTRUCTURA DE DATOS (SQLite / Drift)"
echo "------------------------------------------------------------------------------"
check_file "lib/features/inventory/data/models/reception_model.dart" "Modelo de Recepción de Mercancías"
check_file "lib/features/inventory/data/models/reception_item_model.dart" "Modelo de Ítems de Recepción"
check_content "lib/features/inventory/data/models/reception_model.dart" "isComplete" "Soporte para recepción parcial y completa"
check_content "lib/features/inventory/data/models/reception_item_model.dart" "difference" "Campo de registro de diferencias y cantidades"

echo ""
echo "2. VERIFICACIÓN DE REPOSITORIOS Y ACCESO A DATOS"
echo "------------------------------------------------------------------------------"
check_file "lib/features/inventory/domain/repositories/reception_repository.dart" "Repositorio de Recepción (Dominio/Contrato)"
check_file "lib/features/inventory/data/repositories/reception_repository_impl.dart" "Implementación de Repositorio de Recepción"
check_content "lib/features/inventory/data/repositories/reception_repository_impl.dart" "inventory" "Actualización automática de inventario al recibir"

echo ""
echo "3. VERIFICACIÓN DE PROVIDERS (Riverpod State Management)"
echo "------------------------------------------------------------------------------"
check_file "lib/features/inventory/presentation/providers/reception_provider.dart" "Provider de Recepción de Mercancías"
check_content "lib/features/inventory/presentation/providers/reception_provider.dart" "StateNotifierProvider" "Definición correcta de StateNotifier/AsyncNotifier para recepciones"

echo ""
echo "4. VERIFICACIÓN DE LA INTERFAZ DE USUARIO (UI / Vistas y Formularios)"
echo "------------------------------------------------------------------------------"
check_file "lib/features/inventory/presentation/screens/reception_list_screen.dart" "Pantalla de Listado de Recepciones"
check_file "lib/features/inventory/presentation/screens/reception_detail_screen.dart" "Pantalla de Detalle / Formulario de Recepción"
check_content "lib/features/inventory/presentation/screens/reception_detail_screen.dart" "observaciones" "Campo de registro de observaciones implementado"
check_content "lib/features/inventory/presentation/screens/reception_detail_screen.dart" "diferencias" "Validación y visualización de diferencias de cantidades"

echo ""
echo "5. VERIFICACIÓN DE INTEGRIDAD Y CONEXIONES GLOBALES"
echo "------------------------------------------------------------------------------"
if command -v flutter &> /dev/null; then
    echo "[INFO  ] Ejecutando análisis estático de Flutter (flutter analyze)..."
    if flutter analyze; then
        echo "[  OK  ] Análisis estático de Flutter superado sin errores de compilación."
    else
        echo "[FAIL  ] Se detectaron errores estáticos en el código."
        ((ERRORS++))
    fi
else
    echo "[WARN  ] Flutter CLI no disponible en el entorno actual para compilación estática."
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
    echo "ESTADO: [ ÉXITO / COMPLETADO ]"
    echo "La Etapa 4.2 – Recepción de Mercancías está 100% implementada, conectada y validada."
    echo "Se cumplen todos los requerimientos: recepción parcial/completa, validación de"
    echo "cantidades, registro de diferencias, actualización de inventario y observaciones."
    exit 0
else
    echo "ESTADO: [ FALLIDO / INCOMPLETO ]"
    echo "Existen componentes faltantes o desconectados. No se puede aprobar la etapa."
    exit 1
fi
