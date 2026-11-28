import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/contabilidad/data/config/plantilla_json_loader.dart';
import 'package:fiscogest_rd/core/contabilidad/data/seed/plan_cuentas_rd_seed.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/balance_comprobacion_page.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/detalle_asiento_page.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/libro_diario_page.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/libro_mayor_page.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/nuevo_asiento_page.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/pages/plan_cuentas_page.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

class ContabilidadHomePage extends StatefulWidget {
  const ContabilidadHomePage({super.key});

  static const routeName = 'contabilidad-home';
  static const routePath = '/contabilidad';

  @override
  State<ContabilidadHomePage> createState() => _ContabilidadHomePageState();
}

class _ContabilidadHomePageState extends State<ContabilidadHomePage> {
  late Future<List<AsientoContable>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<AsientoContable>> _cargar() {
    return RepositoryInjection.instance.asientoRepository.listar(limite: 40);
  }

  void _refrescar() {
    final f = _cargar();
    setState(() {
      _futuro = f;
    });
  }

  Future<void> _cambiarPais(String codigo) async {
    ContabilidadPaisConfig.setPais(codigo);
    final plantilla = await PlantillaJsonLoader.cargar(codigo);
    ContabilidadPaisConfig.setPlantilla(plantilla);

    try {
      await PlanCuentasRdSeed(
        RepositoryInjection.instance.planCuentasRepository,
      ).asegurarPlanMinimo(paisCodigo: codigo);
    } catch (_) {}

    if (!mounted) return;
    setState(() {});
    _refrescar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AcctStrings.countryLabel}: ${plantilla.nombre} · '
          '${plantilla.etiquetaImpuesto}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantilla = ContabilidadPaisConfig.plantilla;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AcctStrings.title),
        actions: [
          IconButton(
            tooltip: AcctStrings.refresh,
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>(NuevoAsientoPage.routePath);
          if (ok == true) _refrescar();
        },
        icon: const Icon(Icons.add),
        label: const Text(AcctStrings.entryNew),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AcctStrings.homeSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.public),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AcctStrings.countryLabel,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: ContabilidadPaisConfig.paisCodigo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: PlantillasContrapartida.todas
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.paisCodigo,
                                  child: Text('${p.nombre} (${p.paisCodigo})'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _cambiarPais(v);
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plantilla.etiquetaImpuesto,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(PlanCuentasPage.routePath),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text(AcctStrings.accountsTitle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok =
                        await context.push<bool>(NuevoAsientoPage.routePath);
                    if (ok == true) _refrescar();
                  },
                  icon: const Icon(Icons.post_add),
                  label: const Text(AcctStrings.entryNew),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AcctStrings.booksTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.push(LibroDiarioPage.routePath),
                child: const Text(AcctStrings.journalTitle),
              ),
              OutlinedButton(
                onPressed: () => context.push(LibroMayorPage.routePath),
                child: const Text(AcctStrings.ledgerTitle),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.push(BalanceComprobacionPage.routePath),
                child: const Text(AcctStrings.trialBalanceTitle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AcctStrings.entriesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<AsientoContable>>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text('${AcctStrings.errorGeneric}: ${snap.error}');
              }
              final items = snap.data ?? const <AsientoContable>[];
              if (items.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text(AcctStrings.emptyEntries),
                );
              }
              return Column(
                children: items
                    .map(
                      (a) => Card(
                        child: ListTile(
                          title: Text(
                            a.numeroAsiento.isEmpty
                                ? '#${a.id}'
                                : a.numeroAsiento,
                          ),
                          subtitle: Text(a.concepto),
                          trailing: Text(a.estado.name),
                          onTap: () async {
                            final ok = await context.push<bool>(
                              '${DetalleAsientoPage.routePath}?id=${a.id}',
                            );
                            if (ok == true) _refrescar();
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
