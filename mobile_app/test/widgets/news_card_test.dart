import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/news_item.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/news_card.dart';

NewsItem _news({String? photoUrl}) => NewsItem(
      id: 1,
      title: 'Trail reopens',
      body: 'The campus trail is open again after maintenance.',
      photoUrl: photoUrl,
      authorId: 7,
      isPublished: true,
      publishedAt: DateTime(2026, 3, 14),
      createdAt: DateTime(2026, 3, 14),
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('NewsCard', () {
    testWidgets('renders date, title and body on an AppCard', (tester) async {
      await tester.pumpWidget(_wrap(NewsCard(item: _news())));

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Mar 14, 2026'), findsOneWidget);
      expect(find.text('Trail reopens'), findsOneWidget);
      expect(find.text('The campus trail is open again after maintenance.'), findsOneWidget);
    });

    testWidgets('omits the image when there is no photo', (tester) async {
      await tester.pumpWidget(_wrap(NewsCard(item: _news())));

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.broken_image), findsNothing);
    });

    testWidgets('shows broken-image fallback when the photo fails to load', (tester) async {
      // Network requests in widget tests return HTTP 400, triggering errorBuilder.
      await tester.pumpWidget(_wrap(NewsCard(item: _news(photoUrl: '/uploads/missing.jpg'))));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('forwards taps to onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(NewsCard(item: _news(), onTap: () => tapped = true)));

      await tester.tap(find.text('Trail reopens'));
      expect(tapped, isTrue);
    });
  });
}
