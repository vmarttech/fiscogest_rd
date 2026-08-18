import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';

class RegistrarVentaPage extends StatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = '/ventas/registrar';

  @override
  State<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends State<RegistrarVentaPage> {
  final _buscadorController = TextEditingController();

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
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
            rows: [
              DataRow(cells: [
                const DataCell(Text('ART001')),
                const DataCell(Text('1')),
                DataCell(AppButton(text: '+ Agregar', height: 36, onPressed: () {})),
              ]),
            ],
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
            const Text('Venta Actual • Ticket #10594 • Cajero: Ana G.'),
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
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('1')),
                    DataCell(Text('Producto A')),
                    DataCell(Text('\$255.00')),
                  ]),
                  DataRow(cells: [
                    DataCell(SizedBox.shrink()),
                    DataCell(Text('ITBIS')),
                    DataCell(Text('\$0.00')),
                  ]),
                  DataRow(cells: [
                    DataCell(SizedBox.shrink()),
                    DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('RD\$ 3,450.00', style: TextStyle(fontWeight: FontWeight.bold))),
                  ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSection(
          title: 'Opciones de Venta',
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: () {}),
                AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: () {}),
                AppButton(text: 'Nota de Crédito', icon: Icons.receipt_long, onPressed: () {}),
                AppButton(text: 'Descuento %', icon: Icons.percent, onPressed: () {}),
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
                'TOTAL A PAGAR: RD\$ 3,450.00',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'COBRAR E IMPRIMIR (F12)',
                  icon: Icons.payment,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
