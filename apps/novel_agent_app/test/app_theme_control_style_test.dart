import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_typography.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';

void main() {
  test('app theme composes color theme and control style independently', () {
    final linear = AppTheme.tokenSetFor('builtin.light');
    final gentle = AppTheme.tokenSetFor(
      'builtin.light',
      controlStyleId: 'builtin.gentle',
    );

    expect(linear.descriptor.id, gentle.descriptor.id);
    expect(linear.colors.canvasBackground, gentle.colors.canvasBackground);
    expect(linear.colors.accentColor, gentle.colors.accentColor);

    expect(linear.controlStyle.descriptor.id, 'builtin.studio');
    expect(gentle.controlStyle.descriptor.id, 'builtin.gentle');
    expect(linear.surfaces.panel.radius, 8);
    expect(gentle.surfaces.panel.radius, 8);
    expect(linear.surfaces.inputDock.radius, 8);
    expect(gentle.surfaces.inputDock.radius, 8);
  });

  test('app theme exposes cjk fallback and readable dark surface contrast', () {
    final light = AppTheme.tokenSetFor('builtin.light');
    final dark = AppTheme.tokenSetFor('builtin.dark');
    final darkTheme = AppTheme.dark();
    final fallback =
        darkTheme.textTheme.bodyMedium?.fontFamilyFallback ?? const <String>[];

    expect(fallback, containsAll(AppTypography.cjkFontFamilyFallback.take(4)));

    expect(
      _contrastRatio(light.colors.textColor, light.colors.panelBackground),
      greaterThan(10),
    );
    expect(
      _contrastRatio(dark.colors.textColor, dark.colors.panelBackground),
      greaterThan(12),
    );
    expect(
      _contrastRatio(dark.colors.mutedTextColor, dark.colors.panelBackground),
      greaterThan(7),
    );
    expect(dark.colors.canvasBackground, isNot(dark.colors.panelBackground));
    expect(dark.colors.panelBackground, isNot(dark.colors.inputBackground));
  });
}

double _contrastRatio(Color intendedForeground, Color intendedBackground) {
  final foregroundLuminance = intendedForeground.computeLuminance();
  final backgroundLuminance = intendedBackground.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
