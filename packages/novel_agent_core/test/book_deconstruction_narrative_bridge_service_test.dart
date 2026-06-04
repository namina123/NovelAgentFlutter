import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionNarrativeBridgeService', () {
    const service = BookDeconstructionNarrativeBridgeService();
    const promotionService = BookDeconstructionNarrativePromotionService();
    const followupMenuBuilder = BookDeconstructionFollowupMenuBuilderService();
    const derivedPlanBuilder =
        BookDeconstructionDerivedProjectPlanBuilderService();

    test(
      'builds analysis claims, profile proposal and semantic review from deconstruction output',
      () {
        final input = BookDeconstructionInput(
          extractionId: 'extract_001',
          title: '海上城邦',
          sourceDocuments: const <BookDeconstructionSourceDocument>[
            BookDeconstructionSourceDocument(
              id: 'source_primary',
              title: '海上城邦',
              content: '正文',
              relativePathHint: 'imports/source_book.md',
            ),
          ],
          operatorNotes: '先桥接为分析态事实。',
        );
        const extraction = BookDeconstructionExtractionResult(
          extractionId: 'extract_001',
          sourceTitle: '海上城邦',
          premises: <InspirationPremise>[
            InspirationPremise(
              id: 'premise_1',
              displayName: '核心前提',
              summary: '主角被迫卷入城邦与航线垄断的斗争。',
            ),
          ],
          storyOutlineSummary: '港口风暴揭开城邦议会与航线垄断的暗线。',
          chapterOutlines: <BookDeconstructionChapterOutline>[
            BookDeconstructionChapterOutline(
              id: 'chapter_1',
              title: '港口风暴',
              sequence: 1,
              summary: '主角在港口卷入追捕。',
            ),
          ],
          styleProfiles: <StyleProfile>[
            StyleProfile(id: 'style_1', displayName: '商业节奏', summary: '冲突推进快。'),
          ],
          worldRuleSets: <WorldRuleSet>[
            WorldRuleSet(
              id: 'world_1',
              displayName: '航线规则',
              summary: '权力依附于航线控制。',
              rules: <String>['印记媒介才能释放超常能力'],
            ),
          ],
          characterProfiles: <CharacterProfile>[
            CharacterProfile(
              id: 'hero',
              displayName: '林砚',
              summary: '被迫卷入风暴的主角。',
            ),
          ],
          organizationProfiles: <OrganizationProfile>[
            OrganizationProfile(
              id: 'council',
              displayName: '黑潮议会',
              summary: '掌控港口秩序的势力。',
            ),
          ],
          continuityHints: BookDeconstructionContinuityHints(
            scopeMap: BookDeconstructionScopeMap(
              scopes: <BookDeconstructionScopeHint>[
                BookDeconstructionScopeHint(
                  id: 'scope_harbor',
                  displayName: '港区线',
                ),
              ],
            ),
            mechanicHints: <BookDeconstructionMechanicHint>[
              BookDeconstructionMechanicHint(
                id: 'mechanic_hidden_memory',
                displayName: '记忆残留',
                sourceKind: BookDeconstructionHintSourceKind.inferredHint,
                notes: '疑似存在只有主角保留记忆的异常线索。',
              ),
            ],
            notes: 'mechanic hint is inferred',
          ),
        );

        final bundle = service.build(
          input: input,
          extractionResult: extraction,
        );

        expect(bundle.claims, isNotEmpty);
        expect(
          bundle.claims.map((claim) => claim.claimNamespace),
          containsAll(<String>[
            'analysis.deconstruction.premise',
            'analysis.deconstruction.story_outline',
            'analysis.explainer.continuity.mechanic_hint',
          ]),
        );
        expect(
          bundle.claims
              .where(
                (claim) =>
                    claim.claimNamespace ==
                    'analysis.explainer.continuity.mechanic_hint',
              )
              .single
              .source
              .sourceType,
          NarrativeSourceTypes.explainerInterpreted,
        );
        expect(bundle.profileProposals, hasLength(1));
        expect(
          bundle.profileProposals.single.proposalStatus,
          NarrativeProfileLifecycleStatus.proposed,
        );
        expect(
          bundle.profileProposals.single.source.sourceType,
          NarrativeSourceTypes.explainerInterpreted,
        );
        expect(bundle.semanticReviews, hasLength(1));
        expect(
          bundle.semanticReviews.single.recommendedDisposition,
          SemanticReviewRecommendedDisposition.acceptWithNote,
        );
        expect(bundle.semanticReviews.single.questionedClaimIds, isNotEmpty);

        final promoted = promotionService.promote(
          analysisBundle: bundle,
          claimStatus:
              BookDeconstructionNarrativeBridgeConstants.acceptedStatus,
        );
        expect(
          promoted.claims
              .where((claim) => claim.claimId.endsWith('_promoted'))
              .map((claim) => claim.claimNamespace),
          contains('continuity.foundation.story_outline'),
        );
        expect(
          promoted.profileProposals.single.proposalStatus,
          NarrativeProfileLifecycleStatus.accepted,
        );

        final menu = followupMenuBuilder.build(
          preferredDirection:
              BookDeconstructionContinuationDirection.generalNovelPreferred,
        );
        final plan = derivedPlanBuilder.build(
          input: input,
          followupMenu: menu,
          followupOptionId: 'general_novel',
          narrativeArtifacts: promoted,
        );

        final inheritedArtifacts = ValueReaders.mapList(
          plan.metadata['inherited_narrative_artifacts'],
        );
        expect(inheritedArtifacts, isNotEmpty);
        expect(
          inheritedArtifacts
              .map((entry) => ValueReaders.stringValue(entry['status']))
              .toSet(),
          contains(BookDeconstructionNarrativeBridgeConstants.acceptedStatus),
        );
      },
    );
  });
}
