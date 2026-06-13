import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('InformationEvidenceReviewContractMapperService', () {
    const service = InformationEvidenceReviewContractMapperService();
    const handoffService = ReviewRepairHandoffService();
    const summaryBuilder = ReviewSummaryBuilderService();

    test('maps awaiting confirmation into shared checkpoint-user review', () {
      final review = service.buildReview(
        executionId: 'information_waiting_001',
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'checkpoint_user',
          reason: 'information_waiting_user',
          summary: '待确认研究 1 项。',
          waitingUser: true,
          changedPaths: <String>[
            '.novel_agent/information/research_requests/request_1.json',
          ],
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.blocking,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.checkpointUser,
            awaitingConfirmationCount: 1,
            waitingUser: true,
          ),
        ),
      )!;

      final handoff = handoffService.handoffFromReview(review);
      final summary = summaryBuilder.buildSummary(review);

      expect(review.validateBasics(), isEmpty);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.checkpointUser,
      );
      expect(review.riskLevel, ReviewRiskLevels.high);
      expect(review.findings, hasLength(1));
      expect(handoff.action, RepairHandoffActions.waitingUser);
      expect(summary.validateBasics(), isEmpty);
      expect(
        summary.recommendedDisposition,
        ReviewRecommendedDispositions.checkpointUser,
      );
    });

    test('maps gateway failure into blocking repair review', () {
      final review = service.buildReview(
        executionId: 'information_repair_001',
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'repair',
          reason: 'information_gateway_failed',
          summary: '研究网关失败 1 项。',
          requiresRepair: true,
          changedPaths: <String>['research/资料研究摘要.md'],
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.blocking,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.repair,
            gatewayFailureCount: 1,
            requiresRepair: true,
          ),
        ),
      )!;

      final handoff = handoffService.handoffFromReview(review);

      expect(review.validateBasics(), isEmpty);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.repair,
      );
      expect(review.repairBrief, contains('修复资料网关'));
      expect(review.findings, hasLength(1));
      expect(review.findings.single.findingId, 'information_gateway_failed');
      expect(handoff.action, RepairHandoffActions.createBlockingRepair);
      expect(
        handoff.repairRequest?.targetPaths,
        contains('research/资料研究摘要.md'),
      );
    });

    test('maps source insufficiency into non-blocking remind review', () {
      final review = service.buildReview(
        executionId: 'information_remind_001',
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'accept',
          summary: '严谨来源不足 1 项。',
          changedPaths: <String>['research/来源说明.md'],
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.warning,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.accept,
            rigorousSourceInsufficientCount: 1,
          ),
        ),
      )!;

      final handoff = handoffService.handoffFromReview(review);

      expect(review.validateBasics(), isEmpty);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.remind,
      );
      expect(review.riskLevel, ReviewRiskLevels.medium);
      expect(handoff.action, RepairHandoffActions.noteOnly);
      expect(handoff.blocksMainFlow, isFalse);
    });
  });
}
