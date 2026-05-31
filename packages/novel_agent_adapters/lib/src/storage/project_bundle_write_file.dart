class ProjectBundleWriteFile {
  const ProjectBundleWriteFile({
    required this.entryKind,
    required this.entryId,
    required this.targetPath,
    required this.content,
  });

  final String entryKind;
  final String entryId;
  final String targetPath;
  final String content;
}
