import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
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

  /// Si el proyecto tiene Google encendido.
  ///
  /// Responde `false` tambien cuando no se pudo preguntar: la pantalla ofrece
  /// entonces solo correo y contrasena, que es mejor que un boton que siempre
  /// va a fallar. No es un error que merezca interrumpir el login.
  Future<bool> googleEnabled();

  /// Entra con Google. Solo tiene sentido si [availableProviders] lo trae.
  Future<AppUser> signInWithGoogle();

  /// Entra como invitado: sin correo ni clave, pero con `userId` propio, asi
  /// que lo que escriba queda a su nombre y se conserva si luego se registra.
  Future<AppUser> signInAnonymously();

  /// Asciende al invitado enlazando su cuenta de Google, conservando todo lo
  /// suyo: el `userId` no cambia.
  ///
  /// Lanza `AuthFailure` con `code` [AuthFailure.emailTaken] si esa cuenta de
  /// Google ya pertenece a otro usuario: Roble no fusiona dos cuentas.
  Future<AppUser> upgradeWithGoogle();

  /// Asciende al invitado a una cuenta conservando todo lo suyo.
  ///
  /// Lanza `AuthFailure` con `code` [AuthFailure.emailTaken] si ese correo ya
  /// tiene cuenta: Roble no fusiona dos cuentas, asi que no hay nada que
  /// reintentar.
  Future<AppUser> upgradeAccount({
    required String email,
    required String password,
    String? name,
  });

  Future<void> logout();
}
