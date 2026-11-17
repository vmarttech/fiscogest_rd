import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/providers/gastronomia_providers.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/utils/gastro_whatsapp.dart';
import 'dart:async';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_storage.dart';

class CatalogoGastronomiaPage extends ConsumerStatefulWidget {
  const CatalogoGastronomiaPage({super.key});
  static const routeName = 'catalogo-gastronomia';
  @override
  ConsumerState<CatalogoGastronomiaPage> createState() =>
      _CatalogoGastronomiaPageState();
}

class _CatalogoGastronomiaPageState extends ConsumerState<CatalogoGastronomiaPage> {
  bool _soloGastro = true;

  @override
  void initState() {
    super.initState();
    _purgarFotosViejasDeDocuments();
  }

  /// Las fotos NO deben persistir en documents (peso de app / inicio lento).
  /// Borra la carpeta legacy de versiones anteriores.
  Future<void> _purgarFotosViejasDeDocuments() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final viejo = Directory('${dir.path}/gastro_fotos');
      if (await viejo.exists()) await viejo.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> _tomarFoto(ProductoData p) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (xfile == null) return;
    // TEMPORAL (no persiste en documents). Se borra del equipo al subir a Storage.
    final tmp = await getTemporaryDirectory();
    final destino = '${tmp.path}/gastro_fotos_temp';
    await Directory(destino).create(recursive: true);
    final ruta = '$destino/producto_${p.id}.jpg';
    await File(xfile.path).copy(ruta);

