import 'package:flutter_test/flutter_test.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/features/auth/data/datasources/i_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/domain/auth_failure.dart';

/// Una fuente de datos falsa: devuelve la fila que la prueba le diga, o lanza
/// el error que la prueba le diga. No sale a la red.
///
/// Se importa `package:roble` solo por sus excepciones: el trabajo del
/// repositorio es traducirlas, y para probarlo hay que lanzar una.
class FakeAuthDataSource extends Fake implements IAuthDataSource {
  Map<String, dynamic> profileToReturn = {};
  Object? errorToThrow;
  List<Map<String, dynamic>> providersToReturn = [];

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return profileToReturn;
  }

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (errorToThrow != null) throw errorToThrow!;
    return profileToReturn;
  }

  @override
  Future<List<Map<String, dynamic>>> listProviders() async {
    if (errorToThrow != null) throw errorToThrow!;
    return providersToReturn;
  }

  // El repositorio los usa al convertir el perfil; aqui no importan.
  @override
  bool get isAnonymous => false;

  @override
  set currentUserId(String? value) {}
}

void main() {
  late FakeAuthDataSource fakeAuthDataSource;
  late AuthRepository authRepository;

  setUp(() {
    fakeAuthDataSource = FakeAuthDataSource();
    authRepository = AuthRepository(fakeAuthDataSource);
  });

  group('convertir el perfil', () {
    test('la fila del servidor se vuelve un AppUser', () async {
      fakeAuthDataSource.profileToReturn = {
        'userId': 'u_ana',
        'name': 'Ana Torres',
        'email': 'ana@demo.com',
      };

      final user = await authRepository.loginWithEmail(
        email: 'ana@demo.com',
        password: '123456',
      );

      expect(user.userId, 'u_ana');
      expect(user.name, 'Ana Torres');
      expect(user.isAnonymous, isFalse);
    });

    test('un perfil sin nombre se muestra como «Sin nombre»', () async {
      fakeAuthDataSource.profileToReturn = {
        'userId': 'u_1',
        'email': 'x@demo.com',
      };

      final user = await authRepository.loginWithEmail(
        email: 'x@demo.com',
        password: '123456',
      );

      expect(user.name, 'Sin nombre');
    });
  });

  group('traducir errores', () {
    test('un error del servidor llega como AuthFailure con su mensaje', () {
      fakeAuthDataSource.errorToThrow = const RobleApiHttpException(
        401,
        'Credenciales invalidas',
      );

      expect(
        authRepository.loginWithEmail(email: 'ana@demo.com', password: 'mala'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            'Credenciales invalidas',
          ),
        ),
      );
    });

    test('un 409 con Google dice que el correo ya tiene cuenta', () {
      fakeAuthDataSource.errorToThrow = const RobleApiConflictException(
        'Correo registrado',
      );

      expect(
        authRepository.signInWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.emailTaken,
          ),
        ),
      );
    });
  });

  group('Google', () {
    test('esta disponible si el servidor lo tiene encendido', () async {
      fakeAuthDataSource.providersToReturn = [
        {'name': 'google', 'displayName': 'Google'},
      ];

      expect(await authRepository.googleEnabled(), isTrue);
    });

    test('si el servidor no contesta, no se ofrece', () async {
      fakeAuthDataSource.errorToThrow = const RobleApiNetworkException(
        'Sin conexion',
      );

      expect(await authRepository.googleEnabled(), isFalse);
    });
  });
}
