import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xml_builder.dart';
import 'package:fiscogest_rd/features/e_cf/domain/value_objects/ecfe_payload.dart';
import 'package:xml/xml.dart';

class EcfeXmlBuilderImpl implements EcfeXmlBuilder {
  @override
  Future<String> construir(
    EcfeDocumento doc,
    Map<String, dynamic> payloadNegocio,
  ) async {
    final payload = payloadNegocio['payload'];
    if (payload is! EcfePayload) {
      throw StateError('payloadNegocio["payload"] debe ser EcfePayload');
    }
    return construirDesdePayload(payload);
  }

  String construirDesdePayload(EcfePayload p) {
    if (p.esRfce) return _buildRfce(p);
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'ECF',
      nest: () {
        builder.element(
          'Encabezado',
          nest: () {
            builder.element('Version', nest: '1.0');
            builder.element(
              'IdDoc',
              nest: () {
                builder.element('TipoeCF', nest: p.tipoEcfCodigo.toString());
                builder.element('eNCF', nest: p.encf);
                if (p.tipoEcfCodigo != 34) {
                  builder.element(
                    'FechaVencimientoSecuencia',
                    nest: p.fechaVencimientoSecuencia,
                  );
                }
                if (p.tipoEcfCodigo == 34) {
                  builder.element(
                    'IndicadorNotaCredito',
                    nest: p.indicadorNotaCredito,
                  );
                }
                builder.element('IndicadorMontoGravado', nest: '0');
                if (p.tipoEcfCodigo != 41 && p.tipoEcfCodigo != 43) {
                  builder.element('TipoIngresos', nest: p.tipoIngresos);
                }
                builder.element('TipoPago', nest: p.tipoPago);
                if (p.tipoPago == '2' && p.fechaLimitePago.trim().isNotEmpty) {
                  builder.element('FechaLimitePago', nest: p.fechaLimitePago);
                }
                builder.element(
                  'TablaFormasPago',
                  nest: () {
                    builder.element(
                      'FormaDePago',
                      nest: () {
                        builder.element('FormaPago', nest: p.formaPagoCodigo);
                        builder.element(
                          'MontoPago',
                          nest: _money(p.montoPago ?? p.montoTotal),
                        );
                      },
                    );
                  },
                );
              },
            );
            builder.element(
              'Emisor',
              nest: () {
                builder.element('RNCEmisor', nest: p.rncEmisor);
                builder.element(
                  'RazonSocialEmisor',
                  nest: _safe(p.razonSocialEmisor),
                );
                builder.element(
                  'DireccionEmisor',
                  nest: _safe(p.direccionEmisor),
                );
                if ((p.telefonoEmisor ?? '').isNotEmpty) {
                  builder.element(
                    'TablaTelefonoEmisor',
                    nest: () {
                      builder.element(
                        'TelefonoEmisor',
                        nest: p.telefonoEmisor!,
                      );
                    },
                  );
                }
                if ((p.correoEmisor ?? '').isNotEmpty) {
                  builder.element('CorreoEmisor', nest: p.correoEmisor!);
                }
                builder.element('FechaEmision', nest: p.fechaEmision);
              },
            );
            if (p.tipoEcfCodigo != 43) {
              builder.element(
                'Comprador',
                nest: () {
                  if ((p.rncComprador ?? '').isNotEmpty) {
                    builder.element('RNCComprador', nest: p.rncComprador!);
                  }
                  builder.element(
                    'RazonSocialComprador',
                    nest: _safe(
                      (p.razonSocialComprador ?? '').isEmpty
                          ? 'CONSUMIDOR FINAL'
                          : p.razonSocialComprador!,
                    ),
                  );
                  if ((p.direccionComprador ?? '').isNotEmpty) {
                    builder.element(
                      'DireccionComprador',
                      nest: _safe(p.direccionComprador!),
                    );
                  }
                },
              );
            }
            builder.element(
              'Totales',
              nest: () {
                builder.element(
                  'MontoGravadoTotal',
                  nest: _money(p.montoGravadoTotal),
                );
                final g1 = p.bandasItbis
                    ? p.montoGravadoI1
                    : p.montoGravadoTotal;
                final i1 = p.bandasItbis ? p.totalItbis1 : p.totalItbis;
                final tasa1 = p.bandasItbis ? 18.0 : p.tasaItbis;
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('MontoGravadoI1', nest: _money(g1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element(
                    'MontoGravadoI2',
                    nest: _money(p.montoGravadoI2),
                  );
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element(
                    'MontoGravadoI3',
                    nest: _money(p.montoGravadoI3),
                  );
                }
                if (p.bandasItbis && p.montoExento > 0.004) {
                  builder.element('MontoExento', nest: _money(p.montoExento));
                }
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('ITBIS1', nest: _rate(tasa1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element('ITBIS2', nest: _rate(16));
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element('ITBIS3', nest: _rate(0));
                }
                builder.element('TotalITBIS', nest: _money(p.totalItbis));
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('TotalITBIS1', nest: _money(i1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element('TotalITBIS2', nest: _money(p.totalItbis2));
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element('TotalITBIS3', nest: _money(p.totalItbis3));
                }
                builder.element('MontoTotal', nest: _money(p.montoTotal));
              },
            );
          },
        );
        builder.element(
          'DetallesItems',
          nest: () {
            for (final it in p.items) {
              builder.element(
                'Item',
                nest: () {
                  builder.element(
                    'NumeroLinea',
                    nest: it.numeroLinea.toString(),
                  );
                  builder.element(
                    'IndicadorFacturacion',
                    nest: it.indicadorFacturacion,
                  );
                  builder.element('NombreItem', nest: _safe(it.nombreItem));
                  builder.element(
                    'IndicadorBienoServicio',
                    nest: it.indicadorBienoServicio,
                  );
                  builder.element('CantidadItem', nest: _qty(it.cantidad));
                  builder.element(
                    'UnidadMedida',
                    nest: _unidadDgii(it.unidadMedida),
                  );
                  builder.element(
                    'PrecioUnitarioItem',
                    nest: _money(it.precioUnitario),
                  );
                  builder.element('MontoItem', nest: _money(it.montoItem));
                },
              );
            }
          },
        );
        if (p.tipoEcfCodigo == 33 || p.tipoEcfCodigo == 34) {
          builder.element(
            'InformacionReferencia',
            nest: () {
              builder.element(
                'NCFModificado',
                nest: (p.encfReferencia ?? '').trim(),
              );
              builder.element('FechaNCFModificado', nest: p.fechaNcfModificado);
              builder.element('CodigoModificacion', nest: p.codigoModificacion);
            },
          );
        }
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }

  String _unidadDgii(String raw) {
    final t = raw.trim();
    if (RegExp(r'^\d{1,2}$').hasMatch(t)) return t;
    return '43';
  }

  static String _money(double v) => v.toStringAsFixed(2);
  static String _qty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  static String _rate(double v) => v.toStringAsFixed(2);

  static String _safe(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _buildRfce(EcfePayload p) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'RFCE',
      nest: () {
        builder.element(
          'Encabezado',
          nest: () {
            builder.element('Version', nest: '1.0');
            builder.element(
              'IdDoc',
              nest: () {
                builder.element('TipoeCF', nest: p.tipoEcfCodigo.toString());
                builder.element('eNCF', nest: p.encf);
                if (p.tipoEcfCodigo != 41 && p.tipoEcfCodigo != 43) {
                  builder.element('TipoIngresos', nest: p.tipoIngresos);
                }
                builder.element('TipoPago', nest: p.tipoPago);
                if (p.tipoPago == '2' && p.fechaLimitePago.trim().isNotEmpty) {
                  builder.element('FechaLimitePago', nest: p.fechaLimitePago);
                }
              },
            );
            builder.element(
              'Emisor',
              nest: () {
                builder.element('RNCEmisor', nest: p.rncEmisor);
                builder.element(
                  'RazonSocialEmisor',
                  nest: _safe(p.razonSocialEmisor),
                );
                builder.element('FechaEmision', nest: p.fechaEmision);
              },
            );
            if ((p.rncComprador ?? '').isNotEmpty) {
              builder.element('RNCComprador', nest: p.rncComprador!);
            }

            builder.element(
              'Totales',
              nest: () {
                builder.element(
                  'MontoGravadoTotal',
                  nest: _money(p.montoGravadoTotal),
                );
                final g1 = p.bandasItbis
                    ? p.montoGravadoI1
                    : p.montoGravadoTotal;
                final i1 = p.bandasItbis ? p.totalItbis1 : p.totalItbis;
                final tasa1 = p.bandasItbis ? 18.0 : p.tasaItbis;
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('MontoGravadoI1', nest: _money(g1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element(
                    'MontoGravadoI2',
                    nest: _money(p.montoGravadoI2),
                  );
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element(
                    'MontoGravadoI3',
                    nest: _money(p.montoGravadoI3),
                  );
                }
                if (p.bandasItbis && p.montoExento > 0.004) {
                  builder.element('MontoExento', nest: _money(p.montoExento));
                }
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('ITBIS1', nest: _rate(tasa1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element('ITBIS2', nest: _rate(16));
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element('ITBIS3', nest: _rate(0));
                }
                builder.element('TotalITBIS', nest: _money(p.totalItbis));
                if (!p.bandasItbis || g1 > 0.004) {
                  builder.element('TotalITBIS1', nest: _money(i1));
                }
                if (p.bandasItbis && p.montoGravadoI2 > 0.004) {
                  builder.element('TotalITBIS2', nest: _money(p.totalItbis2));
                }
                if (p.bandasItbis && p.montoGravadoI3 > 0.004) {
                  builder.element('TotalITBIS3', nest: _money(p.totalItbis3));
                }
                builder.element('MontoTotal', nest: _money(p.montoTotal));
              },
            );
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }
}
