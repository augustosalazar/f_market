import 'package:get/get.dart';

import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/auth/data/local_auth_repository.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/data/local_chat_repository.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/listings/data/local_listing_repository.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/notifications/data/local_notification_repository.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';
import 'package:f_roble_market/features/notifications/ui/viewmodels/notifications_view_model.dart';
import 'package:f_roble_market/features/qa/data/local_qa_repository.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';

/// El unico sitio donde se decide que implementacion concreta usa la app.
///
/// Los controladores piden siempre la interfaz (`IListingRepository`...), asi
/// que pasar de la fuente local a Roble es cambiar estas lineas y nada mas.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Fuente de datos (fase 1: memoria).
    Get.put(DummyData(), permanent: true);

    // La bandeja local hace de repositorio y de emisor: en la fase 1 no hay
    // servidor que produzca los avisos, los produce la propia app.
    final notifications = LocalNotificationRepository(Get.find());

    Get.put<IAuthRepository>(LocalAuthRepository(Get.find()), permanent: true);
    Get.put<IListingRepository>(
      LocalListingRepository(Get.find()),
      permanent: true,
    );
    Get.put<IQaRepository>(LocalQaRepository(Get.find()), permanent: true);
    Get.put<IChatRepository>(LocalChatRepository(Get.find()), permanent: true);
    Get.put<INotificationRepository>(notifications, permanent: true);
    Get.put<INotificationDispatcher>(notifications, permanent: true);

    // Estado global: quien esta dentro y su bandeja.
    Get.put(SessionViewModel(Get.find()), permanent: true);
    Get.put(NotificationsViewModel(Get.find(), Get.find()), permanent: true);
  }
}
