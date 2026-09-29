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
import 'package:f_roble_market/features/listings/ui/widgets/brand_strip.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';

/// Una pantalla que lista datos: su view model es de verdad, y los
/// repositorios que hay debajo son falsos.
///
/// El repositorio falso de publicaciones devuelve lo que la prueba le diga y
/// **anota el filtro que le pidieron**. Asi se comprueba que tocar una marca
/// llega hasta el repositorio sin necesitar datos que filtrar de verdad.
class FakeListingRepository extends Fake implements IListingRepository {
  List<CarListing> listingsToReturn = [];
  ListingFilter? lastRequestedFilter;

  @override
  Future<List<CarListing>> search(ListingFilter filter) async {
    lastRequestedFilter = filter;
    return listingsToReturn;
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

CarListing buildListing(String id, String brand, String model) => CarListing(
  id: id,
  sellerId: 'u_ana',
  sellerName: 'Ana Torres',
  brand: brand,
  model: model,
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
  late FakeListingRepository fakeListingRepository;

  setUp(() => fakeListingRepository = FakeListingRepository());

  tearDown(Get.reset);

  /// Se llama **despues** de decir que devuelve el repositorio falso.
  Future<void> openCatalog(WidgetTester tester) async {
    // La pantalla busca su view model con `Get.find`: se registra antes de
    // pintarla. Al registrarlo, GetX llama a `onInit`, que carga los datos en
    // ese momento. Por eso esto no va en `setUp`: cargaria antes de que la
    // prueba prepare lo que el repositorio tiene que devolver.
    final sessionViewModel = SessionViewModel(FakeAuthRepository());
    Get.put(
      CatalogViewModel(
        fakeListingRepository,
        FakeVehicleCatalogRepository(),
        FollowsViewModel(fakeListingRepository, sessionViewModel),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CatalogPage()));
    // Un frame mas para que lleguen los datos de los repositorios falsos.
    await tester.pump();
  }

  testWidgets('pinta las publicaciones que da el repositorio', (tester) async {
    fakeListingRepository.listingsToReturn = [
      buildListing('l_1', 'Mazda', '3'),
      buildListing('l_2', 'Kia', 'Picanto'),
    ];

    await openCatalog(tester);

    expect(find.text('Mazda 3 2021'), findsOneWidget);

    // Una lista solo construye lo que cabe en pantalla: la segunda tarjeta
    // todavia no existe. Se arrastra la lista del catalogo hasta que aparezca.
    await tester.dragUntilVisible(
      find.byKey(CatalogPage.cardKey('l_2')), // lo que se busca
      find.byKey(CatalogPage.listKey), // lo que se arrastra
      const Offset(0, -300), // cuanto en cada paso
    );
    expect(find.text('Kia Picanto 2021'), findsOneWidget);
  });

  testWidgets('sin publicaciones dice que no hay resultados', (tester) async {
    fakeListingRepository.listingsToReturn = [];

    await openCatalog(tester);

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('las marcas salen como filtros de un toque', (tester) async {
    await openCatalog(tester);

    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Mazda'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Kia'), findsOneWidget);
  });

  testWidgets('tocar una marca le pide esa marca al repositorio', (
    tester,
  ) async {
    await openCatalog(tester);

    await tester.tap(find.byKey(BrandStrip.chipKey('Kia')));
    await tester.pump();

    expect(fakeListingRepository.lastRequestedFilter?.brand, 'Kia');
  });
}
