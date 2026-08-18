import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';

// VALORES CONFIRMADOS EN EL PLAN: XS=4, S=8, M=16, L=24
const double _xs = 4;
const double _s = 8;
const double _m = 16;
const double _l = 24;

// Estilos definidos SIN fontSize manual (cumpliendo regla del Plan)
const _etiqueta = TextStyle(fontWeight: FontWeight.bold);
const _cuerpo = TextStyle();
const _cuerpoResaltado = TextStyle(fontWeight: FontWeight.bold);
const _textoPequeno = TextStyle(color: Colors.grey);

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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(_m),
          child: Row(
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Buscar producto por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                ),
              ),
              const SizedBox(width: _m),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: _m),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(_m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Productos disponibles', style: _etiqueta),
              const SizedBox(height: _s),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    children: [
                      Text('Producto', style: _etiqueta),
                      Text('Precio', style: _etiqueta, textAlign: TextAlign.right),
                      Text('Stock', style: _etiqueta, textAlign: TextAlign.center),
                      SizedBox.shrink(),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto A\nPROD001', style: _cuerpo),
                      const Text('RD\$ 250.00', style: _cuerpo, textAlign: TextAlign.right),
                      const Text('18', style: _cuerpo, textAlign: TextAlign.center),
                      AppButton(text: '+ Agregar', onPressed: () {}),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto B\nPROD002', style: _cuerpo),
                      const Text('RD\$ 450.00', style: _cuerpo, textAlign: TextAlign.right),
                      const Text('7', style: _cuerpo, textAlign: TextAlign.center),
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(_m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ticket #10594', style: _textoPequeno),
                  Text('Ana G', style: _textoPequeno),
                  Text('Hoy', style: _textoPequeno),
                ],
              ),
              const SizedBox(height: _s),
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
        const SizedBox(height: _m),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(_m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CARRITO', style: _etiqueta),
                  Text('2 productos', style: _textoPequeno),
                ],
              ),
              const SizedBox(height: _s),
              const Divider(height: 1),
              const SizedBox(height: _s),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: esPantallaAncha ? 320 : 200),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildFilaCarrito('Producto A', 2, 250.00),
                    _buildFilaCarrito('Producto B', 1, 450.00),
                  ],
                ),
              ),
              const SizedBox(height: _s),
              const Divider(height: 1),
              const SizedBox(height: _s),
              _buildFilaTotal('Subtotal', 950.00),
              _buildFilaTotal('Descuento', 0.00),
              _buildFilaTotal('ITBIS (18%)', 171.00),
              const SizedBox(height: _s),
              const Divider(height: 2, thickness: 2),
              const SizedBox(height: _s),
              _buildFilaTotal('TOTAL', 1121.00, esResaltado: true),
            ],
          ),
        ),
        const SizedBox(height: _m),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(_m),
          child: Wrap(
            spacing: _s,
            runSpacing: _s,
            children: [
              AppButton(text: '% Descuento', icon: Icons.percent, onPressed: () {}),
              AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: () {}),
              AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: () {}),
              AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: _m),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(_l),
          child: Column(
            children: [
              const Text('TOTAL A PAGAR', style: _etiqueta),
              const SizedBox(height: _xs),
              Text('RD\$ 1,121.00', style: _etiqueta.copyWith(color: Colors.blueAccent)),
              const SizedBox(height: _m),
              SizedBox(
                width: double.infinity,
                child: AppButton(text: 'COBRAR', icon: Icons.payment, onPressed: () {}),
              ),
            ],
          ),
        ),
      ],
    );

    if (esPantallaAncha) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(_m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 52, child: contenidoIzquierda),
            const SizedBox(width: _m),
            Expanded(flex: 48, child: contenidoDerecha),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          contenidoIzquierda,
          const SizedBox(height: _m),
          contenidoDerecha,
        ],
      ),
    );
  }

  Widget _buildFilaCarrito(String nombre, int cantidad, double precio) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _xs / 2),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(nombre, style: _cuerpo)),
          Flexible(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(text: '-', onPressed: () {}),
                const SizedBox(width: _xs),
                Text('$cantidad', style: _cuerpoResaltado),
                const SizedBox(width: _xs),
                AppButton(text: '+', onPressed: () {}),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('RD\$ ${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: _cuerpo)),
          const SizedBox(width: _xs),
          AppButton(text: '✕', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esResaltado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _xs / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: esResaltado ? _etiqueta : _cuerpo),
          Text('RD\$ ${monto.toStringAsFixed(2)}', style: esResaltado ? _etiqueta : _cuerpo),
        ],
      ),
    );
  }
}
