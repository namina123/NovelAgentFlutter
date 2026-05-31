import 'package:flutter/material.dart';

@immutable
class ControlStyleDescriptor {
  const ControlStyleDescriptor({
    required this.id,
    required this.label,
    this.isBuiltIn = true,
    this.isEditable = false,
  });

  final String id;
  final String label;
  final bool isBuiltIn;
  final bool isEditable;
}
