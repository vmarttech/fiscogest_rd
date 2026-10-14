import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_config.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

class EcfeValidacionResultado {
  const EcfeValidacionResultado({required this.ok, this.errores = const []});

  factory EcfeValidacionResultado.ok() =>
      const EcfeValidacionResultado(ok: true);

  factory EcfeValidacionResultado.fallo(List<String> errores) =>
      EcfeValidacionResultado(ok: false, errores: errores);

  final bool ok;
  final List<String> errores;
}

/// Validaciones de negocio antes de construir XML.
/// No consulta DGII ni firma.
class EcfeNegocioValidator {
  static final _soloDigitos = RegExp(r'^\d+$');

  /// RNC 9 dígitos o cédula 11 dígitos (regla práctica RD).
  static bool esIdentificadorValido(String valor) {
    final v = valor.trim();
    if (!_soloDigitos.hasMatch(v)) return false;
    return v.length == 9 || v.length == 11;
  }

  EcfeValidacionResultado validarParaEncolar({
    required EcfeConfig config,
    required TipoEcf tipoEcf,
    required String rncReceptor,
    required String nombreReceptor,
    required double subtotal,
    required double itbis,
    required double total,
    required String ncfLocal,
  }) {
    final errs = <String>[];

    if (!config.habilitado) {
      errs.add('Módulo e-CF deshabilitado');
    }
    if (!config.ambiente.permiteEnvio) {
      errs.add('Ambiente no permite envío (${config.ambiente.etiqueta})');
    }
    if (!esIdentificadorValido(config.rncEmisor)) {
      errs.add('RNC emisor inválido o vacío');
    }
    if (config.razonSocialEmisor.trim().isEmpty) {
      errs.add('Razón social del emisor requerida');
    }

    const soportados = {
      TipoEcf.facturaCreditoFiscal,
      TipoEcf.facturaConsumo,
      TipoEcf.notaDebito,
      TipoEcf.notaCredito,
      TipoEcf.compras,
      TipoEcf.gastosMenores,
      TipoEcf.regimenesEspeciales,
    };
    if (!soportados.contains(tipoEcf)) {
      errs.add('Tipo e-CF ${tipoEcf.codigo} aún no soportado');
    }

    if (tipoEcf == TipoEcf.facturaCreditoFiscal) {
      if (!esIdentificadorValido(rncReceptor)) {
        errs.add('Tipo 31 requiere RNC/cédula del receptor');
      }
      if (nombreReceptor.trim().isEmpty) {
        errs.add('Tipo 31 requiere nombre del receptor');
      }
    }

    if (tipoEcf == TipoEcf.facturaConsumo && total >= 250000) {
      if (!esIdentificadorValido(rncReceptor)) {
        errs.add('Consumo desde 250000 requiere RNC o cedula del comprador');
      }
      if (nombreReceptor.trim().isEmpty) {
        errs.add('Consumo desde 250000 requiere nombre del comprador');
      }
    }
    if (subtotal < 0 || itbis < 0 || total < 0) {
      errs.add('Montos no pueden ser negativos');
    }
    if (total <= 0) {
      errs.add('Total debe ser mayor que cero');
    }
    final esperado = subtotal + itbis;
    if ((esperado - total).abs() > 0.05) {
      errs.add(
        'Inconsistencia de totales: subtotal+ITBIS ($esperado) ≠ total ($total)',
      );
    }

    final ncf = ncfLocal.trim().toUpperCase();
    if (ncf.isEmpty) {
      errs.add('NCF local vacío');
    } else if (!ncf.startsWith('B01') &&
        !ncf.startsWith('B02') &&
        !ncf.startsWith('B03') &&
        !ncf.startsWith('B04') &&
        !ncf.startsWith('B11') &&
        !ncf.startsWith('B13') &&
        !ncf.startsWith('B14')) {
      errs.add('NCF local no es B01/B02/B03/B04/B11/B13/B14: $ncf');
    }

    if (tipoEcf == TipoEcf.facturaCreditoFiscal && !ncf.startsWith('B01')) {
      errs.add('Tipo 31 debería corresponder a NCF B01');
    }
    if (tipoEcf == TipoEcf.facturaConsumo && !ncf.startsWith('B02')) {
      errs.add('Tipo 32 debería corresponder a NCF B02');
    }
    if (tipoEcf == TipoEcf.notaDebito && !ncf.startsWith('B03')) {
      errs.add('Tipo 33 debería corresponder a NCF B03');
    }
    if (tipoEcf == TipoEcf.notaCredito && !ncf.startsWith('B04')) {
      errs.add('Tipo 34 debería corresponder a NCF B04');
    }
    if (tipoEcf == TipoEcf.compras && !ncf.startsWith('B11')) {
      errs.add('Tipo 41 debería corresponder a NCF B11');
    }
    if (tipoEcf == TipoEcf.gastosMenores && !ncf.startsWith('B13')) {
      errs.add('Tipo 43 debería corresponder a NCF B13');
    }
    if (tipoEcf == TipoEcf.regimenesEspeciales && !ncf.startsWith('B14')) {
      errs.add('Tipo 44 debería corresponder a NCF B14');
    }
    if ((tipoEcf == TipoEcf.compras ||
            tipoEcf == TipoEcf.regimenesEspeciales) &&
        !esIdentificadorValido(rncReceptor)) {
      errs.add('Este comprobante requiere RNC o cédula');
    }

    if (errs.isEmpty) return EcfeValidacionResultado.ok();
    return EcfeValidacionResultado.fallo(errs);
  }
}
