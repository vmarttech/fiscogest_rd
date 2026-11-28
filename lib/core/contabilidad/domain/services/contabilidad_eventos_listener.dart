import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/repositories/i_plan_cuentas_repository.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/motor_partida_doble.dart';
import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';

/// Asientos automáticos por eventos. Códigos vía plantilla del país activo.
class ContabilidadEventosListener {
  ContabilidadEventosListener({
    required MotorPartidaDoble motor,
    required IPlanCuentasRepository planCuentas,
  })  : _motor = motor,
        _plan = planCuentas {
    _registrarEscuchas();
    debugPrint(
      'ContabilidadEventosListener: país=${ContabilidadPaisConfig.paisCodigo}',
    );
  }

  final MotorPartidaDoble _motor;
  final IPlanCuentasRepository _plan;

  PlantillaContrapartida get _plantilla => ContabilidadPaisConfig.plantilla;

  void _registrarEscuchas() {
    EventoBus.escuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
    EventoBus.escuchar(EventosSistema.ventaConfirmada, _alConfirmarVenta);
  }

  Future<void> _alConfirmarCompra(Map<String, dynamic> datos) async {
    final compraId = _asInt(datos['compraId']);
    if (compraId == null) return;

    final neto = _asCents(datos, 'montoNetoCents', 'montoNeto');
    final impuesto = _asCents(datos, 'itbisCents', 'itbis') ??
        _asCents(datos, 'impuestoCents', 'impuesto') ??
        0;
    final total = _asCents(datos, 'totalCents', 'total') ??
        (neto == null ? null : neto + impuesto);

    if (neto == null || total == null || total <= 0) {
      debugPrint('Contabilidad → Compra $compraId: faltan montos. Omitido.');
      return;
    }

    try {
      final inv = await _idPorRol(CuentaRol.inventario);
      final prov = await _idPorRol(CuentaRol.cxp);
      final impCred = impuesto > 0 ? await _idPorRol(CuentaRol.impuestoCredito) : null;

      final lineas = <LineaAsiento>[
        LineaAsiento(cuentaId: inv, debeCents: neto, concepto: 'Inventario compra #$compraId'),
        if (impuesto > 0 && impCred != null)
          LineaAsiento(
            cuentaId: impCred,
            debeCents: impuesto,
            concepto: '${_plantilla.etiquetaImpuesto} crédito compra #$compraId',
          ),
        LineaAsiento(cuentaId: prov, haberCents: total, concepto: 'CxP compra #$compraId'),
      ];

      final ahora = DateTime.now();
      final reg = await _motor.registrar(
        asiento: AsientoContable(
          numeroAsiento: '',
          fecha: ahora,
          concepto: 'Compra confirmada #$compraId',
          estado: EstadoAsiento.borrador,
          documentoOrigen: 'compra:$compraId',
          tipoOrigen: 'compra',
          referenciaId: compraId,
          creadoEn: ahora,
        ),
        lineas: lineas,
      );
      debugPrint('Contabilidad → Compra $compraId asiento ${reg.numeroAsiento} OK');
    } catch (e, st) {
      debugPrint('Contabilidad → Error asiento compra $compraId: $e\n$st');
    }
  }

  Future<void> _alConfirmarVenta(Map<String, dynamic> datos) async {
    final ventaId = _asInt(datos['ventaId']);
    if (ventaId == null) return;

    final neto = _asCents(datos, 'montoNetoCents', 'montoNeto');
    final impuesto = _asCents(datos, 'itbisCents', 'itbis') ??
        _asCents(datos, 'impuestoCents', 'impuesto') ??
        0;
    final total = _asCents(datos, 'totalCents', 'total') ??
        (neto == null ? null : neto + impuesto);
    final costo = _asCents(datos, 'costoCents', 'costo') ?? 0;
    final contado = datos['contado'] == true || datos['formaPago'] == 'contado';

    if (neto == null || total == null || total <= 0) {
      debugPrint('Contabilidad → Venta $ventaId: faltan montos. Omitido.');
      return;
    }

    try {
      final cajaOCxc = await _idPorRol(contado ? CuentaRol.caja : CuentaRol.cxc);
      final ingresos = await _idPorRol(CuentaRol.ingresosVentas);
      final impPagar = impuesto > 0 ? await _idPorRol(CuentaRol.impuestoPorPagar) : null;

      final lineas = <LineaAsiento>[
        LineaAsiento(
          cuentaId: cajaOCxc,
          debeCents: total,
          concepto: contado ? 'Cobro venta #$ventaId' : 'CxC venta #$ventaId',
        ),
        LineaAsiento(
          cuentaId: ingresos,
          haberCents: neto,
          concepto: 'Ingreso venta #$ventaId',
        ),
        if (impuesto > 0 && impPagar != null)
          LineaAsiento(
            cuentaId: impPagar,
            haberCents: impuesto,
            concepto: '${_plantilla.etiquetaImpuesto} venta #$ventaId',
          ),
      ];

      // Costo de venta: Debe costoVentas / Haber inventario
      if (costo > 0) {
        final cogs = await _idPorRol(CuentaRol.costoVentas);
        final inv = await _idPorRol(CuentaRol.inventario);
        lineas.addAll([
          LineaAsiento(
            cuentaId: cogs,
            debeCents: costo,
            concepto: 'Costo venta #$ventaId',
          ),
          LineaAsiento(
            cuentaId: inv,
            haberCents: costo,
            concepto: 'Salida inventario venta #$ventaId',
          ),
        ]);
      }

      final ahora = DateTime.now();
      final reg = await _motor.registrar(
        asiento: AsientoContable(
          numeroAsiento: '',
          fecha: ahora,
          concepto: 'Venta confirmada #$ventaId',
          estado: EstadoAsiento.borrador,
          documentoOrigen: 'venta:$ventaId',
          tipoOrigen: 'venta',
          referenciaId: ventaId,
          creadoEn: ahora,
        ),
        lineas: lineas,
      );
      debugPrint('Contabilidad → Venta $ventaId asiento ${reg.numeroAsiento} OK');
    } catch (e, st) {
      debugPrint('Contabilidad → Error asiento venta $ventaId: $e\n$st');
    }
  }

  Future<int> _idPorRol(CuentaRol rol) async {
    final codigo = _plantilla.codigo(rol);
    final c = await _plan.obtenerPorCodigo(codigo);
    if (c == null || !c.esValidaParaMovimiento) {
      throw StateError('acct_error_account_code_missing:$codigo (${rol.name})');
    }
    return c.id;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _asCents(Map<String, dynamic> datos, String keyCents, String keyDouble) {
    final c = datos[keyCents];
    if (c is int) return c;
    if (c is String) return int.tryParse(c);
    final d = datos[keyDouble];
    if (d is num) return (d * 100).round();
    if (d is String) {
      final v = double.tryParse(d);
      if (v != null) return (v * 100).round();
    }
    return null;
  }

  void dispose() {
    EventoBus.dejarDeEscuchar(EventosSistema.compraConfirmada, _alConfirmarCompra);
    EventoBus.dejarDeEscuchar(EventosSistema.ventaConfirmada, _alConfirmarVenta);
  }
}
