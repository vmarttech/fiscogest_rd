// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class SchemaVersion {
  final int version;
  final List<TableInfo<Table, dynamic>> entities;
  final Map<String, Object?> options;

  const SchemaVersion({
    required this.version,
    required this.entities,
    this.options = const {},
  });
}

class Schema extends SchemaVersion {
  const Schema({
    required int version,
    required List<TableInfo<Table, dynamic>> entities,
    Map<String, Object?> options = const {},
  }) : super(version: version, entities: entities, options: options);

  static const List<int> versions = <int>[];

  static MigrationStrategy create() {
    throw UnimplementedError();
  }

  static MigrationStrategy migrate(int from, int to) {
    throw UnimplementedError();
  }
}
