import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'source_document_format_catalog_service.dart';
import 'source_import_path_scanner_service.dart';

class SourceImportDiscoveryService implements SourceImportDiscoveryPort {
  const SourceImportDiscoveryService({
    SourceImportPathScannerService? pathScannerService,
    SourceDocumentFormatCatalogService? formatCatalogService,
    SourceImportNormalizationService? normalizationService,
  }) : _pathScannerService =
           pathScannerService ?? const SourceImportPathScannerService(),
       _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _normalizationService =
           normalizationService ?? const SourceImportNormalizationService();

  final SourceImportPathScannerService _pathScannerService;
  final SourceDocumentFormatCatalogService _formatCatalogService;
  final SourceImportNormalizationService _normalizationService;

  @override
  Future<SourceImportDiscoveryResult> discover(
    SourceImportRequest request,
  ) async {
    // 中文注释: discovery 先归一化 selection，再展开目录与集合路径，最后只保留格式目录认可的文件。
    final normalizedRequest = _normalizationService.normalizeRequest(request);
    final discoveredSelections = <SourceImportSelection>[];
    final skippedPaths = <String>[];
    for (final selection in normalizedRequest.selections) {
      final expanded = await _expandSelection(selection);
      discoveredSelections.addAll(expanded.selections);
      skippedPaths.addAll(expanded.skippedPaths);
    }
    return SourceImportDiscoveryResult(
      selections: List<SourceImportSelection>.unmodifiable(
        discoveredSelections,
      ),
      skippedPaths: _dedupePaths(skippedPaths),
    );
  }

  Future<_DiscoveryExpansion> _expandSelection(
    SourceImportSelection selection,
  ) async {
    // 中文注释: 单选项既支持单文件，也支持目录与集合入口，具体展开后的文件都会统一投影成 single_file selection。
    final paths = await _scanSelectionPaths(selection);
    if (paths.isEmpty) {
      return _DiscoveryExpansion(
        selections: const <SourceImportSelection>[],
        skippedPaths: <String>[
          selection.sourceLocator.trim().isNotEmpty
              ? _normalizePath(selection.sourceLocator.trim())
              : selection.selectionId.trim(),
        ],
      );
    }
    final discoveredSelections = <SourceImportSelection>[];
    final skippedPaths = <String>[];
    for (var index = 0; index < paths.length; index += 1) {
      final filePath = paths[index];
      final descriptor = _formatCatalogService.resolveByPath(filePath);
      if (descriptor == null) {
        skippedPaths.add(filePath);
        continue;
      }
      final relativePathHint = _relativePathHint(selection, filePath);
      discoveredSelections.add(
        selection.copyWith(
          selectionId: _expandedSelectionId(selection, index + 1, filePath),
          selectionKind: SourceImportSelectionKinds.singleFile,
          sourceIdentity: selection.sourceIdentity.copyWith(
            sourceKind: 'file',
            displayName: _displayNameForPath(relativePathHint, filePath),
            resolverUri: filePath,
            localHintPath: relativePathHint,
          ),
          sourceLocator: filePath,
          mediaType: descriptor.mediaType,
          relativePathHint: relativePathHint,
          recursive: false,
          metadata: <String, Object?>{
            ...selection.metadata,
            'discovered_from_selection_id': selection.selectionId,
            'discovered_source_path': filePath,
            'discovered_media_type': descriptor.mediaType,
          },
        ),
      );
    }
    return _DiscoveryExpansion(
      selections: discoveredSelections,
      skippedPaths: skippedPaths,
    );
  }

  Future<List<String>> _scanSelectionPaths(
    SourceImportSelection selection,
  ) async {
    // 中文注释: 扫描阶段只关心实际文件路径，目录、集合与单文件都通过同一入口统一展开。
    final locator = selection.sourceLocator.trim();
    if (locator.isEmpty) {
      return const <String>[];
    }
    final entityType = await FileSystemEntity.type(locator, followLinks: false);
    if (entityType == FileSystemEntityType.file) {
      return <String>[_normalizePath(File(locator).absolute.path)];
    }
    if (entityType == FileSystemEntityType.directory) {
      return _pathScannerService.scan(
        sourcePath: locator,
        recursive: selection.recursive,
      );
    }
    if (selection.selectionKind == SourceImportSelectionKinds.collection) {
      return await _scanCollectionPaths(selection);
    }
    final collectionPaths = await _scanCollectionPaths(selection);
    if (collectionPaths.isNotEmpty) {
      return collectionPaths;
    }
    return const <String>[];
  }

