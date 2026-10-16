import 'package:flutter/material.dart';

import 'package:mobile_app/constants/colors.dart';

/// Centred, brand-colored spinner for async loading states.
///
/// Pass [height] when the spinner sits inside a scroll view or a list section
/// that has no bounded height (e.g. a `FutureBuilder` inside a `Column`).
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.height});

  /// Optional fixed height. When null the widget fills its parent's space.
  final double? height;

  @override
  Widget build(BuildContext context) {
    const spinner = Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
    if (height == null) return spinner;
    return SizedBox(height: height, child: spinner);
  }
}
