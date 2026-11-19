import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/models/activity.dart';
import 'package:mobile_app/services/activity_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/app_card.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';
import 'package:mobile_app/widgets/stat_item.dart';
import 'package:mobile_app/widgets/workout_control_bar.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

/// Live workout recording screen with sport selection, periodic timer,
/// pause/resume controls, post-workout summary, and exit confirmation while active.
class ActivityRecordScreen extends StatefulWidget {
  final ActivityService? activityService;

  const ActivityRecordScreen({super.key, this.activityService});

  @override
  State<ActivityRecordScreen> createState() => _ActivityRecordScreenState();
}

class _ActivityRecordScreenState extends State<ActivityRecordScreen> {
  late final ActivityService _activityService =
      widget.activityService ?? ActivityService();
  final AuthService _authService = AuthService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedSport = SportTypeSelector.sportTypes.first;
  WorkoutStatus _status = WorkoutStatus.idle;
  Duration _elapsed = Duration.zero;
  double _distanceKm = 0.0;
  Timer? _timer;

  bool _isSummarizing = false;
  bool _isPublic = false;
  bool _isSaving = false;

  double? get _paceMinPerKm {
    if (_distanceKm <= 0 || _elapsed.inSeconds <= 0) {
      return null;
    }
    return (_elapsed.inSeconds / 60.0) / _distanceKm;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status != WorkoutStatus.recording) {
        return;
      }
      setState(() {
        _elapsed += const Duration(seconds: 1);
        _distanceKm +=
            ActivityCard.getActivitySpeedKmh(_selectedSport) / 3600.0;
      });
    });
  }

  void _startWorkout() {
    setState(() {
      _status = WorkoutStatus.recording;
      _elapsed = Duration.zero;
      _distanceKm = 0.0;
      _isSummarizing = false;
      _isPublic = false;
      _isSaving = false;
    });
    _startTimer();
  }

  void _pauseWorkout() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = WorkoutStatus.paused;
    });
  }

  void _resumeWorkout() {
    setState(() {
      _status = WorkoutStatus.recording;
    });
    _startTimer();
  }

  void _discardWorkout() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = WorkoutStatus.idle;
      _elapsed = Duration.zero;
      _distanceKm = 0.0;
      _isSummarizing = false;
      _isPublic = false;
      _isSaving = false;
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = WorkoutStatus.paused;
      _isSummarizing = true;
      _isPublic = false;
      _isSaving = false;
      _titleController.text = ActivityCard.getDefaultActivityTitle(
        _selectedSport,
      );
      _notesController.clear();
    });
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) return;

    final trimmedTitle = _titleController.text.trim();
    final title = trimmedTitle.isEmpty
        ? ActivityCard.getDefaultActivityTitle(_selectedSport)
        : trimmedTitle;
    final trimmedNotes = _notesController.text.trim();
    final double durationMinutes = _elapsed.inSeconds < 60
        ? 1.0
        : _elapsed.inSeconds / 60.0;

    setState(() {
      _isSaving = true;
    });

    try {
      await _activityService.createActivity(
        Activity(
          id: 0,
          title: title,
          type: _selectedSport,
          userId: _authService.currentUser?.id ?? 0,
          isPublic: _isPublic,
          createdAt: DateTime.now(),
          duration: durationMinutes,
          distanceKm: _distanceKm,
          body: trimmedNotes.isEmpty ? null : trimmedNotes,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSummarizing = false;
        _status = WorkoutStatus.idle;
        _elapsed = Duration.zero;
        _distanceKm = 0.0;
      });
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save activity. Please try again.'),
        ),
      );
    }
  }

  Future<void> _confirmDiscardAndExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text(
          'Are you sure you want to leave? Your active workout will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    _discardWorkout();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
    );
  }

  Widget _buildSummaryView() {
    final Color accentColor = ActivityCard.getActivityColor(_selectedSport);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Duration',
                    value: WorkoutMetricsPanel.formatDuration(_elapsed),
                    valueColor: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Distance',
                    value: WorkoutMetricsPanel.formatDistance(_distanceKm),
                    unit: 'km',
                    valueColor: accentColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatItem(
                    label: 'Avg pace',
                    value: WorkoutMetricsPanel.formatPace(
                      elapsed: _elapsed,
                      distanceKm: _distanceKm,
                      paceMinPerKm: _paceMinPerKm,
                    ),
                    unit: 'min/km',
                    valueColor: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          key: const ValueKey<String>('workout_title_field'),
          controller: _titleController,
          enabled: !_isSaving,
          decoration: _inputDecoration('Activity title'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey<String>('workout_notes_field'),
          controller: _notesController,
          enabled: !_isSaving,
          maxLines: 3,
          decoration: _inputDecoration('Notes (optional)'),
        ),
        const SizedBox(height: 16),
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Make activity public',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Visible to other campus users in their social feeds',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: _isPublic,
              activeThumbColor: AppColors.primary,
              onChanged: _isSaving
                  ? null
                  : (val) {
                      setState(() {
                        _isPublic = val;
                      });
                    },
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Save activity',
          icon: Icons.check,
          isLoading: _isSaving,
          onPressed: _saveWorkout,
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Discard workout',
          icon: Icons.delete_outline,
          variant: AppButtonVariant.danger,
          onPressed: _isSaving ? null : _confirmDiscardAndExit,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _status == WorkoutStatus.idle && !_isSummarizing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSaving) return;
        _confirmDiscardAndExit();
      },
      child: MasterContainer(
        crossAxisAlignment: CrossAxisAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                ),
                onPressed: _isSaving ? null : () => Navigator.maybePop(context),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Expanded(child: SectionHeader(title: 'Activity Mode')),
            ],
          ),
          const SizedBox(height: 24),
          if (_isSummarizing)
            _buildSummaryView()
          else ...[
            const Text(
              'Choose sport',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SportTypeSelector(
              selectedType: _selectedSport,
              enabled: _status == WorkoutStatus.idle,
              onSelected: (type) {
                setState(() {
                  _selectedSport = type;
                });
              },
            ),
            const SizedBox(height: 24),
            WorkoutMetricsPanel(
              elapsed: _elapsed,
              distanceKm: _distanceKm,
              paceMinPerKm: _paceMinPerKm,
              status: _status,
              sportType: _selectedSport,
            ),
            const SizedBox(height: 24),
            WorkoutControlBar(
              status: _status,
              onStart: _startWorkout,
              onPause: _pauseWorkout,
              onResume: _resumeWorkout,
              onFinish: _finishWorkout,
              onDiscard: _discardWorkout,
            ),
          ],
        ],
      ),
    );
  }
}
