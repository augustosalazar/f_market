import 'package:get/get.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/datasources/in_memory_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/data/datasources/in_memory_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/listings/data/datasources/in_memory_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:f_roble_market/features/notifications/ui/viewmodels/notifications_view_model.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/in_memory_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/data/repositories/vehicle_catalog_repository.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';
import 'package:f_roble_market/features/profiles/data/datasources/in_memory_rating_data_source.dart';
import 'package:f_roble_market/features/profiles/data/repositories/rating_repository.dart';
import 'package:f_roble_market/features/profiles/domain/repositories/i_rating_repository.dart';
import 'package:f_roble_market/features/qa/data/datasources/in_memory_qa_data_source.dart';
import 'package:f_roble_market/features/qa/data/repositories/qa_repository.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';

/// Los mismos repositorios, con los datasources de memoria.
///
/// Es lo que usan las pruebas y sirve para trabajar en la UI sin servidor. Que
/// solo cambie el datasource es la prueba de que la separacion vale: las
/// pruebas ejercitan el repositorio de verdad, no una copia suya.
class LocalBindings extends Bindings {
  @override
  void dependencies() {
    final data = DummyData();
    Get.put(data, permanent: true);

    Get.put<IAuthRepository>(
      AuthRepository(InMemoryAuthDataSource(data)),
      permanent: true,
    );
    Get.put<IListingRepository>(
      ListingRepository(InMemoryListingDataSource(data)),
      permanent: true,
    );
    Get.put<IQaRepository>(
      QaRepository(InMemoryQaDataSource(data)),
      permanent: true,
    );
    Get.put<IVehicleCatalogRepository>(
      VehicleCatalogRepository(InMemoryVehicleCatalogDataSource(data)),
      permanent: true,
    );
    Get.put<IRatingRepository>(
      RatingRepository(InMemoryRatingDataSource(data)),
      permanent: true,
    );
    Get.put<IChatRepository>(
      ChatRepository(InMemoryChatDataSource(data)),
      permanent: true,
    );

    final notifications = InMemoryNotificationRepository();
    Get.put<INotificationRepository>(notifications, permanent: true);
    Get.put<INotificationDispatcher>(notifications, permanent: true);

    Get.put(SessionViewModel(Get.find()), permanent: true);
    // Lo seguido es estado global, no de una pantalla: el catalogo, el detalle
    // y «Lo mio -> Siguiendo» leen y escriben el mismo conjunto.
    Get.put(
      FollowsViewModel(Get.find(), Get.find<SessionViewModel>()),
      permanent: true,
    );
    Get.put(NotificationsViewModel(Get.find(), Get.find()), permanent: true);
  }
}
