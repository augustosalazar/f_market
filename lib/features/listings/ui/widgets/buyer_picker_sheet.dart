import 'package:flutter/material.dart';

import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';

/// Lo que el vendedor decidio al cerrar la venta.
class SoldChoice {
  const SoldChoice({this.buyerId, this.buyerName});

  /// Sin comprador: la publicacion se cierra igual, pero la venta no queda
  /// registrada y por tanto nadie podra calificarla.
  const SoldChoice.unregistered() : buyerId = null, buyerName = null;

  final String? buyerId;
  final String? buyerName;

  bool get isRegistered => buyerId != null;
}

/// Pregunta a quien se le vendio.
///
/// Los candidatos son quienes abrieron un chat sobre la publicacion: es lo
/// unico que la app sabe de posibles compradores. Si nadie escribio, se puede
/// cerrar sin registrar, porque un carro tambien se vende fuera de la app.
class BuyerPickerSheet extends StatelessWidget {
  const BuyerPickerSheet({super.key, required this.candidates});

  final List<ChatThread> candidates;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('A quien se lo vendiste?', style: text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              candidates.isEmpty
                  ? 'Nadie te ha escrito por esta publicacion, asi que no hay '
                        'a quien registrar.'
                  : 'Registrarlo deja la venta en el historial de los dos y '
                        'les permite calificarse.',
              style: text.bodySmall,
            ),
          ),
          for (final thread in candidates)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(thread.buyerName),
              onTap: () => Navigator.of(context).pop(
                SoldChoice(
                  buyerId: thread.buyerId,
                  buyerName: thread.buyerName,
                ),
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Se vendio por fuera'),
            subtitle: const Text('Cierra la publicacion sin registrar comprador'),
            onTap: () =>
                Navigator.of(context).pop(const SoldChoice.unregistered()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
