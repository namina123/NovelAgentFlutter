class KnowledgeBaseBranchDefinition {
  const KnowledgeBaseBranchDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.opensProjectAssetsByDefault = false,
    this.preferredAssetsTabId = '',
  });

  final String id;
  final String title;
  final String description;
  final bool opensProjectAssetsByDefault;
  final String preferredAssetsTabId;
}
