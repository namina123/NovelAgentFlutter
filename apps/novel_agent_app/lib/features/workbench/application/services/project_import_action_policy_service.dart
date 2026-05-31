import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_import_action_policy.dart';

class ProjectImportActionPolicyService {
  ProjectImportActionPolicyService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  static const List<String> _autoDeconstructionExtensions = <String>[
    '.txt',
    '.md',
    '.markdown',
  ];

  final ProjectContentPathPolicyService _contentPathPolicyService;

  ProjectImportActionPolicy build({
    required String projectType,
    required List<String> sourcePaths,
    String requestedTargetDirectory = '',
    bool requestedAutoDeconstruct = false,
  }) {
    final normalizedProjectType = projectType.trim();
    final cleanSourcePaths = sourcePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final canAutoDeconstruct = _supportsAutoDeconstruction(cleanSourcePaths);
    final resolvedTargetDirectory = _resolvedTargetDirectory(
      projectType: normalizedProjectType,
      requestedTargetDirectory: requestedTargetDirectory,
    );
    final autoDeconstruct = canAutoDeconstruct
        ? requestedAutoDeconstruct ||
              (normalizedProjectType == BookDeconstructionConstants.projectTypeId &&
                  cleanSourcePaths.isNotEmpty)
        : false;
    return ProjectImportActionPolicy(
      projectType: normalizedProjectType,
      resolvedTargetDirectory: resolvedTargetDirectory,
      sourcePaths: cleanSourcePaths,
      autoDeconstruct: autoDeconstruct,
      canAutoDeconstruct: canAutoDeconstruct,
      fileSelectionHint: _fileSelectionHint(cleanSourcePaths),
      outputHint: _outputHint(
        projectType: normalizedProjectType,
        cleanSourcePaths: cleanSourcePaths,
        canAutoDeconstruct: canAutoDeconstruct,
        autoDeconstruct: autoDeconstruct,
      ),
    );
  }

  String autoDeconstructionPreviewPath({
    required String projectType,
    required String sourcePath,
  }) {
    final slug = _safeSlug(_fileStem(sourcePath), fallback: 'imported_source');
    if (projectType.trim() == BookDeconstructionConstants.projectTypeId) {
      return 'chapters/book_deconstruction_$slug.md';
    }
    return 'analysis/deconstruction/book_deconstruction_$slug.md';
  }

  bool _supportsAutoDeconstruction(List<String> sourcePaths) {
    if (sourcePaths.length != 1) {
      return false;
    }
    final lowerPath = sourcePaths.single.toLowerCase();
    for (final extension in _autoDeconstructionExtensions) {
      if (lowerPath.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }

  String _resolvedTargetDirectory({
    required String projectType,
    required String requestedTargetDirectory,
  }) {
    final cleanRequestedTarget = requestedTargetDirectory.trim();
    if (cleanRequestedTarget.isNotEmpty) {
      return cleanRequestedTarget;
    }
    if (projectType == BookDeconstructionConstants.projectTypeId) {
      return ProjectContentPathPolicyService.chaptersRoot;
    }
    return _contentPathPolicyService.defaultImportTargetDirectory();
  }

  String _fileSelectionHint(List<String> sourcePaths) {
    if (sourcePaths.isEmpty) {
      return '请选择一个或多个本地文件。';
    }
    if (sourcePaths.length == 1) {
      return '已选择 1 个文件。';
    }
    return '已选择 ${sourcePaths.length} 个文件。自动拆书仅支持单个文本或 Markdown 文件。';
  }

  String _outputHint({
    required String projectType,
    required List<String> cleanSourcePaths,
    required bool canAutoDeconstruct,
    required bool autoDeconstruct,
  }) {
    if (cleanSourcePaths.isEmpty) {
      return projectType == BookDeconstructionConstants.projectTypeId
          ? '拆书项目默认允许自动拆书；选择单个 .txt / .md / .markdown 文件后会自动启用。'
          : '自动拆书仅支持单个 .txt / .md / .markdown 文件。';
    }
    if (!canAutoDeconstruct) {
      return '当前选择不支持自动拆书；请改为单个 .txt / .md / .markdown 文件。';
    }
    final previewPath = autoDeconstructionPreviewPath(
      projectType: projectType,
      sourcePath: cleanSourcePaths.single,
    );
    return projectType == BookDeconstructionConstants.projectTypeId
        ? '导入原文会归档到 chapters/，自动拆书预演纪要会写入 $previewPath。'
        : '自动拆书预演纪要会写入 $previewPath，原始导入文件仍保留在所选目标目录。';
  }

  String _fileStem(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final fileName = normalized.split('/').last;
    final separatorIndex = fileName.lastIndexOf('.');
    if (separatorIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, separatorIndex);
  }

  String _safeSlug(String value, {required String fallback}) {
    final clean = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return clean.isEmpty ? fallback : clean;
  }
}
