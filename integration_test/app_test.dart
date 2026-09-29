import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/di/local_bindings.dart';
import 'package:f_roble_market/features/auth/ui/pages/login_page.dart';
import 'package:f_roble_market/features/home/ui/pages/home_page.dart';
import 'package:f_roble_market/features/listings/ui/pages/my_listings_page.dart';
import 'package:f_roble_market/features/listings/ui/widgets/brand_strip.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';
import 'package:f_roble_market/main.dart';

/// La app entera —rutas, pantallas, view models y repositorios de verdad— con
/// una sola cosa cambiada: las fuentes de datos. `LocalBindings` le mete las de
/// memoria en vez de las de Roble, asi que esto prueba la app y no el servidor,
/// y corre sin red ni cuenta.
///
/// Corre en un dispositivo, no en la VM de `flutter test`:
///
/// ```bash
/// flutter test integration_test -d macos
/// flutter test integration_test -d emulator-5554
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(prepareApp);

  // GetX es estado global: sin esto, la sesion de una prueba se cuela en la
  // siguiente.
  tearDown(Get.reset);

  // Se toca y se recorre por clave; se comprueba por texto lo que la persona
  // lee en pantalla.

  Future<void> startApp(WidgetTester tester) async {
    await tester.pumpWidget(RobleMarketApp(bindings: LocalBindings()));
    await tester.waitFor(find.text('Chevrolet Onix Turbo 2023'));
  }

  Future<void> goToTab(WidgetTester tester, Key tab) async {
    await tester.tap(find.byKey(tab));
    await tester.pump();
  }

  testWidgets('un visitante ve el catalogo sin cuenta', (tester) async {
    await startApp(tester);

    expect(find.text('Chevrolet Onix Turbo 2023'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
  });

  testWidgets('tocar una marca filtra el catalogo', (tester) async {
    await startApp(tester);

    // Las marcas se cargan despues de las publicaciones: hay que esperarlas.
    // Renault es de las primeras de la tira: cabe en la pantalla de un
    // telefono sin desplazarla. Una marca del final no llegaria a construirse.
    final renaultChip = find.byKey(BrandStrip.chipKey('Renault'));
    await tester.waitFor(renaultChip);
    await tester.tap(renaultChip);

    // De las publicaciones de prueba, el unico Renault es el Duster, y el
    // Chevrolet que iba primero desaparece.
    await tester.waitFor(find.textContaining('Duster'));
    await tester.waitUntilGone(find.text('Chevrolet Onix Turbo 2023'));
  });

  testWidgets('entrar con la cuenta de demo', (tester) async {
    await startApp(tester);

    // «Lo mio» sin sesion ofrece entrar.
    await goToTab(tester, HomePage.mineTabKey);
    await tester.tap(find.byKey(MyListingsPage.signInButtonKey));
    // Mientras el login entra animado, «Lo mio» sigue a la vista, y un toque
    // en ese momento no llega al login. Se espera a que quede tapado.
    await tester.waitUntilGone(find.byKey(MyListingsPage.signInButtonKey));

    // El login viene precargado con la cuenta de demo de los datos falsos.
    expect(find.text(DummyData.demoEmail), findsOneWidget);
    await tester.tap(find.byKey(LoginPage.submitButtonKey));
    // Lo mismo al volver: si se toca la barra de abajo mientras el login se
    // cierra, el toque cae en el login.
    await tester.waitUntilGone(find.byKey(LoginPage.submitButtonKey));

    // De vuelta en la app, el perfil es el de Ana.
    await goToTab(tester, HomePage.profileTabKey);
    await tester.waitFor(find.text('Ana Torres'));
  });

  testWidgets('seguir sin cuenta abre una sesion de invitado', (tester) async {
    await startApp(tester);

    // Sin pasar por el login: seguir es el gesto de quien todavia mira.
    await tester.tap(find.byKey(ListingCard.followButtonKey).first);
    await tester.waitFor(find.byTooltip('Dejar de seguir'));
    expect(find.byKey(LoginPage.submitButtonKey), findsNothing);

    // Y lo seguido es suyo: aparece en «Lo mio», sin haber creado cuenta.
    await goToTab(tester, HomePage.mineTabKey);
    await tester.waitFor(find.byKey(MyListingsPage.followingTabKey));
    await tester.tap(find.byKey(MyListingsPage.followingTabKey));
    await tester.waitFor(find.text('Chevrolet Onix Turbo 2023'));
  });
}

extension on WidgetTester {
  /// Avanza hasta que [finder] ya no este en pantalla.
  Future<void> waitUntilGone(Finder finder) =>
      waitFor(finder, shouldBePresent: false);

  /// Avanza hasta que aparezca [finder].
  ///
  /// `pumpAndSettle` no sirve como espera general: los indicadores de carga
  /// giran sin parar y nunca «se asienta». Y las fuentes en memoria simulan
  /// latencia con `Future.delayed`, que en un dispositivo corre con reloj real.
  ///
  /// Y en un dispositivo `pump(duracion)` **no espera** esa duracion: solo
  /// pinta un frame. Por eso se mide el tiempo con el reloj de verdad.
  Future<void> waitFor(
    Finder finder, {
    bool shouldBePresent = true,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await pump();
      if (finder.evaluate().isNotEmpty == shouldBePresent) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TestFailure(
      shouldBePresent
          ? 'No aparecio a tiempo: $finder'
          : 'No se fue a tiempo: $finder',
    );
  }
}
