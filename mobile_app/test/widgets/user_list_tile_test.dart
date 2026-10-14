import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/widgets/user_list_tile.dart';

void main() {
  group('UserListTile Tests', () {
    final sampleUser = User(
      id: 42,
      username: 'Alex.Morgan',
      email: 'alex.morgan@epfl.ch',
      role: 'student',
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('renders username, capitalized role and ID', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListTile(user: sampleUser),
          ),
        ),
      );

      expect(find.text('Alex.Morgan'), findsOneWidget);
      expect(find.text('Student • ID: 42'), findsOneWidget);
    });

    testWidgets('renders custom subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListTile(
              user: sampleUser,
              subtitle: 'Runner • 15 activities',
            ),
          ),
        ),
      );

      expect(find.text('Alex.Morgan'), findsOneWidget);
      expect(find.text('Runner • 15 activities'), findsOneWidget);
      expect(find.text('Student • ID: 42'), findsNothing);
    });

    testWidgets('renders trailing widget and responds to tap', (tester) async {
      bool tapped = false;
      bool trailingTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListTile(
              user: sampleUser,
              onTap: () => tapped = true,
              trailing: IconButton(
                icon: const Icon(Icons.star),
                onPressed: () => trailingTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star));
      expect(trailingTapped, isTrue);

      await tester.tap(find.text('Alex.Morgan'));
      expect(tapped, isTrue);
    });
  });
}
