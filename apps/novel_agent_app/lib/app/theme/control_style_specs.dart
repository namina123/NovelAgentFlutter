import 'package:flutter/material.dart';

@immutable
class PanelChromeSpec {
  const PanelChromeSpec({
    required this.radius,
    required this.borderWidth,
    this.shadow = const <BoxShadow>[],
  });

  final double radius;
  final double borderWidth;
  final List<BoxShadow> shadow;
}

@immutable
class ButtonChromeSpec {
  const ButtonChromeSpec({
    required this.radius,
    required this.borderWidth,
    required this.regularMinHeight,
    required this.compactMinHeight,
    required this.regularPadding,
    required this.compactPadding,
    required this.regularIconSize,
    required this.compactIconSize,
  });

  final double radius;
  final double borderWidth;
  final double regularMinHeight;
  final double compactMinHeight;
  final EdgeInsets regularPadding;
  final EdgeInsets compactPadding;
  final double regularIconSize;
  final double compactIconSize;
}

@immutable
class ToolbarChromeSpec {
  const ToolbarChromeSpec({
    required this.radius,
    required this.borderWidth,
    required this.buttonSize,
    required this.padding,
    required this.iconSize,
  });

  final double radius;
  final double borderWidth;
  final double buttonSize;
  final EdgeInsets padding;
  final double iconSize;
}

@immutable
class InputChromeSpec {
  const InputChromeSpec({
    required this.radius,
    required this.borderWidth,
    required this.contentPadding,
    required this.minHeight,
  });

  final double radius;
  final double borderWidth;
  final EdgeInsets contentPadding;
  final double minHeight;
}

@immutable
class ChipChromeSpec {
  const ChipChromeSpec({
    required this.radius,
    required this.borderWidth,
    required this.padding,
    required this.minHeight,
  });

  final double radius;
  final double borderWidth;
  final EdgeInsets padding;
  final double minHeight;
}

@immutable
class CardChromeSpec {
  const CardChromeSpec({
    required this.radius,
    required this.borderWidth,
    required this.dividerWidth,
    this.margin = EdgeInsets.zero,
    this.shadow = const <BoxShadow>[],
  });

  final double radius;
  final double borderWidth;
  final double dividerWidth;
  final EdgeInsets margin;
  final List<BoxShadow> shadow;
}
