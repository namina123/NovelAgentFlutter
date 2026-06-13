import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceBatchPlannerService', () {
    final structureService = ReferenceSourceDocumentStructureService();
    final planner = ReferenceSourceBatchPlannerService(
      structureService: structureService,
    );
    const resolver = ReferenceIngestionBudgetResolverService();

    test('keeps explicit chapter structure first when chapters fit budget', () {
      final structure = structureService.analyze('''
CHAPTER ONE
Harry lived at number four, Privet Drive.

CHAPTER TWO
Letters arrived from Hogwarts.

CHAPTER THREE
The giant on the rock explained the wizarding world.
''');
      final resolution = resolver.resolve(
        policy: const ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 12000,
          sourceWindowRatio: 0.35,
          minSourceChars: 200,
          maxSourceChars: 1200,
          maxSectionsPerBatch: 2,
        ),
      );

      final plan = planner.plan(
        planId: 'plan-structured',
        structure: structure,
        budgetResolution: resolution,
        budgetPolicy: const ReferenceIngestionBudgetPolicy(
          minSourceChars: 200,
          maxSourceChars: 1200,
          maxSectionsPerBatch: 2,
        ),
      );

      expect(
        plan.structureMode,
        ReferenceSourceDocumentStructureKinds.explicitChapter,
      );
      expect(plan.batches, hasLength(2));
      expect(plan.batches.first.sectionIndexes, <int>[1, 2]);
      expect(
        plan.batches.first.splitMode,
        ReferenceSourceBatchSplitModes.sectionAligned,
      );
      expect(plan.batches.last.sectionIndexes, <int>[3]);
    });

    test('splits oversized chapter before falling back to later batches', () {
      final longSection = List<String>.filled(14, 'A' * 220).join('\n\n');
      final structure = structureService.analyze('''
CHAPTER ONE
$longSection
''');
      final resolution = resolver.resolve(
        policy: const ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 8000,
          sourceWindowRatio: 0.3,
          minSourceChars: 400,
          maxSourceChars: 900,
        ),
      );

      final plan = planner.plan(
        planId: 'plan-oversized',
        structure: structure,
        budgetResolution: resolution,
        budgetPolicy: const ReferenceIngestionBudgetPolicy(
          minSourceChars: 400,
          maxSourceChars: 900,
          oversizeSectionMinChars: 300,
        ),
      );

      expect(plan.batches.length, greaterThan(1));
      expect(
        plan.batches.every(
          (batch) =>
              batch.splitMode ==
              ReferenceSourceBatchSplitModes.oversizedSectionSplit,
        ),
        isTrue,
      );
      expect(plan.batches.first.syntheticSplit, isTrue);
      expect(plan.batches.first.parentSectionIds, contains('section_001'));
    });

    test('degrades to structure fallback when no explicit chapters exist', () {
      final structure = structureService.analyze(
        List<String>.filled(
          8,
          'Harry walked through a long paragraph cluster without any chapter heading.',
        ).join('\n\n'),
      );
      final resolution = resolver.resolve(
        policy: const ReferenceIngestionBudgetPolicy(
          defaultAvailableContextChars: 7000,
          sourceWindowRatio: 0.3,
          minSourceChars: 300,
          maxSourceChars: 800,
        ),
      );

      final plan = planner.plan(
        planId: 'plan-fallback',
        structure: structure,
        budgetResolution: resolution,
        budgetPolicy: const ReferenceIngestionBudgetPolicy(
          minSourceChars: 300,
          maxSourceChars: 800,
        ),
      );

      expect(
        structure.structureKind,
        ReferenceSourceDocumentStructureKinds.paragraphCluster,
      );
      expect(plan.batches, isNotEmpty);
      expect(
        plan.batches.every(
          (batch) =>
              batch.splitMode ==
              ReferenceSourceBatchSplitModes.structureFallback,
        ),
        isTrue,
      );
      expect(plan.structureFallbackUsed, isFalse);
    });

    test(
      'chapter-first mode keeps chapter boundaries even when multiple chapters fit budget',
      () {
        final structure = structureService.analyze('''
CHAPTER ONE
Harry lived at number four, Privet Drive.

CHAPTER TWO
Letters arrived from Hogwarts.

CHAPTER THREE
The giant on the rock explained the wizarding world.
''');
        final resolution = resolver.resolve(
          policy: const ReferenceIngestionBudgetPolicy(
            defaultAvailableContextChars: 12000,
            sourceWindowRatio: 0.45,
            minSourceChars: 200,
            maxSourceChars: 1200,
            maxSectionsPerBatch: 3,
            planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
          ),
        );

        final plan = planner.plan(
          planId: 'plan-chapter-first',
          structure: structure,
          budgetResolution: resolution,
          budgetPolicy: const ReferenceIngestionBudgetPolicy(
            minSourceChars: 200,
            maxSourceChars: 1200,
            maxSectionsPerBatch: 3,
            planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
          ),
        );

        expect(plan.validateBasics(), isEmpty);
        expect(
          plan.planningMode,
          ReferenceSourceBatchPlanningModes.chapterFirst,
        );
        expect(plan.batches, hasLength(3));
        expect(
          plan.batches.every((batch) => batch.sectionIndexes.length == 1),
          isTrue,
        );
      },
    );

    test(
      'chapter-first degrades cleanly when source has no chapter structure',
      () {
        final structure = structureService.analyze(
          List<String>.filled(
            6,
            'A long paragraph cluster without chapter headings but with enough text for batching.',
          ).join('\n\n'),
        );
        final resolution = resolver.resolve(
          policy: const ReferenceIngestionBudgetPolicy(
            defaultAvailableContextChars: 7000,
            sourceWindowRatio: 0.32,
            minSourceChars: 300,
            maxSourceChars: 800,
            planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
          ),
        );

        final plan = planner.plan(
          planId: 'plan-chapter-fallback',
          structure: structure,
          budgetResolution: resolution,
          budgetPolicy: const ReferenceIngestionBudgetPolicy(
            minSourceChars: 300,
            maxSourceChars: 800,
            planningMode: ReferenceSourceBatchPlanningModes.chapterFirst,
          ),
        );

        expect(plan.structureFallbackUsed, isTrue);
        expect(
          plan.batches.every(
            (batch) =>
                batch.splitMode ==
                ReferenceSourceBatchSplitModes.structureFallback,
          ),
          isTrue,
        );
      },
    );

    test('tracks batch coverage progress after sequential completion', () {
      const plan = ReferenceSourceBatchPlan(
        planId: 'plan-progress',
        structureMode: ReferenceSourceDocumentStructureKinds.explicitChapter,
        totalSourceChars: 18,
        totalSectionCount: 2,
        budgetResolution: ReferenceIngestionBudgetResolution(
          availableContextChars: 8000,
          targetSourceChars: 500,
          minSourceChars: 300,
          maxSourceChars: 700,
          minSectionsPerBatch: 1,
          maxSectionsPerBatch: 2,
          instructionReserveChars: 1000,
          carryForwardReserveChars: 500,
          responseReserveChars: 1000,
          safetyReserveChars: 300,
        ),
        batches: <ReferenceSourceBatch>[
          ReferenceSourceBatch(
            batchId: 'batch_001',
            batchIndex: 1,
            structureMode:
                ReferenceSourceDocumentStructureKinds.explicitChapter,
            splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
            sourceText: 'batch one',
            sectionIds: <String>['section_001'],
          ),
          ReferenceSourceBatch(
            batchId: 'batch_002',
            batchIndex: 2,
            structureMode:
                ReferenceSourceDocumentStructureKinds.explicitChapter,
            splitMode: ReferenceSourceBatchSplitModes.sectionAligned,
            sourceText: 'batch two',
            sectionIds: <String>['section_002'],
          ),
        ],
      );
      const progressService = ReferenceSourceBatchProgressService();
      var progress = progressService.initialize(plan);
      progress = progressService.markCompleted(
        progress: progress,
        batch: plan.batches.first,
        proposalCount: 3,
        completedAt: '2026-06-08T12:00:00Z',
      );
      progress = progressService.markCompleted(
        progress: progress,
        batch: plan.batches.last,
        proposalCount: 2,
        completedAt: '2026-06-08T12:01:00Z',
      );

      expect(progress.completedBatchCount, 2);
      expect(progress.pendingBatchCount, 0);
      expect(progress.coverageRatio, 1);
      expect(progress.consolidationReady, isTrue);
      expect(
        progress.items.every(
          (item) => item.status == ReferenceSourceBatchStatuses.completed,
        ),
        isTrue,
      );
    });
  });
}
