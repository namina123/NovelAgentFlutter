import 'package:novel_agent_core/novel_agent_core.dart';

import '../packages/local_skill_group_catalog.dart';
import '../packages/local_skill_package_catalog.dart';
import '../storage/project_tree_order_service.dart';
import '../workflow/project_workflow_runtime_service.dart';
import '../host/desktop_process_runner.dart';
import 'project_file_edit_tool_executor.dart';
import 'project_file_read_tool_executor.dart';
import 'project_file_write_tool_executor.dart';
import 'project_agent_skill_tool_executor.dart';
import 'project_agent_skill_runtime_loadout_service.dart';
import 'project_gateway_process_service.dart';
import 'project_gateway_tool_executor.dart';
import 'project_information_domain_tool_executor.dart';
import 'project_long_task_tool_executor.dart';
import 'project_management_tool_executor.dart';
import 'project_narrative_domain_tool_executor.dart';
import 'project_structured_memory_tool_executor.dart';
import 'project_task_tool_executor.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_relative_path_resolver.dart';
import 'project_tool_result_factory.dart';

class ProjectToolDispatcher implements ToolExecutionPort {
  ProjectToolDispatcher({
    required ProjectToolHostPort hostPort,
    HostInformationPermissionContext? hostInformationPermissionContext,
    ProjectInformationDomainToolExecutor? informationDomainToolExecutor,
    LocalSkillPackageCatalog? skillPackageCatalog,
    LocalSkillGroupCatalog? skillGroupCatalog,
    ToolCallNormalizerService? toolCallNormalizerService,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
    ProjectTreeOrderService? treeOrderService,
    BuildModeGuidancePlanInputUseCase? buildModeGuidancePlanInputUseCase,
    ProjectWorkflowRuntimeService? workflowRuntimeService,
    ProjectLongTaskToolExecutor? longTaskToolExecutor,
    ProjectAgentSkillRuntimeLoadoutService? agentSkillRuntimeLoadoutService,
  }) : _toolCallNormalizerService =
           toolCallNormalizerService ?? ToolCallNormalizerService(),
       _hostPort = hostPort,
       _skillPackageCatalog = skillPackageCatalog,
       _skillGroupCatalog = skillGroupCatalog,
       _pathPolicy = pathPolicy,
       _treeOrderService = treeOrderService,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _workflowRuntimeService = workflowRuntimeService,
       _agentSkillRuntimeLoadoutService = agentSkillRuntimeLoadoutService,
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _relativePathResolver = ProjectToolRelativePathResolver(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
       ),
       _readToolExecutor = ProjectFileReadToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _writeToolExecutor = ProjectFileWriteToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _editToolExecutor = ProjectFileEditToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _structuredMemoryToolExecutor = ProjectStructuredMemoryToolExecutor(
         hostPort: hostPort,
         writeToolExecutor: ProjectFileWriteToolExecutor(
           hostPort: hostPort,
           pathPolicy: pathPolicy,
           resultFactory: resultFactory,
         ),
         pathPolicy: pathPolicy,
       ),
       _taskToolExecutor = ProjectTaskToolExecutor(
         hostPort: hostPort,
         pathPolicy: pathPolicy,
         resultFactory: resultFactory,
       ),
       _managementToolExecutor = ProjectManagementToolExecutor(
         hostPort: hostPort,
         resultFactory: resultFactory,
         treeOrderService: treeOrderService,
         pathPolicy: pathPolicy,
         gatewayToolExecutor: ProjectGatewayToolExecutor(
           resultFactory: resultFactory,
           pathPolicy: pathPolicy,
           processService: ProjectGatewayProcessService(
             processRunner: DesktopProcessRunner(),
           ),
         ),
       ),
       _longTaskToolExecutor =
           longTaskToolExecutor ??
           (buildModeGuidancePlanInputUseCase != null &&
                   workflowRuntimeService != null
               ? ProjectLongTaskToolExecutor(
                   loadPlanInput: buildModeGuidancePlanInputUseCase.execute,
                   createLongTaskWorkflow:
                       workflowRuntimeService.createLongTaskWorkflow,
                   resultFactory: resultFactory,
                 )
               : null),
       _agentSkillToolExecutor = ProjectAgentSkillToolExecutor(
         skillPackageCatalog: skillPackageCatalog,
         skillGroupCatalog: skillGroupCatalog,
         resultFactory: resultFactory,
         runtimeLoadoutService: agentSkillRuntimeLoadoutService,
       ),
       _hostInformationPermissionContext = hostInformationPermissionContext,
       _narrativeDomainToolCatalog = NarrativeDomainToolCatalog(),
       _narrativeDomainDispatcher = _buildNarrativeDomainDispatcher(),
       _informationDomainDispatcher = _buildInformationDomainDispatcher(),
       _narrativeDomainToolExecutor = ProjectNarrativeDomainToolExecutor(
         workspacePort: _ProjectToolHostWorkspacePortAdapter(hostPort),
         hostPort: hostPort,
         dispatcher: _buildNarrativeDomainDispatcher(),
       ),
       _informationDomainToolExecutor =
           informationDomainToolExecutor ??
           ProjectInformationDomainToolExecutor(
             workspacePort: _ProjectToolHostWorkspacePortAdapter(hostPort),
             dispatcher: _buildInformationDomainDispatcher(),
           );

