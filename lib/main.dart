import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importaciones de pantallas
import 'package:fiscogestrd/screens/listado_productos_screen.dart';
import 'package:fiscogestrd/screens/listado_clientes.dart';
import 'package:fiscogestrd/screens/formulario_cliente.dart';
import 'package:fiscogestrd/compras/registro_compra_screen.dart';
import 'package:fiscogestrd/ventas/pantalla_venta_unificada.dart';

void main() {
  runApp(const ProviderScope(child: FiscoGestRdApp()));
}

class FiscoGestRdApp extends StatelessWidget {
  const FiscoGestRdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FiscoGest RD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          primary: Color(0xFF0A2463),
          onPrimary: Colors.white,
          secondary: Color(0xFF3E92CC),
          onSecondary: Colors.white,
          tertiary: Color(0xFF2A9134),
          onTertiary: Colors.white,
          error: Color(0xFFE63946),
          onError: Colors.white,
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF1E293B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: const CardThemeData(
          elevation: 2,
          shadowColor: Color(0x1A000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: EdgeInsets.zero,
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(),
      routes: {
        '/productos': (context) => const ListadoProductosScreen(),
        '/clientes': (context) => const ListadoClientes(),
        '/clientes/nuevo': (context) => const FormularioClienteScreen(),
        '/compras': (context) => const RegistroCompraScreen(),
        '/venta': (context) => const PantallaVentaUnificada(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceSeleccionado = 0;

  final List<Widget> _paginas = const [
    _DashboardInicio(),
    PantallaVentaUnificada(),
    _VistaFacturacion(),
    ListadoClientes(),
    ListadoProductosScreen(),
    RegistroCompraScreen(),
    _VistaProveedores(),
    _VistaGastos(),
    _VistaReportes(),
    _VistaConfiguracion(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esPantallaGrande = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.shield, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'FiscoGest RD',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
            centerTitle: false,
          ),
          drawer: esPantallaGrande ? null : _MenuLateral(
            indiceSeleccionado: _indiceSeleccionado,
            alSeleccionar: (i) => setState(() => _indiceSeleccionado = i),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esPantallaGrande)
                SizedBox(
                  width: 240,
                  height: constraints.maxHeight,
                  child: _MenuLateral(
                    indiceSeleccionado: _indiceSeleccionado,
                    alSeleccionar: (i) => setState(() => _indiceSeleccionado = i),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  width: constraints.maxWidth - (esPantallaGrande ? 240 : 0),
                  height: constraints.maxHeight,
                  child: _paginas[_indiceSeleccionado],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuLateral extends StatelessWidget {
  final int indiceSeleccionado;
  final Function(int) alSeleccionar;

  const _MenuLateral({
    required this.indiceSeleccionado,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: indiceSeleccionado,
      onDestinationSelected: (i) {
        alSeleccionar(i);
        Navigator.pop(context);
      },
      backgroundColor: const Color(0xFF0A2463),
      indicatorColor: const Color(0xFF1E40AF),
      children: const [
        DrawerHeader(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF0A2463),
            border: Border(bottom: BorderSide(color: Color(0xFF1E40AF), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'FiscoGest RD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Facturación y Gestión Empresarial',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text('PRINCIPAL', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.dashboard, color: Colors.white, size: 20),
          label: Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.point_of_sale_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.point_of_sale, color: Colors.white, size: 20),
          label: Text('Punto de Venta', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.receipt_long, color: Colors.white, size: 20),
          label: Text('Facturación', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('GESTIÓN', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.people_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.people, color: Colors.white, size: 20),
          label: Text('Clientes', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.inventory_2, color: Colors.white, size: 20),
          label: Text('Inventario', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.add_shopping_cart_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
          label: Text('Compras', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.business_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.business, color: Colors.white, size: 20),
          label: Text('Proveedores', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.money_off_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.money_off, color: Colors.white, size: 20),
          label: Text('Gastos', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('REPORTES', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.bar_chart_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.bar_chart, color: Colors.white, size: 20),
          label: Text('Reportes', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('CONFIGURACIÓN', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
          selectedIcon: Icon(Icons.settings, color: Colors.white, size: 20),
          label: Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}

class _DashboardInicio extends StatelessWidget {
  const _DashboardInicio();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0A2463)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x200A2463), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: const [
                    Icon(Icons.business_center, color: Colors.white, size: 56),
                    SizedBox(height: 24),
                    Text(
                      'Bienvenido a FiscoGest RD',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tu centro de control empresarial',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Aún no hay movimientos registrados.\nComienza creando tu primera venta, cliente o producto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Acciones Rápidas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _BotonAcceso(
                    texto: 'Nueva Venta',
                    icono: Icons.point_of_sale,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.pushNamed(context, '/venta'),
                  ),
                  _BotonAcceso(
                    texto: 'Nuevo Cliente',
                    icono: Icons.person_add,
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.pushNamed(context, '/clientes/nuevo'),
                  ),
                  _BotonAcceso(
                    texto: 'Nuevo Producto',
                    icono: Icons.inventory_2,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushNamed(context, '/productos'),
                  ),
                  _BotonAcceso(
                    texto: 'Nueva Compra',
                    icono: Icons.add_shopping_cart,
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.pushNamed(context, '/compras'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _BotonAcceso extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonAcceso({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _VistaFacturacion extends StatelessWidget {
  const _VistaFacturacion();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Facturación'));
}

class _VistaProveedores extends StatelessWidget {
  const _VistaProveedores();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Proveedores'));
}

class _VistaGastos extends StatelessWidget {
  const _VistaGastos();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Gastos'));
}

class _VistaReportes extends StatelessWidget {
  const _VistaReportes();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Módulo de Reportes'));
}

class _VistaConfiguracion extends StatelessWidget {
  const _VistaConfiguracion();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Configuración del Sistema'));
}
