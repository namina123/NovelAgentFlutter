class EntityIdentity {
  const EntityIdentity({
    required this.id,
    required this.kind,
    required this.displayName,
    this.summary = '',
    this.aliases = const <String>[],
    this.nameHistory = const <String>[],
  });

  final String id;
  final String kind;
  final String displayName;
  final String summary;
  final List<String> aliases;
  final List<String> nameHistory;
}
