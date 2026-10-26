import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_auth_client.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

/// Caché en memoria del JWT por ambiente (evita pedir semilla en cada envío/consulta).
class DgiiTokenCache {
  DgiiTokenCache._();
  static final DgiiTokenCache instance = DgiiTokenCache._();

  final Map<String, DgiiToken> _byAmbiente = {};

  String _key(AmbienteDgii a) => a.name;

  DgiiToken? get(AmbienteDgii ambiente) {
    final t = _byAmbiente[_key(ambiente)];
    if (t == null) return null;
    final exp = t.expira;
    if (exp != null) {
      // margen 2 min
      if (DateTime.now().isAfter(exp.subtract(const Duration(minutes: 2)))) {
        _byAmbiente.remove(_key(ambiente));
        return null;
      }
    } else {
      // Sin expiración conocida, no reutilizar el token almacenado.
      _byAmbiente.remove(_key(ambiente));
      return null;
    }
    return t;
  }

  void put(AmbienteDgii ambiente, DgiiToken token) {
    // Solo cachear tokens cuya expiración se conoce.
    if (token.expira == null) {
      _byAmbiente.remove(_key(ambiente));
      return;
    }
    _byAmbiente[_key(ambiente)] = token;
  }

  void invalidate([AmbienteDgii? ambiente]) {
    if (ambiente == null) {
      _byAmbiente.clear();
    } else {
      _byAmbiente.remove(_key(ambiente));
    }
  }
}
