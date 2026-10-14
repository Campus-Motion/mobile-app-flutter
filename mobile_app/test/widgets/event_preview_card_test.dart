import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/event.dart';
import 'package:mobile_app/widgets/event_preview_card.dart';
import 'package:mobile_app/widgets/section_header.dart';

Event _event({String title = 'Campus Fun Run'}) => Event(
      id: 42,
      title: title,
      body: '5 km loop around the lake',
      startTime: DateTime(2026, 10, 12, 18, 30),
      endTime: DateTime(2026, 10, 12, 19, 30),
      participantCount: 12,
      createdAt: DateTime(2026, 10, 1),
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(height: EventPreviewCard.size, child: child),
        ),
      ),
    );

void main() {
  group('EventPreviewCard', () {
    testWidgets('renders title, formatted start time and icon', (tester) async {
      await tester.pumpWidget(_wrap(EventPreviewCard(event: _event())));

      expect(find.text('Campus Fun Run'), findsOneWidget);
      expect(find.text('Oct 12, 18:30'), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(EventPreviewCard(event: _event(), onTap: () => tapped = true)));

      await tester.tap(find.byType(EventPreviewCard));
      expect(tapped, isTrue);
    });

    testWidgets('long titles are ellipsized without overflow', (tester) async {
      await tester.pumpWidget(_wrap(EventPreviewCard(
        event: _event(title: 'A very long event title that should never overflow the fixed tile'),
      )));

      expect(tester.takeException(), isNull);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders its title', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SectionHeader(title: 'Latest News')),
      ));

      expect(find.text('Latest News'), findsOneWidget);
    });
  });
}
