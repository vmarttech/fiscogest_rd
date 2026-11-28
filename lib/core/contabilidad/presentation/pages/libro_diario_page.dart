import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Libro diario: asientos del rango (partida doble, centavos).
class LibroDiarioPage extends StatefulWidget {
  const LibroDiarioPage({super.key});

  static const routeName = 'contabilidad-diario';
  static const routePath = '/contabilidad/diario';

  @override
  State<LibroDiarioPage> createState() => _LibroDiarioPageState();
}

class _LibroDiarioPageState extends State<LibroDiarioPage> {
  DateTime _desde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _hasta = DateTime.now();
  bool _loading = true;
  String? _error;
  List<(AsientoContable, List<LineaAsiento>)> _filas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _fmt(int c) => (c / 100).toStringAsFixed(2);

  String _f(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = RepositoryInjection.instance.asientoRepository;
      final motor = RepositoryInjection.instance.motorPartidaDoble;
      final list = await repo.listar(limite: 200);
      final out = <(AsientoContable, List<LineaAsiento>)>[];
      final d0 = DateTime(_desde.year, _desde.month, _desde.day);
      final d1 = DateTime(_hasta.year, _hasta.month, _hasta.day, 23, 59, 59);
      for (final a in list) {
        if (a.fecha.isBefore(d0) || a.fecha.isAfter(d1)) continue;
        final lineas = await motor.obtenerLineas(a.id);
        out.add((a, lineas));
      }
      out.sort((x, y) => x.$1.fecha.compareTo(y.$1.fecha));
      setState(() {
        _filas = out;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDesde() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _desde,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _desde = d);
  }

  Future<void> _pickHasta() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _hasta,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _hasta = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AcctStrings.journalTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDesde,
                    child: Text('${AcctStrings.filterFrom}: ${_f(_desde)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickHasta,
                    child: Text('${AcctStrings.filterTo}: ${_f(_hasta)}'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _cargar,
                  child: const Text(AcctStrings.filterApply),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _filas.isEmpty
                        ? const Center(child: Text(AcctStrings.booksEmpty))
                        : ListView.builder(
                            itemCount: _filas.length,
                            itemBuilder: (context, i) {
                              final (a, lineas) = _filas[i];
                              final debe = lineas.fold(0, (s, l) => s + l.debeCents);
                              final haber = lineas.fold(0, (s, l) => s + l.haberCents);
                              return ExpansionTile(
                                title: Text(
                                  a.numeroAsiento.isEmpty
                                      ? '#${a.id}'
                                      : a.numeroAsiento,
                                ),
                                subtitle: Text('${_f(a.fecha)} · ${a.concepto}'),
                                trailing: Text(
                                  '${_fmt(debe)} / ${_fmt(haber)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                children: lineas
                                    .map(
                                      (l) => ListTile(
                                        dense: true,
                                        title: Text(
                                          '${AcctStrings.colAccount} #${l.cuentaId}',
                                        ),
                                        trailing: Text(
                                          l.debeCents > 0
                                              ? '${AcctStrings.colDebit} ${_fmt(l.debeCents)}'
                                              : '${AcctStrings.colCredit} ${_fmt(l.haberCents)}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
