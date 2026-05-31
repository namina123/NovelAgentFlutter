import 'package:flutter/material.dart';

@immutable
class ThemeSurfaceSpec {
  const ThemeSurfaceSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.mutedForegroundColor,
    required this.highlightBackgroundColor,
    required this.highlightBorderColor,
    required this.highlightForegroundColor,
    required this.borderWidth,
    required this.radius,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;
  final Color highlightBackgroundColor;
  final Color highlightBorderColor;
  final Color highlightForegroundColor;
  final double borderWidth;
  final double radius;
}
