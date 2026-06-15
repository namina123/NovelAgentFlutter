import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';
import '../tools/project_narrative_domain_tool_executor.dart';
import 'chapter_delivery_outcome_projection_service.dart';
import 'project_chapter_label_hint_service.dart';
import 'project_chaptered_writing_task_service.dart';
import 'project_context_activation_service.dart';
import 'project_draft_execution_constraint_runtime_service.dart';
import 'project_writing_execution_contract_service.dart';
import 'project_workflow_runtime_bridge_service.dart';

class ProjectConversationDraftRuntimePreparation {
  const ProjectConversationDraftRuntimePreparation({
    required this.runId,
    required this.taskType,
    required this.activationReportPath,
    required this.activationReport,
    required this.sessionContextMarkdown,
    required this.exposedToolIds,
    this.executionConstraints = const <String, Object?>{},
  });

  final String runId;
  final String taskType;
  final String activationReportPath;
  final JsonMap activationReport;
  final String sessionContextMarkdown;
  final List<String> exposedToolIds;
  final JsonMap executionConstraints;
}

class ProjectConversationDraftRuntimeArtifacts {
  const ProjectConversationDraftRuntimeArtifacts({
    this.outputPath = '',
    this.activationReportPath = '',
    this.activationReportSummary = '',
    this.chapterDelivery = const <String, Object?>{},
    this.writingExecutionResult = const <String, Object?>{},
    this.informationStatus = '',
    this.informationSummary = '',
    this.informationChangedPaths = const <String>[],
    this.changedPaths = const <String>[],
  });

  final String outputPath;
  final String activationReportPath;
  final String activationReportSummary;
  final JsonMap chapterDelivery;
  final JsonMap writingExecutionResult;
  final String informationStatus;
  final String informationSummary;
  final List<String> informationChangedPaths;
  final List<String> changedPaths;
}

class ProjectConversationDraftRuntimeService {
  static const Set<String> _conversationBlockedToolIds = <String>{
    'set_agent_tasks',
  };

