import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';

/// Interfaz abstracta del repositorio de Cuentas por Cobrar
/// Según manual: registrar, listar, abonar, filtrar, obtener resúmenes
abstract class ICuentaPorCobrarRepository {
  /// Registra una nueva cuenta por cobrar con su plan de pagos y abono inicial
  /// Devuelve el ID generado
  Future<int> registrarCredito({
    required CuentaPorCobrar cuenta,
    PlanPago? planPago,
    AbonoCredito? abonoInicial,
  });

  /// Obtiene una cuenta completa por su ID
  Future<CuentaPorCobrar?> obtenerPorId(int cuentaId);

  /// Lista todas las cuentas con filtros opcionales
  /// Según manual sección 10: filtros por estado, cliente, fecha, vencimiento, monto
  Future<List<CuentaPorCobrar>> listarCuentas({
    EstadoCredito? estado,
    int? clienteId,
    DateTime? desde,
    DateTime? hasta,
    DateTime? venceDesde,
    DateTime? venceHasta,
    double? montoMinimo,
    double? montoMaximo,
    String? busqueda,
  });

  /// Registra un abono sobre una cuenta
  /// Actualiza automáticamente el saldo pendiente
  /// Si el método es efectivo/transferencia, debe impactar Caja
  Future<int> registrarAbono(AbonoCredito abono);

  /// Actualiza el estado de una cuenta
  Future<void> actualizarEstado(int cuentaId, EstadoCredito nuevoEstado);

  /// Marca una cuenta como totalmente pagada
  Future<void> marcarComoPagada(int cuentaId);

  /// Cancela/anula una cuenta por cobrar
  Future<void> cancelarCuenta(int cuentaId, String motivo);

  /// Lista todos los abonos de una cuenta
  Future<List<AbonoCredito>> listarAbonos(int cuentaId);

  /// Lista todas las cuentas de un cliente específico
  Future<List<CuentaPorCobrar>> listarCuentasPorCliente(int clienteId);

  // ============================================
  // RESÚMENES PARA DASHBOARD / PANEL PRINCIPAL
  // ============================================

  /// Total de dinero pendiente de cobrar (todas las cuentas activas)
  Future<double> totalPorCobrar();

  /// Total de dinero vencido (cuentas pasadas de fecha)
  Future<double> totalVencido();

  /// Cantidad de clientes que actualmente tienen deuda
  Future<int> cantidadClientesConDeuda();

  /// Cantidad de clientes con cuentas vencidas
  Future<int> cantidadClientesVencidos();

  /// Total que vence en un rango de fechas (ej: esta semana)
  Future<double> totalPorVencerEnRango(DateTime desde, DateTime hasta);

  /// Lista las cuentas vencidas ordenadas por días de atraso
  Future<List<CuentaPorCobrar>> listarVencidas({int? limite});

  /// Lista las cuentas próximas a vencer
  Future<List<CuentaPorCobrar>> listarProximasAVencer({
    required int diasAnticipacion,
    int? limite,
  });
}
