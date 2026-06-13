import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Reference ingestion budget contracts', () {
    const resolver = ReferenceIngestionBudgetResolverService();

    test('policy round-trips planning mode, batch goal and split policy', () {
      const policy = ReferenceIngestionBudgetPolicy(
        defaultAvailableContextChars: 48000,
        sourceWindowRatio: 0.42,
        minSourceChars: 1800,
        maxSourceChars: 6400,
        minSectionsPerBatch: 1,
        maxSectionsPerBatch: 3,
        planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
        oversizeSectionSplitPolicy:
            ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
        batchGoalKind: ReferenceBatchGoalKinds.timelineSweep,
        allowStructureFallback: true,
      );
      final decoded = ReferenceIngestionBudgetPolicy.fromJson(policy.toJson());

      expect(decoded.validateBasics(), isEmpty);
      expect(
        decoded.planningMode,
        ReferenceSourceBatchPlanningModes.chapterFirst,
      );
      expect(decoded.batchGoalKind, ReferenceBatchGoalKinds.timelineSweep);
      expect(
        decoded.oversizeSectionSplitPolicy,
        ReferenceOversizeSectionSplitPolicies.paragraphClusterPreferred,
      );
    });

    test(
      'resolver carries planning semantics into resolved budget contract',
      () {
        final resolution = resolver.resolve(
          policy: const ReferenceIngestionBudgetPolicy(
            defaultAvailableContextChars: 32000,
            sourceWindowRatio: 0.38,
            minSourceChars: 2200,
            maxSourceChars: 5400,
            planningMode: ReferenceSourceBatchPlanningModes.structureFirst,
            batchGoalKind: ReferenceBatchGoalKinds.semanticExtraction,
          ),
        );

        expect(resolution.validateBasics(), isEmpty);
        expect(
          resolution.planningMode,
          ReferenceSourceBatchPlanningModes.structureFirst,
        );
        expect(
          resolution.batchGoalKind,
          ReferenceBatchGoalKinds.semanticExtraction,
        );
        expect(resolution.targetSourceChars, inInclusiveRange(2200, 5400));
      },
    );

    test(
      'builtin strategies keep single-concurrency extraction discipline',
      () {
        const profiles = <ReferenceExtractionStrategyProfile>[
          ReferenceExtractionStrategyProfiles.standard,
          ReferenceExtractionStrategyProfiles.bulkLongContext,
          ReferenceExtractionStrategyProfiles.factFocused,
          ReferenceExtractionStrategyProfiles.exploratory,
        ];

        for (final profile in profiles) {
          expect(
            profile.executionDiscipline.concurrencyMode,
            ReferenceExtractionConcurrencyModes.single,
          );
          expect(profile.executionDiscipline.maxConcurrentBatches, 1);
          expect(
            profile.executionDiscipline.allowParallelHeavyTextConsumption,
            isFalse,
          );
        }
      },
    );
  });
}
