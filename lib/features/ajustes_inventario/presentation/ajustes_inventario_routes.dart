import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/lista_ajustes_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';

final ajustesInventarioRoutes = [
  GoRoute(
    path: '/ajustes-inventario',
    name: ListaAjustesPage.routeName,
    builder: (context, state) => const ListaAjustesPage(),
  ),
  GoRoute(
    path: '/ajustes-inventario/nuevo',
    name: RegistrarAjustePage.routeName,
    builder: (context, state) => const RegistrarAjustePage(),
  ),
];