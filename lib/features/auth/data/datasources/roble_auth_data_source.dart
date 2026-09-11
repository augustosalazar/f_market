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
