import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/screens/app/heatmap/index.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/app_button.dart';

XFile _file(String name) =>
    XFile.fromData(Uint8List.fromList([1, 2, 3]), name: name, path: name);

void main() {
  setUp(() => ApiService.mockMode = false);
  tearDown(() => ApiService.mockMode = false);

  testWidgets('demo clearly disables real file import', (tester) async {
    ApiService.mockMode = true;
    await tester.pumpWidget(
      MaterialApp(home: HeatmapScreen(loadHeatmap: () async => null)),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Choose FIT file'),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text(
        'Demo mode shows sample data. FIT import requires the live API.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('picker cancellation sends no upload and allows choosing again', (
    tester,
  ) async {
    var choices = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeatmapScreen(
          loadHeatmap: () async => null,
          pickFitFile: () async {
            choices++;
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose FIT file'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
    expect(choices, 1);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Choose FIT file'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('cancel confirmation does not upload', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: HeatmapScreen(
              loadHeatmap: () async => null,
              pickFitFile: () async => _file('campus-run.fit'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose FIT file'));
        // The busy spinner stays active while the confirmation is open.
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Import FIT route?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
      () => MockClient(
        (_) async =>
            throw StateError('Upload must not occur before confirmation'),
      ),
    );
  });

  testWidgets(
    'confirmation uploads once, refreshes the heatmap and reports private saving',
    (tester) async {
      var requests = 0;
      var loads = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: HeatmapScreen(
                loadHeatmap: () async {
                  loads++;
                  return null;
                },
                pickFitFile: () async => _file('campus-run.fit'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Choose FIT file'));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Import'));
          await tester.pumpAndSettle();
          expect(requests, 1);
          expect(loads, 2);
          expect(find.text('FIT activity saved privately.'), findsOneWidget);
        },
        () => MockClient((request) async {
          requests++;
          expect(request.url.path, '/activities/import-fit');
          return http.Response(
            json.encode({'id': 9, 'is_public': false, 'type': 'other'}),
            201,
          );
        }),
      );
    },
  );

  testWidgets('server errors are safe and allow retry', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: HeatmapScreen(
              loadHeatmap: () async => null,
              pickFitFile: () async => _file('campus-run.fit'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose FIT file'));
        // The busy spinner stays active while the confirmation is open.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Import'));
        await tester.pumpAndSettle();
        expect(find.textContaining('private parser diagnostic'), findsNothing);
        expect(
          find.text(
            'The file is invalid or has fewer than two supported GPS points.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<AppButton>(
                find.widgetWithText(AppButton, 'Choose FIT file'),
              )
              .onPressed,
          isNotNull,
        );
      },
      () => MockClient(
        (_) async => http.Response('private parser diagnostic', 422),
      ),
    );
  });

  testWidgets('leaving while picker is open causes no disposed-state update', (
    tester,
  ) async {
    final selected = Completer<XFile?>();
    await tester.pumpWidget(
      MaterialApp(
        home: HeatmapScreen(
          loadHeatmap: () async => null,
          pickFitFile: () => selected.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose FIT file'));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    selected.complete(_file('campus-run.fit'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
