import 'package:flutter/material.dart';

class Breakpoints {
  static const double compact = 600;
  static const double medium = 800;
  static const double expanded = 1200;
}

enum ScreenSize { compact, medium, expanded }

class Responsive {
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return ScreenSize.compact;
    if (width < Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      getScreenSize(context) == ScreenSize.compact;

  static bool isMedium(BuildContext context) =>
      getScreenSize(context) == ScreenSize.medium;

  static bool isExpanded(BuildContext context) =>
      getScreenSize(context) == ScreenSize.expanded;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static double padding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return 12;
    if (width < Breakpoints.medium) return 24;
    if (width < Breakpoints.expanded) return 32;
    return 48;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return 12;
    if (width < Breakpoints.medium) return 24;
    if (width < Breakpoints.expanded) return 48;
    return 80;
  }

  static double gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return 1;
    if (width <= Breakpoints.medium) return 2;
    if (width <= Breakpoints.expanded) return 3;
    return 4;
  }

  static double cardAspectRatio(BuildContext context) {
    final size = getScreenSize(context);
    if (size == ScreenSize.compact) return 1.0;
    if (size == ScreenSize.medium) return 1.2;
    return 1.3;
  }

  static double fontSizeMultiplier(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.compact) return 1.0;
    if (width < Breakpoints.medium) return 1.0;
    if (width < Breakpoints.expanded) return 1.1;
    return 1.2;
  }
}
