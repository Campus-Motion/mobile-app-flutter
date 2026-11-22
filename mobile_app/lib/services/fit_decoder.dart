import 'dart:typed_data';

/// Metadata extracted from a Garmin/ANT+ .FIT activity file.
class FitMetadata {
  final String sport;
  final double? durationMinutes;
  final double? distanceKm;
  final int waypointCount;
  final List<Map<String, dynamic>> waypoints;
  final DateTime? startTime;

  const FitMetadata({
    this.sport = 'other',
    this.durationMinutes,
    this.distanceKm,
    this.waypointCount = 0,
    this.waypoints = const [],
    this.startTime,
  });

  @override
  String toString() =>
      'FitMetadata(sport: $sport, durationMinutes: $durationMinutes, distanceKm: $distanceKm, waypointCount: $waypointCount, startTime: $startTime)';
}

class _FitFieldDef {
  final int fieldNum;
  final int size;
  final int baseType;

  const _FitFieldDef(this.fieldNum, this.size, this.baseType);
}

class _FitMsgDef {
  final Endian endian;
  final int globalMsgNum;
  final List<_FitFieldDef> fields;
  final int devFieldsSize;

  const _FitMsgDef(
    this.endian,
    this.globalMsgNum,
    this.fields,
    this.devFieldsSize,
  );
}

/// Lightweight, standalone parser for Garmin/ANT+ FIT files.
class FitDecoder {
  static const int fitEpochUnixSeconds = 631065600; // 1989-12-31 00:00:00 UTC

