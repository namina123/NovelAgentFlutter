import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'partial selection only retains claims backed by selected plan items',
    () {
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: 'Harbor City',
        sourceContent:
            'Chapter 1 Harbor Storm\nThe hero enters the city.\n\n'
            'Chapter 2 Council Shadow\nThe council reveals its plan.',
        sourceAbsolutePath: 'D:/Books/harbor_city.md',
      );
      final selectedChapter = buildResult.applicationPlan.items.firstWhere(
        (item) =>
            item.sourceKind == BookDeconstructionArtifactKind.chapterOutline,
      );

      final selected =
          const BookDeconstructionNarrativeArtifactSelectionService().select(
            buildResult: buildResult,
            selectedItemIds: <String>{selectedChapter.id},
          );

      expect(selected.claims, hasLength(1));
      expect(
        selected.claims.single.claimNamespace,
        'analysis.deconstruction.chapter_outline',
      );
      expect(
        selected.claims.single.claimPayload['chapter_id'],
        selectedChapter.sourceId,
      );
      expect(selected.profileProposals, isEmpty);
      expect(selected.semanticReviews, isEmpty);
      expect(selected.knowledgeCards, isEmpty);
    },
  );

  test('full selection preserves aggregate narrative artifacts', () {
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: 'Harbor City',
      sourceContent: 'Chapter 1 Harbor Storm\nThe hero enters the city.',
      sourceAbsolutePath: 'D:/Books/harbor_city.md',
    );

    final selected = const BookDeconstructionNarrativeArtifactSelectionService()
        .select(
          buildResult: buildResult,
          selectedItemIds: buildResult.applicationPlan.items
              .map((item) => item.id)
              .toSet(),
        );

    expect(selected.claims, same(buildResult.narrativeArtifacts.claims));
    expect(selected.profileProposals, isNotEmpty);
    expect(selected.semanticReviews, isNotEmpty);
  });

  test(
    'partial selection preserves claims for selected foreshadow, timeline, and relationship records',
    () {
      const input = BookDeconstructionInput(
        extractionId: 'extract_continuity_assets',
        title: '连续性资产',
        sourceDocuments: <BookDeconstructionSourceDocument>[
          BookDeconstructionSourceDocument(
            id: 'source_primary',
            title: '连续性资产',
            content: '正文',
            relativePathHint: 'sources/original/source.md',
          ),
        ],
      );
      const extraction = BookDeconstructionExtractionResult(
        extractionId: 'extract_continuity_assets',
        sourceTitle: '连续性资产',
        characterProfiles: <CharacterProfile>[
          CharacterProfile(id: 'hero', displayName: '林砚', summary: '被卷入风暴的主角。'),
        ],
        foreshadowRecords: <ForeshadowRecord>[
          ForeshadowRecord(
            id: 'harbor_key',
            title: '港口密钥',
            status: 'planted',
            summary: '密钥会指向终局。',
          ),
        ],
        timelineRecords: <TimelineRecord>[
          TimelineRecord(
            id: 'harbor_storm',
            displayName: '港口风暴',
            summary: '主角卷入追捕。',
          ),
        ],
        relationshipRecords: <RelationshipRecord>[
          RelationshipRecord(
            id: 'hero_council',
            displayName: '林砚与议会',
            leftEntityId: 'hero',
            rightEntityId: 'council',
            summary: '从依附逐步走向对立。',
          ),
        ],
      );
      final plan = BuildBookDeconstructionApplicationPlanUseCase().execute(
        input: input,
        extractionResult: extraction,
      );
      final buildResult = BookDeconstructionDraftBuildResult(
        input: input,
        extractionResult: extraction,
        applicationPlan: plan,
        followupMenu: BookDeconstructionFollowupMenuBuilderService().build(
          preferredDirection:
              BookDeconstructionContinuationDirection.analysisFirst,
        ),
        narrativeArtifacts: BookDeconstructionNarrativeBridgeService().build(
          input: input,
          extractionResult: extraction,
        ),
      );
      final selectedItemIds = plan.items
          .where(
            (item) =>
                item.sourceKind ==
                    BookDeconstructionArtifactKind.foreshadowRecord ||
                item.sourceKind ==
                    BookDeconstructionArtifactKind.timelineRecord ||
                item.sourceKind ==
                    BookDeconstructionArtifactKind.relationshipRecord,
          )
          .map((item) => item.id)
          .toSet();

      final selected =
          const BookDeconstructionNarrativeArtifactSelectionService().select(
            buildResult: buildResult,
            selectedItemIds: selectedItemIds,
          );

      expect(
        selected.claims.map((claim) => claim.claimNamespace),
        unorderedEquals(<String>[
          'analysis.deconstruction.foreshadow_record',
          'analysis.deconstruction.timeline_record',
          'analysis.deconstruction.relationship_record',
        ]),
      );
      expect(
        selected.claims.map((claim) => claim.claimPayload),
        containsAll(<Object>[
          containsPair('foreshadow_id', 'harbor_key'),
          containsPair('timeline_id', 'harbor_storm'),
          containsPair('relationship_id', 'hero_council'),
        ]),
      );
    },
  );
}
