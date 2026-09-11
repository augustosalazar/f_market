import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/utils/message_listener.dart';
import 'package:f_roble_market/core/widgets/car_photo.dart';
import 'package:f_roble_market/core/widgets/status_chip.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/listing_detail_view_model.dart';
import 'package:f_roble_market/features/listings/ui/widgets/buyer_picker_sheet.dart';
import 'package:f_roble_market/features/profiles/ui/pages/profile_args.dart';
import 'package:f_roble_market/features/qa/ui/widgets/question_list.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// La ficha completa de una publicacion, con sus preguntas publicas.
class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({super.key});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage>
    with MessageListener<ListingDetailPage> {
  final controller = Get.find<ListingDetailViewModel>();

  @override
  void initState() {
    super.initState();
    listenMessages(message: controller.message, error: controller.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = controller.listing.value;
        if (listing == null) {
          return const Center(child: Text('La publicacion ya no existe.'));
        }
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: controller.isFollowing
                      ? 'Dejar de seguir'
                      : 'Seguir y recibir avisos',
                  onPressed: controller.toggleFollow,
                  icon: Icon(
                    controller.isFollowing ? Icons.star : Icons.star_border,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _Gallery(
                  images: listing.images,
                  index: controller.photoIndex,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(listing.title, style: text.headlineSmall),
                      ),
                      StatusChip(status: listing.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.price(listing.price),
                    style: text.headlineMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Specs(listing: listing),
                  const SizedBox(height: 20),
                  Text('Descripcion', style: text.titleMedium),
                  const SizedBox(height: 6),
                  Text(listing.description, style: text.bodyMedium),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(listing.sellerName[0])),
                    title: Text(listing.sellerName),
                    subtitle: Text(
                      'Publicado ${Formatters.relative(listing.createdAt)}',
                    ),
                    // Antes de escribirle conviene poder mirar a quien le
                    // estas comprando: su historial y lo que opinan de el.
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(
                      AppRoutes.userProfile,
                      arguments: ProfileArgs(
                        userId: listing.sellerId,
                        name: listing.sellerName,
                      ),
                    ),
                  ),
                  if (listing.buyerName != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.handshake_outlined),
                      ),
                      title: Text('Vendido a ${listing.buyerName}'),
                      subtitle: listing.soldAt == null
                          ? null
                          : Text(Formatters.date(listing.soldAt!)),
                    ),
                  if (controller.isOwner) ...[
                    const Divider(height: 32),
                    Text('Estado de la publicacion', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final status in ListingStatus.values)
                          ChoiceChip(
                            label: Text(status.label),
                            selected: listing.status == status,
                            onSelected: (_) => status == ListingStatus.sold
                                ? _sell(context)
                                : controller.changeStatus(status),
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  QuestionList(
                    questions: controller.questions,
                    isOwner: controller.isOwner,
                    onAsk: controller.ask,
                    onAnswer: controller.answer,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.listing.value == null) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: controller.isOwner
                ? const SizedBox.shrink()
                : FilledButton.icon(
                    onPressed: controller.openPrivateChat,
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Chat privado con el vendedor'),
                  ),
          ),
        );
      }),
    );
  }

  /// Igual que en «Lo mio»: cerrar la venta pregunta a quien se le vendio.
  Future<void> _sell(BuildContext context) async {
    final candidates = await controller.buyerCandidates();
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<SoldChoice>(
      context: context,
      builder: (_) => BuyerPickerSheet(candidates: candidates),
    );
    if (choice == null) return;
    if (!choice.isRegistered) {
      await controller.changeStatus(ListingStatus.sold);
      return;
    }
    await controller.markSold(
      buyerId: choice.buyerId!,
      buyerName: choice.buyerName!,
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images, required this.index});

  final List<String> images;
  final RxInt index;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const CarPhoto(source: null);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: (value) => index.value = value,
          itemCount: images.length,
          itemBuilder: (_, i) => CarPhoto(source: images[i]),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == index.value
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({required this.listing});

  final CarListing listing;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.calendar_today_outlined, 'Ano', '${listing.year}'),
      (Icons.speed, 'Kilometraje', Formatters.mileage(listing.mileageKm)),
      (Icons.local_gas_station_outlined, 'Combustible', listing.fuel.label),
      (Icons.settings, 'Transmision', listing.transmission.label),
      (Icons.place_outlined, 'Ciudad', listing.city),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (icon, label, value) in items)
          Container(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.labelSmall),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
