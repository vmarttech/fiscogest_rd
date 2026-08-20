import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/nueva_cotizacion_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/apartados_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/devoluciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/pagar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/descuentos_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ofertas_page.dart';

class VentasRoute {

  const VentasRoute({required this.path, required this.name, required this.builder});
  final String path;
  final String name;
  final WidgetBuilder builder;
}

final List<VentasRoute> ventasRoutes = [
  VentasRoute(path: '/ventas', name: VentasPage.routeName, builder: (_) => const VentasPage()),
  VentasRoute(path: '/ventas/registrar', name: RegistrarVentaPage.routeName, builder: (_) => const RegistrarVentaPage()),
  VentasRoute(path: '/ventas/cotizaciones/nueva', name: NuevaCotizacionPage.routeName, builder: (_) => const NuevaCotizacionPage()),
  VentasRoute(path: '/ventas/apartados', name: ApartadosPage.routeName, builder: (_) => const ApartadosPage()),
  VentasRoute(path: '/ventas/devoluciones', name: DevolucionesPage.routeName, builder: (_) => const DevolucionesPage()),
  VentasRoute(path: '/ventas/cobrar', name: CobrarPage.routeName, builder: (_) => const CobrarPage()),
  VentasRoute(path: '/ventas/pagar', name: PagarPage.routeName, builder: (_) => const PagarPage()),
  VentasRoute(path: '/ventas/descuentos', name: DescuentosPage.routeName, builder: (_) => const DescuentosPage()),
  VentasRoute(path: '/ventas/ofertas', name: OfertasPage.routeName, builder: (_) => const OfertasPage()),
];
