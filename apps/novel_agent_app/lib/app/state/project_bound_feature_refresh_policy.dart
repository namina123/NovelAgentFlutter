import '../routing/app_destination.dart';
import 'feature_refresh_intent.dart';
import 'feature_visibility_state.dart';

class ProjectBoundFeatureRefreshPolicy {
  const ProjectBoundFeatureRefreshPolicy();

  List<FeatureRefreshIntent> resolveAfterProjectLoad(
    FeatureVisibilityState state,
  ) {
    if (!state.hasProject) {
      return const <FeatureRefreshIntent>[];
    }
    switch (state.destination) {
      case AppDestination.projectOpen:
        return const <FeatureRefreshIntent>[
          FeatureRefreshIntent(FeatureRefreshTarget.projectOpen),
        ];
      case AppDestination.bookDeconstruction:
        return const <FeatureRefreshIntent>[
          FeatureRefreshIntent(FeatureRefreshTarget.bookDeconstruction),
        ];
      case AppDestination.projectAssets:
        return const <FeatureRefreshIntent>[
          FeatureRefreshIntent(FeatureRefreshTarget.projectAssets),
        ];
      case AppDestination.longTaskStation:
        return const <FeatureRefreshIntent>[
          FeatureRefreshIntent(FeatureRefreshTarget.longTaskStation),
        ];
      case AppDestination.taskCenter:
        return const <FeatureRefreshIntent>[
          FeatureRefreshIntent(FeatureRefreshTarget.taskCenter),
        ];
      case AppDestination.workbench:
      case AppDestination.agentEcosystem:
      case AppDestination.settings:
        return const <FeatureRefreshIntent>[];
    }
  }
}
