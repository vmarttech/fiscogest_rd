import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/pages/almacenes_page.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/store/store_channel.dart';
import 'package:fiscogest_rd/core/legal/legal_page.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/licencia_admin_pedidos_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/licencia_activar_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/licencia_comprar_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/licencia_estado_page.dart';
import 'package:fiscogest_rd/core/ui/fisco_splash.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/presentation/widgets/app_shell.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/productos_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/kardex_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/nuevo_producto_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/registrar_entrada_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/pages/registrar_salida_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/registrar_conteo_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/diferencias_conteo_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/listar_conteos_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/capturar_conteo_page.dart';
import 'package:fiscogest_rd/features/seguridad/presentation/pages/login_page.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/core/auth/permisos.dart';
import 'package:fiscogest_rd/features/seguridad/presentation/pages/usuarios_page.dart';
import 'package:fiscogest_rd/features/seguridad/presentation/pages/setup_cuenta_page.dart';
import 'package:fiscogest_rd/features/seguridad/presentation/pages/recuperar_clave_page.dart';

import 'package:fiscogest_rd/features/ventas/presentation/contenedor/ventas_contenedor_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/nueva_venta_borrador_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cotizaciones_historial_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ventas_historial_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/venta_detalle_page.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/simulador_credito_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/devoluciones_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobro_cxc_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/credito_inicio_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/solicitudes_credito_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/detalle_solicitud_credito_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/detalle_cuenta_cobrar_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/config_credito_page.dart';

