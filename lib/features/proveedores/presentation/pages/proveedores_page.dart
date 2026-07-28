import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/providers/proveedor_providers.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';

class ProveedoresPage extends ConsumerStatefulWidget {
  const ProveedoresPage({super.key});

  @override
  ConsumerState<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends ConsumerState<ProveedoresPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresAsync = ref.watch(proveedorControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
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
                        'Directorio de Proveedores',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administración de datos generales, contactos, RNC y direcciones comerciales.',
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
                    icon: const Icon(Icons.business, size: 18),
                    label: const Text(
                      'Nuevo Proveedor',
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
                    hintText: 'Buscar proveedor por nombre, RNC, contacto o correo...',
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
                  child: proveedoresAsync.when(
                    data: (proveedores) {
                      final filtrados = proveedores.where((p) =>
                        p.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        p.rnc.toLowerCase().contains(_filtroBusqueda) ||
                        p.contacto.toLowerCase().contains(_filtroBusqueda) ||
                        p.correo.toLowerCase().contains(_filtroBusqueda)
                      ).toList();

                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay proveedores registrados o coincidentes.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (context, index) {
                          final proveedor = filtrados[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.store_mall_directory_outlined, color: Color(0xFF0F172A), size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        proveedor.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'RNC: ${proveedor.rnc} | Contacto: ${proveedor.contacto}',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tel: ${proveedor.telefono} | ${proveedor.correo}',
                                        style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        proveedor.direccion,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                                      tooltip: 'Editar Proveedor',
                                      onPressed: () => _mostrarModalRegistro(context, proveedorToEdit: proveedor),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                      tooltip: 'Eliminar Proveedor',
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirmar Eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('¿Está seguro de eliminar al proveedor "${proveedor.nombre}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                                onPressed: () {
                                                  if (proveedor.id != null) {
                                                    ref.read(proveedorControllerProvider.notifier).eliminar(proveedor.id!);
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

  void _mostrarModalRegistro(BuildContext context, {Proveedor? proveedorToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: proveedorToEdit?.nombre ?? '');
    final contactoController = TextEditingController(text: proveedorToEdit?.contacto ?? '');
    final direccionController = TextEditingController(text: proveedorToEdit?.direccion ?? '');
    final telefonoController = TextEditingController(text: proveedorToEdit?.telefono ?? '');
    final correoController = TextEditingController(text: proveedorToEdit?.correo ?? '');
    final rncController = TextEditingController(text: proveedorToEdit?.rnc ?? '');
    final isEditing = proveedorToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Razón Social / Nombre Comercial'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: rncController,
                    decoration: const InputDecoration(labelText: 'RNC del Proveedor'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el RNC' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: contactoController,
                    decoration: const InputDecoration(labelText: 'Persona de Contacto'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el contacto' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el teléfono' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: correoController,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el correo' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (v) => v!.isEmpty ? 'Ingrese la dirección' : null,
                  ),
                ],
              ),
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
                  final prov = Proveedor(
                    id: proveedorToEdit?.id,
                    nombre: nombreController.text.trim(),
                    contacto: contactoController.text.trim(),
                    direccion: direccionController.text.trim(),
                    telefono: telefonoController.text.trim(),
                    correo: correoController.text.trim(),
                    rnc: rncController.text.trim(),
                  );

                  if (isEditing) {
                    ref.read(proveedorControllerProvider.notifier).actualizar(prov);
                  } else {
                    ref.read(proveedorControllerProvider.notifier).guardar(prov);
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
