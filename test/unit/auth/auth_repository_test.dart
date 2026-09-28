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
  Map<String, dynamic> perfil = {};
  Object? error;
  List<Map<String, dynamic>> proveedores = [];

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return perfil;
  }

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (error != null) throw error!;
    return perfil;
  }

  @override
  Future<List<Map<String, dynamic>>> listProviders() async {
    if (error != null) throw error!;
    return proveedores;
  }

  // El repositorio los usa al convertir el perfil; aqui no importan.
  @override
  bool get isAnonymous => false;

  @override
  set currentUserId(String? value) {}
}

void main() {
  late FakeAuthDataSource fuente;
  late AuthRepository repositorio;

  setUp(() {
    fuente = FakeAuthDataSource();
    repositorio = AuthRepository(fuente);
  });

  group('convertir el perfil', () {
    test('la fila del servidor se vuelve un AppUser', () async {
      fuente.perfil = {
        'userId': 'u_ana',
        'name': 'Ana Torres',
        'email': 'ana@demo.com',
      };

      final usuario = await repositorio.loginWithEmail(
        email: 'ana@demo.com',
        password: '123456',
      );

      expect(usuario.userId, 'u_ana');
      expect(usuario.name, 'Ana Torres');
      expect(usuario.isAnonymous, isFalse);
    });

    test('un perfil sin nombre se muestra como «Sin nombre»', () async {
      fuente.perfil = {'userId': 'u_1', 'email': 'x@demo.com'};

      final usuario = await repositorio.loginWithEmail(
        email: 'x@demo.com',
        password: '123456',
      );

      expect(usuario.name, 'Sin nombre');
    });
  });

  group('traducir errores', () {
    test('un error del servidor llega como AuthFailure con su mensaje', () {
      fuente.error = const RobleApiHttpException(401, 'Credenciales invalidas');

      expect(
        repositorio.loginWithEmail(email: 'ana@demo.com', password: 'mala'),
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
      fuente.error = const RobleApiConflictException('Correo registrado');

      expect(
        repositorio.signInWithGoogle(),
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
      fuente.proveedores = [
        {'name': 'google', 'displayName': 'Google'},
      ];

      expect(await repositorio.googleEnabled(), isTrue);
    });

    test('si el servidor no contesta, no se ofrece', () async {
      fuente.error = const RobleApiNetworkException('Sin conexion');

      expect(await repositorio.googleEnabled(), isFalse);
    });
  });
}
