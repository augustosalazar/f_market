import 'package:roble/roble.dart';

import 'package:f_roble_market/features/auth/data/datasources/i_auth_data_source.dart';
import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';

/// Sesion con correo y contrasena: decide y traduce, no habla.
///
/// El paquete guarda y refresca los tokens por su cuenta; aqui no se tocan.
class AuthRepository implements IAuthRepository {
  AuthRepository(this._source);

  final IAuthDataSource _source;

  @override
  Stream<void> get sessionExpired => _source.sessionExpired;

  @override
  Future<AppUser?> restoreSession() async {
    if (!await _source.restoreSession()) return null;
    return _guard(() async => _toUser(await _source.currentUser()));
  }

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () async => _toUser(await _source.login(email: email, password: password)),
  );

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    // `register` crea la cuenta pero no deja sesion abierta, y segun la
    // configuracion del proyecto puede no pedir verificacion por correo. Se
    // entra a continuacion para dejar al usuario dentro.
    await _source.register(name: name, email: email, password: password);
    return _toUser(await _source.login(email: email, password: password));
  });

  /// El servidor dice que proveedores tiene encendidos; la app solo sabe usar
  /// Google, asi que lo demas se ignora. Un fallo aqui no merece una pantalla
  /// rota: queda el login por correo, que es el camino de siempre.
  @override
  Future<bool> googleEnabled() async {
    try {
      final proveedores = await _source.listProviders();
      return proveedores.any((p) => p['name'] == 'google');
    } on RobleApiException {
      return false;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() =>
      _guard(() async => _toUser(await _source.signInWithGoogle()));

  @override
  Future<AppUser> signInAnonymously() => _guard(
    () async => _toUser(await _source.signInAnonymously()),
    // El paquete distingue las dos razones por las que un proyecto puede no
    // admitir invitados; para quien mira la pantalla son la misma cosa.
    siNoHayInvitados: true,
  );

  @override
  Future<AppUser> upgradeWithGoogle() => _guard(
    () async => _toUser(await _source.upgradeWithGoogle()),
    alEnlazar: true,
  );

  @override
  Future<AppUser> upgradeAccount({
    required String email,
    required String password,
    String? name,
  }) => _guard(
    () async => _toUser(
      await _source.upgradeAccount(
        email: email,
        password: password,
        name: name,
      ),
    ),
  );

  @override
  Future<void> logout() async {
    _source.currentUserId = null;
    await _source.logout();
  }

  AppUser _toUser(Map<String, dynamic> profile) {
    final user = AppUser(
      // El token es la fuente buena: tras ascender, el perfil del servidor ya
      // viene sin la marca, y el token se renueva en la misma llamada.
      isAnonymous: profile['isAnonymous'] == true || _source.isAnonymous,
      // `userId` es el del usuario, el que referencian las tablas; `id` es el
      // de la fila del perfil y no sirve para eso.
      userId: profile['userId'] as String,
      name: (profile['name'] as String?) ?? 'Sin nombre',
      email: (profile['email'] as String?) ?? '',
    );
    _source.currentUserId = user.userId;
    return user;
  }

  /// Aqui mueren las excepciones del paquete: la pantalla ve un `AuthFailure`
  /// con algo que se le puede enseñar a una persona.
  Future<AppUser> _guard(
    Future<AppUser> Function() action, {
    bool siNoHayInvitados = false,
    bool alEnlazar = false,
  }) async {
    try {
      return await action();
    } on RobleApiConflictException {
      // El mismo 409 significa dos cosas distintas, y confundirlas manda a
      // quien lo lee a arreglar lo que no es. Al enlazar: esa cuenta de Google
      // ya es de otro usuario. Al entrar: Google no certifico el correo y ese
      // correo ya tiene cuenta aqui. En los dos casos Roble no fusiona nada,
      // asi que reintentar no cambia nada.
      throw AuthFailure(
        alEnlazar
            ? 'Esa cuenta de Google ya esta en otro usuario de la app. Usa '
                  'otra, o guarda esta con tu correo y una contrasena.'
            : 'Ese correo ya tiene cuenta en la app. Entra con tu contrasena '
                  'para usarla.',
        code: AuthFailure.emailTaken,
      );
    } on RobleAnonUpgradeEmailTakenException {
      throw AuthFailure(
        'Ya hay una cuenta con ese correo. Si es tuya, entra con ella: lo que '
        'guardaste como invitado se queda en esta sesion.',
        code: AuthFailure.emailTaken,
      );
    } on RobleAnonymousAuthException catch (e) {
      // `ANON_AUTH_DISABLED` y `ANON_REQUIRES_ROW_OWNERSHIP` son las dos
      // mitades de la misma configuracion, y ninguna es culpa de quien entra.
      // Cual de las dos falta va detras, que es lo unico accionable.
      throw AuthFailure(
        'Entrar sin cuenta no esta disponible ahora mismo. (${e.message})',
        code: AuthFailure.guestsDisabled,
      );
    } on RobleApiHttpException catch (e) {
      // 429: el servidor limita las sesiones de invitado por IP, porque cada
      // una deja una fila permanente. No es que no se pueda: es que ahora no.
      if (siNoHayInvitados && e.statusCode == 429) {
        throw AuthFailure(
          'Demasiados invitados desde esta conexion. Espera un momento, o '
          'entra con tu cuenta.',
          code: AuthFailure.tooManyGuests,
        );
      }
      if (siNoHayInvitados) {
        // El mensaje del servidor viaja detras: sin el, un 404 —servidor sin
        // acceso anonimo— y un 429 —demasiadas sesiones— se leen igual, y el
        // motivo real no aparece en ningun sitio.
        throw AuthFailure(
          'Entrar sin cuenta no esta disponible ahora mismo. (${e.message})',
          code: AuthFailure.guestsDisabled,
        );
      }
      throw AuthFailure(e.message);
    } on RobleApiException catch (e) {
      if (siNoHayInvitados) {
        throw AuthFailure(
          'Entrar sin cuenta no esta disponible ahora mismo. (${e.message})',
          code: AuthFailure.guestsDisabled,
        );
      }
      throw AuthFailure(e.message);
    }
  }
}
