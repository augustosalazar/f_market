import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';

/// Un repositorio falso: devuelve lo que la prueba le diga.
///
/// `Fake` deja escribir solo los metodos que se usan. Si el view model llamara
/// a otro, la prueba fallaria diciendo cual.
class FakeAuthRepository extends Fake implements IAuthRepository {
  AppUser? usuario;
  AuthFailure? fallo;
  int llamadas = 0;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    llamadas++;
    if (fallo != null) throw fallo!;
    return usuario!;
  }
}

const ana = AppUser(userId: 'u_ana', name: 'Ana Torres', email: 'ana@demo.com');

void main() {
  late FakeAuthRepository repositorio;
  late SessionViewModel viewModel;

  setUp(() {
    repositorio = FakeAuthRepository();
    viewModel = SessionViewModel(repositorio);
  });

  group('validaciones', () {
    test('un correo mal escrito no llega al repositorio', () async {
      final entro = await viewModel.login(email: 'ana', password: '123456');

      expect(entro, isFalse);
      expect(viewModel.error.value, 'Ese correo no parece valido.');
      expect(repositorio.llamadas, 0);
    });

    test('sin contrasena no llega al repositorio', () async {
      final entro = await viewModel.login(email: 'ana@demo.com', password: '');

      expect(entro, isFalse);
      expect(viewModel.error.value, 'Escribe tu contrasena.');
      expect(repositorio.llamadas, 0);
    });

    test('al registrarse, las contrasenas tienen que coincidir', () async {
      final entro = await viewModel.register(
        name: 'Ana Torres',
        email: 'ana@demo.com',
        password: '123456',
        confirmation: '654321',
      );

      expect(entro, isFalse);
      expect(viewModel.error.value, 'Las contrasenas no coinciden.');
    });
  });

  group('estado', () {
    test('entrar guarda al usuario y apaga la carga', () async {
      repositorio.usuario = ana;

      final entro = await viewModel.login(
        email: 'ana@demo.com',
        password: '123456',
      );

      expect(entro, isTrue);
      expect(viewModel.user.value, ana);
      expect(viewModel.busy.value, isFalse);
      expect(viewModel.error.value, isNull);
    });

    test('si el repositorio falla, se muestra su mensaje', () async {
      repositorio.fallo = AuthFailure('Correo o contrasena incorrectos.');

      final entro = await viewModel.login(
        email: 'ana@demo.com',
        password: 'mala',
      );

      expect(entro, isFalse);
      expect(viewModel.user.value, isNull);
      expect(viewModel.error.value, 'Correo o contrasena incorrectos.');
      expect(viewModel.busy.value, isFalse);
    });
  });

  group('invitados', () {
    test('un invitado tiene sesion pero no cuenta', () {
      viewModel.user.value = const AppUser(
        userId: 'u_invitado',
        name: 'Invitado',
        email: '',
        isAnonymous: true,
      );

      expect(viewModel.isLoggedIn, isTrue);
      expect(viewModel.isGuest, isTrue);
      expect(viewModel.hasAccount, isFalse);
    });
  });
}
