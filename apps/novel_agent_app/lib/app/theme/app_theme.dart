import 'package:flutter/material.dart';

import 'control_style_descriptor.dart';
import 'control_style_registry.dart';
import 'control_style_resolver.dart';
import 'control_style_token_set.dart';
import 'theme_descriptor.dart';
import 'theme_registry.dart';
import 'theme_resolver.dart';
import 'theme_token_set.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeRegistry _themeRegistry = ThemeRegistry.builtIn();
  static final ControlStyleRegistry _controlStyleRegistry =
      ControlStyleRegistry.builtIn();
  static const ControlStyleResolver _controlStyleResolver =
      ControlStyleResolver();
  static const ThemeResolver _themeResolver = ThemeResolver();

  static ThemeData light({
    String controlStyleId = ControlStyleRegistry.defaultStyleId,
  }) {
    return themeDataFor('builtin.light', controlStyleId: controlStyleId);
  }

  static ThemeData dark({
    String controlStyleId = ControlStyleRegistry.defaultStyleId,
  }) {
    return themeDataFor('builtin.dark', controlStyleId: controlStyleId);
  }

  static ThemeData themeDataFor(
    String id, {
    String controlStyleId = ControlStyleRegistry.defaultStyleId,
  }) {
    return _themeResolver.resolve(
      tokenSetFor(id, controlStyleId: controlStyleId),
    );
  }

  static List<ThemeDescriptor> builtInDescriptors() {
    return _themeRegistry.builtInDescriptors();
  }

  static List<ControlStyleDescriptor> builtInControlStyleDescriptors() {
    return _controlStyleRegistry.builtInDescriptors();
  }

  static ThemeTokenSet tokenSetFor(
    String id, {
    String controlStyleId = ControlStyleRegistry.defaultStyleId,
  }) {
    final colorTokenSet = _themeRegistry.requireColorTokenSet(id);
    final controlStyle = controlStyleTokenSetFor(controlStyleId);
    return ThemeTokenSet(
      descriptor: colorTokenSet.descriptor,
      colors: colorTokenSet.colors,
      controlStyle: controlStyle,
      surfaces: _controlStyleResolver.resolveSurfaceSpecs(
        colors: colorTokenSet.colors,
        controlStyle: controlStyle,
      ),
    );
  }

  static ControlStyleTokenSet controlStyleTokenSetFor(String id) {
    final resolvedId = _controlStyleRegistry.contains(id)
        ? id
        : ControlStyleRegistry.defaultStyleId;
    return _controlStyleRegistry.requireTokenSet(resolvedId);
  }
}
