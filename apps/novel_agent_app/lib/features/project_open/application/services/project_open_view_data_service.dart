import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_open_snapshot.dart';
import '../../presentation/models/project_open_view_data.dart';

class ProjectOpenViewDataService {
  ProjectOpenViewDataService({
    ProjectTypeCatalogService? projectTypeCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService();

  final ProjectTypeCatalogService _projectTypeCatalogService;

  ProjectOpenViewData build(ProjectOpenSnapshot snapshot) {
    final entries = snapshot.records
        .map(
          (record) => ProjectOpenEntryViewData(
            id: record.id,
            title: record.title,
            path: record.path,
            projectTypeLabel:
                _projectTypeCatalogService.definitionOf(record.projectTypeId).name,
            storageLabel: _storageLabel(record.storageStrategyId),
            runtimeBaselineLabel: record.runtimeBaselineId.trim().isEmpty
                ? '未指定'
                : record.runtimeBaselineId,
            lastModifiedLabel: _formatModifiedAt(record.modifiedAt),
            sourceBadges: List<String>.unmodifiable(record.sourceBadges),
            isCurrentProject: record.isCurrentProject,
            isSelected: record.id == snapshot.selectedEntryId,
          ),
        )
        .toList(growable: false);
    return ProjectOpenViewData(
      title: '作品库',
      description: '先新建作品，或从默认项目目录继续打开已有作品。',
      projectsRootPath: snapshot.projectsRootPath,
      currentProjectPath: snapshot.currentProjectPath,
      allowImportLocal: snapshot.allowImportLocal,
      entries: entries,
      selectedEntryId: snapshot.selectedEntryId,
      status: snapshot.status.trim().isNotEmpty
          ? snapshot.status.trim()
          : entries.isEmpty
          ? '还没有可继续的作品。'
          : '',
    );
  }

  ProjectOpenViewData selectEntry(ProjectOpenViewData current, String entryId) {
    final cleanId = entryId.trim();
    return current.copyWith(
      selectedEntryId: cleanId,
      entries: current.entries
          .map((entry) => entry.copyWith(isSelected: entry.id == cleanId))
          .toList(growable: false),
    );
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
}
