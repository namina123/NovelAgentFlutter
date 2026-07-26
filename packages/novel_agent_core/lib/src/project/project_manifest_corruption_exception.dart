class ProjectManifestCorruptionException implements Exception {
  const ProjectManifestCorruptionException({
    required this.rootPath,
    this.message = '项目清单损坏或包含当前版本无法识别的合同字段。',
  });

  final String rootPath;
  final String message;

  @override
  String toString() => '$message 路径：$rootPath';
}
