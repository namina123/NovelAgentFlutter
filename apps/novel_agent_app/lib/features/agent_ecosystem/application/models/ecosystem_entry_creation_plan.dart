class EcosystemEntryCreationPlan {
  const EcosystemEntryCreationPlan({
    required this.entryId,
    required this.kind,
    required this.relativePath,
    required this.content,
    required this.title,
  });

  final String entryId;
  final String kind;
  final String relativePath;
  final String content;
  final String title;
}
