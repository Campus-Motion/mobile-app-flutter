import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:mobile_app/models/fit_import_exception.dart';
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
  const HeatmapScreen({super.key, this.loadHeatmap, this.pickFitFile});

  final Future<HeatmapData?> Function()? loadHeatmap;
  final Future<XFile?> Function()? pickFitFile;

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  late Future<HeatmapData?> _request;
  final _activities = ActivityService();
  bool _importing = false;

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

  Future<void> _importFit() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final file = await (widget.pickFitFile ?? _activities.pickFitFile)();
      if (!mounted || file == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Import FIT route?'),
          content: Text(
            'Import "${file.name}" as a new private activity? '
            'Your file will be sent to Campus Motion. Only GPS coordinates and '
            'timestamps will be saved; sensor fields and the original file are discarded. '
            'Importing again creates another activity.',
          ),
          actions: [
            AppButton(
              text: 'Cancel',
              width: 100,
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              text: 'Import',
              width: 100,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _activities.importFitFile(file);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FIT activity saved privately.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is FitImportException
          ? error.message
          : 'The FIT file could not be imported. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
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
        const SizedBox(height: 16),
        AppButton(
          text: 'Choose FIT file',
          icon: Icons.upload_file,
          isLoading: _importing,
          onPressed: _activities.canImportFit && !_importing
              ? _importFit
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          _activities.canImportFit
              ? 'One .fit file, up to 10 MiB. Imported activities are private.'
              : 'Demo mode shows sample data. FIT import requires the live API.',
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
