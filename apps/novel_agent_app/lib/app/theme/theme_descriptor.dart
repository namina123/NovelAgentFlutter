import 'package:flutter/material.dart';

@immutable
class ThemeDescriptor {
  const ThemeDescriptor({
    required this.id,
    required this.label,
    required this.brightness,
    this.isBuiltIn = true,
    this.isEditable = false,
  });

  final String id;
  final String label;
  final Brightness brightness;
  final bool isBuiltIn;
  final bool isEditable;
}
