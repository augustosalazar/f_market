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
}
