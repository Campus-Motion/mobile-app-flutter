import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/error_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows icon and message', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'Failed to load')));
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('shows retry button and calls onRetry when tapped', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(ErrorState(message: 'Failed to load', onRetry: () => taps++)),
    );
    expect(find.byType(AppButton), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('hides retry button when onRetry is null', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'Failed to load')));
    expect(find.byType(AppButton), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });
}
