import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/nueva_cuenta_page.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Lista del plan de cuentas (seed multi-país). Solo lectura + desactivar hoja en F1.
class PlanCuentasPage extends StatefulWidget {
  const PlanCuentasPage({super.key});

  static const routeName = 'contabilidad-plan';
  static const routePath = '/contabilidad/plan';

  @override
  State<PlanCuentasPage> createState() => _PlanCuentasPageState();
}

class _PlanCuentasPageState extends State<PlanCuentasPage> {
  late Future<List<PlanCuenta>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<PlanCuenta>> _cargar() {
    return RepositoryInjection.instance.planCuentasRepository
        .obtenerArbolCompleto();
  }

  void _refrescar() {
    final f = _cargar();
    setState(() {
      _futuro = f;
    });
  }


  Future<void> _activar(PlanCuenta c) async {
    final ok = await RepositoryInjection.instance.planCuentasRepository
        .activar(c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? AcctStrings.accountActive : AcctStrings.errorGeneric,
        ),
      ),
    );
    if (ok) _refrescar();
  }

  Future<void> _desactivar(PlanCuenta c) async {
    if (!c.permiteMovimiento) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AcctStrings.accountGroup)),
      );
      return;
    }
    final ok = await RepositoryInjection.instance.planCuentasRepository
        .desactivar(c.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? AcctStrings.accountInactive : AcctStrings.errorGeneric,
        ),
      ),
    );
    if (ok) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>(NuevaCuentaPage.routePath);
          if (ok == true) _refrescar();
        },
        icon: const Icon(Icons.add),
        label: const Text(AcctStrings.accountNew),
      ),
      appBar: AppBar(
        title: const Text(AcctStrings.accountsTitle),
        actions: [
          IconButton(
            tooltip: AcctStrings.refresh,
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<PlanCuenta>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${AcctStrings.errorGeneric}: ${snap.error}'));
          }
          final items = snap.data ?? const <PlanCuenta>[];
          if (items.isEmpty) {
            return const Center(child: Text(AcctStrings.accountsEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = items[i];
              final indent = (c.nivel - 1).clamp(0, 6) * 12.0;
              return ListTile(
                contentPadding: EdgeInsets.only(left: 16 + indent, right: 8),
                title: Text('${c.codigo}  ${c.nombre}'),
                subtitle: Text(
                  [
                    c.tipo.name,
                    c.permiteMovimiento
                        ? AcctStrings.accountLeaf
                        : AcctStrings.accountGroup,
                    c.activo
                        ? AcctStrings.accountActive
                        : AcctStrings.accountInactive,
                  ].join(' · '),
                ),
                trailing: c.permiteMovimiento
                    ? (c.activo
                        ? IconButton(
                            tooltip: AcctStrings.accountDeactivate,
                            icon: const Icon(Icons.block_outlined),
                            onPressed: () => _desactivar(c),
                          )
                        : IconButton(
                            tooltip: AcctStrings.accountActive,
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _activar(c),
                          ))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
