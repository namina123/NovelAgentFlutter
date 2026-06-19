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
    '.epub',
  ];

  final ProjectContentPathPolicyService _contentPathPolicyService;

  ProjectImportActionPolicy build({
    required String projectType,
    required List<String> sourcePaths,
    String requestedTargetDirectory = '',
    bool requestedAutoDeconstruct = false,
    bool requestedSmartAnalysis = false,
    String smartAnalysisProviderId = '',
    String smartAnalysisModelId = '',
    bool requestedSmartDeconstruction = false,
    String smartDeconstructionProviderId = '',
    String smartDeconstructionModelId = '',
  }) {
    final normalizedProjectType = projectType.trim();
    final cleanSourcePaths = sourcePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final canAutoDeconstruct = _supportsAutoDeconstruction(cleanSourcePaths);
    final canSmartAnalyze =
        normalizedProjectType != BookDeconstructionConstants.projectTypeId;
    final canSmartDeconstruction =
        normalizedProjectType == BookDeconstructionConstants.projectTypeId &&
        cleanSourcePaths.isNotEmpty;
    final cleanSmartAnalysisProviderId = smartAnalysisProviderId.trim();
    final cleanSmartAnalysisModelId = smartAnalysisModelId.trim();
    final resolvedTargetDirectory = _resolvedTargetDirectory(
      projectType: normalizedProjectType,
      requestedTargetDirectory: requestedTargetDirectory,
    );
    final autoDeconstruct = canAutoDeconstruct
        ? requestedAutoDeconstruct ||
              (normalizedProjectType ==
                      BookDeconstructionConstants.projectTypeId &&
                  cleanSourcePaths.isNotEmpty)
        : false;
    final cleanSmartDeconstructionProviderId = smartDeconstructionProviderId
        .trim();
    final cleanSmartDeconstructionModelId = smartDeconstructionModelId.trim();
    final smartAnalysis =
        canSmartAnalyze &&
        requestedSmartAnalysis &&
        cleanSmartAnalysisProviderId.isNotEmpty &&
        cleanSmartAnalysisModelId.isNotEmpty;
    final smartDeconstruction =
        canSmartDeconstruction &&
        requestedSmartDeconstruction &&
        cleanSmartDeconstructionProviderId.isNotEmpty &&
        cleanSmartDeconstructionModelId.isNotEmpty;
    return ProjectImportActionPolicy(
      projectType: normalizedProjectType,
      resolvedTargetDirectory: resolvedTargetDirectory,
      sourcePaths: cleanSourcePaths,
      autoDeconstruct: autoDeconstruct,
      canAutoDeconstruct: canAutoDeconstruct,
      smartAnalysis: smartAnalysis,
      canSmartAnalyze: canSmartAnalyze,
      smartAnalysisProviderId: cleanSmartAnalysisProviderId,
      smartAnalysisModelId: cleanSmartAnalysisModelId,
      smartDeconstruction: smartDeconstruction,
      canSmartDeconstruction: canSmartDeconstruction,
      smartDeconstructionProviderId: cleanSmartDeconstructionProviderId,
      smartDeconstructionModelId: cleanSmartDeconstructionModelId,
      fileSelectionHint: _fileSelectionHint(cleanSourcePaths),
      outputHint: _outputHint(
        projectType: normalizedProjectType,
        cleanSourcePaths: cleanSourcePaths,
        canAutoDeconstruct: canAutoDeconstruct,
        autoDeconstruct: autoDeconstruct,
        canSmartAnalyze: canSmartAnalyze,
        smartAnalysis: smartAnalysis,
        smartAnalysisProviderId: cleanSmartAnalysisProviderId,
        smartAnalysisModelId: cleanSmartAnalysisModelId,
        canSmartDeconstruction: canSmartDeconstruction,
        smartDeconstruction: smartDeconstruction,
        smartDeconstructionProviderId: cleanSmartDeconstructionProviderId,
        smartDeconstructionModelId: cleanSmartDeconstructionModelId,
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
      return const ProjectContentPathPolicyService().directoryForContentType(
        'source_original',
      );
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
    return '已选择 ${sourcePaths.length} 个文件。自动拆书仅支持单个 .txt / .md / .markdown / .epub 文件。';
  }

  String _outputHint({
    required String projectType,
    required List<String> cleanSourcePaths,
    required bool canAutoDeconstruct,
    required bool autoDeconstruct,
    required bool canSmartAnalyze,
    required bool smartAnalysis,
    required String smartAnalysisProviderId,
    required String smartAnalysisModelId,
    required bool canSmartDeconstruction,
    required bool smartDeconstruction,
    required String smartDeconstructionProviderId,
    required String smartDeconstructionModelId,
  }) {
    if (cleanSourcePaths.isEmpty) {
      if (projectType == BookDeconstructionConstants.projectTypeId) {
        return '导入支持格式的文件后，可选启用智能拆书。';
      }
      return canSmartAnalyze
          ? '导入后可启用智能分析，判断资料更像正文、设定、大纲还是参考。'
          : '当前导入不支持智能分析。';
    }
    if (!canAutoDeconstruct) {
      if (canSmartAnalyze) {
        final analysisHint = _smartAnalysisHint(
          smartAnalysis: smartAnalysis,
          smartAnalysisProviderId: smartAnalysisProviderId,
          smartAnalysisModelId: smartAnalysisModelId,
        );
        return analysisHint.isEmpty
            ? '当前选择不支持自动拆书；如需智能分析，请先选择内置分析器使用的模型。'
            : analysisHint;
      }
      return '当前选择不支持自动拆书；请改为单个 .txt / .md / .markdown / .epub 文件。';
    }
    final previewPath = autoDeconstructionPreviewPath(
      projectType: projectType,
      sourcePath: cleanSourcePaths.single,
    );
    final smartAnalysisHint = _smartAnalysisHint(
      smartAnalysis: smartAnalysis,
      smartAnalysisProviderId: smartAnalysisProviderId,
      smartAnalysisModelId: smartAnalysisModelId,
    );
    if (projectType == BookDeconstructionConstants.projectTypeId) {
      final smartDeconstructionHint = _smartDeconstructionHint(
        canSmartDeconstruction: canSmartDeconstruction,
        smartDeconstruction: smartDeconstruction,
        smartDeconstructionProviderId: smartDeconstructionProviderId,
        smartDeconstructionModelId: smartDeconstructionModelId,
      );
      final base = '导入原文后，预演纪要会写入 $previewPath。';
      return smartDeconstructionHint.isEmpty
          ? base
          : '$base $smartDeconstructionHint';
    }
    final base = '预演纪要会写入 $previewPath，原始导入文件保留在目标目录。';
    return smartAnalysisHint.isEmpty ? base : '$base $smartAnalysisHint';
  }

  String _smartAnalysisHint({
    required bool smartAnalysis,
    required String smartAnalysisProviderId,
    required String smartAnalysisModelId,
  }) {
    final providerId = smartAnalysisProviderId.trim();
    final modelId = smartAnalysisModelId.trim();
    if (providerId.isEmpty || modelId.isEmpty) {
      return '如需智能分析，请先选择模型。';
    }
    if (!smartAnalysis) {
      return '已选择分析模型，可按需开启。';
    }
    return '智能分析已开启，将使用 $modelId 判断内容类型。';
  }

  String _smartDeconstructionHint({
    required bool canSmartDeconstruction,
    required bool smartDeconstruction,
    required String smartDeconstructionProviderId,
    required String smartDeconstructionModelId,
  }) {
    if (!canSmartDeconstruction) {
      return '';
    }
    if (smartDeconstructionProviderId.trim().isEmpty ||
        smartDeconstructionModelId.trim().isEmpty) {
      return '如需智能拆书，请先选择专用模型。';
    }
    if (!smartDeconstruction) {
      return '已选择拆书模型，可按需开启。';
    }
    return '智能拆分已开启，将使用 $smartDeconstructionModelId 处理章节划分。';
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
