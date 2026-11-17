import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/app_button.dart';
import 'package:mobile_app/widgets/workout_metrics_panel.dart';

export 'package:mobile_app/widgets/workout_metrics_panel.dart'
    show WorkoutStatus;

/// Transport controls for starting, pausing, resuming, finishing, or discarding
/// a live workout based on the current [WorkoutStatus].
class WorkoutControlBar extends StatelessWidget {
  final WorkoutStatus status;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onFinish;
  final VoidCallback? onDiscard;

  const WorkoutControlBar({
    super.key,
    required this.status,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onFinish,
    this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WorkoutStatus.idle:
        return AppButton(
          text: 'Start activity',
          icon: Icons.play_arrow,
          variant: AppButtonVariant.primary,
          onPressed: onStart,
        );
      case WorkoutStatus.recording:
        return AppButton(
          text: 'Pause',
          icon: Icons.pause,
          variant: AppButtonVariant.secondary,
          onPressed: onPause,
        );
      case WorkoutStatus.paused:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Resume',
                    icon: Icons.play_arrow,
                    variant: AppButtonVariant.outline,
                    onPressed: onResume,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Finish',
                    icon: Icons.check,
                    variant: AppButtonVariant.primary,
                    onPressed: onFinish,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Discard',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.danger,
              onPressed: onDiscard,
            ),
          ],
        );
    }
  }
}
