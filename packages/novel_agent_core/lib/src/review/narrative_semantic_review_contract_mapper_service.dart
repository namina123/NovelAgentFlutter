import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state.dart';
import 'review_basis.dart';
import 'review_contract.dart';
import 'review_contract_catalog.dart';
import 'review_finding_contract.dart';
import 'review_reviewer_ref.dart';
import 'review_type_catalog_service.dart';
import 'review_type_constants.dart';

class NarrativeSemanticReviewContractMapperService {
  NarrativeSemanticReviewContractMapperService({
    ReviewTypeCatalogService? reviewTypeCatalogService,
  }) : _reviewTypeCatalogService =
           reviewTypeCatalogService ?? ReviewTypeCatalogService();

  final ReviewTypeCatalogService _reviewTypeCatalogService;

  ReviewContract mapReview({
    required NarrativeSemanticReview review,
    String reviewType = ReviewTypeConstants.general,
    List<String> sourcePaths = const <String>[],
    List<String> targetPaths = const <String>[],
    List<String> reportPaths = const <String>[],
    String createdAt = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 普通项目语义审稿先映射到共享 review contract，后续 repair/summary 才能复用同一条主链。
    final normalizedReviewType = _reviewTypeCatalogService.normalizeReviewType(
      reviewType,
    );
    final normalizedSourcePaths = _mergePaths(
      sourcePaths,
      _pathsFromTargetRefs(review.targetRefs),
    );
    final normalizedTargetPaths = _mergePaths(
      targetPaths,
      _pathsFromTargetRefs(review.targetRefs),
    );
    final evidencePaths = _mergePaths(
      reportPaths,
      _mergePaths(normalizedSourcePaths, normalizedTargetPaths),
    );
    return ReviewContract(
      reviewId: review.reviewId,
      reviewType: normalizedReviewType,
      reviewer: _reviewer(review.source),
      basis: ReviewBasis(
        basisType: 'semantic_review',
        summary: review.summary,
        sourcePaths: normalizedSourcePaths,
        targetPaths: normalizedTargetPaths,
        metadata: <String, Object?>{
          'semantic_review_source_type': review.source.sourceType,
          'semantic_review_source_id': review.source.sourceId,
        },
      ),
      findings: review.findings
          .map(
            (finding) => ReviewFindingContract(
              findingId: finding.findingId,
              severity: _findingSeverity(finding.severity),
              summary: finding.summary,
              suggestedAction: finding.suggestedAction,
              evidencePaths: _findingEvidencePaths(
                finding,
                fallbackPaths: evidencePaths,
              ),
              metadata: <String, Object?>{
                ...finding.metadata,
                'related_claim_ids': finding.relatedClaimIds,
                'unable_to_locate_evidence': finding.unableToLocateEvidence,
                'unlocatable_reason': finding.unlocatableReason,
                'confidence': finding.confidence,
              },
            ),
          )
          .toList(growable: false),
      riskLevel: _riskLevel(review.findings),
      recommendedDisposition: _recommendedDisposition(
        review.recommendedDisposition,
      ),
      repairBrief: _repairBrief(review),
      summary: review.summary,
      evidencePaths: evidencePaths,
      createdAt: createdAt.trim(),
      metadata: <String, Object?>{
        ...review.metadata,
        ...metadata,
        'origin': 'narrative_semantic_review_contract_mapper',
        'semantic_review_recommended_disposition':
            review.recommendedDisposition.id,
      },
    );
  }

  ReviewReviewerRef _reviewer(NarrativeSourceRef source) {
    final reviewerId = source.sourceId.trim().isNotEmpty
        ? source.sourceId.trim()
        : source.sourceType.trim().isNotEmpty
        ? source.sourceType.trim()
        : 'semantic_reviewer';
    return ReviewReviewerRef(
      reviewerId: reviewerId,
      reviewerRole: source.sourceType.trim().isEmpty
          ? 'reviewer'
          : source.sourceType.trim(),
      label: source.label.trim().isNotEmpty
          ? source.label.trim()
          : source.description.trim(),
      metadata: ValueReaders.deepCopyMap(source.metadata),
    );
  }

  String _findingSeverity(SemanticReviewSeverity severity) {
    switch (severity) {
      case SemanticReviewSeverity.blocking:
        return ReviewFindingSeverities.blocking;
      case SemanticReviewSeverity.high:
        return ReviewFindingSeverities.high;
      case SemanticReviewSeverity.medium:
        return ReviewFindingSeverities.medium;
      case SemanticReviewSeverity.low:
        return ReviewFindingSeverities.low;
      case SemanticReviewSeverity.info:
        return ReviewFindingSeverities.info;
    }
  }

  String _riskLevel(List<SemanticReviewFinding> findings) {
    if (findings.any(
      (finding) => finding.severity == SemanticReviewSeverity.blocking,
    )) {
      return ReviewRiskLevels.critical;
    }
    if (findings.any(
      (finding) => finding.severity == SemanticReviewSeverity.high,
    )) {
      return ReviewRiskLevels.high;
    }
    if (findings.any(
      (finding) => finding.severity == SemanticReviewSeverity.medium,
    )) {
      return ReviewRiskLevels.medium;
    }
    if (findings.any(
      (finding) => finding.severity == SemanticReviewSeverity.low,
    )) {
      return ReviewRiskLevels.low;
    }
    return ReviewRiskLevels.none;
  }

  String _recommendedDisposition(
    SemanticReviewRecommendedDisposition disposition,
  ) {
    switch (disposition) {
      case SemanticReviewRecommendedDisposition.repair:
        return ReviewRecommendedDispositions.repair;
      case SemanticReviewRecommendedDisposition.checkpointUser:
        return ReviewRecommendedDispositions.checkpointUser;
      case SemanticReviewRecommendedDisposition.manualAttention:
        return ReviewRecommendedDispositions.manualAttention;
      case SemanticReviewRecommendedDisposition.acceptWithNote:
        return ReviewRecommendedDispositions.remind;
      case SemanticReviewRecommendedDisposition.accept:
        return ReviewRecommendedDispositions.accept;
    }
  }

  String _repairBrief(NarrativeSemanticReview review) {
    if (review.recommendedDisposition !=
        SemanticReviewRecommendedDisposition.repair) {
      return '';
    }
    if (review.summary.trim().isNotEmpty) {
      return review.summary.trim();
    }
    for (final finding in review.findings) {
      if (finding.suggestedAction.trim().isNotEmpty) {
        return finding.suggestedAction.trim();
      }
    }
    return '根据语义审稿结论完成必要修复。';
  }

  List<String> _findingEvidencePaths(
    SemanticReviewFinding finding, {
    required List<String> fallbackPaths,
  }) {
    final result = <String>[];
    for (final evidence in finding.evidenceRefs) {
      _appendIfPresent(result, evidence.targetRef?.relativePath);
      _appendIfPresent(result, evidence.targetRef?.sourcePath);
      _appendIfPresent(
        result,
        ValueReaders.stringValue(evidence.metadata['relative_path']),
      );
      _appendIfPresent(
        result,
        ValueReaders.stringValue(evidence.sourceRef?.metadata['relative_path']),
      );
    }
    if (result.isEmpty) {
      result.addAll(fallbackPaths);
    }
    return result;
  }

  List<String> _pathsFromTargetRefs(List<NarrativeRef> refs) {
    final result = <String>[];
    for (final ref in refs) {
      _appendIfPresent(result, ref.relativePath);
      _appendIfPresent(result, ref.sourcePath);
    }
    return result;
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final value in right) {
      _appendIfPresent(result, value);
    }
    return result;
  }

  void _appendIfPresent(List<String> target, String? value) {
    final clean = (value ?? '').trim().replaceAll('\\', '/');
    if (clean.isEmpty || target.contains(clean)) {
      return;
    }
    target.add(clean);
  }
}
