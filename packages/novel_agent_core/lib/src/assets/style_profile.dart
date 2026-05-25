class StyleProfile {
  const StyleProfile({
    required this.id,
    required this.displayName,
    required this.summary,
    this.guardrails = const <String>[],
  });

  final String id;
  final String displayName;
  final String summary;
  final List<String> guardrails;
}
