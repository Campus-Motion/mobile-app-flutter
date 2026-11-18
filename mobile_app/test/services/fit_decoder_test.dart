import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/fit_decoder.dart';

void main() {
  group('FitDecoder unit tests', () {
    test('returns default metadata for empty or corrupt bytes', () {
      final empty = FitDecoder.parseMetadata(Uint8List(0));
      expect(empty.sport, 'other');
      expect(empty.waypointCount, 0);

      final short = FitDecoder.parseMetadata(Uint8List.fromList([14, 1, 2, 3]));
      expect(short.sport, 'other');

      final invalidSig = FitDecoder.parseMetadata(
        Uint8List.fromList(List.filled(14, 0)),
      );
      expect(invalidSig.sport, 'other');
    });

    test('decodes sport message (running -> run)', () {
      // Build minimal FIT buffer with sport msg (global 12)
      final dataBytes = <int>[
        // Def msg for local 0 -> global 12 (sport)
        0x40, 0x00, 0x00, 0x0C, 0x00, 0x01,
        0x00, 0x01, 0x00, // field 0 (sport), size 1
        // Data msg for local 0: sport = 1 (run)
        0x00, 0x01,
      ];

      final header = <int>[
        14, 0x10, 0x88, 0x08,
        dataBytes.length, 0x00, 0x00, 0x00, // data size
        0x2E, 0x46, 0x49, 0x54, // .FIT
        0x00, 0x00,
      ];

      final fitBytes = Uint8List.fromList([...header, ...dataBytes]);
      final meta = FitDecoder.parseMetadata(fitBytes);

      expect(meta.sport, 'run');
    });

    test('decodes session message (cycle, duration and distance)', () {
      // Build data with session msg (global 18)
      // Duration: 1800000 ms (30 min) -> 0x001B7740 -> [0x40, 0x77, 0x1B, 0x00]
      // Distance: 1200000 cm (12 km) -> 0x00124F80 -> [0x80, 0x4F, 0x12, 0x00]
      final durBytes = [0x40, 0x77, 0x1B, 0x00];
      final distBytes = [0x80, 0x4F, 0x12, 0x00];
      final timeBytes = [0x00, 0x00, 0x00, 0x01]; // timestamp

      final dataBytes = <int>[
        // Def msg for local 0 -> global 18 (session)
        0x40, 0x00, 0x00, 0x12, 0x00, 0x04,
        0x05, 0x01, 0x00, // field 5 (sport), size 1
        0x07, 0x04, 0x86, // field 7 (elapsed time), size 4
        0x09, 0x04, 0x86, // field 9 (distance), size 4
        0xFD, 0x04, 0x86, // field 253 (timestamp), size 4
        // Data msg for local 0:
        0x00,
        0x02, // sport = 2 (cycling)
        ...durBytes,
        ...distBytes,
        ...timeBytes,
      ];

      final header = <int>[
        14,
        0x10,
        0x88,
        0x08,
        dataBytes.length,
        0x00,
        0x00,
        0x00,
        0x2E,
        0x46,
        0x49,
        0x54,
        0x00,
        0x00,
      ];

      final fitBytes = Uint8List.fromList([...header, ...dataBytes]);
      final meta = FitDecoder.parseMetadata(fitBytes);

      expect(meta.sport, 'cycle');
      expect(meta.durationMinutes, closeTo(30.0, 0.01));
      expect(meta.distanceKm, closeTo(12.0, 0.01));
      expect(meta.startTime, isNotNull);
    });

    test('decodes record messages into GPS waypoints', () {
      final latBytes = [0xDF, 0x03, 0x14, 0x21];
      final lonBytes = [0x60, 0x37, 0xAB, 0x04];

      final dataBytes = <int>[
        // Def msg for local 0 -> global 20 (record)
        0x40, 0x00, 0x00, 0x14, 0x00, 0x02,
        0x00, 0x04, 0x85, // field 0 (lat), size 4
        0x01, 0x04, 0x85, // field 1 (lon), size 4
        // Data msg 1
        0x00,
        ...latBytes,
        ...lonBytes,
        // Data msg 2
        0x00,
        ...latBytes,
        ...lonBytes,
      ];

      final header = <int>[
        14,
        0x10,
        0x88,
        0x08,
        dataBytes.length,
        0x00,
        0x00,
        0x00,
        0x2E,
        0x46,
        0x49,
        0x54,
        0x00,
        0x00,
      ];

      final fitBytes = Uint8List.fromList([...header, ...dataBytes]);
      final meta = FitDecoder.parseMetadata(fitBytes);

      expect(meta.waypointCount, 2);
      expect(meta.waypoints.length, 2);
      expect(meta.waypoints[0]['latitude'], closeTo(46.516, 0.01));
      expect(meta.waypoints[0]['longitude'], closeTo(6.566, 0.01));
    });
  });
}
