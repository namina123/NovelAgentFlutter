enum SemanticReviewSeverity {
  info('info'),
  low('low'),
  medium('medium'),
  high('high'),
  blocking('blocking');

  const SemanticReviewSeverity(this.id);

  final String id;

  static SemanticReviewSeverity fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final severity in SemanticReviewSeverity.values) {
      if (severity.id == clean) {
        return severity;
      }
    }
    return SemanticReviewSeverity.info;
  }
}
