import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class SeleccionarClienteDialog extends ConsumerStatefulWidget {
  const SeleccionarClienteDialog._interno();

  static Future<ClienteEntity?> mostrar(BuildContext contexto) async {
    final seleccionado = await showDialog<ClienteCompleto>(
      context: contexto,
      builder: (_) => const SeleccionarClienteDialog._interno(),
    );
    if (seleccionado == null) return null;
    return ClienteEntity(
      id: seleccionado.id,
      codigo: seleccionado.rncCedula.isNotEmpty
          ? seleccionado.rncCedula
          : 'CLI-${seleccionado.id}',
      nombre: seleccionado.nombre,
      rncCedula: seleccionado.rncCedula,
      telefono: seleccionado.telefono,
      correo: seleccionado.correo,
      direccion: seleccionado.direccion,
      activo: seleccionado.activo,
    );
  }

  @override
  ConsumerState<SeleccionarClienteDialog> createState() =>
      _SeleccionarClienteDialogState();
}

class _SeleccionarClienteDialogState
    extends ConsumerState<SeleccionarClienteDialog> {
  final _busqueda = TextEditingController();
  String _termino = '';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _abrirNuevoCliente() async {
    final creado = await showDialog<ClienteCompleto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NuevoClienteFormDialog(),
    );
    if (creado != null && mounted) {
      Navigator.of(context).pop(creado);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Seleccionar Cliente',
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Buscar cliente',
              hint: 'Nombre, RNC o Teléfono',
              controller: _busqueda,
              onChanged: (valor) => setState(() => _termino = valor),
            ),
            AppLayout.vM,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Nuevo cliente'),
                onPressed: _abrirNuevoCliente,
              ),
            ),
            AppLayout.vM,
            Flexible(
              child: FutureBuilder<List<ClienteCompleto>>(
                future: ref
                    .read(clienteCompletoControllerProvider.notifier)
                    .buscarPorNombre(_termino),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final lista = snap.data ?? [];
                  if (lista.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _termino.trim().isEmpty
                            ? 'Escribe para buscar o crea un cliente nuevo.'
                            : 'Sin resultados.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 280,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = lista[i];
                        return ListTile(
                          title: Text(c.nombre),
                          subtitle: Text(
                            [
                              if (c.rncCedula.isNotEmpty) c.rncCedula,
                              if (c.telefono.isNotEmpty) c.telefono,
                            ].join(' · '),
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Formulario de alta: el State es dueño de los controllers (sin dispose prematuro).
class _NuevoClienteFormDialog extends ConsumerStatefulWidget {
  const _NuevoClienteFormDialog();

  @override
  ConsumerState<_NuevoClienteFormDialog> createState() =>
      _NuevoClienteFormDialogState();
}

class _NuevoClienteFormDialogState
    extends ConsumerState<_NuevoClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _rnc;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _direccion;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController();
    _rnc = TextEditingController();
    _telefono = TextEditingController();
    _correo = TextEditingController();
    _direccion = TextEditingController();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _rnc.dispose();
    _telefono.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _guardando = true);
    try {
      final cli = ClienteCompleto(
        nombre: _nombre.text.trim(),
        rncCedula: _rnc.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
        direccion: _direccion.text.trim(),
        activo: true,
      );
      await ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);
      final lista = await ref
          .read(clienteCompletoControllerProvider.notifier)
          .buscarPorNombre(cli.nombre);
      ClienteCompleto? encontrado;
      for (final c in lista) {
        if (c.rncCedula == cli.rncCedula || c.nombre == cli.nombre) {
          encontrado = c;
          break;
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(encontrado ?? (lista.isNotEmpty ? lista.first : cli));
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Error al guardar cliente: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo cliente'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre / Razón Social *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rnc,
                  decoration: const InputDecoration(
                    labelText: 'RNC o Cédula (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono / Celular *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correo,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccion,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
