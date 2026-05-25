class CharacterProfile {
  const CharacterProfile({
    required this.id,
    required this.displayName,
    this.summary = '',
    this.aliases = const <String>[],
    this.nameHistory = const <String>[],
    this.storyRole = '',
    this.traits = const <String>[],
    this.organizationIds = const <String>[],
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final List<String> aliases;
  final List<String> nameHistory;
  final String storyRole;
  final List<String> traits;
  final List<String> organizationIds;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
