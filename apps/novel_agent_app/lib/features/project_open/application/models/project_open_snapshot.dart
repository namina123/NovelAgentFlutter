import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectOpenSnapshot {
  const ProjectOpenSnapshot({
    required this.projectsRootPath,
    required this.recentProjectPath,
    required this.currentProjectPath,
    required this.allowImportLocal,
    required this.records,
    required this.selectedEntryId,
    required this.status,
  });

  final String projectsRootPath;
  final String recentProjectPath;
  final String currentProjectPath;
  final bool allowImportLocal;
  final List<ProjectOpenProjectRecord> records;
  final String selectedEntryId;
  final String status;

  factory ProjectOpenSnapshot.initial() {
    return const ProjectOpenSnapshot(
      projectsRootPath: '',
      recentProjectPath: '',
      currentProjectPath: '',
      allowImportLocal: true,
      records: <ProjectOpenProjectRecord>[],
      selectedEntryId: '',
      status: '',
    );
  }

  ProjectOpenSnapshot copyWith({
    String? projectsRootPath,
    String? recentProjectPath,
    String? currentProjectPath,
    bool? allowImportLocal,
    List<ProjectOpenProjectRecord>? records,
    String? selectedEntryId,
    String? status,
  }) {
    return ProjectOpenSnapshot(
      projectsRootPath: projectsRootPath ?? this.projectsRootPath,
      recentProjectPath: recentProjectPath ?? this.recentProjectPath,
      currentProjectPath: currentProjectPath ?? this.currentProjectPath,
      allowImportLocal: allowImportLocal ?? this.allowImportLocal,
      records: records ?? this.records,
      selectedEntryId: selectedEntryId ?? this.selectedEntryId,
      status: status ?? this.status,
    );
  }

  ProjectOpenSnapshot selectEntry(String entryId) {
    return copyWith(selectedEntryId: entryId.trim());
  }

  factory ProjectOpenSnapshot.fromJson(JsonMap payload) {
    // 中文注释: 背景 isolate 只回传基础类型，主 isolate 在这里把作品发现快照还原成正式模型。
    return ProjectOpenSnapshot(
      projectsRootPath: ValueReaders.stringValue(payload['projects_root_path']),
      recentProjectPath: ValueReaders.stringValue(payload['recent_project_path']),
      currentProjectPath: ValueReaders.stringValue(
        payload['current_project_path'],
      ),
      allowImportLocal: ValueReaders.boolValue(payload['allow_import_local']),
      records: ValueReaders.mapList(payload['records'])
          .map(ProjectOpenProjectRecord.fromJson)
          .toList(growable: false),
      selectedEntryId: ValueReaders.stringValue(payload['selected_entry_id']),
      status: ValueReaders.stringValue(payload['status']),
    );
  }
}

class ProjectOpenProjectRecord {
  const ProjectOpenProjectRecord({
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

  factory ProjectOpenProjectRecord.fromJson(JsonMap payload) {
    // 中文注释: 记录字段只由基础类型重建，避免跨 isolate 传递自定义对象。
    return ProjectOpenProjectRecord(
      id: ValueReaders.stringValue(payload['id']),
      title: ValueReaders.stringValue(payload['title']),
      path: ValueReaders.stringValue(payload['path']),
      projectTypeId: ValueReaders.stringValue(payload['project_type_id']),
      storageStrategyId: ValueReaders.stringValue(
        payload['storage_strategy_id'],
      ),
      runtimeBaselineId: ValueReaders.stringValue(
        payload['runtime_baseline_id'],
      ),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        ValueReaders.intValue(payload['modified_at_ms']),
      ),
      sourceBadges: ValueReaders.stringList(payload['source_badges']),
      isCurrentProject: ValueReaders.boolValue(payload['is_current_project']),
    );
  }
}
