import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/services/calculador_saldos.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Balance de comprobación: saldos por cuenta hoja + totales debe/haber.
class BalanceComprobacionPage extends StatefulWidget {
  const BalanceComprobacionPage({super.key});

  static const routeName = 'contabilidad-balance';
  static const routePath = '/contabilidad/balance';

  @override
  State<BalanceComprobacionPage> createState() =>
      _BalanceComprobacionPageState();
}

class _BalanceComprobacionPageState extends State<BalanceComprobacionPage> {
  DateTime _desde = DateTime(DateTime.now().year, 1, 1);
  DateTime _hasta = DateTime.now();
  bool _loading = true;
  String? _error;
  List<(PlanCuenta, int debe, int haber, int saldo)> _rows = [];
  int _totDebe = 0;
  int _totHaber = 0;

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
      final planRepo = RepositoryInjection.instance.planCuentasRepository;
      final asientoRepo = RepositoryInjection.instance.asientoRepository;
      final motor = RepositoryInjection.instance.motorPartidaDoble;
      final cuentas = await planRepo.obtenerArbolCompleto();
      final hojas = cuentas.where((c) => c.permiteMovimiento && c.activo).toList();
      final list = await asientoRepo.listar(limite: 500);
      final d0 = DateTime(_desde.year, _desde.month, _desde.day);
      final d1 = DateTime(_hasta.year, _hasta.month, _hasta.day, 23, 59, 59);

      final porCuenta = <int, List<LineaAsiento>>{};
      for (final a in list) {
        if (a.fecha.isBefore(d0) || a.fecha.isAfter(d1)) continue;
        final lineas = await motor.obtenerLineas(a.id);
        for (final l in lineas) {
          porCuenta.putIfAbsent(l.cuentaId, () => []).add(l);
        }
      }

      final calc = CalculadorSaldos();
      final rows = <(PlanCuenta, int, int, int)>[];
      var td = 0;
      var th = 0;
      for (final c in hojas) {
        final mov = porCuenta[c.id] ?? <LineaAsiento>[];
        if (mov.isEmpty) continue;
        final debe = mov.fold(0, (s, l) => s + l.debeCents);
        final haber = mov.fold(0, (s, l) => s + l.haberCents);
        final saldo = calc.calcularSaldo(c, mov);
        rows.add((c, debe, haber, saldo));
        td += debe;
        th += haber;
      }
      rows.sort((a, b) => a.$1.codigo.compareTo(b.$1.codigo));
      setState(() {
        _rows = rows;
        _totDebe = td;
        _totHaber = th;
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
      appBar: AppBar(title: const Text(AcctStrings.trialBalanceTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
          ),
          ListTile(
            title: Text(
              '${AcctStrings.colDebit}: ${_fmt(_totDebe)}  ·  '
              '${AcctStrings.colCredit}: ${_fmt(_totHaber)}',
            ),
            subtitle: Text(
              _totDebe == _totHaber
                  ? '✓ Cuadrado'
                  : '⚠ Diferencia ${_fmt((_totDebe - _totHaber).abs())}',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _rows.isEmpty
                        ? const Center(child: Text(AcctStrings.booksEmpty))
                        : ListView.separated(
                            itemCount: _rows.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final (c, debe, haber, saldo) = _rows[i];
                              return ListTile(
                                title: Text('${c.codigo} ${c.nombre}'),
                                subtitle: Text(
                                  '${AcctStrings.colDebit} ${_fmt(debe)} · '
                                  '${AcctStrings.colCredit} ${_fmt(haber)}',
                                ),
                                trailing: Text(
                                  '${AcctStrings.colBalance} ${_fmt(saldo)}',
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
