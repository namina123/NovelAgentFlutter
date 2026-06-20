import 'dart:isolate';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_open_snapshot.dart';

class ProjectOpenScanRuntime {
  const ProjectOpenScanRuntime();

  Future<ProjectOpenSnapshot> scan({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    String selectedEntryId = '',
    String status = '',
  }) async {
    // 中文注释: 作品库发现的目录遍历和 manifest 读取统一转到后台 isolate，避免主交互热路径被默认目录扫描拖慢。
    final payload = await Isolate.run(
      () => _scanProjectOpenSnapshotSync(
        projectsRootPath: projectsRootPath,
        recentProjectPath: recentProjectPath,
        currentProjectPath: currentProjectPath,
        allowImportLocal: allowImportLocal,
        selectedEntryId: selectedEntryId,
        status: status,
      ),
    );
    return ProjectOpenSnapshot.fromJson(payload);
  }
}

JsonMap _scanProjectOpenSnapshotSync({
  required String projectsRootPath,
  required String recentProjectPath,
  required String currentProjectPath,
  required bool allowImportLocal,
  required String selectedEntryId,
  required String status,
}) {
  // 中文注释: 同步扫描只在 isolate 内执行，负责把默认目录、当前项目和最近项目合成一个可消费快照。
  final records = <String, JsonMap>{};
  final normalizedProjectsRootPath = projectsRootPath.trim();
  if (normalizedProjectsRootPath.isNotEmpty) {
    final rootDirectory = Directory(normalizedProjectsRootPath);
    if (rootDirectory.existsSync()) {
      for (final entity in rootDirectory.listSync(followLinks: false)) {
        if (entity is! Directory) {
          continue;
        }
        _tryCollectProjectSync(
          entity.path,
          records,
          sourceLabel: '默认目录',
          currentProjectPath: currentProjectPath,
        );
      }
    }
  }
  if (currentProjectPath.trim().isNotEmpty) {
    _tryCollectProjectSync(
      currentProjectPath,
      records,
      sourceLabel: '',
      currentProjectPath: currentProjectPath,
    );
  }
  if (recentProjectPath.trim().isNotEmpty) {
    _tryCollectProjectSync(
      recentProjectPath,
      records,
      sourceLabel: '最近项目',
      currentProjectPath: currentProjectPath,
    );
  }

  final entries = records.values.toList(growable: false)
    ..sort(_compareRecords);
  final resolvedSelectedEntryId = _resolveSelectedEntryId(
    requestedId: selectedEntryId,
    records: entries,
  );
  return <String, Object?>{
    'projects_root_path': normalizedProjectsRootPath,
    'recent_project_path': recentProjectPath.trim(),
    'current_project_path': currentProjectPath.trim(),
    'allow_import_local': allowImportLocal,
    'records': entries,
    'selected_entry_id': resolvedSelectedEntryId,
    'status': status.trim().isNotEmpty
        ? status.trim()
        : entries.isEmpty
        ? '还没有可继续的作品。'
        : '',
  };
}

void _tryCollectProjectSync(
  String rootPath,
  Map<String, JsonMap> output, {
  required String sourceLabel,
  required String currentProjectPath,
}) {
  // 中文注释: 单个项目目录发现只做 manifest 解析和修改时间读取，不再回到主 isolate。
  final cleanRootPath = rootPath.trim();
  if (cleanRootPath.isEmpty) {
    return;
  }
  final manifest = _tryReadManifestSync(cleanRootPath);
  if (manifest == null) {
    return;
  }
  final key = _pathKey(cleanRootPath);
  final modifiedAt = _readModifiedAtSync(cleanRootPath);
  final existing = output[key];
  final nextBadges = <String>{
    if (existing != null) ...ValueReaders.stringList(existing['source_badges']),
    if (sourceLabel.trim().isNotEmpty) sourceLabel,
  }.toList(growable: false);
  output[key] = <String, Object?>{
    'id': key,
    'title': ValueReaders.stringValue(
      manifest['title'],
      _fallbackTitleFromPath(cleanRootPath),
    ),
    'path': cleanRootPath,
    'project_type_id': ValueReaders.stringValue(manifest['project_type']),
    'storage_strategy_id': ValueReaders.stringValue(
      manifest['storage_strategy'],
    ),
    'runtime_baseline_id': ValueReaders.stringValue(
      manifest['runtime_baseline_id'],
    ),
    'modified_at_ms': modifiedAt.millisecondsSinceEpoch,
    'source_badges': nextBadges,
    'is_current_project':
        _pathKey(currentProjectPath) == _pathKey(cleanRootPath),
  };
}

