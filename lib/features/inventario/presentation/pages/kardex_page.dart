import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';

class KardexPage extends ConsumerStatefulWidget {
  const KardexPage({super.key, this.productoId});
  final String? productoId;

  @override
  ConsumerState<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends ConsumerState<KardexPage> {
  late final int? _productoIdFijo;
  String _filtroBusqueda = '';
  TipoMovimiento? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _productoIdFijo = widget.productoId != null ? int.tryParse(widget.productoId!) : null;
  }

  @override
  Widget build(BuildContext context) {
    final movimientosAsync = ref.watch(
      kardexPorProductoProvider(_productoIdFijo?.toString() ?? ''),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Movimientos (Kárdex)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Entradas, salidas, ajustes, transferencias y traslados del inventario.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (valor) => setState(
                          () => _filtroBusqueda = valor.trim().toLowerCase(),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar por producto, documento o fecha...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TipoMovimiento>(
                      initialValue: _filtroTipo,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      hint: const Text('Tipo Movimiento', style: TextStyle(fontSize: 13)),
                      items: TipoMovimiento.values.map((tipo) => DropdownMenuItem<TipoMovimiento>(
                        value: tipo,
                        child: Text(tipo.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (valor) => setState(() => _filtroTipo = valor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: movimientosAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, pila) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error al cargar movimientos: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                    data: (movimientos) {
                      final filtrados = movimientos.where((mov) {
                        if (_productoIdFijo != null && mov.productoId != _productoIdFijo) return false;
                        final coincideTexto = mov.productoId.toString().contains(_filtroBusqueda) ||
                            (mov.documentoReferencia?.toLowerCase().contains(_filtroBusqueda) ?? false);
                        final coincideTipo = _filtroTipo == null || mov.tipoMovimiento == _filtroTipo;
                        return coincideTexto && coincideTipo;
                      }).toList();

                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay movimientos registrados o coincidentes.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFFE2E8F0), height: 1),
                        itemBuilder: (_, indice) {
                          final mov = filtrados[indice];
                          final colorTipo = switch(mov.tipoMovimiento) {
                            TipoMovimiento.entrada => const Color(0xFF10B981),
                            TipoMovimiento.salida => const Color(0xFFEF4444),
                            TipoMovimiento.ajuste => const Color(0xFFF59E0B),
                            TipoMovimiento.transferencia => const Color(0xFF6366F1),
                            _ => const Color(0xFF8B5CF6),
                          };
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 48,
                                  decoration: BoxDecoration(color: colorTipo, borderRadius: BorderRadius.circular(4)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mov.tipoMovimiento.name.toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Prod: ${mov.productoId} • Doc: ${mov.documentoReferencia ?? 'Sin documento'}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                      Text(
                                        'Cant: ${mov.cantidad} • Saldo: ${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${mov.fechaMovimiento!.day.toString().padLeft(2,'0')}/'
                                  '${mov.fechaMovimiento!.month.toString().padLeft(2,'0')}/'
                                  '${mov.fechaMovimiento!.year}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
