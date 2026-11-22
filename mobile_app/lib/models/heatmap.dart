import 'dart:convert';
import 'dart:typed_data';

class HeatmapData {
  final Uint8List imageBytes;
  final List<List<double>> bounds;
  final int runs;

  HeatmapData({
    required this.imageBytes,
    required this.bounds,
    required this.runs,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String;
    const prefix = 'data:image/png;base64,';
    if (!image.startsWith(prefix)) {
      throw const FormatException('Expected a PNG heatmap');
    }
    final bounds = (json['bounds'] as List)
        .map(
          (pair) => (pair as List).map((v) => (v as num).toDouble()).toList(),
        )
        .toList();
    if (bounds.length != 2 || bounds.any((pair) => pair.length != 2)) {
      throw const FormatException('Invalid heatmap bounds');
    }
    return HeatmapData(
      imageBytes: base64Decode(image.substring(prefix.length)),
      bounds: bounds,
      runs: (json['runs'] as num).toInt(),
    );
  }
}
