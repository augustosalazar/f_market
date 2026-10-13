import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/auth/data/datasources/i_auth_data_source.dart';


/// Habla con Roble sobre cuentas. No decide nada.
///
/// Devuelve el perfil como llega —el `Map` del servidor— y deja subir las
/// excepciones del paquete: convertirlo en `AppUser` y traducir los fallos es
/// del repositorio.
class RobleAuthDataSource implements IAuthDataSource {
  RobleAuthDataSource(this._client);

  final RobleClient _client;

  /// `true` si habia una sesion guardada viva.
  @override
  Future<bool> restoreSession() => _client.db.restoreSession();

  @override
  Future<Map<String, dynamic>> currentUser() => _client.db.currentUser();

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _client.db.login(email: email, password: password);

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _client.db.register(email: email, password: password, name: name);

  /// Una sola llamada devuelve los proveedores activos, asi que anadir uno en
  /// la consola no obliga a tocar la app.
  @override
  Future<List<Map<String, dynamic>>> listProviders() async {
    final proveedores = await _client.db.listProviders();
    return [
      for (final p in proveedores)
        {
          'name': p.name,
          'displayName': p.displayName,
          'autoLinkSupported': p.autoLinkSupported,
        },
    ];
  }

  /// El paquete elige el camino segun la plataforma: en movil el selector
  /// nativo de Google, sin navegador ni retorno que enrutar; en web, una
  /// ventana emergente.
  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    await _client.db.signInWithGoogle();
    // El perfil no viene con los tokens: se pide aparte, igual que en `login`.
    return _client.db.currentUser();
  }

  @override
  Future<Map<String, dynamic>> signInAnonymously() async {
    await _client.db.signInAnonymously();
    // El perfil no viene con los tokens: se pide aparte, igual que en `login`.
    return _client.db.currentUser();
  }

  @override
  Future<Map<String, dynamic>> upgradeWithGoogle() async {
    await _client.linkGoogle();
    return _client.db.currentUser();
  }

  @override
  Future<Map<String, dynamic>> upgradeAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    // `verify: false` a proposito: el proyecto no tiene correo saliente, y
    // dejar la cuenta esperando un codigo que no llega la deja inservible.
    await _client.db.upgradeAccount(
      email: email,
      password: password,
      name: name,
    );
    return _client.db.currentUser();
  }

  @override
  bool get isAnonymous => _client.db.isAnonymous;

  @override
  Future<void> logout() => _client.db.logout();

  /// Avisa cuando la sesion se cae sola. No emite en `logout()`.
  @override
  Stream<void> get sessionExpired => _client.db.onSessionExpired;

  /// El cliente cachea el `userId` de la sesion porque varias lecturas
  /// dependen de quien mira y `currentUser()` es un viaje al servidor.
  @override
  set currentUserId(String? value) => _client.currentUserId = value;
}
