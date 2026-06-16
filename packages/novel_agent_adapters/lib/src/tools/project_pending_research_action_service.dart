import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_information_event_repository.dart';
import '../storage/open_narrative_state_index_document_service.dart';
import '../storage/open_narrative_state_record_document_service.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_json_document_service.dart';

abstract final class ProjectPendingResearchRequestStates {
  static const String pendingGatewayExecution = 'pending_gateway_execution';
  static const String pendingReview = 'pending_review';
  static const String awaitingUserConfirmation = 'awaiting_user_confirmation';
  static const String needsUserInfo = 'needs_user_info';
  static const String rejected = 'rejected';
  static const String completed = 'completed';

  static const Set<String> actionableStates = <String>{
    pendingGatewayExecution,
    pendingReview,
    awaitingUserConfirmation,
    needsUserInfo,
  };
}

abstract final class ProjectPendingResearchActionCommands {
  static const String approve = 'approve';
  static const String reject = 'reject';
  static const String markNeedsUserInfo = 'mark_needs_user_info';
}

class ProjectPendingResearchActionService {
  ProjectPendingResearchActionService({
    required ProjectWorkspacePort workspacePort,
    ProjectInformationPathService? pathService,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStateIndexDocumentService? indexDocumentService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    InformationEventRepository? informationEventRepository,
  }) : _pathService = pathService ?? ProjectInformationPathService(),
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _indexDocumentService =
           indexDocumentService ??
           OpenNarrativeStateIndexDocumentService(
             jsonDocumentService:
                 jsonDocumentService ??
                 ProjectJsonDocumentService(workspacePort: workspacePort),
           ),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _informationEventRepository =
           informationEventRepository ??
           LocalInformationEventRepository(workspacePort: workspacePort);

  final ProjectInformationPathService _pathService;
  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final InformationEventRepository _informationEventRepository;

  Future<JsonMap> load(ProjectDescriptor project, {required String requestId}) {
    // 中文注释: 读取单条 pending research 记录是 CLI/GUI 展示同一审批真相的基础，不应只靠 list 反推。
    return _readRecord(project, requestId).then((record) {
      if (record.isEmpty) {
        return record;
      }
      return ValueReaders.deepCopyMap(record)
        ..['relative_path'] = _pathService.researchRequestPath(requestId);
    });
  }

  Future<List<JsonMap>> list(ProjectDescriptor project) async {
    // 中文注释: 统一列出仍可处理的 pending research request，供 GUI/CLI 后续复用，不让外层自己扫隐藏 JSON。
    final requestIds = await _indexDocumentService.readIds(
      project.rootPath,
      _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
    );
    final result = <JsonMap>[];
    for (final requestId in requestIds) {
      final record = await _readRecord(project, requestId);
      if (record.isEmpty) {
        continue;
      }
      final requestState = ValueReaders.stringValue(
        record['request_state'],
      ).trim();
      if (!ProjectPendingResearchRequestStates.actionableStates.contains(
        requestState,
      )) {
        continue;
      }
      result.add(record);
    }
    return result;
  }

  Future<JsonMap> approve(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) {
    // 中文注释: approve 只把 research request 放回可后续执行的待处理状态，不在这一轮直接触发 gateway。
    return _applyAction(
      project,
      requestId: requestId,
      command: ProjectPendingResearchActionCommands.approve,
      actorId: actorId,
      note: note,
    );
  }

  Future<JsonMap> reject(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) {
    // 中文注释: reject 保留 request 与 evidence gap，只更新状态和审计，不删除记录。
    return _applyAction(
      project,
      requestId: requestId,
      command: ProjectPendingResearchActionCommands.reject,
      actorId: actorId,
      note: note,
    );
  }

  Future<JsonMap> markNeedsUserInfo(
    ProjectDescriptor project, {
    required String requestId,
    String actorId = 'pending_research_action_service',
    String note = '',
  }) {
    // 中文注释: 该动作只表达“当前信息还不够，需要用户补充”，不把 request 误判成已拒绝或已完成。
    return _applyAction(
      project,
      requestId: requestId,
      command: ProjectPendingResearchActionCommands.markNeedsUserInfo,
      actorId: actorId,
      note: note,
    );
  }

