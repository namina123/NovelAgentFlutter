enum WorkspaceCommandMode {
  editProjectInfo,
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
    required this.genre,
    required this.premise,
    required this.notes,
    required this.relativePath,
    required this.entryName,
    required this.content,
    required this.sourcePathsText,
    required this.targetDirectory,
  });

  final WorkspaceCommandMode mode;
  final String title;
  final String description;
  final String confirmLabel;
  final String status;
  final String projectTitle;
  final String projectType;
  final String genre;
  final String premise;
  final String notes;
  final String relativePath;
  final String entryName;
  final String content;
  final String sourcePathsText;
  final String targetDirectory;
}

class WorkspaceCommandRequestViewData {
  const WorkspaceCommandRequestViewData({
    required this.mode,
    this.projectTitle = '',
    this.projectType = '',
    this.genre = '',
    this.premise = '',
    this.notes = '',
    this.relativePath = '',
    this.entryName = '',
    this.content = '',
    this.sourcePathsText = '',
    this.targetDirectory = '',
  });

  final WorkspaceCommandMode mode;
  final String projectTitle;
  final String projectType;
  final String genre;
  final String premise;
  final String notes;
  final String relativePath;
  final String entryName;
  final String content;
  final String sourcePathsText;
  final String targetDirectory;
}
