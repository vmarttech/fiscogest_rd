import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let mensajero = engineBridge.applicationRegistrar.messenger()
      let canalIdentidad = FlutterMethodChannel(name: "fiscogest/device_identity", binaryMessenger: mensajero)
      canalIdentidad.setMethodCallHandler { call, result in
        guard call.method == "getStableDeviceId" else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          result(try DeviceIdentity.getOrCreate())
        } catch {
          result(FlutterError(code: "device_id_unavailable", message: error.localizedDescription, details: nil))
        }
      }
      let canal = FlutterMethodChannel(name: "fiscogest/pkcs12", binaryMessenger: mensajero)
      canal.setMethodCallHandler { call, result in
        guard call.method == "firmar",
              let args = call.arguments as? [String: Any],
              let ruta = args["ruta"] as? String,
              let clave = args["clave"] as? String,
              let datos = args["datos"] as? FlutterStandardTypedData else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          result(try Pkcs12Movil.firmar(ruta: ruta, clave: clave, datos: datos.data))
        } catch {
          result(FlutterError(code: "pkcs12", message: error.localizedDescription, details: nil))
        }
      }

  }
}


enum DeviceIdentity {
  private static let account = "fiscogest.device.identity.v1"

  static func getOrCreate() throws -> String {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Bundle.main.bundleIdentifier ?? "fiscogest",
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess,
       let data = item as? Data,
       let value = String(data: data, encoding: .utf8) {
      return value
    }
    guard status == errSecItemNotFound else {
      throw NSError(domain: "DeviceIdentity", code: Int(status), userInfo: [
        NSLocalizedDescriptionKey: "No se pudo leer la identidad segura del dispositivo.",
      ])
    }

    let value = UUID().uuidString
    query.removeValue(forKey: kSecReturnData as String)
    query.removeValue(forKey: kSecMatchLimit as String)
    query[kSecValueData as String] = Data(value.utf8)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let addStatus = SecItemAdd(query as CFDictionary, nil)
    if addStatus == errSecSuccess { return value }
    if addStatus == errSecDuplicateItem { return try getOrCreate() }
    throw NSError(domain: "DeviceIdentity", code: Int(addStatus), userInfo: [
      NSLocalizedDescriptionKey: "No se pudo guardar la identidad segura del dispositivo.",
    ])
  }
}

enum Pkcs12Movil {
  static func firmar(ruta: String, clave: String, datos: Data) throws -> [String: String] {
    let archivo = try Data(contentsOf: URL(fileURLWithPath: ruta))
    let opciones = [kSecImportExportPassphrase as String: clave] as CFDictionary
    var items: CFArray?
    let estado = SecPKCS12Import(archivo as CFData, opciones, &items)
    guard estado == errSecSuccess,
          let lista = items as? [[String: Any]],
          let primero = lista.first,
          let identidad = primero[kSecImportItemIdentity as String] as? SecIdentity else {
      throw NSError(domain: "Pkcs12", code: Int(estado), userInfo: [
        NSLocalizedDescriptionKey: "No se pudo abrir el .p12. Revisa la clave.",
      ])
    }
    var llave: SecKey?
    var certificado: SecCertificate?
    SecIdentityCopyPrivateKey(identidad, &llave)
    SecIdentityCopyCertificate(identidad, &certificado)
    guard let llave, let certificado else {
      throw NSError(domain: "Pkcs12", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "El .p12 no tiene llave privada",
      ])
    }
    var error: Unmanaged<CFError>?
    guard let firmado = SecKeyCreateSignature(llave, .rsaSignatureMessagePKCS1v15SHA256, datos as CFData, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    return [
      "certificado": (SecCertificateCopyData(certificado) as Data).base64EncodedString(),
      "firma": (firmado as Data).base64EncodedString(),
    ]
  }
}
