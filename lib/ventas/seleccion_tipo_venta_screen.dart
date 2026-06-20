import 'package:flutter/material.dart';

class SeleccionTipoVentaScreen extends StatelessWidget {
  const SeleccionTipoVentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              '¿Qué tipo de operación vas a realizar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2463),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Elige la opción que corresponda para generar el registro correcto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 40),

            // Opción 1: Venta Rápida
            _TarjetaOpcion(
              icono: Icons.speed,
              colorIcono: const Color(0xFF10B981),
              titulo: 'Venta Rápida',
              subtitulo: 'Para consumidores finales, sin datos fiscales',
              descripcion: 'Registra la venta, calcula el ITBIS y guarda el movimiento. No requiere ingresar RNC ni datos del cliente.',
              alPresionar: () {
                Navigator.pushNamed(context, '/venta-rapida');
              },
            ),

            const SizedBox(height: 24),

            // Opción 2: Venta con Comprobante ✅ RUTA CORREGIDA
            _TarjetaOpcion(
              icono: Icons.receipt_long,
              colorIcono: const Color(0xFF1D4ED8),
              titulo: 'Venta con Comprobante',
              subtitulo: 'Con validez fiscal para reportar a la DGII',
              descripcion: 'Ingresa datos del cliente, número de comprobante, cálculos de impuestos y genera el registro oficial.',
              alPresionar: () {
                Navigator.pushNamed(context, '/venta-con-comprobante');
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final VoidCallback alPresionar;

  const _TarjetaOpcion({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorIcono.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: colorIcono,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorIcono,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}