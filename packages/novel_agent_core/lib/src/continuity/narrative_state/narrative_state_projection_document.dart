class NarrativeStateProjectionDocument {
  const NarrativeStateProjectionDocument({
    required this.projectionId,
    required this.relativePath,
    required this.title,
    required this.markdown,
  });

  static const String rulesProjectionId = 'narrative_state_rules';
  static const String rulesRelativePath = 'continuity/叙事状态规则.md';
  static const String recentChangesProjectionId = 'recent_state_changes';
  static const String recentChangesRelativePath = 'continuity/最近状态变化.md';
  static const String constraintSummaryProjectionId =
      'constraint_summary_projection';
  static const String constraintSummaryRelativePath = 'constraints/项目约束摘要.md';
  static const String semanticReviewSummaryProjectionId =
      'semantic_review_summary';
  static const String semanticReviewSummaryRelativePath = 'reviews/语义复核摘要.md';

  final String projectionId;
  final String relativePath;
  final String title;
  final String markdown;
}
