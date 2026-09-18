import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/registrar_abono_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/detalle_cuenta_pagar_page.dart';

class FichaProveedorPage extends ConsumerStatefulWidget {
  const FichaProveedorPage({
    super.key,
    required this.proveedorId,
  });

  static String ruta = '/ficha-proveedor';
  final int proveedorId;

  @override
  ConsumerState<FichaProveedorPage> createState() => _FichaProveedorPageState();
}

class _FichaProveedorPageState extends ConsumerState<FichaProveedorPage>
    with SingleTickerProviderStateMixin {
  Proveedor? _proveedor;
  bool _cargando = true;
  double _saldoPendiente = 0.0;
  double _limiteCredito = 0.0;

  List<_ItemHistorialCompra> _historialCompras = [];
  List<_ItemCuentaPendiente> _cuentasPendientes = [];
  List<_ItemPago> _pagosRealizados = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final db = ref.read(appDatabaseProvider);

    // 1. Datos del proveedor
    final filas = await db.select(db.proveedoresTable).get();
    final fila = filas.where((p) => p.id == widget.proveedorId).firstOrNull;

    if (fila == null) {
      setState(() {
        _proveedor = null;
        _cargando = false;
      });
      return;
    }

    final proveedor = Proveedor(
      id: fila.id,
      nombreEmpresa: fila.nombreEmpresa,
      nombreContacto: fila.nombreContacto,
      rnc: fila.rnc,
      telefono: fila.telefono,
      celular: fila.celular,
      whatsApp: fila.whatsApp,
      email: fila.email,
      direccion: fila.direccion,
      ciudad: fila.ciudad,
      provincia: fila.provincia,
      limiteCredito: fila.limiteCredito,
      diasCredito: fila.diasCredito,
      condicionesNota: fila.condicionesNota,
      estado: fila.estado,
      fechaCreacion: fila.fechaCreacion,
      fechaActualizacion: fila.fechaActualizacion,
    );

    // 2. Historial de compras
    final compras = await (db.select(db.comprasTable)
          ..where((c) => c.proveedorId.equals(widget.proveedorId))
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.fechaEmision,
                  mode: OrderingMode.desc,
                )
          ]))
        .get();

    final historial = compras
        .map((c) => _ItemHistorialCompra(
              id: c.id,
              fecha: c.fechaEmision,
              numero: c.numeroComprobante.isNotEmpty
                  ? c.numeroComprobante
                  : 'Compra #${c.id}',
              total: c.totalCompra,
              estado: c.estado.name,
              esCredito: c.formaPago.toLowerCase().contains('credito') ||
                  c.condicionPago.toLowerCase().contains('credito'),
            ))
        .toList();

    // 3. Cuentas por pagar + saldo real (monto - abonos)
    final cuentasDao = ref.read(repo.cuentasPagarDaoProvider);
    final cuentas = await (db.select(db.cuentasPagarTable)
          ..where((cp) => cp.proveedorId.equals(widget.proveedorId)))
        .get();

    double saldoTotal = 0.0;
    final pendientes = <_ItemCuentaPendiente>[];

    for (final cta in cuentas) {
      final pagos = await cuentasDao.listarPagosPorCuenta(cta.id);
      final totalAbonado =
          pagos.fold<double>(0.0, (s, p) => s + p.monto);
      final saldo = cta.monto - totalAbonado;

      if (saldo > 0.01) {
        saldoTotal += saldo;
        pendientes.add(_ItemCuentaPendiente(
          id: cta.id,
          concepto: cta.concepto,
          fechaEmision: cta.fechaEmision,
          fechaVencimiento: cta.fechaVencimiento,
          monto: cta.monto,
          abonado: totalAbonado,
          pendiente: saldo,
          estado: cta.estado.name,
        ));
      }
    }

    // 4. Pagos realizados
    final todosPagos = await (db.select(db.pagosProveedorTable)
          ..where((p) => p.proveedorId.equals(widget.proveedorId))
          ..orderBy([
            (p) => OrderingTerm(
                  expression: p.fechaPago,
                  mode: OrderingMode.desc,
                )
          ]))
        .get();

    final pagos = todosPagos
        .map((p) => _ItemPago(
              id: p.id,
              fecha: p.fechaPago,
              monto: p.monto,
              formaPago: p.formaPago,
              referencia: p.referencia,
              nota: p.nota,
            ))
        .toList();

    setState(() {
      _proveedor = proveedor;
      _limiteCredito = proveedor.limiteCredito;
      _saldoPendiente = saldoTotal;
      _historialCompras = historial;
      _cuentasPendientes = pendientes;
      _pagosRealizados = pagos;
      _cargando = false;
    });
  }

  String _formatearMonto(double valor) {
    return NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$').format(valor);
  }

  String _formatearFecha(DateTime f) =>
      DateFormat('dd/MM/yyyy').format(f);

  void _irADetalleCompra(int compraId) {
    context.goNamed(
      DetalleCompraPage.routeName,
      pathParameters: {'compraId': compraId.toString()},
    );
  }

  void _irARegistrarAbono(int cuentaId) {
    // Ajusta el nombre de ruta si es diferente en tu router
    try {
      context.goNamed(
        RegistrarAbonoPage.routeName,
        pathParameters: {'cuentaId': cuentaId.toString()},
      );
    } catch (_) {
      // Fallback por si la ruta usa query o arguments
      context.pushNamed(
        RegistrarAbonoPage.routeName,
        extra: {'cuentaId': cuentaId, 'proveedorId': widget.proveedorId},
      );
    }
  }

  void _irADetalleCuenta(int cuentaId) {
    try {
      context.goNamed(
        DetalleCuentaPagarPage.routeName,
        pathParameters: {'cuentaId': cuentaId.toString()},
      );
    } catch (_) {
      context.pushNamed(
        DetalleCuentaPagarPage.routeName,
        extra: cuentaId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha del Proveedor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: _proveedor == null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Datos'),
                  Tab(text: 'Compras'),
                  Tab(text: 'Cuentas / Pagos'),
                ],
              ),
      ),
      body: SafeArea(
        bottom: true,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _proveedor == null
                ? const Center(child: Text('Proveedor no encontrado'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabDatos(),
                      _buildTabCompras(),
                      _buildTabCuentasYPagos(),
                    ],
                  ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Datos generales + crédito
  // ---------------------------------------------------------------------------
  Widget _buildTabDatos() {
    final p = _proveedor!;
    return SingleChildScrollView(
      padding: AppLayout.pantallaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: 'Datos Generales',
            children: [
              AppTextField(
                label: 'Empresa / Razón Social',
                controller: TextEditingController(text: p.nombreEmpresa),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Contacto',
                controller: TextEditingController(text: p.nombreContacto ?? '—'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'RNC / Identificación',
                controller: TextEditingController(text: p.rnc ?? '—'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Dirección',
                controller: TextEditingController(
                  text: p.direccionCompleta.isNotEmpty
                      ? p.direccionCompleta
                      : '—',
                ),
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          AppSection(
            title: 'Contacto',
            children: [
              AppTextField(
                label: 'Teléfono',
                controller: TextEditingController(text: p.telefono ?? '—'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Celular',
                controller: TextEditingController(text: p.celular ?? '—'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'WhatsApp',
                controller: TextEditingController(text: p.whatsApp ?? '—'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Correo Electrónico',
                controller: TextEditingController(text: p.email ?? '—'),
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          AppSection(
            title: 'Crédito y Condiciones',
            children: [
              AppTextField(
                label: 'Límite de Crédito',
                controller: TextEditingController(
                  text: _formatearMonto(_limiteCredito),
                ),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Días de Crédito',
                controller: TextEditingController(text: '${p.diasCredito} días'),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                label: 'Condiciones',
                controller: TextEditingController(
                  text: p.condicionesNota ?? 'Sin condiciones',
                ),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.m),
              AppCard(
                color: _saldoPendiente > 0
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.success.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    children: [
                      Text(
                        'Saldo Pendiente',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        _formatearMonto(_saldoPendiente),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _saldoPendiente > 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                      ),
                      if (_limiteCredito > 0) ...[
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'Disponible: ${_formatearMonto((_limiteCredito - _saldoPendiente).clamp(0, _limiteCredito))}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Editar Proveedor',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/editar-proveedor',
                arguments: widget.proveedorId,
              );
            },
          ),
          const SizedBox(height: AppSpacing.m),
          AppButton(
            text: 'Volver',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Historial de compras (navegable a detalle)
  // ---------------------------------------------------------------------------
  Widget _buildTabCompras() {
    if (_historialCompras.isEmpty) {
      return const Center(
        child: Text('Sin compras registradas'),
      );
    }

    return ListView.separated(
      padding: AppLayout.pantallaPadding,
      itemCount: _historialCompras.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _historialCompras[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          onTap: () => _irADetalleCompra(item.id),
          title: Text(
            item.numero,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${_formatearFecha(item.fecha)}  ·  ${item.esCredito ? 'Crédito' : 'Contado'}  ·  ${item.estado}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatearMonto(item.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Cuentas pendientes + Pagos (navegable a abono / detalle)
  // ---------------------------------------------------------------------------
  Widget _buildTabCuentasYPagos() {
    return SingleChildScrollView(
      padding: AppLayout.pantallaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cuentas pendientes
          Text(
            'Cuentas pendientes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (_cuentasPendientes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay cuentas pendientes',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._cuentasPendientes.map((cta) {
              final vencida = DateTime.now().isAfter(cta.fechaVencimiento) &&
                  cta.estado != PagarEstado.pagado.name;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: vencida ? Colors.red.shade50 : null,
                child: InkWell(
                  onTap: () => _irADetalleCuenta(cta.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cta.concepto,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              _formatearMonto(cta.pendiente),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: vencida ? Colors.red : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Emisión: ${_formatearFecha(cta.fechaEmision)}  ·  '
                          'Vence: ${_formatearFecha(cta.fechaVencimiento)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Total: ${_formatearMonto(cta.monto)}  ·  '
                          'Abonado: ${_formatearMonto(cta.abonado)}  ·  '
                          '${vencida ? 'Vencida' : cta.estado}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.payments, size: 18),
                            label: const Text('Registrar abono'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                            ),
                            onPressed: () => _irARegistrarAbono(cta.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: AppSpacing.l),

          // Pagos realizados
          Text(
            'Pagos realizados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (_pagosRealizados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay pagos registrados',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._pagosRealizados.map((pago) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payments_outlined, size: 22),
                title: Text(
                  _formatearMonto(pago.monto),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_formatearFecha(pago.fecha)}  ·  ${pago.formaPago}'
                  '${pago.referencia != null && pago.referencia!.isNotEmpty ? '  ·  ${pago.referencia}' : ''}',
                ),
              );
            }),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// Modelos internos simples para la UI
class _ItemHistorialCompra {
  const _ItemHistorialCompra({
    required this.id,
    required this.fecha,
    required this.numero,
    required this.total,
    required this.estado,
    required this.esCredito,
  });
  final int id;
  final DateTime fecha;
  final String numero;
  final double total;
  final String estado;
  final bool esCredito;
}

class _ItemCuentaPendiente {
  const _ItemCuentaPendiente({
    required this.id,
    required this.concepto,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.monto,
    required this.abonado,
    required this.pendiente,
    required this.estado,
  });
  final int id;
  final String concepto;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final double monto;
  final double abonado;
  final double pendiente;
  final String estado;
}

class _ItemPago {
  const _ItemPago({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.formaPago,
    this.referencia,
    this.nota,
  });
  final int id;
  final DateTime fecha;
  final double monto;
  final String formaPago;
  final String? referencia;
  final String? nota;
}
