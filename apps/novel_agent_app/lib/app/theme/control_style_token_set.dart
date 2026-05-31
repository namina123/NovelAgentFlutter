import 'package:flutter/material.dart';

import 'control_style_descriptor.dart';
import 'control_style_specs.dart';

@immutable
class ControlStyleTokenSet {
  const ControlStyleTokenSet({
    required this.descriptor,
    required this.panel,
    required this.button,
    required this.toolbar,
    required this.input,
    required this.chip,
    required this.card,
  });

  final ControlStyleDescriptor descriptor;
  final PanelChromeSpec panel;
  final ButtonChromeSpec button;
  final ToolbarChromeSpec toolbar;
  final InputChromeSpec input;
  final ChipChromeSpec chip;
  final CardChromeSpec card;
}
