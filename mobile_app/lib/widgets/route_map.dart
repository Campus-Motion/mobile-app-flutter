import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/stat_item.dart';

final Uint8List _kTransparentPng = Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  10,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

class _TestTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
}

double _minMovingSpeedMs(String? activityType) {
  switch (activityType?.toLowerCase().trim()) {
    case 'swim':
      return 0.15;
    case 'walk':
    case 'hike':
      return 0.30;
    case 'run':
    case 'cycle':
    default:
      return 0.50;
  }
}

double _maxValidSpeedMs(String? activityType) {
  switch (activityType?.toLowerCase().trim()) {
    case 'cycle':
      return 28.0; // Up to ~100 km/h for road cycling descents
    case 'run':
      return 12.0; // Up to ~43 km/h
    case 'walk':
    case 'hike':
      return 6.0; // Up to ~21.6 km/h
    case 'swim':
      return 4.0; // Up to ~14.4 km/h
    default:
      return 25.0;
  }
}

double _interpolatePercentile(List<double> sorted, double percentile) {
  if (sorted.isEmpty) return 0.0;
  if (sorted.length == 1) return sorted.first;
  final pos = (percentile / 100.0) * (sorted.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  final frac = pos - lo;
  return sorted[lo] + (sorted[hi] - sorted[lo]) * frac;
}

List<double> _uniformFilter1dNearest(List<double> input, int size) {
  final n = input.length;
  if (size <= 1 || n <= 1) return input;
  final half = size ~/ 2;
  final window = 2 * half + 1;
  final out = List<double>.filled(n, 0.0);
  for (int i = 0; i < n; i++) {
    double sum = 0.0;
    for (int k = -half; k <= half; k++) {
      final idx = (i + k).clamp(0, n - 1);
      sum += input[idx];
    }
    out[i] = sum / window;
  }
  return out;
}

class _CoursePoint {
  final LatLng latLng;
  final double speedMs;
  final double paceMinKm;

  const _CoursePoint({
    required this.latLng,
    required this.speedMs,
    required this.paceMinKm,
  });
}

class _CourseAnalysis {
  final List<_CoursePoint> records;
  final List<Polyline> polylines;
  final double minPace;
  final double maxPace;

  const _CourseAnalysis({
    required this.records,
    required this.polylines,
    required this.minPace,
    required this.maxPace,
  });

  static double _haversineMeters(LatLng a, LatLng b) {
    const double earthR = 6378137.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final dLon = (b.longitude - a.longitude) * (math.pi / 180.0);
    final lat1 = a.latitude * (math.pi / 180.0);
    final lat2 = b.latitude * (math.pi / 180.0);
    final sinDLat = math.sin(dLat / 2.0);
    final sinDLon = math.sin(dLon / 2.0);
    final h =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    return 2.0 *
        earthR *
        math.atan2(math.sqrt(h), math.sqrt(math.max(0.0, 1.0 - h)));
  }

  static Color paceColormap(double pace, double minPace, double maxPace) {
    final span = maxPace - minPace;
    final t = span > 1e-6 ? ((pace - minPace) / span).clamp(0.0, 1.0) : 0.5;
    if (t <= 0.5) {
      return Color.lerp(AppColors.paceFast, AppColors.paceMedium, t * 2.0)!;
    } else {
      return Color.lerp(
        AppColors.paceMedium,
        AppColors.paceSlow,
        (t - 0.5) * 2.0,
      )!;
    }
  }

  static String formatPace(double paceDec) {
    final totalSec = (paceDec * 60.0).round();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static _CourseAnalysis fromWaypoints(
    List<Waypoint> waypoints, {
    String? activityType,
  }) {
    final n = waypoints.length;
    final minSpeed = _minMovingSpeedMs(activityType);
    final maxSpeed = _maxValidSpeedMs(activityType);
    final segCount = math.max(0, n - 1);
    final rawSegSpeeds = List<double>.filled(segCount, 0.0);

    for (int i = 0; i < segCount; i++) {
      final p1 = LatLng(waypoints[i].latitude, waypoints[i].longitude);
      final p2 = LatLng(waypoints[i + 1].latitude, waypoints[i + 1].longitude);
      final d = _haversineMeters(p1, p2);
      final dt =
          waypoints[i + 1].recordedAt
              .difference(waypoints[i].recordedAt)
              .inMilliseconds /
          1000.0;
      rawSegSpeeds[i] = dt > 0 ? d / dt : 0.0;
    }

    // Smooth 1-second GPS speed jitter over a rolling window on dense .fit
    // tracks while keeping 100% of original GPS points intact.
    final int smoothWindow = segCount >= 60 ? 11 : (segCount >= 15 ? 5 : 1);
    final segSpeeds = smoothWindow > 1
        ? _uniformFilter1dNearest(rawSegSpeeds, smoothWindow)
        : rawSegSpeeds;

    final activeMovingPaces = <double>[];
    for (int i = 0; i < segCount; i++) {
      final speed = segSpeeds[i];
      if (speed > minSpeed && speed <= maxSpeed) {
        activeMovingPaces.add(1000.0 / (speed * 60.0));
      }
    }

    // Dynamic 5th-95th percentile pace scale so cycling, running, walking,
    // hiking, and swimming each span the full green-yellow-red gradient.
    double minPace = 3.5;
    double maxPace = 7.5;
    if (activeMovingPaces.isNotEmpty) {
      activeMovingPaces.sort();
      final p05 = _interpolatePercentile(activeMovingPaces, 5.0);
      final p95 = _interpolatePercentile(activeMovingPaces, 95.0);
      if (p95 - p05 >= 0.25) {
        minPace = p05;
        maxPace = p95;
      } else {
        final mid = _interpolatePercentile(activeMovingPaces, 50.0);
        minPace = math.max(0.5, mid * 0.85);
        maxPace = math.max(minPace + 0.5, mid * 1.15);
      }
    }

    final vertexSpeeds = List<double>.filled(n, 0.0);
    if (n > 1) {
      vertexSpeeds[0] = segSpeeds[0];
      for (int i = 1; i < n - 1; i++) {
        vertexSpeeds[i] = 0.5 * (segSpeeds[i - 1] + segSpeeds[i]);
      }
      vertexSpeeds[n - 1] = segSpeeds[n - 2];
    }

    final records = <_CoursePoint>[];
    for (int i = 0; i < n; i++) {
      final double speedMs = vertexSpeeds[i];
      final double pace = speedMs > minSpeed
          ? (1000.0 / (speedMs * 60.0)).clamp(minPace, maxPace)
          : maxPace;
      records.add(
        _CoursePoint(
          latLng: LatLng(waypoints[i].latitude, waypoints[i].longitude),
          speedMs: speedMs,
          paceMinKm: pace,
        ),
      );
    }

    // 1 Polyline per consecutive GPS pair [pt1, pt2] with a single solid color
    // (exact port of Trail/onecourse.py without GPU gradient shader overhead).
    final polylines = <Polyline>[];
    for (int i = 0; i < records.length - 1; i++) {
      final pt1 = records[i];
      final pt2 = records[i + 1];
      final avgPace = (pt1.paceMinKm + pt2.paceMinKm) / 2.0;

      polylines.add(
        Polyline(
          points: [pt1.latLng, pt2.latLng],
          color: paceColormap(
            avgPace,
            minPace,
            maxPace,
          ).withValues(alpha: 0.90),
          strokeWidth: 5.0,
        ),
      );
    }

    return _CourseAnalysis(
      records: records,
      polylines: polylines,
      minPace: minPace,
      maxPace: maxPace,
    );
  }
}

class _HeatmapRasterResult {
  final Uint8List pngBytes;
  final LatLngBounds bounds;
  final int runs;
  final int minIntensity;
  final double saturation;

  const _HeatmapRasterResult({
    required this.pngBytes,
    required this.bounds,
    required this.runs,
    required this.minIntensity,
    required this.saturation,
  });
}

/// Port of Trail/heatmap_v2.py: continuous line rasterization on a fine
/// metric Web Mercator grid, 2D Gaussian blur, 98th-percentile normalization,
/// gamma compression, and monochrome color LUT parameterized by sport color.
class _TrailHeatmapRenderer {
  static const double _earthR = 6378137.0;
  static const double _defaultPixelM = 2.0;
  static const double _blurM = 5.0;
  static const int _smoothPoints = 3;
  static const int _maxSidePx = 1600;
  static const double _maxGapS = 15.0;
  static const double _percentile = 98.0;
  static const double _gamma = 0.4;
  static const double _opacity = 0.95;

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);

  static (double, double) _project(double lat, double lon, double scale) {
    final x = _earthR * _degToRad(lon) * scale;
    final y =
        _earthR *
        math.log(math.tan(math.pi / 4.0 + _degToRad(lat) / 2.0)) *
        scale;
    return (x, y);
  }

  static LatLng _unproject(double x, double y, double scale) {
    final lon = _radToDeg(x / (_earthR * scale));
    final lat = _radToDeg(
      2.0 * math.atan(math.exp(y / (_earthR * scale))) - math.pi / 2.0,
    );
    return LatLng(lat, lon);
  }

  static _HeatmapRasterResult? compute(
    List<List<Waypoint>> rawTracks,
    Color baseColor, {
    String? activityType,
  }) {
    final validTracks = rawTracks.where((t) => t.length >= 2).toList();
    if (validTracks.isEmpty) return null;

    final minSpeedMs = _minMovingSpeedMs(activityType);
    final maxSpeedMs = _maxValidSpeedMs(activityType);

    double sumLat = 0.0;
    int countPts = 0;
    for (final track in validTracks) {
      for (final w in track) {
        sumLat += w.latitude;
        countPts++;
      }
    }
    if (countPts == 0) return null;

    final refLat = sumLat / countPts;
    final scale = math.cos(_degToRad(refLat));

    final projTracks = <(List<double>, List<double>, List<double>)>[];
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final track in validTracks) {
      final sorted = List<Waypoint>.from(track)
        ..sort((a, b) {
          final cmp = a.recordedAt.compareTo(b.recordedAt);
          return cmp != 0 ? cmp : a.sequenceOrder.compareTo(b.sequenceOrder);
        });
      final t0 = sorted.first.recordedAt;
      final t = List<double>.generate(
        sorted.length,
        (i) => sorted[i].recordedAt.difference(t0).inMilliseconds / 1000.0,
      );
      var lat = List<double>.generate(sorted.length, (i) => sorted[i].latitude);
      var lon = List<double>.generate(
        sorted.length,
        (i) => sorted[i].longitude,
      );

      if (_smoothPoints > 1 && lat.length >= _smoothPoints) {
        lat = _uniformFilter1dNearest(lat, _smoothPoints);
        lon = _uniformFilter1dNearest(lon, _smoothPoints);
      }

      final xs = List<double>.filled(lat.length, 0.0);
      final ys = List<double>.filled(lat.length, 0.0);
      for (int i = 0; i < lat.length; i++) {
        final (px, py) = _project(lat[i], lon[i], scale);
        xs[i] = px;
        ys[i] = py;
        if (px < minX) minX = px;
        if (px > maxX) maxX = px;
        if (py < minY) minY = py;
        if (py > maxY) maxY = py;
      }
      projTracks.add((t, xs, ys));
    }

    double pixelM = _defaultPixelM;
    final extent = math.max(maxX - minX, maxY - minY);
    if (extent / pixelM > _maxSidePx) {
      pixelM = extent / _maxSidePx;
    }
    if (pixelM <= 0) pixelM = _defaultPixelM;

    final double margin = 4.0 * _blurM + 2.0 * pixelM;
    final double sigmaPx = _blurM / pixelM;

    final double x0 = minX - margin;
    final double ytop = maxY + margin;
    final int w = math.max(1, ((maxX + margin - x0) / pixelM).ceil());
    final int h = math.max(1, ((ytop - (minY - margin)) / pixelM).ceil());

    final grid = Float32List(w * h);

    for (final (t, x, y) in projTracks) {
      final segCount = x.length - 1;
      if (segCount <= 0) continue;

      final dxs = List<double>.filled(segCount, 0.0);
      final dys = List<double>.filled(segCount, 0.0);
      final dists = List<double>.filled(segCount, 0.0);
      final strictOk = List<bool>.filled(segCount, false);
      bool hasAnyStrict = false;

      for (int i = 0; i < segCount; i++) {
        final dx = x[i + 1] - x[i];
        final dy = y[i + 1] - y[i];
        final dt = t[i + 1] - t[i];
        final dist = math.sqrt(dx * dx + dy * dy);
        dxs[i] = dx;
        dys[i] = dy;
        dists[i] = dist;
        final speed = dt > 0 ? dist / dt : double.infinity;
        final ok =
            dt > 0 &&
            dt <= _maxGapS &&
            speed <= maxSpeedMs &&
            speed >= minSpeedMs;
        strictOk[i] = ok;
        if (ok) hasAnyStrict = true;
      }

      for (int i = 0; i < segCount; i++) {
        final useSegment = hasAnyStrict ? strictOk[i] : dists[i] > 0;
        if (!useSegment) continue;

        final dist = dists[i];
        final n = math.max(1, (dist / (pixelM * 0.5)).ceil());
        final weight = (dist / n) / pixelM;
        final xStart = x[i];
        final yStart = y[i];
        final dx = dxs[i];
        final dy = dys[i];

        for (int k = 1; k <= n; k++) {
          final f = k / n;
          final xs = xStart + dx * f;
          final ys = yStart + dy * f;
          final ix = ((xs - x0) / pixelM).floor();
          final iy = ((ytop - ys) / pixelM).floor();
          if (ix >= 0 && ix < w && iy >= 0 && iy < h) {
            grid[iy * w + ix] += weight;
          }
        }
      }
    }

    final blurred = _gaussianFilter2d(grid, w, h, sigmaPx);
    final linePeak = 1.0 / (math.sqrt(2.0 * math.pi) * sigmaPx);

    final core = <double>[];
    final allNonZero = <double>[];
    for (int i = 0; i < blurred.length; i++) {
      final val = blurred[i];
      if (val > 0.5 * linePeak) {
        core.add(val);
      }
      if (val > 0) {
        allNonZero.add(val);
      }
    }

    final ref = core.isNotEmpty ? core : allNonZero;
    double p98 = linePeak;
    if (ref.isNotEmpty) {
      ref.sort();
      p98 = _interpolatePercentile(ref, _percentile);
    }
    final cap = math.max(p98, linePeak);
    final saturation = math.max(1.0, cap / linePeak);

    // 3-stop monochrome palette derived from baseColor (exact port of
    // heatmap_v2.py PALETTES["rouge écriture logo"] = [0.0: 20% base, 0.6: base, 1.0: 82% towards white])
    final c0 = Color.from(
      alpha: 1.0,
      red: baseColor.r * 0.20,
      green: baseColor.g * 0.20,
      blue: baseColor.b * 0.20,
    );
    final c1 = baseColor;
    final c2 = Color.lerp(baseColor, AppColors.cardBackground, 0.82)!;
    final lutR = Uint8List(256);
    final lutG = Uint8List(256);
    final lutB = Uint8List(256);
    for (int i = 0; i < 256; i++) {
      final t = i / 255.0;
      final c = t <= 0.6
          ? Color.lerp(c0, c1, t / 0.6)!
          : Color.lerp(c1, c2, (t - 0.6) / 0.4)!;
      lutR[i] = (c.r * 255.0).round().clamp(0, 255);
      lutG[i] = (c.g * 255.0).round().clamp(0, 255);
      lutB[i] = (c.b * 255.0).round().clamp(0, 255);
    }

    final rgba = Uint8List(w * h * 4);
    final threshold = 0.05 * linePeak;
    for (int i = 0; i < blurred.length; i++) {
      final val = blurred[i];
      if (val < threshold) continue;
      final vNorm = (val / cap).clamp(0.0, 1.0);
      final vGamma = math.pow(vNorm, _gamma).toDouble();
      final lutIdx = (vGamma * 255.0).floor().clamp(0, 255);
      final alpha = ((vGamma * 3.0).clamp(0.0, 1.0) * 255.0 * _opacity)
          .floor()
          .clamp(0, 255);
      final base = i * 4;
      rgba[base] = lutR[lutIdx];
      rgba[base + 1] = lutG[lutIdx];
      rgba[base + 2] = lutB[lutIdx];
      rgba[base + 3] = alpha;
    }

    final southWest = _unproject(x0, ytop - h * pixelM, scale);
    final northEast = _unproject(x0 + w * pixelM, ytop, scale);
    final bounds = LatLngBounds(southWest, northEast);
    final pngBytes = _PngEncoder.encodeRgba(w, h, rgba);

    return _HeatmapRasterResult(
      pngBytes: pngBytes,
      bounds: bounds,
      runs: validTracks.length,
      minIntensity: 1,
      saturation: saturation,
    );
  }

  static Float32List _gaussianFilter2d(
    Float32List src,
    int w,
    int h,
    double sigma,
  ) {
    final radius = (3.0 * sigma).ceil();
    final kSize = 2 * radius + 1;
    final kernel = Float32List(kSize);
    double sum = 0.0;
    for (int d = -radius; d <= radius; d++) {
      final weight = math.exp(-0.5 * (d / sigma) * (d / sigma));
      kernel[d + radius] = weight;
      sum += weight;
    }
    for (int i = 0; i < kSize; i++) {
      kernel[i] /= sum;
    }

    final temp = Float32List(w * h);
    for (int y = 0; y < h; y++) {
      final rowOffset = y * w;
      for (int x = 0; x < w; x++) {
        double acc = 0.0;
        for (int d = -radius; d <= radius; d++) {
          final nx = x + d;
          if (nx >= 0 && nx < w) {
            acc += src[rowOffset + nx] * kernel[d + radius];
          }
        }
        temp[rowOffset + x] = acc;
      }
    }

    final dst = Float32List(w * h);
    for (int y = 0; y < h; y++) {
      final rowOffset = y * w;
      for (int x = 0; x < w; x++) {
        double acc = 0.0;
        for (int d = -radius; d <= radius; d++) {
          final ny = y + d;
          if (ny >= 0 && ny < h) {
            acc += temp[ny * w + x] * kernel[d + radius];
          }
        }
        dst[rowOffset + x] = acc;
      }
    }
    return dst;
  }
}

