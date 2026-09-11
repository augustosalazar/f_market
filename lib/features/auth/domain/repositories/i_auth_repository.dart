import 'package:f_roble_market/features/auth/domain/models/app_user.dart';

/// El contrato de sesion. La implementacion de esta fase es local; la de la
/// siguiente delega en `RobleApiDataBase` sin que la UI cambie.
abstract class IAuthRepository {
  /// El usuario de la sesion guardada, o `null` si no hay ninguna.
  Future<AppUser?> restoreSession();

  /// Avisa cuando la sesion se cae sola, no cuando se cierra a proposito.
  ///
  /// Sin esto, una sesion caducada se descubre por el 401 de la siguiente
  /// pantalla que pida datos —tarde, y una pantalla cada vez—. Emite una sola
  /// vez por caida aunque fallen varias llamadas juntas.
  Stream<void> get sessionExpired;

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> logout();
}
