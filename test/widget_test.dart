import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/di/app_bindings.dart';
import 'package:f_roble_market/features/listings/ui/pages/catalog_page.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';

void main() {
  setUp(Get.reset);

  testWidgets('el catalogo se ve sin haber iniciado sesion', (tester) async {
    // Las dependencias se registran dentro del cuerpo de la prueba: los
    // `Future.delayed` de la fuente local solo avanzan con el reloj falso que
    // `testWidgets` instala, y en `setUp` ese reloj todavia no existe.
    AppBindings().dependencies();
    Get.put(CatalogViewModel(Get.find(), Get.find<SessionViewModel>()));

    await tester.pumpWidget(const GetMaterialApp(home: CatalogPage()));
    // `pumpAndSettle` no sirve aqui: el indicador de carga gira sin parar.
    // Se avanza el reloj lo justo para que resuelva la consulta simulada.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Los datos de prueba traen cinco publicaciones; basta con ver una.
    // El catalogo ordena por fecha: la publicacion mas reciente va primero.
    expect(find.text('Chevrolet Onix Turbo 2023'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
    // La busqueda esta disponible sin sesion.
    expect(find.byType(TextField), findsOneWidget);
  });
}