  Future<List<String>> _scanCollectionPaths(
    SourceImportSelection selection,
  ) async {
    // 中文注释: collection 允许通过 metadata 提供路径列表，便于未来批量导入不被单一路径语义锁死。
    final metadataPaths = _metadataPaths(selection.metadata);
    if (metadataPaths.isEmpty) {
      return const <String>[];
    }
    final result = <String>[];
    for (final path in metadataPaths) {
      result.addAll(
        await _pathScannerService.scan(
          sourcePath: path,
          recursive: selection.recursive,
        ),
      );
    }
    result.sort();
    return result;
  }

  List<String> _metadataPaths(Map<String, Object?> metadata) {
    // 中文注释: collection 路径优先读常见路径字段，避免调用点为了批量导入重新发明私有字段名。
    const candidates = <String>['source_paths', 'paths', 'items'];
    for (final key in candidates) {
      final value = metadata[key];
      if (value is List) {
        return value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const <String>[];
  }

  String _relativePathHint(SourceImportSelection selection, String filePath) {
    // 中文注释: relativePathHint 以目录相对路径优先，single file 则退回文件名，保证导入目标可稳定重建层级。
    final relativeHint = SourceAssetIdentity.normalizeLocalHintPath(
      selection.relativePathHint,
    ).trim();
    final locator = selection.sourceLocator.replaceAll('\\', '/').trim();
    if (locator.isEmpty) {
      if (relativeHint.isNotEmpty) {
        return relativeHint;
      }
      return _fileName(filePath);
    }
    final locatorType = FileSystemEntity.typeSync(locator, followLinks: false);
    if (locatorType == FileSystemEntityType.directory) {
      final childRelativePath = _directoryRelativePath(locator, filePath);
      if (childRelativePath.isNotEmpty) {
        return childRelativePath;
      }
      if (relativeHint.isNotEmpty) {
        return relativeHint;
      }
    }
    if (relativeHint.isNotEmpty) {
      return relativeHint;
    }
    if (locatorType == FileSystemEntityType.directory) {
      final root = Directory(locator).absolute.path.replaceAll('\\', '/');
      final normalizedFile = File(filePath).absolute.path.replaceAll('\\', '/');
      if (normalizedFile.startsWith('$root/')) {
        return normalizedFile.substring(root.length + 1);
      }
    }
    return _fileName(filePath);
  }

  String _directoryRelativePath(String rootPath, String filePath) {
    // 中文注释: 目录相对路径只做根目录切片，避免 discovery 在目录扫描时丢失嵌套层级。
    final root = Directory(rootPath).absolute.path.replaceAll('\\', '/');
    final normalizedFile = File(filePath).absolute.path.replaceAll('\\', '/');
    if (normalizedFile.startsWith('$root/')) {
      return normalizedFile.substring(root.length + 1);
    }
    return '';
  }

  String _expandedSelectionId(
    SourceImportSelection selection,
    int index,
    String filePath,
  ) {
    // 中文注释: 展开后的 selectionId 需要稳定且可追踪，避免目录扫描后各文件撞号。
    final base = selection.selectionId.trim().isEmpty
        ? selection.sourceIdentity.sourceAssetId.trim()
        : selection.selectionId.trim();
    final suffix = _fileName(
      filePath,
    ).replaceAll(RegExp(r'[^A-Za-z0-9\u4E00-\u9FFF._-]+'), '_');
    return '$base.$index.$suffix';
  }

  String _displayNameForPath(String relativePathHint, String filePath) {
    // 中文注释: 显示名优先用相对路径，方便目录扫描后的结果保持树形可读性。
    final candidate = relativePathHint.trim();
    if (candidate.isNotEmpty) {
      return candidate;
    }
    return _fileName(filePath);
  }

  String _fileName(String filePath) {
    // 中文注释: 文件名提取只做最轻量的路径尾段处理，避免把 discovery 变成复杂路径规范器。
    final normalized = filePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  List<String> _dedupePaths(List<String> paths) {
    // 中文注释: skippedPaths 去重后再输出，避免目录扫描时同一路径因多层展开重复出现。
    final result = <String>[];
    for (final path in paths) {
      final clean = path.trim();
      if (clean.isEmpty || result.contains(clean)) {
        continue;
      }
      result.add(_normalizePath(clean));
    }
    return List<String>.unmodifiable(result);
  }

  String _normalizePath(String value) {
    // 中文注释: discovery 输出统一使用斜杠，避免 Windows 上混合分隔符污染导入和测试断言。
    return value.replaceAll('\\', '/');
  }
}

class _DiscoveryExpansion {
  const _DiscoveryExpansion({
    required this.selections,
    required this.skippedPaths,
  });

  final List<SourceImportSelection> selections;
  final List<String> skippedPaths;
}
