import 'package:flutter/material.dart';

class WorkbenchProjectPanelActionViewData {
  const WorkbenchProjectPanelActionViewData({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionId,
    this.isEnabled = true,
    this.disabledReason = '',
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionId;
  final bool isEnabled;
  final String disabledReason;
}
