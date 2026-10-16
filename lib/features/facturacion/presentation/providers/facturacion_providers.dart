import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/notas_credito_dao.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_factura_service.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_nc_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

final secuenciasNcfDaoProvider = Provider<SecuenciasNcfDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SecuenciasNcfDao(db);
});

final secuenciasNcfListProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.watch(secuenciasNcfDaoProvider);
  await dao.asegurarDefaults();
  return dao.listar();
});

final emitirFacturaServiceProvider = Provider<EmitirFacturaService>((ref) {
  return EmitirFacturaService(
    ventasRepo: ref.watch(ventasRepositoryProvider),
    secuenciasDao: ref.watch(secuenciasNcfDaoProvider),
    onPostEmision:
        ({
          required Venta venta,
          required String tipoNcf,
          required String rncCliente,
        }) async {
          try {
            final encolar = ref.read(encolarEcfeDesdeVentaProvider);
            await encolar(
              venta: venta,
              tipoNcf: tipoNcf,
              rncCliente: rncCliente,
              nombreCliente: venta.nombreCliente ?? '',
            );
            ref.invalidate(ecfeColaProvider);
          } catch (_) {}
        },
  );
});

final documentosPendientesFacturaProvider =
    FutureProvider.autoDispose<List<Venta>>((ref) async {
      final repo = ref.watch(ventasRepositoryProvider);
      final list = await repo.listarCotizaciones();
      return list.where((v) {
        final ncf = (v.numeroFactura ?? '').trim();
        final ncfFiscal =
            ncf.startsWith('B01') ||
            ncf.startsWith('B02') ||
            ncf.startsWith('B14');
        if (ncfFiscal) return false;
        // Cotizado/aprobado, o ya cobrado en Caja sin NCF DGII
        return v.estadoDocumento == EstadoDocumento.cotizado ||
            v.estadoDocumento == EstadoDocumento.aprobado ||
            v.estadoDocumento == EstadoDocumento.facturado ||
            v.estadoDocumento == EstadoDocumento.enCredito;
      }).toList();
    });

final _cuentasCobrarDaoFactProvider = Provider<CuentasCobrarDao>((ref) {
  return CuentasCobrarDao(ref.watch(databaseProvider));
});

final emitirNcServiceProvider = Provider<EmitirNcService>((ref) {
  return EmitirNcService(
    ventasRepo: ref.watch(ventasRepositoryProvider),
    secuenciasDao: ref.watch(secuenciasNcfDaoProvider),
    notasDao: ref.watch(notasCreditoDaoProvider),
    inventarioService: ref.watch(ventaInventarioServiceProvider),
    cuentasCobrarDao: ref.watch(_cuentasCobrarDaoFactProvider),
    onPostEmision:
        ({
          required Venta venta,
          required String tipoNcf,
          required String rncCliente,
        }) async {
          try {
            final encolar = ref.read(encolarEcfeDesdeVentaProvider);
            await encolar(
              venta: venta,
              tipoNcf: tipoNcf,
              rncCliente: rncCliente,
              nombreCliente: venta.nombreCliente ?? '',
            );
            ref.invalidate(ecfeColaProvider);
          } catch (_) {}
        },
  );
});

final notasCreditoDaoProvider = Provider<NotasCreditoDao>((ref) {
  final db = ref.watch(databaseProvider);
  return NotasCreditoDao(db);
});

final notasCreditoListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(notasCreditoDaoProvider).listar();
});


class FacturacionKpis {
  const FacturacionKpis({
    required this.facturasHoy,
    required this.ncHoy,
    required this.ncfDisponibles,
    required this.alertasNcf,
  });
  final int facturasHoy;
  final int ncHoy;
  final int ncfDisponibles;
  final int alertasNcf;
}

/// KPIs del hub Facturación: hoy + stock NCF.
final facturacionKpisProvider =
    FutureProvider.autoDispose<FacturacionKpis>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  final notasDao = ref.watch(notasCreditoDaoProvider);
  final seqDao = ref.watch(secuenciasNcfDaoProvider);

  await seqDao.asegurarDefaults();

  final ahora = DateTime.now();
  final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finHoy = inicioHoy.add(const Duration(days: 1));

  // Facturas hoy: ventas con NCF fiscal emitido hoy
  final ventas = await repo.listarVentas();
  final facturasHoy = ventas.where((v) {
    final ncf = (v.numeroFactura ?? '').trim();
    final tieneNcf = ncf.startsWith('B01') ||
        ncf.startsWith('B02') ||
        ncf.startsWith('B14') ||
        ncf.startsWith('E');
    if (!tieneNcf && v.estadoDocumento != EstadoDocumento.facturado) {
      return false;
    }
    final f = v.fecha;
    return !f.isBefore(inicioHoy) && f.isBefore(finHoy);
  }).length;

  // NC hoy
  final notas = await notasDao.listar();
  final ncHoy = notas.where((n) {
    final f = n.creadoEn;
    return !f.isBefore(inicioHoy) && f.isBefore(finHoy);
  }).length;

  // NCF disponibles: solo rangos realmente asignados (no defaults del sistema)
  final secuencias = await seqDao.listar();
  var ncfDisponibles = 0;
  var alertas = 0;
  const umbralAlerta = 100;
  for (final s in secuencias) {
    if (!s.activo) continue;
    // Tope del sistema (asegurarDefaults) = sin rango DGII asignado por el negocio
    if (s.secuenciaHasta >= 99999999) continue;
    final rest = s.secuenciaHasta - s.secuenciaActual;
    if (rest > 0) ncfDisponibles += rest;
    if (rest <= umbralAlerta) alertas += 1;
  }

  return FacturacionKpis(
    facturasHoy: facturasHoy,
    ncHoy: ncHoy,
    ncfDisponibles: ncfDisponibles,
    alertasNcf: alertas,
  );
});