  final ToolCallNormalizerService _toolCallNormalizerService;
  final ProjectToolHostPort _hostPort;
  final LocalSkillPackageCatalog? _skillPackageCatalog;
  final LocalSkillGroupCatalog? _skillGroupCatalog;
  final ProjectToolPathPolicy? _pathPolicy;
  final ProjectTreeOrderService? _treeOrderService;
  final BuildModeGuidancePlanInputUseCase?
  _buildModeGuidancePlanInputUseCase;
  final ProjectWorkflowRuntimeService? _workflowRuntimeService;
  final ProjectAgentSkillRuntimeLoadoutService?
  _agentSkillRuntimeLoadoutService;
  final ProjectToolResultFactory _resultFactory;
  final ProjectToolRelativePathResolver _relativePathResolver;
  final ProjectFileReadToolExecutor _readToolExecutor;
  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectFileEditToolExecutor _editToolExecutor;
  final ProjectStructuredMemoryToolExecutor _structuredMemoryToolExecutor;
  final ProjectTaskToolExecutor _taskToolExecutor;
  final ProjectManagementToolExecutor _managementToolExecutor;
  final ProjectLongTaskToolExecutor? _longTaskToolExecutor;
  final ProjectAgentSkillToolExecutor _agentSkillToolExecutor;
  final HostInformationPermissionContext? _hostInformationPermissionContext;
  final NarrativeDomainToolCatalog _narrativeDomainToolCatalog;
  final NarrativeDomainToolDispatcher _narrativeDomainDispatcher;
  final NarrativeDomainToolDispatcher _informationDomainDispatcher;
  final ProjectNarrativeDomainToolExecutor _narrativeDomainToolExecutor;
  final ProjectInformationDomainToolExecutor _informationDomainToolExecutor;

  ProjectToolDispatcher scopedWithHostInformationPermissionContext(
    HostInformationPermissionContext? hostInformationPermissionContext,
  ) {
    return ProjectToolDispatcher(
      hostPort: _hostPort,
      hostInformationPermissionContext: hostInformationPermissionContext,
      informationDomainToolExecutor: _informationDomainToolExecutor,
      skillPackageCatalog: _skillPackageCatalog,
      skillGroupCatalog: _skillGroupCatalog,
      toolCallNormalizerService: _toolCallNormalizerService,
      pathPolicy: _pathPolicy,
      resultFactory: _resultFactory,
      treeOrderService: _treeOrderService,
      buildModeGuidancePlanInputUseCase:
          _buildModeGuidancePlanInputUseCase,
      workflowRuntimeService: _workflowRuntimeService,
      longTaskToolExecutor: _longTaskToolExecutor,
      agentSkillRuntimeLoadoutService: _agentSkillRuntimeLoadoutService,
    );
  }

