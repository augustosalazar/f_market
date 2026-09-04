import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/my_listings_view_model.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// Lo mio: lo que vendo, y lo que sigo (que es lo que me genera avisos).
class MyListingsPage extends GetView<MyListingsViewModel> {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lo mio'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis publicaciones'),
              Tab(text: 'Siguiendo'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (!await session.ensureLoggedIn()) return;
            final created = await Get.toNamed(AppRoutes.createListing);
            if (created != null) controller.load();
          },
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
        body: Obx(() {
          if (!session.isLoggedIn) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: 'Entra para ver lo tuyo',
              message: 'Necesitas una cuenta para publicar y seguir carros.',
              action: FilledButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: const Text('Entrar'),
              ),
            );
          }
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            children: [_selling(context), _following()],
          );
        }),
      ),
    );
  }

  Widget _selling(BuildContext context) {
    if (controller.selling.isEmpty) {
      return const EmptyState(
        icon: Icons.sell_outlined,
        title: 'Aun no vendes nada',
        message: 'Publica tu carro y recibiras avisos cuando pregunten.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: controller.selling.length,
      itemBuilder: (context, index) {
        final listing = controller.selling[index];
        return ListingCard(
          listing: listing,
          onTap: () =>
              Get.toNamed(AppRoutes.listingDetail, arguments: listing.id),
          trailing: Wrap(
            spacing: 8,
            children: [
              for (final status in ListingStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  visualDensity: VisualDensity.compact,
                  selected: listing.status == status,
                  onSelected: (_) => controller.changeStatus(listing, status),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _following() {
    if (controller.following.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border,
        title: 'No sigues ninguna publicacion',
        message:
            'Marca con la estrella los carros que te interesan: te avisaremos '
            'de preguntas, respuestas y cambios de estado.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: controller.following.length,
      itemBuilder: (context, index) {
        final listing = controller.following[index];
        return ListingCard(
          listing: listing,
          isFollowed: true,
          onTap: () =>
              Get.toNamed(AppRoutes.listingDetail, arguments: listing.id),
        );
      },
    );
  }
}
