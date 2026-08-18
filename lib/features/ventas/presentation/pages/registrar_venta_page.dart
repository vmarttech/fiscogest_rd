import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';

  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  final _buscadorController = TextEditingController();
  String _ventaId = '';
  String _usuarioNombre = 'Usuario actual';

  @override
  void initState() {
    super.initState();
    _ventaId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _cobrarYRegistrarSalida() async {
    try {
      // ✅ Registrar salida en Kardex por cada producto del carrito
      // TODO: Reemplazar por lista real de productos del carrito
      // await ref.read(salidaControllerProvider.notifier).registrarSalida(
      //   productoId: producto.id,
      //   cantidad: producto.cantidad,
      //   usuarioResponsable: _usuarioNombre,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta registrada. Kardex actualizado.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaAncha = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'Registrar Venta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: esPantallaAncha
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildZonaIzquierda()),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(flex: 2, child: _buildZonaDerecha()),
                ],
              )
            : Column(
                children: [
                  _buildZonaIzquierda(),
                  const SizedBox(height: 16),
                  _buildZonaDerecha(),
                ],
              ),
      ),
    );
  }

  Widget _buildZonaIzquierda() {
    return AppSection(
      title: 'Artículos / Búsqueda',
      children: [
        AppTextField(
          label: 'Buscar artículo por nombre, código o EAN',
          prefixIcon: Icons.search,
          controller: _buscadorController,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 8,
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Cantidad')),
              DataColumn(label: Text('Acción')),
            ],
            rows: const [],
          ),
        ),
      ],
    );
  }

  Widget _buildZonaDerecha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'Carrito / Resumen de Factura',
          children: [
            Text('Venta Actual • Ticket #$_ventaId • Cajero: $_usuarioNombre'),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                horizontalMargin: 4,
                columns: const [
                  DataColumn(label: Text('Cant.')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Total Parcial')),
                ],
                rows: const [],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppSection(
          title: 'Opciones de Venta',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: null),
                AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: null),
                AppButton(text: 'Nota de Crédito', icon: Icons.receipt_long, onPressed: null),
                AppButton(text: 'Descuento %', icon: Icons.percent, onPressed: null),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL A PAGAR: RD\$ 0.00',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'COBRAR E IMPRIMIR (F12)',
                  icon: Icons.payment,
                  onPressed: _cobrarYRegistrarSalida,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
