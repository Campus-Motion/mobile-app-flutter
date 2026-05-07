import 'package:flutter/material.dart';

class MasterContainer extends StatelessWidget {
  final List<Widget> children;
  final bool useSafeArea;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final Widget? bottomNavigationBar;
  final Future<void> Function()? onRefresh;

  const MasterContainer({
    super.key,
    required this.children,
    this.useSafeArea = true,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
    this.backgroundColor = Colors.white,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.bottomNavigationBar,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );

    if (padding != EdgeInsets.zero) {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: onRefresh != null ? const AlwaysScrollableScrollPhysics() : null,
        child: content,
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    Widget screen = Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: content,
      ),
    );

    return Container(
      color: backgroundColor, // Background for the non-constrained area on web/desktop
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450, // Mobile app width limit
          ),
          child: screen,
        ),
      ),
    );
  }
}
