import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/cliente.dart';
import 'package:fiscogestrd/providers/cliente_provider.dart';
import 'package:fiscogestrd/services/dgii_service.dart';

class FormularioClienteScreen extends ConsumerStatefulWidget {
  const FormularioClienteScreen({super.key, this.cliente});
  final Cliente? cliente;

  @override
  ConsumerState<FormularioClienteScreen> createState() =>
      _FormularioClienteScreenState();
}

class _FormularioClienteScreenState
    extends ConsumerState<FormularioClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final IDgiiService _dgiiService = DgiiService();

  final _ctrlNombre = TextEditingController();
  final _ctrlIdentificacion = TextEditingController();
  final _ctrlDireccion = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlCorreo = TextEditingController();

  String _tipoIdentificacion = 'CÉDULA';
  bool _exentoITBIS = false;
  String _regimenFiscal = 'Normal';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _ctrlNombre.text = widget.cliente!.nombre;
      _ctrlIdentificacion.text = widget.cliente!.identificacion;
      _ctrlDireccion.text = widget.cliente!.direccion ?? '';
      _ctrlTelefono.text = widget.cliente!.telefono ?? '';
      _ctrlCorreo.text = widget.cliente!.correo ?? '';
      _tipoIdentificacion = widget.cliente!.tipoIdentificacion;
      _exentoITBIS = widget.cliente!.exentoITBIS;
      _regimenFiscal = widget.cliente!.regimenFiscal;
    }
    _ctrlIdentificacion.addListener(_alEscribirIdentificacion);
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlIdentificacion.dispose();
    _ctrlDireccion.dispose();
    _ctrlTelefono.dispose();
    _ctrlCorreo.dispose();
    super.dispose();
  }

  void _alEscribirIdentificacion() {
    final texto = _ctrlIdentificacion.text.trim();
    if (texto.isNotEmpty && (texto.length == 11 || texto.length == 13)) {
      _ejecutarBusqueda(texto);
    }
  }

  Future<void> _ejecutarBusqueda(String numero) async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      final datos = await _dgiiService.buscarContribuyente(numero);

      if (mounted && datos != null) {
        setState(() {
          _ctrlNombre.text = datos['nombre'] ?? '';
          _regimenFiscal = datos['regimen'] ?? 'Normal';
          _exentoITBIS = datos['exento'] ?? false;
          _tipoIdentificacion = numero.length == 13 ? 'RNC' : 'CÉDULA';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos cargados correctamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final cliente = Cliente(
        id: widget.cliente?.id,
        nombre: _ctrlNombre.text.trim(),
        identificacion: _ctrlIdentificacion.text.trim(),
        tipoIdentificacion: _tipoIdentificacion,
        direccion: _ctrlDireccion.text.trim(),
        telefono: _ctrlTelefono.text.trim(),
        correo: _ctrlCorreo.text.trim(),
        exentoITBIS: _exentoITBIS,
        regimenFiscal: _regimenFiscal,
        fechaRegistro: DateTime.now(),
      );

      try {
        await ref.read(clienteNotifierProvider.notifier).guardar(cliente);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cliente guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cliente != null ? 'Editar Cliente' : 'Nuevo Cliente',
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          TextButton(
            onPressed: _guardar,
            child: const Text(
              'GUARDAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _ctrlIdentificacion,
                decoration: InputDecoration(
                  labelText: 'RNC / CÉDULA',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                  suffixIcon: _cargando
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.search, color: Colors.blue),
                  hintText: 'Escriba 11 o 13 dígitos...',
                ),
                keyboardType: TextInputType.number,
                maxLength: 13,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length != 11 && v.length != 13) {
                    return 'Debe tener 11 o 13 dígitos';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _ctrlNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre o Razón Social',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              const SizedBox(height: 15),

              // ✅ SOLO SE CAMBIÓ value -> initialValue AQUÍ, LO DEMÁS IGUAL
              DropdownButtonFormField<String>(
                initialValue: _tipoIdentificacion,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Identificación',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CÉDULA', child: Text('CÉDULA')),
                  DropdownMenuItem(value: 'RNC', child: Text('RNC')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoIdentificacion = v);
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                initialValue: _regimenFiscal,
                decoration: const InputDecoration(
                  labelText: 'Régimen Fiscal',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),

              const SizedBox(height: 15),

              // ✅ value SE QUEDA AQUÍ, ES CORRECTO
              SwitchListTile(
                title: const Text('¿Exento de ITBIS?'),
                subtitle: const Text('Se marca automáticamente según DGII'),
                value: _exentoITBIS,
                onChanged: (v) => setState(() => _exentoITBIS = v),
                activeThumbColor: Colors.green,
              ),

              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 15),

              TextFormField(
                controller: _ctrlDireccion,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ctrlTelefono,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ctrlCorreo,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
