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
          'continuation',
          'fanfic',
          'future_extensions',
        ]);
        expect(menu.highlightedGroupId, 'fanfic');
        expect(menu.highlightedOptionId, 'fanfic_seed_autopilot_novel');
        expect(
          menu.highlightedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
        expect(menu.allowsMultipleDerivedProjects, isTrue);

        final continuationOptions = menu.groups.first.options;
        expect(continuationOptions, hasLength(1));
        expect(continuationOptions.first.id, 'continuation_novel');
        expect(
          continuationOptions.first.recommendedBuildTier,
          ContinuityBuildTier.quickBridge,
        );

        final fanficOptions = menu.groups[1].options;
        expect(
          fanficOptions.map((item) => item.id),
          containsAll(<String>[
            'fanfic_seed_autopilot_novel',
            'fanfic_full_outline_consensus',
            'fanfic_volume_checkpoint_handoff',
            'fanfic_chapter_brief_supervised',
            'fanfic_salvage_restructure_existing',
          ]),
        );
        expect(
          fanficOptions
              .firstWhere((item) => item.id == 'fanfic_full_outline_consensus')
              .recommendedBuildTier,
          ContinuityBuildTier.deepReconstruction,
        );
        expect(
          fanficOptions
              .firstWhere((item) => item.id == 'fanfic_chapter_brief_supervised')
              .recommendedBuildTier,
          ContinuityBuildTier.standardFoundation,
        );
        expect(
          fanficOptions
              .firstWhere((item) => item.id == 'fanfic_seed_autopilot_novel')
              .sourceInheritanceMode,
          BookDeconstructionSourceInheritanceMode.fanfic,
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
        expect(menu.notes, contains('continuation / fanfic 基座'));
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
        followupOptionId: 'continuation_novel',
      );

      expect(plan.planId, 'derive_extract_001_continuation_novel');
      expect(plan.sourceExtractionId, 'extract_001');
      expect(plan.targetProjectTypeId, 'novel');
      expect(plan.targetProjectStrategyId, 'general_novel');
      expect(plan.targetModeId, isEmpty);
      expect(
        plan.sourceInheritanceMode,
        BookDeconstructionSourceInheritanceMode.continuation,
      );
      expect(plan.recommendedBuildTier, ContinuityBuildTier.quickBridge);
      expect(plan.suggestedProjectTitle, '海上城邦 - 一般小说');
    });
  });
}
