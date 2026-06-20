import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/state/feature_refresh_intent.dart';
import 'package:novel_agent_app/app/state/feature_visibility_state.dart';
import 'package:novel_agent_app/app/state/project_bound_feature_refresh_policy.dart';

void main() {
  group('ProjectBoundFeatureRefreshPolicy', () {
    test('returns projectOpen refresh for projectOpen visibility', () {
      const policy = ProjectBoundFeatureRefreshPolicy();

      final intents = policy.resolveAfterProjectLoad(
        const FeatureVisibilityState(
          destination: AppDestination.projectOpen,
          projectPath: 'D:/Projects/demo',
          isProjectHydrationInProgress: false,
        ),
      );

      expect(intents, hasLength(1));
      expect(intents.single.target, FeatureRefreshTarget.projectOpen);
    });

    test('returns no refresh when the active page is workbench', () {
      const policy = ProjectBoundFeatureRefreshPolicy();

      final intents = policy.resolveAfterProjectLoad(
        const FeatureVisibilityState(
          destination: AppDestination.workbench,
          projectPath: 'D:/Projects/demo',
          isProjectHydrationInProgress: false,
        ),
      );

      expect(intents, isEmpty);
    });

    test('returns no refresh without an active project path', () {
      const policy = ProjectBoundFeatureRefreshPolicy();

      final intents = policy.resolveAfterProjectLoad(
        const FeatureVisibilityState(
          destination: AppDestination.projectAssets,
          projectPath: '',
          isProjectHydrationInProgress: false,
        ),
      );

      expect(intents, isEmpty);
    });
  });
}
