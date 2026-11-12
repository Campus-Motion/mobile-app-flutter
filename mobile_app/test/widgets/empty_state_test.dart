import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows icon and title', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyState(title: 'No events')));
    expect(find.text('No events'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('shows subtitle only when provided', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmptyState(title: 'No events', subtitle: 'Check back soon')),
    );
    expect(find.text('Check back soon'), findsOneWidget);

    await tester.pumpWidget(_wrap(const EmptyState(title: 'No events')));
    expect(find.text('Check back soon'), findsNothing);
  });
}
