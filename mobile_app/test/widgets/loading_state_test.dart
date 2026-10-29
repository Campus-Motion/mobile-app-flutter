import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/loading_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Column(children: [child])),
);

void main() {
  testWidgets('shows a centred spinner', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState(height: 100)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('applies the fixed height when provided', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState(height: 120)));
    expect(tester.getSize(find.byType(LoadingState)).height, 120);
  });
}
