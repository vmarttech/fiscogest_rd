import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/negocio.dart';
import 'package:fiscogestrd/providers/negocio_providers.dart';

class ConfiguracionNegocioScreen extends ConsumerStatefulWidget {
  const ConfiguracionNegocioScreen({super.key});

  @override
  ConsumerState<ConfiguracionNegocioScreen> createState() =>
      _ConfiguracionNegocioScreenState();
}

class _ConfiguracionNegocioScreenState
    extends ConsumerState<ConfiguracionNegocioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos
  final _nombreController = TextEditingController();
  final _rncController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _actividadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar datos existentes cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estado = ref.read(negocioProvider);
      estado.whenData((negocio) {
        if (negocio != null) {
          _nombreController.text = negocio.nombre;
          _rncController.text = negocio.rnc;
          _direccionController.text = negocio.direccion;
          _telefonoController.text = negocio.telefono;
          _correoController.text = negocio.correo;
          _actividadController.text = negocio.actividadEconomica;
        }
      });
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rncController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _actividadController.dispose();
    super.dispose();
  }

  // Función para guardar
  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final negocio = Negocio(
        nombre: _nombreController.text.trim(),
        rnc: _rncController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        correo: _correoController.text.trim(),
        actividadEconomica: _actividadController.text.trim(),
      );

      try {
        await ref.read(negocioProvider.notifier).guardar(negocio);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos guardados correctamente ✅')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar: $e ❌')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(negocioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Datos del Negocio'), centerTitle: true),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nombre del Negocio
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre o Razón Social *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // RNC
                TextFormField(
                  controller: _rncController,
                  decoration: const InputDecoration(
                    labelText: 'RNC / Cédula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Dirección
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Correo
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Actividad Económica
                TextFormField(
                  controller: _actividadController,
                  decoration: const InputDecoration(
                    labelText: 'Actividad Económica',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('GUARDAR DATOS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
