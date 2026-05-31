import 'package:flutter/material.dart';

import 'control_style_token_set.dart';
import 'theme_color_tokens.dart';
import 'theme_descriptor.dart';
import 'theme_surface_spec_set.dart';

@immutable
class ThemeTokenSet {
  const ThemeTokenSet({
    required this.descriptor,
    required this.colors,
    required this.controlStyle,
    required this.surfaces,
  });

  final ThemeDescriptor descriptor;
  final ThemeColorTokens colors;
  final ControlStyleTokenSet controlStyle;
  final ThemeSurfaceSpecSet surfaces;
}
