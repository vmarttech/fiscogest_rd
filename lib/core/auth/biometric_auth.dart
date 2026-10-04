import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  static final _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      if (kIsWeb) return false;
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({
    String reason = 'Confirme su identidad para entrar a FiscoGest RD',
  }) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (e) {
      debugPrint('BiometricAuth: $e');
      return false;
    }
  }
}