import 'package:fiscogest_rd/features/ventas/presentation/pages/caja_inicio_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/caja_historial_turno_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/pagar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/descuentos_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/ofertas_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/fios_lista_page.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/clientes_page.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/clientes_gestion_page.dart';
import 'package:fiscogest_rd/features/clientes/presentation/pages/nuevo_cliente_page.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/pages/proveedores_page.dart';
import 'package:fiscogest_rd/features/reports/presentation/pages/reports_page.dart';
import 'package:fiscogest_rd/features/gastos/presentation/pages/gastos_page.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/pages/ecfe_hub_page.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/pages/ecfe_detalle_page.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/pages/ecfe_spec_page.dart';
import 'package:fiscogest_rd/features/reportes/presentation/pages/detalle_reporte_page.dart';
import 'package:fiscogest_rd/features/reportes/presentation/pages/dashboard_economico_page.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/pages/impuestos_page.dart';
import 'package:fiscogest_rd/features/import_export/presentation/pages/import_export_page.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/lista_ajustes_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/pages/registrar_transferencia_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/recepcion/registrar_recepcion_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/dashboard_compras_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/lista_compras_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/historial_costos_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/lista_cuentas_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/detalle_cuenta_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/registrar_abono_page.dart';
import 'package:fiscogest_rd/features/presentaciones/presentation/pages/presentaciones_page.dart';
import 'package:fiscogest_rd/features/categorias/presentation/pages/categorias_page.dart';
import 'package:fiscogest_rd/features/marcas/presentation/pages/marcas_page.dart';
import 'package:fiscogest_rd/features/unidades/presentation/pages/unidades_page.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pages/facturacion_inicio_page.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pages/secuencias_ncf_page.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pages/emitir_factura_page.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pages/historial_facturas_page.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pages/emitir_nc_page.dart';
import 'package:fiscogest_rd/core/presentation/pages/inicio_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final path = state.uri.path;
      // Rutas públicas (setup solo si el usuario elige Registro en el menú)
      if (path == '/login' ||
          path == '/splash' ||
          path == '/setup-cuenta' ||
          path == '/recuperar-clave' ||
          path == '/legal/privacidad' ||
          path == '/legal/terminos') {
        return null;
      }
      var sesion = ref.read(sesionProvider);
      if (sesion == null) {
        try {
          final db = ref.read(databaseProvider);
          final usuarios = await db.select(db.usuariosTable).get();
          // ignore: avoid_print
          print('ROUTER: path=$path usuarios=${usuarios.length}');
          if (usuarios.isEmpty) {
            ref.read(sesionProvider.notifier).state = const UsuarioSesion(
              id: 0,
              username: 'invitado',
              nombre: 'Modo prueba',
              rol: 'Admin',
              requiereSetupInicial: false,
            );
            sesion = ref.read(sesionProvider);
            // ignore: avoid_print
            print('ROUTER: invitado OK → continuar a $path');
          } else {
            // ignore: avoid_print
            // print('ROUTER: hay usuarios → /login');
            return '/login';
          }
        } catch (e) {
          // ignore: avoid_print
          // print('ROUTER: error al leer usuarios: $e');
          // print(st);
          return '/login';
        }
      }
      if (sesion == null) return '/login';
      // Solo dueño FiscoGest puede administrar pedidos de pago
      if ((path == '/licencia/admin' || path.startsWith('/licencia/admin/')) &&
          !esDuenoPlataforma(sesion.username)) {
        return '/licencia';
      }
      // Tiendas: no checkout de licencia por transferencia dentro de la app
      if (storeOcultaCompraTransferencia &&
          (path == '/licencia/comprar' ||
              path.startsWith('/licencia/comprar/'))) {
        return '/licencia/activar';
      }
      // Plan simplificado: sin módulos fiscales
      try {
        final db = ref.read(databaseProvider);
        final licSvc = LicenciaService(db);
        final lic = await licSvc.obtenerActual();
        final gates = LicenciaGates(lic);
        final path = state.uri.path;
        const fiscalPrefixes = <String>[
          '/ecfe',
          '/impuestos',
          '/taxes',
          '/sales', // hub NCF + emitir/historial/secuencias
        ];
        if (!gates.permiteFiscal) {
          for (final pref in fiscalPrefixes) {
            if (path == pref || path.startsWith('$pref/')) {
              return '/licencia';
            }
          }
        }
        // Fiao solo si el plan lo permite
        if (!gates.permiteFiao &&
            (path == '/ventas/fios' || path.startsWith('/ventas/fios/'))) {
          return '/licencia';
        }
        // Crédito formal solo Pro/Empresa (y demo/dev)
        if (!gates.permiteCreditoFormal &&
            (path == '/creditos' || path.startsWith('/creditos/'))) {
          return '/licencia';
        }
      } catch (_) {}

      // Setup obligatorio SOLO para cuentas reales de fábrica (no invitado).
      // El registro voluntario es por menú → /setup-cuenta.
      final esInvitado =
          sesion.id == 0 || sesion.username.toLowerCase() == 'invitado';
      if (!esInvitado &&
          sesion.requiereSetupInicial &&
          path != '/setup-cuenta') {
        // ignore: avoid_print
        print(
          'ROUTER: requiereSetupInicial → /setup-cuenta (user=${sesion.username})',
        );
        return '/setup-cuenta';
      }
      if (!rutaPermitida(path, sesion)) {
        return rutaFallback(sesion);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/licencia',
        name: LicenciaEstadoPage.routeName,
        builder: (_, __) => const AppShell(child: LicenciaEstadoPage()),
      ),
      GoRoute(
        path: '/licencia/comprar',
        name: LicenciaComprarPage.routeName,
        builder: (_, __) => const AppShell(child: LicenciaComprarPage()),
      ),
      GoRoute(
        path: '/licencia/activar',
        name: LicenciaActivarPage.routeName,
        builder: (_, __) => const AppShell(child: LicenciaActivarPage()),
      ),
      GoRoute(
        path: '/licencia/admin',
        name: LicenciaAdminPedidosPage.routeName,
        builder: (_, __) => const AppShell(child: LicenciaAdminPedidosPage()),
      ),

      GoRoute(
        path: '/splash',
        name: FiscoSplashPage.routeName,
        builder: (_, __) => const FiscoSplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: LoginPage.routeName,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/legal/privacidad',
        name: LegalPage.routePrivacidad,
        builder: (_, __) =>
            const LegalPage(documento: LegalDocumento.privacidad),
      ),
      GoRoute(
        path: '/legal/terminos',
        name: LegalPage.routeTerminos,
        builder: (_, __) => const LegalPage(documento: LegalDocumento.terminos),
      ),
      GoRoute(
        path: '/setup-cuenta',
        name: SetupCuentaPage.routeName,
        builder: (_, __) => const SetupCuentaPage(),
      ),
      GoRoute(
        path: '/recuperar-clave',
        name: RecuperarClavePage.routeName,
        builder: (_, __) => const RecuperarClavePage(),
      ),
      GoRoute(
        path: '/usuarios',
        name: UsuariosPage.routeName,
        builder: (_, __) => const AppShell(child: UsuariosPage()),
      ),

      GoRoute(
        path: '/',
        name: 'inicio',
        builder: (_, __) => const AppShell(child: InicioPage()),
      ),
      GoRoute(
        path: '/sales',
        name: 'facturacion-inicio',
        builder: (context, state) =>
            const AppShell(child: FacturacionInicioPage()),
        routes: [
          GoRoute(
            path: 'emitir-factura',
            name: 'facturacion-emitir-factura',
            builder: (context, state) =>
                const AppShell(child: EmitirFacturaPage()),
          ),
          GoRoute(
            path: 'emitir-nc',
            name: 'facturacion-emitir-nc',
            builder: (context, state) => const AppShell(child: EmitirNcPage()),
          ),
          GoRoute(
            path: 'historial',
            name: 'facturacion-historial',
            builder: (context, state) =>
                const AppShell(child: HistorialFacturasPage()),
          ),
          GoRoute(
            path: 'secuencias-ncf',
            name: 'facturacion-secuencias-ncf',
            builder: (context, state) =>
                const AppShell(child: SecuenciasNcfPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/ventas',
        name: VentasContenedorPage.nombreRuta,
        builder: (_, __) => const AppShell(child: VentasContenedorPage()),
        routes: [
          GoRoute(
            path: 'registrar',
            builder: (_, __) => const AppShell(child: NuevaVentaBorradorPage()),
          ),
          GoRoute(
            path: 'cotizaciones/nueva',
            builder: (_, __) => const AppShell(child: NuevaVentaBorradorPage()),
          ),
          GoRoute(
            path: 'historial/detalle',
            name: VentaDetallePage.routeName,
            builder: (context, state) {
              final extra = state.extra;
              final venta = extra is Venta ? extra : null;
              final idStr = state.uri.queryParameters['id'];
              return AppShell(
                child: VentaDetallePage(
                  venta: venta,
                  ventaId: idStr != null ? int.tryParse(idStr) : null,
                ),
              );
            },
          ),
          GoRoute(
            path: 'historial',
            name: VentasHistorialPage.routeName,
            builder: (_, __) => const AppShell(child: VentasHistorialPage()),
          ),
          GoRoute(
            path: 'cotizaciones/historial',
            name: CotizacionesHistorialPage.routeName,
            builder: (_, __) =>
                const AppShell(child: CotizacionesHistorialPage()),
          ),

          GoRoute(
            path: 'devoluciones',
            name: DevolucionesPage.routeName,
            builder: (_, __) => const AppShell(child: DevolucionesPage()),
          ),
          GoRoute(
            path: 'cobrar',
            name: CobrarPage.routeName,
            builder: (_, __) => const AppShell(child: CobrarPage()),
          ),

          GoRoute(
            path: 'cobro/cxc/:id',
            name: CobroCxcPage.routeName,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return AppShell(child: CobroCxcPage(cuentaId: id));
            },
          ),

          GoRoute(
            path: 'cobro',
            // redirect móvil caja: no hub unificado; solo flujo cotización
            redirect: (context, state) {
              // Móvil: no hub de caja unificada; solo flujo cotización
              double w = 800;
              try {
                w = MediaQuery.sizeOf(context).width;
              } catch (_) {
                final views = WidgetsBinding.instance.platformDispatcher.views;
                if (views.isNotEmpty) {
                  final v = views.first;
                  w = v.physicalSize.width / v.devicePixelRatio;
                }
              }
              if (w < 600) return '/ventas/cotizaciones/nueva';
              return null;
            },
            name: CajaInicioPage.routeName,
            builder: (_, __) => const AppShell(child: CajaInicioPage()),
            routes: [
              // Legacy: misma Caja unificada
              GoRoute(
                path: 'operacion',
                name: 'cobro-venta-operacion-legacy',
                builder: (_, __) => const AppShell(child: CajaInicioPage()),
              ),
              GoRoute(
                path: 'historial-turno',
                name: CajaHistorialTurnoPage.routeName,
                builder: (_, __) =>
                    const AppShell(child: CajaHistorialTurnoPage()),
              ),
            ],
          ),
          GoRoute(
            path: 'pagar',
            name: PagarPage.routeName,
            builder: (_, __) => const AppShell(child: PagarPage()),
          ),
          GoRoute(
            path: 'descuentos',
            name: DescuentosPage.routeName,
            builder: (_, __) => const AppShell(child: DescuentosPage()),
          ),
          GoRoute(
            path: 'ofertas',
            name: OfertasPage.routeName,
            builder: (_, __) => const AppShell(child: OfertasPage()),
          ),
          GoRoute(
            path: 'fios',
            name: FiosListaPage.routeName,
            builder: (_, __) => const AppShell(child: FiosListaPage()),
          ),
        ],
      ),

      GoRoute(
        path: '/creditos',
        name: CreditoInicioPage.routeName,
        builder: (_, __) => const AppShell(child: CreditoInicioPage()),
        routes: [
          GoRoute(
            path: 'config',
            name: ConfigCreditoPage.routeName,
            builder: (_, __) => const AppShell(child: ConfigCreditoPage()),
          ),

          GoRoute(
            path: 'cuentas',
            name: CuentasCobrarPage.routeName,
            builder: (_, __) => const AppShell(child: CuentasCobrarPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: DetalleCuentaCobrarPage.routeName,
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return AppShell(child: DetalleCuentaCobrarPage(cuentaId: id));
                },
              ),
            ],
          ),

          GoRoute(
            path: 'solicitudes',
            name: SolicitudesCreditoPage.routeName,
            builder: (_, __) => const AppShell(child: SolicitudesCreditoPage()),
            routes: [
              GoRoute(
                path: ':ventaId',
                name: DetalleSolicitudCreditoPage.routeName,
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['ventaId'] ?? '') ?? 0;
                  return AppShell(
                    child: DetalleSolicitudCreditoPage(ventaId: id),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/compras',
        name: DashboardComprasPage.routeName,
        builder: (_, __) => const AppShell(child: DashboardComprasPage()),
        routes: [
          GoRoute(
            path: 'lista',
            name: ListaComprasPage.routeName,
            builder: (_, __) => const AppShell(child: ListaComprasPage()),
          ),
          GoRoute(
            path: 'registrar',
            name: RegistrarCompraPage.routeName,
            builder: (_, __) => const AppShell(child: RegistrarCompraPage()),
          ),
          GoRoute(
            path: 'detalle/:compraId',
            name: DetalleCompraPage.routeName,
            builder: (context, state) {
              int compraId = 0;
              final idDesdePath = state.pathParameters['compraId'];
              if (idDesdePath != null && idDesdePath.isNotEmpty) {
                final soloDigitos = idDesdePath.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                compraId = int.tryParse(soloDigitos) ?? 0;
              }
              if (compraId == 0 && state.extra != null) {
                final extra = state.extra;
                if (extra is int) {
                  compraId = extra;
                } else if (extra is String) {
                  final soloDigitos = extra.replaceAll(RegExp(r'[^0-9]'), '');
                  compraId = int.tryParse(soloDigitos) ?? 0;
                }
              }
              return AppShell(child: DetalleCompraPage(compraId: compraId));
            },
          ),
          GoRoute(
            path: 'historial-costos/:productoId',
            name: HistorialCostosPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['productoId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final productoId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(
                child: HistorialCostosPage(productoId: productoId),
              );
            },
          ),
          GoRoute(
            path: 'cuentas-pagar',
            name: ListaCuentasPagarPage.routeName,
            builder: (_, __) => const AppShell(child: ListaCuentasPagarPage()),
          ),
          GoRoute(
            path: 'cuentas-pagar/detalle/:cuentaId',
            name: DetalleCuentaPagarPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['cuentaId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final cuentaId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(
                child: DetalleCuentaPagarPage(cuentaId: cuentaId),
              );
            },
          ),
          GoRoute(
            path: 'cuentas-pagar/registrar-abono/:cuentaId',
            name: RegistrarAbonoPage.routeName,
            builder: (context, state) {
              final idCrudo = state.pathParameters['cuentaId'] ?? '0';
              final soloDigitos = idCrudo.replaceAll(RegExp(r'[^0-9]'), '');
              final cuentaId = int.tryParse(soloDigitos) ?? 0;
              return AppShell(child: RegistrarAbonoPage(cuentaId: cuentaId));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/ventas/simulador-credito',
        name: SimuladorCreditoPage.routeName,
        builder: (_, __) => const AppShell(child: SimuladorCreditoPage()),
      ),
      GoRoute(
        path: '/inventario',
        name: ProductosPage.routeName,
        builder: (_, __) => const AppShell(child: ProductosPage()),
      ),
      GoRoute(
        path: '/kardex',
        name: KardexPage.routeName,
        builder: (_, __) => const AppShell(child: KardexPage()),
      ),
      GoRoute(
        path: '/productos/nuevo',
        name: NuevoProductoPage.routeName,
        builder: (context, state) {
          final extra = state.extra;
          final producto = extra is Producto ? extra : null;
          return AppShell(child: NuevoProductoPage(producto: producto));
        },
      ),
      GoRoute(
        path: '/inventario/entrada/:productoId/:nombreProducto',
        name: RegistrarEntradaPage.routeName,
        builder: (context, state) {
          final productoIdCrudo = state.pathParameters['productoId'] ?? '0';
          final soloDigitosProd = productoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final productoId = int.tryParse(soloDigitosProd) ?? 0;
          final nombreProducto = Uri.decodeComponent(
            state.pathParameters['nombreProducto'] ?? '',
          );
          return AppShell(
            child: RegistrarEntradaPage(
              productoId: productoId,
              nombreProducto: nombreProducto,
            ),
          );
        },
      ),
      GoRoute(
        path: '/inventario/salida/:productoId/:nombreProducto',
        name: RegistrarSalidaPage.routeName,
        builder: (context, state) {
          final productoIdCrudo = state.pathParameters['productoId'] ?? '0';
          final soloDigitosProd = productoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final productoId = int.tryParse(soloDigitosProd) ?? 0;
          final nombreProducto = Uri.decodeComponent(
            state.pathParameters['nombreProducto'] ?? '',
          );
          return AppShell(
            child: RegistrarSalidaPage(
              productoId: productoId,
              nombreProducto: nombreProducto,
            ),
          );
        },
      ),
      GoRoute(
        path: '/inventario-fisico',
        name: RegistrarConteoPage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarConteoPage()),
      ),
      GoRoute(
        path: '/inventario-fisico/listar',
        name: ListarConteosPage.routeName,
        builder: (_, __) => const AppShell(child: ListarConteosPage()),
      ),
      GoRoute(
        path: '/inventario-fisico/nuevo',
        redirect: (_, __) => '/inventario-fisico',
      ),
      GoRoute(
        path: '/inventario-fisico/capturar/:conteoId',
        name: CapturarConteoPage.routeName,
        builder: (context, state) {
          final idRaw = state.pathParameters['conteoId'] ?? '0';
          final id = int.tryParse(idRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return AppShell(child: CapturarConteoPage(conteoId: id));
        },
      ),
      GoRoute(
        path: '/diferencias-conteo-fisico/:conteoId',
        name: DiferenciasConteoPage.routeName,
        builder: (context, state) {
          final conteoIdCrudo = state.pathParameters['conteoId'] ?? '0';
          final soloDigitosConteo = conteoIdCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final conteoId = int.tryParse(soloDigitosConteo) ?? 0;
          return AppShell(child: DiferenciasConteoPage(conteoId: conteoId));
        },
      ),
      GoRoute(
        path: '/lista-ajustes',
        name: ListaAjustesPage.routeName,
        builder: (_, __) => const AppShell(child: ListaAjustesPage()),
      ),
      GoRoute(
        path: '/registrar-ajuste',
        name: RegistrarAjustePage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarAjustePage()),
      ),
      GoRoute(
        path: '/clientes',
        name: ClientesGestionPage.routeName,
        builder: (_, __) => const AppShell(child: ClientesGestionPage()),
        routes: [
          GoRoute(
            path: 'nuevo',
            name: NuevoClientePage.routeName,
            builder: (_, __) => const AppShell(child: NuevoClientePage()),
          ),
          GoRoute(
            path: 'editar',
            name: NuevoClientePage.editRouteName,
            builder: (context, state) => AppShell(
              child: NuevoClientePage(cliente: state.extra as ClienteCompleto?),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/clientes/detalle',
        name: 'cliente-detalle',
        builder: (context, state) {
          final c = state.extra;
          if (c is! ClienteCompleto) {
            return const AppShell(child: ClientesGestionPage());
          }
          return AppShell(child: ClienteDetallePage.fromCliente(c));
        },
      ),
      GoRoute(path: '/customers', redirect: (_, __) => '/clientes'),
      GoRoute(path: '/clients', redirect: (_, __) => '/clientes'),
      GoRoute(
        path: '/clientes/gestion',
        name: ClientesPage.routeName,
        builder: (_, __) => const AppShell(child: ClientesPage()),
      ),
      GoRoute(
        path: '/proveedores',
        name: ProveedoresPage.routeName,
        builder: (_, __) => const AppShell(child: ProveedoresPage()),
      ),
      GoRoute(path: '/suppliers', redirect: (_, __) => '/proveedores'),
      GoRoute(
        path: '/recepcion/:compraId/:proveedorId',
        name: RegistrarRecepcionPage.routeName,
        builder: (context, state) {
          final idCompraCrudo = state.pathParameters['compraId']!;
          final compraIdLimpio = idCompraCrudo.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final compraId = int.tryParse(compraIdLimpio) ?? 0;
          final idProvCrudo = state.pathParameters['proveedorId']!;
          final provIdLimpio = idProvCrudo.replaceAll(RegExp(r'[^0-9]'), '');
          final proveedorId = int.tryParse(provIdLimpio) ?? 0;
          return AppShell(
            child: RegistrarRecepcionPage(
              compraId: compraId,
              proveedorId: proveedorId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/transferencias/registrar',
        name: RegistrarTransferenciaPage.routeName,
        builder: (_, __) => const AppShell(child: RegistrarTransferenciaPage()),
      ),
      GoRoute(
        path: '/presentaciones',
        name: PresentacionesPage.routeName,
        builder: (_, __) => const AppShell(child: PresentacionesPage()),
      ),
      GoRoute(
        path: '/categorias',
        name: CategoriasPage.routeName,
        builder: (_, __) => const AppShell(child: CategoriasPage()),
      ),
      GoRoute(
        path: '/marcas',
        name: MarcasPage.routeName,
        builder: (_, __) => const AppShell(child: MarcasPage()),
      ),
      GoRoute(
        path: '/almacenes',
        name: AlmacenesPage.routeName,
        builder: (_, __) => const AppShell(child: AlmacenesPage()),
      ),
      GoRoute(
        path: '/unidades',
        name: UnidadesPage.routeName,
        builder: (_, __) => const AppShell(child: UnidadesPage()),
      ),
      GoRoute(
        path: '/ecfe',
        name: EcfeHubPage.routeName,
        builder: (_, __) => const AppShell(child: EcfeHubPage()),
      ),
      GoRoute(
        path: '/ecfe/spec',
        name: EcfeSpecPage.routeName,
        builder: (_, __) => const AppShell(child: EcfeSpecPage()),
      ),
      GoRoute(
        path: '/ecfe/:id',
        name: EcfeDetallePage.routeName,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AppShell(child: EcfeDetallePage(documentoId: id));
        },
      ),
      GoRoute(
        path: '/gastos',
        name: GastosPage.routeName,
        builder: (_, __) => const AppShell(child: GastosPage()),
      ),
      GoRoute(
        path: '/reports',
        name: 'dashboard-reportes',
        builder: (_, __) => const AppShell(child: DashboardEconomicoPage()),
        routes: [
          GoRoute(
            path: 'hub',
            name: ReportsPage.routeName,
            builder: (_, __) => const AppShell(child: ReportsPage()),
          ),
          GoRoute(
            path: 'detalle/:tipo',
            name: DetalleReportePage.routeName,
            builder: (context, state) {
              final tipo = state.pathParameters['tipo'] ?? 'ventas';
              return AppShell(child: DetalleReportePage(tipo: tipo));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/impuestos',
        name: ImpuestosPage.routeName,
        builder: (_, __) => const AppShell(child: ImpuestosPage()),
      ),
      GoRoute(path: '/taxes', redirect: (_, __) => '/impuestos'),
      GoRoute(
        path: '/import-export',
        name: ImportExportPage.routeName,
        builder: (_, __) => const AppShell(child: ImportExportPage()),
      ),
      GoRoute(path: '/import', redirect: (_, __) => '/import-export'),
      GoRoute(
        path: '/configuracion',
        name: ConfiguracionPage.routeName,
        builder: (_, __) => const AppShell(child: ConfiguracionPage()),
      ),
      GoRoute(path: '/settings', redirect: (_, __) => '/configuracion'),
    ],
  );
});