  Future<JsonMap> _applyAction(
    ProjectDescriptor project, {
    required String requestId,
    required String command,
    required String actorId,
    required String note,
  }) async {
    final record = await _readRecord(project, requestId);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Pending research request not found.',
        'request_id': requestId,
        'changed_paths': const <Object?>[],
      };
    }
    final currentState = ValueReaders.stringValue(
      record['request_state'],
    ).trim();
    final currentAction = _currentAction(record);
    final transition = _resolveTransition(
      command: command,
      currentState: currentState,
      currentAction: currentAction,
    );
    if (!transition.allowed) {
      return <String, Object?>{
        'ok': false,
        'error': transition.message,
        'request_id': requestId,
        'request_state': currentState,
        'action_status': 'not_allowed',
        'changed_paths': const <Object?>[],
      };
    }
    if (transition.alreadyApplied) {
      return <String, Object?>{
        'ok': true,
        'request_id': requestId,
        'request_state': currentState,
        'action_status': 'already_applied',
        'changed_paths': const <Object?>[],
      };
    }

    final updatedRecord = _updatedRecord(
      record,
      command: command,
      nextState: transition.nextState,
      actorId: actorId,
      note: note,
    );
    final recordPath = _pathService.researchRequestPath(requestId);
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: recordPath,
      document: updatedRecord,
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    await _appendActionEvent(
      project,
      requestId: requestId,
      nextState: transition.nextState,
      command: command,
      actorId: actorId,
      note: note,
      record: updatedRecord,
    );
    return <String, Object?>{
      'ok': true,
      'request_id': requestId,
      'request_state': transition.nextState,
      'action_status': 'updated',
      'changed_paths': <Object?>[
        recordPath,
        _pathService.researchRequestsIndexPath(),
        _pathService.informationEventsLogPath(),
      ],
    };
  }

  Future<JsonMap> _readRecord(ProjectDescriptor project, String requestId) {
    return _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.researchRequestPath(requestId),
    );
  }

  _PendingResearchTransition _resolveTransition({
    required String command,
    required String currentState,
    required String currentAction,
  }) {
    if (currentState == ProjectPendingResearchRequestStates.rejected) {
      if (command == ProjectPendingResearchActionCommands.reject) {
        return const _PendingResearchTransition.alreadyApplied(
          ProjectPendingResearchRequestStates.rejected,
        );
      }
      return _PendingResearchTransition.notAllowed(
        'Rejected research request cannot accept further actions.',
      );
    }
    if (currentState.isEmpty ||
        currentState == ProjectPendingResearchRequestStates.completed) {
      return _PendingResearchTransition.notAllowed(
        'Current research request state does not allow this action.',
      );
    }
    switch (command) {
      case ProjectPendingResearchActionCommands.approve:
        if (currentState ==
            ProjectPendingResearchRequestStates.pendingGatewayExecution) {
          return const _PendingResearchTransition.alreadyApplied(
            ProjectPendingResearchRequestStates.pendingGatewayExecution,
          );
        }
        if (currentAction == ProjectPendingResearchActionCommands.approve &&
            currentState ==
                ProjectPendingResearchRequestStates.pendingGatewayExecution) {
          return const _PendingResearchTransition.alreadyApplied(
            ProjectPendingResearchRequestStates.pendingGatewayExecution,
          );
        }
        return const _PendingResearchTransition.allowed(
          ProjectPendingResearchRequestStates.pendingGatewayExecution,
        );
      case ProjectPendingResearchActionCommands.reject:
        if (currentAction == ProjectPendingResearchActionCommands.reject &&
            currentState == ProjectPendingResearchRequestStates.rejected) {
          return const _PendingResearchTransition.alreadyApplied(
            ProjectPendingResearchRequestStates.rejected,
          );
        }
        return const _PendingResearchTransition.allowed(
          ProjectPendingResearchRequestStates.rejected,
        );
      case ProjectPendingResearchActionCommands.markNeedsUserInfo:
        if (currentState == ProjectPendingResearchRequestStates.needsUserInfo) {
          return const _PendingResearchTransition.alreadyApplied(
            ProjectPendingResearchRequestStates.needsUserInfo,
          );
        }
        if (currentAction ==
                ProjectPendingResearchActionCommands.markNeedsUserInfo &&
            currentState == ProjectPendingResearchRequestStates.needsUserInfo) {
          return const _PendingResearchTransition.alreadyApplied(
            ProjectPendingResearchRequestStates.needsUserInfo,
          );
        }
        return const _PendingResearchTransition.allowed(
          ProjectPendingResearchRequestStates.needsUserInfo,
        );
      default:
        return _PendingResearchTransition.notAllowed(
          'Unknown pending research action: $command',
        );
    }
  }

  JsonMap _updatedRecord(
    JsonMap record, {
    required String command,
    required String nextState,
    required String actorId,
    required String note,
  }) {
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(record['metadata']),
    );
    final permissionDecision = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(record['permission_decision']),
    );
    final actionLog = ValueReaders.mapList(
      metadata['pending_research_actions'],
    );
    final now = DateTime.now().toIso8601String();
    metadata['pending_research_actions'] = <Object?>[
      ...actionLog,
      <String, Object?>{
        'command': command,
        'next_state': nextState,
        'actor_id': actorId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'occurred_at': now,
      },
    ];
    metadata['latest_pending_research_action'] = <String, Object?>{
      'command': command,
      'next_state': nextState,
      'actor_id': actorId,
      if (note.trim().isNotEmpty) 'note': note.trim(),
      'occurred_at': now,
    };
    if (permissionDecision.isNotEmpty) {
      permissionDecision['disposition'] = _permissionDispositionFor(command);
      if (note.trim().isNotEmpty) {
        permissionDecision['reason'] = note.trim();
      }
      permissionDecision['resolved_by'] = actorId;
      permissionDecision['resolved_at'] = now;
    }
    return <String, Object?>{
      ...record,
      'request_state': nextState,
      'network_execution_performed': false,
      'updated_at': now,
      'resolved_by': actorId,
      if (command == ProjectPendingResearchActionCommands.approve)
        'approved_at': now,
      if (command == ProjectPendingResearchActionCommands.reject)
        'rejected_at': now,
      if (command == ProjectPendingResearchActionCommands.markNeedsUserInfo)
        'needs_user_info_at': now,
      if (note.trim().isNotEmpty) 'resolution_note': note.trim(),
      if (permissionDecision.isNotEmpty)
        'permission_decision': permissionDecision,
      'metadata': metadata,
    };
  }

  String _currentAction(JsonMap record) {
    final latest = ValueReaders.mapValue(
      ValueReaders.mapValue(
        record['metadata'],
      )['latest_pending_research_action'],
    );
    return ValueReaders.stringValue(latest['command']).trim();
  }

  Future<void> _appendActionEvent(
    ProjectDescriptor project, {
    required String requestId,
    required String nextState,
    required String command,
    required String actorId,
    required String note,
    required JsonMap record,
  }) {
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    final query = ValueReaders.stringValue(researchRequest['query']).trim();
    final occurredAt = DateTime.now().toIso8601String();
    final event = InformationEvent(
      eventId: 'research_request_action:$requestId:$command:$occurredAt',
      eventType: _eventTypeFor(command),
      subjectRef: NarrativeRef(
        refType: InformationLinkedRefTypes.researchRequest,
        refId: requestId,
      ),
      lifecycleStatus: _lifecycleStatusFor(nextState),
      actorRef: NarrativeRef(refType: NarrativeRefTypes.asset, refId: actorId),
      summary: _eventSummaryFor(command, query, note),
      occurredAt: occurredAt,
      metadata: <String, Object?>{
        'request_id': requestId,
        'command': command,
        'next_state': nextState,
        'actor_id': actorId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return _informationEventRepository.appendInformationEvent(project, event);
  }

  String _eventTypeFor(String command) {
    switch (command) {
      case ProjectPendingResearchActionCommands.approve:
        return 'research_request_approved';
      case ProjectPendingResearchActionCommands.reject:
        return 'research_request_rejected';
      case ProjectPendingResearchActionCommands.markNeedsUserInfo:
        return 'research_request_needs_user_info';
      default:
        return 'research_request_updated';
    }
  }

  String _lifecycleStatusFor(String requestState) {
    switch (requestState) {
      case ProjectPendingResearchRequestStates.rejected:
        return InformationLifecycleStatuses.rejected;
      case ProjectPendingResearchRequestStates.pendingGatewayExecution:
        return InformationLifecycleStatuses.accepted;
      case ProjectPendingResearchRequestStates.needsUserInfo:
      case ProjectPendingResearchRequestStates.awaitingUserConfirmation:
      case ProjectPendingResearchRequestStates.pendingReview:
      default:
        return InformationLifecycleStatuses.proposed;
    }
  }

  String _eventSummaryFor(String command, String query, String note) {
    final cleanQuery = query.isEmpty ? '待处理 research request' : query;
    final cleanNote = note.trim();
    switch (command) {
      case ProjectPendingResearchActionCommands.approve:
        return cleanNote.isEmpty
            ? '已确认 research request：$cleanQuery'
            : '已确认 research request：$cleanQuery；$cleanNote';
      case ProjectPendingResearchActionCommands.reject:
        return cleanNote.isEmpty
            ? '已拒绝 research request：$cleanQuery'
            : '已拒绝 research request：$cleanQuery；$cleanNote';
      case ProjectPendingResearchActionCommands.markNeedsUserInfo:
        return cleanNote.isEmpty
            ? 'research request 需要用户补充信息：$cleanQuery'
            : 'research request 需要用户补充信息：$cleanQuery；$cleanNote';
      default:
        return cleanQuery;
    }
  }

  String _permissionDispositionFor(String command) {
    switch (command) {
      case ProjectPendingResearchActionCommands.approve:
        return DomainToolPermissionDispositions.accepted;
      case ProjectPendingResearchActionCommands.reject:
        return DomainToolPermissionDispositions.rejected;
      case ProjectPendingResearchActionCommands.markNeedsUserInfo:
      default:
        return DomainToolPermissionDispositions.needsUserConfirmation;
    }
  }
}

class _PendingResearchTransition {
  const _PendingResearchTransition({
    required this.allowed,
    required this.alreadyApplied,
    required this.nextState,
    required this.message,
  });

  const _PendingResearchTransition.allowed(String nextState)
    : this(
        allowed: true,
        alreadyApplied: false,
        nextState: nextState,
        message: '',
      );

  const _PendingResearchTransition.alreadyApplied(String nextState)
    : this(
        allowed: true,
        alreadyApplied: true,
        nextState: nextState,
        message: '',
      );

  const _PendingResearchTransition.notAllowed(String message)
    : this(
        allowed: false,
        alreadyApplied: false,
        nextState: '',
        message: message,
      );

  final bool allowed;
  final bool alreadyApplied;
  final String nextState;
  final String message;
}
