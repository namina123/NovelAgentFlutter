import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_open_view_data.dart';

typedef LoadProjectWorkspaceSnapshot =
    Future<ProjectWorkspaceSnapshot?> Function(String rootPath);

class ProjectOpenViewDataService {
  ProjectOpenViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;

  Future<ProjectOpenViewData> build({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    required LoadProjectWorkspaceSnapshot loadWorkspace,
    String selectedEntryId = '',
    String status = '',
  }) async {
    final descriptors = <String, _ProjectOpenRecord>{};
    final normalizedProjectsRootPath = projectsRootPath.trim();
    if (normalizedProjectsRootPath.isNotEmpty) {
      await _tryCollectProject(
        normalizedProjectsRootPath,
        descriptors,
        sourceLabel: '默认目录',
        loadWorkspace: loadWorkspace,
        currentProjectPath: currentProjectPath,
      );
      final rootDirectory = Directory(normalizedProjectsRootPath);
      if (await rootDirectory.exists()) {
        await for (final entity in rootDirectory.list(followLinks: false)) {
          if (entity is! Directory) {
            continue;
          }
          await _tryCollectProject(
            entity.path,
            descriptors,
            sourceLabel: '默认目录',
            loadWorkspace: loadWorkspace,
            currentProjectPath: currentProjectPath,
          );
        }
      }
    }
    if (recentProjectPath.trim().isNotEmpty) {
      await _tryCollectProject(
        recentProjectPath,
        descriptors,
        sourceLabel: '最近项目',
        loadWorkspace: loadWorkspace,
        currentProjectPath: currentProjectPath,
      );
    }

    final entries = descriptors.values.toList(growable: false)
      ..sort(_compareRecords);
    final resolvedSelectedEntryId = _resolveSelectedEntryId(
      requestedId: selectedEntryId,
      records: entries,
    );
    return ProjectOpenViewData(
      title: '打开项目',
      description: '从默认项目目录继续工作，或导入一个本地已有项目。',
      projectsRootPath: normalizedProjectsRootPath,
      currentProjectPath: currentProjectPath.trim(),
      allowImportLocal: allowImportLocal,
      entries: entries
          .map(
            (record) => ProjectOpenEntryViewData(
              id: record.id,
              title: record.title,
              path: record.path,
              projectTypeLabel: _projectTypeCatalogService
                  .definitionOf(record.projectTypeId)
                  .name,
              storageLabel: _storageLabel(record.storageStrategyId),
              runtimeBaselineLabel: record.runtimeBaselineId.trim().isEmpty
                  ? '未指定'
                  : record.runtimeBaselineId,
              lastModifiedLabel: _formatModifiedAt(record.modifiedAt),
              sourceBadges: List<String>.unmodifiable(record.sourceBadges),
              isCurrentProject: record.isCurrentProject,
              isSelected: record.id == resolvedSelectedEntryId,
            ),
          )
          .toList(growable: false),
      selectedEntryId: resolvedSelectedEntryId,
      status: status.trim().isNotEmpty
          ? status.trim()
          : entries.isEmpty
          ? '默认项目目录下还没有可打开的项目。'
          : '',
    );
  }

  ProjectOpenViewData selectEntry(
    ProjectOpenViewData current,
    String entryId,
  ) {
    final cleanId = entryId.trim();
    return current.copyWith(
      selectedEntryId: cleanId,
      entries: current.entries
          .map((entry) => entry.copyWith(isSelected: entry.id == cleanId))
          .toList(growable: false),
    );
  }