  static NarrativeDomainToolDispatcher _buildNarrativeDomainDispatcher() {
    return NarrativeDomainToolDispatchService(
      handlers: <NarrativeDomainToolHandler>[
        SubmitChapterDeliveryHandler(),
        const SubmitNarrativeStateClaimsHandler(),
        const ProposeNarrativeProfileUpdateHandler(),
        const SubmitSemanticReviewHandler(),
        const ProposeConstraintBindingHandler(),
        const RequestProfileClarificationHandler(),
      ],
    );
  }

  static NarrativeDomainToolDispatcher _buildInformationDomainDispatcher() {
    return NarrativeDomainToolDispatchService(
      handlers: <NarrativeDomainToolHandler>[
        const RequestExternalResearchHandler(),
        const SubmitResearchNoteHandler(),
        const ProposeKnowledgeCardHandler(),
        const ProposeDesignElementHandler(),
        const LinkInformationEvidenceHandler(),
        const ProposeReferenceWorkHandler(),
      ],
    );
  }

  static const Set<String> _domainToolNames = <String>{
    NarrativeDomainToolNames.submitChapterDelivery,
    NarrativeDomainToolNames.submitNarrativeStateClaims,
    NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
    NarrativeDomainToolNames.submitSemanticReview,
    NarrativeDomainToolNames.proposeConstraintBinding,
    NarrativeDomainToolNames.requestProfileClarification,
    NarrativeDomainToolNames.requestExternalResearch,
    NarrativeDomainToolNames.submitResearchNote,
    NarrativeDomainToolNames.proposeKnowledgeCard,
    NarrativeDomainToolNames.proposeDesignElement,
    NarrativeDomainToolNames.linkInformationEvidence,
    NarrativeDomainToolNames.proposeReferenceWork,
  };

