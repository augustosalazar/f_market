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

  /// La fase local no habla con ningun proveedor: la pantalla no pintara
  /// ningun boton social, que es la verdad aqui.
  @override
  Future<List<Map<String, dynamic>>> listProviders() async => const [];

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async =>
      throw StateError('Sin servidor no hay login con Google.');

  @override
  Future<Map<String, dynamic>> upgradeWithGoogle() async =>
      throw StateError('Sin servidor no hay login con Google.');

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
  Future<Map<String, dynamic>> signInAnonymously() async {
    await Future.delayed(_delay);
    final id = _data.nextId('u');
    final guest = <String, dynamic>{
      'userId': id,
      'name': 'Invitado',
      // La misma direccion inventada que pone el servidor: no existe y no se
      // muestra.
      'email': 'anon_$id@anonymous.invalid',
      'isAnonymous': true,
    };
    _data.users.add(guest);
    _data.session = guest;
    return guest;
  }

  @override
  Future<Map<String, dynamic>> upgradeAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    await Future.delayed(_delay);
    final guest = _data.session;
    if (guest == null || guest['isAnonymous'] != true) {
      throw StateError('Esta cuenta ya no es un invitado.');
    }
    final normalized = email.toLowerCase();
    if (_data.users.any(
      (u) => (u['email'] as String).toLowerCase() == normalized &&
          u['userId'] != guest['userId'],
    )) {
      throw StateError('Ya existe una cuenta con ese correo.');
    }
    // **Muta la fila que ya hay**, como el servidor: el `userId` no cambia, y
    // por eso lo que el invitado escribio sigue siendo suyo.
    guest['email'] = normalized;
    guest['name'] = (name?.trim().isNotEmpty ?? false) ? name!.trim() : guest['name'];
    guest['isAnonymous'] = false;
    _data.passwords[normalized] = password;
    return guest;
  }

  @override
  bool get isAnonymous => _data.session?['isAnonymous'] == true;

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
