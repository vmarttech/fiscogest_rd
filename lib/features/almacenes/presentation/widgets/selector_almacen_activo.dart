import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_activo_provider.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';

/// Chip / botón para ver y cambiar la sucursal (almacén) activa.
/// Si el plan no permite almacenes o solo hay uno, muestra solo el nombre.
class SelectorAlmacenActivo extends ConsumerWidget {
  const SelectorAlmacenActivo({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habilitado = ref.watch(almacenesHabilitadosProvider);
    final activo = ref.watch(almacenActivoProvider);
    final listaAsync = ref.watch(almacenesControllerProvider);

    if (!habilitado) {
      return const SizedBox.shrink();
    }

    return listaAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => const Icon(Icons.store_mall_directory_outlined),
      data: (lista) {
        final activos = lista.where((a) => a.activo).toList();
        if (activos.isEmpty) {
          return const SizedBox.shrink();
        }
        final actual = activo ?? activos.first;
        final nombre = actual.nombre;

        if (activos.length == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront,
                  size: compact ? 18 : 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    nombre,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return PopupMenuButton<int>(
          tooltip: 'Cambiar sucursal',
          onSelected: (id) {
            ref.read(almacenActivoIdProvider.notifier).setActivo(id);
          },
          itemBuilder: (ctx) => [
            for (final a in activos)
              PopupMenuItem<int>(
                value: a.id!,
                child: Row(
                  children: [
                    Icon(
                      a.id == actual.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.nombre)),
                    if (a.esPrincipal)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'Principal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront,
                  size: compact ? 18 : 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    nombre,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