  Future<void> _tryCollectProject(
    String rootPath,
    Map<String, _ProjectOpenRecord> output, {
    required String sourceLabel,
    required LoadProjectWorkspaceSnapshot loadWorkspace,
    required String currentProjectPath,
  }) async {
    final cleanRootPath = rootPath.trim();
    if (cleanRootPath.isEmpty) {
      return;
    }
    final snapshot = await loadWorkspace(cleanRootPath);
    if (snapshot == null) {
      return;
    }
    final key = _pathKey(snapshot.project.rootPath);
    final modifiedAt = await _readModifiedAt(snapshot.project.rootPath);
    final existing = output[key];
    final nextBadges = <String>{
      if (existing != null) ...existing.sourceBadges,
      sourceLabel,
    }.toList(growable: false);
    output[key] = _ProjectOpenRecord(
      id: key,
      title: snapshot.project.name,
      path: snapshot.project.rootPath,
      projectTypeId: snapshot.project.projectType,
      storageStrategyId: snapshot.project.storageStrategy.id,
      runtimeBaselineId: snapshot.project.runtimeBaselineId,
      modifiedAt: modifiedAt,
      sourceBadges: nextBadges,
      isCurrentProject:
          _pathKey(currentProjectPath) == _pathKey(snapshot.project.rootPath),
    );
  }

  int _compareRecords(_ProjectOpenRecord left, _ProjectOpenRecord right) {
    if (left.isCurrentProject != right.isCurrentProject) {
      return left.isCurrentProject ? -1 : 1;
    }
    final leftRecent = left.sourceBadges.contains('最近项目');
    final rightRecent = right.sourceBadges.contains('最近项目');
    if (leftRecent != rightRecent) {
      return leftRecent ? -1 : 1;
    }
    final modifiedOrder = right.modifiedAt.compareTo(left.modifiedAt);
    if (modifiedOrder != 0) {
      return modifiedOrder;
    }
    return left.title.compareTo(right.title);
  }

  String _resolveSelectedEntryId({
    required String requestedId,
    required List<_ProjectOpenRecord> records,
  }) {
    final cleanRequestedId = requestedId.trim();
    if (cleanRequestedId.isNotEmpty) {
      for (final record in records) {
        if (record.id == cleanRequestedId) {
          return cleanRequestedId;
        }
      }
    }
    for (final record in records) {
      if (record.isCurrentProject) {
        return record.id;
      }
    }
    for (final record in records) {
      if (record.sourceBadges.contains('最近项目')) {
        return record.id;
      }
    }
    return records.isEmpty ? '' : records.first.id;
  }

  Future<DateTime> _readModifiedAt(String rootPath) async {
    try {
      return await Directory(rootPath).stat().then((value) => value.modified);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _storageLabel(String storageStrategyId) {
    switch (storageStrategyId.trim()) {
      case 'sqlite_project_store':
        return 'SQLite';
      case 'markdown_project_store':
      default:
        return 'Markdown';
    }
  }

  String _formatModifiedAt(DateTime modifiedAt) {
    if (modifiedAt.millisecondsSinceEpoch <= 0) {
      return '未知';
    }
    final month = modifiedAt.month.toString().padLeft(2, '0');
    final day = modifiedAt.day.toString().padLeft(2, '0');
    final hour = modifiedAt.hour.toString().padLeft(2, '0');
    final minute = modifiedAt.minute.toString().padLeft(2, '0');
    return '${modifiedAt.year}-$month-$day $hour:$minute';
  }

  String _pathKey(String path) {
    final normalized = path.trim().replaceAll('\\', '/').replaceAll(
      RegExp(r'/+$'),
      '',
    );
    if (Platform.isWindows) {
      return normalized.toLowerCase();
    }
    return normalized;
  }
}

class _ProjectOpenRecord {
  const _ProjectOpenRecord({
    required this.id,
    required this.title,
    required this.path,
    required this.projectTypeId,
    required this.storageStrategyId,
    required this.runtimeBaselineId,
    required this.modifiedAt,
    required this.sourceBadges,
    required this.isCurrentProject,
  });

  final String id;
  final String title;
  final String path;
  final String projectTypeId;
  final String storageStrategyId;
  final String runtimeBaselineId;
  final DateTime modifiedAt;
  final List<String> sourceBadges;
  final bool isCurrentProject;
}