/// Pure-Dart RGBA PNG encoder using uncompressed ZLIB/DEFLATE blocks.
class _PngEncoder {
  static final Uint32List _crcTable = _buildCrcTable();

  static Uint32List _buildCrcTable() {
    final table = Uint32List(256);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  static int _crc32(List<int> type, Uint8List data, int offset, int length) {
    int c = 0xFFFFFFFF;
    for (int i = 0; i < type.length; i++) {
      c = _crcTable[(c ^ type[i]) & 0xFF] ^ (c >>> 8);
    }
    for (int i = 0; i < length; i++) {
      c = _crcTable[(c ^ data[offset + i]) & 0xFF] ^ (c >>> 8);
    }
    return (c ^ 0xFFFFFFFF) >>> 0;
  }

  static void _writeUint32BE(BytesBuilder builder, int value) {
    builder.addByte((value >>> 24) & 0xFF);
    builder.addByte((value >>> 16) & 0xFF);
    builder.addByte((value >>> 8) & 0xFF);
    builder.addByte(value & 0xFF);
  }

  static void _writeChunk(
    BytesBuilder builder,
    List<int> type,
    Uint8List data,
  ) {
    _writeUint32BE(builder, data.length);
    builder.add(type);
    if (data.isNotEmpty) {
      builder.add(data);
    }
    final crc = _crc32(type, data, 0, data.length);
    _writeUint32BE(builder, crc);
  }

  static Uint8List encodeRgba(int width, int height, Uint8List rgba) {
    final rowStride = width * 4;
    final rawLen = height * (1 + rowStride);
    final raw = Uint8List(rawLen);

    int dst = 0;
    int src = 0;
    for (int y = 0; y < height; y++) {
      raw[dst++] = 0; // Filter type 0 (None)
      raw.setRange(dst, dst + rowStride, rgba, src);
      dst += rowStride;
      src += rowStride;
    }

    // Adler-32 checksum over raw scanlines
    int s1 = 1;
    int s2 = 0;
    for (int i = 0; i < rawLen; i++) {
      s1 = (s1 + raw[i]) % 65521;
      s2 = (s2 + s1) % 65521;
    }
    final adler = ((s2 << 16) | s1) >>> 0;

    // Zlib stream with stored (BTYPE=00) DEFLATE blocks
    final zlibBuilder = BytesBuilder(copy: false);
    zlibBuilder.addByte(0x78);
    zlibBuilder.addByte(0x01);

    int offset = 0;
    while (offset < rawLen) {
      final blockLen = math.min(65535, rawLen - offset);
      final isLast = (offset + blockLen) >= rawLen;
      zlibBuilder.addByte(isLast ? 0x01 : 0x00);
      zlibBuilder.addByte(blockLen & 0xFF);
      zlibBuilder.addByte((blockLen >>> 8) & 0xFF);
      final nlen = (~blockLen) & 0xFFFF;
      zlibBuilder.addByte(nlen & 0xFF);
      zlibBuilder.addByte((nlen >>> 8) & 0xFF);
      zlibBuilder.add(Uint8List.sublistView(raw, offset, offset + blockLen));
      offset += blockLen;
    }
    _writeUint32BE(zlibBuilder, adler);
    final idatData = zlibBuilder.toBytes();

    final pngBuilder = BytesBuilder(copy: false);
    // PNG signature
    pngBuilder.add(const [137, 80, 78, 71, 13, 10, 26, 10]);

    // IHDR chunk
    final ihdr = Uint8List(13);
    final ihdrBd = ByteData.sublistView(ihdr);
    ihdrBd.setUint32(0, width, Endian.big);
    ihdrBd.setUint32(4, height, Endian.big);
    ihdr[8] = 8; // bit depth
    ihdr[9] = 6; // RGBA
    ihdr[10] = 0; // compression
    ihdr[11] = 0; // filter
    ihdr[12] = 0; // interlace
    _writeChunk(pngBuilder, const [73, 72, 68, 82], ihdr);

    // IDAT chunk
    _writeChunk(pngBuilder, const [73, 68, 65, 84], idatData);

    // IEND chunk
    _writeChunk(pngBuilder, const [73, 69, 78, 68], Uint8List(0));

    return pngBuilder.toBytes();
  }
}

enum _MapBaseStyle {
  dark(
    label: 'Dark',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: 16,
    attribution: '© Esri',
    icon: Icons.dark_mode_outlined,
  ),
  standard(
    label: 'Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxNativeZoom: 19,
    attribution: '© OpenStreetMap',
    icon: Icons.map_outlined,
  ),
  satellite(
    label: 'Satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: 17,
    attribution: '© Esri',
    icon: Icons.satellite_alt_outlined,
  );