    final svc = ref.read(gastronomiaServiceProvider);
    final meta = (await svc.metaDeProductos([p.id]))[p.id] ??
        ProductoGastroMeta(productoId: p.id, esGastronomico: true);
    await svc.guardarMeta(ProductoGastroMeta(
      productoId: p.id,
      fotoPath: ruta,
      fotoRemotaKey: meta.fotoRemotaKey,
      esGastronomico: true,
      destacado: meta.destacado,
      disponibleMenu: meta.disponibleMenu,
    ));
    if (mounted) setState(() {});
    unawaited(_subirFotoPendiente(p.id, ruta));
  }

  Future<void> _subirFotoPendiente(int productoId, String rutaTemp) async {
    try {
      final f = File(rutaTemp);
      if (!await f.exists()) return;
      final negocioId = await NegocioLocal.getId();
      if (negocioId == null || negocioId.isEmpty) return;
      if (!SupabaseConfig.isConfigured) return;
      final bytes = await f.readAsBytes();
      final clave = await SupabaseStorage()
          .subir(negocioId: negocioId, productoId: productoId, bytes: bytes);
      await ref
          .read(gastronomiaServiceProvider)
          .marcarFotoSubida(productoId, clave);
      try { await f.delete(); } catch (_) {}
      if (mounted) setState(() {});
    } catch (_) {
      // Sin red / RLS / sin negocio: queda en temp; el retry lo sube despues.
    }
  }

  Widget _fotoLeading(ProductoGastroMeta? m) {
    final remota = m?.fotoRemotaKey ?? '';
    if (remota.isNotEmpty) {
      return Image.network(
        SupabaseStorage.urlPublica(remota),
        width: 48, height: 48, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
      );
    }
    final local = m?.fotoPath ?? '';
    if (local.isNotEmpty && File(local).existsSync()) {
      return Image.file(File(local), width: 48, height: 48, fit: BoxFit.cover);
    }
    return const Icon(Icons.fastfood);
  }

  Future<void> _toggle(ProductoData p, {bool? gastro, bool? disp, bool? dest}) async {
    final svc = ref.read(gastronomiaServiceProvider);
    final meta = (await svc.metaDeProductos([p.id]))[p.id] ??
        ProductoGastroMeta(productoId: p.id);
    await svc.guardarMeta(ProductoGastroMeta(
      productoId: p.id,
      fotoPath: meta.fotoPath,
      esGastronomico: gastro ?? meta.esGastronomico,
      destacado: dest ?? meta.destacado,
      disponibleMenu: disp ?? meta.disponibleMenu,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _dialogoExtraGlobal({ExtraGastronomico? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final precioCtrl = TextEditingController(
      text: existente != null ? existente.precio.toStringAsFixed(2) : '0',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existente == null ? 'Nuevo extra' : 'Editar extra'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.sentences,
          ),
          TextField(
            controller: precioCtrl,
            decoration: const InputDecoration(labelText: 'Precio (RD\$)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'Compartir menú',
            icon: const Icon(Icons.share),
            onPressed: () => _compartirMenuCatalogo(context, ref),
          ),
          if (existente != null)
            TextButton(
              onPressed: () async {
                await ref.read(gastronomiaServiceProvider).desactivarExtra(existente.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    final nombre = nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final precio = double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0;
    await ref.read(gastronomiaServiceProvider).guardarExtra(
          ExtraGastronomico(
            id: existente?.id ?? 0,
            nombre: nombre,
            precio: precio,
          ),
        );
    ref.invalidate(extrasGlobalesProvider);
    if (mounted) setState(() {});
  }

  Future<void> _gestionarExtrasProducto(ProductoData p) async {
    final svc = ref.read(gastronomiaServiceProvider);
    final vinculados = await svc.extrasDeProducto(p.id);
    final globales = await svc.extrasGlobales();
    final vinculadosIds = vinculados.map((e) => e.id).toSet();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Extras · ${p.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (globales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No hay extras globales. Crea uno desde el menú ⋮'),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in globales)
                        SwitchListTile(
                          title: Text(e.nombre),
                          subtitle: Text('RD\$ ${e.precio.toStringAsFixed(2)}'),
                          value: vinculadosIds.contains(e.id),
                          onChanged: (v) async {
                            if (v) {
                              await svc.vincularExtra(p.id, e.id);
                              vinculadosIds.add(e.id);
                            } else {
                              await svc.desvincularExtra(p.id, e.id);
                              vinculadosIds.remove(e.id);
                            }
                            setModal(() {});
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Listo'),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  void _mostrarExtrasGlobales() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Consumer(builder: (ctx, ref, _) {
          final extras = ref.watch(extrasGlobalesProvider);
          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(children: [
                  const Expanded(
                    child: Text('Extras globales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _dialogoExtraGlobal();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo'),
                  ),
                ]),
              ),
              extras.when(
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sin extras. Crea el primero.'),
                      )
                    : Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in list)
                              ListTile(
                                title: Text(e.nombre),
                                subtitle:
                                    Text('RD\$ ${e.precio.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _dialogoExtraGlobal(existente: e);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
            ]),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo Gastronómico'),
        actions: [
          IconButton(
            tooltip: _soloGastro ? 'Mostrar todos' : 'Solo gastronómicos',
            icon: Icon(_soloGastro ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () => setState(() => _soloGastro = !_soloGastro),
          ),
          IconButton(
            tooltip: 'Extras globales',
            icon: const Icon(Icons.extension),
            onPressed: _mostrarExtrasGlobales,
          ),
        ],
      ),
      body: FutureBuilder<List<ProductoData>>(
        future: (db.select(db.productosTable)..where((t) => t.activo.equals(1))).get(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final productos = snap.data!;
          return FutureBuilder<Map<int, ProductoGastroMeta>>(
            future: ref
                .read(gastronomiaServiceProvider)
                .metaDeProductos(productos.map((p) => p.id)),
            builder: (ctx, snapMeta) {
              final meta = snapMeta.data ?? {};
              final visibles = _soloGastro
                  ? productos.where((p) => meta[p.id]?.esGastronomico == true).toList()
                  : productos;

              if (visibles.isEmpty) {
                return Center(
                  child: Text(_soloGastro
                      ? 'No hay productos marcados como gastronómicos.\nQuita el filtro para ver todos.'
                      : 'No hay productos activos.'),
                );
              }

              return ListView.builder(
                itemCount: visibles.length,
                itemBuilder: (ctx, i) {
                  final p = visibles[i];
                  final m = meta[p.id];
                  final activo = m?.esGastronomico ?? false;
                  return ListTile(
                    leading: _fotoLeading(m),
                    title: Text(p.nombre),
                    subtitle: Text(
                      'RD\$ ${(p.precioVenta ?? 0.0).toStringAsFixed(2)}'
                      '${activo ? ' · Gastro' : ''}'
                      '${m?.destacado == true ? ' · ★' : ''}',
                    ),
                    trailing: Wrap(spacing: 0, children: [
                      IconButton(
                        tooltip: 'Extras del producto',
                        icon: const Icon(Icons.extension_outlined),
                        onPressed: () => _gestionarExtrasProducto(p),
                      ),
                      IconButton(
                        tooltip: 'Foto',
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: () => _tomarFoto(p),
                      ),
                      Switch(
                        value: activo,
                        onChanged: (v) => _toggle(p, gastro: v),
                      ),
                    ]),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (sheetCtx) => SafeArea(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.visibility),
                            title: const Text('Disponible en menú'),
                            trailing: Switch(
                              value: m?.disponibleMenu ?? true,
                              onChanged: (v) {
                                _toggle(p, disp: v);
                                Navigator.pop(sheetCtx);
                              },
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.star),
                            title: const Text('Destacado'),
                            trailing: Switch(
                              value: m?.destacado ?? false,
                              onChanged: (v) {
                                _toggle(p, dest: v);
                                Navigator.pop(sheetCtx);
                              },
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.extension),
                            title: const Text('Gestionar extras'),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _gestionarExtrasProducto(p);
                            },
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _compartirMenuCatalogo(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final svc = ref.read(gastronomiaServiceProvider);
    final productos =
        await (db.select(db.productosTable)..where((t) => t.activo.equals(1))).get();
    final cats =
        await (db.select(db.categorias)..where((t) => t.activo.equals(true))).get();
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
          const SnackBar(content: Text('No hay productos en el menú.')),
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
    b.writeln('Escribe para ordenar. ¡Te atendemos!');
    await GastroWhatsapp.compartirTexto(b.toString(), subject: 'Menú');
  }
}
