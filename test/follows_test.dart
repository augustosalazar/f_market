import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/data/datasources/in_memory_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/my_listings_view_model.dart';
import 'package:f_roble_market/features/chat/data/datasources/in_memory_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/in_memory_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/data/repositories/vehicle_catalog_repository.dart';

/// La estrella se marca en el catalogo o en el detalle, pero quien la muestra
/// tambien es «Lo mio -> Siguiendo». Esa pestana vive en un `IndexedStack` y no
/// se reconstruye al volver a ella, asi que la unica forma de que se entere es
/// que lo seguido sea uno solo y observable.
void main() {
  late DummyData data;
  late ListingRepository listings;
  late SessionViewModel session;
  late FollowsViewModel follows;
  late CatalogViewModel catalog;
  late MyListingsViewModel mine;

  setUp(() async {
    Get.reset();
    data = DummyData();
    listings = ListingRepository(InMemoryListingDataSource(data));
    session = SessionViewModel(AuthRepository(InMemoryAuthDataSource(data)));
    await session.login(
      email: 'carla@demo.com',
      password: DummyData.demoPassword,
    );

    // Van por `Get.put` y no por el constructor a secas porque lo que se prueba
    // vive en `onInit`: sin registrarlos, GetX no lo llama.
    follows = Get.put(FollowsViewModel(listings, session));
    catalog = Get.put(
      CatalogViewModel(
        listings,
        VehicleCatalogRepository(InMemoryVehicleCatalogDataSource(data)),
        follows,
      ),
    );
    mine = Get.put(
      MyListingsViewModel(
        listings,
        ChatRepository(InMemoryChatDataSource(data)),
        InMemoryNotificationRepository(),
        session,
        follows,
      ),
    );
    await _settle();
  });

  tearDown(Get.reset);

  test('seguir desde el catalogo aparece en «Lo mio -> Siguiendo»', () async {
    // Carla no sigue nada en los datos de prueba.
    expect(mine.following, isEmpty);

    await catalog.toggleFollow('l_1');
    await _settle();

    expect(follows.ids, contains('l_1'));
    expect(mine.following.map((l) => l.id), contains('l_1'));
  });

  test('dejar de seguir la saca de la lista', () async {
    await catalog.toggleFollow('l_1');
    await _settle();
    expect(mine.following, isNotEmpty);

    await catalog.toggleFollow('l_1');
    await _settle();

    expect(follows.ids, isEmpty);
    expect(mine.following, isEmpty);
  });
}

/// La fuente de memoria simula latencia; hay que dejarla resolver antes de
/// mirar las listas.
Future<void> _settle() => Future.delayed(const Duration(milliseconds: 900));
