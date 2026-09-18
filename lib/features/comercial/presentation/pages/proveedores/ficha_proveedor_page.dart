import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _FichaProveedorPageState extends ConsumerState<FichaProveedorPage> {
  Proveedor? _proveedor;
  bool _cargando = true;
  double _saldoPendiente = 0.0;
  List<Map<String, dynamic>> _historialCompras = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final db = ref.read(appDatabaseProvider);
    final filas = await db.select(db.proveedoresTable).get();
    final fila = filas
        .where((p) => p.id == widget.proveedorId)
        .firstOrNull;

    if (fila != null) {
      setState(() {
        _proveedor = Proveedor(
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
      });

      final cuentasPagar = await (db.select(db.cuentasPagarTable)
        ..where((cp) => cp.proveedorId.equals(widget.proveedorId))).get();

      setState(() {
        _saldoPendiente = cuentasPagar.fold<double>(
          0.0,
          (total, cta) => total + cta.monto,
        );
      });

      final compras = await (db.select(db.comprasTable)
        ..where((c) => c.proveedorId.equals(widget.proveedorId))
        ..orderBy([(c) => OrderingTerm(expression: c.fechaEmision, mode: OrderingMode.desc)])).get();

      setState(() {
        _historialCompras = compras
            .map((c) => <String, dynamic>{
                  'fecha': c.fechaEmision,
                  'numero': c.numeroComprobante,
                  'total': c.totalCompra,
                  'estado': c.estado,
                })
            .toList();
      });
    }

    setState(() => _cargando = false);
  }

  String _formatearMonto(double valor) {
    return NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$').format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha del Proveedor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom: true,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _proveedor == null
                ? const Center(child: Text('Proveedor no encontrado'))
                : SingleChildScrollView(
                    padding: AppLayout.pantallaPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSection(
                          title: 'Datos Generales',
                          children: [
                            AppTextField(
                              label: 'Empresa / Razón Social',
                              controller: TextEditingController(text: _proveedor!.nombreEmpresa),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Contacto',
                              controller: TextEditingController(text: _proveedor!.nombreContacto ?? '—'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'RNC / Identificación',
                              controller: TextEditingController(text: _proveedor!.rnc ?? '—'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Dirección',
                              controller: TextEditingController(
                                text: _proveedor!.direccionCompleta.isNotEmpty
                                    ? _proveedor!.direccionCompleta
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
                              controller: TextEditingController(text: _proveedor!.telefono ?? '—'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Celular',
                              controller: TextEditingController(text: _proveedor!.celular ?? '—'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'WhatsApp',
                              controller: TextEditingController(text: _proveedor!.whatsApp ?? '—'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Correo Electrónico',
                              controller: TextEditingController(text: _proveedor!.email ?? '—'),
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
                              controller: TextEditingController(text: _formatearMonto(_proveedor!.limiteCredito)),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Días de Crédito',
                              controller: TextEditingController(text: '${_proveedor!.diasCredito} días'),
                              enabled: false,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            AppTextField(
                              label: 'Condiciones',
                              controller: TextEditingController(
                                text: _proveedor!.condicionesNota ?? 'Sin condiciones',
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),
                        AppSection(
                          title: 'Historial de Compras',
                          children: [
                            if (_historialCompras.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(AppSpacing.m),
                                child: Text(
                                  'Sin compras registradas',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._historialCompras.map((compra) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.m,
                                    horizontal: AppSpacing.s,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('dd/MM/yyyy')
                                                  .format(compra['fecha'] as DateTime),
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              compra['numero'] as String,
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatearMonto(compra['total'] as double),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
                  ),
      ),
    );
  }
}
