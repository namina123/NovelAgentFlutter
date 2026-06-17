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
    String analysisAgentId = '',
    String analysisAgentGroupId = '',
  }) {
    final normalizedProjectType = projectType.trim();
    final cleanSourcePaths = sourcePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    final canAutoDeconstruct = _supportsAutoDeconstruction(cleanSourcePaths);
    final canSmartAnalyze =
        normalizedProjectType != BookDeconstructionConstants.projectTypeId;
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
    final smartAnalysis = canSmartAnalyze ? requestedSmartAnalysis : false;
    return ProjectImportActionPolicy(
      projectType: normalizedProjectType,
      resolvedTargetDirectory: resolvedTargetDirectory,
      sourcePaths: cleanSourcePaths,
      autoDeconstruct: autoDeconstruct,
      canAutoDeconstruct: canAutoDeconstruct,
      smartAnalysis: smartAnalysis,
      canSmartAnalyze: canSmartAnalyze,
      analysisAgentId: analysisAgentId.trim(),
      analysisAgentGroupId: analysisAgentGroupId.trim(),
      fileSelectionHint: _fileSelectionHint(cleanSourcePaths),
      outputHint: _outputHint(
        projectType: normalizedProjectType,
        cleanSourcePaths: cleanSourcePaths,
        canAutoDeconstruct: canAutoDeconstruct,
        autoDeconstruct: autoDeconstruct,
        canSmartAnalyze: canSmartAnalyze,
        smartAnalysis: smartAnalysis,
        analysisAgentId: analysisAgentId,
        analysisAgentGroupId: analysisAgentGroupId,
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
    required String analysisAgentId,
    required String analysisAgentGroupId,
  }) {
    if (cleanSourcePaths.isEmpty) {
      if (projectType == BookDeconstructionConstants.projectTypeId) {
        return '拆书项目默认允许自动拆书；选择单个 .txt / .md / .markdown / .epub 文件后会自动启用。';
      }
      return canSmartAnalyze
          ? '导入后可启用智能分析，先判断资料更像正文、设定、大纲还是参考；请选择一个或多个本地 .txt / .md / .markdown / .epub 文件。'
          : '当前导入不支持智能分析。';
    }
    if (!canAutoDeconstruct) {
      if (canSmartAnalyze) {
        final analysisHint = _smartAnalysisHint(
          smartAnalysis: smartAnalysis,
          analysisAgentId: analysisAgentId,
          analysisAgentGroupId: analysisAgentGroupId,
        );
        return analysisHint.isEmpty
            ? '当前选择不支持自动拆书；如需智能分析，请继续确认分析智能体或智能体组。'
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
      analysisAgentId: analysisAgentId,
      analysisAgentGroupId: analysisAgentGroupId,
    );
    if (projectType == BookDeconstructionConstants.projectTypeId) {
      return '导入原文会归档到 sources/original/，自动拆书预演纪要会写入 $previewPath。';
    }
    final base = '自动拆书预演纪要会写入 $previewPath，原始导入文件仍保留在所选目标目录。';
    return smartAnalysisHint.isEmpty ? base : '$base $smartAnalysisHint';
  }

  String _smartAnalysisHint({
    required bool smartAnalysis,
    required String analysisAgentId,
    required String analysisAgentGroupId,
  }) {
    if (!smartAnalysis) {
      return '';
    }
    final agentId = analysisAgentId.trim();
    final agentGroupId = analysisAgentGroupId.trim();
    if (agentId.isEmpty && agentGroupId.isEmpty) {
      return '智能分析默认开启，会先大致判断导入内容类型。';
    }
    final selected = <String>[];
    if (agentId.isNotEmpty) {
      selected.add('智能体 $agentId');
    }
    if (agentGroupId.isNotEmpty) {
      selected.add('智能体组 $agentGroupId');
    }
    return '智能分析默认开启，将由${selected.join(' / ')} 先判断导入内容类型。';
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
