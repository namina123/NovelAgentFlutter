import 'review_contract.dart';
import 'review_contract_catalog.dart';
import 'review_summary.dart';

class ReviewSummaryBuilderService {
  const ReviewSummaryBuilderService();

  ReviewSummary buildSummary(ReviewContract review) {
    final evidencePaths = <String>[];
    _appendUnique(evidencePaths, review.evidencePaths);
    for (final finding in review.findings) {
      _appendUnique(evidencePaths, finding.evidencePaths);
    }
    return ReviewSummary(
      reviewId: review.reviewId,
      reviewType: review.reviewType,
      reviewerId: review.reviewer.reviewerId,
      reviewerRole: review.reviewer.reviewerRole,
      riskLevel: review.riskLevel,
      recommendedDisposition: review.recommendedDisposition,
      findingCount: review.findings.length,
      blockingFindingCount: review.findings
          .where((finding) => finding.severity == ReviewFindingSeverities.blocking)
          .length,
      summary: review.summary,
      repairBrief: review.repairBrief,
      evidencePaths: evidencePaths,
      metadata: review.metadata,
    );
  }

  void _appendUnique(List<String> target, List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && !target.contains(clean)) {
        target.add(clean);
      }
    }
  }
}