  static const Set<String> _lowLevelToolNames = <String>{
    'list_project_files',
    'read_project_file',
    'write_project_file',
    'edit_project_file',
    'delete_project_file',
    'get_project_file_info',
    'search_project_files',
    'create_project_entry',
    'move_project_file',
    'rename_project_file',
    'manipulate_project_file_lines',
    'list_history_sessions',
    'create_backup',
    'restore_backup',
  };

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 调度器负责把显示层/模型层传来的路径折叠为英文项目相对路径，后续执行器只吃规范参数。
    final normalized = _toolCallNormalizerService.normalizeToolCall(toolCall);
    final toolName = ValueReaders.stringValue(normalized['name']).trim();
    final arguments = await _normalizeArguments(
      project: project,
      toolName: toolName,
      arguments: ValueReaders.mapValue(normalized['arguments']),
    );
    if (_domainToolNames.contains(toolName)) {
      return _executeNarrativeDomainTool(
        project: project,
        rawToolCall: toolCall,
        normalizedToolCall: normalized,
        toolName: toolName,
        arguments: arguments,
      );
    }
    final result = await _executeProjectTool(
      project: project,
      toolName: toolName,
      arguments: arguments,
    );
    return _annotateToolResult(toolName, result);
  }

  Future<JsonMap> _executeProjectTool({
    required ProjectDescriptor project,
    required String toolName,
    required JsonMap arguments,
  }) async {
    switch (toolName) {
      case 'list_project_files':
        return _readToolExecutor.listProjectFiles(project, arguments);
      case 'read_project_file':
        return _readToolExecutor.readProjectFile(project, arguments);
      case 'write_project_file':
        return _writeToolExecutor.writeProjectFile(project, arguments);
      case 'edit_project_file':
        return _editToolExecutor.editProjectFile(project, arguments);
      case 'delete_project_file':
        return _writeToolExecutor.deleteProjectFile(project, arguments);
      case 'get_project_file_info':
        return _readToolExecutor.getProjectFileInfo(project, arguments);
      case 'search_project_files':
        return _readToolExecutor.searchProjectFiles(project, arguments);
      case 'create_project_entry':
        return _writeToolExecutor.createProjectEntry(project, arguments);
      case 'move_project_file':
        return _writeToolExecutor.moveProjectFile(project, arguments);
      case 'rename_project_file':
        return _writeToolExecutor.renameProjectFile(project, arguments);
      case 'manipulate_project_file_lines':
        return _editToolExecutor.manipulateProjectFileLines(project, arguments);
      case 'list_history_sessions':
        return _readToolExecutor.listHistorySessions(project, arguments);
      case 'create_backup':
        return _writeToolExecutor.createBackup(project, arguments);
      case 'restore_backup':
        return _writeToolExecutor.restoreBackup(project, arguments);
      case 'update_world_state':
        return _structuredMemoryToolExecutor.updateWorldState(
          project,
          arguments,
        );
      case 'update_character_state':
        return _structuredMemoryToolExecutor.updateCharacterState(
          project,
          arguments,
        );
      case 'update_foreshadow_state':
        return _structuredMemoryToolExecutor.updateForeshadowState(
          project,
          arguments,
        );
      case 'update_timeline_state':
        return _structuredMemoryToolExecutor.updateTimelineState(
          project,
          arguments,
        );
      case 'update_relationship_state':
        return _structuredMemoryToolExecutor.updateRelationshipState(
          project,
          arguments,
        );
      case 'summarize_context':
        return _structuredMemoryToolExecutor.summarizeContext(
          project,
          arguments,
        );
      case 'run_continuity_check':
        return _structuredMemoryToolExecutor.runContinuityCheck(
          project,
          arguments,
        );
      case 'create_chapter_task':
        return _taskToolExecutor.createChapterTask(project, arguments);
      case 'mark_task_status':
        return _taskToolExecutor.markTaskStatus(project, arguments);
      case 'present_user_options':
        return _presentUserOptions(arguments);
      case 'start_long_task_run':
        if (_longTaskToolExecutor == null) {
          return _resultFactory.notExecuted('当前宿主尚未接入长任务启动执行器。');
        }
        return _longTaskToolExecutor.startLongTaskRun(project, arguments);
      case 'set_agent_tasks':
        return _taskToolExecutor.setAgentTasks(project, arguments);
      case 'load_agent_skill':
        return _agentSkillToolExecutor.loadAgentSkill(project, arguments);
      case 'call_sub_agent':
        return _resultFactory.notExecuted(
          'call_sub_agent 由上层 ToolExecutionService 直接接管；当前分发器只保留兜底结果。',
        );
      case 'rename_project':
        return _managementToolExecutor.renameProject(project, arguments);
      case 'reorder_project_file':
        return _managementToolExecutor.reorderProjectFile(project, arguments);
      case 'request_gateway_tool':
        return _managementToolExecutor.requestGatewayTool(project, arguments);
      default:
        return _resultFactory.error('Unknown project tool: $toolName');
    }
  }

  Future<JsonMap> _normalizeArguments({
    required ProjectDescriptor project,
    required String toolName,
    required JsonMap arguments,
  }) async {
    // 中文注释: 中文目录名、显示名匹配和旧输入兼容只允许存在于这一层，避免渗透进核心与各执行器。
    final normalized = ValueReaders.deepCopyMap(arguments);
    switch (toolName) {
      case 'list_project_files':
      case 'search_project_files':
      case 'reorder_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveScopePath(project, normalized);
        return normalized;
      case 'read_project_file':
      case 'get_project_file_info':
      case 'delete_project_file':
      case 'create_backup':
      case 'edit_project_file':
      case 'rename_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        return normalized;
      case 'write_project_file':
      case 'create_project_entry':
        normalized['relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['relative_path']),
            );
        return normalized;
      case 'move_project_file':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        normalized['target_relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['target_relative_path']),
            );
        return normalized;
      case 'manipulate_project_file_lines':
        normalized['relative_path'] = await _relativePathResolver
            .resolveFilePath(project, normalized);
        normalized['target_relative_path'] = _relativePathResolver
            .normalizeProjectPath(
              ValueReaders.stringValue(normalized['target_relative_path']),
            );
        return normalized;
      case 'restore_backup':
        normalized['backup_path'] = await _relativePathResolver.resolveFilePath(
          project,
          <String, Object?>{'relative_path': normalized['backup_path']},
          allowSessions: true,
        );
        normalized['target_path'] = _relativePathResolver.normalizeProjectPath(
          ValueReaders.stringValue(normalized['target_path']),
        );
        return normalized;
      case 'request_gateway_tool':
        final nestedArguments = ValueReaders.mapValue(normalized['arguments']);
        final outputPath = ValueReaders.stringValue(
          normalized['relative_path'],
          ValueReaders.stringValue(
            normalized['output_relative_path'],
            ValueReaders.stringValue(
              nestedArguments['relative_path'],
              ValueReaders.stringValue(nestedArguments['output_relative_path']),
            ),
          ),
        );
        final normalizedOutputPath = _relativePathResolver.normalizeProjectPath(
          outputPath,
        );
        if (normalizedOutputPath.isNotEmpty) {
          normalized['relative_path'] = normalizedOutputPath;
          normalized['output_relative_path'] = normalizedOutputPath;
        }
        return normalized;
      case NarrativeDomainToolNames.submitChapterDelivery:
        normalized['chapter_path'] = _relativePathResolver.normalizeProjectPath(
          ValueReaders.stringValue(normalized['chapter_path']),
        );
        return normalized;
      default:
        return normalized;
    }
  }

  Future<JsonMap> _executeNarrativeDomainTool({
    required ProjectDescriptor project,
    required JsonMap rawToolCall,
    required JsonMap normalizedToolCall,
    required String toolName,
    required JsonMap arguments,
  }) async {
    final parseResult = _narrativeDomainToolCatalog.parseRequest(
      callId: ValueReaders.stringValue(normalizedToolCall['id']).trim(),
      toolName: toolName,
      source: _resolveDomainSource(toolName, rawToolCall, arguments),
      arguments: arguments,
      toolRoundEvidence: _readToolRoundEvidence(rawToolCall, arguments),
      schemaVersion: ValueReaders.stringValue(
        rawToolCall['schema_version'],
        ValueReaders.stringValue(arguments['schema_version']),
      ).trim(),
    );
    if (!parseResult.isSuccess) {
      final capability = _domainCapabilityFor(toolName);
      return <String, Object?>{
        'ok': false,
        'not_executed': true,
        'retryable': true,
        'error': '领域工具参数不合法。',
        'display_text': '领域工具参数不合法：${_domainDisplayName(toolName)}',
        'changed_paths': const <String>[],
        'interaction_type': 'domain_tool',
        'tool_layer': 'domain',
        'tool_capability': _toolCapability(
          toolName,
          toolLayer: 'domain',
          capabilityKind: 'narrative_domain_tool',
        ),
        'domain_tool_name': toolName,
        'domain_capability': capability?.toJson(),
        'domain_parse_issues': parseResult.issues
            .map(
              (issue) => <String, Object?>{
                'code': issue.code,
                'field_path': issue.fieldPath,
                'message': issue.message,
              },
            )
            .toList(growable: false),
        'tool_result_summary': '领域工具参数不合法，工具尚未执行；请根据 domain_parse_issues 修正参数后重试。',
      };
    }

    final outcome = await _executeDomainTool(project, parseResult.request!);
    final changedPaths = _domainChangedPaths(outcome);
    final waitingForUserChoice =
        outcome.outcomeStatus ==
        DomainToolOutcomeStatuses.needsUserConfirmation;
    final ok =
        outcome.outcomeStatus == DomainToolOutcomeStatuses.accepted ||
        outcome.outcomeStatus == DomainToolOutcomeStatuses.proposed ||
        waitingForUserChoice;
    final summary = _domainToolSummary(toolName, outcome, changedPaths);
    return <String, Object?>{
      'ok': ok,
      if (!ok)
        'error': ValueReaders.stringValue(outcome.error?.message, '领域工具执行失败。'),
      'display_text': summary,
      'changed_paths': changedPaths,
      'interaction_type': 'domain_tool',
      'tool_layer': 'domain',
      'tool_capability': _toolCapability(
        toolName,
        toolLayer: 'domain',
        capabilityKind: 'narrative_domain_tool',
      ),
      'domain_tool_name': toolName,
      'domain_capability': _domainCapabilityFor(toolName)?.toJson(),
      'domain_outcome_status': outcome.outcomeStatus,
      'domain_outcome': outcome.toJson(),
      'tool_result_summary': summary,
      'waiting_for_user_choice': waitingForUserChoice,
    };
  }

  NarrativeSourceRef _resolveDomainSource(
    String toolName,
    JsonMap rawToolCall,
    JsonMap arguments,
  ) {
    final sourceJson =
        ValueReaders.mapValue(rawToolCall['source_ref']).isNotEmpty
        ? ValueReaders.mapValue(rawToolCall['source_ref'])
        : ValueReaders.mapValue(
            ValueReaders.mapValue(rawToolCall['source']).isNotEmpty
                ? rawToolCall['source']
                : arguments['source_ref'],
          );
    if (sourceJson.isNotEmpty) {
      return NarrativeSourceRef.fromJson(sourceJson);
    }
    final sourceType = ValueReaders.stringValue(
      rawToolCall['source_type'],
      ValueReaders.stringValue(
        arguments['_domain_source_type'],
        ValueReaders.stringValue(
          arguments['domain_source_type'],
          _defaultDomainSourceType(toolName),
        ),
      ),
    ).trim();
    final sourceId = ValueReaders.stringValue(
      rawToolCall['source_id'],
      ValueReaders.stringValue(
        arguments['_domain_source_id'],
        'project_tool_dispatcher',
      ),
    ).trim();
    return NarrativeSourceRef(
      sourceType: sourceType.isEmpty
          ? _defaultDomainSourceType(toolName)
          : sourceType,
      sourceId: sourceId.isEmpty ? 'project_tool_dispatcher' : sourceId,
      label: ValueReaders.stringValue(
        rawToolCall['source_label'],
        ValueReaders.stringValue(arguments['_domain_source_label'], sourceType),
      ).trim(),
    );
  }

  ToolRoundEvidence? _readToolRoundEvidence(
    JsonMap rawToolCall,
    JsonMap arguments,
  ) {
    final raw = ValueReaders.mapValue(rawToolCall['tool_round_evidence']);
    if (raw.isNotEmpty) {
      return ToolRoundEvidence.fromJson(raw);
    }
    final argumentRaw = ValueReaders.mapValue(arguments['tool_round_evidence']);
    if (argumentRaw.isNotEmpty) {
      return ToolRoundEvidence.fromJson(argumentRaw);
    }
    return null;
  }

  NarrativeDomainToolCapability? _domainCapabilityFor(String toolName) {
    return _domainDispatcherFor(toolName).capabilityFor(toolName);
  }

  String _defaultDomainSourceType(String toolName) {
    switch (toolName) {
      case NarrativeDomainToolNames.submitChapterDelivery:
      case NarrativeDomainToolNames.submitNarrativeStateClaims:
      case NarrativeDomainToolNames.requestExternalResearch:
      case NarrativeDomainToolNames.submitResearchNote:
      case NarrativeDomainToolNames.proposeKnowledgeCard:
      case NarrativeDomainToolNames.proposeDesignElement:
        return NarrativeSourceTypes.writer;
      case NarrativeDomainToolNames.submitSemanticReview:
      case NarrativeDomainToolNames.linkInformationEvidence:
        return NarrativeSourceTypes.reviewer;
      case NarrativeDomainToolNames.proposeConstraintBinding:
      case NarrativeDomainToolNames.proposeReferenceWork:
        return NarrativeSourceTypes.user;
      case NarrativeDomainToolNames.proposeNarrativeProfileUpdate:
        return NarrativeSourceTypes.deconstruction;
      case NarrativeDomainToolNames.requestProfileClarification:
      default:
        return NarrativeSourceTypes.system;
    }
  }

  NarrativeDomainToolDispatcher _domainDispatcherFor(String toolName) {
    if (_isInformationDomainTool(toolName)) {
      return _informationDomainDispatcher;
    }
    return _narrativeDomainDispatcher;
  }

  bool _isInformationDomainTool(String toolName) {
    return const <String>{
      NarrativeDomainToolNames.requestExternalResearch,
      NarrativeDomainToolNames.submitResearchNote,
      NarrativeDomainToolNames.proposeKnowledgeCard,
      NarrativeDomainToolNames.proposeDesignElement,
      NarrativeDomainToolNames.linkInformationEvidence,
      NarrativeDomainToolNames.proposeReferenceWork,
    }.contains(toolName);
  }

  Future<DomainToolOutcome> _executeDomainTool(
    ProjectDescriptor project,
    DomainToolRequest request,
  ) {
    if (_isInformationDomainTool(request.toolName)) {
      return _informationDomainToolExecutor.execute(
        project,
        request,
        hostPermissionContext: _hostInformationPermissionContext,
      );
    }
    return _narrativeDomainToolExecutor.execute(project, request);
  }

  List<String> _domainChangedPaths(DomainToolOutcome outcome) {
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(outcome.metadata['adapter_persistence']),
    );
    return ValueReaders.stringList(persistence['changed_paths']);
  }

  String _domainToolSummary(
    String toolName,
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) {
    if (toolName == NarrativeDomainToolNames.requestExternalResearch) {
      return _requestExternalResearchSummary(outcome, changedPaths);
    }
    final label = _domainDisplayName(toolName);
    final status = outcome.outcomeStatus;
    final pathPreview = changedPaths.isEmpty ? '' : '：${changedPaths.first}';
    switch (status) {
      case DomainToolOutcomeStatuses.accepted:
        return '已执行领域工具：$label$pathPreview';
      case DomainToolOutcomeStatuses.proposed:
        return '已记录领域提案：$label$pathPreview';
      case DomainToolOutcomeStatuses.needsUserConfirmation:
        return '领域工具等待用户确认：$label';
      case DomainToolOutcomeStatuses.rejected:
        return '领域工具被拒绝：$label';
      case DomainToolOutcomeStatuses.invalidPayload:
        return '领域工具参数无效：$label';
      case DomainToolOutcomeStatuses.executionFailed:
      default:
        return '领域工具执行失败：$label';
    }
  }

  String _requestExternalResearchSummary(
    DomainToolOutcome outcome,
    List<String> changedPaths,
  ) {
    final label = _domainDisplayName(NarrativeDomainToolNames.requestExternalResearch);
    final payload = ValueReaders.mapValue(outcome.outcomePayload);
    final execution = ValueReaders.mapValue(payload['research_execution']);
    final executedNetwork = ValueReaders.boolValue(
      payload['network_execution_performed'],
    );
    final executedImport = ValueReaders.boolValue(
      payload['import_execution_performed'],
    );
    final waitingForConfirmation = ValueReaders.boolValue(
      payload['requires_user_confirmation'],
    );
    final blocked = ValueReaders.boolValue(execution['blocked']);
    final pathPreview = changedPaths.isEmpty ? '' : '：${changedPaths.first}';

    if (executedNetwork) {
      return '已登记并自动执行资料研究：$label$pathPreview';
    }
    if (executedImport && waitingForConfirmation) {
      return '已登记并执行导入研究，联网仍待确认：$label$pathPreview';
    }
    if (executedImport) {
      return '已登记并执行导入研究：$label$pathPreview';
    }
    if (waitingForConfirmation ||
        outcome.outcomeStatus == DomainToolOutcomeStatuses.needsUserConfirmation) {
      return '已登记待研究请求，等待用户确认：$label';
    }
    if (blocked) {
      return '已登记待研究请求，但当前无法执行：$label';
    }
    return '已登记待研究请求：$label$pathPreview';
  }

  String _domainDisplayName(String toolName) {
    final definition = _narrativeDomainToolCatalog.definitionFor(toolName);
    return definition?.displayName ?? toolName;
  }

  JsonMap _annotateToolResult(String toolName, JsonMap result) {
    if (ValueReaders.stringValue(result['tool_layer']).trim().isNotEmpty) {
      return result;
    }
    final toolLayer = _toolLayerFor(toolName);
    return <String, Object?>{
      ...result,
      'tool_layer': toolLayer,
      'tool_capability': _toolCapability(
        toolName,
        toolLayer: toolLayer,
        capabilityKind: toolLayer == 'low_level'
            ? 'project_low_level_tool'
            : 'project_tool',
      ),
    };
  }

  String _toolLayerFor(String toolName) {
    if (_domainToolNames.contains(toolName)) {
      return 'domain';
    }
    if (_lowLevelToolNames.contains(toolName)) {
      return 'low_level';
    }
    return 'project';
  }

  JsonMap _toolCapability(
    String toolName, {
    required String toolLayer,
    required String capabilityKind,
  }) {
    return <String, Object?>{
      'tool_name': toolName,
      'tool_layer': toolLayer,
      'capability_kind': capabilityKind,
    };
  }

  JsonMap _presentUserOptions(JsonMap arguments) {
    // 中文注释: 选项工具是纯状态结果，不需要宿主 IO，但要告诉主循环当前应该等待用户选择。
    final options = _normalizedUserOptions(arguments);
    if (options.isEmpty) {
      return _resultFactory.notExecuted(
        'present_user_options 至少需要 1 个可点击选项。请提供 options/choices/items 数组，并为每项补齐 title 或 label。',
        data: <String, Object?>{
          'question': ValueReaders.stringValue(arguments['question']),
          'suggested_tool': 'present_user_options',
        },
      );
    }
    return _resultFactory.success(
      '已生成用户选项：${options.length} 个',
      data: <String, Object?>{
        'question': ValueReaders.stringValue(arguments['question']),
        'options': options,
        'waiting_for_user_choice': true,
      },
    );
  }

  List<JsonMap> _normalizedUserOptions(JsonMap arguments) {
    // 中文注释: 这里兼容 options/choices/items 等常见别名，避免模型轻微字段漂移就把整组按钮吞掉。
    final rawOptions = ValueReaders.objectList(
      arguments['options'] ??
          arguments['choices'] ??
          arguments['items'] ??
          arguments['buttons'] ??
          arguments['suggestions'] ??
          arguments['entries'],
    );
    final result = <JsonMap>[];
    for (final rawEntry in rawOptions) {
      if (rawEntry is String || rawEntry is num) {
        final text = ValueReaders.stringValue(rawEntry).trim();
        if (text.isEmpty) {
          continue;
        }
        result.add(<String, Object?>{
          'id': 'option_${result.length + 1}',
          'label': text,
          'title': text,
          'description': '',
          'prompt': text,
        });
        continue;
      }
      final entry = ValueReaders.mapValue(rawEntry);
      if (entry.isEmpty) {
        continue;
      }
      final label = ValueReaders.stringValue(
        entry['label'],
        ValueReaders.stringValue(
          entry['title'],
          ValueReaders.stringValue(
            entry['name'],
            ValueReaders.stringValue(entry['text'], '选项'),
          ),
        ),
      ).trim();
      final description = ValueReaders.stringValue(
        entry['description'],
        ValueReaders.stringValue(
          entry['detail'],
          ValueReaders.stringValue(
            entry['summary'],
            ValueReaders.stringValue(entry['subtitle']),
          ),
        ),
      ).trim();
      final prompt = ValueReaders.stringValue(
        entry['prompt'],
        ValueReaders.stringValue(
          entry['value'],
          ValueReaders.stringValue(
            entry['title'],
            ValueReaders.stringValue(entry['text'], label),
          ),
        ),
      ).trim();
      final id = ValueReaders.stringValue(
        entry['id'],
        label.isEmpty ? 'option_${result.length + 1}' : label,
      ).trim();
      if (label.isEmpty && prompt.isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        'id': id.isEmpty ? 'option_${result.length + 1}' : id,
        'label': label.isEmpty ? prompt : label,
        'title': label.isEmpty ? prompt : label,
        'description': description,
        'prompt': prompt.isEmpty ? label : prompt,
      });
    }
    return result;
  }
}

class _ProjectToolHostWorkspacePortAdapter implements ProjectWorkspacePort {
  const _ProjectToolHostWorkspacePortAdapter(this._hostPort);

  final ProjectToolHostPort _hostPort;

  @override
  Future<void> createDirectory(String rootPath, String relativePath) {
    return _hostPort.createDirectory(rootPath, relativePath);
  }

  @override
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true}) {
    return _hostPort.listEntries(rootPath, recursive: recursive);
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) {
    return _hostPort.readTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) {
    return _hostPort.writeTextFile(rootPath, relativePath, content);
  }
}
