import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';

class ProveedorRepository {
  final List<Proveedor> _proveedoresLocales = [
    Proveedor(
      id: 1,
      nombre: 'Distribuidora Global, S.A.',
      contacto: 'Lic. Juan Pérez',
      direccion: 'Av. John F. Kennedy, Santo Domingo',
      telefono: '809-555-1234',
      correo: 'contacto@distribuidoraglobal.do',
      rnc: '101-23456-7',
    ),
  ];

  Future<List<Proveedor>> obtenerProveedores() async {
    return _proveedoresLocales;
  }

  Future<void> agregarProveedor(Proveedor proveedor) async {
    final existe = _proveedoresLocales.any((p) => p.rnc.trim() == proveedor.rnc.trim());
    if (existe) {
      throw Exception('Ya existe un proveedor registrado con ese RNC.');
    }
    final nuevoId = _proveedoresLocales.isEmpty ? 1 : (_proveedoresLocales.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    _proveedoresLocales.add(proveedor.copyWith(id: nuevoId));
  }

  Future<void> actualizarProveedor(Proveedor proveedor) async {
    final duplicado = _proveedoresLocales.any((p) => p.id != proveedor.id && p.rnc.trim() == proveedor.rnc.trim());
    if (duplicado) {
      throw Exception('Ya existe otro proveedor registrado con ese RNC.');
    }
    final index = _proveedoresLocales.indexWhere((p) => p.id == proveedor.id);
    if (index != -1) {
      _proveedoresLocales[index] = proveedor;
    }
  }

  Future<void> eliminarProveedor(int id) async {
    _proveedoresLocales.removeWhere((p) => p.id == id);
  }
}
