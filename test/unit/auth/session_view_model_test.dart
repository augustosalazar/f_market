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
  AppUser? userToReturn;
  AuthFailure? failureToThrow;
  int loginCalls = 0;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (failureToThrow != null) throw failureToThrow!;
    return userToReturn!;
  }
}

const ana = AppUser(userId: 'u_ana', name: 'Ana Torres', email: 'ana@demo.com');

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late SessionViewModel sessionViewModel;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    sessionViewModel = SessionViewModel(fakeAuthRepository);
  });

  group('validaciones', () {
    test('un correo mal escrito no llega al repositorio', () async {
      final signedIn = await sessionViewModel.login(
        email: 'ana',
        password: '123456',
      );

      expect(signedIn, isFalse);
      expect(sessionViewModel.error.value, 'Ese correo no parece valido.');
      expect(fakeAuthRepository.loginCalls, 0);
    });

    test('sin contrasena no llega al repositorio', () async {
      final signedIn = await sessionViewModel.login(
        email: 'ana@demo.com',
        password: '',
      );

      expect(signedIn, isFalse);
      expect(sessionViewModel.error.value, 'Escribe tu contrasena.');
      expect(fakeAuthRepository.loginCalls, 0);
    });

    test('al registrarse, las contrasenas tienen que coincidir', () async {
      final signedIn = await sessionViewModel.register(
        name: 'Ana Torres',
        email: 'ana@demo.com',
        password: '123456',
        confirmation: '654321',
      );

      expect(signedIn, isFalse);
      expect(sessionViewModel.error.value, 'Las contrasenas no coinciden.');
    });
  });

  group('estado', () {
    test('entrar guarda al usuario y apaga la carga', () async {
      fakeAuthRepository.userToReturn = ana;

      final signedIn = await sessionViewModel.login(
        email: 'ana@demo.com',
        password: '123456',
      );

      expect(signedIn, isTrue);
      expect(sessionViewModel.user.value, ana);
      expect(sessionViewModel.busy.value, isFalse);
      expect(sessionViewModel.error.value, isNull);
    });

    test('si el repositorio falla, se muestra su mensaje', () async {
      fakeAuthRepository.failureToThrow = AuthFailure(
        'Correo o contrasena incorrectos.',
      );

      final signedIn = await sessionViewModel.login(
        email: 'ana@demo.com',
        password: 'mala',
      );

      expect(signedIn, isFalse);
      expect(sessionViewModel.user.value, isNull);
      expect(sessionViewModel.error.value, 'Correo o contrasena incorrectos.');
      expect(sessionViewModel.busy.value, isFalse);
    });
  });

  group('invitados', () {
    test('un invitado tiene sesion pero no cuenta', () {
      sessionViewModel.user.value = const AppUser(
        userId: 'u_invitado',
        name: 'Invitado',
        email: '',
        isAnonymous: true,
      );

      expect(sessionViewModel.isLoggedIn, isTrue);
      expect(sessionViewModel.isGuest, isTrue);
      expect(sessionViewModel.hasAccount, isFalse);
    });
  });
}
