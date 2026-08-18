import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

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
    if (esPantallaAncha) {
      // ✅ ESCRITORIO: Expanded FUERA, Scrollable DENTRO → SIN CONFLICTO
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildSeccionProductos(),
            ),
          ),
          SizedBox(width: AppSpacing.m),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: AppSpacing.allM,
              child: _buildSeccionCarrito(esPantallaAncha),
            ),
          ),
        ],
      );
    }

    // ✅ MÓVIL: Scrollable envuelve todo, SIN Expanded dentro
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSeccionProductos(),
          SizedBox(height: AppSpacing.m),
          _buildSeccionCarrito(esPantallaAncha),
        ],
      ),
    );
  }

  Widget _buildSeccionProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: AppSpacing.allM,
          child: Row(
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Buscar producto por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                ),
              ),
              SizedBox(width: AppSpacing.m),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: AppSpacing.allM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Productos disponibles', style: AppTypography.labelMedium),
              SizedBox(height: AppSpacing.s),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.3),
                },
                children: [
                  TableRow(
                    children: [
                      const Text('Producto', style: AppTypography.labelMedium),
                      const Text('Precio', style: AppTypography.labelMedium, textAlign: TextAlign.right),
                      const Text('Stock', style: AppTypography.labelMedium, textAlign: TextAlign.center),
                      const SizedBox.shrink(),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto A\nPROD001', style: AppTypography.bodyMedium),
                      const Text('RD\$ 250.00', style: AppTypography.bodyMedium, textAlign: TextAlign.right),
                      const Text('18', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                      AppButton(text: '+ Agregar', onPressed: () {}),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Text('Producto B\nPROD002', style: AppTypography.bodyMedium),
                      const Text('RD\$ 450.00', style: AppTypography.bodyMedium, textAlign: TextAlign.right),
                      const Text('7', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
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
  }

  Widget _buildSeccionCarrito(bool esPantallaAncha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: AppSpacing.allM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ticket #10594', style: AppTypography.bodySmall),
                  Text('Ana G', style: AppTypography.bodySmall),
                  Text('Hoy', style: AppTypography.bodySmall),
                ],
              ),
              SizedBox(height: AppSpacing.s),
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
        SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: AppSpacing.allM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CARRITO', style: AppTypography.labelMedium),
                  const Text('2 productos', style: AppTypography.bodySmall),
                ],
              ),
              SizedBox(height: AppSpacing.s),
              const Divider(height: 1),
              SizedBox(height: AppSpacing.s),
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
              SizedBox(height: AppSpacing.s),
              const Divider(height: 1),
              SizedBox(height: AppSpacing.s),
              _buildFilaTotal('Subtotal', 950.00),
              _buildFilaTotal('Descuento', 0.00),
              _buildFilaTotal('ITBIS (18%)', 171.00),
              SizedBox(height: AppSpacing.s),
              const Divider(height: 2, thickness: 2),
              SizedBox(height: AppSpacing.s),
              _buildFilaTotal('TOTAL', 1121.00, esResaltado: true),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: AppSpacing.allM,
          child: Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              AppButton(text: '% Descuento', icon: Icons.percent, onPressed: () {}),
              AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: () {}),
              AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: () {}),
              AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: () {}),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
          ),
          padding: AppSpacing.allL,
          child: Column(
            children: [
              const Text('TOTAL A PAGAR', style: AppTypography.labelMedium),
              SizedBox(height: AppSpacing.xs),
              Text('RD\$ 1,121.00', style: AppTypography.h2.copyWith(color: Colors.blueAccent)),
              SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: AppButton(text: 'COBRAR', icon: Icons.payment, onPressed: () {}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilaCarrito(String nombre, int cantidad, double precio) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(nombre, style: AppTypography.bodyMedium)),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text('$cantidad', style: AppTypography.labelMedium),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('RD\$ ${subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: AppTypography.bodyMedium)),
          SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Text('✕', style: TextStyle(fontSize: 12)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esResaltado = false}) {
    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: esResaltado ? AppTypography.labelMedium : AppTypography.bodyMedium),
          Text('RD\$ ${monto.toStringAsFixed(2)}', style: esResaltado ? AppTypography.labelMedium : AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
