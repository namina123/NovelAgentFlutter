import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_json_document_service.dart';
import '../storage/project_task_repository.dart';
import 'project_tool_permission_approval_path_service.dart';

abstract final class ProjectToolPermissionApprovalScopes {
  static const String ordinaryConversation = 'ordinary_conversation';
  static const String workflowTask = 'workflow_task';
}

abstract final class ProjectToolPermissionApprovalStatuses {
  static const String pending = 'pending';
  static const String resolved = 'resolved';
  static const String consumed = 'consumed';
}

abstract final class ProjectToolPermissionApprovalOptionKinds {
  static const String allowOnce = 'allow_once';
  static const String denyAndContinue = 'deny_and_continue';
}

class ProjectToolPermissionApprovalRecordService {
  ProjectToolPermissionApprovalRecordService({
    required ProjectTaskRepository taskRepository,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectToolPermissionApprovalPathService? pathService,
  }) : _taskRepository = taskRepository,
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(
             workspacePort: taskRepository.workspacePort,
           ),
       _pathService = pathService ?? ProjectToolPermissionApprovalPathService();

  final ProjectTaskRepository _taskRepository;
  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectToolPermissionApprovalPathService _pathService;

  Future<JsonMap> persistPendingApprovalsForExecutedTools(
    ProjectDescriptor project, {
    required String scopeType,
    required List<Object?> executedTools,
    String sessionId = '',
    String taskPath = '',
    String executionPath = '',
  }) async {
    final changedPaths = <String>[];
    final nextExecutedTools = <Object?>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      if (!_isPermissionWaitingResult(result)) {
        nextExecutedTools.add(ValueReaders.deepCopyMap(tool));
        continue;
      }
      final persisted = await _persistSingleApproval(
        project,
        tool: tool,
        result: result,
        scopeType: scopeType,
        sessionId: sessionId,
        taskPath: taskPath,
        executionPath: executionPath,
      );
      final recordPath = ValueReaders.stringValue(
        persisted['relative_path'],
      ).trim();
      if (recordPath.isNotEmpty) {
        changedPaths.add(recordPath);
      }
      nextExecutedTools.add(ValueReaders.mapValue(persisted['tool']));
    }
    return <String, Object?>{
      'executed_tools': nextExecutedTools,
      'changed_paths': changedPaths,
    };
  }

  Future<List<JsonMap>> listPending(
    ProjectDescriptor project, {
    String scopeType = '',
    String sessionId = '',
    String taskPath = '',
  }) async {
    final records = <JsonMap>[];
    for (final approvalId in await _indexedApprovalIds(project)) {
      final record = await _loadRecord(project, approvalId);
      if (record.isEmpty) {
        continue;
      }
      if (ValueReaders.stringValue(record['status']) !=
          ProjectToolPermissionApprovalStatuses.pending) {
        continue;
      }
      if (scopeType.trim().isNotEmpty &&
          ValueReaders.stringValue(record['scope_type']).trim() !=
              scopeType.trim()) {
        continue;
      }
      if (sessionId.trim().isNotEmpty &&
          ValueReaders.stringValue(record['session_id']).trim() !=
              sessionId.trim()) {
        continue;
      }
      if (taskPath.trim().isNotEmpty &&
          ValueReaders.stringValue(record['task_path']).trim() !=
              taskPath.trim()) {
        continue;
      }
      records.add(record);
    }
    records.sort((left, right) {
      final leftCreatedAt = ValueReaders.stringValue(left['created_at']);
      final rightCreatedAt = ValueReaders.stringValue(right['created_at']);
      return rightCreatedAt.compareTo(leftCreatedAt);
    });
    return records;
  }

  List<JsonMap> pendingOptionsForRecords(List<JsonMap> records) {
    final result = <JsonMap>[];
    for (final record in records) {
      final question = ValueReaders.stringValue(record['question']).trim();
      final approvalId = ValueReaders.stringValue(record['id']).trim();
      for (final rawOption in ValueReaders.objectList(record['options'])) {
        final option = ValueReaders.mapValue(rawOption);
        if (option.isEmpty) {
          continue;
        }
        result.add(
          _decorateOption(option, approvalId: approvalId, question: question),
        );
      }
    }
    return result;
  }

  Future<JsonMap> resolveSelection(
    ProjectDescriptor project, {
    required String approvalId,
    required String optionId,
    String actorId = 'project_tool_permission_approval_record_service',
  }) async {
    final record = await _loadRecord(project, approvalId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Tool permission approval record not found.',
        'approval_id': approvalId,
      };
    }
    final status = ValueReaders.stringValue(record['status']).trim();
    if (status == ProjectToolPermissionApprovalStatuses.consumed) {
      return <String, Object?>{
        'ok': true,
        'approval_id': approvalId,
        'status': status,
        'action_status': 'already_consumed',
      };
    }
    final option = _optionById(record, optionId);
    if (option.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Permission approval option not found.',
        'approval_id': approvalId,
      };
    }
    final now = DateTime.now().toIso8601String();
    final nextRecord = ValueReaders.deepCopyMap(record)
      ..['status'] = ProjectToolPermissionApprovalStatuses.resolved
      ..['selected_option_id'] = ValueReaders.stringValue(option['id'])
      ..['selected_option_kind'] = ValueReaders.stringValue(
        option['approval_option_kind'],
        ValueReaders.stringValue(option['id']),
      )
      ..['selected_option'] = ValueReaders.deepCopyMap(option)
      ..['resolved_at'] = now
      ..['resolved_by'] = actorId
      ..['updated_at'] = now;
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.recordPath(approvalId),
      nextRecord,
    );
    return <String, Object?>{
      'ok': true,
      'approval_id': approvalId,
      'status': ProjectToolPermissionApprovalStatuses.resolved,
      'selected_option': ValueReaders.deepCopyMap(option),
      'selected_option_kind': ValueReaders.stringValue(
        option['approval_option_kind'],
        ValueReaders.stringValue(option['id']),
      ),
      'prompt': ValueReaders.stringValue(option['prompt']),
      'changed_paths': <Object?>[_pathService.recordPath(approvalId)],
    };
  }

  Future<JsonMap> consumeResolvedOverrideContext(
    ProjectDescriptor project, {
    required String approvalId,
  }) async {
    final record = await _loadRecord(project, approvalId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Tool permission approval record not found.',
        'approval_id': approvalId,
      };
    }
    final status = ValueReaders.stringValue(record['status']).trim();
    final selectedKind = ValueReaders.stringValue(
      record['selected_option_kind'],
    ).trim();
    if (status == ProjectToolPermissionApprovalStatuses.consumed) {
      return <String, Object?>{
        'ok': true,
        'approval_id': approvalId,
        'status': status,
        'action_status': 'already_consumed',
      };
    }
    if (status != ProjectToolPermissionApprovalStatuses.resolved ||
        selectedKind != ProjectToolPermissionApprovalOptionKinds.allowOnce) {
      return <String, Object?>{
        'ok': true,
        'approval_id': approvalId,
        'status': status,
        'action_status': 'no_override',
      };
    }
    final baseContext = HostToolPermissionContext.fromJson(
      ValueReaders.mapValue(record['permission_context']),
    );
    final capability = ValueReaders.stringValue(
      record['permission_capability'],
    );
    final overrideContext = _contextAllowingCapability(baseContext, capability);
    final now = DateTime.now().toIso8601String();
    final nextRecord = ValueReaders.deepCopyMap(record)
      ..['status'] = ProjectToolPermissionApprovalStatuses.consumed
      ..['consumed_at'] = now
      ..['updated_at'] = now;
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.recordPath(approvalId),
      nextRecord,
    );
    return <String, Object?>{
      'ok': true,
      'approval_id': approvalId,
      'status': ProjectToolPermissionApprovalStatuses.consumed,
      'action_status': 'override_ready',
      'host_tool_permission_context': overrideContext.toJson(),
      'changed_paths': <Object?>[_pathService.recordPath(approvalId)],
    };
  }

  Future<JsonMap> _persistSingleApproval(
    ProjectDescriptor project, {
    required JsonMap tool,
    required JsonMap result,
    required String scopeType,
    required String sessionId,
    required String taskPath,
    required String executionPath,
  }) async {
    final now = DateTime.now().toIso8601String();
    final approvalId =
        'tool_permission_${DateTime.now().microsecondsSinceEpoch}_${ValueReaders.stringValue(tool['call_id'], ValueReaders.stringValue(tool['name'], 'tool')).trim()}';
    final question = ValueReaders.stringValue(result['question']).trim();
    final options = ValueReaders.objectList(
      result['options'],
    ).map(ValueReaders.mapValue).toList(growable: false);
    final decoratedOptions = <Object?>[];
    for (final rawOption in options) {
      final optionId = ValueReaders.stringValue(
        rawOption['id'],
        'option_${decoratedOptions.length + 1}',
      ).trim();
      decoratedOptions.add(
        _decorateOption(
          rawOption,
          approvalId: approvalId,
          question: question,
          optionId: optionId,
        ),
      );
    }
    final record = <String, Object?>{
      'schema_version': 1,
      'id': approvalId,
      'status': ProjectToolPermissionApprovalStatuses.pending,
      'scope_type': scopeType,
      'session_id': sessionId.trim(),
      'task_path': taskPath.trim(),
      'execution_path': executionPath.trim(),
      'tool_name': ValueReaders.stringValue(tool['name']).trim(),
      'tool_call_id': ValueReaders.stringValue(tool['call_id']).trim(),
      'question': question,
      'options': decoratedOptions,
      'permission_decision': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(result['permission_decision']),
      ),
      'permission_capability': ValueReaders.stringValue(
        result['permission_capability'],
      ).trim(),
      'permission_context': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(result['permission_context']),
      ),
      'created_at': now,
      'updated_at': now,
    };
    final relativePath = _pathService.recordPath(approvalId);
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      relativePath,
      record,
    );
    await _appendIndex(project, approvalId);
    final nextResult = ValueReaders.deepCopyMap(result)
      ..['permission_approval_id'] = approvalId
      ..['options'] = decoratedOptions;
    return <String, Object?>{
      'relative_path': relativePath,
      'tool': ValueReaders.deepCopyMap(tool)..['result'] = nextResult,
    };
  }

  bool _isPermissionWaitingResult(JsonMap result) {
    return ValueReaders.boolValue(result['waiting_for_user_choice']) &&
        ValueReaders.mapValue(result['permission_decision']).isNotEmpty;
  }

  Future<List<String>> _indexedApprovalIds(ProjectDescriptor project) async {
    final index = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.indexPath(),
    );
    return ValueReaders.stringList(index['approval_ids']);
  }

  Future<void> _appendIndex(
    ProjectDescriptor project,
    String approvalId,
  ) async {
    final approvalIds = await _indexedApprovalIds(project);
    if (approvalIds.contains(approvalId)) {
      return;
    }
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.indexPath(),
      <String, Object?>{
        'schema_version': 1,
        'approval_ids': <Object?>[...approvalIds, approvalId],
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<JsonMap> _loadRecord(
    ProjectDescriptor project,
    String approvalId,
  ) async {
    final record = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.recordPath(approvalId),
    );
    if (record.isEmpty) {
      return record;
    }
    return ValueReaders.deepCopyMap(record)
      ..['relative_path'] = _pathService.recordPath(approvalId);
  }

  JsonMap _optionById(JsonMap record, String optionId) {
    final cleanOptionId = optionId.trim();
    for (final rawOption in ValueReaders.objectList(record['options'])) {
      final option = ValueReaders.mapValue(rawOption);
      if (ValueReaders.stringValue(option['id']).trim() == cleanOptionId) {
        return option;
      }
    }
    return const <String, Object?>{};
  }

  JsonMap _decorateOption(
    JsonMap option, {
    required String approvalId,
    required String question,
    String optionId = '',
  }) {
    final cleanOptionId = optionId.trim().isEmpty
        ? ValueReaders.stringValue(
            option['id'],
            'option_${DateTime.now().microsecondsSinceEpoch}',
          ).trim()
        : optionId.trim();
    final optionKind =
        cleanOptionId == ProjectToolPermissionApprovalOptionKinds.allowOnce
        ? ProjectToolPermissionApprovalOptionKinds.allowOnce
        : ProjectToolPermissionApprovalOptionKinds.denyAndContinue;
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(option),
      'id': cleanOptionId,
      'approval_record_id': approvalId,
      'approval_option_id': cleanOptionId,
      'approval_option_kind': optionKind,
      'source_question': question,
    };
  }

  HostToolPermissionContext _contextAllowingCapability(
    HostToolPermissionContext baseContext,
    String capability,
  ) {
    final cleanCapability = capability.trim();
    switch (cleanCapability) {
      case HostToolPermissionPolicyService.capabilityRead:
        return baseContext.copyWith(
          allowRead: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityWrite:
        return baseContext.copyWith(
          allowWrite: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityDelete:
        return baseContext.copyWith(
          allowDelete: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityNetwork:
        return baseContext.copyWith(
          allowNetwork: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityProcess:
        return baseContext.copyWith(
          allowProcess: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilitySubAgents:
        return baseContext.copyWith(
          allowSubAgents: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityLongTaskControl:
        return baseContext.copyWith(
          allowLongTaskControl: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      case HostToolPermissionPolicyService.capabilityFormalDelivery:
        return baseContext.copyWith(
          allowFormalDelivery: true,
          source: 'tool_permission_approval:$cleanCapability',
        );
      default:
        return baseContext.copyWith(
          source: 'tool_permission_approval:$cleanCapability',
        );
    }
  }
}
