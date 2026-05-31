import 'package:flutter/material.dart';

import 'theme_surface_spec.dart';

@immutable
class ThemeSurfaceSpecSet {
  const ThemeSurfaceSpecSet({
    required this.panel,
    required this.sidebar,
    required this.inputDock,
    required this.conversationEntry,
    required this.toolRow,
    required this.optionTile,
    required this.splitter,
  });

  final ThemeSurfaceSpec panel;
  final ThemeSurfaceSpec sidebar;
  final ThemeSurfaceSpec inputDock;
  final ThemeSurfaceSpec conversationEntry;
  final ThemeSurfaceSpec toolRow;
  final ThemeSurfaceSpec optionTile;
  final ThemeSurfaceSpec splitter;
}
