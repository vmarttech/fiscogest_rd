// Registro de repositorios para la inyección de dependencias
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_existencia_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/existencia_repository_impl.dart';

class RepositoryInjection {
  // Almacenamos instancia para uso global, elimina variable sin usar
  static IExistenciaRepository? existenciaRepository;

  static void register(AppDatabase db) {
    // ===== REPOSITORIO EXISTENCIAS - ETAPA 3.1 FINALIZADA =====
    existenciaRepository = ExistenciaRepositoryImpl(db);

    // ===== AQUÍ SE AGREGARÁN PRÓXIMOS REPOSITORIOS EN ORDEN DEL PLAN =====
    // Ejemplo estructura a seguir:
    // static IEntradaRepository? entradaRepository;
    // entradaRepository = EntradaRepositoryImpl(db);
  }
}
