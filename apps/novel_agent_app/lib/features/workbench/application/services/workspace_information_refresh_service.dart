import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/workbench_information_view_data.dart';
import 'workspace_information_projection_service.dart';
import 'workspace_information_scan_runtime.dart';

class WorkspaceInformationRefreshService {
  WorkspaceInformationRefreshService({
    WorkspaceInformationScanRuntime? scanRuntime,
    WorkspaceInformationProjectionService? projectionService,
  }) : _scanRuntime = scanRuntime ?? const WorkspaceInformationScanRuntime(),
       _projectionService =
           projectionService ?? const WorkspaceInformationProjectionService();

  final WorkspaceInformationScanRuntime _scanRuntime;
  final WorkspaceInformationProjectionService _projectionService;
  final Map<String, _WorkspaceInformationCacheEntry> _cacheByProjectRootPath =
      <String, _WorkspaceInformationCacheEntry>{};

  Future<WorkbenchInformationViewData> build({
    required ProjectDescriptor project,
    required List<JsonMap> workspaceEntries,
    bool forceRefresh = false,
  }) async {
    // 中文注释: 资料视图刷新先尝试命中缓存，只有树结构或隐藏支持文件真的变化时才重新后台扫描。
    final projectRootPath = _normalizePath(project.rootPath);
    if (projectRootPath.isEmpty) {
      return const WorkbenchInformationViewData();
    }
    final workspaceSignature = _workspaceSignature(workspaceEntries);
    final cachedEntry = _cacheByProjectRootPath[projectRootPath];
    if (!forceRefresh &&
        cachedEntry != null &&
        cachedEntry.workspaceSignature == workspaceSignature &&
        await _isCacheValid(cachedEntry)) {
      return cachedEntry.viewData;
    }

    final scanResult = await _scanRuntime.scan(
      projectRootPath: projectRootPath,
      workspaceEntries: workspaceEntries,
    );
    final viewData = _projectionService.build(
      workspaceEntries: scanResult.workspaceEntries,
      fileContents: scanResult.fileContents,
    );
    _cacheByProjectRootPath[projectRootPath] = _WorkspaceInformationCacheEntry(
      projectRootPath: projectRootPath,
      workspaceSignature: workspaceSignature,
      sourceStats: await _captureSourceStats(
        projectRootPath: projectRootPath,
        sourcePaths: scanResult.sourcePaths,
      ),
      viewData: viewData,
    );
    return viewData;
  }

  void invalidateProject(String rootPath) {
    // 中文注释: 外部动作如果已经明确写过隐藏资料树，就主动清掉这份缓存，避免旧投影继续回填。
    final projectRootPath = _normalizePath(rootPath);
    if (projectRootPath.isEmpty) {
      return;
    }
    _cacheByProjectRootPath.remove(projectRootPath);
  }

  void clear() {
    // 中文注释: 全量清缓存只在项目切换或测试场景里使用，避免旧项目的投影残留到新项目上。
    _cacheByProjectRootPath.clear();
  }

  Future<bool> _isCacheValid(_WorkspaceInformationCacheEntry entry) async {
    // 中文注释: 命中缓存前先校验已知源文件还在不在、有没有被改过，确保复用不会拿到明显过期的资料摘要。
    if (entry.sourceStats.isEmpty) {
      return true;
    }
    for (final sourceStat in entry.sourceStats) {
      final currentStat = await _readSourceStat(
        entry.projectRootPath,
        sourceStat.relativePath,
      );
      if (currentStat == null || currentStat != sourceStat) {
        return false;
      }
    }
    return true;
  }

  Future<List<_TrackedSourceStat>> _captureSourceStats({
    required String projectRootPath,
    required List<String> sourcePaths,
  }) async {
    // 中文注释: 只追踪真正参与资料投影的源文件状态，避免把整棵树的无关改动也拉进缓存判定。
    final stats = <_TrackedSourceStat>[];
    for (final sourcePath in sourcePaths) {
      final stat = await _readSourceStat(projectRootPath, sourcePath);
      if (stat != null) {
        stats.add(stat);
      }
    }
    return stats;
  }

  Future<_TrackedSourceStat?> _readSourceStat(
    String projectRootPath,
    String relativePath,
  ) async {
    // 中文注释: 这里用文件 stat 做轻量校验，避免每次都重新读完整文件内容。
    final resolvedPath = _resolveProjectFilePath(projectRootPath, relativePath);
    final file = File(resolvedPath);
    if (!await file.exists()) {
      return null;
    }
    final stat = await file.stat();
    return _TrackedSourceStat(
      relativePath: _normalizePath(relativePath),
      modifiedAt: stat.modified,
      size: stat.size,
    );
  }

  String _workspaceSignature(List<JsonMap> workspaceEntries) {
    // 中文注释: 工作台可见树的签名只记录路径和目录属性，便于快速判断这棵树是否已经换过。
    final normalized = workspaceEntries
        .map(
          (entry) =>
              '${_normalizePath(ValueReaders.stringValue(entry['relative_path']))}|${ValueReaders.boolValue(entry['is_dir']) ? '1' : '0'}',
        )
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: true)
      ..sort();
    return normalized.join('\n');
  }

  String _normalizePath(String value) {
    // 中文注释: 路径比较统一走同一种归一化，避免 Windows 斜杠差异把缓存判定搞乱。
    return value.trim().replaceAll('\\', '/');
  }

  String _resolveProjectFilePath(String rootPath, String relativePath) {
    // 中文注释: 文件定位统一按平台分隔符拼接，避免缓存校验与实际扫描路径出现分叉。
    final normalizedRoot = rootPath.replaceAll('\\', Platform.pathSeparator);
    final normalizedRelative = relativePath.replaceAll(
      '/',
      Platform.pathSeparator,
    );
    return '$normalizedRoot${Platform.pathSeparator}$normalizedRelative';
  }
}

class _WorkspaceInformationCacheEntry {
  const _WorkspaceInformationCacheEntry({
    required this.projectRootPath,
    required this.workspaceSignature,
    required this.sourceStats,
    required this.viewData,
  });

  final String projectRootPath;
  final String workspaceSignature;
  final List<_TrackedSourceStat> sourceStats;
  final WorkbenchInformationViewData viewData;
}

class _TrackedSourceStat {
  const _TrackedSourceStat({
    required this.relativePath,
    required this.modifiedAt,
    required this.size,
  });

  final String relativePath;
  final DateTime modifiedAt;
  final int size;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _TrackedSourceStat &&
            other.relativePath == relativePath &&
            other.modifiedAt == modifiedAt &&
            other.size == size;
  }

  @override
  int get hashCode => Object.hash(relativePath, modifiedAt, size);
}
