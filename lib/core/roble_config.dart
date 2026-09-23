/// A que proyecto de Roble apunta la app.
///
/// El `contractId` no es un secreto —identifica el proyecto, no da acceso—,
/// asi que puede ir en el repositorio. Se puede apuntar a otro proyecto sin
/// tocar el codigo:
///
/// ```bash
/// flutter run --dart-define=ROBLE_CONTRACT_ID=otro_proyecto
/// ```
abstract class RobleConfig {
  static const baseUrl = String.fromEnvironment(
    'ROBLE_BASE_URL',
    defaultValue: 'https://roble-api.test-openlab.uninorte.edu.co',
  );

  static const contractId = String.fromEnvironment(
    'ROBLE_CONTRACT_ID',
    defaultValue: 'market_46aeeeed04',
  );

  /// El **nombre** del destino de retorno del login social, no una URL: la URL
  /// vive en la consola de Roble, y asi cada build elige cual usa sin tocar
  /// codigo. Si el nombre no esta registrado alli, el proveedor devuelve
  /// «state invalido».
  ///
  /// Hay uno por entorno porque en web el destino incluye el puerto:
  /// `--dart-define=ROBLE_SSO_REDIRECT=market-web-dev` para `flutter run`.
  static const ssoRedirect = String.fromEnvironment(
    'ROBLE_SSO_REDIRECT',
    defaultValue: 'market-web',
  );

  /// El destino al que vuelve el **enlace** de una cuenta de invitado con
  /// Google. Es otro distinto del de entrar: aqui el retorno lo recoge
  /// `web/auth.html`, y alli la ventana emergente del paquete.
  ///
  /// Registralo en la consola apuntando a `<tu origen>/auth.html`.
  static const webLinkRedirect = String.fromEnvironment(
    'ROBLE_SSO_REDIRECT_ENLACE',
    defaultValue: 'market-web-link',
  );

  /// Fuera de web el retorno vuelve por el esquema propio de la app, el mismo
  /// que esta declarado en `AndroidManifest.xml` y en `Info.plist`. Cambiarlo
  /// aqui sin cambiarlo alli deja el enlace colgado esperando un retorno que
  /// no llega. En la consola apunta a `roblemarket://sso-done`.
  static const mobileSsoRedirect = String.fromEnvironment(
    'ROBLE_SSO_REDIRECT_MOVIL',
    defaultValue: 'market-movil',
  );

  static const mobileCallbackScheme = 'roblemarket';

  /// Client ID de iOS de Google, lo unico del login social que sigue en manos
  /// de la app: es por plataforma, asi que Roble no lo guarda. En Android no
  /// hace falta —alli el SDK lo resuelve por la firma del paquete— y en web
  /// tampoco, porque no se usa el selector nativo.
  ///
  /// Vacio significa «no configurado»: en iOS el selector nativo no saldra.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
