import '../common/json_types.dart';
import '../common/source_asset_identity.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_entry_path_service.dart';
import '../imports/source_import_discovery_port.dart';
import '../imports/source_import_normalization_service.dart';
import '../imports/source_import_request.dart';
import '../imports/source_import_selection.dart';
import '../imports/source_import_selection_kind.dart';

class ImportProjectFilesUseCase {
  ImportProjectFilesUseCase({
    required ProjectToolHostPort projectToolHostPort,
    ProjectEntryPathService? pathService,
    SourceImportNormalizationService? sourceImportNormalizationService,
    SourceImportDiscoveryPort? sourceImportDiscoveryPort,
  }) : _projectToolHostPort = projectToolHostPort,
       _pathService = pathService ?? const ProjectEntryPathService(),
       _sourceImportNormalizationService =
           sourceImportNormalizationService ??
           const SourceImportNormalizationService(),
       _sourceImportDiscoveryPort = sourceImportDiscoveryPort;

  final ProjectToolHostPort _projectToolHostPort;
  final ProjectEntryPathService _pathService;
  final SourceImportNormalizationService _sourceImportNormalizationService;
  final SourceImportDiscoveryPort? _sourceImportDiscoveryPort;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    SourceImportRequest? sourceImportRequest,
    String targetDirectory = '',
  }) async {
    // 中文注释: 外部文件导入收口在这里，统一处理目标目录、重名去重和结果摘要。
    final cleanTargetDirectory = _pathService.cleanRelativePath(
      targetDirectory,
    );
    if (cleanTargetDirectory.isNotEmpty &&
        !_pathService.isSafeScopePath(cleanTargetDirectory)) {
      return _error(
        '目标目录不安全。',
        data: <String, Object?>{'target_directory': cleanTargetDirectory},
      );
    }
    final discoveryRequest =
        sourceImportRequest ?? _buildLegacyDiscoveryRequest(sourcePaths);
    final discoveryResult = _sourceImportDiscoveryPort == null
        ? null
        : await _sourceImportDiscoveryPort.discover(discoveryRequest);
    final normalizedSources = discoveryResult == null
        ? (sourceImportRequest == null
              ? _normalizeLegacySourcePaths(sourcePaths)
              : _normalizeRequestSelections(sourceImportRequest))
        : discoveryResult.selections;
    final importedPaths = <String>[];
    final skippedPaths = <String>[
      ...discoveryResult?.skippedPaths ?? const <String>[],
    ];
    for (final normalizedSource in normalizedSources) {
      final cleanSourcePath = normalizedSource.sourceLocator.trim();
      if (cleanSourcePath.isEmpty) {
        continue;
      }
      if (normalizedSource.selectionKind ==
          SourceImportSelectionKinds.directory) {
        skippedPaths.add(cleanSourcePath);
        continue;
      }
      final sourcePathHint = _normalizedRelativePath(
        normalizedSource.relativePathHint,
        fallbackFileName: _sourceFileName(cleanSourcePath),
      );
      if (sourcePathHint.isEmpty) {
        skippedPaths.add(cleanSourcePath);
        continue;
      }
      final targetRelativePath = cleanTargetDirectory.isEmpty
          ? sourcePathHint
          : '$cleanTargetDirectory/$sourcePathHint';
      final uniqueTargetPath = await _pathService.uniqueRelativePath(
        hostPort: _projectToolHostPort,
        rootPath: project.rootPath,
        relativePath: targetRelativePath,
      );
      await _projectToolHostPort.copyExternalFile(
        cleanSourcePath,
        project.rootPath,
        uniqueTargetPath,
      );
      importedPaths.add(uniqueTargetPath);
    }
    return <String, Object?>{
      'ok': importedPaths.isNotEmpty,
      'summary': importedPaths.isEmpty
          ? '没有可导入的文件。'
          : '已导入 ${importedPaths.length} 个文件。',
      'imported_paths': importedPaths,
      'skipped_paths': skippedPaths,
    };
  }

  List<SourceImportSelection> _normalizeLegacySourcePaths(
    List<String> sourcePaths,
  ) {
    // 中文注释: 旧的 sourcePaths 调用先映射成最小 source import selection，保证兼容路径继续走同一合同出口。
    return _sourceImportNormalizationService.normalizeSelections(
      SourceImportRequest(
        requestId: 'legacy_source_paths',
        selections: sourcePaths
            .asMap()
            .entries
            .map(
              (entry) => SourceImportSelection(
                selectionId: 'legacy_${entry.key + 1}',
                selectionKind: SourceImportSelectionKinds.singleFile,
                sourceIdentity: SourceAssetIdentity(
                  sourceAssetId: 'legacy_${entry.key + 1}',
                  sourceKind: 'file',
                  displayName: _sourceFileName(entry.value),
                  localHintPath: entry.value,
                ),
                sourceLocator: entry.value,
                sortOrder: entry.key + 1,
                mediaType: '',
                relativePathHint: '',
                recursive: false,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  List<SourceImportSelection> _normalizeRequestSelections(
    SourceImportRequest request,
  ) {
    // 中文注释: 新的 source import request 直接走统一规范化，保证 general import 与拆书输入看到同一排序和身份规则。
    return _sourceImportNormalizationService
        .normalizeRequest(request)
        .selections;
  }

  SourceImportRequest _buildLegacyDiscoveryRequest(List<String> sourcePaths) {
    // 中文注释: 旧的 sourcePaths 入口先映射成统一 discovery request，方便目录扫描和格式过滤复用同一条主链。
    return SourceImportRequest(
      requestId: 'legacy_source_paths_discovery',
      selections: sourcePaths
          .asMap()
          .entries
          .map(
            (entry) => SourceImportSelection(
              selectionId: 'legacy_discovery_${entry.key + 1}',
              selectionKind: SourceImportSelectionKinds.singleFile,
              sourceIdentity: SourceAssetIdentity(
                sourceAssetId: 'legacy_discovery_${entry.key + 1}',
                sourceKind: 'file',
                displayName: _sourceFileName(entry.value),
                localHintPath: entry.value,
              ),
              sourceLocator: entry.value,
              sortOrder: entry.key + 1,
              mediaType: '',
              relativePathHint: '',
              recursive: true,
            ),
          )
          .toList(growable: false),
    );
  }

  String _normalizedRelativePath(
    String value, {
    required String fallbackFileName,
  }) {
    // 中文注释: 相对路径统一清洗后再拼接目标目录，避免 discovery 结果里混入绝对路径或平台分隔符。
    final clean = value.replaceAll('\\', '/').trim();
    if (clean.isNotEmpty) {
      final normalized = clean.replaceAll(RegExp(r'/+'), '/');
      if (SourceAssetIdentity.isAbsolutePath(normalized)) {
        return fallbackFileName;
      }
      return normalized;
    }
    return fallbackFileName;
  }

  String _sourceFileName(String sourcePath) {
    // 中文注释: 外部源文件名提取单独收口，避免路径分隔符判断散落在导入循环里。
    final normalized = sourcePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized.split('/');
    return _pathService.safeFileName(
      segments.isEmpty ? normalized : segments.last,
      fallback: 'imported_file',
    );
  }

  JsonMap _error(String error, {JsonMap data = const <String, Object?>{}}) {
    return <String, Object?>{'ok': false, 'error': error, ...data};
  }
}
