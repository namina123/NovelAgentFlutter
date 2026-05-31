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
  });

  final String title;
  final String description;
  final String projectsRootPath;
  final String currentProjectPath;
  final bool allowImportLocal;
  final List<ProjectOpenEntryViewData> entries;
  final String selectedEntryId;
  final String status;

  factory ProjectOpenViewData.initial() {
    return const ProjectOpenViewData(
      title: '打开项目',
      description: '选择已有项目，或新建一个项目继续工作。',
      projectsRootPath: '',
      currentProjectPath: '',
      allowImportLocal: true,
      entries: <ProjectOpenEntryViewData>[],
      selectedEntryId: '',
      status: '',
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
