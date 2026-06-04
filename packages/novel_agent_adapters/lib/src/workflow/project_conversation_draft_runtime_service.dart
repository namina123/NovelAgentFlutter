import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';
import '../tools/project_narrative_domain_tool_executor.dart';
import 'project_context_activation_service.dart';
import 'project_workflow_runtime_bridge_service.dart';

class ProjectConversationDraftRuntimePreparation {
  const ProjectConversationDraftRuntimePreparation({
    required this.runId,
    required this.taskType,
    required this.activationReportPath,
    required this.activationReport,
    required this.sessionContextMarkdown,
    required this.exposedToolIds,
  });

  final String runId;
  final String taskType;
  final String activationReportPath;
  final JsonMap activationReport;
  final String sessionContextMarkdown;
  final List<String> exposedToolIds;
}

class ProjectConversationDraftRuntimeArtifacts {
  const ProjectConversationDraftRuntimeArtifacts({
    this.outputPath = '',
    this.activationReportPath = '',
    this.activationReportSummary = '',
    this.chapterDelivery = const <String, Object?>{},
    this.changedPaths = const <String>[],
  });

  final String outputPath;
  final String activationReportPath;
  final String activationReportSummary;
  final JsonMap chapterDelivery;
  final List<String> changedPaths;
}

class ProjectConversationDraftRuntimeService {
  ProjectConversationDraftRuntimeService({
    required ProjectWorkspacePort workspacePort,
    required ProjectToolHostPort hostPort,
    ProjectTaskRepository? taskRepository,
    ProjectWorkflowRuntimeBridgeService? workflowRuntimeBridgeService,
    ProjectNarrativeDomainToolExecutor? narrativeDomainToolExecutor,
  }) : _workspacePort = workspacePort,
       _taskRepository =
           taskRepository ?? ProjectTaskRepository(workspacePort: workspacePort),
       _workflowRuntimeBridgeService =
           workflowRuntimeBridgeService ??
           ProjectWorkflowRuntimeBridgeService(
             contextActivationService: ProjectContextActivationService(
               workspacePort: workspacePort,
             ),
           ),
       _narrativeDomainToolExecutor =
           narrativeDomainToolExecutor ??
           ProjectNarrativeDomainToolExecutor(
             workspacePort: workspacePort,
             hostPort: hostPort,
           );

  final ProjectWorkspacePort _workspacePort;
  final ProjectTaskRepository _taskRepository;
  final ProjectWorkflowRuntimeBridgeService _workflowRuntimeBridgeService;
  final ProjectNarrativeDomainToolExecutor _narrativeDomainToolExecutor;

