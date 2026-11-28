import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/plan_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/enums/tipo_cuenta.dart';
import 'package:fiscogest_rd/core/contabilidad/presentation/acct_strings.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Alta de cuenta hoja bajo un grupo del plan (multi-país: código libre).
class NuevaCuentaPage extends StatefulWidget {
  const NuevaCuentaPage({super.key});

  static const routeName = 'contabilidad-cuenta-nueva';
  static const routePath = '/contabilidad/plan/nueva';

  @override
  State<NuevaCuentaPage> createState() => _NuevaCuentaPageState();
}

class _NuevaCuentaPageState extends State<NuevaCuentaPage> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  List<PlanCuenta> _grupos = [];
  int? _padreId;
  TipoCuenta _tipo = TipoCuenta.activo;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final arbol = await RepositoryInjection.instance.planCuentasRepository
        .obtenerArbolCompleto();
    setState(() {
      // Padre = grupo (no permite movimiento) o cualquier cuenta activa
      _grupos = arbol.where((c) => c.activo && !c.permiteMovimiento).toList();
      if (_grupos.isEmpty) {
        _grupos = arbol.where((c) => c.activo).toList();
      }
      _grupos.sort((a, b) => a.codigo.compareTo(b.codigo));
      if (_grupos.isNotEmpty) {
        _padreId = _grupos.first.id;
        _tipo = _grupos.first.tipo;
      }
      _loading = false;
    });
  }

  Future<void> _guardar() async {
    final codigo = _codigoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    if (_padreId == null) {
      setState(() => _error = AcctStrings.accountParentRequired);
      return;
    }
    if (codigo.isEmpty || nombre.isEmpty) {
      setState(() => _error = AcctStrings.errorMissingLine);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = RepositoryInjection.instance.planCuentasRepository;
      final existe = await repo.obtenerPorCodigo(codigo);
      if (existe != null) {
        setState(() {
          _error = AcctStrings.accountCodeExists;
          _saving = false;
        });
        return;
      }
      final padre = _grupos.firstWhere((c) => c.id == _padreId);
      final nivel = padre.nivel + 1;
      final ahora = DateTime.now();
      final cuenta = PlanCuenta(
        id: 0,
        codigo: codigo,
        nombre: nombre,
        tipo: _tipo,
        padreId: padre.id,
        nivel: nivel,
        permiteMovimiento: true,
        activo: true,
        creadoEn: ahora,
      );
      final id = await repo.insertar(cuenta);
      if (!mounted) return;
      if (id <= 0) {
        setState(() {
          _error = AcctStrings.errorGeneric;
          _saving = false;
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AcctStrings.accountCreated)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AcctStrings.accountNew)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _padreId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.accountParent,
                    border: OutlineInputBorder(),
                  ),
                  items: _grupos
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
                  onChanged: (v) {
                    if (v == null) return;
                    final p = _grupos.firstWhere((c) => c.id == v);
                    setState(() {
                      _padreId = v;
                      _tipo = p.tipo;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.accountCode,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.accountName,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TipoCuenta>(
                  // ignore: deprecated_member_use
                  value: _tipo,
                  decoration: const InputDecoration(
                    labelText: AcctStrings.accountType,
                    border: OutlineInputBorder(),
                  ),
                  items: TipoCuenta.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _tipo = v);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _guardar,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AcctStrings.accountSave),
                ),
              ],
            ),
    );
  }
}
