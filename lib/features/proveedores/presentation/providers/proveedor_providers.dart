import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';

class ProveedorNotifier extends StateNotifier<AsyncValue<List<Proveedor>>> {
  ProveedorNotifier()
    : super(
        AsyncValue.data([
          Proveedor(
            id: 1,
            nombre: 'Distribuidora Global, S.A.',
            contacto: 'Lic. Juan Pérez',
            direccion: 'Av. John F. Kennedy, Santo Domingo',
            telefono: '809-555-1234',
            correo: 'contacto@distribuidoraglobal.do',
            rnc: '101-23456-7',
          ),
        ]),
      );

  Future<void> guardar(Proveedor proveedor) async {
    state.whenData((lista) {
      final existe = lista.any((p) => p.rnc.trim() == proveedor.rnc.trim());
      if (existe) {
        throw Exception('Ya existe un proveedor registrado con ese RNC.');
      }
      final nuevoId = lista.isEmpty
          ? 1
          : (lista.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final nuevoProveedor = proveedor.copyWith(id: nuevoId);
      state = AsyncValue.data([...lista, nuevoProveedor]);
    });
  }

  Future<void> actualizar(Proveedor proveedor) async {
    state.whenData((lista) {
      final duplicado = lista.any(
        (p) => p.id != proveedor.id && p.rnc.trim() == proveedor.rnc.trim(),
      );
      if (duplicado) {
        throw Exception('Ya existe otro proveedor registrado con ese RNC.');
      }
      state = AsyncValue.data([
        for (var p in lista)
          if (p.id == proveedor.id) proveedor else p,
      ]);
    });
  }

  Future<void> eliminar(int id) async {
    state.whenData((lista) {
      state = AsyncValue.data(lista.where((p) => p.id != id).toList());
    });
  }
}

final proveedorControllerProvider =
    StateNotifierProvider<ProveedorNotifier, AsyncValue<List<Proveedor>>>((
      ref,
    ) {
      return ProveedorNotifier();
    });
