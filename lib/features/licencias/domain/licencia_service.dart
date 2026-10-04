import 'dart:math';

import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';

class LicenciaService {
  LicenciaService(this._db);

  final AppDatabase _db;
  final _rng = Random.secure();

  /// Crea demo 15 días si no existe ninguna licencia.
  Future<LicenciaInfo> ensureLicenciaInicial() async {
    final rows = await _db.select(_db.licenciasTable).get();
    if (rows.isNotEmpty) {
      return _mapYActualizarEstado(rows.first);
    }

    final ahora = DateTime.now();
    final fin = ahora.add(const Duration(days: kDiasPrueba));
    final id = await _db.into(_db.licenciasTable).insert(
          LicenciasTableCompanion.insert(
            plan: 'demo',
            vigenciaTipo: 'prueba',
            fechaInicio: ahora.toIso8601String(),
            fechaFin: Value(fin.toIso8601String()),
            maxDispositivos: const Value(1),
            maxCajas: const Value(1),
            ecfHabilitado: const Value(false),
            vitalicia: const Value(false),
            estado: 'activa',
            actualizadoEn: ahora.toIso8601String(),
          ),
        );
    final row = await (_db.select(_db.licenciasTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _mapYActualizarEstado(row);
  }

  Future<LicenciaInfo?> obtenerActual() async {
    final rows = await _db.select(_db.licenciasTable).get();
    if (rows.isEmpty) return null;
    // Preferir desarrollador / la más reciente
    rows.sort((a, b) => b.id.compareTo(a.id));
    final dev = rows.where((r) => r.plan == 'desarrollador' || r.vitalicia);
    final row = dev.isNotEmpty ? dev.first : rows.first;
    return _mapYActualizarEstado(row);
  }

  /// Acceso vitalicio del dueño (MartTech).
  Future<LicenciaInfo> activarDesarrolladorVitalicio() async {
    final ahora = DateTime.now();
    final existentes = await _db.select(_db.licenciasTable).get();
    for (final r in existentes) {
      if (r.plan == 'desarrollador' || r.vitalicia) {
        await (_db.update(_db.licenciasTable)..where((t) => t.id.equals(r.id)))
            .write(
          LicenciasTableCompanion(
            estado: const Value('activa'),
            vitalicia: const Value(true),
            plan: const Value('desarrollador'),
            vigenciaTipo: const Value('vitalicia'),
            fechaFin: const Value(null),
            maxCajas: const Value(999),
            maxDispositivos: const Value(999),
            ecfHabilitado: const Value(true),
            actualizadoEn: Value(ahora.toIso8601String()),
          ),
        );
        return (await obtenerActual())!;
      }
    }

    await _db.into(_db.licenciasTable).insert(
          LicenciasTableCompanion.insert(
            plan: 'desarrollador',
            vigenciaTipo: 'vitalicia',
            fechaInicio: ahora.toIso8601String(),
            fechaFin: const Value(null),
            maxDispositivos: const Value(999),
            maxCajas: const Value(999),
            ecfHabilitado: const Value(true),
            vitalicia: const Value(true),
            estado: 'activa',
            actualizadoEn: ahora.toIso8601String(),
          ),
        );
    return (await obtenerActual())!;
  }

  Future<LicenciaInfo> _mapYActualizarEstado(LicenciasTableData row) async {
    final info = _fromRow(row);
    final nuevoEstado = _calcularEstado(info);
    if (nuevoEstado != row.estado) {
      await (_db.update(_db.licenciasTable)..where((t) => t.id.equals(row.id)))
          .write(
        LicenciasTableCompanion(
          estado: Value(nuevoEstado),
          actualizadoEn: Value(DateTime.now().toIso8601String()),
        ),
      );
      return _fromRow(row).copyWithEstado(nuevoEstado);
    }
    return info;
  }

  String _calcularEstado(LicenciaInfo info) {
    if (info.esDesarrollador) return 'activa';
    final fin = info.fechaFin;
    if (fin == null) return 'activa';
    final ahora = DateTime.now();
    if (ahora.isBefore(fin) || ahora.isAtSameMomentAs(fin)) return 'activa';
    final graciaHasta = fin.add(const Duration(days: kDiasGracia));
    if (ahora.isBefore(graciaHasta)) return 'gracia';
    return 'vencida';
  }

  LicenciaInfo _fromRow(LicenciasTableData r) {
    return LicenciaInfo(
      id: r.id,
      plan: r.plan,
      vigenciaTipo: r.vigenciaTipo,
      fechaInicio: DateTime.tryParse(r.fechaInicio) ?? DateTime.now(),
      fechaFin: r.fechaFin != null ? DateTime.tryParse(r.fechaFin!) : null,
      maxDispositivos: r.maxDispositivos,
      maxCajas: r.maxCajas,
      ecfHabilitado: r.ecfHabilitado,
      vitalicia: r.vitalicia,
      estado: r.estado,
      fingerprint: r.fingerprint,
      codigoActivacion: r.codigoActivacion,
    );
  }

  /// Genera referencia única FG- + 5 dígitos.
  Future<String> generarReferenciaUnica() async {
    for (var i = 0; i < 40; i++) {
      final n = 10000 + _rng.nextInt(90000);
      final ref = 'FG-$n';
      final existe = await (_db.select(_db.pedidosLicenciaTable)
            ..where((t) => t.referencia.equals(ref)))
          .get();
      if (existe.isEmpty) return ref;
    }
    return 'FG-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  Future<String> crearPedido({
    required String plan,
    required String vigenciaTipo,
    String? negocioNombre,
    String? rnc,
    String? medioPreferido,
  }) async {
    final monto = precioPlanVigencia(plan, vigenciaTipo);
    if (monto == null) {
      throw ArgumentError('Plan/vigencia no tarifados: $plan / $vigenciaTipo');
    }
    final ahora = DateTime.now();
    final ref = await generarReferenciaUnica();
    await _db.into(_db.pedidosLicenciaTable).insert(
          PedidosLicenciaTableCompanion.insert(
            referencia: ref,
            plan: plan,
            vigenciaTipo: vigenciaTipo,
            monto: monto,
            estado: 'pendiente_pago',
            negocioNombre: Value(negocioNombre),
            rnc: Value(rnc),
            fechaCreacion: ahora.toIso8601String(),
            fechaExpiracionPedido:
                ahora.add(const Duration(days: kDiasExpiracionPedido)).toIso8601String(),
            medioPagoPreferido: Value(medioPreferido),
          ),
        );
    return ref;
  }

  Future<void> marcarPagoReportado(String referencia) async {
    await (_db.update(_db.pedidosLicenciaTable)
          ..where((t) => t.referencia.equals(referencia)))
        .write(
      const PedidosLicenciaTableCompanion(
        estado: Value('pago_reportado'),
      ),
    );
  }

  /// Admin: confirmó el depósito → emite licencia de pago.
  Future<LicenciaInfo> marcarPagadoYEmitirLicencia(String referencia) async {
    final pedidos = await (_db.select(_db.pedidosLicenciaTable)
          ..where((t) => t.referencia.equals(referencia)))
        .get();
    if (pedidos.isEmpty) {
      throw StateError('Pedido no encontrado: $referencia');
    }
    final p = pedidos.first;
    final ahora = DateTime.now();
    final dias = _diasVigencia(p.vigenciaTipo);
    final fin = ahora.add(Duration(days: dias));

    await (_db.update(_db.pedidosLicenciaTable)
          ..where((t) => t.id.equals(p.id)))
        .write(
      const PedidosLicenciaTableCompanion(
        estado: Value('licencia_emitida'),
      ),
    );

    final id = await _db.into(_db.licenciasTable).insert(
          LicenciasTableCompanion.insert(
            plan: p.plan,
            vigenciaTipo: p.vigenciaTipo,
            fechaInicio: ahora.toIso8601String(),
            fechaFin: Value(fin.toIso8601String()),
            maxDispositivos: Value(maxInstalacionesPermitidas(p.plan)),
            maxCajas: Value(kMaxCajasPorPlan[p.plan] ?? 1),
            ecfHabilitado: Value(planIncluyeEcf(p.plan)),
            vitalicia: const Value(false),
            estado: 'activa',
            codigoActivacion: Value(referencia),
            actualizadoEn: ahora.toIso8601String(),
          ),
        );

    final row = await (_db.select(_db.licenciasTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _mapYActualizarEstado(row);
  }

  int _diasVigencia(String tipo) {
    switch (tipo) {
      case 'mensual':
        return 30;
      case 'trimestral':
        return 90;
      case 'semestral':
        return 180;
      case 'anual':
        return 365;
      case 'prueba':
        return kDiasPrueba;
      default:
        return 30;
    }
  }

  Future<int> expirarPedidosVencidos() async {
    final ahora = DateTime.now();
    final pendientes = await (_db.select(_db.pedidosLicenciaTable)
          ..where(
            (t) =>
                t.estado.equals('pendiente_pago') |
                t.estado.equals('pago_reportado'),
          ))
        .get();
    var n = 0;
    for (final p in pendientes) {
      final exp = DateTime.tryParse(p.fechaExpiracionPedido);
      if (exp != null && ahora.isAfter(exp)) {
        await (_db.update(_db.pedidosLicenciaTable)
              ..where((t) => t.id.equals(p.id)))
            .write(
          const PedidosLicenciaTableCompanion(estado: Value('expirado')),
        );
        n++;
      }
    }
    return n;
  }
}

extension on LicenciaInfo {
  LicenciaInfo copyWithEstado(String e) => LicenciaInfo(
        id: id,
        plan: plan,
        vigenciaTipo: vigenciaTipo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        maxDispositivos: maxDispositivos,
        maxCajas: maxCajas,
        ecfHabilitado: ecfHabilitado,
        vitalicia: vitalicia,
        estado: e,
        fingerprint: fingerprint,
        codigoActivacion: codigoActivacion,
      );
}
