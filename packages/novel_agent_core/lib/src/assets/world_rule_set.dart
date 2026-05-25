class WorldRuleSet {
  const WorldRuleSet({
    required this.id,
    required this.displayName,
    this.summary = '',
    this.rules = const <String>[],
    this.forbiddenAssumptions = const <String>[],
  });

  final String id;
  final String displayName;
  final String summary;
  final List<String> rules;
  final List<String> forbiddenAssumptions;
}
