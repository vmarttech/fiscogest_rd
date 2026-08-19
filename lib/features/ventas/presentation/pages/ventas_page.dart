import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_cotizaciones.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_apartados.dart';

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});
  static const String routeName = 'ventas';

  @override
  ConsumerState<VentasPage> createState() => VentasPageState();
}

class VentasPageState extends ConsumerState<VentasPage> with SingleTickerProviderStateMixin {
  late final TabController controladorPestanas;

  @override
  void initState() {
    super.initState();
    controladorPestanas = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    controladorPestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Módulo de Ventas',
      body: Column(
        children: [
          TabBar(
            controller: controladorPestanas,
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Registrar Venta'),
              Tab(icon: Icon(Icons.history), text: 'Historial de Ventas'),
              Tab(icon: Icon(Icons.request_quote), text: 'Cotizaciones'),
              Tab(icon: Icon(Icons.bookmark), text: 'Apartados'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controladorPestanas,
              children: const [
                RegistrarVentaPage(),
                HistorialVentas(),
                HistorialCotizaciones(),
                HistorialApartados(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
