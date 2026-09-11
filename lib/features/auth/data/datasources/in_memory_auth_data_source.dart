import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/i_auth_data_source.dart';

/// Cuentas en memoria. La sesion no sobrevive a cerrar la app, asi que
/// `restoreSession` solo encuentra algo dentro de la misma corrida.
class InMemoryAuthDataSource implements IAuthDataSource {
  InMemoryAuthDataSource(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 400);

  @override
  Future<bool> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _data.session != null;
  }

  @override
  Future<Map<String, dynamic>> currentUser() async {
    final session = _data.session;
    if (session == null) throw StateError('No hay sesion');
    return session;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final normalized = email.toLowerCase();
    final user = _data.users
        .where((u) => (u['email'] as String).toLowerCase() == normalized)
        .firstOrNull;
    if (user == null || _data.passwords[user['email']] != password) {
      // El mismo mensaje que da el servidor: el repositorio lo traduce igual.
      throw StateError('Correo o contrasena incorrectos.');
    }
    _data.session = user;
    return user;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);
    final normalized = email.toLowerCase();
    if (_data.users.any((u) => (u['email'] as String).toLowerCase() == normalized)) {
      throw StateError('Ya existe una cuenta con ese correo.');
    }
    _data.users.add({
      'userId': _data.nextId('u'),
      'name': name,
      'email': normalized,
    });
    _data.passwords[normalized] = password;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _data.session = null;
  }

  // Una sesion en memoria no caduca sola: nunca emite.
  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  set currentUserId(String? value) {}
}
