import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionReviewGateService', () {
    test(
      'respects custom review policy when evidence requirement is relaxed',
      () {
        const service = ReferenceExtractionReviewGateService();

        final outcome = service.review(
          const <ReferenceExtractionProposal>[
            ReferenceExtractionProposal(
              proposalId: 'proposal_1',
              entryId: 'entry_1',
              entryNamespace: 'semantic_extraction',
              entryKind: ReferenceEntryKinds.knowledgeFact,
              title: '高置信度但无证据',
              summary: '用于测试关闭证据硬门槛后的审核行为。',
              confidence: 0.91,
            ),
          ],
          policy: const ReferenceExtractionReviewPolicy(
            acceptanceThreshold: 0.9,
            candidateThreshold: 0.5,
            requireEvidence: false,
          ),
        );

        expect(outcome.acceptedProposalIds, <String>['proposal_1']);
      },
    );
  });
}
