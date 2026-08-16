import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/recepcion/recepcion_provider.dart';

class RegistrarRecepcionPage extends ConsumerWidget {

  const RegistrarRecepcionPage({
    super.key,
    required this.compraId,
    required this.proveedorId,
    this.proveedorNombre,
    this.usuarioResponsable = 'usuario_actual',
  });
  final String compraId;
  final String proveedorId;
  final String? proveedorNombre;
  final String usuarioResponsable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Recepción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos de Recepción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Recepción',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: proveedorNombre ?? proveedorId,
                decoration: const InputDecoration(
                  labelText: 'Proveedor',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final recepcion = Recepcion(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        compraId: compraId,
                        proveedorId: proveedorId,
                        proveedorNombre: proveedorNombre,
                        fechaRecepcion: DateTime.now(),
                        estado: 'pendiente',
                        detalles: <DetalleRecepcion>[],
                        usuarioResponsable: usuarioResponsable,
                        fechaCreacion: DateTime.now(),
                      );
                      await ref.read(recepcionServiceProvider).registrar(recepcion, usuarioResponsable);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Confirmar Recepción'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
