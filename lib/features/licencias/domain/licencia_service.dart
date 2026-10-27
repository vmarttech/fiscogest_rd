import 'dart:math';

import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:fiscogest_rd/core/sync/supabase/licencia_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

class LicenciaService {
  LicenciaService(this._db);

  final AppDatabase _db;
  final _rng = Random.secure();

  /// Crea demo 15 días si no existe ninguna licencia.
  Future<LicenciaInfo> ensureLicenciaInicial() async {
    final rows = await _db.select(_db.licenciasTable).get();
    if (rows.isNotEmpty) {
      rows.sort((a, b) => b.id.compareTo(a.id));
      final dev = rows.where((r) => r.plan == 'desarrollador' || r.vitalicia);
      final row = dev.isNotEmpty ? dev.first : rows.first;
      return _mapYActualizarEstado(row);
    }
    // Equipo vacío pero negocio ya vinculado (reinstalación): restaurar desde nube
    if (SupabaseConfig.isConfigured) {
      final nid = await NegocioLocal.getId();
      if (nid != null && nid.isNotEmpty) {
        try {
          final ok = await LicenciaSync(_db).pullDesdeNegocio();
          if (ok) {
            final after = await obtenerActual();
            if (after != null) return after;
          }
        } catch (e) {
          // ignore: avoid_print
          print('ensureLicenciaInicial pull: $e');
        }
      }
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

  /// Licencia de plataforma para cuenta de desarrollador autorizado.
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

    // Demo o plan de pago vencido (tras gracia) → gratis automático
    // (cancelar solo evita renovar; al llegar fechaFin también cae aquí)
    final planLow = row.plan.toLowerCase();
    final esPagoVencido = planLow == 'basico' ||
        planLow == 'simplificado' ||
        planLow == 'pro' ||
        planLow == 'profesional' ||
        planLow == 'empresa';
    if ((planLow == 'demo' || esPagoVencido) && nuevoEstado == 'vencida') {
      final ahora = DateTime.now();
      await (_db.update(_db.licenciasTable)..where((t) => t.id.equals(row.id)))
          .write(
        LicenciasTableCompanion(
          plan: const Value('gratis'),
          vigenciaTipo: const Value('permanente_limitada'),
          fechaFin: const Value(null),
          vitalicia: const Value(false),
          maxDispositivos: const Value(1),
          maxCajas: const Value(1),
          ecfHabilitado: const Value(false),
          estado: const Value('activa'),
          actualizadoEn: Value(ahora.toIso8601String()),
        ),
      );
      final updated = await (_db.select(_db.licenciasTable)
            ..where((t) => t.id.equals(row.id)))
          .getSingle();
      return _fromRow(updated);
    }

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


  /// Crea el pedido ya como licencia_emitida y emite la licencia.
  /// Solo debe llamarse DESPUÉS de que PayPal confirme el capture (COMPLETED).
  Future<LicenciaInfo> crearPedidoTrasPagoExitoso({
    required String referencia,
    required String plan,
    required String vigenciaTipo,
    String? medioPreferido,
  }) async {
    final monto = precioMensualUsd(plan) ??
        precioPlanVigencia(plan, vigenciaTipo);
    if (monto == null) {
      throw ArgumentError('Plan/vigencia no tarifados: $plan / $vigenciaTipo');
    }

    final ahora = DateTime.now();

    await _db.into(_db.pedidosLicenciaTable).insert(
          PedidosLicenciaTableCompanion.insert(
            referencia: referencia,
            plan: plan,
            vigenciaTipo: vigenciaTipo,
            monto: monto,
            estado: 'licencia_emitida',
            fechaCreacion: ahora.toIso8601String(),
            fechaExpiracionPedido: ahora
                .add(const Duration(days: kDiasExpiracionPedido))
                .toIso8601String(),
            medioPagoPreferido: Value(medioPreferido),
          ),
        );

    return marcarPagadoYEmitirLicencia(referencia);
  }

  Future<String> crearPedido({
    required String plan,
    required String vigenciaTipo,
    String? negocioNombre,
    String? rnc,
    String? medioPreferido,
  }) async {
    // Móvil automático: USD; si no, tarifa DOP legacy.
    final monto = precioMensualUsd(plan) ??
        precioPlanVigencia(plan, vigenciaTipo);
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

  /// Cliente: solo aplica licencia si el pedido YA está en licencia_emitida
  /// (aprobado por la plataforma). No cambia el estado del pedido.
  Future<LicenciaInfo> aplicarLicenciaSiYaEmitida(String referencia) async {
    final refCode = referencia.trim().toUpperCase();
    final rows = await (_db.select(_db.pedidosLicenciaTable)
          ..where((t) => t.referencia.equals(refCode)))
        .get();
    if (rows.isEmpty) {
      throw Exception(
        'Referencia no encontrada. Sincronice o verifique el código FG-.',
      );
    }
    final p = rows.first;
    if (p.estado != 'licencia_emitida') {
      throw Exception(
        'Esta referencia aún no está autorizada por la plataforma. '
        'Estado: ${p.estado}.',
      );
    }

    // Ya aplicada con este código → devolver actual
    final existentes = await (_db.select(_db.licenciasTable)
          ..where((t) => t.codigoActivacion.equals(refCode)))
        .get();
    if (existentes.isNotEmpty) {
      return _mapYActualizarEstado(existentes.first);
    }

    final ahora = DateTime.now();
    final dias = _diasVigencia(p.vigenciaTipo);
    final fin = ahora.add(Duration(days: dias));
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
            codigoActivacion: Value(refCode),
            actualizadoEn: ahora.toIso8601String(),
          ),
        );
    final row = await (_db.select(_db.licenciasTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _mapYActualizarEstado(row);
  }

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


  /// Cancela la renovación: el plan de pago sigue hasta fechaFin.
  /// Al vencer (tras gracia), [ _mapYActualizarEstado ] debe pasar a gratis.
  /// No acorta el periodo ya pagado.
  Future<LicenciaInfo> cancelarPlanPagado() async {
    final actual = await obtenerActual();
    if (actual == null) {
      throw StateError('No hay licencia activa');
    }
    if (actual.esDesarrollador) {
      throw StateError('La licencia de desarrollador no se cancela aquí');
    }
    final plan = actual.plan.toLowerCase();
    if (plan == 'gratis' || plan == 'demo') {
      throw StateError('No hay plan de pago que cancelar');
    }
    // Marca en notas/estado: no renovar. Mantiene fechaFin y plan actual.
    final ahora = DateTime.now().toIso8601String();
    await (_db.update(_db.licenciasTable)
          ..where((t) => t.id.equals(actual.id)))
        .write(
      LicenciasTableCompanion(
        // vigenciaTipo especial para saber que no debe renovarse
        vigenciaTipo: const Value('mensual_cancelada'),
        actualizadoEn: Value(ahora),
      ),
    );
    final row = await (_db.select(_db.licenciasTable)
          ..where((t) => t.id.equals(actual.id)))
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
