import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/core/data/dummy_data.dart';

/// Sesion contra la fuente local. Simula la latencia de red para que los
/// estados de carga de la UI se puedan ver de verdad.
class LocalAuthRepository implements IAuthRepository {
  LocalAuthRepository(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 600);

  @override
  Future<AppUser?> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _data.session;
  }

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final normalized = email.toLowerCase();
    final user = _data.users
        .where((u) => u.email.toLowerCase() == normalized)
        .firstOrNull;
    if (user == null || _data.passwords[user.email] != password) {
      throw AuthFailure('Correo o contrasena incorrectos.');
    }
    _data.session = user;
    return user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final normalized = email.toLowerCase();
    if (_data.users.any((u) => u.email.toLowerCase() == normalized)) {
      throw AuthFailure('Ya existe una cuenta con ese correo.');
    }
    final user = AppUser(
      userId: _data.nextId('u'),
      name: name,
      email: normalized,
    );
    _data.users.add(user);
    _data.passwords[user.email] = password;
    _data.session = user;
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(_delay);
    // En la fase 1 no hay proveedor real: se entra como el usuario de demo
    // para poder recorrer los flujos que exigen sesion.
    final user = _data.users.firstWhere(
      (u) => u.email == DummyData.demoEmail,
    );
    _data.session = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _data.session = null;
  }
}
