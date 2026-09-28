import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/di/local_bindings.dart';
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

  Future<void> arrancar(WidgetTester tester) async {
    await tester.pumpWidget(RobleMarketApp(bindings: LocalBindings()));
    await tester.esperar(find.text('Chevrolet Onix Turbo 2023'));
  }

  Future<void> irA(WidgetTester tester, String pestana) async {
    await tester.tap(find.widgetWithText(NavigationDestination, pestana));
    await tester.pump();
  }

  testWidgets('un visitante ve el catalogo sin cuenta', (tester) async {
    await arrancar(tester);

    expect(find.text('Chevrolet Onix Turbo 2023'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
  });

  testWidgets('tocar una marca filtra el catalogo', (tester) async {
    await arrancar(tester);

    // Las marcas se cargan despues de las publicaciones: hay que esperarlas.
    // Renault es de las primeras de la tira: cabe en la pantalla de un
    // telefono sin desplazarla. Una marca del final no llegaria a construirse.
    final renault = find.widgetWithText(ChoiceChip, 'Renault');
    await tester.esperar(renault);
    await tester.tap(renault);

    // De las publicaciones de prueba, el unico Renault es el Duster, y el
    // Chevrolet que iba primero desaparece.
    await tester.esperar(find.textContaining('Duster'));
    await tester.esperarQueSeVaya(find.text('Chevrolet Onix Turbo 2023'));
  });

  testWidgets('entrar con la cuenta de demo', (tester) async {
    await arrancar(tester);

    // «Lo mio» sin sesion ofrece entrar.
    await irA(tester, 'Lo mio');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    // Mientras el login entra animado, «Lo mio» sigue a la vista con su propio
    // boton «Entrar». Hay que esperar a que se tape antes de tocar otra vez.
    await tester.esperarQueSeVaya(find.text('Entra para ver lo tuyo'));

    // El login viene precargado con la cuenta de demo de los datos falsos.
    expect(find.text(DummyData.demoEmail), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    // Lo mismo al volver: si se toca la barra de abajo mientras el login se
    // cierra, el toque cae en el login.
    await tester.esperarQueSeVaya(
      find.text('Entra para publicar, preguntar y chatear.'),
    );

    // De vuelta en la app, el perfil es el de Ana.
    await irA(tester, 'Perfil');
    await tester.esperar(find.text('Ana Torres'));
  });

  testWidgets('seguir sin cuenta abre una sesion de invitado', (tester) async {
    await arrancar(tester);

    // Sin pasar por el login: seguir es el gesto de quien todavia mira.
    await tester.tap(find.byTooltip('Seguir y recibir avisos').first);
    await tester.esperar(find.byTooltip('Dejar de seguir'));
    expect(find.text('Entra para publicar, preguntar y chatear.'), findsNothing);

    // Y lo seguido es suyo: aparece en «Lo mio», sin haber creado cuenta.
    await irA(tester, 'Lo mio');
    await tester.esperar(find.text('Siguiendo'));
    await tester.tap(find.text('Siguiendo'));
    await tester.esperar(find.text('Chevrolet Onix Turbo 2023'));
  });
}

extension on WidgetTester {
  /// Avanza hasta que [finder] ya no este en pantalla.
  Future<void> esperarQueSeVaya(Finder finder) =>
      esperar(finder, presente: false);

  /// Avanza hasta que aparezca [finder].
  ///
  /// `pumpAndSettle` no sirve como espera general: los indicadores de carga
  /// giran sin parar y nunca «se asienta». Y las fuentes en memoria simulan
  /// latencia con `Future.delayed`, que en un dispositivo corre con reloj real.
  ///
  /// Y en un dispositivo `pump(duracion)` **no espera** esa duracion: solo
  /// pinta un frame. Por eso se mide el tiempo con el reloj de verdad.
  Future<void> esperar(
    Finder finder, {
    bool presente = true,
    Duration limite = const Duration(seconds: 10),
  }) async {
    final fin = DateTime.now().add(limite);
    while (DateTime.now().isBefore(fin)) {
      await pump();
      if (finder.evaluate().isNotEmpty == presente) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TestFailure(
      presente ? 'No aparecio a tiempo: $finder' : 'No se fue a tiempo: $finder',
    );
  }
}
