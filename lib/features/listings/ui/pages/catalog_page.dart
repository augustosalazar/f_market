import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/widgets/empty_state.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/catalog_view_model.dart';
import 'package:f_roble_market/features/listings/ui/widgets/brand_strip.dart';
import 'package:f_roble_market/features/listings/ui/widgets/filter_sheet.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// El catalogo: la primera pantalla y la unica que se ve sin sesion
/// (requisito 3).
class CatalogPage extends GetView<CatalogViewModel> {
  /// Las claves que usan las pruebas para llegar a la lista sin depender de
  /// su texto. Viven aqui, junto al widget, para que prueba y pantalla
  /// compartan el nombre: una errata es un error de compilacion.
  static const listKey = Key('catalog.list');

  /// La tarjeta de una publicacion, por su id.
  static Key cardKey(String listingId) => ValueKey('catalog.card.$listingId');

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
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
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
              // La lista se copia **dentro** del `Obx`: pasar la observable
              // tal cual no la lee aqui, y sin lectura no hay dependencia —la
              // tira se quedaria vacia aunque llegaran las marcas.
              Obx(
                () => BrandStrip(
                  brands: [...controller.brands],
                  selected: controller.selectedBrand,
                  onSelected: controller.selectBrand,
                ),
              ),
              const SizedBox(height: 8),
            ],
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
            key: listKey,
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: controller.listings.length,
            itemBuilder: (context, index) {
              final listing = controller.listings[index];
              return Obx(
                () => ListingCard(
                  key: cardKey(listing.id),
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
        brands: [for (final brand in controller.brands) brand.name],
      ),
    );
    if (result != null) controller.applyFilter(result);
  }
}
