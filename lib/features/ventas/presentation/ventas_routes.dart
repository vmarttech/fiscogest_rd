import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cotizaciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/apartados_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/devoluciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/pagar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/descuentos_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ofertas_page.dart';

final ventasRoutes = [
  VentasRoute(path: '/ventas', name: VentasPage.routeName, builder: const VentasPage()),
  VentasRoute(path: '/ventas/registrar', name: RegistrarVentaPage.routeName, builder: const RegistrarVentaPage()),
  VentasRoute(path: '/ventas/cotizaciones', name: CotizacionesPage.routeName, builder: const CotizacionesPage()),
  VentasRoute(path: '/ventas/apartados', name: ApartadosPage.routeName, builder: const ApartadosPage()),
  VentasRoute(path: '/ventas/devoluciones', name: DevolucionesPage.routeName, builder: const DevolucionesPage()),
  VentasRoute(path: '/ventas/cobrar', name: CobrarPage.routeName, builder: const CobrarPage()),
  VentasRoute(path: '/ventas/pagar', name: PagarPage.routeName, builder: const PagarPage()),
  VentasRoute(path: '/ventas/descuentos', name: DescuentosPage.routeName, builder: const DescuentosPage()),
  VentasRoute(path: '/ventas/ofertas', name: OfertasPage.routeName, builder: const OfertasPage()),
];

class VentasRoute {

  VentasRoute({required this.path, required this.name, required this.builder});
  final String path;
  final String name;
  final Widget builder;
}
