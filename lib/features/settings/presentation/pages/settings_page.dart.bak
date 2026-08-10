import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _rncController = TextEditingController(text: '131-23456-7');
  final _razonSocialController = TextEditingController(text: 'FiscoGest Soluciones SRL');
  final _telefonoController = TextEditingController(text: '809-555-1234');
  final _direccionController = TextEditingController(text: 'Av. 27 de Febrero, Santo Domingo');

  String _idiomaSeleccionado = 'Español (DO)';
  String _monedaSeleccionada = 'DOP (RD\$)';
  String _formatoFecha = 'DD/MM/AAAA';
  double _tasaItbisDefault = 18.0;
  bool _modoPruebasDGII = true;
  bool _respaldoAutomatico = true;
  String? _logoPath;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const backgroundColor = Color(0xFFF4F6F9);
    const borderColor = Color(0xFFE2E8F0);
    const textColor = Color(0xFF1E293B);
    const subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración Global del Sistema',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administración centralizada, identidad del negocio, moneda, impuestos y parámetros DGII.',
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuración global guardada correctamente.')),
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Guardar Cambios'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Diseño en Recuadros / Tarjetas Profesionales
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    // Recuadro 1: Identidad y Negocio (Logo y RNC)
                    _buildCard(
                      title: 'Identidad del Negocio y Logo',
                      subtitle: 'Logotipo corporativo y datos del contribuyente',
                      width: constraints.maxWidth > 900 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                      borderColor: borderColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: _logoPath != null
                                    ? const Icon(Icons.business, size: 35, color: primaryColor)
                                    : const Icon(Icons.camera_alt_outlined, size: 30, color: subtitleColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _logoPath = 'logo_cargado.png';
                                        });
                                      },
                                      icon: const Icon(Icons.upload_file, size: 16),
                                      label: const Text('Subir / Cambiar Logo'),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('PNG, JPG hasta 2MB recomendados.', style: TextStyle(fontSize: 11, color: subtitleColor)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _rncController,
                            decoration: const InputDecoration(labelText: 'RNC o Cédula', border: OutlineInputBorder(), isDense: true),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _razonSocialController,
                            decoration: const InputDecoration(labelText: 'Razón Social / Nombre Comercial', border: OutlineInputBorder(), isDense: true),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _telefonoController,
                                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _direccionController,
                                  decoration: const InputDecoration(labelText: 'Dirección Fiscal', border: OutlineInputBorder(), isDense: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Recuadro 2: Idioma, Moneda y Formatos
                    _buildCard(
                      title: 'Idioma, Moneda y Formatos',
                      subtitle: 'Localización y presentación de valores',
                      width: constraints.maxWidth > 900 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                      borderColor: borderColor,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _idiomaSeleccionado,
                            decoration: const InputDecoration(labelText: 'Idioma del Sistema', border: OutlineInputBorder(), isDense: true),
                            items: ['Español (DO)', 'English (US)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _idiomaSeleccionado = val!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _monedaSeleccionada,
                            decoration: const InputDecoration(labelText: 'Moneda Principal', border: OutlineInputBorder(), isDense: true),
                            items: ['DOP (RD\$)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _monedaSeleccionada = val!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _formatoFecha,
                            decoration: const InputDecoration(labelText: 'Formato de Fecha', border: OutlineInputBorder(), isDense: true),
                            items: ['DD/MM/AAAA', 'MM/DD/AAAA', 'AAAA-MM-DD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _formatoFecha = val!),
                          ),
                        ],
                      ),
                    ),

                    // Recuadro 3: Impuestos y Normativa DGII
                    _buildCard(
                      title: 'Impuestos y Normativa Fiscal',
                      subtitle: 'Configuración de tasas y comprobantes',
                      width: constraints.maxWidth > 900 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                      borderColor: borderColor,
                      child: Column(
                        children: [
                          DropdownButtonFormField<double>(
                            initialValue: _tasaItbisDefault,
                            decoration: const InputDecoration(labelText: 'Tasa ITBIS Predeterminada', border: OutlineInputBorder(), isDense: true),
                            items: [18.0, 16.0, 0.0].map((e) => DropdownMenuItem(value: e, child: Text('$e%'))).toList(),
                            onChanged: (val) => setState(() => _tasaItbisDefault = val!),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Modo Pruebas / Sandbox DGII', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Conexión con servidores de prueba para e-NCF.'),
                            value: _modoPruebasDGII,
                            onChanged: (val) => setState(() => _modoPruebasDGII = val),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    // Recuadro 4: Preferencias y Respaldos
                    _buildCard(
                      title: 'Preferencias y Seguridad',
                      subtitle: 'Copias de seguridad automáticas y comportamiento',
                      width: constraints.maxWidth > 900 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                      borderColor: borderColor,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Respaldo Automático SQLite', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text('Genera respaldo cifrado al salir del sistema.'),
                            value: _respaldoAutomatico,
                            onChanged: (val) => setState(() => _respaldoAutomatico = val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Base de datos respaldada con éxito.')),
                              );
                            },
                            icon: const Icon(Icons.backup_outlined, size: 18),
                            label: const Text('Generar Respaldo Manual Ahora'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required double width,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          child,
        ],
      ),
    );
  }
}
