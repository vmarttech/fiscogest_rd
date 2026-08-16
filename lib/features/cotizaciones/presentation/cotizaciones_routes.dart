import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/cotizaciones/presentation/pages/lista_cotizaciones_page.dart';

final cotizacionesRoutes = [
  GoRoute(
    path: '/cotizaciones',
    name: ListaCotizacionesPage.routeName,
    builder: (context, state) => const ListaCotizacionesPage(),
  ),
];
