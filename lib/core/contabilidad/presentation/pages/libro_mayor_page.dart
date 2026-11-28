import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/calculador_saldos.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Libro mayor por cuenta hoja (movimientos + saldo naturaleza).
class LibroMayorPage extends StatefulWidget {
  const LibroMayorPage({super.key});

  static const routeName = 'contabilidad-mayor';
  static const routePath = '/contabilidad/mayor';

  @override
  State<LibroMayorPage> createState() => _LibroMayorPageState();
}

class _LibroMayorPageState extends State<LibroMayorPage> {
  List<PlanCuenta> _hojas = [];
  int? _cuentaId;
  DateTime _desde = DateTime(DateTime.now().year, 1, 1);
  DateTime _hasta = DateTime.now();
  bool _loading = false;
  String? _error;
  List<(DateTime, String, LineaAsiento)> _movs = [];
  int _saldo = 0;

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  String _fmt(int c) => (c / 100).toStringAsFixed(2);
  String _f(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargarCuentas() async {
    final arbol = await RepositoryInjection.instance.planCuentasRepository
        .obtenerArbolCompleto();
    setState(() {
      _hojas = arbol.where((c) => c.permiteMovimiento).toList()
        ..sort((a, b) => a.codigo.compareTo(b.codigo));
      if (_hojas.isNotEmpty) _cuentaId = _hojas.first.id;
    });
  }

  Future<void> _cargar() async {
    final cid = _cuentaId;
    if (cid == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = RepositoryInjection.instance.asientoRepository;
      final motor = RepositoryInjection.instance.motorPartidaDoble;
      final plan = _hojas.firstWhere((c) => c.id == cid);
      final list = await repo.listar(limite: 300);
      final d0 = DateTime(_desde.year, _desde.month, _desde.day);
      final d1 = DateTime(_hasta.year, _hasta.month, _hasta.day, 23, 59, 59);
      final movs = <(DateTime, String, LineaAsiento)>[];
      final soloCuenta = <LineaAsiento>[];
      for (final a in list) {
        if (a.fecha.isBefore(d0) || a.fecha.isAfter(d1)) continue;
        final lineas = await motor.obtenerLineas(a.id);
        for (final l in lineas) {
          if (l.cuentaId != cid) continue;
          movs.add((a.fecha, a.numeroAsiento.isEmpty ? '#${a.id}' : a.numeroAsiento, l));
          soloCuenta.add(l);
        }
      }
      movs.sort((x, y) => x.$1.compareTo(y.$1));
      final saldo = CalculadorSaldos().calcularSaldo(plan, soloCuenta);
      setState(() {
        _movs = movs;
        _saldo = saldo;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AcctStrings.ledgerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _cuentaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.selectAccount,
                    border: OutlineInputBorder(),
                  ),
                  items: _hojas
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.codigo} ${c.nombre}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _cuentaId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _desde,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _desde = d);
                        },
                        child: Text('${AcctStrings.filterFrom}: ${_f(_desde)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _hasta,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d != null) setState(() => _hasta = d);
                        },
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
              ],
            ),
          ),
          if (_saldo != 0 || _movs.isNotEmpty)
            ListTile(
              title: const Text(AcctStrings.colBalance),
              trailing: Text(
                _fmt(_saldo),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _movs.isEmpty
                        ? const Center(child: Text(AcctStrings.booksEmpty))
                        : ListView.separated(
                            itemCount: _movs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final (fecha, num, l) = _movs[i];
                              return ListTile(
                                title: Text('$num · ${_f(fecha)}'),
                                subtitle: Text(l.concepto ?? ''),
                                trailing: Text(
                                  l.debeCents > 0
                                      ? '${AcctStrings.colDebit} ${_fmt(l.debeCents)}'
                                      : '${AcctStrings.colCredit} ${_fmt(l.haberCents)}',
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
