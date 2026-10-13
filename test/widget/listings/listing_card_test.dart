import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f_roble_market/core/utils/formatters.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/ui/widgets/listing_card.dart';

/// Un widget sin estado: recibe datos y funciones, y pinta. No hace falta nada
/// falso, ni GetX, ni repositorios.
final mazda = CarListing(
  id: 'l_1',
  sellerId: 'u_ana',
  sellerName: 'Ana Torres',
  brand: 'Mazda',
  model: '3',
  year: 2021,
  price: 78500000,
  mileageKm: 42000,
  fuel: FuelType.gasoline,
  transmission: TransmissionType.automatic,
  city: 'Barranquilla',
  description: '',
  // Sin fotos: la tarjeta pinta un color, sin ir a la red.
  images: const [],
  status: ListingStatus.available,
  createdAt: DateTime(2026, 9, 1),
);

/// Todo widget necesita un `MaterialApp` alrededor: de ahi salen el tema, la
/// direccion del texto y los tooltips.
Widget wrapInApp(Widget widget) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: widget)),
);

void main() {
  testWidgets('pinta el titulo, el precio y el estado', (tester) async {
    await tester.pumpWidget(
      wrapInApp(ListingCard(listing: mazda, onTap: () {})),
    );

    expect(find.text('Mazda 3 2021'), findsOneWidget);
    expect(find.text(Formatters.price(78500000)), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('sin onToggleFollow no hay estrella', (tester) async {
    await tester.pumpWidget(
      wrapInApp(ListingCard(listing: mazda, onTap: () {})),
    );

    expect(find.byKey(ListingCard.followButtonKey), findsNothing);
  });

  testWidgets('la estrella dice si ya se sigue', (tester) async {
    await tester.pumpWidget(
      wrapInApp(
        ListingCard(
          listing: mazda,
          onTap: () {},
          isFollowed: true,
          onToggleFollow: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byTooltip('Dejar de seguir'), findsOneWidget);
  });

  testWidgets('tocar la estrella avisa a quien la puso', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapInApp(
        ListingCard(listing: mazda, onTap: () {}, onToggleFollow: () => taps++),
      ),
    );

    await tester.tap(find.byKey(ListingCard.followButtonKey));

    expect(taps, 1);
  });

  testWidgets('tocar la tarjeta abre la publicacion', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      wrapInApp(ListingCard(listing: mazda, onTap: () => opened = true)),
    );

    await tester.tap(find.byType(ListingCard));

    expect(opened, isTrue);
  });
}
