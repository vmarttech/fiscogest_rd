import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';

class MarcasPage extends ConsumerStatefulWidget {
  const MarcasPage({super.key});

  @override
  ConsumerState<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends ConsumerState<MarcasPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marcasAsync = ref.watch(marcaControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo de Marcas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administración de marcas comerciales del sistema.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarModalRegistro(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Nueva Marca',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _filtroBusqueda = value.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar marca por nombre...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: marcasAsync.when(
                    data: (marcas) {
                      final filtradas = marcas.where((m) =>
                        m.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        (m.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                      ).toList();

                      if (filtradas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay marcas registradas o coincidentes.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (context, index) {
                          final marca = filtradas[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.verified_outlined, color: Color(0xFF0F172A), size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        marca.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        marca.descripcion?.isEmpty ?? true ? 'Sin descripción' : marca.descripcion!,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                                      tooltip: 'Editar Marca',
                                      onPressed: () => _mostrarModalRegistro(context, marcaToEdit: marca),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                      tooltip: 'Eliminar Marca',
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirmar Eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('¿Está seguro de eliminar la marca "${marca.nombre}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                                onPressed: () {
                                                  if (marca.id != null) {
                                                    ref.read(marcaControllerProvider.notifier).eliminar(marca.id!);
                                                  }
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalRegistro(BuildContext context, {Marca? marcaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: marcaToEdit?.nombre ?? '');
    final descripcionController = TextEditingController(text: marcaToEdit?.descripcion ?? '');
    final isEditing = marcaToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Marca' : 'Nueva Marca', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Marca'),
                  validator: (v) => v?.isEmpty ?? true ? 'Ingrese el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                try {
                  final mar = Marca(
                    id: marcaToEdit?.id,
                    nombre: nombreController.text.trim(),
                    descripcion: descripcionController.text.trim(),
                    creadoEn: marcaToEdit?.creadoEn ?? DateTime.now(),
                    actualizadoEn: isEditing ? DateTime.now() : null,
                  );

                  if (isEditing) {
                    ref.read(marcaControllerProvider.notifier).actualizar(mar);
                  } else {
                    ref.read(marcaControllerProvider.notifier).guardar(mar);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}