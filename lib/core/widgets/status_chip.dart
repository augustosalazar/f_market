import 'package:flutter/material.dart';

import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';

/// El estado de una publicacion, con el color que le corresponde.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final ListingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ListingStatus.available => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ListingStatus.reserved => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ListingStatus.sold => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      ListingStatus.withdrawn => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
