import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/providers/gastronomia_providers.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/utils/gastro_whatsapp.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/utils/comanda_cocina.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';

class DeliveryHubPage extends ConsumerWidget {
  const DeliveryHubPage({super.key});
  static const routeName = 'delivery-hub';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(pedidosGastroPendientesProvider);
    final sectores = ref.watch(sectoresDeliveryProvider);
    final repartidores = ref.watch(repartidoresProvider);
    final resumen = ref.watch(resumenRepartidoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery · Gastronomía'),
        actions: [
          IconButton(
            tooltip: 'Compartir menú por WhatsApp',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => _compartirMenu(context, ref),
          ),
          TextButton.icon(
            onPressed: () => _nuevoPedidoDelivery(context, ref),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nuevo pedido'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevoPedidoDelivery(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pedido'),
      ),
      body: ListView(children: [
        // ── Sectores ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Expanded(
              child: Text('Sectores',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            TextButton.icon(
              onPressed: () => _dialogoSector(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ]),
        ),
        sectores.when(
          data: (list) => Column(children: [
            for (final sec in list)
              ListTile(
                leading: const Icon(Icons.place),
                title: Text(sec.nombre),
                subtitle: Text(
                  'Tarifa RD\$ ${sec.tarifaEnvio.toStringAsFixed(2)}'
                  '${sec.montoMinimoEnvioGratis > 0 ? ' · gratis desde RD\$ ${sec.montoMinimoEnvioGratis.toStringAsFixed(0)}' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _dialogoSector(context, ref, existente: sec),
                ),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin sectores. Agrega uno para calcular envíos.'),
              ),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error sectores: $e'),
          ),
        ),

        const Divider(),

        // ── Repartidores ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            const Expanded(
              child: Text('Repartidores',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            TextButton.icon(
              onPressed: () => _dialogoRepartidor(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ]),
        ),
        repartidores.when(
          data: (list) => Column(children: [
            for (final r in list)
              ListTile(
                leading: const Icon(Icons.delivery_dining),
                title: Text(r.nombre),
                subtitle: Text(r.telefono.isEmpty ? 'Sin teléfono' : r.telefono),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _dialogoRepartidor(context, ref, existente: r),
                ),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin repartidores configurados.'),
              ),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error repartidores: $e'),
          ),
        ),

        const Divider(),

        // ── Efectivo por repartidor (H3) ──
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Efectivo por repartidor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        resumen.when(
          data: (list) => Column(children: [
            for (final r in list)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(r.nombre),
                subtitle: Text(
                  'Entregados: ${r.pedidosEntregados} · Cobrados: ${r.pedidosCobrados}\n'
                  'Cobrado: RD\$ ${r.montoCobrado.toStringAsFixed(2)} · '
                  'Pendiente: RD\$ ${r.montoPendiente.toStringAsFixed(2)}',
                ),
                isThreeLine: true,
                trailing: r.montoPendiente > 0.01
                    ? const Icon(Icons.warning_amber_outlined, color: Colors.orange)
                    : const Icon(Icons.check_circle_outline, color: Colors.green),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin pedidos entregados todavía.'),
              ),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error resumen: $e'),
          ),
        ),

        const Divider(),

        // ── Pedidos pendientes ──
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Pedidos pendientes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        pedidos.when(
          data: (list) => Column(children: [
            for (final pe in list)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.motorcycle),
                  title: Text('#${pe.id} · ${pe.nombreCliente}'),
                  subtitle: Text(
                    '${pe.ventaId != null ? 'Cobrado #${pe.ventaId}' : 'Pendiente de cobro'} · '
                    '${pe.estadoEntrega} · RD\$ ${pe.total.toStringAsFixed(2)}'
                    '${pe.telefono.isNotEmpty ? ' · ${pe.telefono}' : ''}',
                  ),
                  isThreeLine: pe.telefono.isNotEmpty,
                  trailing: Wrap(spacing: 0, children: [
                    if (pe.telefono.trim().isNotEmpty)
                      IconButton(
                        tooltip: 'WhatsApp cliente',
                        icon: const Icon(Icons.chat),
                        onPressed: () async {
                          final msg = GastroWhatsapp.mensajePedido(
                            pedidoId: pe.id,
                            nombreCliente: pe.nombreCliente,
                            total: pe.total,
                            estado: pe.estado,
                            direccion: pe.direccionReferencia,
                          );
                          final ok = await GastroWhatsapp.abrir(pe.telefono, mensaje: msg);
                          if (!context.mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo abrir WhatsApp')),
                            );
                          }
                        },
                      ),
                    IconButton(
                      tooltip: 'Comanda cocina',
                      icon: const Icon(Icons.receipt_outlined),
                      onPressed: () async {
                        final lineas = await ref.read(gastronomiaServiceProvider).lineasDePedido(pe.id);
                        if (!context.mounted) return;
                        await ComandaCocina.compartir(pe, lineas);
                      },
                    ),
                    if (pe.ventaId == null)
                      TextButton.icon(
                        onPressed: () => _cobrarPedido(context, ref, pe),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Cobrar'),
                      ),
                    IconButton(
                      tooltip: 'Asignar repartidor',
                      icon: const Icon(Icons.person_add_alt),
                      onPressed: () => _asignarRepartidor(context, ref, pe.id),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(gastronomiaServiceProvider)
                            .actualizarEstadoPedido(pe.id, 'en_preparacion');
                        ref.invalidate(pedidosGastroPendientesProvider);
                      },
                      child: const Text('En cocina'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(gastronomiaServiceProvider)
                            .actualizarEstadoPedido(pe.id, 'en_camino');
                        ref.invalidate(pedidosGastroPendientesProvider);
                      },
                      child: const Text('En camino'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(gastronomiaServiceProvider)
                            .actualizarEstadoPedido(pe.id, 'entregado');
                        ref.invalidate(pedidosGastroPendientesProvider);
                      },
                      child: const Text('Entregado'),
                    ),
                    IconButton(
                      tooltip: 'Cancelar pedido',
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: () async {
                        await ref.read(gastronomiaServiceProvider).cancelarPedido(pe.id);
                        ref.invalidate(pedidosGastroPendientesProvider);
                      },
                    ),
                  ]),
                ),
              ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sin pedidos pendientes.'),
              ),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error pedidos: $e'),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  static Future<void> _dialogoSector(
    BuildContext context,
    WidgetRef ref, {
    SectorDelivery? existente,
  }) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final tarifaCtrl = TextEditingController(
        text: existente != null ? existente.tarifaEnvio.toStringAsFixed(2) : '0');
    final gratisCtrl = TextEditingController(
        text: existente != null
            ? existente.montoMinimoEnvioGratis.toStringAsFixed(0)
            : '0');

    final ok = await AppDialog.show<bool>(
      context,
      title: existente == null ? 'Nuevo sector' : 'Editar sector',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del sector',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: tarifaCtrl,
            decoration: const InputDecoration(
              labelText: 'Tarifa de envío',
              prefixText: 'RD\$ ',
              prefixIcon: Icon(Icons.local_shipping_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: gratisCtrl,
            decoration: const InputDecoration(
              labelText: 'Envío gratis desde (0 = no aplica)',
              prefixText: 'RD\$ ',
              prefixIcon: Icon(Icons.card_giftcard_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        if (existente != null)
          TextButton(
            onPressed: () async {
              await ref.read(gastronomiaServiceProvider).desactivarSector(existente.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    );

    if (ok != true) return;
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final tarifa = double.tryParse(tarifaCtrl.text.replaceAll(',', '.')) ?? 0;
    final gratis = double.tryParse(gratisCtrl.text.replaceAll(',', '.')) ?? 0;

    await ref.read(gastronomiaServiceProvider).guardarSector(
          SectorDelivery(
            id: existente?.id ?? 0,
            nombre: nombre,
            tarifaEnvio: tarifa,
            montoMinimoEnvioGratis: gratis,
            orden: existente?.orden ?? 0,
          ),
        );
    ref.invalidate(sectoresDeliveryProvider);
  }

  static Future<void> _dialogoRepartidor(
    BuildContext context,
    WidgetRef ref, {
    Repartidor? existente,
  }) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final telCtrl = TextEditingController(text: existente?.telefono ?? '');

    final ok = await AppDialog.show<bool>(
      context,
      title: existente == null ? 'Nuevo repartidor' : 'Editar repartidor',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: telCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono / WhatsApp',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        if (existente != null)
          TextButton(
            onPressed: () async {
              await ref.read(gastronomiaServiceProvider).desactivarRepartidor(existente.id);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Guardar'),
        ),
      ],
    );

    if (ok != true) return;
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) return;

    await ref.read(gastronomiaServiceProvider).guardarRepartidor(
          Repartidor(
            id: existente?.id ?? 0,
            nombre: nombre,
            telefono: telCtrl.text.trim(),
          ),
        );
    ref.invalidate(repartidoresProvider);
  }

  static Future<void> _asignarRepartidor(
    BuildContext context,
    WidgetRef ref,
    int pedidoId,
  ) async {
    final list = await ref.read(gastronomiaServiceProvider).repartidores();
    if (!context.mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay repartidores. Agrega uno primero.')),
      );
      return;
    }

    final elegido = await AppDialog.show<Repartidor>(
      context,
      title: 'Asignar repartidor',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in list)
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: Text(r.nombre),
              subtitle: Text(r.telefono.isEmpty ? 'Sin teléfono' : r.telefono),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context, r),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
    if (elegido == null) return;

    await ref.read(gastronomiaServiceProvider).asignarRepartidor(pedidoId, elegido.id);
    ref.invalidate(pedidosGastroPendientesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asignado a ${elegido.nombre} · en camino')),
      );
    }
  }

  /// H2: cobra un pedido delivery contra entrega: crea la venta (descuenta stock),
  /// registra el ingreso de caja y vincula ventaId al pedido (evita cobro duplicado).
  static Future<void> _cobrarPedido(
    BuildContext context,
    WidgetRef ref,
    PedidoGastronomiaData pe,
  ) async {
    final formas = ['efectivo', 'tarjeta', 'transferencia'];
    String forma = pe.formaPago.isEmpty ? 'efectivo' : pe.formaPago;
    final montoCtrl = TextEditingController(text: pe.total.toStringAsFixed(2));

    final ok = await AppDialog.show<bool>(
      context,
      title: 'Cobrar pedido #${pe.id}',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cliente: ${pe.nombreCliente}\nTotal: RD\$ ${pe.total.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<String>(
            initialValue: forma,
            decoration: const InputDecoration(labelText: 'Forma de pago'),
            items: [
              for (final f in formas)
                DropdownMenuItem(
                    value: f, child: Text(f[0].toUpperCase() + f.substring(1))),
            ],
            onChanged: (v) => forma = v ?? forma,
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: montoCtrl,
            decoration: const InputDecoration(
                labelText: 'Monto cobrado', prefixText: 'RD\$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Cobrar y registrar'),
        ),
      ],
    );
    if (ok != true) return;

    final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? pe.total;
    if (monto <= 0) return;

    final svc = ref.read(gastronomiaServiceProvider);
    final lineas = await svc.lineasDePedido(pe.id);
    final detalles = lineas
        .map((l) => DetalleVenta(
              productoId: l.productoId,
              cantidad: l.cantidad,
              precioUnitario: l.precioUnitario,
              subtotal: l.subtotal,
              nombreProducto: l.nombreSnapshot,
              tasaImpuesto: 0.18,
            ))
        .toList();

    if (!context.mounted) return;
    try {
      final estadoVenta = RegistrarVentaState(
        usuarioId: (ref.read(sesionUsuarioIdProvider) ?? 1),
        clienteId: pe.clienteId ?? 0,
        clienteNombre: pe.nombreCliente,
        tipoPago: forma,
        esCredito: false,
        abonoInicial: monto,
        detalles: detalles,
        subtotal: pe.subtotal,
        itbis: pe.itbis,
        costoEnvio: pe.costoEnvio,
        total: pe.total,
        montoDescuento: pe.descuento,
      );
      final venta = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoVenta);
      final ventaId = venta.id;
      if (ventaId == null || ventaId <= 0) {
        throw Exception('La venta se creó pero no devolvió un ID válido');
      }
      await svc.vincularPagoPedido(
        pedidoId: pe.id,
        ventaId: ventaId,
        monto: monto,
        formaPago: forma,
      );
      await svc.marcarVentaFacturada(ventaId);
      ref.invalidate(pedidosGastroPendientesProvider);
      ref.invalidate(resumenRepartidoresProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cobrado #$ventaId · RD\$ ${monto.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cobrar: $e')));
      }
    }
  }

  /// Formulario centrado (AppDialog) para tomar un pedido de delivery.
  static Future<void> _nuevoPedidoDelivery(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nombreCtrl = TextEditingController(text: 'Consumidor Final');
    final telCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    final propinaCtrl = TextEditingController(text: '0');

    final sectores = await ref.read(gastronomiaServiceProvider).sectores();
    if (!context.mounted) return;

    if (sectores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero agrega al menos un sector de delivery.'),
        ),
      );
      return;
    }