  ProjectConversationDraftRuntimeService({
    required ProjectWorkspacePort workspacePort,
    required ProjectToolHostPort hostPort,
    ProjectTaskRepository? taskRepository,
    ProjectWorkflowRuntimeBridgeService? workflowRuntimeBridgeService,
    ProjectNarrativeDomainToolExecutor? narrativeDomainToolExecutor,
    WritingExecutionResultNormalizerService? writingExecutionResultNormalizer,
    ChapterDeliveryOutcomeProjectionService? chapterDeliveryOutcomeProjection,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    ProjectWritingExecutionContractService? writingExecutionContractService,
    ExpressionConstraintSurfaceRiskScanService?
    expressionConstraintSurfaceRiskScanService,
    ChapterLengthMeasurementService? chapterLengthMeasurementService,
    ProjectChapterLabelHintService? chapterLabelHintService,
    ProjectChapteredWritingTaskService? chapteredWritingTaskService,
    AgentGroupDelegationCapabilityService?
    agentGroupDelegationCapabilityService,
  }) : _workspacePort = workspacePort,
       _taskRepository =
           taskRepository ??
           ProjectTaskRepository(workspacePort: workspacePort),
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
           ),
       _chapterDeliveryOutcomeProjection =
           chapterDeliveryOutcomeProjection ??
           const ChapterDeliveryOutcomeProjectionService(),
       _draftExecutionConstraintRuntimeService =
           draftExecutionConstraintRuntimeService ??
           ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
             workspacePort: workspacePort,
           ),
       _writingExecutionResultNormalizer =
           writingExecutionResultNormalizer ??
           WritingExecutionResultNormalizerService(),
       _writingExecutionContractService =
           writingExecutionContractService ??
           const ProjectWritingExecutionContractService(),
       _expressionConstraintSurfaceRiskScanService =
           expressionConstraintSurfaceRiskScanService ??
           const ExpressionConstraintSurfaceRiskScanService(),
       _chapterLengthMeasurementService =
           chapterLengthMeasurementService ??
           const ChapterLengthMeasurementService(),
       _chapterLabelHintService =
           chapterLabelHintService ?? const ProjectChapterLabelHintService(),
       _chapteredWritingTaskService =
           chapteredWritingTaskService ??
           const ProjectChapteredWritingTaskService(),
       _agentGroupDelegationCapabilityService =
           agentGroupDelegationCapabilityService ??
           const AgentGroupDelegationCapabilityService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectTaskRepository _taskRepository;
  final ProjectWorkflowRuntimeBridgeService _workflowRuntimeBridgeService;
  final ProjectNarrativeDomainToolExecutor _narrativeDomainToolExecutor;
  final ChapterDeliveryOutcomeProjectionService
  _chapterDeliveryOutcomeProjection;
  final ProjectDraftExecutionConstraintRuntimeService
  _draftExecutionConstraintRuntimeService;
  final WritingExecutionResultNormalizerService
  _writingExecutionResultNormalizer;
  final ProjectWritingExecutionContractService _writingExecutionContractService;
  final ExpressionConstraintSurfaceRiskScanService
  _expressionConstraintSurfaceRiskScanService;
  final ChapterLengthMeasurementService _chapterLengthMeasurementService;
  final ProjectChapterLabelHintService _chapterLabelHintService;
  final ProjectChapteredWritingTaskService _chapteredWritingTaskService;
  final AgentGroupDelegationCapabilityService
  _agentGroupDelegationCapabilityService;

  Future<ProjectConversationDraftRuntimePreparation> prepareDraftRun(
    ProjectDescriptor project, {
    required String taskType,
    List<String> pinnedRelativePaths = const <String>[],
    String chapterLabelHint = '',
    String activeDocumentPath = '',
    String agentId = '',
    String modeId = '',
    String stageId = '',
    String intent = '',
    String phase = '',
    String expressionConstraintPolicyMode = '',
    String expressionConstraintInjectionMode = '',
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
  }) async {
    final cleanTaskType = taskType.trim().isEmpty ? 'chapter' : taskType.trim();
    final runtimeTaskContext = _runtimeTaskContextForTaskType(
      cleanTaskType,
      stageOverride: stageId,
      intentOverride: intent,
      phaseOverride: phase,
    );
    final runId = _buildRunId(cleanTaskType);
    final chapterLabel = _chapterLabelHintService.resolve(
      chapterLabelHint: chapterLabelHint,
      activeDocumentPath: activeDocumentPath,
      pinnedRelativePaths: pinnedRelativePaths,
    );
    final executionConstraints = await _draftExecutionConstraintRuntimeService
        .resolve(
          project,
          appliesTo: runtimeTaskContext.appliesTo,
          agentId: agentId,
          modeId: modeId,
          stageId: runtimeTaskContext.stageId,
          intent: runtimeTaskContext.intent,
          taskType: cleanTaskType,
          phase: runtimeTaskContext.phase,
          expressionConstraintPolicyMode: expressionConstraintPolicyMode,
          expressionConstraintInjectionMode: expressionConstraintInjectionMode,
        );
    final bridge = await _workflowRuntimeBridgeService.buildTaskBridge(
      project,
      <String, Object?>{
        'task_type': cleanTaskType,
        'chapter': chapterLabel,
        'metadata': <String, Object?>{
          'persistent_context_paths': pinnedRelativePaths,
        },
      },
    );
    return ProjectConversationDraftRuntimePreparation(
      runId: runId,
      taskType: cleanTaskType,
      activationReportPath:
          'tracking/conversation_draft/$runId.activation_report.json',
      activationReport: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(bridge['activation_report']),
      ),
      sessionContextMarkdown: _mergeSessionContext(
        ValueReaders.stringValue(bridge['activation_context_markdown']),
        ValueReaders.stringValue(
          executionConstraints['session_context_markdown'],
        ),
      ),
      exposedToolIds: _conversationExposedToolIds(
        cleanTaskType,
        ValueReaders.stringList(bridge['workflow_tool_ids']),
        selectedCollaborationGroup: selectedCollaborationGroup,
      ),
      executionConstraints: ValueReaders.deepCopyMap(executionConstraints),
    );
  }

  List<String> _conversationExposedToolIds(
    String taskType,
    List<String> toolIds, {
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
  }) {
    final blockedToolIds = <String>{..._conversationBlockedToolIds};
    if (selectedCollaborationGroup.isNotEmpty &&
        !_agentGroupDelegationCapabilityService.supportsChildDelegation(
          selectedCollaborationGroup,
        )) {
      blockedToolIds.add('call_sub_agent');
    }
    return List<String>.unmodifiable(
      toolIds
          .where((toolId) => !blockedToolIds.contains(toolId))
          .toList(growable: false),
    );
  }

  Future<ProjectConversationDraftRuntimeArtifacts> finalizeDraftRun({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String title,
    String fallbackSavedPath = '',
  }) async {
    final changedPaths = <String>[];
    _appendChangedPaths(changedPaths, result.changedPaths);
    _appendChangedPaths(changedPaths, _toolChangedPaths(result.executedTools));
    final informationSummary = _informationExecutionSummary(
      result.executedTools,
    );
    _appendChangedPaths(changedPaths, informationSummary.changedPaths);
    if (preparation.activationReport.isNotEmpty) {
      await _taskRepository.saveRecord(
        project,
        preparation.activationReportPath,
        preparation.activationReport,
      );
      _appendChangedPaths(changedPaths, <String>[
        preparation.activationReportPath,
      ]);
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
      _appendChangedPaths(changedPaths, ensured.changedPaths);
    }

    final outputPath = _resolveOutputPath(
      result: result,
      fallbackSavedPath: fallbackSavedPath,
      delivery: delivery,
    );
    final expressionSurfaceReview = await _expressionSurfaceReview(
      project: project,
      preparation: preparation,
      result: result,
      delivery: delivery,
      outputPath: outputPath,
      fallbackSavedPath: fallbackSavedPath,
    );
    final writingExecutionResult = _buildWritingExecutionResult(
      preparation: preparation,
      result: result,
      delivery: delivery,
      informationSummary: informationSummary,
      expressionConstraintReview: expressionSurfaceReview,
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
      writingExecutionResult: writingExecutionResult,
      informationStatus: informationSummary.status,
      informationSummary: informationSummary.summary,
      informationChangedPaths: informationSummary.changedPaths,
      changedPaths: List<String>.unmodifiable(changedPaths),
    );
  }

  bool _shouldEnsureChapterDelivery({
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required String fallbackSavedPath,
  }) {
    final candidatePath = _chapterPathCandidate(
      result: result,
      fallbackSavedPath: fallbackSavedPath,
    );
    if (!_requiresFormalChapterDelivery(
      taskType: preparation.taskType,
      outputPath: candidatePath,
    )) {
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
    final sidecarState = ValueReaders.stringValue(
      delivery['sidecar_state'],
    ).trim();
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
    _assertChapterLengthWindow(
      preparation: preparation,
      chapterPath: chapterPath,
      chapterContent: chapterContent,
    );
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
          'chapter_length_metadata': ValueReaders.deepCopyMap(
            ValueReaders.mapValue(
              preparation.executionConstraints['chapter_length_metadata'],
            ),
          ),
        },
      },
      schemaVersion: '1',
    );
    final outcome = await _narrativeDomainToolExecutor.execute(
      project,
      request,
    );
    if (outcome.outcomeStatus != DomainToolOutcomeStatuses.accepted) {
      final message = ValueReaders.stringValue(
        outcome.error?.message,
        '普通会话章节交付失败。',
      );
      throw StateError(message);
    }
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(outcome.metadata['adapter_persistence']),
    );
    return _EnsuredConversationChapterDelivery(
      delivery: _chapterDeliveryOutcomeProjection.fromDomainOutcome(
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        outcome: outcome,
      ),
      changedPaths: ValueReaders.stringList(persistence['changed_paths']),
    );
  }

  JsonMap _syntheticSubmission({
    required ProjectConversationDraftRuntimePreparation preparation,
    required String chapterPath,
    required String title,
  }) {
    return <String, Object?>{
      'submission_id': 'submission:$chapterPath',
      'chapter_ref': <String, Object?>{
        'ref_type': NarrativeRefTypes.chapter,
        'ref_id': chapterPath,
        'relative_path': chapterPath,
      },
      'title': title.trim(),
      'summary': '',
      'metadata': <String, Object?>{
        'runtime_source': 'ordinary_conversation_runtime',
        'activation_report_path': preparation.activationReportPath,
      },
    };
  }

  void _assertChapterLengthWindow({
    required ProjectConversationDraftRuntimePreparation preparation,
    required String chapterPath,
    required String chapterContent,
  }) {
    final profile = ValueReaders.mapValue(
      ValueReaders.mapValue(
        ValueReaders.mapValue(
          preparation.executionConstraints['chapter_length_metadata'],
        )['chapter_length_profile'],
      ),
    );
    if (profile.isEmpty) {
      return;
    }
    final min = ValueReaders.intValue(profile['preferred_min']);
    final max = ValueReaders.intValue(profile['preferred_max']);
    if (min <= 0 && max <= 0) {
      return;
    }
    final measuredLength = _chapterLengthMeasurementService
        .measureVisibleCharacters(chapterContent);
    if (min > 0 && measuredLength < min) {
      throw StateError(
        '普通会话正式章节交付未通过字数 gate：$chapterPath 实际长度 $measuredLength，低于最小要求 $min。',
      );
    }
    if (max > 0 && measuredLength > max) {
      throw StateError(
        '普通会话正式章节交付未通过字数 gate：$chapterPath 实际长度 $measuredLength，高于最大要求 $max。',
      );
    }
  }

  String _resolveOutputPath({
    required DraftGenerationResult result,
    required String fallbackSavedPath,
    required JsonMap delivery,
  }) {
    final deliveryPath = _persistedChapterPathFromDelivery(delivery);
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
    if (!_requiresFormalChapterDelivery(
      taskType: preparation.taskType,
      outputPath: outputPath,
    )) {
      return;
    }
    if (result.cancelledByUser || result.waitingForUserChoice) {
      return;
    }
    if (_persistedChapterPathFromDelivery(delivery).isNotEmpty) {
      return;
    }
    if (result.stoppedByToolError && _hasFailedChapterDeliveryAttempt(result)) {
      return;
    }
    throw StateError(_formalChapterDeliveryFailureMessage(result));
  }

  bool _requiresFormalChapterDelivery({
    required String taskType,
    String outputPath = '',
  }) {
    return _chapteredWritingTaskService.requiresFormalChapterDelivery(
      taskType: taskType,
      outputPath: outputPath,
    );
  }

  String _formalChapterDeliveryFailureMessage(DraftGenerationResult result) {
    final toolNames = _distinctToolNames(result.executedTools);
    final trace = toolNames.isEmpty ? '无工具调用' : toolNames.join('、');
    final onlyPlanOrDelegation =
        toolNames.isNotEmpty &&
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

  List<String> _toolChangedPaths(List<Object?> executedTools) {
    final changedPaths = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      _appendChangedPaths(
        changedPaths,
        ValueReaders.stringList(result['changed_paths']),
      );
      final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
      final persistence = ValueReaders.mapValue(
        ValueReaders.mapValue(domainOutcome['metadata'])['adapter_persistence'],
      );
      _appendChangedPaths(
        changedPaths,
        ValueReaders.stringList(persistence['changed_paths']),
      );
      final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
      final researchExecution = ValueReaders.mapValue(
        payload['research_execution'],
      );
      _appendChangedPaths(
        changedPaths,
        ValueReaders.stringList(researchExecution['changed_paths']),
      );
    }
    return List<String>.unmodifiable(changedPaths);
  }

  _ConversationInformationSummary _informationExecutionSummary(
    List<Object?> executedTools,
  ) {
    final changedPaths = <String>[];
    var executedResearch = false;
    var waitingConfirmation = false;
    var sourceInsufficient = false;
    var blocked = false;
    var pendingResearchCount = 0;
    var awaitingConfirmationCount = 0;
    var rigorousSourceInsufficientCount = 0;
    var blockedResearchCount = 0;
    final executedSummaries = <String>[];
    final waitingSummaries = <String>[];
    final insufficientSummaries = <String>[];
    final blockedSummaries = <String>[];

    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final toolName = ValueReaders.stringValue(tool['name']).trim();
      final result = ValueReaders.mapValue(tool['result']);
      final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
      final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
      final researchExecution = ValueReaders.mapValue(
        payload['research_execution'],
      );
      _appendChangedPaths(
        changedPaths,
        _informationChangedPathsForResult(result),
      );

      if (toolName != NarrativeDomainToolNames.requestExternalResearch) {
        continue;
      }

      final executedNetwork =
          ValueReaders.boolValue(payload['network_execution_performed']) ||
          ValueReaders.boolValue(researchExecution['executed_network']);
      final executedImport =
          ValueReaders.boolValue(payload['import_execution_performed']) ||
          ValueReaders.boolValue(researchExecution['executed_import']);
      final awaitUserConfirmation =
          ValueReaders.boolValue(payload['requires_user_confirmation']) ||
          ValueReaders.boolValue(researchExecution['await_user_confirmation']);
      final executionBlocked = ValueReaders.boolValue(
        researchExecution['blocked'],
      );
      final executionSummary = ValueReaders.stringValue(
        payload['research_execution_summary'],
        ValueReaders.stringValue(
          researchExecution['summary'],
          ValueReaders.stringValue(result['tool_result_summary']),
        ),
      ).trim();
      final sourceQualitySummary = ValueReaders.mapValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(
            researchExecution['gateway_summary'],
          )['source_quality_summary'],
        ),
      );
      final rigorousRequired = ValueReaders.boolValue(
        sourceQualitySummary['requires_rigorous_sources'],
      );
      final meetsRequirement = ValueReaders.boolValue(
        sourceQualitySummary['meets_source_requirement'],
        true,
      );

      if (executedNetwork || executedImport) {
        executedResearch = true;
        if (executionSummary.isNotEmpty) {
          executedSummaries.add(executionSummary);
        }
      }
      if (awaitUserConfirmation) {
        waitingConfirmation = true;
        awaitingConfirmationCount += 1;
        if (executionSummary.isNotEmpty) {
          waitingSummaries.add(executionSummary);
        }
      }
      if (executionBlocked) {
        blocked = true;
        blockedResearchCount += 1;
        if (executionSummary.isNotEmpty) {
          blockedSummaries.add(executionSummary);
        }
      }
      if (rigorousRequired && !meetsRequirement) {
        sourceInsufficient = true;
        rigorousSourceInsufficientCount += 1;
        if (executionSummary.isNotEmpty) {
          insufficientSummaries.add(executionSummary);
        }
      }
      if (!executedNetwork &&
          !executedImport &&
          !awaitUserConfirmation &&
          !executionBlocked) {
        pendingResearchCount += 1;
      }
    }

    final normalizedChangedPaths = List<String>.unmodifiable(changedPaths);
    final changedCount = normalizedChangedPaths.length;
    if (waitingConfirmation) {
      return _ConversationInformationSummary(
        status: 'waiting_confirmation',
        reason: 'information_awaiting_confirmation',
        summary: _firstNonEmpty(waitingSummaries) ?? '已登记待研究请求，等待用户确认。',
        changedPaths: normalizedChangedPaths,
        awaitingConfirmationCount: awaitingConfirmationCount,
        pendingResearchCount: pendingResearchCount,
        blockedResearchCount: blockedResearchCount,
        rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      );
    }
    if (sourceInsufficient) {
      final base = _firstNonEmpty(insufficientSummaries) ?? '已执行资料研究，但严谨来源不足。';
      return _ConversationInformationSummary(
        status: 'source_insufficient',
        reason: 'information_rigorous_source_insufficient',
        summary: changedCount > 0
            ? '$base information 改动 $changedCount 项。'
            : base,
        changedPaths: normalizedChangedPaths,
        awaitingConfirmationCount: awaitingConfirmationCount,
        pendingResearchCount: pendingResearchCount,
        blockedResearchCount: blockedResearchCount,
        rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      );
    }
    if (blocked) {
      return _ConversationInformationSummary(
        status: 'blocked',
        reason: 'information_gateway_failed',
        summary: _firstNonEmpty(blockedSummaries) ?? '已登记待研究请求，但当前无法执行。',
        changedPaths: normalizedChangedPaths,
        awaitingConfirmationCount: awaitingConfirmationCount,
        pendingResearchCount: pendingResearchCount,
        blockedResearchCount: blockedResearchCount,
        rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      );
    }
    if (executedResearch) {
      final base = _firstNonEmpty(executedSummaries) ?? '已执行资料研究。';
      return _ConversationInformationSummary(
        status: 'executed_research',
        reason: 'information_research_executed',
        summary: changedCount > 0
            ? '$base information 改动 $changedCount 项。'
            : base,
        changedPaths: normalizedChangedPaths,
        awaitingConfirmationCount: awaitingConfirmationCount,
        pendingResearchCount: pendingResearchCount,
        blockedResearchCount: blockedResearchCount,
        rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      );
    }
    if (normalizedChangedPaths.isNotEmpty) {
      return _ConversationInformationSummary(
        status: 'information_changed',
        reason: 'information_changed',
        summary: '已更新资料，information 改动 $changedCount 项。',
        changedPaths: normalizedChangedPaths,
        awaitingConfirmationCount: awaitingConfirmationCount,
        pendingResearchCount: pendingResearchCount,
        blockedResearchCount: blockedResearchCount,
        rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      );
    }
    return _ConversationInformationSummary(
      status: 'no_information_change',
      reason: '',
      summary: '无 information 变更。',
      pendingResearchCount: pendingResearchCount,
      awaitingConfirmationCount: awaitingConfirmationCount,
      blockedResearchCount: blockedResearchCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
    );
  }

  Future<ExpressionConstraintReviewProjection> _expressionSurfaceReview({
    required ProjectDescriptor project,
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required JsonMap delivery,
    required String outputPath,
    required String fallbackSavedPath,
  }) async {
    final executionConstraints = preparation.executionConstraints;
    if (executionConstraints.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    final bridge = WritingExecutionConstraintBridgeResult.fromJson(
      executionConstraints,
    );
    if (!bridge.expressionConstraintApplied ||
        bridge.projectExpressionConstraintBindings.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    final chapterPath = outputPath.trim().isNotEmpty
        ? outputPath.trim()
        : _chapterPathCandidate(
            result: result,
            fallbackSavedPath: fallbackSavedPath,
          );
    if (chapterPath.isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    final chapterContent = await _safeChapterContentCandidate(
      project: project,
      result: result,
      delivery: delivery,
      chapterPath: chapterPath,
      fallbackSavedPath: fallbackSavedPath,
    );
    if (chapterContent.trim().isEmpty) {
      return const ExpressionConstraintReviewProjection();
    }
    return _expressionConstraintSurfaceRiskScanService.scan(
      profiles: bridge.expressionConstraintProfiles,
      bindings: bridge.projectExpressionConstraintBindings,
      texts: <String>[chapterContent],
    );
  }

  Future<String> _safeChapterContentCandidate({
    required ProjectDescriptor project,
    required DraftGenerationResult result,
    required JsonMap delivery,
    required String chapterPath,
    required String fallbackSavedPath,
  }) async {
    final persisted = await _workspacePort.readTextFile(
      project.rootPath,
      chapterPath,
    );
    if ((persisted ?? '').trim().isNotEmpty) {
      return persisted ?? '';
    }
    try {
      final content = await _chapterContentCandidate(
        project: project,
        result: result,
        chapterPath: chapterPath,
        fallbackSavedPath: fallbackSavedPath,
      );
      if (content.trim().isNotEmpty) {
        return content;
      }
    } catch (_) {
      // 中文注释: surface scan 是证据增强，不能让扫描失败覆盖正式交付结果。
    }
    return ValueReaders.stringValue(
      ValueReaders.mapValue(delivery['submission'])['chapter_content'],
    );
  }

  JsonMap _buildWritingExecutionResult({
    required ProjectConversationDraftRuntimePreparation preparation,
    required DraftGenerationResult result,
    required JsonMap delivery,
    required _ConversationInformationSummary informationSummary,
    ExpressionConstraintReviewProjection? expressionConstraintReview,
  }) {
    final executionConstraints = preparation.executionConstraints;
    final resultJson = _writingExecutionResultNormalizer
        .normalize(
          executionId: preparation.runId,
          workflowKind: _workflowKindForConversationTask(preparation.taskType),
          deliveryState: _writingExecutionContractService
              .chapterDeliveryStateFromDelivery(delivery: delivery),
          constraintBridgeResult: _writingExecutionContractService
              .constraintBridgeResult(executionConstraints),
          expressionConstraintReview: expressionConstraintReview,
          activationReport: _writingExecutionContractService
              .activationReportFromJson(preparation.activationReport),
          informationSignal: _informationSignalForConversation(
            informationSummary,
          ),
          recoveryPlan: _conversationRecoveryPlan(
            result: result,
            informationSummary: informationSummary,
          ),
          metadata: <String, Object?>{
            'task_type': preparation.taskType,
            'activation_report_path': preparation.activationReportPath,
            'expression_constraint_policy_mode': ValueReaders.stringValue(
              executionConstraints['expression_constraint_policy_mode'],
            ),
          },
        )
        .toJson();
    return _writingExecutionContractService.attachDerivedProjections(
      resultJson,
    );
  }

  String _runtimeStageIdForTaskType(String taskType, {String override = ''}) {
    final cleanOverride = override.trim();
    if (cleanOverride.isNotEmpty) {
      return cleanOverride;
    }
    return switch (taskType.trim()) {
      'revision' => 'revision',
      'review' => 'review',
      'planning' => 'planning',
      _ => 'draft',
    };
  }

  String _runtimeIntentForTaskType(String taskType, {String override = ''}) {
    final cleanOverride = override.trim();
    if (cleanOverride.isNotEmpty) {
      return cleanOverride;
    }
    return switch (taskType.trim()) {
      'revision' => 'revision',
      'review' => 'review',
      'planning' => 'planning',
      _ => 'draft',
    };
  }

  _ConversationRuntimeTaskContext _runtimeTaskContextForTaskType(
    String taskType, {
    String stageOverride = '',
    String intentOverride = '',
    String phaseOverride = '',
  }) {
    final normalizedTaskType = taskType.trim().toLowerCase();
    final baseStageId = _runtimeStageIdForTaskType(
      normalizedTaskType,
      override: stageOverride,
    );
    final baseIntent = _runtimeIntentForTaskType(
      normalizedTaskType,
      override: intentOverride,
    );
    final cleanPhaseOverride = phaseOverride.trim();

    if (_isResearchPriorityConversationTask(normalizedTaskType)) {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.explanation,
        intent: intentOverride.trim().isNotEmpty ? baseIntent : 'research',
        stageId: stageOverride.trim().isNotEmpty
            ? baseStageId
            : 'research_execution',
        phase: cleanPhaseOverride.isNotEmpty
            ? cleanPhaseOverride
            : 'research_execution',
      );
    }
    if (_isContinuationRevisionConversationTask(normalizedTaskType)) {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.repair,
        intent: baseIntent,
        stageId: baseStageId,
        phase: cleanPhaseOverride.isNotEmpty
            ? cleanPhaseOverride
            : 'continuation_revision',
      );
    }
    if (_isContinuationWritingConversationTask(normalizedTaskType)) {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.writing,
        intent: intentOverride.trim().isNotEmpty ? baseIntent : 'draft',
        stageId: stageOverride.trim().isNotEmpty
            ? baseStageId
            : 'chapter_write',
        phase: cleanPhaseOverride.isNotEmpty
            ? cleanPhaseOverride
            : 'continuation_write',
      );
    }
    if (_isSummaryOrExplainerConversationTask(normalizedTaskType)) {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.explanation,
        intent: intentOverride.trim().isNotEmpty ? baseIntent : 'summary',
        stageId: stageOverride.trim().isNotEmpty ? baseStageId : 'summary',
        phase: cleanPhaseOverride.isNotEmpty
            ? cleanPhaseOverride
            : 'explanation_summary',
      );
    }
    if (_isDeconstructionAnalysisConversationTask(normalizedTaskType)) {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.deconstruction,
        intent: intentOverride.trim().isNotEmpty
            ? baseIntent
            : 'deconstruction',
        stageId: stageOverride.trim().isNotEmpty ? baseStageId : 'analysis',
        phase: cleanPhaseOverride.isNotEmpty
            ? cleanPhaseOverride
            : 'deconstruction_analysis',
      );
    }
    if (normalizedTaskType == 'planning') {
      return _ConversationRuntimeTaskContext(
        appliesTo: ConstraintBindingAppliesTo.explanation,
        intent: baseIntent,
        stageId: baseStageId,
        phase: cleanPhaseOverride.isNotEmpty ? cleanPhaseOverride : 'planning',
      );
    }
    return _ConversationRuntimeTaskContext(
      appliesTo: normalizedTaskType == 'revision'
          ? ConstraintBindingAppliesTo.repair
          : ConstraintBindingAppliesTo.writing,
      intent: baseIntent,
      stageId: baseStageId,
      phase: cleanPhaseOverride,
    );
  }

  bool _isResearchPriorityConversationTask(String taskType) {
    return _hasResearchPriorityMarker(taskType) &&
        !_hasContinuationWritingMarker(taskType) &&
        !_isContinuationRevisionConversationTask(taskType);
  }

  bool _isContinuationRevisionConversationTask(String taskType) {
    return taskType == 'revision' ||
        ((taskType.contains('continuation') || taskType.contains('followup')) &&
            taskType.contains('revision'));
  }

  bool _isContinuationWritingConversationTask(String taskType) {
    if (_isContinuationRevisionConversationTask(taskType) ||
        _hasResearchPriorityMarker(taskType)) {
      return false;
    }
    return _hasContinuationWritingMarker(taskType);
  }

  bool _isSummaryOrExplainerConversationTask(String taskType) {
    if (_isResearchPriorityConversationTask(taskType) ||
        _isContinuationWritingConversationTask(taskType) ||
        _isContinuationRevisionConversationTask(taskType)) {
      return false;
    }
    return taskType.contains('summary') ||
        taskType.contains('explainer') ||
        taskType.contains('retelling');
  }

  bool _isDeconstructionAnalysisConversationTask(String taskType) {
    if (_isResearchPriorityConversationTask(taskType) ||
        _isContinuationWritingConversationTask(taskType) ||
        _isContinuationRevisionConversationTask(taskType) ||
        _isSummaryOrExplainerConversationTask(taskType)) {
      return false;
    }
    return taskType.contains('deconstruction') || taskType.contains('followup');
  }

  bool _hasResearchPriorityMarker(String taskType) {
    return taskType.contains('research') || taskType.contains('information');
  }

  bool _hasContinuationWritingMarker(String taskType) {
    return taskType.contains('continuation') ||
        taskType.contains('continue_write') ||
        taskType.contains('continuation_write') ||
        taskType.contains('followup_write');
  }

  String _mergeSessionContext(String base, String extra) {
    final parts = <String>[];
    final cleanBase = base.trim();
    final cleanExtra = extra.trim();
    if (cleanBase.isNotEmpty) {
      parts.add(cleanBase);
    }
    if (cleanExtra.isNotEmpty) {
      parts.add(cleanExtra);
    }
    return parts.join('\n\n');
  }

  String _workflowKindForConversationTask(String taskType) {
    final cleanTaskType = taskType.trim();
    if (cleanTaskType == 'chapter' || cleanTaskType == 'revision') {
      return 'ordinary_project';
    }
    if (cleanTaskType.contains('deconstruction') ||
        cleanTaskType.contains('followup') ||
        cleanTaskType.contains('continuation')) {
      return 'deconstruction_followup';
    }
    if (cleanTaskType.contains('explainer')) {
      return 'explainer_followup';
    }
    return cleanTaskType.isEmpty ? 'ordinary_project' : cleanTaskType;
  }

  JsonMap _informationSignalForConversation(
    _ConversationInformationSummary informationSummary,
  ) {
    final changedPaths = informationSummary.changedPaths;
    if (informationSummary.status == 'no_information_change' &&
        changedPaths.isEmpty) {
      return const <String, Object?>{};
    }
    final category = switch (informationSummary.status) {
      'waiting_confirmation' => 'checkpoint_user',
      'blocked' => 'repair',
      _ => 'accept',
    };
    return <String, Object?>{
      'present': true,
      'category': category,
      'reason': informationSummary.reason,
      'summary': informationSummary.summary,
      'changed_paths': changedPaths,
      'pending_research_count': informationSummary.pendingResearchCount,
      'awaiting_confirmation_count':
          informationSummary.awaitingConfirmationCount,
      'gateway_failure_count': informationSummary.blockedResearchCount,
      'rigorous_source_insufficient_count':
          informationSummary.rigorousSourceInsufficientCount,
      'waiting_user': informationSummary.status == 'waiting_confirmation',
      'requires_repair': informationSummary.status == 'blocked',
    };
  }

  JsonMap _conversationRecoveryPlan({
    required DraftGenerationResult result,
    required _ConversationInformationSummary informationSummary,
  }) {
    if (informationSummary.status == 'waiting_confirmation') {
      return <String, Object?>{
        'action': 'resume_when_user_confirms',
        'reason': informationSummary.reason,
        'note': informationSummary.summary,
      };
    }
    if (informationSummary.status == 'blocked') {
      return <String, Object?>{
        'action': 'pause_for_repair',
        'reason': informationSummary.reason,
        'note': informationSummary.summary,
      };
    }
    if (result.waitingForUserChoice) {
      return const <String, Object?>{
        'action': 'resume_when_user_confirms',
        'reason': 'ordinary_conversation_waiting_user_choice',
        'note': '普通会话当前停在用户选择点，确认后再继续。',
      };
    }
    return const <String, Object?>{};
  }

  List<String> _informationChangedPathsForResult(JsonMap result) {
    final changedPaths = <String>[];
    _appendChangedPaths(
      changedPaths,
      ValueReaders.stringList(result['changed_paths']),
    );
    final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(domainOutcome['metadata'])['adapter_persistence'],
    );
    _appendChangedPaths(
      changedPaths,
      ValueReaders.stringList(persistence['changed_paths']),
    );
    final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
    final researchExecution = ValueReaders.mapValue(
      payload['research_execution'],
    );
    _appendChangedPaths(
      changedPaths,
      ValueReaders.stringList(researchExecution['changed_paths']),
    );
    return changedPaths
        .where(_isInformationChangedPath)
        .toList(growable: false);
  }

  bool _isInformationChangedPath(String path) {
    final normalized = path.trim().replaceAll('\\', '/').toLowerCase();
    return normalized.startsWith('.novel_agent/information/') ||
        normalized.startsWith('knowledge/') ||
        normalized.startsWith('research/') ||
        normalized.startsWith('references/');
  }

  String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return null;
  }

  void _appendChangedPaths(List<String> target, Iterable<String> paths) {
    for (final rawPath in paths) {
      final path = rawPath.trim();
      if (path.isEmpty || target.contains(path)) {
        continue;
      }
      target.add(path);
    }
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
      final relativePath = ValueReaders.stringValue(
        resultJson['relative_path'],
      );
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

  String _persistedChapterPathFromDelivery(JsonMap delivery) {
    final chapterPath = ValueReaders.stringValue(
      delivery['chapter_path'],
    ).trim();
    if (!_isChapterPath(chapterPath)) {
      return '';
    }
    if (!_isPersistedDeliveryOutcome(
      ValueReaders.stringValue(delivery['outcome_status']),
    )) {
      return '';
    }
    final stateResult = ValueReaders.mapValue(delivery['state_result']);
    if (!ValueReaders.boolValue(stateResult['chapter_body_delivered'])) {
      return '';
    }
    return chapterPath;
  }

  bool _isPersistedDeliveryOutcome(String outcomeStatus) {
    return switch (outcomeStatus.trim()) {
      'accepted' || 'proposed' || 'needs_user_confirmation' => true,
      _ => false,
    };
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
      final relativePath = ValueReaders.stringValue(
        resultJson['relative_path'],
      );
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
    final persisted = await _workspacePort.readTextFile(
      project.rootPath,
      chapterPath,
    );
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

  bool _hasFailedChapterDeliveryAttempt(DraftGenerationResult result) {
    for (final rawTool in result.executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.stringValue(tool['name']) !=
              NarrativeDomainToolNames.submitChapterDelivery ||
          ValueReaders.boolValue(tool['ok'], true)) {
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
    final safeTaskType = taskType.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
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

class _ConversationRuntimeTaskContext {
  const _ConversationRuntimeTaskContext({
    required this.appliesTo,
    required this.intent,
    required this.stageId,
    required this.phase,
  });

  final String appliesTo;
  final String intent;
  final String stageId;
  final String phase;
}

class _ConversationInformationSummary {
  const _ConversationInformationSummary({
    required this.status,
    required this.reason,
    required this.summary,
    this.changedPaths = const <String>[],
    this.pendingResearchCount = 0,
    this.awaitingConfirmationCount = 0,
    this.blockedResearchCount = 0,
    this.rigorousSourceInsufficientCount = 0,
  });

  final String status;
  final String reason;
  final String summary;
  final List<String> changedPaths;
  final int pendingResearchCount;
  final int awaitingConfirmationCount;
  final int blockedResearchCount;
  final int rigorousSourceInsufficientCount;
}
