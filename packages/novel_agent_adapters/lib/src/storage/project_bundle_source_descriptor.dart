class ProjectBundleSourceDescriptor {
  const ProjectBundleSourceDescriptor({
    required this.sourcePath,
    required this.rootDirectoryPath,
    required this.bundleFilePath,
    required this.bundleContent,
  });

  final String sourcePath;
  final String rootDirectoryPath;
  final String bundleFilePath;
  final String bundleContent;
}
