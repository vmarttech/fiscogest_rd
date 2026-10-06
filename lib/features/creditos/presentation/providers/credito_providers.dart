import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';
import 'package:fiscogest_rd/features/creditos/domain/repositories/i_solicitud_credito_repository.dart';
import 'package:fiscogest_rd/features/creditos/data/repositories/solicitud_credito_repository_impl.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/solicitud_credito_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/parametros_credito_dao.dart';
import 'package:fiscogest_rd/features/creditos/data/repositories/cuenta_por_cobrar_repository_impl.dart';
import 'package:fiscogest_rd/features/creditos/data/services/credito_documento_service_impl.dart';
import 'package:fiscogest_rd/features/creditos/domain/repositories/i_cuenta_por_cobrar_repository.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/i_credito_documento_service.dart';

final cuentasCobrarDaoCreditoProvider = Provider<CuentasCobrarDao>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return CuentasCobrarDao(db);
});

final cuentaPorCobrarRepositoryProvider = Provider<ICuentaPorCobrarRepository>((
  ref,
) {
  final dao = ref.watch(cuentasCobrarDaoCreditoProvider);
  return CuentaPorCobrarRepositoryImpl(dao);
});

final parametrosCreditoDaoProvider = Provider<ParametrosCreditoDao>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return ParametrosCreditoDao(db);
});

final parametrosCreditoProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.watch(parametrosCreditoDaoProvider);
  return dao.obtenerOCrear();
});

final creditoDocumentoServiceProvider =
    FutureProvider.autoDispose<ICreditoDocumentoService>((ref) async {
      final params = await ref.watch(parametrosCreditoProvider.future);
      final empresa =
          ref.watch(configuracionControllerProvider).valueOrNull;
      return CreditoDocumentoServiceImpl(
        empresa: empresa,
        plantillaSolicitudExtra: params.plantillaSolicitud,
        plantillaContratoExtra: params.plantillaContrato,
      );
    });

final solicitudCreditoDaoProvider = Provider<SolicitudCreditoDao>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return SolicitudCreditoDao(db);
});

final solicitudCreditoRepositoryProvider =
    Provider<ISolicitudCreditoRepository>((ref) {
      return SolicitudCreditoRepositoryImpl(
        ref.watch(solicitudCreditoDaoProvider),
        ref.watch(clienteRepositoryProvider),
      );
    });

final expedienteCreditoPorVentaProvider = FutureProvider.autoDispose
    .family<
      SolicitudCreditoExpediente,
      ({int ventaId, String nombre, int? clienteId})
    >((ref, args) async {
      final repo = ref.watch(solicitudCreditoRepositoryProvider);
      return repo.obtenerOCrearPorVenta(
        ventaId: args.ventaId,
        nombreInicial: args.nombre,
        clienteId: args.clienteId,
      );
    });
