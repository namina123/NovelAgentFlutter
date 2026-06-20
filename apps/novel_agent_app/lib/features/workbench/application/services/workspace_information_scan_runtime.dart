import 'dart:isolate';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/workspace_information_scan_result.dart';

class WorkspaceInformationScanRuntime {
  const WorkspaceInformationScanRuntime({
    this.maxScanAttempts = 3,
  });

  final int maxScanAttempts;

  Future<WorkspaceInformationScanResult> scan({
    required String projectRootPath,
    required List<JsonMap> workspaceEntries,
  }) async {
    // 中文注释: 这里把隐藏资料树扫描放到背景 isolate，避免工作台切页后在主 isolate 上反复扫盘。
    final payload = await Isolate.run(
      () => _scanWorkspaceInformationSync(
        projectRootPath: projectRootPath,
        workspaceEntries: workspaceEntries,
        maxScanAttempts: maxScanAttempts,
      ),
    );
    return WorkspaceInformationScanResult.fromJson(payload);
  }
}

JsonMap _scanWorkspaceInformationSync({
  required String projectRootPath,
  required List<JsonMap> workspaceEntries,
  required int maxScanAttempts,
}) {
  // 中文注释: 同步扫描函数只在背景 isolate 内执行，负责把可见树和隐藏资料投影树合并成一次性快照。
  final cleanProjectRootPath = projectRootPath.trim();
  if (cleanProjectRootPath.isEmpty) {
    return <String, Object?>{
      'project_root_path': cleanProjectRootPath,
      'workspace_entries': const <JsonMap>[],
      'file_contents': const <String, Object?>{},
      'source_paths': const <String>[],
    };
  }
  final entryByPath = <String, JsonMap>{};
  for (final entry in workspaceEntries) {
    final relativePath = _normalizeRelativePath(
      _stringValue(entry['relative_path']),
    );
    if (relativePath.isEmpty) {
      continue;
    }
    entryByPath[relativePath] = ValueReaders.deepCopyMap(entry);
  }

  for (final entry in _scanInformationSupportEntriesSync(
    cleanProjectRootPath,
    maxScanAttempts: maxScanAttempts,
  )) {
    final relativePath = _normalizeRelativePath(
      _stringValue(entry['relative_path']),
    );
    if (relativePath.isEmpty) {
      continue;
    }
    entryByPath[relativePath] = entry;
  }

  final fileContents = <String, String>{};
  final orderedPaths = entryByPath.keys.toList(growable: true)..sort();
  for (final path in orderedPaths) {
    if (!_shouldReadInformationProjectionFile(path)) {
      continue;
    }
    final content = File(
      _resolveProjectFilePath(cleanProjectRootPath, path),
    ).readAsStringSync();
    if (content.trim().isEmpty) {
      continue;
    }
    fileContents[path] = content;
  }

  return <String, Object?>{
    'project_root_path': cleanProjectRootPath,
    'workspace_entries': entryByPath.values.toList(growable: false),
    'file_contents': fileContents,
    'source_paths': fileContents.keys.toList(growable: false),
  };
}

List<JsonMap> _scanInformationSupportEntriesSync(
  String projectRootPath, {
  required int maxScanAttempts,
}) {
  // 中文注释: 隐藏支持文件只扫描一次入口，再把候选文件补进快照，避免控制器自己维护多段目录遍历。
  final entries = <JsonMap>[];
  final seenPaths = <String>{};

  void addFileIfExists(String relativePath) {
    final normalizedPath = _normalizeRelativePath(relativePath);
    if (normalizedPath.isEmpty || seenPaths.contains(normalizedPath)) {
      return;
    }
    final resolved = _resolveProjectFilePath(projectRootPath, normalizedPath);
    if (!File(resolved).existsSync()) {
      return;
    }
    seenPaths.add(normalizedPath);
    entries.add(<String, Object?>{
      'relative_path': normalizedPath,
      'display_name': normalizedPath.split('/').last,
      'is_dir': false,
    });
  }

  for (final projectionPath in _informationProjectionPaths) {
    addFileIfExists(projectionPath);
  }

  for (final relativePath in _scanRelativeFilesUnderSync(
    projectRootPath,
    '.novel_agent/information',
    maxScanAttempts: maxScanAttempts,
  )) {
    if (_isPendingInformationPath(relativePath)) {
      addFileIfExists(relativePath);
    }
  }

  for (final relativePath in _scanRelativeFilesUnderSync(
    projectRootPath,
    'tracking',
    maxScanAttempts: maxScanAttempts,
  )) {
    if (relativePath.endsWith('activation_report.json')) {
      addFileIfExists(relativePath);
    }
  }

  for (final relativePath in _scanRelativeFilesUnderSync(
    projectRootPath,
    '.novel_agent',
    maxScanAttempts: maxScanAttempts,
  )) {
    if (relativePath.endsWith('activation_report.json')) {
      addFileIfExists(relativePath);
    }
  }

  return entries;
}

