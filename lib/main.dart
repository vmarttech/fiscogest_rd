import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ IMPORTACIONES SOLO DE LO QUE SE USA (LIMPIO Y HOMOLOGADO)
import 'screens/listado_productos_screen.dart';
import 'screens/listado_clientes.dart';
import 'screens/formulario_cliente.dart';

void main() {
  runApp(const ProviderScope(child: FiscoGestApp()));
}

class FiscoGestApp extends StatelessWidget {
  const FiscoGestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FiscoGest RD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      // ✅ PANTALLA PRINCIPAL ACTUAL (HomeScreen definido abajo)
      home: const HomeScreen(),
      // ✅ RUTAS DE NAVEGACIÓN CORRECTAS
      routes: {
        '/productos': (context) => const ListadoProductosScreen(),
        '/clientes': (context) => const ListadoClientes(),
        '/clientes/nuevo': (context) => const FormularioClienteScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FiscoGest RD - Sistema Fiscal',
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
          // ✅ BOTÓN PRODUCTOS: FUNCIONAL
          _MenuBoton(
            icono: Icons.inventory_2,
            texto: 'Productos',
            color: Colors.blueGrey,
            onTap: () {
              Navigator.pushNamed(context, '/productos');
            },
          ),

          _MenuBoton(
            icono: Icons.storage,
            texto: 'Existencias',
            color: Colors.teal,
            onTap: () => _mostrarMensaje(context, 'Módulo de Existencias'),
          ),

          // ✅ BOTÓN CLIENTES: HOMOLOGADO A ListadoClientes
          _MenuBoton(
            icono: Icons.people,
            texto: 'Clientes',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListadoClientes()),
              );
            },
          ),

          _MenuBoton(
            icono: Icons.receipt_long,
            texto: 'Facturación',
            color: Colors.orange,
            onTap: () => _mostrarMensaje(context, 'Próximamente: Facturación Electrónica'),
          ),

          _MenuBoton(
            icono: Icons.settings,
            texto: 'Configuración',
            color: Colors.grey[700]!,
            onTap: () => _mostrarMensaje(context, 'Configuración del Sistema'),
          ),

          _MenuBoton(
            icono: Icons.info_outline,
            texto: 'Acerca de',
            color: Colors.indigo,
            onTap: () => _mostrarMensaje(context, 'FiscoGest RD © 2026'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}

class _MenuBoton extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _MenuBoton({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
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