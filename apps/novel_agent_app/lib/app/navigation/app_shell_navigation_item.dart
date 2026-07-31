import 'package:flutter/widgets.dart';

import '../routing/app_destination.dart';

class AppShellNavigationItem {
  const AppShellNavigationItem({
    required this.destination,
    required this.label,
    required this.tooltip,
    required this.icon,
    this.badgeCount = 0,
  });

  final AppDestination destination;
  final String label;
  final String tooltip;
  final IconData icon;
  final int badgeCount;
}
