import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/waypoint.dart';
import 'package:mobile_app/widgets/empty_state.dart';

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

/// Reusable map widget displaying a GPS track with start and finish markers.
///
/// Built on top of [FlutterMap] and OpenStreetMap tiles. Follows Campus Motion
/// privacy invariants by requesting only public OSM map tiles without trackers.
class RouteMap extends StatelessWidget {
  final List<Waypoint> waypoints;
  final List<List<Waypoint>>? tracks;
  final double height;
  final Color routeColor;
  final bool interactive;
  final TileProvider? tileProvider;

  const RouteMap({
    super.key,
    this.waypoints = const [],
    this.tracks,
    this.height = 260.0,
    this.routeColor = AppColors.primary,
    this.interactive = true,
    this.tileProvider,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTracks = tracks ?? (waypoints.isNotEmpty ? [waypoints] : []);
    final allPoints = <LatLng>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    for (final track in effectiveTracks) {
      final points = track.map((w) => LatLng(w.latitude, w.longitude)).toList();
      if (points.isNotEmpty) {
        allPoints.addAll(points);
        if (points.length > 1) {
          polylines.add(
            Polyline(
              points: points,
              strokeWidth: tracks != null ? 3.5 : 4.5,
              color: routeColor,
            ),
          );
        }
      }
    }

    if (allPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: const EmptyState(
          title: 'No GPS data',
          subtitle: 'No GPS track recorded for this workout.',
          icon: Icons.map_outlined,
        ),
      );
    }

    // Single track mode: add start & finish markers
    if (tracks == null && waypoints.isNotEmpty) {
      final firstPoint = LatLng(
        waypoints.first.latitude,
        waypoints.first.longitude,
      );
      markers.add(
        Marker(
          point: firstPoint,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
          ),
        ),
      );

      if (waypoints.length > 1) {
        final lastPoint = LatLng(
          waypoints.last.latitude,
          waypoints.last.longitude,
        );
        markers.add(
          Marker(
            point: lastPoint,
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.flag, size: 16, color: Colors.white),
            ),
          ),
        );
      }
    }

    final cameraFit = allPoints.length == 1
        ? CameraFit.coordinates(
            coordinates: [allPoints.first],
            maxZoom: 15,
            padding: const EdgeInsets.all(32),
          )
        : CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(allPoints),
            padding: const EdgeInsets.all(32),
          );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    final effectiveTileProvider =
        tileProvider ?? (isTest ? _TestTileProvider() : null);

    return Container(
      height: height,
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
            FlutterMap(
              options: MapOptions(
                initialCameraFit: cameraFit,
                interactionOptions: InteractionOptions(
                  flags: interactive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ch.campusmotion.app',
                  tileProvider: effectiveTileProvider,
                ),
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