    SectorDelivery? sectorSel = sectores.first;
    String formaPago = 'efectivo';

    final ok = await AppDialog.show<bool>(
      context,
      title: 'Nuevo pedido delivery',
      content: StatefulBuilder(
        builder: (ctx, setLocal) {
          final sec0 = sectorSel;
          final tarifa = sec0?.tarifaEnvio ?? 0;
          final umbral0 = sec0?.montoMinimoEnvioGratis ?? 0;
          final sub0 = ref.read(carritoGastroProvider).fold<double>(0, (s, l) => s + l.subtotal);
          final gratis0 = umbral0 > 0 && (sub0 * 1.18) >= umbral0;
          final envioTexto = gratis0
              ? 'Envío gratis · compra ≥ RD\$ ${umbral0.toStringAsFixed(0)}'
              : 'Costo de envío estimado: RD\$ ${tarifa.toStringAsFixed(2)}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: telCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.m),
              DropdownButtonFormField<SectorDelivery>(
                key: ValueKey(sectorSel?.id),
                initialValue: sectorSel,
                decoration: const InputDecoration(
                  labelText: 'Sector',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in sectores)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.nombre} · RD\$ ${s.tarifaEnvio.toStringAsFixed(0)}',
                      ),
                    ),
                ],
                onChanged: (v) => setLocal(() => sectorSel = v),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección / referencias',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Calle, color de casa, cerca de…',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas del pedido',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.m),
              DropdownButtonFormField<String>(
                key: ValueKey(formaPago),
                initialValue: formaPago,
                decoration: const InputDecoration(
                  labelText: 'Forma de pago',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                ],
                onChanged: (v) => setLocal(() => formaPago = v ?? 'efectivo'),
              ),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: propinaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Propina (RD\$)',
                  prefixIcon: Icon(Icons.room_service_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Material(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          envioTexto,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Los productos se toman del carrito de Venta Rápida. '
                'Si está vacío, se crea el pedido solo con datos de entrega.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Crear pedido'),
        ),
      ],
    );

    if (ok != true || sectorSel == null) return;

    final carrito = ref.read(carritoGastroProvider);
    final subtotal = carrito.fold<double>(0, (s, l) => s + l.subtotal);
    // ITBIS solo sobre productos (no sobre envío), mismo criterio que venta rápida
    final base = subtotal;
    final itbis = double.parse((base * 0.18).toStringAsFixed(2));
    // H1: envío gratis cuando la mercancía (con ITBIS) alcanza el umbral del sector
    final umbralGratis = sectorSel!.montoMinimoEnvioGratis;
    final aplicaGratis = umbralGratis > 0 && (base + itbis) >= umbralGratis;
    final costoEnvio = aplicaGratis ? 0.0 : sectorSel!.tarifaEnvio;
    final propinaDel = double.tryParse(propinaCtrl.text.replaceAll(',', '.')) ?? 0;
    final total = double.parse((base + itbis + costoEnvio + propinaDel).toStringAsFixed(2));

    final pedido = PedidoGastronomia(
      tipo: 'delivery',
      estado: 'pendiente',
      nombreCliente: nombreCtrl.text.trim().isEmpty
          ? 'Consumidor Final'
          : nombreCtrl.text.trim(),
      telefono: telCtrl.text.trim(),
      sectorId: sectorSel!.id,
      direccionReferencia: refCtrl.text.trim(),
      costoEnvio: costoEnvio,
      subtotal: subtotal,
      itbis: itbis,
      descuento: 0,
      propina: propinaDel,
      total: total,
      formaPago: formaPago,
      notas: notasCtrl.text.trim(),
    );

    try {
      final id = await ref
          .read(gastronomiaServiceProvider)
          .crearPedido(pedido, carrito);
      if (carrito.isNotEmpty) {
        ref.read(carritoGastroProvider.notifier).limpiar();
      }
      ref.invalidate(pedidosGastroPendientesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido #$id creado · RD\$ ${total.toStringAsFixed(2)}'
              '${carrito.isEmpty ? ' (sin productos)' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear pedido: $e')),
        );
      }
    }
  }

  /// Genera texto del menú gastronómico y lo comparte.
  static Future<void> _compartirMenu(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final svc = ref.read(gastronomiaServiceProvider);

    final productos = await (db.select(db.productosTable)
          ..where((t) => t.activo.equals(1)))
        .get();
    final cats = await (db.select(db.categorias)
          ..where((t) => t.activo.equals(true)))
        .get();
    final catNombre = {for (final c in cats) c.id: c.nombre};
    final meta = await svc.metaDeProductos(productos.map((p) => p.id));

    final porCat = <int?, List<ProductoData>>{};
    for (final p in productos) {
      final m = meta[p.id];
      if (m == null || !m.esGastronomico || !m.disponibleMenu) continue;
      porCat.putIfAbsent(p.categoriaId, () => []).add(p);
    }
    if (porCat.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay productos en el menú. Actívalos en Catálogo.'),
          ),
        );
      }
      return;
    }

    final b = StringBuffer();
    b.writeln('*MENÚ*');
    b.writeln('────────────────');
    final keys = porCat.keys.toList()
      ..sort((a, b) =>
          (catNombre[a] ?? 'Otros').compareTo(catNombre[b] ?? 'Otros'));
    for (final cid in keys) {
      b.writeln();
      b.writeln('*${catNombre[cid] ?? 'Otros'}*');
      final lista = porCat[cid]!;
      lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      for (final p in lista) {
        final nombre = p.nombre;
        final precio = (p.precioVenta as num?)?.toDouble() ?? 0.0;
        b.writeln('• $nombre — RD\$ ${precio.toStringAsFixed(2)}');
      }
    }
    b.writeln();
    b.writeln('────────────────');
    b.writeln('Escribe para ordenar. ¡Te atendemos!');

    await GastroWhatsapp.compartirTexto(b.toString(), subject: 'Menú');
  }
}