JsonMap? _tryReadManifestSync(String rootPath) {
  // 中文注释: manifest 读取走同步文件访问，保持整条扫描链在 isolate 内完成。
  final manifestPath =
      '$rootPath${Platform.pathSeparator}'
      '${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    return null;
  }
  try {
    final codec = ProjectManifestCodecService();
    final manifest = codec.parse(
      manifestFile.readAsStringSync(),
      fallbackTitle: _fallbackTitleFromPath(rootPath),
    );
    return codec.toJson(manifest);
  } catch (_) {
    return null;
  }
}

String _fallbackTitleFromPath(String rootPath) {
  // 中文注释: 没有 manifest 标题时，回退到目录名，确保作品卡片仍然能读得懂。
  final segments = Directory(rootPath).uri.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) {
    return '未命名项目';
  }
  return segments.last;
}

int _compareRecords(
  JsonMap left,
  JsonMap right,
) {
  // 中文注释: 作品排序先保留当前项目，再保留最近项目，再按修改时间和标题稳定排序。
  final leftCurrent = ValueReaders.boolValue(left['is_current_project']);
  final rightCurrent = ValueReaders.boolValue(right['is_current_project']);
  if (leftCurrent != rightCurrent) {
    return leftCurrent ? -1 : 1;
  }
  final leftRecent = ValueReaders.stringList(left['source_badges']).contains(
    '最近项目',
  );
  final rightRecent = ValueReaders.stringList(right['source_badges']).contains(
    '最近项目',
  );
  if (leftRecent != rightRecent) {
    return leftRecent ? -1 : 1;
  }
  final leftModifiedAt = DateTime.fromMillisecondsSinceEpoch(
    ValueReaders.intValue(left['modified_at_ms']),
  );
  final rightModifiedAt = DateTime.fromMillisecondsSinceEpoch(
    ValueReaders.intValue(right['modified_at_ms']),
  );
  final modifiedOrder = rightModifiedAt.compareTo(leftModifiedAt);
  if (modifiedOrder != 0) {
    return modifiedOrder;
  }
  return ValueReaders.stringValue(left['title']).compareTo(
    ValueReaders.stringValue(right['title']),
  );
}

String _resolveSelectedEntryId({
  required String requestedId,
  required List<JsonMap> records,
}) {
  // 中文注释: 默认选中态尽量沿用当前项目，其次沿用最近项目，再退回第一条结果。
  final cleanRequestedId = requestedId.trim();
  if (cleanRequestedId.isNotEmpty) {
    for (final record in records) {
      if (ValueReaders.stringValue(record['id']) == cleanRequestedId) {
        return cleanRequestedId;
      }
    }
  }
  for (final record in records) {
    if (ValueReaders.boolValue(record['is_current_project'])) {
      return ValueReaders.stringValue(record['id']);
    }
  }
  for (final record in records) {
    if (ValueReaders.stringList(record['source_badges']).contains(
      '最近项目',
    )) {
      return ValueReaders.stringValue(record['id']);
    }
  }
  return records.isEmpty ? '' : ValueReaders.stringValue(records.first['id']);
}

DateTime _readModifiedAtSync(String rootPath) {
  // 中文注释: 修改时间直接从文件系统 stat 读取，避免再把这一步拆回异步主链。
  try {
    return Directory(rootPath).statSync().modified;
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

String _pathKey(String path) {
  // 中文注释: 路径 key 保持平台无关比较，保证同一项目在不同环境下命中同一条作品记录。
  final normalized = path
      .trim()
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  if (Platform.isWindows) {
    return normalized.toLowerCase();
  }
  return normalized;
}
