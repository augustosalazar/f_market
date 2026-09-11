import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/di/local_bindings.dart';
import 'package:f_roble_market/features/listings/ui/pages/catalog_page.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/listings/ui/widgets/brand_strip.dart';

void main() {
  setUp(Get.reset);

  testWidgets('el catalogo se ve sin haber iniciado sesion', (tester) async {
    // Con las dependencias locales: la prueba no habla con Roble.
    // Se registran dentro del cuerpo de la prueba porque los
    // `Future.delayed` de la fuente local solo avanzan con el reloj falso que
    // `testWidgets` instala, y en `setUp` ese reloj todavia no existe.
    LocalBindings().dependencies();
    // `FollowsViewModel` ya lo registra `LocalBindings`: es estado global.
    Get.put(
      CatalogViewModel(Get.find(), Get.find(), Get.find<FollowsViewModel>()),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CatalogPage()));
    // `pumpAndSettle` no sirve aqui: el indicador de carga gira sin parar.
    // Se avanza el reloj lo justo para que resuelva la consulta simulada. Van
    // dos avances porque las esperas son encadenadas —primero las
    // publicaciones, despues las marcas— y cada `pump` solo dispara los
    // temporizadores que ya estaban puestos.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Los datos de prueba traen cinco publicaciones; basta con ver una.
    // El catalogo ordena por fecha: la publicacion mas reciente va primero.
    expect(find.text('Chevrolet Onix Turbo 2023'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
    // La busqueda esta disponible sin sesion.
    expect(find.byType(TextField), findsOneWidget);

    // Y la tira de marcas tambien: es un filtro de un toque, y el catalogo se
    // navega sin cuenta.
    expect(find.byType(BrandStrip), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Chevrolet'), findsOneWidget);
  });

  testWidgets('tocar una marca filtra el catalogo', (tester) async {
    LocalBindings().dependencies();
    final controller = Get.put(
      CatalogViewModel(Get.find(), Get.find(), Get.find<FollowsViewModel>()),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CatalogPage()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kia'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(controller.selectedBrand, 'Kia');
    // De las publicaciones de prueba, la unica Kia es la Picanto.
    expect(find.textContaining('Picanto'), findsWidgets);
    expect(find.textContaining('Onix Turbo'), findsNothing);
  });
}
