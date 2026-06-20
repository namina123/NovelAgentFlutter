import '../routing/app_destination.dart';

enum FeatureRefreshTarget {
  projectOpen,
  bookDeconstruction,
  projectAssets,
  longTaskStation,
  taskCenter,
}

class FeatureRefreshIntent {
  const FeatureRefreshIntent(this.target);

  final FeatureRefreshTarget target;

  AppDestination? get destination {
    switch (target) {
      case FeatureRefreshTarget.projectOpen:
        return AppDestination.projectOpen;
      case FeatureRefreshTarget.bookDeconstruction:
        return AppDestination.bookDeconstruction;
      case FeatureRefreshTarget.projectAssets:
        return AppDestination.projectAssets;
      case FeatureRefreshTarget.longTaskStation:
        return AppDestination.longTaskStation;
      case FeatureRefreshTarget.taskCenter:
        return AppDestination.taskCenter;
    }
  }
}
