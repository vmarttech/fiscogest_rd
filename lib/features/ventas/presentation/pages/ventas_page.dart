import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

// =====================================================================
// PANTALLA PRINCIPAL — REDISEÑO PROFESIONAL
// =====================================================================
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final esPantallaAncha = constraints.maxWidth >= 900;
                return TabBarView(
                  controller: _controladorPestanas,
                  children: [
                    esPantallaAncha ? const _VistaEscritorio() : const _VistaMovil(),
                    const Center(child: Text('Cotizaciones — En construcción')),
                    const Center(child: Text('Apartados — En construcción')),
                    const Center(child: Text('Historial de Ventas — En construcción')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// VISTA ESCRITORIO — 2 columnas profesionales
// =====================================================================
class _VistaEscritorio extends StatelessWidget {
  const _VistaEscritorio();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: _PanelProductos(),
          ),
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: _PanelCarrito(),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// VISTA MÓVIL — Productos + Botón flotante del carrito
// =====================================================================
class _VistaMovil extends StatelessWidget {
  const _VistaMovil();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.m,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          child: _PanelProductos(esMovil: true),
        ),
        Positioned(
          left: AppSpacing.m,
          right: AppSpacing.m,
          bottom: AppSpacing.m,
          child: AppButton(
            text: 'Ver carrito (2) • RD\$ 1,121.00',
            icon: Icons.shopping_cart_outlined,
            onPressed: () => _abrirCarrito(context),
          ),
        ),
      ],
    );
  }

  void _abrirCarrito(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: AppSpacing.allM,
          child: SingleChildScrollView(
            controller: controller,
            child: const _PanelCarrito(),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// PANEL PRODUCTOS — Buscador + Lista
// =====================================================================
class _PanelProductos extends StatelessWidget {
  const _PanelProductos({this.esMovil = false});
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TÍTULO DE SECCIÓN
        const Text('Catálogo de productos', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        const Text('Busca y agrega productos al carrito', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.m),

        // BUSCADOR
        _TarjetaProfesional(
          child: Row(
            children: [
              const Expanded(
                child: AppTextField(
                  label: 'Buscar por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // LISTA/TABLA DE PRODUCTOS
        _TarjetaProfesional(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Productos disponibles', style: AppTypography.labelMedium),
                  Text('2 artículos', style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.s),
              esMovil ? const _ListaProductosMovil() : const _TablaProductosEscritorio(),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// TABLA PRODUCTOS — Escritorio
// =====================================================================
class _TablaProductosEscritorio extends StatelessWidget {
  const _TablaProductosEscritorio();

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(0.8),
        3: FlexColumnWidth(1.3),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: AppSpacing.vS,
              child: Text('Producto', style: AppTypography.labelSmall),
            ),
            Padding(
              padding: AppSpacing.vS,
              child: Text('Precio', style: AppTypography.labelSmall, textAlign: TextAlign.right),
            ),
            Padding(
              padding: AppSpacing.vS,
              child: Text('Stock', style: AppTypography.labelSmall, textAlign: TextAlign.center),
            ),
            SizedBox.shrink(),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: AppSpacing.vS,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Producto A', style: AppTypography.bodyMedium),
                  Text('PROD001', style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Padding(
              padding: AppSpacing.vS,
              child: Text('RD\$ 250.00', style: AppTypography.labelMedium, textAlign: TextAlign.right),
            ),
            const Padding(
              padding: AppSpacing.vS,
              child: Text('18', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            ),
            Padding(
              padding: AppSpacing.vS,
              child: Align(
                alignment: Alignment.centerRight,
                child: AppButton(text: 'Agregar', icon: Icons.add, onPressed: () {}),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: AppSpacing.vS,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Producto B', style: AppTypography.bodyMedium),
                  Text('PROD002', style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Padding(
              padding: AppSpacing.vS,
              child: Text('RD\$ 450.00', style: AppTypography.labelMedium, textAlign: TextAlign.right),
            ),
            const Padding(
              padding: AppSpacing.vS,
              child: Text('7', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            ),
            Padding(
              padding: AppSpacing.vS,
              child: Align(
                alignment: Alignment.centerRight,
                child: AppButton(text: 'Agregar', icon: Icons.add, onPressed: () {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =====================================================================
// LISTA PRODUCTOS — Móvil (tarjetas compactas)
// =====================================================================
class _ListaProductosMovil extends StatelessWidget {
  const _ListaProductosMovil();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TarjetaProductoMovil(
          nombre: 'Producto A',
          codigo: 'PROD001',
          precio: 250.00,
          stock: 18,
        ),
        _TarjetaProductoMovil(
          nombre: 'Producto B',
          codigo: 'PROD002',
          precio: 450.00,
          stock: 7,
        ),
      ],
    );
  }
}

class _TarjetaProductoMovil extends StatelessWidget {

  const _TarjetaProductoMovil({
    required this.nombre,
    required this.codigo,
    required this.precio,
    required this.stock,
  });
  final String nombre;
  final String codigo;
  final double precio;
  final int stock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: AppSpacing.allS,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: AppTypography.labelMedium),
                Text(codigo, style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('Stock: $stock', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RD\$ ${precio.toStringAsFixed(2)}', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              AppButton(text: '', icon: Icons.add, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PANEL CARRITO — Ticket + Productos + Totales + Cobro
// =====================================================================
class _PanelCarrito extends StatelessWidget {
  const _PanelCarrito();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TÍTULO
        const Text('Resumen de venta', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        const Text('Ticket, cliente y productos agregados', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.m),

        // INFORMACIÓN DEL TICKET
        _TarjetaProfesional(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TICKET', style: AppTypography.labelSmall),
                      Text('#10594', style: AppTypography.labelMedium),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('CLIENTE', style: AppTypography.labelSmall),
                      Text('Ana G', style: AppTypography.labelMedium),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('FECHA', style: AppTypography.labelSmall),
                      Text('Hoy', style: AppTypography.labelMedium),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
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
        const SizedBox(height: AppSpacing.m),

        // PRODUCTOS EN CARRITO
        _TarjetaProfesional(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Productos', style: AppTypography.labelMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('2 artículos', style: AppTypography.bodySmall.copyWith(color: Colors.blueAccent)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.s),
              _FilaCarritoProfesional(nombre: 'Producto A', cantidad: 2, precio: 250.00),
              _FilaCarritoProfesional(nombre: 'Producto B', cantidad: 1, precio: 450.00),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // TOTALES
        _TarjetaProfesional(
          colorFondo: Colors.grey.shade50,
          child: const _ResumenTotales(),
        ),
        const SizedBox(height: AppSpacing.m),

        // ACCIONES RÁPIDAS
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            AppButton(text: '% Descuento', icon: Icons.percent, onPressed: () {}),
            AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: () {}),
            AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: () {}),
            AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: () {}),
          ],
        ),
        const SizedBox(height: AppSpacing.m),

        // BOTÓN DE COBRO — DESTACADO
        Container(
          padding: AppSpacing.allM,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'TOTAL A PAGAR',
                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'RD\$ 1,121.00',
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.m),
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
  }
}

// =====================================================================
// FILA CARRITO PROFESIONAL — Diseño claro, sin desbordes
// =====================================================================
class _FilaCarritoProfesional extends StatelessWidget {

  _FilaCarritoProfesional({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });
  final String nombre;
  final int cantidad;
  final double precio;

  @override
  Widget build(BuildContext context) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: AppSpacing.vS,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LÍNEA 1: Nombre + Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: AppTypography.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'RD\$ ${subtotal.toStringAsFixed(2)}',
                style: AppTypography.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // LÍNEA 2: Precio unitario + Controles + Eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RD\$ ${precio.toStringAsFixed(2)} c/u',
                style: AppTypography.bodySmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(text: '-', onPressed: () {}),
                  const SizedBox(width: AppSpacing.s),
                  Text('$cantidad', style: AppTypography.labelMedium),
                  const SizedBox(width: AppSpacing.s),
                  AppButton(text: '+', onPressed: () {}),
                ],
              ),
              AppButton(text: '', icon: Icons.delete_outline, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// RESUMEN DE TOTALES — Jerarquía clara
// =====================================================================
class _ResumenTotales extends StatelessWidget {
  const _ResumenTotales();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilaTotal(etiqueta: 'Subtotal', monto: 950.00),
        _FilaTotal(etiqueta: 'Descuento', monto: 0.00),
        _FilaTotal(etiqueta: 'ITBIS (18%)', monto: 171.00),
        const Divider(height: 24, thickness: 1.5),
        _FilaTotal(etiqueta: 'TOTAL', monto: 1121.00, esResaltado: true),
      ],
    );
  }
}

class _FilaTotal extends StatelessWidget {

  _FilaTotal({
    required this.etiqueta,
    required this.monto,
    this.esResaltado = false,
  });
  final String etiqueta;
  final double monto;
  final bool esResaltado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: esResaltado ? AppTypography.h4 : AppTypography.bodyMedium,
          ),
          Text(
            'RD\$ ${monto.toStringAsFixed(2)}',
            style: esResaltado ? AppTypography.h3 : AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// TARJETA PROFESIONAL — Contenedor estandarizado
// =====================================================================
class _TarjetaProfesional extends StatelessWidget {

  const _TarjetaProfesional({
    required this.child,
    this.colorFondo = Colors.white,
  });
  final Widget child;
  final Color colorFondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: colorFondo,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
