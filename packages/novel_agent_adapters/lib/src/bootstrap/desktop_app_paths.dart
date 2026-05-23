class DesktopAppPaths {
  const DesktopAppPaths({
    required this.settingsRootPath,
    required this.defaultProjectRootPath,
    required this.settingsSearchRoots,
  });

  final String settingsRootPath;
  final String defaultProjectRootPath;
  final List<String> settingsSearchRoots;
}
