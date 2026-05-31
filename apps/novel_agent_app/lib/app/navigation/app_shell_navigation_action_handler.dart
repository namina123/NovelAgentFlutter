import '../routing/app_destination.dart';

abstract class AppShellNavigationActionHandler {
  Future<void> onAppShellDestinationRequested(AppDestination destination);
}