  Future<ProjectConversationDraftRuntimePreparation> prepareDraftRun(
    ProjectDescriptor project, {
    required String taskType,
    List<String> pinnedRelativePaths = const <String>[],
  }) async {
    final cleanTaskType = taskType.trim().isEmpty ? 'chapter' : taskType.trim();
    final runId = _buildRunId(cleanTaskType);
    final bridge = await _workflowRuntimeBridgeService.buildTaskBridge(project, <
      String,
      Object?>{
      'task_type': cleanTaskType,
      'metadata': <String, Object?>{
        'persistent_context_paths': pinnedRelativePaths,
      },
    });
    return ProjectConversationDraftRuntimePreparation(
      runId: runId,
      taskType: cleanTaskType,
      activationReportPath:
          'tracking/conversation_draft/$runId.activation_report.json',
      activationReport: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(bridge['activation_report']),
      ),
      sessionContextMarkdown: ValueReaders.stringValue(
        bridge['activation_context_markdown'],
      ),
      exposedToolIds: _conversationExposedToolIds(
        cleanTaskType,
        ValueReaders.stringList(bridge['workflow_tool_ids']),
      ),
    );
  }

  List<String> _conversationExposedToolIds(
    String taskType,
    List<String> toolIds,
  ) {
    if (!_requiresFormalChapterDelivery(taskType)) {
      return toolIds;
    }
    return toolIds
        .where(
          (toolId) => !const <String>{
            'set_agent_tasks',
            'call_sub_agent',
          }.contains(toolId),
        )
        .toList(growable: false);
  }

  Future<ProjectConversationDraftRuntimeArtifacts> finalizeDraftRun({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String title,
    String fallbackSavedPath = '',
  }) async {
    final changedPaths = <String>[];
    if (preparation.activationReport.isNotEmpty) {
      await _taskRepository.saveRecord(
        project,
        preparation.activationReportPath,
        preparation.activationReport,
      );
      changedPaths.add(preparation.activationReportPath);
    }

    var delivery = _workflowRuntimeBridgeService.latestChapterDeliveryOutcome(
      result.executedTools,
    );
    if (_shouldEnsureChapterDelivery(
          preparation: preparation,
          result: result,
          fallbackSavedPath: fallbackSavedPath,
        ) &&
        (delivery.isEmpty || _needsSupplementalChapterDelivery(delivery))) {
      final ensured = await _ensureChapterDelivery(
        project: project,
        preparation: preparation,
        result: result,
        title: title,
        fallbackSavedPath: fallbackSavedPath,
      );
      delivery = ensured.delivery;
      for (final path in ensured.changedPaths) {
        if (!changedPaths.contains(path)) {
          changedPaths.add(path);
        }
      }
    }

    final outputPath = _resolveOutputPath(
      result: result,
      fallbackSavedPath: fallbackSavedPath,
      delivery: delivery,
    );
    _ensureFormalChapterCompletion(
      preparation: preparation,
      result: result,
      outputPath: outputPath,
      delivery: delivery,
    );
    return ProjectConversationDraftRuntimeArtifacts(
      outputPath: outputPath,
      activationReportPath: preparation.activationReportPath,
      activationReportSummary: ValueReaders.stringValue(
        preparation.activationReport['summary'],
      ),
      chapterDelivery: delivery,
      changedPaths: List<String>.unmodifiable(changedPaths),
    );
  }

  bool _shouldEnsureChapterDelivery({
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String fallbackSavedPath,
  }) {
    if (preparation.taskType != 'chapter' && preparation.taskType != 'revision') {
      return false;
    }
    if (result.cancelledByUser || result.waitingForUserChoice) {
      return false;
    }
    final recoverableInvalidDelivery =
        _hasRecoverableInvalidChapterDeliveryAttempt(result);
    if (result.stoppedByToolError && !recoverableInvalidDelivery) {
      return false;
    }
    final candidatePath = _chapterPathCandidate(
      result: result,
      fallbackSavedPath: fallbackSavedPath,
    );
    return candidatePath.isNotEmpty;
  }

  bool _needsSupplementalChapterDelivery(JsonMap delivery) {
    if (delivery.isEmpty) {
      return true;
    }
    final stateResult = ValueReaders.mapValue(delivery['state_result']);
    final chapterBodyDelivered = ValueReaders.boolValue(
      stateResult['chapter_body_delivered'],
    );
    final submissionAccepted = ValueReaders.boolValue(
      stateResult['submission_accepted'],
    );
    final sidecarState = ValueReaders.stringValue(delivery['sidecar_state']).trim();
    if (!chapterBodyDelivered) {
      return false;
    }
    if (!submissionAccepted) {
      return true;
    }
    return sidecarState == 'missing' || sidecarState == 'repair_required';
  }

  Future<_EnsuredConversationChapterDelivery> _ensureChapterDelivery({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String title,
    required String fallbackSavedPath,
  }) async {
    final chapterPath = _chapterPathCandidate(
      result: result,
      fallbackSavedPath: fallbackSavedPath,
    );
    if (chapterPath.isEmpty) {
      throw StateError('普通会话章节生成缺少可交付的 chapter_path。');
    }
    final chapterContent = await _chapterContentCandidate(
      project: project,
      result: result,
      chapterPath: chapterPath,
      fallbackSavedPath: fallbackSavedPath,
    );
    if (chapterContent.trim().isEmpty) {
      throw StateError('普通会话章节生成缺少可交付正文，无法补交 submit_chapter_delivery。');
    }
    final request = DomainToolRequest(
      callId: 'conversation_delivery_${preparation.runId}',
      toolName: NarrativeDomainToolNames.submitChapterDelivery,
      source: const NarrativeSourceRef(
        sourceType: NarrativeSourceTypes.writer,
        sourceId: 'ordinary_conversation_runtime',
        label: 'ordinary_conversation_runtime',
      ),
      requestPayload: <String, Object?>{
        'chapter_path': chapterPath,
        'chapter_content': chapterContent,
        'title': title.trim(),
        'submission': _syntheticSubmission(
          preparation: preparation,
          chapterPath: chapterPath,
          title: title,
        ),
        'metadata': <String, Object?>{
          'runtime_source': 'ordinary_conversation_runtime',
          'activation_report_path': preparation.activationReportPath,
        },
      },
      schemaVersion: '1',
    );
    final outcome = await _narrativeDomainToolExecutor.execute(project, request);
    if (outcome.outcomeStatus != DomainToolOutcomeStatuses.accepted) {
      final message = ValueReaders.stringValue(
        outcome.error?.message,
        '普通会话章节交付失败。',
      );
      throw StateError(message);
    }
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(outcome.metadata['adapter_persistence']),
    );
    return _EnsuredConversationChapterDelivery(
      delivery: <String, Object?>{
        'tool_name': NarrativeDomainToolNames.submitChapterDelivery,
        'outcome_status': outcome.outcomeStatus,
        'delivery_id': ValueReaders.stringValue(payload['delivery_id']),
        'chapter_path': ValueReaders.stringValue(payload['chapter_path']),
        'delivery_state': ValueReaders.stringValue(payload['delivery_state']),
        'chapter_body_state': ValueReaders.stringValue(
          payload['chapter_body_state'],
        ),
        'sidecar_state': ValueReaders.stringValue(payload['sidecar_state']),
        'state_result': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(payload['state_result']),
        ),
      },
      changedPaths: ValueReaders.stringList(persistence['changed_paths']),
    );
  }

  JsonMap _syntheticSubmission({
    required ProjectConversationDraftRuntimePreparation preparation,
    required String chapterPath,
    required String title,
  }) {
    return <String, Object?>{
      'submission_id': 'conversation_submission_${preparation.runId}',
      'chapter_ref': <String, Object?>{
        'ref_type': NarrativeRefTypes.chapter,
        'ref_id': chapterPath,
        'relative_path': chapterPath,
      },
      'title': title.trim(),
      'summary': 'ordinary conversation chapter delivery',
      'metadata': <String, Object?>{
        'runtime_source': 'ordinary_conversation_runtime',
        'activation_report_path': preparation.activationReportPath,
      },
    };
  }

  String _resolveOutputPath({
    required DraftGenerationResult result,
    required String fallbackSavedPath,
    required JsonMap delivery,
  }) {
    final deliveryPath = ValueReaders.stringValue(delivery['chapter_path']).trim();
    if (deliveryPath.isNotEmpty) {
      return deliveryPath;
    }
    if (_isChapterPath(fallbackSavedPath)) {
      return fallbackSavedPath.trim();
    }
    for (final path in result.writtenPaths) {
      if (_isChapterPath(path)) {
        return path.trim();
      }
    }
    return fallbackSavedPath.trim();
  }

  void _ensureFormalChapterCompletion({
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String outputPath,
    required JsonMap delivery,
  }) {
    if (!_requiresFormalChapterDelivery(preparation.taskType)) {
      return;
    }
    if (result.cancelledByUser || result.waitingForUserChoice) {
      return;
    }
    if (outputPath.trim().isNotEmpty && delivery.isNotEmpty) {
      return;
    }
    throw StateError(_formalChapterDeliveryFailureMessage(result));
  }

  bool _requiresFormalChapterDelivery(String taskType) {
    return taskType == 'chapter' || taskType == 'revision';
  }

  String _formalChapterDeliveryFailureMessage(DraftGenerationResult result) {
    final toolNames = _distinctToolNames(result.executedTools);
    final trace = toolNames.isEmpty ? '无工具调用' : toolNames.join('、');
    final onlyPlanOrDelegation = toolNames.isNotEmpty &&
        toolNames.every(_isNonDeliveringConversationTool);
    if (onlyPlanOrDelegation) {
      return '普通会话正式章节任务未形成正式交付：本轮只执行了计划/委派/读取类工具（$trace），没有写出章节正文，也没有 submit_chapter_delivery。';
    }
    return '普通会话正式章节任务未形成正式交付：缺少章节正文输出或 submit_chapter_delivery。当前工具轨迹：$trace';
  }

  List<String> _distinctToolNames(List<Object?> executedTools) {
    final names = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isEmpty || names.contains(name)) {
        continue;
      }
      names.add(name);
    }
    return names;
  }

  bool _isNonDeliveringConversationTool(String toolName) {
    return const <String>{
      'set_agent_tasks',
      'call_sub_agent',
      'load_agent_skill',
      'read_project_file',
      'get_project_file_info',
      'list_project_files',
      'search_project_files',
    }.contains(toolName);
  }

  String _chapterPathCandidate({
    required DraftGenerationResult result,
    required String fallbackSavedPath,
  }) {
    if (_isChapterPath(fallbackSavedPath)) {
      return fallbackSavedPath.trim();
    }
    for (final path in result.writtenPaths.reversed) {
      if (_isChapterPath(path)) {
        return path.trim();
      }
    }
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']);
      if (toolName != 'write_project_file') {
        continue;
      }
      final resultJson = ValueReaders.mapValue(tool['result']);
      final relativePath = ValueReaders.stringValue(resultJson['relative_path']);
      if (_isChapterPath(relativePath)) {
        return relativePath.trim();
      }
    }
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']);
      if (toolName != NarrativeDomainToolNames.submitChapterDelivery) {
        continue;
      }
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final path = ValueReaders.stringValue(
        arguments['chapter_path'],
        ValueReaders.stringValue(
          arguments['relative_path'],
          ValueReaders.stringValue(arguments['output_relative_path']),
        ),
      ).trim();
      if (_isChapterPath(path)) {
        return path;
      }
    }
    return '';
  }

  Future<String> _chapterContentCandidate({
    required ProjectDescriptor project,
    required DraftGenerationResult result,
    required String chapterPath,
    required String fallbackSavedPath,
  }) async {
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']);
      if (toolName != 'write_project_file') {
        continue;
      }
      final resultJson = ValueReaders.mapValue(tool['result']);
      final relativePath = ValueReaders.stringValue(resultJson['relative_path']);
      if (relativePath.trim() != chapterPath) {
        continue;
      }
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final content = ValueReaders.stringValue(arguments['content']);
      if (content.trim().isNotEmpty) {
        return content;
      }
    }
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']);
      if (toolName != NarrativeDomainToolNames.submitChapterDelivery) {
        continue;
      }
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final content = ValueReaders.stringValue(
        arguments['chapter_content'],
        ValueReaders.stringValue(
          arguments['content'],
          ValueReaders.stringValue(arguments['body']),
        ),
      );
      if (content.trim().isNotEmpty) {
        return content;
      }
    }
    if (fallbackSavedPath.trim() == chapterPath &&
        result.draftMarkdown.trim().isNotEmpty) {
      return result.draftMarkdown;
    }
    final persisted = await _workspacePort.readTextFile(project.rootPath, chapterPath);
    return persisted ?? '';
  }

  bool _hasRecoverableInvalidChapterDeliveryAttempt(
    DraftGenerationResult result,
  ) {
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) !=
          NarrativeDomainToolNames.submitChapterDelivery) {
        continue;
      }
      final resultJson = ValueReaders.mapValue(tool['result']);
      final isInvalidPayload =
          !ValueReaders.boolValue(resultJson['ok'], true) &&
          ValueReaders.stringValue(
            resultJson['error'],
            ValueReaders.stringValue(resultJson['tool_result_summary']),
          ).contains('参数不合法');
      if (!isInvalidPayload) {
        continue;
      }
      final arguments = ValueReaders.mapValue(tool['arguments']);
      final chapterPath = ValueReaders.stringValue(
        arguments['chapter_path'],
        ValueReaders.stringValue(
          arguments['relative_path'],
          ValueReaders.stringValue(arguments['output_relative_path']),
        ),
      ).trim();
      final chapterContent = ValueReaders.stringValue(
        arguments['chapter_content'],
        ValueReaders.stringValue(
          arguments['content'],
          ValueReaders.stringValue(arguments['body']),
        ),
      );
      if (_isChapterPath(chapterPath) && chapterContent.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isChapterPath(String path) {
    final normalized = path.replaceAll('\\', '/').trim().toLowerCase();
    return normalized.startsWith('chapters/');
  }

  String _buildRunId(String taskType) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final safeTaskType = taskType.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safeTaskType.isEmpty ? 'chapter' : safeTaskType}_$timestamp';
  }
}

class _EnsuredConversationChapterDelivery {
  const _EnsuredConversationChapterDelivery({
    required this.delivery,
    required this.changedPaths,
  });

  final JsonMap delivery;
  final List<String> changedPaths;
}
