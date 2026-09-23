import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/features/auth/data/datasources/i_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';

/// El boton de Google sale de lo que diga el servidor, no de una constante en
/// la app: mientras el proyecto no lo tenga encendido, la pantalla no lo pinta
/// en vez de ofrecer algo que va a fallar.
class FuenteFalsa implements IAuthDataSource {
  FuenteFalsa({
    this.proveedores = const [],
    this.alEntrar,
    this.fallaAlListar = false,
  });

  final List<Map<String, dynamic>> proveedores;

  /// El servidor no contesta al preguntar por los proveedores.
  final bool fallaAlListar;

  /// Que pasa cuando alguien pulsa el boton.
  final Object? Function()? alEntrar;

  var entroConGoogle = false;
  var enlazoGoogle = false;

  @override
  Future<List<Map<String, dynamic>>> listProviders() async {
    if (fallaAlListar) {
      throw const RobleApiNetworkException('Sin conexion con el servidor.');
    }
    return proveedores;
  }

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    entroConGoogle = true;
    final resultado = alEntrar?.call();
    if (resultado is Exception) throw resultado;
    return {'userId': 'u_1', 'name': 'Quien Sea', 'email': 'q@ejemplo.test'};
  }

  /// Enlazar Google es lo que asciende a un invitado: el usuario es el mismo
  /// —mismo `userId`— pero ya sin la marca.
  @override
  Future<Map<String, dynamic>> upgradeWithGoogle() async {
    enlazoGoogle = true;
    final resultado = alEntrar?.call();
    if (resultado is Exception) throw resultado;
    return {
      'userId': 'invitado_1',
      'name': 'Quien Sea',
      'email': 'q@ejemplo.test',
      'isAnonymous': false,
    };
  }

  @override
  Future<bool> restoreSession() async => false;
  @override
  Future<Map<String, dynamic>> currentUser() async => const {};
  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async => const {};
  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {}
  @override
  Future<Map<String, dynamic>> signInAnonymously() async => const {};
  @override
  Future<Map<String, dynamic>> upgradeAccount({
    required String email,
    required String password,
    String? name,
  }) async => const {};
  @override
  bool get isAnonymous => false;
  @override
  Future<void> logout() async {}
  @override
  Stream<void> get sessionExpired => const Stream.empty();
  @override
  set currentUserId(String? value) {}
}

const _google = {
  'name': 'google',
  'displayName': 'Google',
  'autoLinkSupported': true,
};

void main() {
  test('con Google encendido, la pantalla lo ofrece', () async {
    final session = SessionViewModel(
      AuthRepository(FuenteFalsa(proveedores: const [_google])),
    );

    await session.loadProviders();

    expect(session.googleEnabled.value, isTrue);
  });

  test('sin Google encendido no se ofrece', () async {
    final session = SessionViewModel(AuthRepository(FuenteFalsa()));
    await session.loadProviders();
    expect(session.googleEnabled.value, isFalse);
  });

  test('otro proveedor encendido no cuenta como Google', () async {
    final session = SessionViewModel(
      AuthRepository(
        FuenteFalsa(
          proveedores: const [
            {'name': 'otro', 'displayName': 'Otro', 'autoLinkSupported': true},
          ],
        ),
      ),
    );

    await session.loadProviders();

    expect(session.googleEnabled.value, isFalse);
  });

  test('si el servidor no contesta, queda el login por correo', () async {
    final session = SessionViewModel(
      AuthRepository(FuenteFalsa(fallaAlListar: true)),
    );
    await session.loadProviders();
    expect(session.googleEnabled.value, isFalse);
  });

  test('entrar con Google deja la sesion abierta', () async {
    final fuente = FuenteFalsa(proveedores: const [_google]);
    final session = SessionViewModel(AuthRepository(fuente));

    expect(await session.signInWithGoogle(), isTrue);
    expect(fuente.entroConGoogle, isTrue);
    expect(session.hasAccount, isTrue);
  });

  test('un invitado guarda su cuenta con Google y deja de serlo', () async {
    final fuente = FuenteFalsa(proveedores: const [_google]);
    final session = SessionViewModel(AuthRepository(fuente));

    expect(await session.upgradeWithGoogle(), isTrue);
    expect(fuente.enlazoGoogle, isTrue);
    // El mismo usuario, ya con cuenta: es lo que conserva lo suyo.
    expect(session.requireUser.userId, 'invitado_1');
    expect(session.isGuest, isFalse);
    expect(session.hasAccount, isTrue);
  });

  test('si esa cuenta de Google ya es de otro, se dice', () async {
    final session = SessionViewModel(
      AuthRepository(
        FuenteFalsa(
          alEntrar: () => const RobleApiConflictException(
            'Esta cuenta de proveedor ya esta vinculada a otro usuario.',
          ),
        ),
      ),
    );

    expect(await session.upgradeWithGoogle(), isFalse);
    expect(session.error.value, contains('ya esta en otro usuario'));
    // Y no el mensaje del otro 409, que mandaria a escribir una contrasena
    // que aqui no arregla nada.
    expect(session.error.value, isNot(contains('Entra con tu contrasena')));
  });

  test('un correo que ya tiene cuenta no se une solo, y se explica', () async {
    final session = SessionViewModel(
      AuthRepository(
        FuenteFalsa(
          alEntrar: () =>
              const RobleApiConflictException('El correo ya esta registrado.'),
        ),
      ),
    );

    expect(await session.signInWithGoogle(), isFalse);
    expect(session.error.value, contains('ya tiene cuenta'));
  });
}
