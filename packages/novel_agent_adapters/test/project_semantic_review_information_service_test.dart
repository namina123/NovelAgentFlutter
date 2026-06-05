import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

import '../lib/src/workflow/project_semantic_review_information_service.dart';

void main() {
  group('ProjectSemanticReviewInformationService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectSemanticReviewInformationService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-semantic-review-information-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '语义审稿信息桥测试',
        rootPath: tempDirectory.path,
      );
      service = ProjectSemanticReviewInformationService(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'persist writes bridged semantic review knowledge design and research artifacts plus projections',
      () async {
        final result = await service.persist(
          project: project,
          reviews: <NarrativeSemanticReview>[
            NarrativeSemanticReview(
              reviewId: 'review-1',
              source: const NarrativeSourceRef(
                sourceType: NarrativeSourceTypes.reviewer,
                sourceId: 'reviewer-agent',
                label: '结构审稿员',
              ),
              recommendedDisposition:
                  SemanticReviewRecommendedDisposition.acceptWithNote,
              targetRefs: const <NarrativeRef>[
                NarrativeRef(
                  refType: NarrativeRefTypes.chapter,
                  refId: 'chapter-01',
                  relativePath: 'chapters/ch01.md',
                  displayName: '第01章',
                ),
              ],
              suggestedClaims: <NarrativeStateClaim>[
                NarrativeStateClaim(
                  claimId: 'claim-knowledge-1',
                  claimNamespace: 'analysis.review.world_rule',
                  claimLabel: '誓约代价规则',
                  claimPayload: const <String, Object?>{
                    'summary': '誓约代价会跨章累积，违反后会立即失声。',
                  },
                  source: const NarrativeSourceRef(
                    sourceType: NarrativeSourceTypes.reviewer,
                    sourceId: 'reviewer-agent',
                  ),
                  confidence: 0.78,
                ),
                NarrativeStateClaim(
                  claimId: 'claim-design-1',
                  claimNamespace: 'analysis.review.design.symbol',
                  claimLabel: '镜潮双回环',
                  claimPayload: const <String, Object?>{
                    'summary': '章首章尾要保持镜潮双回环。',
                    'design_kind': 'symbol_system',
                  },
                  source: const NarrativeSourceRef(
                    sourceType: NarrativeSourceTypes.reviewer,
                    sourceId: 'reviewer-agent',
                  ),
                  confidence: 0.81,
                  uncertainty: '需要确认后再提升到正式写作规则。',
                ),
              ],
              findings: const <SemanticReviewFinding>[
                SemanticReviewFinding(
                  findingId: 'finding-1',
                  severity: SemanticReviewSeverity.high,
                  summary: '需要补查镜潮回扣是否在后续章节稳定复现。',
                  suggestedAction: '整理后续章节的镜潮回扣位置。',
                  confidence: 0.69,
                ),
              ],
            ),
          ],
        );

        expect(
          ValueReaders.stringList(result['knowledge_card_ids']),
          contains('knowledge_review-1_claim-knowledge-1'),
        );
        expect(
          ValueReaders.stringList(result['design_element_ids']),
          contains('design_review-1_claim-design-1'),
        );
        expect(
          ValueReaders.stringList(result['research_note_ids']),
          contains('research_review-1_finding-1'),
        );
        expect(
          ValueReaders.stringList(result['changed_paths']),
          containsAll(<String>[
            '.novel_agent/information/knowledge_cards/knowledge_review-1_claim-knowledge-1.json',
            '.novel_agent/information/design_elements/design_review-1_claim-design-1.json',
            '.novel_agent/information/research_notes/research_review-1_finding-1.json',
            'knowledge/项目知识摘要.md',
            'knowledge/设计元素摘要.md',
            'research/资料研究摘要.md',
          ]),
        );

        final knowledgeFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}knowledge_review-1_claim-knowledge-1.json',
        );
        final designFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}design_elements${Platform.pathSeparator}design_review-1_claim-design-1.json',
        );
        final researchFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}research_review-1_finding-1.json',
        );
        final designProjection = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}设计元素摘要.md',
        );

        expect(await knowledgeFile.exists(), isTrue);
        expect(await designFile.exists(), isTrue);
        expect(await researchFile.exists(), isTrue);
        expect(await designProjection.exists(), isTrue);
        expect(
          await knowledgeFile.readAsString(),
          contains('analysis.review.knowledge.world_rule'),
        );
        expect(
          await designFile.readAsString(),
          contains('analysis.review.design.symbol'),
        );
        expect(
          await researchFile.readAsString(),
          contains('analysis_review_finding'),
        );
        expect(await designProjection.readAsString(), contains('镜潮双回环'));
      },
    );
  });
}
