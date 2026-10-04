import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

class LicenciaActivarPage extends ConsumerStatefulWidget {
  const LicenciaActivarPage({super.key});

  static const routeName = 'licencia-activar';
  static const path = '/licencia/activar';

  @override
  ConsumerState<LicenciaActivarPage> createState() => _LicenciaActivarPageState();
}

class _LicenciaActivarPageState extends ConsumerState<LicenciaActivarPage> {
  final _ctrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _activar() async {
    final refCode = _ctrl.text.trim().toUpperCase();
    if (!refCode.startsWith('FG-')) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Usa la referencia FG-XXXXX del pedido pagado.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      await ref.read(licenciaServiceProvider).marcarPagadoYEmitirLicencia(refCode);
      ref.invalidate(licenciaActualProvider);
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Licencia activada')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.sizeOf(context).width < 700;

    return AppScaffold(
      title: 'Activar licencia',
      body: ListView(
        padding: EdgeInsets.fromLTRB(esMovil ? 16 : 24, 16, esMovil ? 16 : 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.key_outlined, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solo si te confirmamos una referencia FG- ya pagada. '
                    'MartTech (dueño) no necesita este paso.',
                    style: TextStyle(color: Colors.white, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Referencia', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'FG-XXXXX',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _cargando ? null : _activar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_cargando ? '…' : 'Activar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
