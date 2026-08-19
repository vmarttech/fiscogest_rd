import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';
  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  final TextEditingController _buscadorController = TextEditingController();
  String _ventaNumero = '';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ventaNumero =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
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
        usuarioId: 1,
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Venta registrada correctamente. ID: ${ventaGuardada.id}',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            backgroundColor: const Color(0xFFC62828),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text('Error al registrar la venta: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar Venta',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool esDesktop = constraints.maxWidth >= 950;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              esDesktop ? 28 : 16,
              20,
              esDesktop ? 28 : 16,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEncabezado(esDesktop),
                const SizedBox(height: 20),
                esDesktop
                    ? _buildLayoutDesktop()
                    : _buildLayoutMovil(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEncabezado(bool esDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: esDesktop ? 22 : 18,
        vertical: esDesktop ? 18 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E7ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: esDesktop ? 48 : 44,
            height: esDesktop ? 48 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Color(0xFF1565C0),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva venta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20242A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Agrega productos y completa los datos de la operación.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (esDesktop) ...[
            const SizedBox(width: 20),
            _buildNumeroVenta(),
          ],
        ],
      ),
    );
  }

  Widget _buildNumeroVenta() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E6EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'VENTA N.º',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .7,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _ventaNumero,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20242A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _buildPanelProductos(),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 4,
          child: _buildPanelResumen(),
        ),
      ],
    );
  }

  Widget _buildLayoutMovil() {
    return Column(
      children: [
        _buildPanelProductos(),
        const SizedBox(height: 16),
        _buildPanelResumen(),
      ],
    );
  }

  Widget _buildPanelProductos() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTituloSeccion(
            icono: Icons.inventory_2_outlined,
            titulo: 'Productos',
            subtitulo: 'Busca y agrega artículos a la venta',
          ),
          const SizedBox(height: 18),
          _buildBuscador(),
          const SizedBox(height: 18),
          _buildEncabezadoCarrito(),
          const Divider(
            height: 1,
            color: Color(0xFFE8EBEF),
          ),
          _buildEstadoVacio(),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFDCE1E7),
        ),
      ),
      child: TextField(
        controller: _buscadorController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por nombre, código o EAN...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF68717D),
            size: 22,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFFE1E5EA),
              ),
            ),
            child: const Center(
              widthFactor: 1,
              child: Text(
                'Buscar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF68717D),
                ),
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezadoCarrito() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      color: const Color(0xFFF8F9FB),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'ARTÍCULO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
                color: Color(0xFF6B737D),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CANT.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
                color: Color(0xFF6B737D),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PRECIO',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
                color: Color(0xFF6B737D),
              ),
            ),
          ),
          SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 52,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 32,
                color: Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay productos en la venta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF363C43),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Busca un producto utilizando su nombre,\ncódigo o código de barras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.45,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelResumen() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTituloSeccion(
            icono: Icons.receipt_long_outlined,
            titulo: 'Resumen de venta',
            subtitulo: 'Información y totales',
          ),
          const SizedBox(height: 18),
          _buildDatosVenta(),
          const SizedBox(height: 18),
          const Divider(
            height: 1,
            color: Color(0xFFE6E9ED),
          ),
          const SizedBox(height: 18),
          _buildTotales(),
          const SizedBox(height: 20),
          _buildBotonCobrar(),
        ],
      ),
    );
  }

  Widget _buildDatosVenta() {
    return Column(
      children: [
        _buildDatoFila(
          icono: Icons.confirmation_number_outlined,
          titulo: 'Número de venta',
          valor: _ventaNumero,
        ),
        const SizedBox(height: 10),
        _buildDatoFila(
          icono: Icons.person_outline_rounded,
          titulo: 'Cliente',
          valor: 'Consumidor final',
          mostrarFlecha: true,
        ),
        const SizedBox(height: 10),
        _buildDatoFila(
          icono: Icons.payments_outlined,
          titulo: 'Forma de pago',
          valor: 'Seleccionar',
          mostrarFlecha: true,
        ),
      ],
    );
  }

  Widget _buildDatoFila({
    required IconData icono,
    required String titulo,
    required String valor,
    bool mostrarFlecha = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E8EC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            size: 19,
            color: const Color(0xFF68717D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF30363D),
                  ),
                ),
              ],
            ),
          ),
          if (mostrarFlecha)
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF9AA2AB),
            ),
        ],
      ),
    );
  }

  Widget _buildTotales() {
    return Column(
      children: [
        _buildTotalFila(
          titulo: 'Artículos',
          valor: '0',
        ),
        const SizedBox(height: 9),
        _buildTotalFila(
          titulo: 'Subtotal',
          valor: 'RD\$ 0.00',
        ),
        const SizedBox(height: 9),
        _buildTotalFila(
          titulo: 'ITBIS',
          valor: 'RD\$ 0.00',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0xFFE3E6EA),
              ),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242A),
                  ),
                ),
              ),
              Text(
                'RD\$ 0.00',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalFila({
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF343A40),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonCobrar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _cobrarYRegistrarSalida,
        icon: _cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Icon(
                Icons.point_of_sale_rounded,
                size: 20,
              ),
        label: Text(
          _cargando
              ? 'Registrando venta...'
              : 'Cobrar y registrar salida',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9EB9D7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTituloSeccion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icono,
            size: 20,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF252A30),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}
