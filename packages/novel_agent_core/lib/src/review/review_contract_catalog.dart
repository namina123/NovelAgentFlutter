abstract final class ReviewRiskLevels {
  static const String none = 'none';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> knownValues = <String>[
    none,
    low,
    medium,
    high,
    critical,
  ];
}

abstract final class ReviewFindingSeverities {
  static const String info = 'info';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String blocking = 'blocking';

  static const List<String> knownValues = <String>[
    info,
    low,
    medium,
    high,
    blocking,
  ];
}

abstract final class ReviewRecommendedDispositions {
  static const String accept = 'accept';
  static const String remind = 'remind';
  static const String adjustNext = 'adjust_next';
  static const String repair = 'repair';
  static const String checkpointUser = 'checkpoint_user';
  static const String manualAttention = 'manual_attention';

  static const List<String> knownValues = <String>[
    accept,
    remind,
    adjustNext,
    repair,
    checkpointUser,
    manualAttention,
  ];
}

abstract final class ReviewContractValidationCodes {
  static const String missingReviewId = 'missing_review_contract_id';
  static const String missingReviewType = 'missing_review_contract_type';
  static const String invalidRiskLevel = 'invalid_review_contract_risk_level';
  static const String invalidRecommendedDisposition =
      'invalid_review_contract_recommended_disposition';
  static const String missingEvidencePaths =
      'missing_review_contract_evidence_paths';
  static const String repairDispositionNeedsBrief =
      'repair_review_contract_needs_repair_brief';
  static const String missingReviewerId = 'missing_review_reviewer_id';
  static const String missingReviewerRole = 'missing_review_reviewer_role';
  static const String missingBasisType = 'missing_review_basis_type';
  static const String missingBasisAnchor = 'missing_review_basis_anchor';
  static const String missingFindingId = 'missing_review_finding_id';
  static const String missingFindingSummary = 'missing_review_finding_summary';
  static const String invalidFindingSeverity =
      'invalid_review_finding_severity';
  static const String missingArtifactId = 'missing_review_artifact_id';
  static const String missingArtifactReviewId = 'missing_review_artifact_review_id';
  static const String missingArtifactPath = 'missing_review_artifact_path';
  static const String missingSummaryReviewId = 'missing_review_summary_review_id';
  static const String missingSummaryReviewType =
      'missing_review_summary_review_type';
  static const String missingSummaryReviewerId =
      'missing_review_summary_reviewer_id';
  static const String missingSummaryReviewerRole =
      'missing_review_summary_reviewer_role';
  static const String invalidSummaryRiskLevel =
      'invalid_review_summary_risk_level';
  static const String invalidSummaryRecommendedDisposition =
      'invalid_review_summary_recommended_disposition';
  static const String invalidSummaryFindingCount =
      'invalid_review_summary_finding_count';
}
