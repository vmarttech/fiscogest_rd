class CategoriaFiscal {
  const CategoriaFiscal({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.porcentajeITBIS,
    required this.impuestoAdicional,
    required this.esExento,
  });
  final String id;
  final String nombre;
  final String descripcion;
  final double porcentajeITBIS;
  final double impuestoAdicional;
  final bool esExento;
}

// ✅ LISTA OFICIAL DE CATEGORÍAS FISCALES RD
const List<CategoriaFiscal> categoriasFiscalesRD = [
  CategoriaFiscal(
    id: 'GENERAL',
    nombre: 'Bienes y Servicios Generales',
    descripcion:
        'Tasa general del 18% ITBIS, aplica a la mayoría de productos y servicios',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 0.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'BIENES_USO',
    nombre: 'Bienes de Uso / Maquinarias',
    descripcion:
        'Maquinarias, equipos y bienes de capital, tasa 18% sin impuesto adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 0.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'COMBUSTIBLES',
    nombre: 'Combustibles y Derivados',
    descripcion:
        'Gasolina, gasoil, GLP, incluye ITBIS 18% + impuesto específico adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 16.0, // Valor promedio según normativa vigente
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'ALCOHOL_TABACO',
    nombre: 'Alcoholes y Tabaco',
    descripcion:
        'Bebidas alcohólicas, cervezas, tabaco y cigarrillos. ITBIS 18% + impuesto selectivo',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 25.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'LUJO',
    nombre: 'Artículos de Lujo',
    descripcion:
        'Vehículos de lujo, joyas, pieles, perfumes costosos. ITBIS 18% + impuesto adicional',
    porcentajeITBIS: 18.0,
    impuestoAdicional: 10.0,
    esExento: false,
  ),
  CategoriaFiscal(
    id: 'ALIMENTOS',
    nombre: 'Alimentos y Productos de Primera Necesidad',
    descripcion:
        'Productos básicos, canasta familiar. EXENTOS de ITBIS según ley 11-92',
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
    descripcion:
        'Energía eléctrica, agua potable, recogida de residuos. EXENTOS',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
  CategoriaFiscal(
    id: 'EXPORTACIONES',
    nombre: 'Exportaciones',
    descripcion:
        'Bienes o servicios destinados al extranjero. Tasa 0% y exención total',
    porcentajeITBIS: 0.0,
    impuestoAdicional: 0.0,
    esExento: true,
  ),
];

// ✅ MAPA DE REGLAS: CADA CATEGORÍA CON SUS PALABRAS CLAVE
final Map<String, List<String>> _reglasDeteccion = {
  'COMBUSTIBLES': ['gasolina', 'gasoil', 'combustible', 'glp', 'diesel'],
  'ALCOHOL_TABACO': [
    'cerveza',
    'ron',
    'vino',
    'alcohol',
    'tabaco',
    'cigarrillo',
  ],
  'MEDICAMENTOS': ['medicina', 'pastilla', 'farmacia', 'salud', 'inyeccion'],
  'ALIMENTOS': [
    'arroz',
    'habichuela',
    'carne',
    'pollo',
    'leche',
    'huevo',
    'pan',
    'azucar',
  ],
  'LIBROS_EDUCACION': ['libro', 'cuaderno', 'escuela', 'educacion'],
  'BIENES_USO': ['maquinaria', 'equipo', 'herramienta'],
};

// ✅ FUNCIÓN AUXILIAR: VERIFICA SI EL TEXTO COINCIDE CON ALGUNA PALABRA CLAVE
bool _coincideConPalabras(String texto, List<String> palabras) {
  return palabras.any((palabra) => texto.contains(palabra));
}

// ✅ FUNCIÓN PRINCIPAL: SIMPLIFICADA Y CON BAJA COMPLEJIDAD
CategoriaFiscal detectarCategoriaFiscal(String nombre, String codigo) {
  final texto = '${nombre.toLowerCase()} ${codigo.toLowerCase()}';

  // Recorremos las reglas y devolvemos la categoría correspondiente
  for (final entrada in _reglasDeteccion.entries) {
    if (_coincideConPalabras(texto, entrada.value)) {
      return categoriasFiscalesRD.firstWhere((cat) => cat.id == entrada.key);
    }
  }

  // Si no coincide con ninguna, devolvemos la categoría general
  return categoriasFiscalesRD.firstWhere((cat) => cat.id == 'GENERAL');
}
