import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/contabilidad_pais_config.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/asiento_contable.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Home F0 del módulo contable. Solo Drift local (sin red).
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
    return RepositoryInjection.instance.asientoRepository.listar(limite: 30);
  }

  void _refrescar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pais = ContabilidadPaisConfig.paisCodigo;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AcctStrings.homeSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: Text('${AcctStrings.countryLabel}: $pais'),
              subtitle: Text(plantilla.nombre),
            ),
          ),
          const SizedBox(height: 8),
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
                return Text('Error: ${snap.error}');
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
                          title: Text(a.numeroAsiento.isEmpty
                              ? '#${a.id}'
                              : a.numeroAsiento),
                          subtitle: Text(a.concepto),
                          trailing: Text(a.estado.name),
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
