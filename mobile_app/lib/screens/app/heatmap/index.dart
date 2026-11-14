import 'package:flutter/material.dart';
import 'package:mobile_app/models/heatmap.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/empty_state.dart';
import 'package:mobile_app/widgets/error_state.dart';
import 'package:mobile_app/widgets/heatmap_view.dart';
import 'package:mobile_app/widgets/loading_state.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/section_header.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key, this.loadHeatmap});

  final Future<HeatmapData?> Function()? loadHeatmap;

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  late Future<HeatmapData?> _request;

  Future<HeatmapData?> _load() =>
      (widget.loadHeatmap ?? ActivityService().getHeatmap)();

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  void _reload() {
    final request = _load();
    setState(() {
      _request = request;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: 'Back',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'My heatmap'),
        const SizedBox(height: 12),
        const Text(
          'Only your routes are shown. Based on your latest 20 activities with GPS data.',
        ),
        const SizedBox(height: 24),
        FutureBuilder<HeatmapData?>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState(height: 320);
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Your heatmap could not be loaded. Please try again.',
                onRetry: _reload,
              );
            }
            final content = snapshot.data == null
                ? const EmptyState(
                    icon: Icons.map_outlined,
                    title: 'No GPS routes yet',
                    subtitle:
                        'Activities need timestamped GPS points with movement to appear here. Manually logged activities do not contain routes.',
                  )
                : HeatmapView(heatmap: snapshot.data!);
            return Column(
              children: [
                content,
                const SizedBox(height: 24),
                AppButton(text: 'Refresh', onPressed: _reload),
              ],
            );
          },
        ),
      ],
    );
  }
}
