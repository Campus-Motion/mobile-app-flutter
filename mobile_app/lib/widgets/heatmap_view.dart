import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/error_state.dart';

/// Displays the server-rendered raster without contacting a map provider.
class HeatmapView extends StatelessWidget {
  const HeatmapView({super.key, required this.heatmap});

  final HeatmapData heatmap;

  @override
  Widget build(BuildContext context) {
    final southWest = heatmap.bounds[0];
    final northEast = heatmap.bounds[1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${heatmap.runs} ${heatmap.runs == 1 ? 'activity' : 'activities'} with GPS routes',
        ),
        const SizedBox(height: 16),
        AppCard(
          backgroundColor: AppColors.textPrimary,
          child: SizedBox(
            height: 320,
            child: InteractiveViewer(
              maxScale: 8,
              child: Image.memory(
                heatmap.imageBytes,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                semanticLabel: 'Your route density heatmap, north at the top',
                errorBuilder: (_, _, _) => const ErrorState(
                  message: 'The heatmap image could not be displayed.',
                ),
              ),
            ),
          ),
        ),
        const Text('North is at the top. Pinch to zoom and drag to explore.'),
        const SizedBox(height: 8),
        const Text(
          'Brighter routes indicate more passages. No street map background.',
        ),
        const SizedBox(height: 8),
        Text(
          'Latitude ${southWest[0].toStringAsFixed(4)} to ${northEast[0].toStringAsFixed(4)}\n'
          'Longitude ${southWest[1].toStringAsFixed(4)} to ${northEast[1].toStringAsFixed(4)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
