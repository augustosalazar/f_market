/// Lo que la feature necesita que alguien sepa hablar sobre cuentas.
///
/// Devuelve el perfil como llega —el `Map` del servidor— y no `AppUser`:
/// convertirlo es del repositorio.
abstract class IAuthDataSource {
  /// `true` si habia una sesion guardada viva.
  Future<bool> restoreSession();

  Future<Map<String, dynamic>> currentUser();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Los proveedores de identidad encendidos en el proyecto, tal como los
  /// devuelve el servidor. No pide sesion.
  Future<List<Map<String, dynamic>>> listProviders();

  /// Abre Google y, al volver, deja la sesion abierta. Devuelve el perfil,
  /// igual que [login].
  Future<Map<String, dynamic>> signInWithGoogle();

  /// Abre una sesion de invitado: un usuario real, sin correo ni clave.
  Future<Map<String, dynamic>> signInAnonymously();

  /// Convierte al invitado de esta sesion en una cuenta enlazando Google,
  /// conservando su `userId`. Devuelve el perfil ya ascendido.
  Future<Map<String, dynamic>> upgradeWithGoogle();

  /// Convierte al invitado de esta sesion en una cuenta, **conservando su
  /// `userId`** y por tanto todo lo que escribio.
  Future<Map<String, dynamic>> upgradeAccount({
    required String email,
    required String password,
    String? name,
  });

  /// Si quien tiene la sesion abierta es un invitado.
  bool get isAnonymous;

  Future<void> logout();

  /// Avisa cuando la sesion se cae sola. No emite al cerrarla a proposito.
  Stream<void> get sessionExpired;

  /// El `userId` de la sesion, que otras features leen para saber quien mira.
  set currentUserId(String? value);
}
