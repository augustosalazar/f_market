import 'package:flutter/material.dart';

import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/profiles/ui/widgets/star_rating.dart';

/// Lo que devuelve la hoja de calificacion.
class RateResult {
  const RateResult({required this.stars, required this.comment});

  final int stars;
  final String comment;
}

/// La hoja para calificar a la otra parte de una venta.
///
/// Arranca en cinco estrellas a proposito: lo normal es que la venta saliera
/// bien, y obligar a elegir desde cero anade un paso a la mayoria de casos.
class RateSheet extends StatefulWidget {
  const RateSheet({
    super.key,
    required this.personName,
    required this.role,
    required this.listingTitle,
  });

  final String personName;
  final RatedRole role;
  final String listingTitle;

  @override
  State<RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<RateSheet> {
  int _stars = UserRating.maxStars;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calificar a ${widget.personName}', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${widget.role.label} · ${widget.listingTitle}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          Center(
            child: StarPicker(
              stars: _stars,
              onChanged: (value) => setState(() => _stars = value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: 'Como fue el trato?',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Una calificacion no se puede cambiar ni borrar despues.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              RateResult(stars: _stars, comment: _comment.text),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Publicar calificacion'),
          ),
        ],
      ),
    );
  }
}
