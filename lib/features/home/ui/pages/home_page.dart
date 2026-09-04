import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/pages/profile_page.dart';
import 'package:f_roble_market/features/chat/ui/pages/chats_page.dart';
import 'package:f_roble_market/features/home/ui/viewmodels/home_view_model.dart';
import 'package:f_roble_market/features/listings/ui/pages/catalog_page.dart';
import 'package:f_roble_market/features/listings/ui/pages/my_listings_page.dart';
import 'package:f_roble_market/features/notifications/ui/pages/notifications_page.dart';
import 'package:f_roble_market/features/notifications/ui/viewmodels/notifications_view_model.dart';

/// La carcasa con la barra inferior. Las pestanas se mantienen vivas en un
/// `IndexedStack` para no recargar el catalogo cada vez que se vuelve a el.
class HomePage extends GetView<HomeViewModel> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = Get.find<NotificationsViewModel>();
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.tabIndex.value,
          children: const [
            CatalogPage(),
            MyListingsPage(),
            ChatsPage(),
            NotificationsPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: controller.goTo,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car),
              label: 'Carros',
            ),
            const NavigationDestination(
              icon: Icon(Icons.sell_outlined),
              selectedIcon: Icon(Icons.sell),
              label: 'Lo mio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: notifications.unreadCount > 0,
                label: Text('${notifications.unreadCount}'),
                child: const Icon(Icons.notifications_none),
              ),
              selectedIcon: const Icon(Icons.notifications),
              label: 'Avisos',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
