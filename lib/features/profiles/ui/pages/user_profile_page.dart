import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/utils/message_listener.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';
import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/profiles/ui/viewmodels/user_profile_view_model.dart';
import 'package:f_roble_market/features/profiles/ui/widgets/rate_sheet.dart';
import 'package:f_roble_market/features/profiles/ui/widgets/star_rating.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// El perfil publico de una persona: su reputacion y su historial.
///
/// Se llega desde el nombre del vendedor en una publicacion, y desde el propio
/// perfil. No exige sesion: quien esta mirando un carro necesita poder juzgar
/// a quien se lo vende **antes** de crear cuenta.
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with MessageListener<UserProfilePage> {
  final controller = Get.find<UserProfileViewModel>();

  @override
  void initState() {
    super.initState();
    listenMessages(message: controller.message, error: controller.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.userName)),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              _header(context),
              const SizedBox(height: 24),
              ..._pendingSection(context),
              _section(
                context,
                'Vende ahora',
                controller.selling,
                'No tiene publicaciones activas.',
              ),
              _section(
                context,
                'Ha vendido',
                controller.sold,
                'Todavia no ha vendido nada por aqui.',
              ),
              _section(
                context,
                'Ha comprado',
                controller.bought,
                'Todavia no ha comprado nada por aqui.',
              ),
              const SizedBox(height: 8),
              Text(
                'Calificaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (controller.received.isEmpty)
                Text(
                  'Nadie la ha calificado todavia. Solo puede hacerlo quien '
                  'le compro o le vendio.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final rating in controller.received) _review(context, rating),
            ],
          ),
        );
      }),
    );
  }

  Widget _header(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final average = controller.average;
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          child: Text(_initials(controller.userName), style: text.titleLarge),
        ),
        const SizedBox(height: 12),
        Text(controller.userName, style: text.titleLarge),
        const SizedBox(height: 6),
        if (average == null)
          Text('Sin calificaciones todavia', style: text.bodySmall)
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StarRating(stars: average),
              const SizedBox(width: 8),
              Text(
                '${average.toStringAsFixed(1)} · ${controller.received.length} '
                '${controller.received.length == 1 ? 'calificacion' : 'calificaciones'}',
                style: text.bodySmall,
              ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _stat(context, '${controller.sold.length}', 'vendidos'),
            _stat(context, '${controller.bought.length}', 'comprados'),
            _stat(context, '${controller.selling.length}', 'en venta'),
          ],
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  /// Lo que quien mira todavia puede calificar. Va arriba porque es lo unico
  /// de esta pantalla que le pide algo.
  List<Widget> _pendingSection(BuildContext context) {
    final pending = controller.pending;
    if (pending.isEmpty) return const [];
    return [
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            for (final item in pending)
              ListTile(
                leading: const Icon(Icons.star_border),
                title: Text('Calificar ${item.role.label.toLowerCase()}'),
                subtitle: Text(item.listing.title),
                trailing: FilledButton(
                  onPressed: controller.saving.value
                      ? null
                      : () => _rate(context, item),
                  child: const Text('Calificar'),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  Future<void> _rate(BuildContext context, PendingRating pending) async {
    final result = await showModalBottomSheet<RateResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RateSheet(
        personName: controller.userName,
        role: pending.role,
        listingTitle: pending.listing.title,
      ),
    );
    if (result == null) return;
    await controller.rate(
      pending: pending,
      stars: result.stars,
      comment: result.comment,
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<CarListing> listings,
    String empty,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (listings.isEmpty)
          Text(empty, style: Theme.of(context).textTheme.bodySmall)
        else
          for (final listing in listings)
            ListingCard(
              listing: listing,
              onTap: () =>
                  Get.toNamed(AppRoutes.listingDetail, arguments: listing.id),
            ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _review(BuildContext context, UserRating rating) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(stars: rating.stars.toDouble(), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${rating.raterName} · ${rating.ratedRole.label.toLowerCase()}',
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(Formatters.relative(rating.createdAt), style: text.bodySmall),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(rating.comment, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
