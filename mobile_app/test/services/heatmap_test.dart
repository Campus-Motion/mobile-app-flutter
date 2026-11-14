import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  setUp(() => ApiService.mockMode = true);
  tearDown(() => ApiService.mockMode = false);

  test(
    'personal heatmap parses the mock backend PNG and geographic bounds',
    () async {
      final heatmap = await ActivityService().getHeatmap();
      expect(heatmap, isNotNull);
      expect(heatmap!.runs, 1);
      expect(heatmap.imageBytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(heatmap.bounds.length, 2);
      expect(heatmap.bounds[0][0], lessThan(heatmap.bounds[1][0]));
    },
  );

  test('malformed image URLs and bounds are rejected', () {
    for (final json in [
      {'image': 'https://example.invalid/image.png', 'bounds': [], 'runs': 1},
      {'image': 'data:image/png;base64,AAAA', 'bounds': [], 'runs': 1},
    ]) {
      expect(() => HeatmapData.fromJson(json), throwsFormatException);
    }
  });
}
