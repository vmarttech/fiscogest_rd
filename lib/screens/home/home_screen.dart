import 'package:flutter/material.dart';

// ✅ IMPORTACIONES CORRECTAS: USANDO SIEMPRE EL FORMATO package:
import 'package:fiscogestrd/compras/registro_compra_screen.dart';
import 'package:fiscogestrd/ventas/registro_venta_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FiscoGest RD - Menú Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _MenuBoton(
            icono: Icons.add_shopping_cart,
            texto: 'Registrar Compra',
            color: Colors.green.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistroCompraScreen(),
                ),
              );
            },
          ),

          _MenuBoton(
            icono: Icons.point_of_sale,
            texto: 'Registrar Venta',
            color: Colors.red.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegistroVentaScreen(),
                ),
              );
            },
          ),

          // Aquí puedes agregar más botones cuando tengas los módulos listos
          _MenuBoton(
            icono: Icons.inventory_2,
            texto: 'Productos',
            color: Colors.blueGrey,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Módulo próximamente')),
            ),
          ),

          _MenuBoton(
            icono: Icons.people,
            texto: 'Clientes',
            color: Colors.deepPurple,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Módulo próximamente')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuBoton extends StatelessWidget {
  const _MenuBoton({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              texto,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}