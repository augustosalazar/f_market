import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/pages/catalog_page.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';

/// Una pantalla que lista datos: su view model es de verdad, y los
/// repositorios que hay debajo son falsos.
///
/// El repositorio falso de publicaciones devuelve lo que la prueba le diga y
/// **anota el filtro que le pidieron**. Asi se comprueba que tocar una marca
/// llega hasta el repositorio sin necesitar datos que filtrar de verdad.
class FakeListingRepository extends Fake implements IListingRepository {
  List<CarListing> resultado = [];
  ListingFilter? ultimoFiltro;

  @override
  Future<List<CarListing>> search(ListingFilter filter) async {
    ultimoFiltro = filter;
    return resultado;
  }
}

class FakeVehicleCatalogRepository extends Fake
    implements IVehicleCatalogRepository {
  @override
  Future<List<CarBrand>> brands() async => const [
    CarBrand(id: 'b_1', name: 'Mazda', sortOrder: 1),
    CarBrand(id: 'b_2', name: 'Kia', sortOrder: 2),
  ];
}

/// El catalogo pregunta que carros sigue quien mira, y para eso necesita la
/// sesion. Sin nadie dentro no llama a nada, asi que el falso va vacio.
class FakeAuthRepository extends Fake implements IAuthRepository {}

CarListing carro(String id, String marca, String modelo) => CarListing(
  id: id,
  sellerId: 'u_ana',
  sellerName: 'Ana Torres',
  brand: marca,
  model: modelo,
  year: 2021,
  price: 50000000,
  mileageKm: 30000,
  fuel: FuelType.gasoline,
  transmission: TransmissionType.manual,
  city: 'Barranquilla',
  description: '',
  images: const [],
  status: ListingStatus.available,
  createdAt: DateTime(2026, 9, 1),
);

void main() {
  late FakeListingRepository publicaciones;

  setUp(() => publicaciones = FakeListingRepository());

  tearDown(Get.reset);

  /// Se llama **despues** de decir que devuelve el repositorio falso.
  Future<void> abrirCatalogo(WidgetTester tester) async {
    // La pantalla busca su view model con `Get.find`: se registra antes de
    // pintarla. Al registrarlo, GetX llama a `onInit`, que carga los datos en
    // ese momento. Por eso esto no va en `setUp`: cargaria antes de que la
    // prueba prepare lo que el repositorio tiene que devolver.
    final sesion = SessionViewModel(FakeAuthRepository());
    Get.put(
      CatalogViewModel(
        publicaciones,
        FakeVehicleCatalogRepository(),
        FollowsViewModel(publicaciones, sesion),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CatalogPage()));
    // Un frame mas para que lleguen los datos de los repositorios falsos.
    await tester.pump();
  }

  testWidgets('pinta las publicaciones que da el repositorio', (tester) async {
    publicaciones.resultado = [
      carro('l_1', 'Mazda', '3'),
      carro('l_2', 'Kia', 'Picanto'),
    ];

    // Una lista solo construye lo que cabe en pantalla, y la de prueba mide
    // 800x600: la segunda tarjeta quedaria debajo del borde y no existiria.
    // Se agranda la pantalla para que quepan las dos.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await abrirCatalogo(tester);

    expect(find.text('Mazda 3 2021'), findsOneWidget);
    expect(find.text('Kia Picanto 2021'), findsOneWidget);
  });

  testWidgets('sin publicaciones dice que no hay resultados', (tester) async {
    publicaciones.resultado = [];

    await abrirCatalogo(tester);

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('las marcas salen como filtros de un toque', (tester) async {
    await abrirCatalogo(tester);

    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Mazda'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Kia'), findsOneWidget);
  });

  testWidgets('tocar una marca le pide esa marca al repositorio', (
    tester,
  ) async {
    await abrirCatalogo(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kia'));
    await tester.pump();

    expect(publicaciones.ultimoFiltro?.brand, 'Kia');
  });
}
