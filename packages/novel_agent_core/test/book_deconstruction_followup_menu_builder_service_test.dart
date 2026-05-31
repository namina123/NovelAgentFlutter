import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionFollowupMenuBuilderService', () {
    const service = BookDeconstructionFollowupMenuBuilderService();

    test(
      'builds complete followup menu for deconstruction source projects',
      () {
        final menu = service.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );

        expect(menu.groups, hasLength(3));
        expect(menu.groups.map((item) => item.id), <String>[
          'general_writing',
          'long_task_writing',
          'future_extensions',
        ]);
        expect(menu.highlightedGroupId, 'long_task_writing');
        expect(menu.highlightedOptionId, 'seed_autopilot_novel');
        expect(
          menu.highlightedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
        expect(menu.allowsMultipleDerivedProjects, isTrue);

        final generalOptions = menu.groups.first.options;
        expect(generalOptions, hasLength(1));
        expect(generalOptions.first.id, 'general_novel');
        expect(
          generalOptions.first.recommendedBuildTier,
          ContinuityBuildTier.quickBridge,
        );

        final longTaskOptions = menu.groups[1].options;
        expect(
          longTaskOptions.map((item) => item.id),
          containsAll(<String>[
            'seed_autopilot_novel',
            'full_outline_consensus',
            'volume_checkpoint_handoff',
            'chapter_brief_supervised',
            'salvage_restructure_existing',
          ]),
        );
        expect(
          longTaskOptions
              .firstWhere((item) => item.id == 'full_outline_consensus')
              .recommendedBuildTier,
          ContinuityBuildTier.deepReconstruction,
        );
        expect(
          longTaskOptions
              .firstWhere((item) => item.id == 'chapter_brief_supervised')
              .recommendedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
      },
    );

    test(
      'analysis first keeps build tier but does not preselect final route',
      () {
        final menu = service.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.analysisFirst,
        );

        expect(menu.highlightedGroupId, isEmpty);
        expect(menu.highlightedOptionId, isEmpty);
        expect(
          menu.highlightedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
        expect(menu.notes, contains('不预选最终执行项目路线'));
      },
    );
  });

  group('BookDeconstructionDerivedProjectPlanBuilderService', () {
    const menuBuilder = BookDeconstructionFollowupMenuBuilderService();
    const planBuilder = BookDeconstructionDerivedProjectPlanBuilderService();

    test('builds reusable derived project plan from a followup option', () {
      final input = BookDeconstructionInput(
        extractionId: 'extract_001',
        title: '海上城邦',
        sourceDocuments: const <BookDeconstructionSourceDocument>[
          BookDeconstructionSourceDocument(
            id: 'source_primary',
            title: '海上城邦',
            content: '正文',
          ),
        ],
        preferredContinuationDirection:
            BookDeconstructionContinuationDirection.generalNovelPreferred,
      );
      final menu = menuBuilder.build(
        preferredDirection: input.preferredContinuationDirection,
      );

      final plan = planBuilder.build(
        input: input,
        followupMenu: menu,
        followupOptionId: 'general_novel',
      );

      expect(plan.planId, 'derive_extract_001_general_novel');
      expect(plan.sourceExtractionId, 'extract_001');
      expect(plan.targetProjectTypeId, 'novel');
      expect(plan.targetProjectStrategyId, 'general_novel');
      expect(plan.targetModeId, isEmpty);
      expect(plan.recommendedBuildTier, ContinuityBuildTier.quickBridge);
      expect(plan.suggestedProjectTitle, '海上城邦 - 一般小说');
    });
  });
}
