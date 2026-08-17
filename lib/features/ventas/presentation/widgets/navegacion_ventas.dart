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
            onTap: () => Navigator.pushNamed(context, '/ventas/registrar'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Cotizaciones'),
            onTap: () => Navigator.pushNamed(context, '/ventas/cotizaciones'),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Apartados'),
            onTap: () => Navigator.pushNamed(context, '/ventas/apartados'),
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Devoluciones'),
            onTap: () => Navigator.pushNamed(context, '/ventas/devoluciones'),
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Cobrar'),
            onTap: () => Navigator.pushNamed(context, '/ventas/cobrar'),
          ),
          ListTile(
            leading: const Icon(Icons.money_off),
            title: const Text('Pagar'),
            onTap: () => Navigator.pushNamed(context, '/ventas/pagar'),
          ),
          ListTile(
            leading: const Icon(Icons.discount),
            title: const Text('Descuentos'),
            onTap: () => Navigator.pushNamed(context, '/ventas/descuentos'),
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Ofertas'),
            onTap: () => Navigator.pushNamed(context, '/ventas/ofertas'),
          ),
        ],
      ),
    );
  }
}
