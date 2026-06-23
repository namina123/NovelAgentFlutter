class ProjectOpenViewData {
  const ProjectOpenViewData({
    required this.title,
    required this.description,
    required this.projectsRootPath,
    required this.currentProjectPath,
    required this.allowImportLocal,
    required this.entries,
    required this.selectedEntryId,
    required this.status,
    this.hasLoaded = true,
  });

  final String title;
  final String description;
  final String projectsRootPath;
  final String currentProjectPath;
  final bool allowImportLocal;
  final List<ProjectOpenEntryViewData> entries;
  final String selectedEntryId;
  final String status;

  /// 是否已完成过至少一次刷新。区分"正在加载（还没数据）"与"加载完了确实没有作品"。
  final bool hasLoaded;

  factory ProjectOpenViewData.initial() {
    return const ProjectOpenViewData(
      title: '作品库',
      description: '选择已有作品，或新建一部作品继续创作。',
      projectsRootPath: '',
      currentProjectPath: '',
      allowImportLocal: true,
      entries: <ProjectOpenEntryViewData>[],
      selectedEntryId: '',
      status: '',
      hasLoaded: false,
    );
  }

  ProjectOpenViewData copyWith({
    String? title,
    String? description,
    String? projectsRootPath,
    String? currentProjectPath,
    bool? allowImportLocal,
    List<ProjectOpenEntryViewData>? entries,
    String? selectedEntryId,
    String? status,
    bool? hasLoaded,
  }) {
    return ProjectOpenViewData(
      title: title ?? this.title,
      description: description ?? this.description,
      projectsRootPath: projectsRootPath ?? this.projectsRootPath,
      currentProjectPath: currentProjectPath ?? this.currentProjectPath,
      allowImportLocal: allowImportLocal ?? this.allowImportLocal,
      entries: entries ?? this.entries,
      selectedEntryId: selectedEntryId ?? this.selectedEntryId,
      status: status ?? this.status,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class ProjectOpenEntryViewData {
  const ProjectOpenEntryViewData({
    required this.id,
    required this.title,
    required this.path,
    required this.projectTypeLabel,
    required this.storageLabel,
    required this.runtimeBaselineLabel,
    required this.lastModifiedLabel,
    required this.sourceBadges,
    required this.isCurrentProject,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String path;
  final String projectTypeLabel;
  final String storageLabel;
  final String runtimeBaselineLabel;
  final String lastModifiedLabel;
  final List<String> sourceBadges;
  final bool isCurrentProject;
  final bool isSelected;

  ProjectOpenEntryViewData copyWith({
    bool? isSelected,
  }) {
    return ProjectOpenEntryViewData(
      id: id,
      title: title,
      path: path,
      projectTypeLabel: projectTypeLabel,
      storageLabel: storageLabel,
      runtimeBaselineLabel: runtimeBaselineLabel,
      lastModifiedLabel: lastModifiedLabel,
      sourceBadges: sourceBadges,
      isCurrentProject: isCurrentProject,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
