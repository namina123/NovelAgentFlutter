import 'package:flutter/material.dart';

class WorkbenchProjectPanelActionViewData {
  const WorkbenchProjectPanelActionViewData({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionId,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionId;
}
