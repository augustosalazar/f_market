import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/widgets/filter_sheet.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// El catalogo: la primera pantalla y la unica que se ve sin sesion
/// (requisito 3).
class CatalogPage extends GetView<CatalogViewModel> {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carros en venta'),
        actions: [
          Obx(() {
            final active = !controller.filter.value.isEmpty;
            return IconButton(
              tooltip: 'Filtrar',
              onPressed: () => _openFilters(context),
              icon: Badge(
                isLabelVisible: active,
                child: const Icon(Icons.tune),
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: controller.onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Marca, modelo o ciudad',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.listings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.listings.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'Sin resultados',
            message: 'Prueba con otra busqueda o quita los filtros.',
            action: OutlinedButton(
              onPressed: controller.clearFilter,
              child: const Text('Quitar filtros'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: controller.listings.length,
            itemBuilder: (context, index) {
              final listing = controller.listings[index];
              return Obx(
                () => ListingCard(
                  listing: listing,
                  isFollowed: controller.followed.contains(listing.id),
                  onToggleFollow: () => controller.toggleFollow(listing.id),
                  onTap: () =>
                      Get.toNamed(AppRoutes.listingDetail, arguments: listing.id),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<ListingFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        initial: controller.filter.value,
        brands: controller.brands,
      ),
    );
    if (result != null) controller.applyFilter(result);
  }
}
