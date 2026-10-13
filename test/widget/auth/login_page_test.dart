import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/pages/login_page.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';

/// Una pantalla con su view model de verdad, y un repositorio falso debajo.
///
/// La prueba unitaria del view model ya sabe que produce los errores. Esta
/// comprueba lo que solo se ve en pantalla: que se pintan, y que los botones
/// aparecen cuando deben.
class FakeAuthRepository extends Fake implements IAuthRepository {
  bool isGoogleEnabled = false;
  AuthFailure? failureToThrow;
  int loginCalls = 0;

  // `Get.put` arranca el view model (`onInit`), y lo primero que hace es
  // escuchar si la sesion caduca. Aqui nunca caduca.
  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  Future<bool> googleEnabled() async => isGoogleEnabled;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    throw failureToThrow ?? AuthFailure('Esta prueba no deja entrar.');
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    // La pantalla busca su view model con `Get.find`, asi que se registra
    // antes de pintarla.
    Get.put(SessionViewModel(fakeAuthRepository));
  });

  tearDown(Get.reset);

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    // Un frame mas para que llegue la respuesta de `googleEnabled`.
    await tester.pump();
  }

  testWidgets('un correo mal escrito se ve como error', (tester) async {
    await openLogin(tester);

    await tester.enterText(find.byKey(LoginPage.emailFieldKey), 'ana');
    await tester.tap(find.byKey(LoginPage.submitButtonKey));
    await tester.pump();

    expect(find.text('Ese correo no parece valido.'), findsOneWidget);
    expect(fakeAuthRepository.loginCalls, 0);
  });

  testWidgets('el error del repositorio se ve en pantalla', (tester) async {
    fakeAuthRepository.failureToThrow = AuthFailure(
      'Correo o contrasena incorrectos.',
    );
    await openLogin(tester);

    await tester.enterText(find.byKey(LoginPage.emailFieldKey), 'ana@demo.com');
    await tester.enterText(find.byKey(LoginPage.passwordFieldKey), 'mala');
    await tester.tap(find.byKey(LoginPage.submitButtonKey));
    await tester.pump();

    expect(find.text('Correo o contrasena incorrectos.'), findsOneWidget);
    expect(fakeAuthRepository.loginCalls, 1);
  });

  testWidgets('sin Google encendido no hay boton de Google', (tester) async {
    fakeAuthRepository.isGoogleEnabled = false;

    await openLogin(tester);

    expect(find.byKey(LoginPage.googleButtonKey), findsNothing);
  });

  testWidgets('con Google encendido aparece su boton', (tester) async {
    fakeAuthRepository.isGoogleEnabled = true;

    await openLogin(tester);

    expect(find.byKey(LoginPage.googleButtonKey), findsOneWidget);
  });
}
