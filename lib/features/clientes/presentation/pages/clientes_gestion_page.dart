import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';

class ClientesGestionPage extends ConsumerStatefulWidget {
  const ClientesGestionPage({super.key});
  static const String routeName = 'clientes-gestion';

  @override
  ConsumerState<ClientesGestionPage> createState() => _ClientesGestionPageState();
}

class _ClientesGestionPageState extends ConsumerState<ClientesGestionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clienteCompletoControllerProvider);

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
                        'Cartera de Clientes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administración de datos personales, fiscales, direcciones e historial.',
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
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text(
                      'Nuevo Cliente',
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
                    hintText: 'Buscar cliente por nombre, RNC/Cédula, teléfono o correo...',
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
                  child: clientesAsync.when(
                    data: (clientes) {
                      final filtrados = clientes.where((c) =>
                        c.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        c.rncCedula.toLowerCase().contains(_filtroBusqueda) ||
                        c.telefono.toLowerCase().contains(_filtroBusqueda) ||
                        c.correo.toLowerCase().contains(_filtroBusqueda)
                      ).toList();

                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay clientes registrados o coincidentes.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (context, index) {
                          final cliente = filtrados[index];
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
                                  child: const Icon(Icons.person_outline, color: Color(0xFF0F172A), size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'RNC/Cédula: ${cliente.rncCedula} | Tel: ${cliente.telefono}',
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
                                        cliente.correo,
                                        style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cliente.direccion,
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
                                      icon: const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
                                      tooltip: 'Ver Historial e Info',
                                      onPressed: () => _mostrarDetallesCliente(context, cliente),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                                      tooltip: 'Editar Cliente',
                                      onPressed: () => _mostrarModalRegistro(context, clienteToEdit: cliente),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                      tooltip: 'Eliminar Cliente',
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Confirmar Eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('¿Está seguro de eliminar al cliente "${cliente.nombre}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                                onPressed: () {
                                                  if (cliente.id != null) {
                                                    ref.read(clienteCompletoControllerProvider.notifier).eliminar(cliente.id!);
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

  void _mostrarDetallesCliente(BuildContext context, ClienteCompleto cliente) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial y Detalles: ${cliente.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RNC / Cédula: ${cliente.rncCedula}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Teléfono: ${cliente.telefono}'),
              Text('Correo: ${cliente.correo}'),
              Text('Dirección: ${cliente.direccion}'),
              const SizedBox(height: 12),
              const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cliente.observaciones.isEmpty ? 'Ninguna' : cliente.observaciones, style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              const Text('Historial de Transacciones / Eventos:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Text(cliente.historial, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarModalRegistro(BuildContext context, {ClienteCompleto? clienteToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: clienteToEdit?.nombre ?? '');
    final direccionController = TextEditingController(text: clienteToEdit?.direccion ?? '');
    final telefonoController = TextEditingController(text: clienteToEdit?.telefono ?? '');
    final correoController = TextEditingController(text: clienteToEdit?.correo ?? '');
    final rncCedulaController = TextEditingController(text: clienteToEdit?.rncCedula ?? '');
    final observacionesController = TextEditingController(text: clienteToEdit?.observaciones ?? '');
    final isEditing = clienteToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    decoration: const InputDecoration(labelText: 'Nombre / Razón Social'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: rncCedulaController,
                    decoration: const InputDecoration(labelText: 'RNC o Cédula'),
                    validator: (v) => v!.isEmpty ? 'Ingrese el RNC o Cédula' : null,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: observacionesController,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    maxLines: 2,
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
                  final cli = ClienteCompleto(
                    id: clienteToEdit?.id,
                    nombre: nombreController.text.trim(),
                    direccion: direccionController.text.trim(),
                    telefono: telefonoController.text.trim(),
                    correo: correoController.text.trim(),
                    rncCedula: rncCedulaController.text.trim(),
                    observaciones: observacionesController.text.trim(),
                    historial: clienteToEdit?.historial ?? 'Cliente registrado en el sistema.',
                  );

                  if (isEditing) {
                    ref.read(clienteCompletoControllerProvider.notifier).actualizar(cli);
                  } else {
                    ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);
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
