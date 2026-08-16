import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/devoluciones/presentation/pages/lista_devoluciones_page.dart';

final devolucionesRoutes = [
  GoRoute(
    path: '/devoluciones',
    name: ListaDevolucionesPage.routeName,
    builder: (context, state) => const ListaDevolucionesPage(),
  ),
];
