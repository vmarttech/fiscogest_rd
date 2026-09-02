import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';

class ImpuestoRepositoryImpl {
  final List<ImpuestoEntity> _impuestosLocales = [
    const ImpuestoEntity(
      id: 1,
      nombre: 'ITBIS 18%',
      porcentaje: 18.0,
      tipo: 'ITBIS',
      esExento: false,
      descripcion: 'Tasa general estándar DGII',
    ),
    const ImpuestoEntity(
      id: 2,
      nombre: 'ITBIS 16%',
      porcentaje: 16.0,
      tipo: 'ITBIS',
      esExento: false,
      descripcion: 'Tasa reducida DGII',
    ),
    const ImpuestoEntity(
      id: 3,
      nombre: 'ITBIS 0% (Exento)',
      porcentaje: 0.0,
      tipo: 'Exento',
      esExento: true,
      descripcion: 'Bienes y servicios exentos de ITBIS',
    ),
    const ImpuestoEntity(
      id: 4,
      nombre: 'Propina Legal 10%',
      porcentaje: 10.0,
      tipo: 'Adicional',
      esExento: false,
      descripcion: 'Ley de protección al consumidor / sector gastronómico',
    ),
  ];

  Future<List<ImpuestoEntity>> obtenerImpuestos() async {
    return _impuestosLocales;
  }

  Future<void> guardarImpuesto(ImpuestoEntity impuesto) async {
    if (impuesto.porcentaje < 0) {
      throw Exception('El porcentaje del impuesto no puede ser negativo.');
    }
    final existe = _impuestosLocales.any(
      (i) =>
          i.nombre.trim().toLowerCase() == impuesto.nombre.trim().toLowerCase(),
    );
    if (existe) {
      throw Exception('Ya existe un impuesto registrado con este nombre.');
    }
    final nuevoId = _impuestosLocales.isEmpty
        ? 1
        : (_impuestosLocales
                  .map((e) => e.id ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1);
    _impuestosLocales.add(impuesto.copyWith(id: nuevoId));
  }

  Future<void> actualizarImpuesto(ImpuestoEntity impuesto) async {
    if (impuesto.porcentaje < 0) {
      throw Exception('El porcentaje del impuesto no puede ser negativo.');
    }
    final duplicado = _impuestosLocales.any(
      (i) =>
          i.id != impuesto.id &&
          i.nombre.trim().toLowerCase() == impuesto.nombre.trim().toLowerCase(),
    );
    if (duplicado) {
      throw Exception('Ya existe otro impuesto con este nombre.');
    }
    final index = _impuestosLocales.indexWhere((i) => i.id == impuesto.id);
    if (index != -1) {
      _impuestosLocales[index] = impuesto;
    }
  }

  Future<void> eliminarImpuesto(int id) async {
    _impuestosLocales.removeWhere((i) => i.id == id);
  }
}
