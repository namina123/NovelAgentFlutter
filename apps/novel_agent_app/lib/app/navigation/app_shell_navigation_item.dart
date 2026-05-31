import 'package:flutter/widgets.dart';

import '../routing/app_destination.dart';

class AppShellNavigationItem {
  const AppShellNavigationItem({
    required this.destination,
    required this.label,
    required this.tooltip,
    required this.icon,
  });

  final AppDestination destination;
  final String label;
  final String tooltip;
  final IconData icon;
}
