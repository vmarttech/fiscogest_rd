import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class VentasPage extends StatefulWidget {

  const VentasPage({super.key});
  static const routeName = '/ventas';

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> with SingleTickerProviderStateMixin {
  late final TabController _controladorPestanas;

  @override
  void initState() {
    super.initState();
    _controladorPestanas = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _controladorPestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaGrande = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'Módulo de Ventas',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Pestañas SUPERIORES — Navegación directa
          TabBar(
            controller: _controladorPestanas,
            isScrollable: true,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '[Activo] Registrar Venta'),
              Tab(text: '[Inactivo] Cotizaciones'),
              Tab(text: '[Inactivo] Apartados'),
              Tab(text: '[Inactivo] Notas de Crédito'),
              Tab(text: '[Inactivo] Historial de Ventas'),
            ],
          ),
          const Divider(height: 1),

          // ✅ Área de contenido
          Expanded(
            child: TabBarView(
              controller: _controladorPestanas,
              children: [
                // =====================================================
                // PESTAÑA 0 — REGISTRAR VENTA (CARGA POR DEFECTO)
                // =====================================================
                _buildRegistrarVenta(esPantallaGrande),

                // =====================================================
                // PESTAÑA 1 — COTIZACIONES
                // =====================================================
                const Center(child: Text('📄 Cotizaciones — En construcción')),

                // =====================================================
                // PESTAÑA 2 — APARTADOS
                // =====================================================
                const Center(child: Text('📝 Apartados — En construcción')),

                // =====================================================
                // PESTAÑA 3 — NOTAS DE CRÉDITO
                // =====================================================
                const Center(child: Text('↩️ Notas de Crédito — En construcción')),

                // =====================================================
                // PESTAÑA 4 — HISTORIAL
                // =====================================================
                const Center(child: Text('📊 Historial de Ventas — En construcción')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // VISTA DE REGISTRAR VENTA — Adaptable por tamaño
  // =====================================================
  Widget _buildRegistrarVenta(bool esPantallaGrande) {
    if (esPantallaGrande) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL IZQUIERDO — Búsqueda + Lista de Artículos
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AppSection(
                title: 'Artículos / Búsqueda',
                children: [
                  const AppTextField(
                    label: 'Buscar artículo por nombre, código o EAN',
                    prefixIcon: Icons.search,
                  ),
                  AppLayout.vM,
                  DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Descripción')),
                      DataColumn(label: Text('Cantidad en Stock')),
                      DataColumn(label: Text('Precio Unitario')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: _generarFilasArticulos(),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // PANEL DERECHO — Carrito + Resumen + Opciones + Total
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSection(
                    title: 'Carrito / Resumen de Factura',
                    children:  [
                      const Text('Venta Actual • Ticket #10594 • Cajero: Ana G.'),
                      const SizedBox(height: 12),
                      DataTable(
                        columnSpacing: 12,
                        horizontalMargin: 4,
                        columns: [
                          const DataColumn(label: Text('Cant.')),
                          const DataColumn(label: Text('Descripción')),
                          const DataColumn(label: Text('Total Parcial')),
                          const DataColumn(label: Text('')),
                        ],
                        rows: [
                          const DataRow(cells: [
                            DataCell(Text('1')),
                            DataCell(Text('Canttotal (2%)')),
                            DataCell(Text('\$255.00')),
                            DataCell(Icon(Icons.close, size: 16)),
                          ]),
                          const DataRow(cells: [
                            DataCell(SizedBox.shrink()),
                            DataCell(Text('ITBIS (ITBIS)')),
                            DataCell(Text('\$0.00')),
                            DataCell(SizedBox.shrink()),
                          ]),
                          const DataRow(
                            cells: [
                              DataCell(SizedBox.shrink()),
                              DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('RD\$ 3,450.00', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppLayout.vM,
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
                  AppLayout.vL,
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
              ),
            ),
          ),
        ],
      );
    } else {
      // En celular: todo apilado verticalmente
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const AppSection(
              title: 'Artículos / Búsqueda',
              children: [
                AppTextField(label: 'Buscar artículo por nombre, código o EAN', prefixIcon: Icons.search),
              ],
            ),
            AppLayout.vM,
            const AppSection(
              title: 'Carrito / Resumen de Factura',
              children: [Text('Resumen de venta...')],
            ),
            AppLayout.vM,
            const AppSection(
              title: 'Opciones de Venta',
              children: [Text('Botones de cotización, apartado, descuento...')],
            ),
            AppLayout.vL,
            SizedBox(
              width: double.infinity,
              child: AppButton(text: 'COBRAR E IMPRIMIR', onPressed: () {}),
            ),
          ],
        ),
      );
    }
  }

  static List<DataRow> _generarFilasArticulos() {
    const articulos = [
      ('SATTT', 'Descripción', '—', '—'),
      ('Artículd', 'Cantidad en Stock', '—', '—'),
      ('Categoría', 'Cantidad en Stock', '—', '—'),
      ('Categonta', 'Cantidad en Stock', '—', '—'),
      ('Collectáivin', '—', '—', '—'),
      ('Colleccio', '—', '—', '—'),
      ('Categoría', '—', '—', '—'),
      ('Cobdito', '—', '—', '—'),
      ('Descuento %', '—', '—', '—'),
    ];

    return articulos.map((a) => DataRow(
      cells: [
        DataCell(Text(a.$1)),
        DataCell(Text(a.$2)),
        DataCell(Text(a.$3)),
        DataCell(Text(a.$4)),
        DataCell(AppButton(text: '+ Agregar', height: 36, onPressed: () {})),
      ],
    )).toList();
  }
}
