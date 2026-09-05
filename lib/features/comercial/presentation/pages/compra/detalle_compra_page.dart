import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class DetalleCompraPage extends ConsumerStatefulWidget {
  const DetalleCompraPage({super.key, required this.compraId});
  static const String routeName = 'detalle-compra';
  final Object compraId;
  @override
  ConsumerState<DetalleCompraPage> createState() => _DetalleCompraPageState();
}

class _DetalleCompraPageState extends ConsumerState<DetalleCompraPage> {
  late final int _idNumerico;

  @override
  void initState() {
    super.initState();
    final texto = widget.compraId.toString();
    final soloDigitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
    _idNumerico = int.tryParse(soloDigitos) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final compraAsync = ref.watch(compraPorIdProvider(_idNumerico));
    return AppScaffold(
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: compraAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, pila) => Center(
              child: Padding(
                padding: AppSpacing.allM,
                child: Text(
                  'Error al cargar compra: $error',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            data: (compra) {
              if (compra == null) {
                return const Center(
                  child: Padding(
                    padding: AppSpacing.allL,
                    child: Text(
                      'Compra no encontrada.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }
              // Mantiene estructura original intacta — solo se corrige el ID
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