Iterable<String> _scanRelativeFilesUnderSync(
  String projectRootPath,
  String relativeRoot, {
  required int maxScanAttempts,
}) sync* {
  // 中文注释: 这里保留有限重试，避免临时文件系统抖动让隐藏资料树扫描直接失败。
  final normalizedRoot = _normalizeRelativePath(relativeRoot);
  final directory = Directory(
    _resolveProjectFilePath(projectRootPath, normalizedRoot),
  );
  if (!directory.existsSync()) {
    return;
  }
  FileSystemException? lastError;
  for (var attempt = 1; attempt <= maxScanAttempts; attempt++) {
    final pendingDirectories = <Directory>[directory];
    try {
      while (pendingDirectories.isNotEmpty) {
        final currentDirectory = pendingDirectories.removeLast();
        for (final entity in currentDirectory.listSync(
          recursive: false,
          followLinks: false,
        )) {
          final relativePath = _relativePathFromAbsolute(
            projectRootPath,
            entity.path,
          );
          if (relativePath.isEmpty ||
              _shouldSkipInformationSupportScanPath(
                scanRoot: normalizedRoot,
                relativePath: relativePath,
              )) {
            continue;
          }
          if (entity is File) {
            yield relativePath;
            continue;
          }
          if (entity is Directory) {
            pendingDirectories.add(entity);
          }
        }
      }
      return;
    } on FileSystemException catch (error) {
      lastError = error;
      if (attempt >= maxScanAttempts) {
        rethrow;
      }
      sleep(Duration(milliseconds: 80 * attempt));
    }
  }
  throw lastError ??
      FileSystemException('扫描资料支持文件失败。', directory.path);
}

bool _shouldReadInformationProjectionFile(String relativePath) {
  // 中文注释: 只有资料投影文档和激活报告才需要读内容，其余只是树形补位，不值得重复读盘。
  return _informationProjectionPaths.contains(relativePath) ||
      _isPendingInformationPath(relativePath) ||
      _isStructuredInformationRecordPath(relativePath) ||
      relativePath.endsWith('activation_report.json');
}

bool _shouldSkipInformationSupportScanPath({
  required String scanRoot,
  required String relativePath,
}) {
  // 中文注释: 信息支持目录只排除明知不该进资料视图的内部根，避免误把大体积派生目录扫进来。
  if (!scanRoot.startsWith('.novel_agent')) {
    return false;
  }
  return _informationSupportIgnoredRoots.any(
    (ignoredRoot) =>
        relativePath == ignoredRoot || relativePath.startsWith('$ignoredRoot/'),
  );
}

bool _isPendingInformationPath(String relativePath) {
  // 中文注释: 待审核或待确认的资料项只要命中这些前缀，就应该出现在工作台的信息投影里。
  return relativePath.startsWith(
        '.novel_agent/information/knowledge_cards/',
      ) ||
      relativePath.startsWith('.novel_agent/information/design_elements/') ||
      relativePath.startsWith('.novel_agent/information/research_requests/') ||
      relativePath.startsWith('.novel_agent/information/reference_works/');
}

bool _isStructuredInformationRecordPath(String relativePath) {
  return (relativePath.startsWith('.novel_agent/information/knowledge_cards/') ||
          relativePath.startsWith('.novel_agent/information/design_elements/') ||
          relativePath.startsWith('.novel_agent/information/research_notes/') ||
          relativePath.startsWith('.novel_agent/information/research_requests/') ||
          relativePath.startsWith('.novel_agent/information/reference_works/')) &&
      relativePath.endsWith('.json');
}

String _resolveProjectFilePath(String projectRootPath, String relativePath) {
  // 中文注释: 绝对路径拼接统一在这里处理，避免平台分隔符差异污染扫描逻辑。
  final normalizedRoot =
      projectRootPath.replaceAll('\\', Platform.pathSeparator);
  final normalizedRelative = relativePath.replaceAll(
    '/',
    Platform.pathSeparator,
  );
  return '$normalizedRoot${Platform.pathSeparator}$normalizedRelative';
}

String _relativePathFromAbsolute(
  String projectRootPath,
  String absolutePath,
) {
  // 中文注释: 背景扫描只接受相对路径输出，便于后续投影层复用统一的路径合同。
  final normalizedRoot = _normalizeRelativePath(projectRootPath);
  final normalizedAbsolute = _normalizeRelativePath(absolutePath);
  if (normalizedRoot.isEmpty || normalizedAbsolute.isEmpty) {
    return '';
  }
  if (normalizedAbsolute == normalizedRoot) {
    return '';
  }
  final prefix = '$normalizedRoot/';
  if (!normalizedAbsolute.startsWith(prefix)) {
    return '';
  }
  return normalizedAbsolute.substring(prefix.length);
}

String _normalizeRelativePath(String value) {
  // 中文注释: 归一化路径用于缓存、比较和投影，确保 Windows 与其他平台看到同一套相对路径。
  return ProjectSupportDocumentCatalog.canonicalizePath(value);
}

String _stringValue(Object? value, [String fallback = '']) {
  // 中文注释: 扫描结果里只要读取字符串字段，遇到空值就退回默认值，避免单个坏字段打断整次刷新。
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

const Set<String> _informationProjectionPaths = <String>{
  InformationProjectionDocument.knowledgeSummaryRelativePath,
  InformationProjectionDocument.designSummaryRelativePath,
  InformationProjectionDocument.researchSummaryRelativePath,
  InformationProjectionDocument.referenceBoundaryRelativePath,
};

const Set<String> _informationSupportIgnoredRoots = <String>{
  '.novel_agent/reference_extraction',
};
