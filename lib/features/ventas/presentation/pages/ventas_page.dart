import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});
  static const String routeName = '/ventas';

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> with SingleTickerProviderStateMixin {
  late final TabController _controladorPestanas;

  @override
  void initState() {
    super.initState();
    _controladorPestanas = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controladorPestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaAncha = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'Módulo de Ventas',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _controladorPestanas,
            isScrollable: true,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Registrar Venta'),
              Tab(text: 'Cotizaciones'),
              Tab(text: 'Apartados'),
              Tab(text: 'Historial de Ventas'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _controladorPestanas,
              children: [
                _buildRegistrarVenta(esPantallaAncha),
                const Center(child: Text('Cotizaciones — En construcción')),
                const Center(child: Text('Apartados — En construcción')),
                const Center(child: Text('Historial de Ventas — En construcción')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrarVenta(bool esPantallaAncha) {
    final contenidoIzquierda = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔍 BUSCADOR PROTAGONISTA
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Buscar producto por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                ),
              ),
              const SizedBox(width: 16),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 📋 PRODUCTOS DISPONIBLES
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Productos disponibles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FixedColumnWidth(100),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(120),
                },
                children: [
                  const TableRow(
                    children: [
                      Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Precio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                      Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                      SizedBox.shrink(),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto A\nPROD001', style: TextStyle(fontSize: 13)),
                      const Text('RD\$ 250.00', style: TextStyle(fontSize: 13), textAlign: TextAlign.right),
                      const Text('18', style: TextStyle(fontSize: 13), textAlign: TextAlign.center),
                      AppButton(text: '+ Agregar', onPressed: () {}),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto B\nPROD002', style: TextStyle(fontSize: 13)),
                      const Text('RD\$ 450.00', style: TextStyle(fontSize: 13), textAlign: TextAlign.right),
                      const Text('7', style: TextStyle(fontSize: 13), textAlign: TextAlign.center),
                      AppButton(text: '+ Agregar', onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final contenidoDerecha = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 📋 ENCABEZADO + CLIENTE
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ticket #10594', style: TextStyle(fontSize: 12)),
                  Text('Ana G', style: TextStyle(fontSize: 12)),
                  Text('Hoy', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                initialValue: 'Consumidor final',
                items: const [
                  DropdownMenuItem(value: 'Consumidor final', child: Text('Consumidor final')),
                  DropdownMenuItem(value: 'buscar', child: Text('Buscar cliente')),
                  DropdownMenuItem(value: 'nuevo', child: Text('Nuevo cliente')),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 🛒 CARRITO
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CARRITO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('2 productos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildFilaCarrito('Producto A', 2, 250.00),
                    _buildFilaCarrito('Producto B', 1, 450.00),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildFilaTotal('Subtotal', 950.00),
              _buildFilaTotal('Descuento', 0.00),
              _buildFilaTotal('ITBIS (18%)', 171.00),
              const SizedBox(height: 12),
              const Divider(height: 2, thickness: 2),
              const SizedBox(height: 12),
              _buildFilaTotal('TOTAL', 1121.00, esResaltado: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ⚙️ ACCIONES SECUNDARIAS
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(text: '% Descuento', icon: Icons.percent, onPressed: () {}),
              AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: () {}),
              AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: () {}),
              AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 💰 TOTAL + BOTÓN COBRAR
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('RD\$ 1,121.00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'COBRAR',
                  icon: Icons.payment,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (esPantallaAncha) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 52, child: contenidoIzquierda),
            const SizedBox(width: 16),
            Expanded(flex: 48, child: contenidoDerecha),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          contenidoIzquierda,
          const SizedBox(height: 16),
          contenidoDerecha,
        ],
      ),
    );
  }

  // ✅ SINTAXIS CORREGIDA — todos los corchetes cerrados
  Widget _buildFilaCarrito(String nombre, int cantidad, double precio) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(nombre, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(text: '-', onPressed: () {}),
                const SizedBox(width: 4),
                Text('$cantidad', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                AppButton(text: '+', onPressed: () {}),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('RD\$ ${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 4),
          AppButton(text: '✕', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esResaltado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: esResaltado ? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13)),
          Text('RD\$ ${monto.toStringAsFixed(2)}', style: esResaltado ? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
