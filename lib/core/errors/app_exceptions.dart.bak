// Excepciones personalizadas para el núcleo de la aplicación
abstract class AppException implements Exception {

  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code = 'DB_ERROR'});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code = 'VALIDATION_ERROR'});
}

class BusinessRuleException extends AppException {
  const BusinessRuleException(super.message, {super.code = 'BUSINESS_RULE_ERROR'});
}
