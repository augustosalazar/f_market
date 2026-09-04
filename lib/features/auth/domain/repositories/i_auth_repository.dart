import 'package:f_roble_market/features/auth/domain/models/app_user.dart';

/// El contrato de sesion. La implementacion de esta fase es local; la de la
/// siguiente delega en `RobleApiDataBase` sin que la UI cambie.
abstract class IAuthRepository {
  /// El usuario de la sesion guardada, o `null` si no hay ninguna.
  Future<AppUser?> restoreSession();

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
