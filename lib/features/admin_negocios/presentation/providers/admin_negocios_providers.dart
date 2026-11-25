
// [ADMIN_FASE2]
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/admin_negocios/data/admin_negocios_remote.dart';

final adminNegociosRemoteProvider =
    Provider<AdminNegociosRemote>((ref) => AdminNegociosRemote());

class AdminNegociosFiltros {
  const AdminNegociosFiltros({
    this.busqueda = '',
    this.estado = '',
    this.plan = '',
    this.orden = 'reciente',
  });
  final String busqueda;
  final String estado;
  final String plan;
  final String orden;
  AdminNegociosFiltros copyWith({String? busqueda, String? estado, String? plan, String? orden}) =>
      AdminNegociosFiltros(
        busqueda: busqueda ?? this.busqueda,
        estado: estado ?? this.estado,
        plan: plan ?? this.plan,
        orden: orden ?? this.orden,
      );
}

final adminNegociosFiltrosProvider =
    StateProvider<AdminNegociosFiltros>((ref) => const AdminNegociosFiltros());
final adminNegociosTickProvider = StateProvider<int>((ref) => 0);

const int kAdminNegociosLimite = 20;

@immutable
class AdminNegociosListaEstado {
  const AdminNegociosListaEstado({
    this.filas = const [],
    this.inicializando = true,
    this.cargandoMas = false,
    this.error,
    this.hayMas = true,
    this.offset = 0,
  });
  final List<AdminNegocioRow> filas;
  final bool inicializando;
  final bool cargandoMas;
  final String? error;
  final bool hayMas;
  final int offset;

  AdminNegociosListaEstado copyWith({
    List<AdminNegocioRow>? filas,
    bool? inicializando,
    bool? cargandoMas,
    String? error,
    bool limpiarError = false,
    bool? hayMas,
    int? offset,
  }) =>
      AdminNegociosListaEstado(
        filas: filas ?? this.filas,
        inicializando: inicializando ?? this.inicializando,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        error: limpiarError ? null : (error ?? this.error),
        hayMas: hayMas ?? this.hayMas,
        offset: offset ?? this.offset,
      );
}

class AdminNegociosListaNotifier extends StateNotifier<AdminNegociosListaEstado> {
  AdminNegociosListaNotifier(this._ref) : super(const AdminNegociosListaEstado()) {
    _ref.listen(adminNegociosTickProvider, (_, __) {
      if (mounted) recargar();
    });
    _ref.listen(adminNegociosFiltrosProvider, (_, __) {
      if (mounted) recargar();
    });
    recargar();
  }

  final Ref _ref;

  AdminNegociosFiltros get _f => _ref.read(adminNegociosFiltrosProvider);

  Future<void> recargar() async {
    state = state.copyWith(inicializando: true, cargandoMas: false, limpiarError: true, hayMas: true, offset: 0);
    try {
      final filas = await _ref.read(adminNegociosRemoteProvider).listar(
            busqueda: _f.busqueda,
            estado: _f.estado.isEmpty ? null : _f.estado,
            plan: _f.plan.isEmpty ? null : _f.plan,
            orden: _f.orden,
            limite: kAdminNegociosLimite,
            offset: 0,
          );
      state = state.copyWith(
        filas: filas,
        inicializando: false,
        hayMas: filas.length == kAdminNegociosLimite,
        offset: filas.length,
      );
    } catch (e) {
      state = state.copyWith(inicializando: false, error: '$e');
    }
  }

  Future<void> cargarMas() async {
    if (state.cargandoMas || !state.hayMas) return;
    state = state.copyWith(cargandoMas: true);
    try {
      final mas = await _ref.read(adminNegociosRemoteProvider).listar(
            busqueda: _f.busqueda,
            estado: _f.estado.isEmpty ? null : _f.estado,
            plan: _f.plan.isEmpty ? null : _f.plan,
            orden: _f.orden,
            limite: kAdminNegociosLimite,
            offset: state.offset,
          );
      state = state.copyWith(
        filas: [...state.filas, ...mas],
        cargandoMas: false,
        hayMas: mas.length == kAdminNegociosLimite,
        offset: state.offset + mas.length,
      );
    } catch (e) {
      state = state.copyWith(cargandoMas: false, error: '$e');
    }
  }
}

final adminNegociosListaProvider =
    StateNotifierProvider<AdminNegociosListaNotifier, AdminNegociosListaEstado>(
        (ref) => AdminNegociosListaNotifier(ref));

final adminNegocioDetalleProvider =
    FutureProvider.autoDispose.family<AdminNegocioDetalle, String>((ref, id) async {
  ref.watch(adminNegociosTickProvider);
  return ref.read(adminNegociosRemoteProvider).detalle(id);
});
