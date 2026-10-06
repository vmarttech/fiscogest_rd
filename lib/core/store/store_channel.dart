/// Canal de distribución de la app (licencia de *software*, no cobro POS).
///
/// Build:
///   flutter run / build --dart-define=STORE=direct   # PC / APK propio (Toke, bancos)
///   flutter build appbundle --dart-define=STORE=play
///   flutter build apk --dart-define=STORE=samsung
library;

enum StoreChannel {
  /// Pedido + transferencia / Toke (fuera de tiendas).
  direct,

  /// Google Play: sin checkout por transferencia en la app.
  play,

  /// Galaxy Store: mismo criterio que Play (activar código; IAP después).
  samsung,
}

StoreChannel get storeChannel {
  const raw = String.fromEnvironment('STORE', defaultValue: 'direct');
  switch (raw.toLowerCase().trim()) {
    case 'play':
      return StoreChannel.play;
    case 'samsung':
      return StoreChannel.samsung;
    default:
      return StoreChannel.direct;
  }
}

/// En Play / Samsung no se muestra el flujo "paga por Toke/banco".
bool get storeOcultaCompraTransferencia =>
    storeChannel == StoreChannel.play || storeChannel == StoreChannel.samsung;

/// Builds pensados para revisión de tiendas.
bool get storeEsTiendaOficial => storeOcultaCompraTransferencia;
