import 'package:drift/drift.dart';

/// Migración 002: Unificar nombres y completar campos en tabla Productos
/// - Solo se ejecuta si la tabla anterior ya existía
/// - Renombra: stockActual → stock, unidadId → unidadMedidaId
/// - Agrega: codigoBarras, descripcion, gastosAsociados, margenGanancia,
///   precioMinimo, precioMayorista, precioEspecial, fechaInicioOferta,
///   fechaFinOferta, stockMaximo, activo
Future<void> migrar002AgregarCamposProductos(Migrator m) async {
  final db = m.database;

  // Verificar si existe alguna tabla previa de productos
  final tablas = await db.customSelect('''
    SELECT name FROM sqlite_master WHERE type='table' AND name IN ('productos', 'productos_table')
  ''').get();

  // ⚠️ Instalación nueva: Drift ya creó la tabla correcta → salir sin tocar nada
  if (tablas.isEmpty) return;

  final nombreTablaVieja = tablas.first.read<String>('name');

  // Ya tiene el nombre correcto → no renombrar
  if (nombreTablaVieja == 'productos_table') return;

  // === Solo si hay que transformar tabla anterior ===
  // 1. Crear tabla nueva con estructura completa
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS productos_nueva (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo TEXT UNIQUE NOT NULL,
      codigo_barras TEXT,
      nombre TEXT NOT NULL,
      descripcion TEXT,
      precio_compra REAL NOT NULL,
      gastos_asociados REAL NOT NULL DEFAULT 0,
      precio_venta REAL NOT NULL,
      margen_ganancia REAL,
      precio_minimo REAL,
      precio_mayorista REAL,
      precio_especial REAL,
      fecha_inicio_oferta TEXT,
      fecha_fin_oferta TEXT,
      stock REAL NOT NULL DEFAULT 0,
      stock_minimo REAL NOT NULL DEFAULT 0,
      stock_maximo REAL,
      categoria_id INTEGER NOT NULL,
      marca_id INTEGER NOT NULL,
      unidad_medida_id INTEGER NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1
    )
  ''');

  // 2. Detectar columnas existentes
  final infoColumnas = await db
      .customSelect('PRAGMA table_info($nombreTablaVieja)')
      .get();
  final nombresColumnas = infoColumnas
      .map((r) => r.read<String>('name'))
      .toList();

  final colStock = nombresColumnas.contains('stock_actual')
      ? 'stock_actual'
      : 'stock';
  final colUnidad = nombresColumnas.contains('unidad_id')
      ? 'unidad_id'
      : 'unidad_medida_id';

  // 3. Copiar datos
  await db.customStatement('''
    INSERT INTO productos_nueva (
      id, codigo, nombre, precio_compra, precio_venta,
      stock, stock_minimo, categoria_id, marca_id, unidad_medida_id, activo
    )
    SELECT
      id, codigo, nombre, precio_compra, precio_venta,
      $colStock, COALESCE(stock_minimo, 0),
      categoria_id, marca_id, $colUnidad, 1
    FROM $nombreTablaVieja
  ''');

  // 4. Reemplazar con nombre correcto
  await db.customStatement('DROP TABLE $nombreTablaVieja');
  await db.customStatement(
    'ALTER TABLE productos_nueva RENAME TO productos_table',
  );
}
