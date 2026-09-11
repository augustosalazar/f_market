import 'package:get/get.dart';

import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/core/roble_config.dart';
import 'package:f_roble_market/features/auth/data/datasources/roble_auth_data_source.dart';
import 'package:f_roble_market/features/auth/data/repositories/auth_repository.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/data/datasources/roble_chat_data_source.dart';
import 'package:f_roble_market/features/chat/data/repositories/chat_repository.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/listings/data/datasources/roble_listing_data_source.dart';
import 'package:f_roble_market/features/listings/data/repositories/listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/notifications/data/repositories/in_memory_notification_repository.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:f_roble_market/features/notifications/ui/viewmodels/notifications_view_model.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/roble_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/data/repositories/vehicle_catalog_repository.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';
import 'package:f_roble_market/features/profiles/data/datasources/roble_rating_data_source.dart';
import 'package:f_roble_market/features/profiles/data/repositories/rating_repository.dart';
import 'package:f_roble_market/features/profiles/domain/repositories/i_rating_repository.dart';
import 'package:f_roble_market/features/qa/data/datasources/roble_qa_data_source.dart';
import 'package:f_roble_market/features/qa/data/repositories/qa_repository.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';

/// El unico sitio donde se decide de donde salen los datos.
///
/// Lo que se elige aqui es el **datasource**, no el repositorio: de esos hay
/// uno por feature y es el mismo en las dos configuraciones. `LocalBindings`
/// enchufa los de memoria a estos mismos repositorios.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Un solo cliente para toda la app: uno por pantalla le daria a cada copia
    // su propia sesion.
    final cliente = RobleClient(
      baseUrl: RobleConfig.baseUrl,
      contractId: RobleConfig.contractId,
    );
    Get.put(cliente, permanent: true);

    Get.put<IAuthRepository>(
      AuthRepository(RobleAuthDataSource(cliente)),
      permanent: true,
    );
    Get.put<IListingRepository>(
      ListingRepository(RobleListingDataSource(cliente)),
      permanent: true,
    );
    Get.put<IQaRepository>(
      QaRepository(RobleQaDataSource(cliente)),
      permanent: true,
    );
    Get.put<IVehicleCatalogRepository>(
      VehicleCatalogRepository(RobleVehicleCatalogDataSource(cliente)),
      permanent: true,
    );
    Get.put<IRatingRepository>(
      RatingRepository(RobleRatingDataSource(cliente)),
      permanent: true,
    );
    Get.put<IChatRepository>(
      ChatRepository(RobleChatDataSource(cliente)),
      permanent: true,
    );

    // Las notificaciones todavia no estan en Roble: bandeja en memoria, que se
    // pierde al cerrar la app. Es la unica pieza que sigue sin servidor, y por
    // eso su repositorio no tiene datasource que elegir.
    final notifications = InMemoryNotificationRepository();
    Get.put<INotificationRepository>(notifications, permanent: true);
    Get.put<INotificationDispatcher>(notifications, permanent: true);

    // Estado global: quien esta dentro y su bandeja.
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
