/// Estados de una cuenta por cobrar / crédito / fiao
/// Según manual sección 6: solamente 4 estados
enum EstadoCredito {
  /// Dentro del plazo, sin atrasos
  alDia,

  /// Próximo a vencer (ej: faltan 3 días o menos)
  proximoAVencer,

  /// Pasó la fecha de vencimiento
  vencido,

  /// Saldo pendiente = 0
  pagado,
}

extension EstadoCreditoExtension on EstadoCredito {
  String get nombre {
    switch (this) {
      case EstadoCredito.alDia:
        return 'Al día';
      case EstadoCredito.proximoAVencer:
        return 'Próximo a vencer';
      case EstadoCredito.vencido:
        return 'Vencido';
      case EstadoCredito.pagado:
        return 'Pagado';
    }
  }

  String get clave {
    switch (this) {
      case EstadoCredito.alDia:
        return 'AL_DIA';
      case EstadoCredito.proximoAVencer:
        return 'PROXIMO_A_VENCER';
      case EstadoCredito.vencido:
        return 'VENCIDO';
      case EstadoCredito.pagado:
        return 'PAGADO';
    }
  }

  static EstadoCredito desdeClave(String? clave) {
    switch (clave) {
      case 'AL_DIA':
        return EstadoCredito.alDia;
      case 'PROXIMO_A_VENCER':
        return EstadoCredito.proximoAVencer;
      case 'VENCIDO':
        return EstadoCredito.vencido;
      case 'PAGADO':
        return EstadoCredito.pagado;
      default:
        return EstadoCredito.alDia;
    }
  }
}
