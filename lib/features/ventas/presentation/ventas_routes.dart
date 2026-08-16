import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/lista_ventas_page.dart';

final ventasRoutes = [
  GoRoute(
    path: '/ventas',
    name: ListaVentasPage.routeName,
    builder: (context, state) => const ListaVentasPage(),
  ),
];
