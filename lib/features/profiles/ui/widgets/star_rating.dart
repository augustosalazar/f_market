import 'package:flutter/material.dart';

import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';

/// Estrellas de solo lectura. Media estrella incluida, que es lo que hace
/// legible un promedio como 4.3 sin tener que leer el numero.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 18});

  final double stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= UserRating.maxStars; i++)
          Icon(
            stars >= i
                ? Icons.star
                : (stars >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: color,
          ),
      ],
    );
  }
}

/// Estrellas que se tocan, para el formulario de calificacion.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.stars, required this.onChanged});

  final int stars;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = UserRating.minStars; i <= UserRating.maxStars; i++)
          IconButton(
            tooltip: '$i',
            onPressed: () => onChanged(i),
            icon: Icon(
              stars >= i ? Icons.star : Icons.star_border,
              size: 32,
              color: color,
            ),
          ),
      ],
    );
  }
}
