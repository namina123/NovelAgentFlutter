import 'package:flutter/widgets.dart';

import 'app_destination.dart';

class AppShellPageDescriptor {
  const AppShellPageDescriptor({
    required this.destination,
    required this.builder,
  });

  final AppDestination destination;
  final WidgetBuilder builder;
}
