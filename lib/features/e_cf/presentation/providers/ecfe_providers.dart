import 'package:fiscogest_rd/features/e_cf/domain/services/certificado_info_service.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_spec_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/e_cf/application/encolar_desde_venta.dart';
import 'package:fiscogest_rd/features/e_cf/application/generar_xml_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/firmar_xml_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/enviar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_estado_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/ecfe_stubs.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_secuencia_service.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_xml_builder_impl.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_xsd_validator_impl.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_config.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_negocio_validator.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_pipeline.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

final ecfeRepositoryProvider = Provider<EcfeRepository>((ref) {
  return EcfeRepository(ref.watch(databaseProvider));
});

final ecfeHabilitadoProvider = FutureProvider.autoDispose<bool>((ref) async {
  final cfg = await ref.watch(ecfeRepositoryProvider).obtenerConfig();
  return cfg.listoParaPipeline;
});

final ecfeConfigProvider =
    FutureProvider.autoDispose<EcfeConfig>((ref) async {
  return ref.watch(ecfeRepositoryProvider).obtenerConfig();
});

final ecfeColaProvider =
    FutureProvider.autoDispose<List<EcfeDocumento>>((ref) async {
  return ref.watch(ecfeRepositoryProvider).listarDocumentos();
});

final ecfeDocumentoProvider =
    FutureProvider.autoDispose.family<EcfeDocumento?, int>((ref, id) async {
  return ref.watch(ecfeRepositoryProvider).obtenerPorId(id);
});

final ecfeEventosProvider = FutureProvider.autoDispose
    .family<List<({String paso, bool ok, String? detalle, DateTime creadoEn})>,
        int>((ref, id) async {
  return ref.watch(ecfeRepositoryProvider).listarEventos(id);
});

final ecfeSecuenciaServiceProvider = Provider<EcfeSecuenciaService>((ref) {
  return EcfeSecuenciaService(ref.watch(databaseProvider));
});

final generarXmlEcfeProvider = Provider<GenerarXmlEcfe>((ref) {
  return GenerarXmlEcfe(
    repo: ref.watch(ecfeRepositoryProvider),
    secuencias: ref.watch(ecfeSecuenciaServiceProvider),
    builder: EcfeXmlBuilderImpl(),
  );
});

final ecfePipelineProvider = Provider<EcfePipeline>((ref) {
  return EcfePipeline(
    xmlBuilder: EcfeXmlBuilderImpl(),
    xsdValidator: EcfeXsdValidatorImpl(),
    signer: StubEcfeSigner(),
    recepcion: StubDgiiRecepcionGateway(),
    consulta: StubDgiiConsultaGateway(),
  );
});

final encolarEcfeDesdeVentaProvider = Provider<EncolarEcfeDesdeVenta>((ref) {
  return EncolarEcfeDesdeVenta(
    repo: ref.watch(ecfeRepositoryProvider),
    validator: EcfeNegocioValidator(),
  );
});

Future<void> intentarEncolarEcfe({
  required WidgetRef ref,
  required Venta venta,
  required String tipoNcf,
  required String rncCliente,
  required String nombreCliente,
}) async {
  try {
    final encolar = ref.read(encolarEcfeDesdeVentaProvider);
    await encolar(
      venta: venta,
      tipoNcf: tipoNcf,
      rncCliente: rncCliente,
      nombreCliente: nombreCliente,
    );
    ref.invalidate(ecfeColaProvider);
  } catch (_) {}
}


final firmarXmlEcfeProvider = Provider<FirmarXmlEcfe>((ref) {
  return FirmarXmlEcfe(repo: ref.watch(ecfeRepositoryProvider));
});


final enviarEcfeProvider = Provider<EnviarEcfe>((ref) {
  return EnviarEcfe(repo: ref.watch(ecfeRepositoryProvider));
});

final consultarEstadoEcfeProvider = Provider<ConsultarEstadoEcfe>((ref) {
  return ConsultarEstadoEcfe(repo: ref.watch(ecfeRepositoryProvider));
});


final ecfePorVentaProvider =
    FutureProvider.autoDispose.family<EcfeDocumento?, int>((ref, ventaId) async {
  final repo = ref.watch(ecfeRepositoryProvider);
  return repo.buscarPorVentaId(ventaId);
});

final ecfeSpecVersionsProvider =
    FutureProvider.autoDispose<List<EcfeSpecVersion>>((ref) async {
  final repo = ref.watch(ecfeRepositoryProvider);
  await repo.asegurarSpecDefault();
  return repo.listarSpecVersions();
});

final ecfeSpecPorIdProvider =
    FutureProvider.autoDispose.family<EcfeSpecVersion?, int>((ref, id) async {
  return ref.watch(ecfeRepositoryProvider).obtenerSpecPorId(id);
});

final ecfeSecuenciasProvider =
    FutureProvider.autoDispose<List<EcfeSecuenciaInfo>>((ref) async {
  final svc = ref.watch(ecfeSecuenciaServiceProvider);
  await svc.asegurarTiposBase();
  return svc.listar();
});

final certificadoInfoProvider =
    FutureProvider.autoDispose<CertificadoInfo?>((ref) async {
  final cfg = await ref.watch(ecfeConfigProvider.future);
  if (cfg.rutaCertificado.trim().isEmpty) return null;
  return CertificadoInfoService.inspeccionar(
    ruta: cfg.rutaCertificado,
    clave: cfg.claveCertificado,
  );
});
