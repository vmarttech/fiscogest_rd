import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class NavegacionVentas extends ConsumerWidget {
  const NavegacionVentas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text('Menú Ventas', style: TextStyle(fontSize: 18)),
          ),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart),
            title: const Text('Registrar Venta'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .establecerModoOperacion(ModoOperacion.venta);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Cotizaciones'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .establecerModoOperacion(ModoOperacion.cotizacion);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Apartados'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .establecerModoOperacion(ModoOperacion.apartado);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Devoluciones'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Cobrar'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario);
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_off),
            title: const Text('Pagar'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pagar — Próximamente')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.discount),
            title: const Text('Descuentos'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descuentos — Próximamente')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Ofertas'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ofertas — Próximamente')),
              );
            },
          ),
        ],
      ),
    );
  }
}
