import '../routing/app_destination.dart';

class FeatureVisibilityState {
  const FeatureVisibilityState({
    required this.destination,
    required this.projectPath,
    required this.isProjectHydrationInProgress,
  });

  final AppDestination destination;
  final String projectPath;
  final bool isProjectHydrationInProgress;

  bool get hasProject => projectPath.trim().isNotEmpty;
}
