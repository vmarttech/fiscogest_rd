import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

class ProveedorRepositoryImpl implements IProveedorRepository {
  final List<Proveedor> _proveedores = [
    Proveedor(
      id: 1,
      nombreEmpresa: 'Distribuidora Global, S.A.',
      nombreContacto: 'Lic. Juan Pérez',
      direccion: 'Av. John F. Kennedy, Santo Domingo',
      telefono: '809-555-1234',
      email: 'contacto@distribuidoraglobal.do',
      rnc: '101-23456-7',
    ),
  ];

  final Map<int, double> _saldos = {};

  @override
  Future<List<Proveedor>> obtenerProveedores() async {
    return List.unmodifiable(_proveedores);
  }

  @override
  Future<Proveedor?> obtenerProveedorPorId(int id) async {
    try {
      return _proveedores.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> guardarProveedor(Proveedor proveedor) async {
    final existe = _proveedores.any(
      (p) => p.rnc?.trim() == proveedor.rnc?.trim() && p.id != proveedor.id,
    );
    if (existe) {
      throw Exception('Ya existe un proveedor registrado con ese RNC.');
    }

    final nuevoId = _proveedores.isEmpty
        ? 1
        : (_proveedores.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);

    final nuevo = proveedor.copyWith(id: nuevoId);
    _proveedores.add(nuevo);
    return nuevoId;
  }

  @override
  Future<bool> actualizarProveedor(Proveedor proveedor) async {
    final duplicado = _proveedores.any(
      (p) => p.id != proveedor.id && p.rnc?.trim() == proveedor.rnc?.trim(),
    );
    if (duplicado) {
      throw Exception('Ya existe otro proveedor con ese RNC.');
    }

    final index = _proveedores.indexWhere((p) => p.id == proveedor.id);
    if (index == -1) return false;
    _proveedores[index] = proveedor;
    return true;
  }

  @override
  Future<bool> eliminarProveedor(int id) async {
    final antes = _proveedores.length;
    _proveedores.removeWhere((p) => p.id == id);
    _saldos.remove(id);
    return _proveedores.length < antes;
  }

  @override
  Future<void> registrarCompraProveedor({
    required int proveedorId,
    required double monto,
  }) async {
    _saldos[proveedorId] = (_saldos[proveedorId] ?? 0.0) + monto;
  }

  @override
  Future<void> agregarSaldo(int proveedorId, double monto) async {
    _saldos[proveedorId] = (_saldos[proveedorId] ?? 0.0) + monto;
  }

  @override
  Future<double> obtenerSaldo(int proveedorId) async {
    return _saldos[proveedorId] ?? 0.0;
  }
}
