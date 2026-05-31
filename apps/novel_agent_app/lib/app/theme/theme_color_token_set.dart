import 'package:flutter/material.dart';

import 'theme_color_tokens.dart';
import 'theme_descriptor.dart';

@immutable
class ThemeColorTokenSet {
  const ThemeColorTokenSet({
    required this.descriptor,
    required this.colors,
  });

  final ThemeDescriptor descriptor;
  final ThemeColorTokens colors;
}
