import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Alta manual de asiento en partida doble (montos en unidades → centavos).
class NuevoAsientoPage extends StatefulWidget {
  const NuevoAsientoPage({super.key});

  static const routeName = 'contabilidad-asiento-nuevo';
  static const routePath = '/contabilidad/asientos/nuevo';

  @override
  State<NuevoAsientoPage> createState() => _NuevoAsientoPageState();
}

class _LineaDraft {
  int? cuentaId;
  final debeCtrl = TextEditingController();
  final haberCtrl = TextEditingController();
}

class _NuevoAsientoPageState extends State<NuevoAsientoPage> {
  final _conceptoCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  final List<_LineaDraft> _lineas = [_LineaDraft(), _LineaDraft()];
  List<PlanCuenta> _hojas = [];
  bool _cargandoCuentas = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHojas();
  }

  Future<void> _cargarHojas() async {
    final arbol = await RepositoryInjection.instance.planCuentasRepository
        .obtenerArbolCompleto();
    setState(() {
      _hojas = arbol
          .where((c) => c.activo && c.permiteMovimiento)
          .toList()
        ..sort((a, b) => a.codigo.compareTo(b.codigo));
      _cargandoCuentas = false;
    });
  }

  int _parseCents(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null) return -1;
    return (v * 100).round();
  }

  Future<void> _guardar() async {
    setState(() {
      _error = null;
      _guardando = true;
    });
    try {
      final concepto = _conceptoCtrl.text.trim();
      final lineas = <LineaAsiento>[];
      for (final d in _lineas) {
        if (d.cuentaId == null) {
          throw StateError('acct_error_missing_line');
        }
        final debe = _parseCents(d.debeCtrl.text);
        final haber = _parseCents(d.haberCtrl.text);
        if (debe < 0 || haber < 0) {
          throw StateError('acct_error_invalid_line');
        }
        if (debe == 0 && haber == 0) continue;
        lineas.add(LineaAsiento(
          cuentaId: d.cuentaId!,
          debeCents: debe,
          haberCents: haber,
        ));
      }
      final ahora = DateTime.now();
      final asiento = AsientoContable(
        numeroAsiento: '',
        fecha: DateTime(_fecha.year, _fecha.month, _fecha.day),
        concepto: concepto,
        estado: EstadoAsiento.borrador,
        creadoEn: ahora,
      );
      final reg = await RepositoryInjection.instance.motorPartidaDoble.registrar(
        asiento: asiento,
        lineas: lineas,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AcctStrings.entrySaved}: ${reg.numeroAsiento}')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      final msg = e.toString();
      String ui = AcctStrings.errorGeneric;
      for (final part in msg.split(RegExp(r'[:|]'))) {
        final p = part.trim();
        if (p.startsWith('acct_error')) {
          ui = AcctStrings.fromErrorCode(p);
          break;
        }
      }
      setState(() {
        _error = ui;
        _guardando = false;
      });
    } finally {
      if (mounted && _guardando) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    for (final l in _lineas) {
      l.debeCtrl.dispose();
      l.haberCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AcctStrings.entryNew)),
      body: _cargandoCuentas
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _conceptoCtrl,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.entryConcept,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AcctStrings.entryDate),
                  subtitle: Text(
                    '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                ),
                const Divider(),
                Text(AcctStrings.entryLines,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...List.generate(_lineas.length, (i) {
                  final d = _lineas[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            // ignore: deprecated_member_use
                            value: d.cuentaId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: AcctStrings.accountsTitle,
                              border: OutlineInputBorder(),
                            ),
                            items: _hojas
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.codigo} ${c.nombre}',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => d.cuentaId = v),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: d.debeCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: AcctStrings.entryDebit,
                                    hintText: AcctStrings.entryAmountHint,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) {
                                    if (d.debeCtrl.text.trim().isNotEmpty) {
                                      d.haberCtrl.clear();
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: d.haberCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: AcctStrings.entryCredit,
                                    hintText: AcctStrings.entryAmountHint,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) {
                                    if (d.haberCtrl.text.trim().isNotEmpty) {
                                      d.debeCtrl.clear();
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                              if (_lineas.length > 2)
                                IconButton(
                                  tooltip: AcctStrings.entryRemoveLine,
                                  onPressed: () {
                                    setState(() {
                                      d.debeCtrl.dispose();
                                      d.haberCtrl.dispose();
                                      _lineas.removeAt(i);
                                    });
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() => _lineas.add(_LineaDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text(AcctStrings.entryAddLine),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AcctStrings.entryPost),
                ),
              ],
            ),
    );
  }
}
