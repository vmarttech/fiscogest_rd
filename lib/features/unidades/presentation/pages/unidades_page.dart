import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';

class UnidadesPage extends ConsumerStatefulWidget {
  const UnidadesPage({super.key});

  @override
  ConsumerState<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends ConsumerState<UnidadesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unidadesAsync = ref.watch(unidadMedidaControllerProvider);

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
                        'Unidades de Medida',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gestión de unidades de venta y compra para el inventario.',
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
                      'Nueva Unidad',
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
                    hintText: 'Buscar unidad por nombre o abreviatura...',
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
                  child: unidadesAsync.when(
                    data: (unidades) {
                      final filtradas = unidades.where((u) =>
                        u.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        (u.abreviatura?.toLowerCase().contains(_filtroBusqueda) ?? false) ||
                        (u.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                      ).toList();

                      if (filtradas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay unidades registradas o coincidentes.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (context, index) {
                          final unidad = filtradas[index];
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
                                  child: Center(
                                    child: Text(
                                      unidad.abreviatura ?? '---',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        unidad.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        unidad.abreviatura != null && unidad.abreviatura!.isNotEmpty
                                            ? 'Abreviatura: ${unidad.abreviatura}'
                                            : unidad.descripcion?.isNotEmpty ?? true
                                                ? 'Sin descripción'
                                                : unidad.descripcion!,
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
                                      tooltip: 'Editar Unidad',
                                      onPressed: () => _mostrarModalRegistro(context, unidadToEdit: unidad),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                      tooltip: 'Eliminar Unidad',
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirmar Eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('¿Está seguro de eliminar la unidad "${unidad.nombre}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                                onPressed: () {
                                                  if (unidad.id != null) {
                                                    ref.read(unidadMedidaControllerProvider.notifier).eliminar(unidad.id!);
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

  void _mostrarModalRegistro(BuildContext context, {UnidadMedida? unidadToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: unidadToEdit?.nombre ?? '');
    final abreviaturaController = TextEditingController(text: unidadToEdit?.abreviatura ?? '');
    final descripcionController = TextEditingController(text: unidadToEdit?.descripcion ?? '');
    final isEditing = unidadToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Unidad' : 'Nueva Unidad', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Unidad'),
                  validator: (v) => v?.isEmpty ?? true ? 'Ingrese el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: abreviaturaController,
                  decoration: const InputDecoration(labelText: 'Abreviatura (ej. UND, KG)'),
                  maxLength: 8,
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
                  final und = UnidadMedida(
                    id: unidadToEdit?.id,
                    nombre: nombreController.text.trim(),
                    abreviatura: abreviaturaController.text.trim().isEmpty ? null : abreviaturaController.text.trim().toUpperCase(),
                    descripcion: descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                    creadoEn: unidadToEdit?.creadoEn ?? DateTime.now(),
                    actualizadoEn: isEditing ? DateTime.now() : null,
                  );

                  if (isEditing) {
                    ref.read(unidadMedidaControllerProvider.notifier).actualizar(und);
                  } else {
                    ref.read(unidadMedidaControllerProvider.notifier).guardar(und);
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