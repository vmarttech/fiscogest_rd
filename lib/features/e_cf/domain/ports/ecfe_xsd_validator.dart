class EcfeXsdResultado {
  const EcfeXsdResultado({required this.ok, this.errores = const []});
  final bool ok;
  final List<String> errores;
}

abstract class EcfeXsdValidator {
  Future<EcfeXsdResultado> validar(String xml);
}
