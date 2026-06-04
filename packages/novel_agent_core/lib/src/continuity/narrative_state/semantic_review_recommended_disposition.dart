enum SemanticReviewRecommendedDisposition {
  accept('accept'),
  acceptWithNote('accept_with_note'),
  repair('repair'),
  checkpointUser('checkpoint_user'),
  manualAttention('manual_attention');

  const SemanticReviewRecommendedDisposition(this.id);

  final String id;

  static SemanticReviewRecommendedDisposition fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final disposition in SemanticReviewRecommendedDisposition.values) {
      if (disposition.id == clean) {
        return disposition;
      }
    }
    return SemanticReviewRecommendedDisposition.accept;
  }
}
