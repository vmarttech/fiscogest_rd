import 'package:fiscogest_rd/core/sync/supabase/renovar_token.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

/// Baja datos de Supabase → Drift para el negocio actual.
class SyncPull {
  SyncPull(this._db);
  final AppDatabase _db;
  final _client = SupabaseRestClient();
  static const _maxNombreUsuarioLength = 80;

  Future<void> pullTodoElNegocio() async {
    await RenovarToken.asegurar();
    if (!SupabaseConfig.isConfigured) {
      debugPrint('SyncPull: Supabase no configurado');
      return;
    }
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('SyncPull: sin negocio_id');
      return;
    }
    debugPrint('SyncPull: negocio=$negocioId');

    await _pullUsuarios(negocioId);
    await _pullProductos(negocioId);
    await _pullClientes(negocioId);
    await _pullPedidos(negocioId);
    await _pullDispositivos(negocioId);
    await _pullVentas(negocioId);
    await _pullCaja(negocioId);
    await _pullFios(negocioId);

    debugPrint('SyncPull: OK');
  }

  Future<void> _pullUsuarios(String negocioId) async {
    final rows = await _client.select(
      table: 'usuarios',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final username = (r['username'] as String?)?.trim() ?? '';
      if (username.isEmpty) continue;

      final existing = await (_db.select(_db.usuariosTable)
            ..where((t) => t.username.equals(username)))
          .getSingleOrNull();

      final nombreRecibido = (r['nombre'] as String?)?.trim() ?? '';
      // Do not let malformed remote data replace a valid local name.
      final nombreSeguro = nombreRecibido.isNotEmpty &&
              nombreRecibido.length <= _maxNombreUsuarioLength
          ? nombreRecibido
          : null;
      final rol = (r['rol'] as String?) ?? 'Vendedor';
      final activo = r['activo'] == true;
      final hash = (r['password_hash'] as String?)?.trim() ?? '';

      if (existing == null) {
        await _db.into(_db.usuariosTable).insert(
              UsuariosTableCompanion.insert(
                nombre: nombreSeguro ?? username,
                username: username,
                passwordHash: hash,
                apellido: const Value(''),
                email: const Value(null),
                rol: Value(rol),
                estado: Value(activo ? 'Activo' : 'Inactivo'),
                requiereSetupInicial: const Value(false),
              ),
            );
      } else {
        await (_db.update(_db.usuariosTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          UsuariosTableCompanion(
            nombre: nombreSeguro == null
                ? const Value.absent()
                : Value(nombreSeguro),
            rol: Value(rol),
            estado: Value(activo ? 'Activo' : 'Inactivo'),
            // Si la nube trae hash, SIEMPRE actualizar local
            passwordHash: hash.isNotEmpty
                ? Value(hash)
                : const Value.absent(),
            requiereSetupInicial: const Value(false),
          ),
        );
      }
    }
    debugPrint('SyncPull: usuarios ${rows.length}');
  }

  Future<void> _pullProductos(String negocioId) async {
    final rows = await _client.select(
      table: 'productos',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final idLocal = r['id_local'];
      final codigo = (r['codigo'] as String?) ?? '';
      final nombre = (r['nombre'] as String?) ?? '';
      if (codigo.isEmpty && nombre.isEmpty) continue;

      ProductoData? existing;
      if (idLocal is int) {
        existing = await (_db.select(_db.productosTable)
              ..where((t) => t.id.equals(idLocal)))
            .getSingleOrNull();
      }
      if (existing == null && codigo.isNotEmpty) {
        existing = await (_db.select(_db.productosTable)
              ..where((t) => t.codigo.equals(codigo)))
            .getSingleOrNull();
      }

      final precioVenta = _toDouble(r['precio_venta']);
      final precioCompra = _toDouble(r['precio_compra']);
      final stock = _toDouble(r['stock']);
      final rawActivo = r['activo'];
      final activo = (rawActivo == false || rawActivo == 0) ? 0 : 1;

      if (existing == null) {
        if (activo == 0) continue;
        await _db.into(_db.productosTable).insert(
              ProductosTableCompanion.insert(
                codigo: codigo.isEmpty ? 'P-${DateTime.now().millisecondsSinceEpoch}' : codigo,
                nombre: nombre.isEmpty ? codigo : nombre,
                categoriaId: 0,
                marcaId: 0,
                unidadMedidaId: 0,
                precioVenta: Value(precioVenta),
                precioCompra: Value(precioCompra),
                stock: Value(stock),
                activo: Value(activo),
              ),
            );
      } else {
        // Soft-delete local gana: no reactivar con activo=1 del remoto
        // (si el push aún no propagó activo=false).
        final activoFinal = existing.activo == 0 ? 0 : activo;
        await (_db.update(_db.productosTable)
              ..where((t) => t.id.equals(existing!.id)))
            .write(
          ProductosTableCompanion(
            codigo: Value(codigo.isEmpty ? existing.codigo : codigo),
            nombre: Value(nombre.isEmpty ? existing.nombre : nombre),
            precioVenta: Value(precioVenta),
            precioCompra: Value(precioCompra),
            stock: Value(stock),
            activo: Value(activoFinal),
          ),
        );
      }
    }
    debugPrint('SyncPull: productos ${rows.length}');
  }

  Future<void> _pullClientes(String negocioId) async {
    final rows = await _client.select(
      table: 'clientes',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final idLocal = r['id_local'];
      final codigo = (r['codigo'] as String?) ?? '';
      final nombre = (r['nombre'] as String?) ?? '';
      if (nombre.isEmpty) continue;

      dynamic existing;
      if (idLocal is int) {
        existing = await (_db.select(_db.clientesTable)
              ..where((t) => t.id.equals(idLocal)))
            .getSingleOrNull();
      }
      if (existing == null && codigo.isNotEmpty) {
        existing = await (_db.select(_db.clientesTable)
              ..where((t) => t.codigo.equals(codigo)))
            .getSingleOrNull();
      }

      final telefono = (r['telefono'] as String?) ?? '';
      final rnc = (r['rnc_cedula'] as String?) ?? '';
      final activo = r['activo'] != false;

      if (existing == null) {
        final cod = codigo.isEmpty
            ? 'CLI-${DateTime.now().millisecondsSinceEpoch}'
            : codigo;
        await _db.into(_db.clientesTable).insert(
              ClientesTableCompanion.insert(
                codigo: cod,
                nombre: nombre,
                rncCedula: rnc,
                telefono: telefono,
                correo: '',
                direccion: '',
                activo: Value(activo),
              ),
            );
      } else {
        await (_db.update(_db.clientesTable)
              ..where((t) => t.id.equals(existing.id as int)))
            .write(
          ClientesTableCompanion(
            nombre: Value(nombre),
            telefono: Value(telefono),
            rncCedula: Value(rnc),
            activo: Value(activo),
          ),
        );
      }
    }
    debugPrint('SyncPull: clientes ${rows.length}');
  }

  Future<void> _pullPedidos(String negocioId) async {
    final rows = await _client.select(
      table: 'pedidos_licencia',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final ref = (r['referencia'] as String?) ?? '';
      if (ref.isEmpty) continue;

      final existing = await (_db.select(_db.pedidosLicenciaTable)
            ..where((t) => t.referencia.equals(ref)))
          .getSingleOrNull();

      final plan = (r['plan'] as String?) ?? '';
      final vigencia = (r['vigencia_tipo'] as String?) ?? '';
      final monto = _toDouble(r['monto']);
      final estado = (r['estado'] as String?) ?? 'pendiente_pago';
      final created = (r['created_at'] as String?) ?? DateTime.now().toIso8601String();
      final expires = (r['expires_at'] as String?) ?? '';

      if (existing == null) {
        await _db.into(_db.pedidosLicenciaTable).insert(
              PedidosLicenciaTableCompanion.insert(
                referencia: ref,
                plan: plan,
                vigenciaTipo: vigencia,
                monto: monto,
                estado: estado,
                fechaCreacion: created,
                fechaExpiracionPedido: expires,
              ),
            );
      } else {
        await (_db.update(_db.pedidosLicenciaTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          PedidosLicenciaTableCompanion(
            plan: Value(plan),
            vigenciaTipo: Value(vigencia),
            monto: Value(monto),
            estado: Value(estado),
            fechaExpiracionPedido: Value(expires),
          ),
        );
      }
    }
    debugPrint('SyncPull: pedidos ${rows.length}');
  }

  Future<void> _pullDispositivos(String negocioId) async {
    final rows = await _client.select(
      table: 'dispositivos_licencia',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final fp = (r['fingerprint'] as String?) ?? '';
      if (fp.isEmpty) continue;

      final existing = await (_db.select(_db.dispositivosLicenciaTable)
            ..where((t) => t.fingerprint.equals(fp)))
          .getSingleOrNull();

      final remoteId = r['id']?.toString();
      final alias = (r['alias'] as String?) ?? 'Equipo';
      final plataforma = (r['plataforma'] as String?) ?? 'android';
      final tipo = (r['tipo'] as String?) ?? 'movil';
      final activo = r['activo'] != false;
      final reg = (r['registrado_en'] as String?) ?? DateTime.now().toIso8601String();
      final uso = (r['ultimo_uso'] as String?) ?? reg;

      if (existing == null) {
        await _db.into(_db.dispositivosLicenciaTable).insert(
              DispositivosLicenciaTableCompanion.insert(
                fingerprint: fp,
                plataforma: plataforma,
                registradoEn: reg,
                ultimoUso: uso,
                remoteId: Value(remoteId),
                negocioId: Value(negocioId),
                alias: Value(alias),
                tipo: Value(tipo),
                activo: Value(activo),
                pendienteSync: const Value(false),
              ),
            );
      } else {
        await (_db.update(_db.dispositivosLicenciaTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          DispositivosLicenciaTableCompanion(
            remoteId: Value(remoteId),
            negocioId: Value(negocioId),
            alias: Value(alias),
            plataforma: Value(plataforma),
            tipo: Value(tipo),
            activo: Value(activo),
            ultimoUso: Value(uso),
            pendienteSync: const Value(false),
          ),
        );
      }
    }
    debugPrint('SyncPull: dispositivos ${rows.length}');
  }



  Future<void> _pullVentas(String negocioId) async {
    final ventas = await _client.select(
      table: 'ventas',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in ventas) {
      final idLocal = r['id_local'];
      if (idLocal is! int) continue;
      final existing = await (_db.select(_db.ventasTable)
            ..where((t) => t.id.equals(idLocal)))
          .getSingleOrNull();

      final fecha = DateTime.tryParse('${r['fecha'] ?? ''}') ?? DateTime.now();
      final fechaReg =
          DateTime.tryParse('${r['fecha_registro'] ?? ''}') ?? fecha;
      final venc = r['vencimiento'] != null
          ? DateTime.tryParse('${r['vencimiento']}')
          : null;
      final fComp = r['fecha_comprobante_entrega'] != null
          ? DateTime.tryParse('${r['fecha_comprobante_entrega']}')
          : null;

      if (existing == null) {
        // Insertar con id forzado no siempre es posible con autoIncrement;
        // usamos insert normal y mapeamos por id_local en updates posteriores.
        await _db.into(_db.ventasTable).insert(
              VentasTableCompanion.insert(
                clienteId: (r['cliente_id_local'] as int?) ?? 0,
                fecha: fecha,
                formaPago: (r['forma_pago'] as String?) ?? 'efectivo',
                numeroCotizacion: (r['numero_cotizacion'] as String?) ?? '',
                estadoDocumento: (r['estado_documento'] as String?) ?? 'venta',
                usuarioId: (r['usuario_id_local'] as int?) ?? 0,
                fechaRegistro: fechaReg,
                nombreCliente: Value(r['nombre_cliente'] as String?),
                clienteTelefono: Value(r['cliente_telefono'] as String?),
                clienteWhatsapp: Value(r['cliente_whatsapp'] as String?),
                clienteDireccion: Value(r['cliente_direccion'] as String?),
                montoSubtotal: Value(_toDouble(r['monto_subtotal'])),
                descuentoGlobal: Value(_toDouble(r['descuento_global'])),
                itbis: Value(_toDouble(r['itbis'])),
                montoTotal: Value(_toDouble(r['monto_total'])),
                costoEnvio: Value(_toDouble(r['costo_envio'])),
                abonoInicial: Value(_toDouble(r['abono_inicial'])),
                numeroCuotas: Value((r['numero_cuotas'] as int?) ?? 1),
                plazoDias: Value((r['plazo_dias'] as int?) ?? 30),
                tasaInteres: Value(_toDouble(r['tasa_interes'])),
                montoInteres: Value(_toDouble(r['monto_interes'])),
                vencimiento: Value(venc),
                numeroFactura: Value(r['numero_factura'] as String?),
                descuentoId: Value(r['descuento_id'] as int?),
                descuentoNombre: Value(r['descuento_nombre'] as String?),
                montoDescuento: Value(_toDouble(r['monto_descuento'])),
                comprobanteEntregaImpreso:
                    Value(r['comprobante_entrega_impreso'] == true),
                fechaComprobanteEntrega: Value(fComp),
              ),
            );
      } else {
        await (_db.update(_db.ventasTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          VentasTableCompanion(
            nombreCliente: Value(r['nombre_cliente'] as String?),
            montoTotal: Value(_toDouble(r['monto_total'])),
            formaPago: Value((r['forma_pago'] as String?) ?? existing.formaPago),
            estadoDocumento: Value(
              (r['estado_documento'] as String?) ?? existing.estadoDocumento,
            ),
          ),
        );
      }
    }
    debugPrint('SyncPull: ventas ${ventas.length}');

    final dets = await _client.select(
      table: 'ventas_detalle',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in dets) {
      final idLocal = r['id_local'];
      final ventaIdLocal = r['venta_id_local'];
      if (idLocal is! int || ventaIdLocal is! int) continue;
      final existing = await (_db.select(_db.ventasDetalleTable)
            ..where((t) => t.id.equals(idLocal)))
          .getSingleOrNull();
      if (existing != null) continue;
      // Solo insert si la venta local existe
      final venta = await (_db.select(_db.ventasTable)
            ..where((t) => t.id.equals(ventaIdLocal)))
          .getSingleOrNull();
      if (venta == null) continue;
      try {
        await _db.into(_db.ventasDetalleTable).insert(
              VentasDetalleTableCompanion.insert(
                ventaId: ventaIdLocal,
                productoId: (r['producto_id_local'] as int?) ?? 0,
                cantidad: _toDouble(r['cantidad']),
                precioUnitario: _toDouble(r['precio_unitario']),
                subtotal: _toDouble(r['subtotal']),
                impuesto: _toDouble(r['impuesto']),
                descuentoLinea: Value(_toDouble(r['descuento_linea'])),
              ),
            );
      } catch (e) {
        debugPrint('SyncPull detalle venta skip: $e');
      }
    }
    debugPrint('SyncPull: ventas_detalle ${dets.length}');
  }

  Future<void> _pullCaja(String negocioId) async {
    final sesiones = await _client.select(
      table: 'caja_sesiones',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    debugPrint('SyncPull: caja_sesiones ${sesiones.length} (push prioritario en v1)');
    final movs = await _client.select(
      table: 'caja_movimientos',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    debugPrint('SyncPull: caja_movimientos ${movs.length} (push prioritario en v1)');
  }

  Future<void> _pullFios(String negocioId) async {
    final rows = await _client.select(
      table: 'fios',
      filters: {'negocio_id': 'eq.$negocioId'},
    );
    for (final r in rows) {
      final idLocal = r['id_local'];
      final nombre = (r['nombre_cliente'] as String?) ?? '';
      if (nombre.isEmpty) continue;
      dynamic existing;
      if (idLocal is int) {
        existing = await (_db.select(_db.fiosTable)
              ..where((t) => t.id.equals(idLocal)))
            .getSingleOrNull();
      }
      final fecha = DateTime.tryParse('${r['fecha'] ?? ''}') ?? DateTime.now();
      if (existing == null) {
        await _db.into(_db.fiosTable).insert(
              FiosTableCompanion.insert(
                nombreCliente: nombre,
                montoOriginal: _toDouble(r['monto_original']),
                saldoPendiente: _toDouble(r['saldo_pendiente']),
                montoAbonado: Value(_toDouble(r['monto_abonado'])),
                fecha: Value(fecha),
                nota: Value(r['nota'] as String?),
                estado: Value((r['estado'] as String?) ?? 'pendiente'),
                ventaId: Value(r['venta_id_local'] as int?),
              ),
            );
      } else {
        await (_db.update(_db.fiosTable)
              ..where((t) => t.id.equals(existing.id as int)))
            .write(
          FiosTableCompanion(
            montoAbonado: Value(_toDouble(r['monto_abonado'])),
            saldoPendiente: Value(_toDouble(r['saldo_pendiente'])),
            estado: Value((r['estado'] as String?) ?? 'pendiente'),
          ),
        );
      }
    }
    debugPrint('SyncPull: fios ${rows.length}');
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
