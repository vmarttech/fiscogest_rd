package com.fiscogest.fiscogest_rd
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fiscogest/pkcs12")
            .setMethodCallHandler { call, result ->
                if (call.method != "firmar") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val ruta = call.argument<String>("ruta") ?: ""
                    val clave = call.argument<String>("clave") ?: ""
                    val datos = call.argument<ByteArray>("datos") ?: ByteArray(0)
                    result.success(Pkcs12Movil.firmar(ruta, clave, datos))
                } catch (e: Exception) {
                    result.error("pkcs12", e.message, null)
                }
            }
    }
}
