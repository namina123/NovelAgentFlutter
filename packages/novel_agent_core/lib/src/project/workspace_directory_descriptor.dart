class WorkspaceDirectoryDescriptor {
  const WorkspaceDirectoryDescriptor({
    required this.path,
    required this.name,
    this.purpose = '',
  });

  final String path;
  final String name;
  final String purpose;
}
