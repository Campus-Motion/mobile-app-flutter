import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/constants/colors.dart';
import 'package:mobile_app/widgets/activity_card.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/section_header.dart';
import 'package:mobile_app/widgets/sport_type_selector.dart';
import 'package:mobile_app/widgets/workout_control_bar.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

/// Live workout recording screen with sport selection, periodic timer,
/// pause/resume controls, and exit confirmation while active.
class ActivityRecordScreen extends StatefulWidget {
  const ActivityRecordScreen({super.key});

  @override
  State<ActivityRecordScreen> createState() => _ActivityRecordScreenState();
}

class _ActivityRecordScreenState extends State<ActivityRecordScreen> {
  String _selectedSport = SportTypeSelector.sportTypes.first;
  WorkoutStatus _status = WorkoutStatus.idle;
  Duration _elapsed = Duration.zero;
  double _distanceKm = 0.0;
  Timer? _timer;

  double? get _paceMinPerKm {
    if (_distanceKm <= 0 || _elapsed.inSeconds <= 0) {
      return null;
    }
    return (_elapsed.inSeconds / 60.0) / _distanceKm;
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    });
  }

  void _finishWorkout() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = WorkoutStatus.idle;
      _elapsed = Duration.zero;
      _distanceKm = 0.0;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
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

    _timer?.cancel();
    _timer = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _status == WorkoutStatus.idle,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
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
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              const Expanded(child: SectionHeader(title: 'Activity Mode')),
            ],
          ),
          const SizedBox(height: 24),
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
      ),
    );
  }
}
