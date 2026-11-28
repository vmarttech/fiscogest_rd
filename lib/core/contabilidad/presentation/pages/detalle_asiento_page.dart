import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

class DetalleAsientoPage extends StatefulWidget {
  const DetalleAsientoPage({super.key, required this.asientoId});

  static const routeName = 'contabilidad-asiento-detalle';
  static const routePath = '/contabilidad/asientos/detalle';

  final int asientoId;

  @override
  State<DetalleAsientoPage> createState() => _DetalleAsientoPageState();
}

class _DetalleAsientoPageState extends State<DetalleAsientoPage> {
  AsientoContable? _asiento;
  List<LineaAsiento> _lineas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final motor = RepositoryInjection.instance.motorPartidaDoble;
      final a = await motor.consultar(widget.asientoId);
      final l = a == null
          ? <LineaAsiento>[]
          : await motor.obtenerLineas(widget.asientoId);
      setState(() {
        _asiento = a;
        _lineas = l;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(int cents) => (cents / 100).toStringAsFixed(2);

  Future<void> _anular() async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AcctStrings.entryVoid),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: AcctStrings.entryVoidReason,
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text(AcctStrings.entryVoid),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    try {
      await RepositoryInjection.instance.motorPartidaDoble.anular(
        widget.asientoId,
        motivo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AcctStrings.entryVoided)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      var ui = AcctStrings.errorGeneric;
      for (final part in msg.split(RegExp(r'[:|]'))) {
        if (part.trim().startsWith('acct_error')) {
          ui = AcctStrings.fromErrorCode(part.trim());
          break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ui)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _asiento;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AcctStrings.entryDetail),
        actions: [
          if (a != null && a.estado == EstadoAsiento.contabilizado)
            IconButton(
              tooltip: AcctStrings.entryVoid,
              onPressed: _anular,
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : a == null
                  ? const Center(child: Text(AcctStrings.errorGeneric))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ListTile(
                          title: Text(a.numeroAsiento),
                          subtitle: Text(a.concepto),
                          trailing: Text(a.estado.name),
                        ),
                        ListTile(
                          title: const Text(AcctStrings.entryDate),
                          subtitle: Text(
                            '${a.fecha.year}-${a.fecha.month.toString().padLeft(2, '0')}-${a.fecha.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        const Divider(),
                        Text(AcctStrings.entryLines,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._lineas.map(
                          (l) => ListTile(
                            title: Text('Cuenta #${l.cuentaId}'),
                            subtitle: Text(l.concepto ?? ''),
                            trailing: Text(
                              l.debeCents > 0
                                  ? '${AcctStrings.entryDebit} ${_fmt(l.debeCents)}'
                                  : '${AcctStrings.entryCredit} ${_fmt(l.haberCents)}',
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: Text(AcctStrings.entryDebit),
                          trailing: Text(_fmt(
                            _lineas.fold(0, (s, l) => s + l.debeCents),
                          )),
                        ),
                        ListTile(
                          title: Text(AcctStrings.entryCredit),
                          trailing: Text(_fmt(
                            _lineas.fold(0, (s, l) => s + l.haberCents),
                          )),
                        ),
                      ],
                    ),
    );
  }
}
