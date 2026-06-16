import '../models/negocio.dart';
// ✅ Importación simple, misma carpeta
import 'db_service.dart';

class NegocioService {
  final DbService _db = DbService();

  // Guardar o actualizar datos del negocio
  Future<int> guardarNegocio(Negocio negocio) async {
    final db = await _db.database;

    // Verificar si ya existe un registro (solo debe haber uno)
    List<Map<String, dynamic>> existente = await db.query('negocio');

    if (existente.isNotEmpty) {
      // Si existe, actualizar
      return await db.update(
        'negocio',
        negocio.toMap(),
        where: 'id = ?',
        whereArgs: [existente.first['id']],
      );
    } else {
      // Si no existe, insertar nuevo
      return await db.insert('negocio', negocio.toMap());
    }
  }

  // Obtener datos guardados
  Future<Negocio?> obtenerNegocio() async {
    final db = await _db.database;
    List<Map<String, dynamic>> resultado = await db.query('negocio');

    if (resultado.isNotEmpty) {
      return Negocio.fromMap(resultado.first);
    }
    return null; // No hay datos guardados
  }

  // Eliminar datos (poco usado, pero disponible)
  Future<int> eliminarNegocio(int id) async {
    final db = await _db.database;
    return await db.delete(
      'negocio',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}