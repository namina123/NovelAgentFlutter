import 'package:novel_agent_core/novel_agent_core.dart';

class RunInstanceDocumentCodecService {
  const RunInstanceDocumentCodecService();

  JsonMap encode(RunInstance instance) {
    // 中文注释: 全局运行实例文档采用稳定扁平 JSON 结构，避免 registry 持久化时再依赖页面态或 workflow 临时 map。
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'global_long_task_run_instance',
      'id': instance.id,
      'runtime_baseline_id': instance.runtimeBaselineId,
      'mode_id': instance.modeId,
      'workflow_strategy_id': instance.workflowStrategyId,
      'status': instance.status.id,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_heartbeat_at': instance.lastHeartbeatAt?.toIso8601String() ?? '',
      'started_at': instance.startedAt?.toIso8601String() ?? '',
      'stopped_at': instance.stoppedAt?.toIso8601String() ?? '',
      'active_task_id': instance.activeTaskId,
      'active_task_title': instance.activeTaskTitle,
      'note': instance.note,
      'stop_reason': instance.stopReason,
      'metadata': ValueReaders.deepCopyMap(instance.metadata),
      'project': <String, Object?>{
        'project_id': instance.project.projectId,
        'project_key': instance.project.projectKey,
        'root_path': instance.project.rootPath,
        'title': instance.project.title,
        'project_type_id': instance.project.projectTypeId,
        'storage_strategy': instance.project.storageStrategy.id,
      },
    };
  }

  RunInstance decode(JsonMap document) {
    final project = ValueReaders.mapValue(document['project']);
    return RunInstance(
      id: ValueReaders.stringValue(document['id']),
      project: RunProjectReference(
        projectId: ValueReaders.stringValue(project['project_id']),
        projectKey: ValueReaders.stringValue(project['project_key']),
        rootPath: ValueReaders.stringValue(project['root_path']),
        title: ValueReaders.stringValue(project['title']),
        projectTypeId: ValueReaders.stringValue(project['project_type_id']),
        storageStrategy: ProjectStorageStrategy.fromId(
          ValueReaders.stringValue(project['storage_strategy']),
        ),
      ),
      runtimeBaselineId: ValueReaders.stringValue(
        document['runtime_baseline_id'],
      ),
      modeId: ValueReaders.stringValue(document['mode_id']),
      workflowStrategyId: ValueReaders.stringValue(
        document['workflow_strategy_id'],
      ),
      status: LongTaskRunStatus.fromId(
        ValueReaders.stringValue(document['status']),
      ),
      createdAt: _dateTimeValue(document['created_at']),
      updatedAt: _dateTimeValue(document['updated_at']),
      lastHeartbeatAt: _optionalDateTimeValue(document['last_heartbeat_at']),
      startedAt: _optionalDateTimeValue(document['started_at']),
      stoppedAt: _optionalDateTimeValue(document['stopped_at']),
      activeTaskId: ValueReaders.stringValue(document['active_task_id']),
      activeTaskTitle: ValueReaders.stringValue(document['active_task_title']),
      note: ValueReaders.stringValue(document['note']),
      stopReason: ValueReaders.stringValue(document['stop_reason']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }

  DateTime _dateTimeValue(Object? rawValue) {
    final parsed = _optionalDateTimeValue(rawValue);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  DateTime? _optionalDateTimeValue(Object? rawValue) {
    final text = ValueReaders.stringValue(rawValue).trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
