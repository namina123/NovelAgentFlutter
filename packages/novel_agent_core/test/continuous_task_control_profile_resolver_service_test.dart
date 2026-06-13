import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskControlProfileResolverService', () {
    const service = ContinuousTaskControlProfileResolverService();

    test(
      'resolves long-form writing into shared watchdog and supervisor contracts',
      () {
        final profile = service.forLongTaskMode(
          'seed_autopilot_novel',
          workflowStrategyId: 'resumable_long_task',
        );
        final decoded = ContinuousTaskControlProfile.fromJson(profile.toJson());

        expect(decoded.validateBasics(), isEmpty);
        expect(
          decoded.taskProfile.familyId,
          ContinuousTaskFamilies.longFormWriting,
        );
        expect(
          decoded.watchdogProfile.profileId,
          'durable_continuous_watchdog',
        );
        expect(decoded.watchdogProfile.requiresHeartbeat, isTrue);
        expect(decoded.supervisorProfile.controlsLifecycleTransitions, isTrue);
        expect(
          decoded.supportedRunPhases,
          contains(ContinuousTaskRunPhases.draftingGuidance),
        );
        expect(
          decoded.supportedStopCategories,
          contains(ContinuousTaskStopCategories.technicalFailure),
        );
      },
    );

    test(
      'goal mode keeps shared lifecycle semantics with lighter watchdog metadata',
      () {
        final profile = service.forGoalMode(workflowStrategyId: 'goal_mode');

        expect(profile.validateBasics(), isEmpty);
        expect(profile.taskProfile.familyId, ContinuousTaskFamilies.goalMode);
        expect(
          profile.watchdogProfile.profileId,
          'lightweight_conversation_watchdog',
        );
        expect(
          ValueReaders.boolValue(
            profile.watchdogProfile.metadata['checkpoint_ui_required'],
          ),
          isFalse,
        );
        expect(
          profile.supportedRunPhases,
          isNot(contains(ContinuousTaskRunPhases.draftingGuidance)),
        );
        expect(
          profile.supportedStopCategories,
          contains(ContinuousTaskStopCategories.cancelled),
        );
      },
    );

    test(
      'reference extraction stays single-chain while sharing the same stop taxonomy',
      () {
        final profile = service.forReferenceExtraction();

        expect(profile.validateBasics(), isEmpty);
        expect(
          profile.taskProfile.familyId,
          ContinuousTaskFamilies.referenceExtraction,
        );
        expect(
          ValueReaders.intValue(
            profile.watchdogProfile.metadata['default_concurrency'],
          ),
          1,
        );
        expect(profile.watchdogProfile.singleActiveWorker, isTrue);
        expect(
          profile.supportedStopCategories,
          orderedEquals(const <String>[
            ContinuousTaskStopCategories.completedNaturally,
            ContinuousTaskStopCategories.cancelled,
            ContinuousTaskStopCategories.budgetExhausted,
            ContinuousTaskStopCategories.technicalFailure,
            ContinuousTaskStopCategories.deliveryFailure,
            ContinuousTaskStopCategories.constraintGatePause,
            ContinuousTaskStopCategories.waitingUser,
            ContinuousTaskStopCategories.manualAttention,
            ContinuousTaskStopCategories.recoveryExhausted,
          ]),
        );
      },
    );
  });
}
