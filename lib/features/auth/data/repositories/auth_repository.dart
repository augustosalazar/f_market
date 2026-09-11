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

  @override
  Future<AppUser> signInWithGoogle() async {
    throw AuthFailure(
      'El login con Google todavia no esta configurado en este proyecto.',
    );
  }

  @override
  Future<void> logout() async {
    _source.currentUserId = null;
    await _source.logout();
  }

  AppUser _toUser(Map<String, dynamic> profile) {
    final user = AppUser(
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
  Future<AppUser> _guard(Future<AppUser> Function() action) async {
    try {
      return await action();
    } on RobleApiException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
