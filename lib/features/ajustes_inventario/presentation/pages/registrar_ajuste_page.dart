import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';

/// Formulario de ajuste — mismo diseño que Lista de Ajustes / Inventario Físico.
class RegistrarAjustePage extends ConsumerStatefulWidget {
  const RegistrarAjustePage({super.key});
  static const String routeName = 'registrar-ajuste';

  @override
  ConsumerState<RegistrarAjustePage> createState() =>
      _RegistrarAjustePageState();
}

class _RegistrarAjustePageState extends ConsumerState<RegistrarAjustePage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  String _tipoSeleccionado = 'entrada';
  Producto? _productoSeleccionado;
  bool _guardando = false;

  static const _bg = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);
  static const _teal = Color(0xFF0D9488);

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  void _seleccionarProducto(Producto prod) {
    setState(() {
      _productoSeleccionado = prod;
      _codigoCtrl.text = prod.codigo;
    });
    Navigator.of(context, rootNavigator: false).pop();
  }

  void _abrirBuscador(List<Producto> todos) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DialogoBusqueda(
        productos: todos,
        onSeleccionar: _seleccionarProducto,
      ),
    );
  }

  InputDecoration _dec(String hint, {IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF94A3B8),
      ),
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      );

  Future<void> _guardar() async {
    if (_guardando) return;
    final producto = _productoSeleccionado;
    if (producto == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione un producto usando la lupa'),
        ),
      );
      return;
    }
    final cant = double.tryParse(_cantidadCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (cant <= 0) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('La cantidad debe ser mayor a cero')),
      );
      return;
    }
    final stockActual = producto.stock ?? 0.0;
    if (_tipoSeleccionado == 'salida' && cant > stockActual) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Stock insuficiente. Disponible: $stockActual'),
        ),
      );
      return;
    }
    final usuarioId = ref.read(usuarioAutenticadoProvider);
    if (usuarioId == null) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Indique el motivo del ajuste')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final ajuste = AjusteInventario(
        productoId: producto.id!,
        codigoBusqueda: _codigoCtrl.text.trim(),
        cantidad: cant,
        tipoAjuste: _tipoSeleccionado,
        motivo: _motivoCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim(),
        usuarioId: usuarioId,
        fechaCreacion: DateTime.now(),
      );
      final exito =
          await ref.read(ajusteInventarioProvider).registrar(ajuste);
      if (!mounted) return;
      setState(() {
        final stockBase = _productoSeleccionado?.stock ?? 0;
        final stockNuevo = _tipoSeleccionado == 'entrada'
            ? stockBase + cant
            : stockBase - cant;
        _productoSeleccionado =
            _productoSeleccionado?.copyWith(stock: stockNuevo);
      });
      ref.invalidate(productoControllerProvider);
      ref.invalidate(kardexHistorialCompletoProvider);
      ref.invalidate(kardexPorProductoProvider);
      ref.invalidate(ajusteInventarioListaProvider);
      if (!exito || !context.mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('✅ Ajuste guardado — stock actualizado'),
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final productosAsync = ref.watch(productoControllerProvider);

    return AppScaffold(
      title: 'Registrar Ajuste',
      subtitle: isMobile ? null : 'Conteos, mermas y correcciones de stock',
      showAppBar: true,
      showBackButton: true,
      backgroundColor: _bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Volver',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed('lista-ajustes');
          }
        },
      ),
      body: productosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        data: (todos) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 12 : 20,
            isMobile ? 16 : 24,
            32,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isMobile) ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.goNamed('lista-ajustes');
                            }
                          },
                          tooltip: 'Volver',
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _textPrimary,
                            side: const BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0D9488),
                                Color(0xFF14B8A6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Ajuste',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _textPrimary,
                                ),
                              ),
                              Text(
                                'Conteo físico, mermas y correcciones de stock',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Card formulario
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Producto'),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _abrirBuscador(todos),
                              icon: Icon(
                                Icons.search_rounded,
                                color: _productoSeleccionado == null
                                    ? const Color(0xFF94A3B8)
                                    : _teal,
                              ),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _productoSeleccionado == null
                                      ? 'Buscar y seleccionar producto'
                                      : '${_productoSeleccionado!.codigo} · ${_productoSeleccionado!.nombre}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _productoSeleccionado == null
                                        ? const Color(0xFF94A3B8)
                                        : _textPrimary,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF8FAFC),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                side: BorderSide(
                                  color: _productoSeleccionado == null
                                      ? _border
                                      : _teal.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_productoSeleccionado != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Text(
                                  'Stock actual: ${_productoSeleccionado!.stock ?? 0.0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),

                          _label('Tipo de ajuste'),
                          Row(
                            children: [
                              Expanded(
                                child: _tipoChip(
                                  'entrada',
                                  'Entrada (+)',
                                  Icons.add_circle_outline,
                                  const Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tipoChip(
                                  'salida',
                                  'Salida (−)',
                                  Icons.remove_circle_outline,
                                  const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          _label('Cantidad'),
                          TextField(
                            controller: _cantidadCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            decoration: _dec('Ej: 5.5'),
                          ),
                          const SizedBox(height: 18),

                          _label('Motivo'),
                          TextField(
                            controller: _motivoCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            decoration: _dec('Ej: Conteo físico / Pérdida'),
                          ),
                          const SizedBox(height: 18),

                          _label('Observaciones (opcional)'),
                          TextField(
                            controller: _observacionesCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: _dec('Comentarios adicionales'),
                          ),
                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _guardando ? null : _guardar,
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 20),
                              label: Text(
                                _guardando ? 'Guardando…' : 'Guardar ajuste',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _teal.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipoChip(
    String value,
    String label,
    IconData icon,
    Color accent,
  ) {
    final selected = _tipoSeleccionado == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _tipoSeleccionado = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : _border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? accent : _textMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? accent : _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoBusqueda extends StatefulWidget {
  const _DialogoBusqueda({
    required this.productos,
    required this.onSeleccionar,
  });
  final List<Producto> productos;
  final void Function(Producto) onSeleccionar;

  @override
  State<_DialogoBusqueda> createState() => _DialogoBusquedaState();
}

class _DialogoBusquedaState extends State<_DialogoBusqueda> {
  final _buscarCtrl = TextEditingController();
  List<Producto> _resultados = [];

  static const _border = Color(0xFFE2E8F0);
  static const _teal = Color(0xFF0D9488);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);

  @override
  void initState() {
    super.initState();
    _resultados = widget.productos;
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _filtrar(String texto) {
    setState(() {
      final t = texto.toLowerCase();
      _resultados = widget.productos.where((p) {
        return p.codigo.toLowerCase().contains(t) ||
            p.nombre.toLowerCase().contains(t);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: _teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Buscar producto',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buscarCtrl,
                autofocus: true,
                onChanged: _filtrar,
                style: const TextStyle(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Código o nombre…',
                  hintStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _resultados.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin resultados',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _resultados.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final p = _resultados[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            title: Text(
                              '${p.codigo} · ${p.nombre}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Stock: ${p.stock ?? 0.0}  ·  Venta: ${p.precioVenta}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            onTap: () => widget.onSeleccionar(p),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
