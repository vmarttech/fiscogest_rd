package com.fiscogest.fiscogest_rd

import android.util.Base64
import java.io.File
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.cert.X509Certificate

object Pkcs12Movil {
    fun firmar(ruta: String, clave: String, datos: ByteArray): Map<String, String> {
        val store = KeyStore.getInstance("PKCS12")
        File(ruta).inputStream().use { store.load(it, clave.toCharArray()) }
        val aliases = store.aliases()
        var alias: String? = null
        while (aliases.hasMoreElements()) {
            val item = aliases.nextElement()
            if (store.isKeyEntry(item)) {
                alias = item
                break
            }
        }
        if (alias == null) throw IllegalStateException("El .p12 no tiene llave privada")
        val key = store.getKey(alias, clave.toCharArray()) as PrivateKey
        val cert = store.getCertificate(alias) as X509Certificate
        val firma = Signature.getInstance("SHA256withRSA")
        firma.initSign(key)
        firma.update(datos)
        return mapOf(
            "certificado" to Base64.encodeToString(cert.encoded, Base64.NO_WRAP),
            "firma" to Base64.encodeToString(firma.sign(), Base64.NO_WRAP),
        )
    }
}
