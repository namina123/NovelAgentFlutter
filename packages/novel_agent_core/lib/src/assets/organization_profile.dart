class OrganizationProfile {
  const OrganizationProfile({
    required this.id,
    required this.displayName,
    this.summary = '',
    this.aliases = const <String>[],
    this.nameHistory = const <String>[],
    this.organizationType = '',
    this.memberCharacterIds = const <String>[],
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final List<String> aliases;
  final List<String> nameHistory;
  final String organizationType;
  final List<String> memberCharacterIds;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
