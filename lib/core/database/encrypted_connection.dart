import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Apertura de BD para desarrollo / Linux offline.
/// Producción Android: reactivar sqlcipher_flutter_libs y la variante cifrada.
LazyDatabase openEncryptedConnection({
  String plainName = 'fiscogest_rd.sqlite',
  String encryptedName = 'fiscogest_rd.enc.sqlite',
}) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final plain = File(p.join(dir.path, plainName));
    return NativeDatabase.createInBackground(plain);
  });
}