  final String label;
  final String urlTemplate;
  final int maxNativeZoom;
  final String attribution;
  final IconData icon;

  const _MapBaseStyle({
    required this.label,
    required this.urlTemplate,
    required this.maxNativeZoom,
    required this.attribution,
    required this.icon,
  });
}

/// Reusable map widget displaying either:
/// - A single GPS workout in the style of `Trail/onecourse.py` (pace-colored
///   micro-segments from green #2DC653 to yellow #FFD166 to red #EF233C with
///   adaptive multi-sport percentile bounds, start/finish markers, and a
///   Campus Motion styled Pace Scale card).
/// - A multi-activity Strava-style raster heatmap in the style of
///   `Trail/heatmap_v2.py` (Gaussian-blurred continuous raster overlay colored
///   by discipline `routeColor` on top of selectable base map tiles — Dark by
///   default, Standard OpenStreetMap, or Satellite — with a Campus Motion
///   styled summary card showing workouts, min intensity, and max intensity).
class RouteMap extends StatefulWidget {
  final List<Waypoint> waypoints;
  final List<List<Waypoint>>? tracks;
  final double height;
  final Color routeColor;
  final String? activityType;
  final bool interactive;
  final TileProvider? tileProvider;

  const RouteMap({
    super.key,
    this.waypoints = const [],
    this.tracks,
    this.height = 260.0,
    this.routeColor = AppColors.primary,
    this.activityType,
    this.interactive = true,
    this.tileProvider,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  _MapBaseStyle _selectedStyle = _MapBaseStyle.dark;
  _CourseAnalysis? _singleAnalysis;
  _HeatmapRasterResult? _heatmapRaster;
  List<Polyline> _polylines = const [];
  List<Marker> _markers = const [];
  List<LatLng> _allPoints = const [];

  @override
  void initState() {
    super.initState();
    _recomputeMapData();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeColor != widget.routeColor ||
        oldWidget.activityType != widget.activityType ||
        !_sameWaypoints(oldWidget.waypoints, widget.waypoints) ||
        !_sameTracks(oldWidget.tracks, widget.tracks)) {
      _recomputeMapData();
    }
  }

  static bool _sameWaypoints(List<Waypoint> a, List<Waypoint> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i]) &&
          (a[i].latitude != b[i].latitude ||
              a[i].longitude != b[i].longitude ||
              a[i].recordedAt != b[i].recordedAt)) {
        return false;
      }
    }
    return true;
  }

  static bool _sameTracks(List<List<Waypoint>>? a, List<List<Waypoint>>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_sameWaypoints(a[i], b[i])) return false;
    }
    return true;
  }

  void _recomputeMapData() {
    final isHeatmapMode = widget.tracks != null;
    final effectiveTracks =
        widget.tracks ??
        (widget.waypoints.isNotEmpty ? [widget.waypoints] : []);
    final allPoints = <LatLng>[];
    for (final track in effectiveTracks) {
      for (final w in track) {
        allPoints.add(LatLng(w.latitude, w.longitude));
      }
    }

    _allPoints = allPoints;
    _singleAnalysis = null;
    _heatmapRaster = null;
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    if (allPoints.isEmpty) {
      _polylines = const [];
      _markers = const [];
      return;
    }

    if (isHeatmapMode) {
      _heatmapRaster = _TrailHeatmapRenderer.compute(
        effectiveTracks,
        widget.routeColor,
        activityType: widget.activityType,
      );
    } else {
      final analysis = _CourseAnalysis.fromWaypoints(
        widget.waypoints,
        activityType: widget.activityType,
      );
      _singleAnalysis = analysis;
      polylines.addAll(analysis.polylines);

      final firstPoint = LatLng(
        widget.waypoints.first.latitude,
        widget.waypoints.first.longitude,
      );
      markers.add(
        Marker(
          point: firstPoint,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.paceFast,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBackground, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 16,
              color: AppColors.cardBackground,
            ),
          ),
        ),
      );

      if (widget.waypoints.length > 1) {
        final lastPoint = LatLng(
          widget.waypoints.last.latitude,
          widget.waypoints.last.longitude,
        );
        markers.add(
          Marker(
            point: lastPoint,
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.paceSlow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBackground, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flag,
                size: 16,
                color: AppColors.cardBackground,
              ),
            ),
          ),
        );
      }
    }

    _polylines = polylines;
    _markers = markers;
  }

  Widget _buildSingleCoursePaceCard(_CourseAnalysis analysis) {
    final paceMinStr = _CourseAnalysis.formatPace(analysis.minPace);
    final paceMidStr = _CourseAnalysis.formatPace(
      (analysis.minPace + analysis.maxPace) / 2.0,
    );
    final paceMaxStr = _CourseAnalysis.formatPace(analysis.maxPace);

    return AppCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pace Scale (min/km)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  AppColors.paceFast,
                  AppColors.paceMedium,
                  AppColors.paceSlow,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                paceMinStr,
                style: const TextStyle(
                  color: AppColors.paceFast,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                paceMidStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                paceMaxStr,
                style: const TextStyle(
                  color: AppColors.paceSlow,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapInfoBox(_HeatmapRasterResult heatmap) {
    final maxPassages = heatmap.saturation.round();
    return AppCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StatItem(
                label: 'Analyzed workouts',
                value: '${heatmap.runs}',
                valueColor: widget.routeColor,
              ),
            ),
          ),
          Container(height: 36, width: 1, color: AppColors.divider),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StatItem(
                label: 'Min intensity',
                value: '${heatmap.minIntensity}',
                unit: heatmap.minIntensity == 1 ? 'passage' : 'passages',
                valueColor: widget.routeColor,
              ),
            ),
          ),
          Container(height: 36, width: 1, color: AppColors.divider),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: StatItem(
                label: 'Max intensity',
                value: '$maxPassages',
                unit: maxPassages == 1 ? 'passage' : 'passages',
                valueColor: widget.routeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectMapStyle(_MapBaseStyle style) {
    if (_selectedStyle == style) return;
    setState(() {
      _selectedStyle = style;
    });
  }

  Widget _buildFlutterMap({
    required CameraFit cameraFit,
    required TileProvider? effectiveTileProvider,
    required _MapBaseStyle style,
    required bool interactive,
    required _HeatmapRasterResult? heatmapRaster,
    required List<Polyline> polylines,
    required List<Marker> markers,
  }) {
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: cameraFit,
        backgroundColor: style == _MapBaseStyle.dark
            ? AppColors.textPrimary
            : AppColors.surfaceLight,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          key: ValueKey(style),
          urlTemplate: style.urlTemplate,
          maxNativeZoom: style.maxNativeZoom,
          userAgentPackageName: 'ch.campusmotion.app',
          tileProvider: effectiveTileProvider,
        ),
        if (heatmapRaster != null)
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: heatmapRaster.bounds,
                imageProvider: MemoryImage(heatmapRaster.pngBytes),
                opacity: 1.0,
              ),
            ],
          ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildStyleSelectorButton({
    required _MapBaseStyle selectedStyle,
    required ValueChanged<_MapBaseStyle> onSelected,
  }) {
    return Material(
      color: AppColors.cardBackground.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: PopupMenuButton<_MapBaseStyle>(
        tooltip: 'Map style',
        initialValue: selectedStyle,
        onSelected: onSelected,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        itemBuilder: (_) => _MapBaseStyle.values.map((style) {
          final isSelected = style == selectedStyle;
          return PopupMenuItem<_MapBaseStyle>(
            value: style,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  style.icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 5),
              Text(
                selectedStyle.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributionBadge(_MapBaseStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        style.attribution,
        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
    );
  }

  void _openFullscreenMap(
    BuildContext context, {
    required CameraFit cameraFit,
    required TileProvider? effectiveTileProvider,
    required _HeatmapRasterResult? heatmapRaster,
    required List<Polyline> polylines,
    required List<Marker> markers,
    required _CourseAnalysis? singleAnalysis,
  }) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: AppColors.background,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return MasterContainer(
              scrollable: false,
              padding: EdgeInsets.zero,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _buildFlutterMap(
                          cameraFit: cameraFit,
                          effectiveTileProvider: effectiveTileProvider,
                          style: _selectedStyle,
                          interactive: true,
                          heatmapRaster: heatmapRaster,
                          polylines: polylines,
                          markers: markers,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: SafeArea(
                          child: Material(
                            color: AppColors.cardBackground.withValues(
                              alpha: 0.94,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            child: IconButton(
                              tooltip: 'Exit fullscreen',
                              icon: const Icon(
                                Icons.fullscreen_exit,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: SafeArea(
                          child: _buildStyleSelectorButton(
                            selectedStyle: _selectedStyle,
                            onSelected: (style) {
                              _selectMapStyle(style);
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildAttributionBadge(_selectedStyle),
                            if (singleAnalysis != null &&
                                singleAnalysis.records.length > 1)
                              _buildSingleCoursePaceCard(singleAnalysis),
                            if (heatmapRaster != null)
                              _buildHeatmapInfoBox(heatmapRaster),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_allPoints.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const EmptyState(
          title: 'No GPS data',
          subtitle: 'No GPS track recorded for this workout.',
          icon: Icons.map_outlined,
        ),
      );
    }

    final singleAnalysis = _singleAnalysis;
    final heatmapRaster = _heatmapRaster;
    final polylines = _polylines;
    final markers = _markers;

    final cameraFit = _allPoints.length == 1
        ? CameraFit.coordinates(
            coordinates: [_allPoints.first],
            maxZoom: 15,
            padding: const EdgeInsets.all(32),
          )
        : CameraFit.bounds(
            bounds:
                heatmapRaster?.bounds ?? LatLngBounds.fromPoints(_allPoints),
            padding: const EdgeInsets.all(24),
          );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    final effectiveTileProvider =
        widget.tileProvider ?? (isTest ? _TestTileProvider() : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                _buildFlutterMap(
                  cameraFit: cameraFit,
                  effectiveTileProvider: effectiveTileProvider,
                  style: _selectedStyle,
                  interactive: widget.interactive,
                  heatmapRaster: heatmapRaster,
                  polylines: polylines,
                  markers: markers,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildStyleSelectorButton(
                    selectedStyle: _selectedStyle,
                    onSelected: _selectMapStyle,
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Material(
                    color: AppColors.cardBackground.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openFullscreenMap(
                        context,
                        cameraFit: cameraFit,
                        effectiveTileProvider: effectiveTileProvider,
                        heatmapRaster: heatmapRaster,
                        polylines: polylines,
                        markers: markers,
                        singleAnalysis: singleAnalysis,
                      ),
                      child: const Tooltip(
                        message: 'Fullscreen',
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.fullscreen,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 4,
                  child: _buildAttributionBadge(_selectedStyle),
                ),
              ],
            ),
          ),
        ),
        if (singleAnalysis != null && singleAnalysis.records.length > 1)
          _buildSingleCoursePaceCard(singleAnalysis),
        if (heatmapRaster != null) _buildHeatmapInfoBox(heatmapRaster),
      ],
    );
  }
}
