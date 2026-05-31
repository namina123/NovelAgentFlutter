import 'app_shell_navigation_item.dart';

class AppShellNavigationSection {
  const AppShellNavigationSection({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<AppShellNavigationItem> items;
}
