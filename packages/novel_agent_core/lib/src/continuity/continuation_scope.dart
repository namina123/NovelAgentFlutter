enum ContinuationScopeKind {
  global,
  world,
  volume,
  arc,
  route,
  instance,
  chapterWindow,
  custom,
}

class ContinuationScope {
  const ContinuationScope({
    required this.id,
    required this.displayName,
    this.kind = ContinuationScopeKind.custom,
    this.parentScopeId = '',
    this.tags = const <String>[],
    this.activationSignals = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final ContinuationScopeKind kind;
  final String parentScopeId;
  final List<String> tags;
  final List<String> activationSignals;
  final Map<String, Object?> metadata;
}
