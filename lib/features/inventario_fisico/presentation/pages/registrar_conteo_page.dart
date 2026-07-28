import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class RegistrarConteoPage extends ConsumerStatefulWidget {
  const RegistrarConteoPage({super.key});
  static const routeName = 'registrar-conteo-fisico';

  @override
  ConsumerState<RegistrarConteoPage> createState() => _RegistrarConteoPageState();
}

class _RegistrarConteoPageState extends ConsumerState<RegistrarConteoPage> {
  final _nombreCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _cargando = true);
    try {
      final conteo = ConteoFisico(
        nombreConteo: _nombreCtrl.text.trim(),
        fechaConteo: DateTime.now(),
        observaciones: _obsCtrl.text.trim(),
        usuarioId: 1,
        fechaCreacion: DateTime.now(),
        estado: EstadoConteo.pendiente,
      );
      await ref.read(registrarConteoProvider).call(conteo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Conteo creado exitosamente')),
        );
        // ✅ USAMOS LA RUTA DECLARADA EN EL ROUTER
        context.goNamed('inventario_fisico');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Conteo Físico')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del Conteo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(labelText: 'Observaciones'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cargando ? null : _guardar,
              child: _cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Crear Conteo'),
            ),
          ],
        ),
      ),
    );
  }
}