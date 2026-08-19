import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';

  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  final _buscadorController = TextEditingController();
  String _ventaNumero = '';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ventaNumero = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _cobrarYRegistrarSalida() async {
    setState(() => _cargando = true);
    try {
      final venta = Venta(
        numero: _ventaNumero,
        clienteId: 1,
        fecha: DateTime.now(),
        detalles: const [],
        subtotal: 0.0,
        itbis: 0.0,
        total: 0.0,
        tipoPago: '',
        esCredito: false,
        createdAt: DateTime.now(),
      );

      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final ventaGuardada = await casoUso(venta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venta registrada. ID: ${ventaGuardada.id}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPantallaAncha = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'Registrar Venta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: esPantallaAncha
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildZonaIzquierda()),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(flex: 2, child: _buildZonaDerecha()),
                ],
              )
            : Column(
                children: [
                  _buildZonaIzquierda(),
                  const SizedBox(height: 16),
                  _buildZonaDerecha(),
                ],
              ),
      ),
    );
  }

  Widget _buildZonaIzquierda() {
    return AppSection(
      title: 'Artículos / Búsqueda',
      children: [
        AppTextField(
          label: 'Buscar artículo por nombre, código o EAN',
          prefixIcon: Icons.search,
          controller: _buscadorController,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 8,
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Cantidad')),
              DataColumn(label: Text('Acción')),
            ],
            rows: const [],
          ),
        ),
      ],
    );
  }

  Widget _buildZonaDerecha() {
    return AppSection(
      title: 'Resumen de Venta',
      children: [
        Text('Venta N°: $_ventaNumero', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Items: 0'),
        const Text('Subtotal: RD\$ 0.00'),
        const Text('ITBIS: RD\$ 0.00'),
        const Text('TOTAL: RD\$ 0.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        AppButton(
          text: _cargando ? 'Guardando...' : '✅ Cobrar y Registrar Salida',
          onPressed: _cargando ? null : _cobrarYRegistrarSalida,
        ),
      ],
    );
  }
}
