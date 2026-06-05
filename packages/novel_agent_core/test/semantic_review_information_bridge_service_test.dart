import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SemanticReviewInformationBridgeService', () {
    const service = SemanticReviewInformationBridgeService();

    test(
      'bridges explainer semantic review suggested claims and findings into analysis proposals',
      () {
        final review = NarrativeSemanticReview(
          reviewId: 'review-explainer-1',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.explainerInterpreted,
            sourceId: 'explainer-agent',
            label: '解书分析器',
          ),
          recommendedDisposition:
              SemanticReviewRecommendedDisposition.acceptWithNote,
          targetRefs: const <NarrativeRef>[
            NarrativeRef(
              refType: NarrativeRefTypes.chapter,
              refId: 'chapter-01',
              displayName: '第01章',
            ),
          ],
          suggestedClaims: <NarrativeStateClaim>[
            NarrativeStateClaim(
              claimId: 'claim-knowledge-1',
              claimNamespace: 'analysis.explainer.world_rule',
              claimLabel: '镜潮互文',
              claimPayload: const <String, Object?>{
                'summary': '镜与潮共同承担身份映照的解释层规律。',
              },
              source: const NarrativeSourceRef(
                sourceType: NarrativeSourceTypes.explainerInterpreted,
                sourceId: 'explainer-agent',
              ),
              evidenceRefs: const <NarrativeEvidenceRef>[
                NarrativeEvidenceRef(
                  evidenceType: NarrativeEvidenceTypes.reviewNote,
                  evidenceId: 'evidence-knowledge-1',
                  summary: '本章多次并置镜面与潮声。',
                ),
              ],
              confidence: 0.72,
            ),
            NarrativeStateClaim(
              claimId: 'claim-design-1',
              claimNamespace: 'analysis.explainer.design.structure',
              claimLabel: '回环结构',
              claimPayload: const <String, Object?>{
                'summary': '章首章末使用同一意象形成回环。',
                'design_kind': 'structure_pattern',
              },
              source: const NarrativeSourceRef(
                sourceType: NarrativeSourceTypes.explainerInterpreted,
                sourceId: 'explainer-agent',
              ),
              evidenceRefs: const <NarrativeEvidenceRef>[
                NarrativeEvidenceRef(
                  evidenceType: NarrativeEvidenceTypes.reviewNote,
                  evidenceId: 'evidence-design-1',
                  summary: '首尾都落在潮声与镜面的反射描写。',
                ),
              ],
              confidence: 0.76,
              uncertainty: '解释性分析，需要确认后再固化。',
            ),
          ],
          findings: const <SemanticReviewFinding>[
            SemanticReviewFinding(
              findingId: 'finding-1',
              severity: SemanticReviewSeverity.high,
              summary: '需要补查镜潮母题是否贯穿后续章节。',
              suggestedAction: '整理后续章节中的镜潮对应片段。',
              unableToLocateEvidence: true,
              unlocatableReason: '当前只拿到了章节级摘要。',
              confidence: 0.66,
            ),
          ],
        );

        final result = service.build(review: review);

        expect(result.knowledgeCards, hasLength(1));
        expect(result.designElements, hasLength(1));
        expect(result.researchNotes, hasLength(1));
        expect(
          result.knowledgeCards.single.cardNamespace,
          'analysis.explainer.knowledge.world_rule',
        );
        expect(
          result.designElements.single.designNamespace,
          'analysis.explainer.design.structure',
        );
        expect(
          result.knowledgeCards.single.sourceRefs.single.sourceAuthority,
          InformationSourceAuthorities.analysisInterpreted,
        );
        expect(
          result.designElements.single.lifecycleStatus,
          InformationLifecycleStatuses.proposed,
        );
        expect(
          result.designElements.single.usagePolicy.requiresConfirmation,
          isTrue,
        );
        expect(
          result
              .knowledgeCards
              .single
              .metadata[AnalysisInformationBridgeConstants
              .metadataPromotionPath],
          AnalysisInformationBridgeConstants.promotionPathUserOrPolicy,
        );
        expect(
          result
              .researchNotes
              .single
              .metadata[AnalysisInformationBridgeConstants
              .metadataAnalysisNamespace],
          'analysis.explainer.research.finding',
        );
        expect(result.researchNotes.single.summary, contains('镜潮母题'));
      },
    );

    test('bridges reviewer source into analysis.review namespace only', () {
      final review = NarrativeSemanticReview(
        reviewId: 'reviewer-1',
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.reviewer,
          sourceId: 'reviewer-agent',
        ),
        recommendedDisposition: SemanticReviewRecommendedDisposition.repair,
        suggestedClaims: <NarrativeStateClaim>[
          NarrativeStateClaim(
            claimId: 'claim-review-1',
            claimNamespace: 'analysis.review.patch',
            claimLabel: '誓约代价规则',
            claimPayload: const <String, Object?>{'summary': '誓约代价需要前后统一。'},
            source: const NarrativeSourceRef(
              sourceType: NarrativeSourceTypes.reviewer,
              sourceId: 'reviewer-agent',
            ),
            confidence: 0.81,
          ),
        ],
      );

      final result = service.build(review: review);

      expect(result.knowledgeCards, hasLength(1));
      expect(
        result.knowledgeCards.single.cardNamespace,
        'analysis.review.knowledge.patch',
      );
      expect(
        result.knowledgeCards.single.metadata[AnalysisInformationBridgeConstants
            .metadataPromotionTargetNamespace],
        'writing.knowledge.patch',
      );
      expect(
        result.knowledgeCards.single.cardNamespace.startsWith('writing.'),
        isFalse,
      );
    });
  });
}
