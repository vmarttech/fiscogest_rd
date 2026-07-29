[1mdiff --git a/lib/features/inventario/domain/entities/kardex.freezed.dart b/lib/features/inventario/domain/entities/kardex.freezed.dart[m
[1mindex 1c4fcbe..53415af 100644[m
[1m--- a/lib/features/inventario/domain/entities/kardex.freezed.dart[m
[1m+++ b/lib/features/inventario/domain/entities/kardex.freezed.dart[m
[36m@@ -1,5 +1,4 @@[m
 // coverage:ignore-file[m
[31m-import "package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart";[m
 // GENERATED CODE - DO NOT MODIFY BY HAND[m
 // ignore_for_file: type=lint[m
 // ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark[m
[1mdiff --git a/lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart.bak b/lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart.bak[m
[1mdeleted file mode 100644[m
[1mindex 0ca2bbf..0000000[m
[1m--- a/lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart.bak[m
[1m+++ /dev/null[m
[36m@@ -1,40 +0,0 @@[m
[31m-import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';[m
[31m-import "package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart";[m
[31m-import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';[m
[31m-[m
[31m-class RegistrarMovimientoKardex {[m
[31m-[m
[31m-  RegistrarMovimientoKardex(this._repo);[m
[31m-  final IKardexRepository _repo;[m
[31m-[m
[31m-  Future<void> ejecutar({[m
[31m-    required int productoId,[m
[31m-    required TipoMovimiento tipoMovimiento,[m
[31m-    required double cantidad,[m
[31m-    required double saldoAnterior,[m
[31m-    required double saldoNuevo,[m
[31m-    required double costoUnitario,[m
[31m-    required double totalMovimiento,[m
[31m-    DateTime? fechaMovimiento,[m
[31m-    String? documentoReferencia,[m
[31m-    String? observacion,[m
[31m-    required int usuarioId, // ✅ PARÁMETRO AGREGADO[m
[31m-  }) async {[m
[31m-    final movimiento = Kardex([m
[31m-      id: null,[m
[31m-      productoId: productoId,[m
[31m-      tipoMovimiento: tipoMovimiento,[m
[31m-      cantidad: cantidad,[m
[31m-      saldoAnterior: saldoAnterior,[m
[31m-      saldoNuevo: saldoNuevo,[m
[31m-      costoUnitario: costoUnitario,[m
[31m-      totalMovimiento: totalMovimiento,[m
[31m-      fechaMovimiento: fechaMovimiento ?? DateTime.now(),[m
[31m-      documentoReferencia: documentoReferencia,[m
[31m-      observacion: observacion,[m
[31m-      usuarioId: usuarioId, // ✅ CAMPO OBLIGATORIO[m
[31m-    );[m
[31m-[m
[31m-    await _repo.registrarMovimiento(movimiento);[m
[31m-  }[m
[31m-}[m
