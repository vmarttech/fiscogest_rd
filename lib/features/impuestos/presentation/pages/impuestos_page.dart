import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/providers/impuesto_providers.dart';
import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';

class ImpuestosPage extends ConsumerStatefulWidget {
  const ImpuestosPage({super.key});
  static const String routeName = 'impuestos';

  @override
  ConsumerState<ImpuestosPage> createState() => _ImpuestosPageState();
}

class _ImpuestosPageState extends ConsumerState<ImpuestosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const surfaceColor = Colors.white;
    const backgroundColor = Color(0xFFF4F6F9);
    const borderColor = Color(0xFFE2E8F0);
    const textColor = Color(0xFF1E293B);
    const subtitleColor = Color(0xFF64748B);

    final impuestosAsync = ref.watch(impuestoControllerProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                        'Configuración Tributaria e ITBIS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administración centralizada de tasas impositivas, tipos globales y exenciones fiscales.',
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarModalRegistro(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add_chart_outlined, size: 18),
                    label: const Text(
                      'Nuevo Impuesto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _filtroBusqueda = value.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText:
                        'Buscar impuesto por nombre, tipo o descripción...',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: subtitleColor,
                      size: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: impuestosAsync.when(
                    data: (impuestos) {
                      final filtrados = impuestos
                          .where(
                            (i) =>
                                i.nombre.toLowerCase().contains(
                                  _filtroBusqueda,
                                ) ||
                                i.tipo.toLowerCase().contains(
                                  _filtroBusqueda,
                                ) ||
                                i.descripcion.toLowerCase().contains(
                                  _filtroBusqueda,
                                ),
                          )
                          .toList();

                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay impuestos registrados o coincidentes.',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: borderColor, height: 1),
                        itemBuilder: (context, index) {
                          final impuesto = filtrados[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: impuesto.esExento
                                        ? const Color(0xFFFEF2F2)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${impuesto.porcentaje.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: impuesto.esExento
                                            ? const Color(0xFFDC2626)
                                            : primaryColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            impuesto.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: impuesto.esExento
                                                  ? const Color(0xFFFEE2E2)
                                                  : const Color(0xFFE0F2FE),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              impuesto.tipo,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: impuesto.esExento
                                                    ? const Color(0xFF991B1B)
                                                    : const Color(0xFF0369A1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        impuesto.descripcion.isEmpty
                                            ? 'Sin descripción'
                                            : impuesto.descripcion,
                                        style: const TextStyle(
                                          color: subtitleColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                      tooltip: 'Editar Impuesto',
                                      onPressed: () => _mostrarModalRegistro(
                                        context,
                                        impuestoToEdit: impuesto,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar Impuesto',
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Confirmar Eliminación',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              '¿Está seguro de eliminar el impuesto "${impuesto.nombre}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFDC2626,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () {
                                                  if (impuesto.id != null) {
                                                    ref
                                                        .read(
                                                          impuestoControllerProvider
                                                              .notifier,
                                                        )
                                                        .eliminar(impuesto.id!);
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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

  void _mostrarModalRegistro(
    BuildContext context, {
    ImpuestoEntity? impuestoToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: impuestoToEdit?.nombre ?? '',
    );
    final porcentajeController = TextEditingController(
      text: impuestoToEdit != null ? impuestoToEdit.porcentaje.toString() : '',
    );
    final descripcionController = TextEditingController(
      text: impuestoToEdit?.descripcion ?? '',
    );
    String tipoSeleccionado = impuestoToEdit?.tipo ?? 'ITBIS';
    bool esExento = impuestoToEdit?.esExento ?? false;
    final isEditing = impuestoToEdit != null;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: Text(
            isEditing ? 'Editar Impuesto' : 'Nuevo Impuesto Tributario',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Impuesto (ej. ITBIS 18%)',
                      ),
                      validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Impuesto Global',
                      ),
                      items: ['ITBIS', 'Exento', 'Adicional', 'Selectivo']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setStateModal(() {
                          tipoSeleccionado = val!;
                          if (tipoSeleccionado == 'Exento') {
                            esExento = true;
                            porcentajeController.text = '0';
                          } else {
                            esExento = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: porcentajeController,
                      decoration: const InputDecoration(
                        labelText: 'Porcentaje (%)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Ingrese el porcentaje';
                        final num = double.tryParse(v);
                        if (num == null || num < 0) {
                          return 'Ingrese un valor válido mayor o igual a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        '¿Es Exento de Impuesto?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: esExento,
                      onChanged: (val) {
                        setStateModal(() {
                          esExento = val;
                          if (esExento) porcentajeController.text = '0';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Base legal',
                      ),
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
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  try {
                    final impuesto = ImpuestoEntity(
                      id: impuestoToEdit?.id,
                      nombre: nombreController.text.trim(),
                      porcentaje: double.parse(
                        porcentajeController.text.trim(),
                      ),
                      tipo: tipoSeleccionado,
                      esExento: esExento,
                      descripcion: descripcionController.text.trim(),
                    );

                    if (isEditing) {
                      ref
                          .read(impuestoControllerProvider.notifier)
                          .actualizar(impuesto);
                    } else {
                      ref
                          .read(impuestoControllerProvider.notifier)
                          .guardar(impuesto);
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
