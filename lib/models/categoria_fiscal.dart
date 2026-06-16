class CategoriaFiscal {
  final String id;
  final String nombre;
  final String descripcion;
  final double porcentajeITBIS;
  final double impuestoAdicional;
  final bool esExento;

  const CategoriaFiscal({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.porcentajeITBIS,
    required this.impuestoAdicional,
    required this.esExento,
  });
}

// ✅ LISTA OFICIAL DE CATEGORÍAS FISCALES RD
const List<CategoriaFiscal> categoriasFiscalesRD = [
  CategoriaFiscal(
    id: 'GENERAL',
    nombre: 'Bienes y Servicios Generales',
    descripcion: 'Tasa general del 18% ITBIS, aplica a la mayoría de productos y servicios',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 0.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'BIENES_USO',
    nombre: 'Bienes de Uso / Maquinarias',
    descripcion: 'Maquinarias, equipos y bienes de capital, tasa 18% sin impuesto adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 0.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'COMBUSTIBLES',
    nombre: 'Combustibles y Derivados',
    descripcion: 'Gasolina, gasoil, GLP, incluye ITBIS 18% + impuesto específico adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 16.0, // Valor promedio según normativa vigente
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'ALCOHOL_TABACO',
    nombre: 'Alcoholes y Tabaco',
    descripcion: 'Bebidas alcohólicas, cervezas, tabaco y cigarrillos. ITBIS 18% + impuesto selectivo',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 25.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'LUJO',
    nombre: 'Artículos de Lujo',
    descripcion: 'Vehículos de lujo, joyas, pieles, perfumes costosos. ITBIS 18% + impuesto adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 10.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'ALIMENTOS',
    nombre: 'Alimentos y Productos de Primera Necesidad',
    descripcion: 'Productos básicos, canasta familiar. EXENTOS de ITBIS según ley 11-92',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
  CategoriaFiscal(
    id: 'MEDICAMENTOS',
    nombre: 'Medicamentos y Productos Farmacéuticos',
    descripcion: 'Medicinas, insumos médicos, equipos de salud. EXENTOS',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
  CategoriaFiscal(
    id: 'LIBROS_EDUCACION',
    nombre: 'Libros, Material Educativo y Cultural',
    descripcion: 'Libros, revistas, material didáctico. EXENTOS',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
  CategoriaFiscal(
    id: 'SERVICIOS_BASICOS',
    nombre: 'Servicios Básicos',
    descripcion: 'Energía eléctrica, agua potable, recogida de residuos. EXENTOS',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
  CategoriaFiscal(
    id: 'EXPORTACIONES',
    nombre: 'Exportaciones',
    descripcion: 'Bienes o servicios destinados al extranjero. Tasa 0% y exención total',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
];

// ✅ FUNCIÓN DE DETECCIÓN AUTOMÁTICA (CORREGIDA)
CategoriaFiscal detectarCategoriaFiscal(String nombre, String codigo) {
  // ✅ CORREGIDO: Uso interpolación en vez de concatenación con +
  final texto = '${nombre.toLowerCase()} ${codigo.toLowerCase()}';

  // Reglas de detección según palabras clave
  if (texto.contains('gasolina') || 
      texto.contains('gasoil') || 
      texto.contains('combustible') || 
      texto.contains('glp') || 
      texto.contains('diesel')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'COMBUSTIBLES');
  }

  if (texto.contains('cerveza') || 
      texto.contains('ron') || 
      texto.contains('vino') || 
      texto.contains('alcohol') || 
      texto.contains('tabaco') || 
      texto.contains('cigarrillo')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'ALCOHOL_TABACO');
  }

  if (texto.contains('medicina') || 
      texto.contains('pastilla') || 
      texto.contains('farmacia') || 
      texto.contains('salud') || 
      texto.contains('inyeccion')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'MEDICAMENTOS');
  }

  if (texto.contains('arroz') || 
      texto.contains('habichuela') || 
      texto.contains('carne') || 
      texto.contains('pollo') || 
      texto.contains('leche') || 
      texto.contains('huevo') || 
      texto.contains('pan') || 
      texto.contains('azucar')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'ALIMENTOS');
  }

  if (texto.contains('libro') || 
      texto.contains('cuaderno') || 
      texto.contains('escuela') || 
      texto.contains('educacion')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'LIBROS_EDUCACION');
  }

  if (texto.contains('maquinaria') || 
      texto.contains('equipo') || 
      texto.contains('herramienta')) {
    return categoriasFiscalesRD.firstWhere((c) => c.id == 'BIENES_USO');
  }

  // Por defecto: General
  return categoriasFiscalesRD.firstWhere((c) => c.id == 'GENERAL');
}