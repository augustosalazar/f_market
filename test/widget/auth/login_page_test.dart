import 'package:flutter/material.dart';
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
  bool conGoogle = false;
  AuthFailure? fallo;
  int llamadas = 0;

  // `Get.put` arranca el view model (`onInit`), y lo primero que hace es
  // escuchar si la sesion caduca. Aqui nunca caduca.
  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  Future<bool> googleEnabled() async => conGoogle;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    llamadas++;
    throw fallo ?? AuthFailure('Esta prueba no deja entrar.');
  }
}

void main() {
  late FakeAuthRepository repositorio;

  setUp(() {
    repositorio = FakeAuthRepository();
    // La pantalla busca su view model con `Get.find`, asi que se registra
    // antes de pintarla.
    Get.put(SessionViewModel(repositorio));
  });

  tearDown(Get.reset);

  Future<void> abrirLogin(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    // Un frame mas para que llegue la respuesta de `googleEnabled`.
    await tester.pump();
  }

  Finder campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

  testWidgets('un correo mal escrito se ve como error', (tester) async {
    await abrirLogin(tester);

    await tester.enterText(campo('Correo'), 'ana');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Ese correo no parece valido.'), findsOneWidget);
    expect(repositorio.llamadas, 0);
  });

  testWidgets('el error del repositorio se ve en pantalla', (tester) async {
    repositorio.fallo = AuthFailure('Correo o contrasena incorrectos.');
    await abrirLogin(tester);

    await tester.enterText(campo('Correo'), 'ana@demo.com');
    await tester.enterText(campo('Contrasena'), 'mala');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Correo o contrasena incorrectos.'), findsOneWidget);
    expect(repositorio.llamadas, 1);
  });

  testWidgets('sin Google encendido no hay boton de Google', (tester) async {
    repositorio.conGoogle = false;

    await abrirLogin(tester);

    expect(find.text('Continuar con Google'), findsNothing);
  });

  testWidgets('con Google encendido aparece su boton', (tester) async {
    repositorio.conGoogle = true;

    await abrirLogin(tester);

    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
