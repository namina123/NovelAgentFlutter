class ForeshadowFeedbackSignal {
  const ForeshadowFeedbackSignal({
    required this.foreshadowId,
    required this.statusHint,
    this.note = '',
    this.relatedTimelineIds = const <String>[],
    this.relatedRelationshipIds = const <String>[],
    this.relatedPaths = const <String>[],
  });

  final String foreshadowId;
  final String statusHint;
  final String note;
  final List<String> relatedTimelineIds;
  final List<String> relatedRelationshipIds;
  final List<String> relatedPaths;
}
