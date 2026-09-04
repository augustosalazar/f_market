import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/pages/login_page.dart';
import 'package:f_roble_market/features/auth/ui/pages/register_page.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/ui/pages/chat_page.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chat_view_model.dart';
import 'package:f_roble_market/features/chat/ui/viewmodels/chats_view_model.dart';
import 'package:f_roble_market/features/home/ui/pages/home_page.dart';
import 'package:f_roble_market/features/home/ui/pages/splash_page.dart';
import 'package:f_roble_market/features/home/ui/viewmodels/home_view_model.dart';
import 'package:f_roble_market/features/listings/ui/pages/create_listing_page.dart';
import 'package:f_roble_market/features/listings/ui/pages/listing_detail_page.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/create_listing_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/listing_detail_view_model.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/my_listings_view_model.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// Registra una instancia recien creada, descartando la que hubiera.
///
/// Hace falta porque `Get.put` **conserva** la instancia ya registrada en vez
/// de reemplazarla: sin esto, volver a entrar a una pantalla que depende del
/// argumento de la ruta seguiria mostrando el argumento anterior.
void _putFresh<T>(T instance) {
  if (Get.isRegistered<T>()) Get.delete<T>(force: true);
  Get.put<T>(instance);
}

/// Las pestanas viven todas a la vez dentro de un `IndexedStack`, asi que sus
/// view models se registran juntos y con `fenix` para que sobrevivan a un
/// `delete` y se reconstruyan solos al volver.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeViewModel(), fenix: true);
    Get.lazyPut(
      () => CatalogViewModel(Get.find(), Get.find<SessionViewModel>()),
      fenix: true,
    );
    Get.lazyPut(
      () => MyListingsViewModel(
        Get.find(),
        Get.find(),
        Get.find<SessionViewModel>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => ChatsViewModel(Get.find(), Get.find<SessionViewModel>()),
      fenix: true,
    );
  }
}

/// El detalle depende del argumento de la ruta, asi que se crea una instancia
/// nueva en cada entrada en vez de reutilizar una registrada.
class ListingDetailBinding extends Bindings {
  @override
  void dependencies() {
    _putFresh(
      ListingDetailViewModel(
        listingId: Get.arguments as String,
        listings: Get.find(),
        qa: Get.find(),
        chats: Get.find(),
        dispatcher: Get.find(),
        session: Get.find<SessionViewModel>(),
      ),
    );
  }
}

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    _putFresh(
      ChatViewModel(
        threadId: Get.arguments as String,
        chats: Get.find(),
        dispatcher: Get.find(),
        session: Get.find<SessionViewModel>(),
      ),
    );
  }
}

class CreateListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CreateListingViewModel(Get.find(), Get.find<SessionViewModel>()),
      fenix: true,
    );
  }
}

abstract class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(
      name: AppRoutes.listingDetail,
      page: () => const ListingDetailPage(),
      binding: ListingDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.createListing,
      page: () => const CreateListingPage(),
      binding: CreateListingBinding(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
    ),
  ];
}
