import 'package:flutter/material.dart';

@immutable
class ThemeColorTokens {
  const ThemeColorTokens({
    required this.canvasBackground,
    required this.panelBackground,
    required this.sidebarBackground,
    required this.inputBackground,
    required this.lineColor,
    required this.lineStrongColor,
    required this.accentColor,
    required this.accentSoftColor,
    required this.warmColor,
    required this.warmStrongColor,
    required this.dangerSoftColor,
    required this.dangerStrongColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.inverseTextColor,
  });

  final Color canvasBackground;
  final Color panelBackground;
  final Color sidebarBackground;
  final Color inputBackground;
  final Color lineColor;
  final Color lineStrongColor;
  final Color accentColor;
  final Color accentSoftColor;
  final Color warmColor;
  final Color warmStrongColor;
  final Color dangerSoftColor;
  final Color dangerStrongColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color inverseTextColor;
}
