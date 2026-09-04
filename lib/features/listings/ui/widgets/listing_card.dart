import 'package:flutter/material.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/core/widgets/car_photo.dart';
import 'package:f_roble_market/core/widgets/status_chip.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';

/// La tarjeta del catalogo. Es la unidad que se repite en todas las listas de
/// publicaciones, asi que vive en la feature y no en cada pantalla.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.isFollowed = false,
    this.onToggleFollow,
    this.trailing,
  });

  final CarListing listing;
  final VoidCallback onTap;
  final bool isFollowed;
  final VoidCallback? onToggleFollow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CarPhoto(source: listing.cover),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: StatusChip(status: listing.status),
                ),
                if (onToggleFollow != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton.filledTonal(
                      onPressed: onToggleFollow,
                      tooltip: isFollowed
                          ? 'Dejar de seguir'
                          : 'Seguir y recibir avisos',
                      icon: Icon(
                        isFollowed ? Icons.star : Icons.star_border,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.price(listing.price),
                    style: text.titleLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _Meta(icon: Icons.speed, label: Formatters.mileage(listing.mileageKm)),
                      _Meta(icon: Icons.settings, label: listing.transmission.label),
                      _Meta(icon: Icons.place_outlined, label: listing.city),
                    ],
                  ),
                  if (trailing != null) ...[const SizedBox(height: 10), trailing!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
