import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/repositories/operacion_repository.dart';
import 'package:fiscogestrd/providers/operacion_notifier.dart';

final operacionRepositoryProvider = Provider((ref) => OperacionRepository());

final operacionNotifierProvider =
    StateNotifierProvider<OperacionNotifier, Map<String, List>>((ref) {
  final repo = ref.watch(operacionRepositoryProvider);
  return OperacionNotifier(repo, ref);
});