  /// Parses high-level metadata (sport, duration, distance, start time, waypoints)
  /// from raw .FIT bytes.
  static FitMetadata parseMetadata(Uint8List bytes) {
    if (bytes.length < 14) {
      return const FitMetadata();
    }

    final headerLen = bytes[0];
    if (headerLen < 12 || headerLen > bytes.length) {
      return const FitMetadata();
    }

    // Verify '.FIT' signature at bytes 8-11
    if (bytes[8] != 0x2E ||
        bytes[9] != 0x46 ||
        bytes[10] != 0x49 ||
        bytes[11] != 0x54) {
      return const FitMetadata();
    }

    final bd = ByteData.sublistView(bytes);
    final dataSize = bd.getUint32(4, Endian.little);
    final totalEnd = (headerLen + dataSize > bytes.length)
        ? bytes.length
        : headerLen + dataSize;

    int offset = headerLen;
    final Map<int, _FitMsgDef> definitions = {};

    String detectedSport = 'other';
    double? detectedDurationMinutes;
    double? detectedDistanceKm;
    DateTime? startTime;
    int? firstRecordTimeSec;
    int? lastRecordTimeSec;
    int? lastRecordDistCm;
    final waypoints = <Map<String, dynamic>>[];

    while (offset < totalEnd) {
      final headerByte = bytes[offset++];
      final isCompressed = (headerByte & 0x80) != 0;

      if (isCompressed) {
        final localNum = (headerByte >> 5) & 0x03;
        final defn = definitions[localNum];
        if (defn == null) break;
        int msgSize = defn.devFieldsSize;
        for (final f in defn.fields) {
          msgSize += f.size;
        }
        offset += msgSize;
        continue;
      }

      final isDef = (headerByte & 0x40) != 0;
      final hasDev = (headerByte & 0x20) != 0;
      final localNum = headerByte & 0x0F;

      if (isDef) {
        if (offset + 5 > totalEnd) break;
        offset++; // reserved byte
        final arch = bytes[offset++];
        final endian = arch == 0 ? Endian.little : Endian.big;
        final globalMsgNum = bd.getUint16(offset, endian);
        offset += 2;
        final numFields = bytes[offset++];

        if (offset + (numFields * 3) > totalEnd) break;
        final fields = <_FitFieldDef>[];
        for (int i = 0; i < numFields; i++) {
          final fNum = bytes[offset++];
          final fSize = bytes[offset++];
          final fType = bytes[offset++];
          fields.add(_FitFieldDef(fNum, fSize, fType));
        }

        int devSize = 0;
        if (hasDev) {
          if (offset >= totalEnd) break;
          final devCount = bytes[offset++];
          if (offset + (devCount * 3) > totalEnd) break;
          for (int i = 0; i < devCount; i++) {
            offset++; // field num
            final size = bytes[offset++];
            offset++; // dev index
            devSize += size;
          }
        }

        definitions[localNum] = _FitMsgDef(
          endian,
          globalMsgNum,
          fields,
          devSize,
        );
      } else {
        // Data message
        final defn = definitions[localNum];
        if (defn == null) break;

        final endian = defn.endian;
        final globalMsgNum = defn.globalMsgNum;

        int? latSemi;
        int? lonSemi;
        int? recordTimeSec;
        double? altitudeM;

        for (final f in defn.fields) {
          if (offset + f.size > totalEnd) break;

          if (globalMsgNum == 12) {
            // Sport message
            if (f.fieldNum == 0 && f.size >= 1) {
              final sportVal = bytes[offset];
              final mapped = _mapSport(sportVal);
              if (mapped != 'other') {
                detectedSport = mapped;
              }
            }
          } else if (globalMsgNum == 18) {
            // Session message
            if (f.fieldNum == 5 && f.size >= 1) {
              final sportVal = bytes[offset];
              final mapped = _mapSport(sportVal);
              if (mapped != 'other') {
                detectedSport = mapped;
              }
            } else if (f.fieldNum == 7 && f.size == 4) {
              final rawTime = bd.getUint32(offset, endian);
              if (rawTime > 0 && rawTime != 0xFFFFFFFF) {
                detectedDurationMinutes ??= (rawTime / 1000.0) / 60.0;
              }
            } else if (f.fieldNum == 8 && f.size == 4) {
              final rawTime = bd.getUint32(offset, endian);
              if (rawTime > 0 && rawTime != 0xFFFFFFFF) {
                detectedDurationMinutes = (rawTime / 1000.0) / 60.0;
              }
            } else if (f.fieldNum == 9 && f.size == 4) {
              final rawDist = bd.getUint32(offset, endian);
              if (rawDist > 0 && rawDist != 0xFFFFFFFF) {
                detectedDistanceKm = (rawDist / 100.0) / 1000.0;
              }
            } else if ((f.fieldNum == 2 || f.fieldNum == 253) && f.size == 4) {
              final fitTime = bd.getUint32(offset, endian);
              if (fitTime > 0 && fitTime != 0xFFFFFFFF) {
                final unixSec = fitEpochUnixSeconds + fitTime;
                final parsedTime = DateTime.fromMillisecondsSinceEpoch(
                  unixSec * 1000,
                  isUtc: true,
                ).toLocal();
                if (f.fieldNum == 2 || startTime == null) {
                  startTime = parsedTime;
                }
              }
            }
          } else if (globalMsgNum == 20) {
            // Record message (GPS point)
            if (f.fieldNum == 0 && f.size == 4) {
              latSemi = bd.getInt32(offset, endian);
            } else if (f.fieldNum == 1 && f.size == 4) {
              lonSemi = bd.getInt32(offset, endian);
            } else if (f.fieldNum == 2 && f.size == 2) {
              final rawAlt = bd.getUint16(offset, endian);
              if (rawAlt != 0xFFFF) {
                altitudeM ??= (rawAlt / 5.0) - 500.0;
              }
            } else if (f.fieldNum == 5 && f.size == 4) {
              final rawDist = bd.getUint32(offset, endian);
              if (rawDist > 0 && rawDist != 0xFFFFFFFF) {
                lastRecordDistCm = rawDist;
              }
            } else if (f.fieldNum == 78 && f.size == 4) {
              final rawAlt = bd.getUint32(offset, endian);
              if (rawAlt != 0xFFFFFFFF) {
                altitudeM = (rawAlt / 5.0) - 500.0;
              }
            } else if (f.fieldNum == 253 && f.size == 4) {
              recordTimeSec = bd.getUint32(offset, endian);
              if (recordTimeSec > 0 && recordTimeSec != 0xFFFFFFFF) {
                firstRecordTimeSec ??= recordTimeSec;
                lastRecordTimeSec = recordTimeSec;
              }
            }
          }

          offset += f.size;
        }

        offset += defn.devFieldsSize;

        if (globalMsgNum == 20 &&
            latSemi != null &&
            lonSemi != null &&
            latSemi != 0x7FFFFFFF &&
            lonSemi != 0x7FFFFFFF) {
          final lat = latSemi * (180.0 / 2147483648.0);
          final lon = lonSemi * (180.0 / 2147483648.0);
          final recDate = recordTimeSec != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (fitEpochUnixSeconds + recordTimeSec) * 1000,
                  isUtc: true,
                ).toIso8601String()
              : DateTime.now().toUtc().toIso8601String();

          waypoints.add(<String, dynamic>{
            'latitude': lat,
            'longitude': lon,
            'recorded_at': recDate,
            'sequence_order': waypoints.length + 1,
            'altitude_m': ?altitudeM,
          });
        }
      }
    }

    if (startTime == null && firstRecordTimeSec != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(
        (fitEpochUnixSeconds + firstRecordTimeSec) * 1000,
        isUtc: true,
      ).toLocal();
    }
    if (detectedDurationMinutes == null &&
        firstRecordTimeSec != null &&
        lastRecordTimeSec != null &&
        lastRecordTimeSec > firstRecordTimeSec) {
      detectedDurationMinutes = (lastRecordTimeSec - firstRecordTimeSec) / 60.0;
    }
    if (detectedDistanceKm == null &&
        lastRecordDistCm != null &&
        lastRecordDistCm > 0) {
      detectedDistanceKm = (lastRecordDistCm / 100.0) / 1000.0;
    }

    return FitMetadata(
      sport: detectedSport,
      durationMinutes: detectedDurationMinutes,
      distanceKm: detectedDistanceKm,
      waypointCount: waypoints.length,
      waypoints: List<Map<String, dynamic>>.unmodifiable(waypoints),
      startTime: startTime,
    );
  }

  static String _mapSport(int sportId) {
    switch (sportId) {
      case 1:
        return 'run';
      case 2:
        return 'cycle';
      case 11:
        return 'walk';
      case 17:
        return 'hike';
      case 5:
        return 'swim';
      default:
        return 'other';
    }
  }
}
