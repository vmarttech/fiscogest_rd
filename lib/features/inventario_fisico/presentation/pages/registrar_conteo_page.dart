import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class RegistrarConteoPage extends ConsumerStatefulWidget {

  const RegistrarConteoPage({super.key});
  // ✅ Propiedad estática agregada en ubicación CORRECTA, DENTRO y al inicio de la clase
  static const routeName = 'registrar-conteo-fisico';

  @override
  ConsumerState<RegistrarConteoPage> createState() => _RegistrarConteoPageState();
}

class _RegistrarConteoPageState extends ConsumerState<RegistrarConteoPage> {
  bool _cargando = false;
  final _nombreCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  Future<void> _guardarConteo() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final nuevoConteo = ConteoFisico(
        nombreConteo: _nombreCtrl.text.trim(),
        fechaConteo: DateTime.tryParse(_fechaCtrl.text) ?? DateTime.now(),
        observaciones: _obsCtrl.text.trim(),
        usuarioId: 1,
        fechaCreacion: DateTime.now(),
        estado: EstadoConteo.pendiente,
      );

      await ref.read(registrarConteoProvider).call(nuevoConteo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Conteo registrado exitosamente')),
      );
      context.goNamed('lista_inventario_fisico');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Conteo Físico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del conteo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fechaCtrl,
              decoration: const InputDecoration(labelText: 'Fecha del conteo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargando ? null : _guardarConteo,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar Conteo'),
            ),
          ],
        ),
      ),
    );
  }
}
