enum WorkspaceCommandMode {
  editProjectInfo,
  transitionProjectType,
  createFile,
  createFolder,
  importFiles,
}

class WorkspaceCommandViewData {
  const WorkspaceCommandViewData({
    required this.mode,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.status,
    required this.projectTitle,
    required this.projectType,
    this.transitionTargetProjectTypeId = '',
    this.transitionRuntimeBaselineId = '',
    required this.genre,
    required this.premise,
    required this.notes,
    required this.relativePath,
    required this.entryName,
    required this.content,
    required this.sourcePathsText,
    required this.targetDirectory,
    this.autoDeconstruct = false,
    this.canAutoDeconstruct = false,
    this.importFileSelectionHint = '',
    this.importOutputHint = '',
  });

  final WorkspaceCommandMode mode;
  final String title;
  final String description;
  final String confirmLabel;
  final String status;
  final String projectTitle;
  final String projectType;
  final String transitionTargetProjectTypeId;
  final String transitionRuntimeBaselineId;
  final String genre;
  final String premise;
  final String notes;
  final String relativePath;
  final String entryName;
  final String content;
  final String sourcePathsText;
  final String targetDirectory;
  final bool autoDeconstruct;
  final bool canAutoDeconstruct;
  final String importFileSelectionHint;
  final String importOutputHint;

  WorkspaceCommandViewData copyWith({
    WorkspaceCommandMode? mode,
    String? title,
    String? description,
    String? confirmLabel,
    String? status,
    String? projectTitle,
    String? projectType,
    String? transitionTargetProjectTypeId,
    String? transitionRuntimeBaselineId,
    String? genre,
    String? premise,
    String? notes,
    String? relativePath,
    String? entryName,
    String? content,
    String? sourcePathsText,
    String? targetDirectory,
    bool? autoDeconstruct,
    bool? canAutoDeconstruct,
    String? importFileSelectionHint,
    String? importOutputHint,
  }) {
    return WorkspaceCommandViewData(
      mode: mode ?? this.mode,
      title: title ?? this.title,
      description: description ?? this.description,
      confirmLabel: confirmLabel ?? this.confirmLabel,
      status: status ?? this.status,
      projectTitle: projectTitle ?? this.projectTitle,
      projectType: projectType ?? this.projectType,
      transitionTargetProjectTypeId:
          transitionTargetProjectTypeId ?? this.transitionTargetProjectTypeId,
      transitionRuntimeBaselineId:
          transitionRuntimeBaselineId ?? this.transitionRuntimeBaselineId,
      genre: genre ?? this.genre,
      premise: premise ?? this.premise,
      notes: notes ?? this.notes,
      relativePath: relativePath ?? this.relativePath,
      entryName: entryName ?? this.entryName,
      content: content ?? this.content,
      sourcePathsText: sourcePathsText ?? this.sourcePathsText,
      targetDirectory: targetDirectory ?? this.targetDirectory,
      autoDeconstruct: autoDeconstruct ?? this.autoDeconstruct,
      canAutoDeconstruct: canAutoDeconstruct ?? this.canAutoDeconstruct,
      importFileSelectionHint:
          importFileSelectionHint ?? this.importFileSelectionHint,
      importOutputHint: importOutputHint ?? this.importOutputHint,
    );
  }
}

class WorkspaceCommandRequestViewData {
  const WorkspaceCommandRequestViewData({
    required this.mode,
    this.projectTitle = '',
    this.projectType = '',
    this.transitionTargetProjectTypeId = '',
    this.transitionRuntimeBaselineId = '',
    this.genre = '',
    this.premise = '',
    this.notes = '',
    this.relativePath = '',
    this.entryName = '',
    this.content = '',
    this.sourcePathsText = '',
    this.targetDirectory = '',
    this.autoDeconstruct = false,
  });

  final WorkspaceCommandMode mode;
  final String projectTitle;
  final String projectType;
  final String transitionTargetProjectTypeId;
  final String transitionRuntimeBaselineId;
  final String genre;
  final String premise;
  final String notes;
  final String relativePath;
  final String entryName;
  final String content;
  final String sourcePathsText;
  final String targetDirectory;
  final bool autoDeconstruct;

  List<String> get sourcePaths => sourcePathsText
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  WorkspaceCommandRequestViewData copyWith({
    WorkspaceCommandMode? mode,
    String? projectTitle,
    String? projectType,
    String? transitionTargetProjectTypeId,
    String? transitionRuntimeBaselineId,
    String? genre,
    String? premise,
    String? notes,
    String? relativePath,
    String? entryName,
    String? content,
    String? sourcePathsText,
    String? targetDirectory,
    bool? autoDeconstruct,
  }) {
    return WorkspaceCommandRequestViewData(
      mode: mode ?? this.mode,
      projectTitle: projectTitle ?? this.projectTitle,
      projectType: projectType ?? this.projectType,
      transitionTargetProjectTypeId:
          transitionTargetProjectTypeId ?? this.transitionTargetProjectTypeId,
      transitionRuntimeBaselineId:
          transitionRuntimeBaselineId ?? this.transitionRuntimeBaselineId,
      genre: genre ?? this.genre,
      premise: premise ?? this.premise,
      notes: notes ?? this.notes,
      relativePath: relativePath ?? this.relativePath,
      entryName: entryName ?? this.entryName,
      content: content ?? this.content,
      sourcePathsText: sourcePathsText ?? this.sourcePathsText,
      targetDirectory: targetDirectory ?? this.targetDirectory,
      autoDeconstruct: autoDeconstruct ?? this.autoDeconstruct,
    );
  }
}
