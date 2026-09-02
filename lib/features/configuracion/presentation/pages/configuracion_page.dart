import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});
  static const String routeName = 'configuracion';

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController(text: 'VmartTech');
  final _rncController = TextEditingController(text: '00500468376');
  final _itbisController = TextEditingController(text: '18.0');
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  String _monedaSeleccionada = 'DOP';
  String _idiomaSeleccionado = 'Español';
  String? _logoPath; // Simulación de ruta del logo

  @override
  void dispose() {
    _nombreController.dispose();
    _rncController.dispose();
    _itbisController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera ejecutiva
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración Global',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Parámetros fiscales, identidad corporativa y preferencias del sistema.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Configuración guardada exitosamente',
                              ),
                              backgroundColor: Color(0xFF0F172A),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Contenido en dos columnas con diseño empresarial completo
                Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda: Identidad Comercial y Logotipo
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    color: Color(0xFF0F172A),
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Identidad Comercial y Fiscal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 32,
                                color: Color(0xFFE2E8F0),
                              ),

                              // Sección del Logotipo Empresarial
                              Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: _logoPath != null
                                        ? const Icon(
                                            Icons.image,
                                            color: Color(0xFF0F172A),
                                            size: 36,
                                          )
                                        : const Icon(
                                            Icons.store_mall_directory_outlined,
                                            color: Color(0xFF64748B),
                                            size: 36,
                                          ),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Logotipo del Negocio',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Formato PNG o JPG recomendado (Máx 2MB)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _logoPath = 'logo_placeholder.png';
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF0F172A,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.upload_file,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Cambiar Logo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Nombre del Negocio
                              _buildInputField(
                                label: 'Nombre Comercial / Razón Social',
                                controller: _nombreController,
                                hint: 'Ej. Almacenes Comerciales RD, S.A.',
                                icon: Icons.storefront,
                                validatorMsg: 'Ingrese el nombre del negocio',
                              ),
                              const SizedBox(height: 20),

                              // RNC o Cédula
                              _buildInputField(
                                label: 'RNC o Cédula de Identidad',
                                controller: _rncController,
                                hint: 'Ej. 131-00000-1',
                                icon: Icons.badge_outlined,
                                validatorMsg: 'Ingrese el RNC o Cédula',
                              ),
                              const SizedBox(height: 20),

                              // Dirección Física
                              _buildInputField(
                                label: 'Dirección Física del Establecimiento',
                                controller: _direccionController,
                                hint: 'Ej. Av. Principal #123, Santo Domingo',
                                icon: Icons.location_on_outlined,
                                validatorMsg: 'Ingrese la dirección',
                              ),
                              const SizedBox(height: 20),

                              // Teléfono y Correo en fila interna
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Teléfono de Contacto',
                                      controller: _telefonoController,
                                      hint: 'Ej. 809-000-0000',
                                      icon: Icons.phone_outlined,
                                      validatorMsg: 'Ingrese el teléfono',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Correo Electrónico',
                                      controller: _correoController,
                                      hint: 'Ej. contacto@negocio.com',
                                      icon: Icons.email_outlined,
                                      validatorMsg: 'Ingrese el correo',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ITBIS por defecto
                              _buildInputField(
                                label: 'Impuesto por Defecto (ITBIS %)',
                                controller: _itbisController,
                                hint: '18.0',
                                icon: Icons.percent,
                                isNumber: true,
                                validatorMsg:
                                    'Ingrese un valor válido de impuesto',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Columna Derecha: Parámetros Regionales y del Sistema
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.tune_outlined,
                                    color: Color(0xFF0F172A),
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Parámetros Regionales',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 32,
                                color: Color(0xFFE2E8F0),
                              ),

                              // Moneda Oficial
                              const Text(
                                'Moneda Oficial',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _monedaSeleccionada,
                                decoration: _inputDecoration(
                                  icon: Icons.monetization_on_outlined,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'DOP',
                                    child: Text('Peso Dominicano (DOP)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child: Text('Dólar Estadounidense (USD)'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _monedaSeleccionada = val!),
                              ),
                              const SizedBox(height: 20),

                              // Idioma
                              const Text(
                                'Idioma del Sistema',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _idiomaSeleccionado,
                                decoration: _inputDecoration(
                                  icon: Icons.language_outlined,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Español',
                                    child: Text('Español'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'English',
                                    child: Text('English'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _idiomaSeleccionado = val!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String validatorMsg,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: _inputDecoration(icon: icon, hint: hint),
          validator: (value) =>
              (value == null || value.isEmpty) ? validatorMsg : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required IconData icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
