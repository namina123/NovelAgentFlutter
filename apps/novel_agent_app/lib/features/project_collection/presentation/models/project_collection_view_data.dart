class ProjectCollectionViewData {
  const ProjectCollectionViewData({
    required this.kind,
    required this.title,
    required this.description,
    required this.entries,
    required this.selectedEntryId,
    required this.detailPath,
    required this.detailBody,
    required this.status,
  });

  final String kind;
  final String title;
  final String description;
  final List<ProjectCollectionEntryViewData> entries;
  final String selectedEntryId;
  final String detailPath;
  final String detailBody;
  final String status;

  factory ProjectCollectionViewData.initial() {
    return const ProjectCollectionViewData(
      kind: 'tasks',
      title: '任务',
      description: '',
      entries: <ProjectCollectionEntryViewData>[],
      selectedEntryId: '',
      detailPath: '',
      detailBody: '',
      status: '',
    );
  }
}

class ProjectCollectionEntryViewData {
  const ProjectCollectionEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    required this.relativePath,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String description;
  final String relativePath;
  final bool isSelected;
}
