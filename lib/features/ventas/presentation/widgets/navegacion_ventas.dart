import 'package:flutter/material.dart';

class NavegacionVentas extends StatelessWidget {
  const NavegacionVentas({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Menú Ventas', style: TextStyle(fontSize: 18))),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart),
            title: const Text('Registrar Venta'),
            onTap: () {
              Navigator.pop(context);
              DefaultTabController.of(context).animateTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Cotizaciones'),
            onTap: () {
              Navigator.pop(context);
              DefaultTabController.of(context).animateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Apartados'),
            onTap: () {
              Navigator.pop(context);
              DefaultTabController.of(context).animateTo(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Devoluciones'),
            onTap: () {
              Navigator.pop(context);
              DefaultTabController.of(context).animateTo(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Cobrar'),
            onTap: () {
              Navigator.pop(context);
              DefaultTabController.of(context).animateTo(4);
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
