import 'package:url_launcher/url_launcher.dart';
import 'package:fiscogest_rd/features/creditos/domain/usecases/enviar_recordatorio_whatsapp.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';

/// Servicio comercial de cobranza amigable por WhatsApp.
///
/// - Usa el WhatsApp instalado en el dispositivo del comercio.
/// - El destinatario es el teléfono del cliente (CxC o fiao).
class RecordatorioWhatsAppService {
  RecordatorioWhatsAppService({
    required IClienteRepository clienteRepository,
    EnviarRecordatorioWhatsApp? useCase,
  })  : _clientes = clienteRepository,
        _useCase = useCase ?? const EnviarRecordatorioWhatsApp();

  final IClienteRepository _clientes;
  final EnviarRecordatorioWhatsApp _useCase;

  String _nombreNegocio(ConfiguracionEntity? empresa) {
    if (empresa == null) return 'nuestro negocio';
    if (empresa.nombreComercial.trim().isNotEmpty) {
      return empresa.nombreComercial.trim();
    }
    if (empresa.razonSocial.trim().isNotEmpty) {
      return empresa.razonSocial.trim();
    }
    return 'nuestro negocio';
  }

  /// Abre WhatsApp con el recordatorio de una cuenta por cobrar formal.
  Future<void> enviarDesdeCuenta({
    required CuentaPorCobrar cuenta,
    required ConfiguracionEntity? empresa,
    String? telefonoOverride,
  }) async {
    var telefono = telefonoOverride?.trim() ?? '';
    if (telefono.isEmpty) {
      final cliente = await _clientes.obtenerClientePorId(cuenta.clienteId);
      telefono = cliente?.telefono.trim() ?? '';
    }
    if (telefono.isEmpty) {
      throw StateError(
        'Este cliente no tiene teléfono registrado. '
        'Agrégalo en Clientes y vuelve a intentar.',
      );
    }

    final resultado = _useCase.preparar(
      telefonoCliente: telefono,
      nombreCliente: cuenta.clienteNombre ?? 'Cliente',
      nombreNegocio: _nombreNegocio(empresa),
      saldoPendiente: cuenta.saldoPendiente,
      numeroCuenta: cuenta.numero ?? (cuenta.id != null ? 'CXC-${cuenta.id}' : null),
    );

    await _lanzar(resultado.uri);
  }

  /// Abre WhatsApp para un fiao informal (requiere teléfono explícito).
  Future<void> enviarDesdeFiao({
    required String nombreCliente,
    required double saldoPendiente,
    required String telefonoCliente,
    required ConfiguracionEntity? empresa,
    String? nota,
  }) async {
    final resultado = _useCase.preparar(
      telefonoCliente: telefonoCliente,
      nombreCliente: nombreCliente,
      nombreNegocio: _nombreNegocio(empresa),
      saldoPendiente: saldoPendiente,
      notaExtra: nota,
    );
    await _lanzar(resultado.uri);
  }

  Future<void> _lanzar(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw StateError(
        'No se pudo abrir WhatsApp. Verifique que esté instalado.',
      );
    }
  }
}
