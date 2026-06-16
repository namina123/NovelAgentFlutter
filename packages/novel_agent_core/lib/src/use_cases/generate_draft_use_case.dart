import '../agents/agent_collaboration_brief_service.dart';
import '../agents/builtin_collaborator_catalog_service.dart';
import '../agents/agent_profile_catalog_service.dart';
import '../agents/agent_loop_contract_service.dart';
import '../agents/agent_tool_message_service.dart';
import '../agents/agent_tool_policy_service.dart';
import '../agents/skill_load_memory.dart';
import '../agents/skill_routing_policy.dart';
import '../agents/skill_routing_policy_service.dart';
import '../agents/skill_activation_signal.dart';
import '../agents/sub_agent_execution_service.dart';
import 'dart:convert';
import '../common/host_platform.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../context/context_assembler_service.dart';
import '../llm/chat_request.dart';
import '../llm/chat_request_capability.dart';
import '../ports/llm_gateway.dart';
import '../ports/tool_execution_port.dart';
import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_prompt_contract.dart';
import '../runtime/draft_generation_result.dart';
import '../runtime/draft_generation_progress.dart';
import '../runtime/draft_generation_cancellation_token.dart';
import '../runtime/draft_generation_stop_phase.dart';
import '../runtime/draft_prompt_builder_service.dart';
import '../runtime/project_context_file_selection_service.dart';
import '../runtime/tool_execution_round_result.dart';
import '../runtime/tool_execution_service.dart';
import '../settings/app_settings.dart';
import '../tools/tool_call_parser_service.dart';
import '../tools/tool_exposure_policy_service.dart';
import '../tools/host_tool_permission_context.dart';
import '../tools/host_tool_permission_policy_service.dart';
import '../tools/tool_schema_builder_service.dart';
import '../tools/tool_strategy_prompt_builder.dart';
import '../tools/tool_strategy_service.dart';
import '../session/session_prompt_context.dart';
import '../workflow/continuous_task_tool_exposure_runtime_resolver_service.dart';
import '../agents/project_agent_binding.dart';

class GenerateDraftUseCase {
  GenerateDraftUseCase({
    required ProjectWorkspacePort projectWorkspacePort,
    required LlmGateway llmGateway,
    required ToolExecutionPort toolExecutionPort,
    required ContextAssemblerService contextAssemblerService,
    required ProjectPromptContract projectPromptContract,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableAgents,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableAgentGroups,
    ProjectContextFileSelectionService? fileSelectionService,
    DraftPromptBuilderService? draftPromptBuilderService,
    AgentProfileCatalogService? agentProfileCatalogService,
    ToolStrategyService? toolStrategyService,
    ToolCallParserService? toolCallParserService,
    ToolSchemaBuilderService? toolSchemaBuilderService,
    AgentLoopContractService? agentLoopContractService,
    AgentToolMessageService? agentToolMessageService,
    AgentToolPolicyService? agentToolPolicyService,
    SkillRoutingPolicyService? skillRoutingPolicyService,
    ToolExecutionService? toolExecutionService,
    SubAgentExecutionService? subAgentExecutionService,
    BuiltinCollaboratorCatalogService? collaboratorCatalogService,
    AgentCollaborationBriefService? collaborationBriefService,
    ToolExposurePolicyService? toolExposurePolicyService,
    ContinuousTaskToolExposureRuntimeResolverService?
    continuousTaskToolExposureRuntimeResolverService,
    HostToolPermissionContext? hostToolPermissionContext,
    HostToolPermissionPolicyService? hostToolPermissionPolicyService,
    HostPlatform hostPlatform = HostPlatform.unknown,
  }) : _projectWorkspacePort = projectWorkspacePort,
       _llmGateway = llmGateway,
       _contextAssemblerService = contextAssemblerService,
       _projectPromptContract = projectPromptContract,
       _loadAvailableAgents = loadAvailableAgents,
       _loadAvailableAgentGroups = loadAvailableAgentGroups,
       _fileSelectionService =
           fileSelectionService ?? ProjectContextFileSelectionService(),
       _draftPromptBuilderService =
           draftPromptBuilderService ??
           DraftPromptBuilderService(
             projectPromptContract: projectPromptContract,
           ),
       _agentProfileCatalogService =
           agentProfileCatalogService ?? AgentProfileCatalogService(),
       _collaboratorCatalogService =
           collaboratorCatalogService ?? BuiltinCollaboratorCatalogService(),
       _collaborationBriefService =
           collaborationBriefService ?? AgentCollaborationBriefService(),
       _toolStrategyService = toolStrategyService ?? ToolStrategyService(),
       _toolExposurePolicyService =
           toolExposurePolicyService ?? const ToolExposurePolicyService(),
       _continuousTaskToolExposureRuntimeResolverService =
           continuousTaskToolExposureRuntimeResolverService ??
           const ContinuousTaskToolExposureRuntimeResolverService(),
       _hostPlatform = hostPlatform,
       _toolCallParserService =
           toolCallParserService ?? ToolCallParserService(),
       _toolSchemaBuilderService =
           toolSchemaBuilderService ?? ToolSchemaBuilderService(),
       _agentLoopContractService =
           agentLoopContractService ?? AgentLoopContractService(),
       _agentToolPolicyService =
           agentToolPolicyService ?? AgentToolPolicyService(),
       _skillRoutingPolicyService =
           skillRoutingPolicyService ?? const SkillRoutingPolicyService(),
       _subAgentExecutionService =
           subAgentExecutionService ??
           SubAgentExecutionService(
             llmGateway: llmGateway,
             toolExecutionPort: toolExecutionPort,
             loadAvailableAgents: loadAvailableAgents,
             loadAvailableGroups: loadAvailableAgentGroups,
             hostPlatform: hostPlatform,
             toolExposurePolicyService:
                 toolExposurePolicyService ?? const ToolExposurePolicyService(),
           ),
       _toolExecutionService =
           toolExecutionService ??
           ToolExecutionService(
             toolExecutionPort: toolExecutionPort,
             agentToolMessageService:
                 agentToolMessageService ?? AgentToolMessageService(),
             subAgentExecutionService:
                 subAgentExecutionService ??
                 SubAgentExecutionService(
                   llmGateway: llmGateway,
                   toolExecutionPort: toolExecutionPort,
                   loadAvailableAgents: loadAvailableAgents,
                   loadAvailableGroups: loadAvailableAgentGroups,
                   hostPlatform: hostPlatform,
                   toolExposurePolicyService:
                       toolExposurePolicyService ??
                       const ToolExposurePolicyService(),
                 ),
             hostToolPermissionContext: hostToolPermissionContext,
             hostToolPermissionPolicyService: hostToolPermissionPolicyService,
           ),
       _toolStrategyPromptBuilder = ToolStrategyPromptBuilder(
         toolStrategyService: toolStrategyService ?? ToolStrategyService(),
         projectPromptContract: projectPromptContract,
       );

  final ProjectWorkspacePort _projectWorkspacePort;
  final LlmGateway _llmGateway;
  final ContextAssemblerService _contextAssemblerService;
  final ProjectPromptContract _projectPromptContract;
  final Future<List<JsonMap>> Function(ProjectDescriptor project)?
  _loadAvailableAgents;
  final Future<List<JsonMap>> Function(ProjectDescriptor project)?
  _loadAvailableAgentGroups;
  final ProjectContextFileSelectionService _fileSelectionService;
  final DraftPromptBuilderService _draftPromptBuilderService;
  final AgentProfileCatalogService _agentProfileCatalogService;
  final BuiltinCollaboratorCatalogService _collaboratorCatalogService;
  final AgentCollaborationBriefService _collaborationBriefService;
  final ToolStrategyService _toolStrategyService;
  final ToolExposurePolicyService _toolExposurePolicyService;
  final ContinuousTaskToolExposureRuntimeResolverService
  _continuousTaskToolExposureRuntimeResolverService;
  final HostPlatform _hostPlatform;
  final ToolCallParserService _toolCallParserService;
  final ToolSchemaBuilderService _toolSchemaBuilderService;
  final AgentLoopContractService _agentLoopContractService;
  final AgentToolPolicyService _agentToolPolicyService;
  final SkillRoutingPolicyService _skillRoutingPolicyService;
  final SubAgentExecutionService _subAgentExecutionService;
  final ToolExecutionService _toolExecutionService;
  final ToolStrategyPromptBuilder _toolStrategyPromptBuilder;

  Future<DraftGenerationResult> executeDelegatedSubAgentTask({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    required String childAgentId,
    String childTask = '',
    String title = '',
    String intent = 'draft',
    JsonMap parentAgent = const <String, Object?>{},
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    JsonMap writingExecutionConstraints = const <String, Object?>{},
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    AppSettings? subAgentRuntimeSettings,
    List<ProjectAgentBinding> subAgentBindings = const <ProjectAgentBinding>[],
    String subAgentBindingModeId = '',
    String subAgentBindingStageId = '',
    List<String> sourcePaths = const <String>[],
    List<String> constraints = const <String>[],
    String expectedOutput = '',
    String sessionContext = '',
    SessionPromptContext sessionPromptContext = const SessionPromptContext(),
  }) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError.value(userPrompt, 'userPrompt', '提示词不能为空。');
    }
    final effectiveSessionPromptContext = _resolvedSessionPromptContext(
      sessionContext: sessionContext,
      sessionPromptContext: sessionPromptContext,
    );
    final projectInfo = <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
      'stage': 'draft',
    };
    final entries = await _projectWorkspacePort.listEntries(project.rootPath);
    final selectedPaths = _fileSelectionService.select(entries);
    final fileContents = ValueReaders.deepCopyMap(projectFileContents);
    for (final path in selectedPaths) {
      if (fileContents.containsKey(path)) {
        continue;
      }
      final content = await _projectWorkspacePort.readTextFile(
        project.rootPath,
        path,
      );
      if (content == null || content.trim().isEmpty) {
        continue;
      }
      fileContents[path] = _trimContent(content);
    }
    final resolvedParentAgent = parentAgent.isEmpty
        ? _agentProfileCatalogService.fallbackDefaultAgent()
        : ValueReaders.deepCopyMap(parentAgent);
    final projectAvailableAgents = await _loadAvailableAgentsSafe(project);
    final optionalAgents = _mergeEntriesById(
      projectAvailableAgents,
      _collaboratorCatalogService.optionalCollaboratorProfiles(),
    );
    final projectAvailableGroups = await _loadAvailableAgentGroupsSafe(project);
    final optionalGroups = _mergeEntriesById(
      projectAvailableGroups,
      _collaboratorCatalogService.optionalCollaboratorGroups(),
    );
    final collaborationGroup = _resolveCollaborationGroup(
      preferredGroup: selectedCollaborationGroup,
      projectAvailableAgents: projectAvailableAgents,
      projectAvailableGroups: projectAvailableGroups,
      availableGroups: optionalGroups,
      fallbackAgent: resolvedParentAgent,
    );
    final routingSignal = _skillRoutingPolicyService.buildActivationSignal(
      intent: intent,
      projectType: project.projectType,
      userPrompt: cleanPrompt,
      routeContext: skillRoutingContext,
    );
    final contextPack = _contextAssemblerService.assemble(<String, Object?>{
      'project': projectInfo,
      'project_files': entries,
      'project_file_contents': fileContents,
      'user_prompt': cleanPrompt,
      'session_context': effectiveSessionPromptContext.contextMarkdown,
      'intent': intent,
      'agent': resolvedParentAgent,
      'optional_agents': optionalAgents,
      'selected_collaboration_group': collaborationGroup,
      'optional_agent_groups': optionalGroups,
      'context_settings': contextSettings,
      'model_profile': modelProfile,
      'memory_sections': memorySections,
      'expression_constraint_profiles': expressionConstraintProfiles,
      'project_expression_constraint_bindings':
          projectExpressionConstraintBindings,
      'project_file_section_plan': projectFileSectionPlan,
    });
    final mainContext = <String, Object?>{
      'intent': intent,
      'project_title': project.name,
      'project_tree_note': _projectPromptContract.projectTreeSummary(entries),
      'selected_collaboration_group': ValueReaders.deepCopyMap(
        collaborationGroup,
      ),
      'selected_collaboration_group_id': ValueReaders.stringValue(
        collaborationGroup['id'],
      ),
      'selected_collaboration_group_name': ValueReaders.stringValue(
        collaborationGroup['name'],
      ),
      'selected_collaboration_group_member_ids': ValueReaders.stringList(
        collaborationGroup['agents'],
      ),
      'style_note': '当前请求已经附带上下文摘录；如需更多文件，请调用项目工具按需读取。',
      'skill_routing_stage': routingSignal.stageId,
      'skill_routing_flags': routingSignal.flags,
      if (subAgentRuntimeSettings != null)
        'sub_agent_runtime_settings': subAgentRuntimeSettings,
      if (subAgentBindings.isNotEmpty)
        'sub_agent_bindings': List<ProjectAgentBinding>.unmodifiable(
          subAgentBindings,
        ),
      'sub_agent_binding_mode_id': subAgentBindingModeId,
      'sub_agent_binding_stage_id': subAgentBindingStageId,
      if (ValueReaders.mapValue(
        skillRoutingContext['workflow_task_context'],
      ).isNotEmpty)
        'workflow_task_context': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillRoutingContext['workflow_task_context']),
        ),
    };
    final toolCall = <String, Object?>{
      'id': 'delegated_sub_agent_${DateTime.now().microsecondsSinceEpoch}',
      'name': 'call_sub_agent',
      'arguments': <String, Object?>{
        'agent_id': childAgentId,
        'task': childTask.trim().isEmpty ? cleanPrompt : childTask.trim(),
        'context_excerpt': cleanPrompt,
        if (sourcePaths.isNotEmpty) 'source_paths': sourcePaths,
        if (constraints.isNotEmpty) 'constraints': constraints,
        if (expectedOutput.trim().isNotEmpty)
          'expected_output': expectedOutput.trim(),
      },
    };
    final childResult = await _subAgentExecutionService.execute(
      project: project,
      parentAgent: resolvedParentAgent,
      toolCall: toolCall,
      modelId: modelId,
      mainContext: mainContext,
    );
    final executedTools = <Object?>[
      <String, Object?>{
        ...toolCall,
        'result': ValueReaders.deepCopyMap(childResult),
      },
    ];
    final toolErrorSummary = ValueReaders.boolValue(childResult['ok'], true)
        ? ''
        : ValueReaders.stringValue(
            childResult['error'],
            ValueReaders.stringValue(childResult['summary']),
          );
    final finalContent = ValueReaders.stringValue(
      childResult['result_markdown'],
      ValueReaders.stringValue(childResult['summary']),
    ).trim();
    return DraftGenerationResult(
      project: project,
      projectInfo: projectInfo,
      userPrompt: cleanPrompt,
      prompt: cleanPrompt,
      modelId: modelId,
      draftMarkdown: finalContent,
      contextPack: contextPack,
      selectedPaths: List<String>.unmodifiable(selectedPaths),
      executedTools: List<Object?>.unmodifiable(executedTools),
      writtenPaths: const <String>[],
      changedPaths: const <String>[],
      transcriptMessages: const <JsonMap>[],
      waitingForUserChoice: ValueReaders.boolValue(
        childResult['waiting_for_user_choice'],
      ),
      reasoningContent: ValueReaders.stringValue(
        childResult['reasoning_content'],
      ),
      stoppedByToolError: !ValueReaders.boolValue(childResult['ok'], true),
      toolErrorSummary: toolErrorSummary,
    );
  }

  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    String sessionContext = '',
    SessionPromptContext sessionPromptContext = const SessionPromptContext(),
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    JsonMap writingExecutionConstraints = const <String, Object?>{},
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    AppSettings? subAgentRuntimeSettings,
    List<ProjectAgentBinding> subAgentBindings = const <ProjectAgentBinding>[],
    String subAgentBindingModeId = '',
    String subAgentBindingStageId = '',
    List<String> exposedToolIds = const <String>[],
    String activeDocumentPath = '',
    String activeDocumentBody = '',
    DraftGenerationCancellationToken? cancellationToken,
    void Function(DraftGenerationProgress progress)? onProgress,
  }) async {
    // 中文注释: 这里负责把项目文件、上下文组装和模型调用收束成一次共享草稿生成流程。
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError.value(userPrompt, 'userPrompt', '提示词不能为空。');
    }
    final effectiveSessionPromptContext = _resolvedSessionPromptContext(
      sessionContext: sessionContext,
      sessionPromptContext: sessionPromptContext,
    );
    final projectInfo = <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
      'stage': 'draft',
    };
    List<String> selectedPaths = const <String>[];
    JsonMap contextPack = const <String, Object?>{};
    var prompt = '';
    List<JsonMap> messages = const <JsonMap>[];
    final executedTools = <Object?>[];
    final writtenPaths = <String>[];
    final changedPaths = <String>[];
    var finalContent = '';
    var latestStreamedDraft = '';
    var waitingForUserChoice = false;
    var stoppedByToolError = false;
    var reasoningContent = '';
    var toolErrorSummary = '';
    var cancellationReported = false;
    DraftGenerationResult cancelledResult(DraftGenerationStopPhase stopPhase) {
      final resolvedContent = _effectiveCancelledDraftContent(
        finalContent: finalContent,
        latestStreamedDraft: latestStreamedDraft,
      );
      final partialContentAccepted = _partialContentAcceptedForCancellation(
        draftMarkdown: resolvedContent,
        writtenPaths: writtenPaths,
        changedPaths: changedPaths,
        waitingForUserChoice: waitingForUserChoice,
      );
      if (!cancellationReported) {
        onProgress?.call(
          DraftGenerationProgress(
            phase: 'cancelled',
            roundIndex: 0,
            draftMarkdown: resolvedContent,
            reasoningContent: reasoningContent,
            executedTools: List<Object?>.unmodifiable(executedTools),
            cancelledByUser: true,
            stopPhase: stopPhase,
            partialContentAccepted: partialContentAccepted,
          ),
        );
        cancellationReported = true;
      }
      return DraftGenerationResult(
        project: project,
        projectInfo: projectInfo,
        userPrompt: cleanPrompt,
        prompt: prompt,
        modelId: modelId,
        draftMarkdown: resolvedContent.trim(),
        contextPack: contextPack,
        selectedPaths: selectedPaths,
        executedTools: List<Object?>.unmodifiable(executedTools),
        writtenPaths: List<String>.unmodifiable(writtenPaths),
        changedPaths: List<String>.unmodifiable(changedPaths),
        transcriptMessages: List<JsonMap>.unmodifiable(messages),
        waitingForUserChoice: waitingForUserChoice,
        reasoningContent: reasoningContent,
        stoppedByToolError: stoppedByToolError,
        toolErrorSummary: toolErrorSummary,
        cancelledByUser: true,
        stopPhase: stopPhase,
        partialContentAccepted: partialContentAccepted,
      );
    }

    if (_shouldCancel(cancellationToken)) {
      return cancelledResult(DraftGenerationStopPhase.preparingContext);
    }
    final entries = await _projectWorkspacePort.listEntries(project.rootPath);
    selectedPaths = _fileSelectionService.select(entries);
    final fileContents = ValueReaders.deepCopyMap(projectFileContents);
    for (final path in selectedPaths) {
      if (_shouldCancel(cancellationToken)) {
        return cancelledResult(DraftGenerationStopPhase.preparingContext);
      }
      if (fileContents.containsKey(path)) {
        continue;
      }
      final content = await _projectWorkspacePort.readTextFile(
        project.rootPath,
        path,
      );
      if (content == null || content.trim().isEmpty) {
        continue;
      }
      fileContents[path] = _trimContent(content);
    }
    if (_shouldCancel(cancellationToken)) {
      return cancelledResult(DraftGenerationStopPhase.preparingContext);
    }
    final resolvedAgent = agent.isEmpty
        ? _agentProfileCatalogService.fallbackDefaultAgent()
        : ValueReaders.deepCopyMap(agent);
    final projectAvailableAgents = await _loadAvailableAgentsSafe(project);
    final optionalAgents = _mergeEntriesById(
      projectAvailableAgents,
      _collaboratorCatalogService.optionalCollaboratorProfiles(),
    );
    final projectAvailableGroups = await _loadAvailableAgentGroupsSafe(project);
    final optionalGroups = _mergeEntriesById(
      projectAvailableGroups,
      _collaboratorCatalogService.optionalCollaboratorGroups(),
    );
    final collaborationGroup = _resolveCollaborationGroup(
      preferredGroup: selectedCollaborationGroup,
      projectAvailableAgents: projectAvailableAgents,
      projectAvailableGroups: projectAvailableGroups,
      availableGroups: optionalGroups,
      fallbackAgent: resolvedAgent,
    );
    final routingSignal = _skillRoutingPolicyService.buildActivationSignal(
      intent: intent,
      projectType: project.projectType,
      userPrompt: cleanPrompt,
      routeContext: skillRoutingContext,
    );
    final routingPolicy = _skillRoutingPolicyService.resolvePolicy(
      routingSignal,
    );
    final skillLoadMemory = SkillLoadMemory(
      scopeId: _skillRoutingScopeId(project, routingSignal),
    );
    contextPack = _withExecutionConstraintSummary(
      _contextAssemblerService.assemble(<String, Object?>{
        'project': projectInfo,
        'project_files': entries,
        'project_file_contents': fileContents,
        'current_file_path': activeDocumentPath,
        'current_file_body': activeDocumentBody,
        'user_prompt': cleanPrompt,
        'session_context': effectiveSessionPromptContext.contextMarkdown,
        'intent': intent,
        'agent': resolvedAgent,
        'optional_agents': optionalAgents,
        'selected_collaboration_group': collaborationGroup,
        'optional_agent_groups': optionalGroups,
        'context_settings': contextSettings,
        'model_profile': modelProfile,
        'memory_sections': memorySections,
        'expression_constraint_profiles': expressionConstraintProfiles,
        'project_expression_constraint_bindings':
            projectExpressionConstraintBindings,
        'project_file_section_plan': projectFileSectionPlan,
      }),
      writingExecutionConstraints: writingExecutionConstraints,
    );
    prompt = _draftPromptBuilderService.build(
      project: projectInfo,
      agent: resolvedAgent,
      contextPack: contextPack,
      userPrompt: cleanPrompt,
      title: title,
      intent: intent,
    );
    if (_shouldCancel(cancellationToken)) {
      return cancelledResult(DraftGenerationStopPhase.preparingContext);
    }
    final toolSettings = _toolStrategyService.defaultSettings();
    final requestedToolIds = exposedToolIds.isEmpty
        ? _toolStrategyService.enabledToolIds(toolSettings)
        : exposedToolIds;
    final toolExposureResolution =
        _continuousTaskToolExposureRuntimeResolverService.resolve(
          candidateToolIds: requestedToolIds,
          selectedCollaborationGroup: collaborationGroup,
          runtimeContext: <String, Object?>{
            'mode': ValueReaders.stringValue(skillRoutingContext['mode']),
            'task_type': ValueReaders.stringValue(
              skillRoutingContext['task_type'],
            ),
            'task_family_id': ValueReaders.stringValue(
              skillRoutingContext['task_family_id'],
            ),
          },
          intent: intent,
        );
    final filteredToolIds = _toolExposurePolicyService.filterExposedToolIds(
      toolExposureResolution.visibleToolIds,
      hostPlatform: _hostPlatform,
      projectType: project.projectType,
      storageStrategy: project.storageStrategy,
    );
    final toolSchemas = _toolSchemaBuilderService.buildOpenAiSchemas(
      filteredToolIds,
    );
    final formalDeliveryRequired =
        exposedToolIds.isNotEmpty &&
        filteredToolIds.contains(AgentToolPolicyService.formalDeliveryToolName);
    final formalDeliveryRecoveryToolIds = formalDeliveryRequired
        ? <String>[AgentToolPolicyService.formalDeliveryToolName]
        : const <String>[];
    final formalDeliveryRecoveryToolSchemas = formalDeliveryRequired
        ? _toolSchemaBuilderService.buildOpenAiSchemas(
            formalDeliveryRecoveryToolIds,
          )
        : const <JsonMap>[];
    final maxLlmRounds = formalDeliveryRequired ? 12 : 8;
    final llmRequestOptions = _llmRequestOptions(
      requestOptions,
      intent: intent,
      toolSettings: toolSettings,
      hasTools: toolSchemas.isNotEmpty,
    );
    final collaborationBrief = collaborationGroup.isEmpty
        ? ''
        : _collaborationBriefService.collaborationBrief(
            collaborationGroup,
            optionalAgents,
          );
    final mainContext = <String, Object?>{
      'intent': intent,
      'project_title': project.name,
      'project_tree_note': _projectPromptContract.projectTreeSummary(entries),
      'active_document_path': activeDocumentPath,
      'active_document_body': activeDocumentBody,
      'selected_collaboration_group': ValueReaders.deepCopyMap(
        collaborationGroup,
      ),
      'selected_collaboration_group_id': ValueReaders.stringValue(
        collaborationGroup['id'],
      ),
      'selected_collaboration_group_name': ValueReaders.stringValue(
        collaborationGroup['name'],
      ),
      'selected_collaboration_group_member_ids': ValueReaders.stringList(
        collaborationGroup['agents'],
      ),
      'continuous_task_family_id': toolExposureResolution.taskProfile.familyId,
      'continuous_task_run_kind': toolExposureResolution.taskProfile.runKind,
      'continuous_task_tool_exposure_resolution': toolExposureResolution
          .toJson(),
      'style_note': '当前请求已经附带上下文包；如需更多文件，请调用项目工具按需读取。',
      'skill_routing_stage': routingPolicy.stageId,
      'skill_routing_flags': routingSignal.flags,
      if (writingExecutionConstraints.isNotEmpty)
        'writing_execution_constraints': ValueReaders.deepCopyMap(
          writingExecutionConstraints,
        ),
      if (subAgentRuntimeSettings != null)
        'sub_agent_runtime_settings': subAgentRuntimeSettings,
      if (subAgentBindings.isNotEmpty)
        'sub_agent_bindings': List<ProjectAgentBinding>.unmodifiable(
          subAgentBindings,
        ),
      'sub_agent_binding_mode_id': subAgentBindingModeId,
      'sub_agent_binding_stage_id': subAgentBindingStageId,
      if (ValueReaders.mapValue(
        skillRoutingContext['workflow_task_context'],
      ).isNotEmpty)
        'workflow_task_context': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(skillRoutingContext['workflow_task_context']),
        ),
    };
    final preloadRound =
        _shouldPreloadRoutedSkills(
          skillRoutingContext: skillRoutingContext,
          exposedToolIds: exposedToolIds,
        )
        ? await _preloadRoutedSkills(
            project: project,
            policyStageNote: routingPolicy.stageId,
            policy: routingPolicy,
            agent: resolvedAgent,
            modelId: modelId,
            mainContext: mainContext,
            skillLoadMemory: skillLoadMemory,
          )
        : const ToolExecutionRoundResult(
            executedTools: <Object?>[],
            writtenPaths: <String>[],
            changedPaths: <String>[],
            transcriptMessages: <JsonMap>[],
            waitingForUserChoice: false,
            stoppedByToolError: false,
            hadPlanTool: false,
          );
    if (_shouldCancel(cancellationToken)) {
      return cancelledResult(DraftGenerationStopPhase.preloadingSkills);
    }
    final skillRoutingNote = _skillRoutingPolicyService
        .buildGuidanceLines(routingPolicy, skillLoadMemory: skillLoadMemory)
        .join('\n');
    final systemPrompt = _toolStrategyPromptBuilder.buildPromptText(
      settings: toolSettings,
      intent: intent,
      projectNote: _projectPromptContract.sessionInfo(
        projectInfo,
        intent,
        agent: resolvedAgent,
      ),
      projectTreeNote: _projectPromptContract.projectTreeSummary(entries),
      agentNote: [
        _projectPromptContract.agentBoundary(
          resolvedAgent,
          optionalAgents: optionalAgents,
        ),
        if (collaborationBrief.trim().isNotEmpty) collaborationBrief,
      ].join('\n\n'),
      styleNote: <String>[
        '当前请求已经附带上下文包；如需更多文件，请调用项目工具按需读取。',
        ValueReaders.stringValue(
              contextPack['creative_rule_summary'],
            ).trim().isEmpty
            ? ''
            : '高优先级创作约束摘要：${ValueReaders.stringValue(contextPack['creative_rule_summary']).trim()}',
        ValueReaders.stringValue(
              writingExecutionConstraints['chapter_length_summary'],
            ).trim().isEmpty
            ? ''
            : '章节字数硬约束：${ValueReaders.stringValue(writingExecutionConstraints['chapter_length_summary']).trim()}。',
        skillRoutingNote,
      ].where((item) => item.trim().isNotEmpty).join('\n'),
      toolIds: filteredToolIds,
    );
    messages = <JsonMap>[
      <String, Object?>{'role': 'system', 'content': systemPrompt},
      ...effectiveSessionPromptContext.historyMessages,
      ...preloadRound.transcriptMessages,
      <String, Object?>{'role': 'user', 'content': prompt},
    ];
    executedTools.addAll(preloadRound.executedTools);
    var previousRoundHadPlanTool = false;
    var planContinueRetryUsed = false;
    var emptyReadOnlyRetryUsed = false;
    var formalDeliveryContinueRetryCount = 0;
    var formalDeliveryRecoveryMode = false;
    var previousToolFingerprint = '';
    var repeatedReadOnlyToolRounds = 0;
    for (var roundIndex = 0; roundIndex < maxLlmRounds; roundIndex++) {
      if (_shouldCancel(cancellationToken)) {
        return cancelledResult(DraftGenerationStopPhase.llmRound);
      }
      final currentToolIds = formalDeliveryRecoveryMode
          ? formalDeliveryRecoveryToolIds
          : filteredToolIds;
      final currentToolSchemas = formalDeliveryRecoveryMode
          ? formalDeliveryRecoveryToolSchemas
          : toolSchemas;
      final llmResult = await _llmGateway.requestChat(
        request: ChatRequest(
          modelId: modelId,
          messages: messages,
          tools: currentToolSchemas,
          options: _roundRequestOptions(
            llmRequestOptions,
            formalDeliveryRecoveryMode: formalDeliveryRecoveryMode,
            modelProfile: modelProfile,
          ),
          capability: ChatRequestCapability.fromModelProfile(modelProfile),
        ),
        cancellationToken: cancellationToken,
        onStreamUpdate: (update) {
          latestStreamedDraft = update.content;
          if (update.reasoningContent.trim().isNotEmpty) {
            reasoningContent = update.reasoningContent.trim();
          }
          onProgress?.call(
            DraftGenerationProgress(
              phase: 'llm_streaming',
              roundIndex: roundIndex,
              draftMarkdown: update.content,
              reasoningContent: update.reasoningContent,
              pendingToolCalls: update.toolCalls,
              executedTools: List<Object?>.unmodifiable(executedTools),
            ),
          );
        },
      );
      if (_shouldCancel(cancellationToken)) {
        return cancelledResult(DraftGenerationStopPhase.llmRound);
      }
      final roundReasoning = ValueReaders.stringValue(
        llmResult['reasoning_content'],
      ).trim();
      if (roundReasoning.isNotEmpty) {
        reasoningContent = roundReasoning;
      }
      final parsedToolCalls = _toolCallParserService.parseToolCalls(
        llmResult,
        allowInlineFallback: ValueReaders.boolValue(
          toolSettings['allow_inline_fallback'],
          true,
        ),
      );
      final toolCalls = _filterToolCallsByAllowedToolIds(
        parsedToolCalls,
        currentToolIds,
      );
      if (parsedToolCalls.isNotEmpty &&
          toolCalls.isEmpty &&
          formalDeliveryRecoveryMode) {
        formalDeliveryContinueRetryCount += 1;
        messages.add(<String, Object?>{
          'role': 'user',
          'content':
              '当前是正式章节交付恢复轮，只允许调用 submit_chapter_delivery。'
              '你刚才请求了当前恢复轮不允许的工具，因此没有执行。'
              '请立刻把已经掌握的信息整理为章节正文，并调用 submit_chapter_delivery 交付；不要继续读取、研究或提交资料笔记。',
        });
        continue;
      }
      final contract = _agentLoopContractService.loopStepContract(
        llmResult,
        toolCalls,
        roundIndex: roundIndex,
        maxRounds: maxLlmRounds,
        waitingForUserChoice: waitingForUserChoice,
        stoppedByToolError: stoppedByToolError,
      );
      final action = ValueReaders.stringValue(contract['action']);
      if (action == 'execute_tools') {
        final normalizedToolCalls = ValueReaders.objectList(
          contract['tool_calls'],
        );
        onProgress?.call(
          DraftGenerationProgress(
            phase: 'tool_calls_ready',
            roundIndex: roundIndex,
            draftMarkdown: finalContent,
            reasoningContent: reasoningContent,
            pendingToolCalls: normalizedToolCalls
                .map(ValueReaders.mapValue)
                .map(ValueReaders.deepCopyMap)
                .toList(growable: false),
            executedTools: List<Object?>.unmodifiable(executedTools),
          ),
        );
        final toolFingerprint = _toolRoundFingerprint(normalizedToolCalls);
        if (toolFingerprint.isNotEmpty &&
            toolFingerprint == previousToolFingerprint &&
            _isReadOnlyToolRound(normalizedToolCalls)) {
          repeatedReadOnlyToolRounds += 1;
        } else {
          repeatedReadOnlyToolRounds = 0;
        }
        previousToolFingerprint = toolFingerprint;
        if (repeatedReadOnlyToolRounds >= 2) {
          stoppedByToolError = true;
          toolErrorSummary = '工具重复空转：同一组只读工具调用连续重复，已主动停止。';
          break;
        }
        if (_shouldCancel(cancellationToken)) {
          return cancelledResult(DraftGenerationStopPhase.executingTools);
        }
        final toolRound = await _toolExecutionService.executeRound(
          project: project,
          assistantMessage: ValueReaders.mapValue(
            contract['assistant_message'],
          ),
          toolCalls: normalizedToolCalls,
          agent: resolvedAgent,
          modelId: modelId,
          mainContext: mainContext,
          skillLoadMemory: skillLoadMemory,
        );
        if (_shouldCancel(cancellationToken)) {
          return cancelledResult(DraftGenerationStopPhase.executingTools);
        }
        previousRoundHadPlanTool = toolRound.hadPlanTool;
        executedTools.addAll(toolRound.executedTools);
        for (final path in toolRound.writtenPaths) {
          if (!writtenPaths.contains(path)) {
            writtenPaths.add(path);
          }
        }
        for (final path in toolRound.changedPaths) {
          if (!changedPaths.contains(path)) {
            changedPaths.add(path);
          }
        }
        messages.addAll(toolRound.transcriptMessages);
        waitingForUserChoice =
            waitingForUserChoice || toolRound.waitingForUserChoice;
        stoppedByToolError = stoppedByToolError || toolRound.stoppedByToolError;
        if (toolRound.stoppedByToolError && toolErrorSummary.isEmpty) {
          toolErrorSummary = _toolErrorSummary(toolRound.executedTools);
        }
        onProgress?.call(
          DraftGenerationProgress(
            phase: 'tool_round_completed',
            roundIndex: roundIndex,
            draftMarkdown: finalContent,
            reasoningContent: reasoningContent,
            executedTools: List<Object?>.unmodifiable(executedTools),
          ),
        );
        final afterExecutedToolRound = _agentToolPolicyService
            .afterExecutedToolRoundDecision(
              formalDeliveryRequired: formalDeliveryRequired,
              formalDeliveryContinueRetryCount:
                  formalDeliveryContinueRetryCount,
              executedTools: executedTools,
              recentExecutedTools: toolRound.executedTools,
              writtenPaths: writtenPaths,
              waitingForUserChoice: waitingForUserChoice,
              stoppedByToolError: stoppedByToolError,
            );
        if (ValueReaders.boolValue(
          afterExecutedToolRound['continue_formal_delivery'],
        )) {
          formalDeliveryContinueRetryCount += 1;
          formalDeliveryRecoveryMode = ValueReaders.boolValue(
            afterExecutedToolRound['restrict_to_formal_delivery'],
          );
          messages.add(<String, Object?>{
            'role': 'user',
            'content': ValueReaders.stringValue(
              afterExecutedToolRound['continue_instruction'],
            ),
          });
          previousRoundHadPlanTool = false;
          stoppedByToolError = false;
          toolErrorSummary = '';
          continue;
        }
        formalDeliveryRecoveryMode = false;
        if (stoppedByToolError || waitingForUserChoice) {
          break;
        }
        continue;
      }
      final content = ValueReaders.stringValue(llmResult['content']).trim();
      final afterToolRound = _agentToolPolicyService.afterToolRoundDecision(
        llmResult,
        roundHasPlanTool: previousRoundHadPlanTool,
        planContinueRetryUsed: planContinueRetryUsed,
        emptyReadOnlyRetryUsed: emptyReadOnlyRetryUsed,
        formalDeliveryRequired: formalDeliveryRequired,
        formalDeliveryContinueRetryCount: formalDeliveryContinueRetryCount,
        executedTools: executedTools,
        writtenPaths: writtenPaths,
      );
      if (ValueReaders.boolValue(afterToolRound['retry_after_plan']) &&
          content.isEmpty) {
        planContinueRetryUsed = true;
        messages.add(<String, Object?>{
          'role': 'user',
          'content': ValueReaders.stringValue(
            afterToolRound['continue_instruction'],
          ),
        });
        previousRoundHadPlanTool = false;
        continue;
      }
      if (ValueReaders.boolValue(
        afterToolRound['retry_after_formal_delivery'],
      )) {
        formalDeliveryContinueRetryCount += 1;
        formalDeliveryRecoveryMode = ValueReaders.boolValue(
          afterToolRound['restrict_to_formal_delivery'],
        );
        messages.add(<String, Object?>{
          'role': 'user',
          'content': ValueReaders.stringValue(
            afterToolRound['continue_instruction'],
          ),
        });
        previousRoundHadPlanTool = false;
        continue;
      }
      if (ValueReaders.boolValue(
        afterToolRound['retry_after_read_only_context'],
      )) {
        emptyReadOnlyRetryUsed = true;
        messages.add(<String, Object?>{
          'role': 'user',
          'content': ValueReaders.stringValue(
            afterToolRound['continue_instruction'],
          ),
        });
        previousRoundHadPlanTool = false;
        continue;
      }
      finalContent = content;
      onProgress?.call(
        DraftGenerationProgress(
          phase: 'llm_completed',
          roundIndex: roundIndex,
          draftMarkdown: finalContent,
          reasoningContent: reasoningContent,
          executedTools: List<Object?>.unmodifiable(executedTools),
        ),
      );
      break;
    }
    if (_shouldCancel(cancellationToken)) {
      return cancelledResult(DraftGenerationStopPhase.finalizingResult);
    }
    final finalContentPolicy = _agentToolPolicyService.finalContentPolicy(
      finalContent,
      waitingForUserChoice: waitingForUserChoice,
      executedTools: executedTools,
      writtenPaths: writtenPaths,
    );
    final resolvedContent = ValueReaders.stringValue(
      finalContentPolicy['content'],
      finalContent,
    );
    return DraftGenerationResult(
      project: project,
      projectInfo: projectInfo,
      userPrompt: cleanPrompt,
      prompt: prompt,
      modelId: modelId,
      draftMarkdown: resolvedContent.trim(),
      contextPack: contextPack,
      selectedPaths: _mergePaths(
        selectedPaths,
        fileContents.keys.toList(growable: false),
      ),
      executedTools: executedTools,
      writtenPaths: writtenPaths,
      changedPaths: changedPaths,
      transcriptMessages: messages,
      waitingForUserChoice: waitingForUserChoice,
      reasoningContent: reasoningContent,
      stoppedByToolError: stoppedByToolError,
      toolErrorSummary: toolErrorSummary,
    );
  }

  String _trimContent(String content) {
    // 中文注释: 单文件片段在进入上下文前先做长度裁剪，避免少量超长正文挤掉所有其他约束。
    const maxChars = 6000;
    if (content.length <= maxChars) {
      return content;
    }
    return content.substring(0, maxChars);
  }

  bool _shouldCancel(DraftGenerationCancellationToken? cancellationToken) {
    return cancellationToken?.isCancellationRequested ?? false;
  }

  String _effectiveCancelledDraftContent({
    required String finalContent,
    required String latestStreamedDraft,
  }) {
    // 中文注释: 协作式取消优先保留当前已拿到的正文片段，避免停止后把已有流式内容全部丢掉。
    final resolved = finalContent.trim().isNotEmpty
        ? finalContent
        : latestStreamedDraft;
    return resolved.trim();
  }

  bool _partialContentAcceptedForCancellation({
    required String draftMarkdown,
    required List<String> writtenPaths,
    required List<String> changedPaths,
    required bool waitingForUserChoice,
  }) {
    // 中文注释: 只要已经形成可读正文、项目写入或等待用户确认，就视为有可保留的中间成果。
    return draftMarkdown.trim().isNotEmpty ||
        writtenPaths.isNotEmpty ||
        changedPaths.isNotEmpty ||
        waitingForUserChoice;
  }

  SessionPromptContext _resolvedSessionPromptContext({
    required String sessionContext,
    required SessionPromptContext sessionPromptContext,
  }) {
    final markdown = sessionPromptContext.hasContextMarkdown
        ? sessionPromptContext.contextMarkdown
        : sessionContext;
    return SessionPromptContext(
      contextMarkdown: markdown,
      historyMessages: sessionPromptContext.historyMessages,
    );
  }

  JsonMap _withExecutionConstraintSummary(
    JsonMap contextPack, {
    required JsonMap writingExecutionConstraints,
  }) {
    final lines = <String>[];
    final chapterLengthSummary = ValueReaders.stringValue(
      writingExecutionConstraints['chapter_length_summary'],
    ).trim();
    if (chapterLengthSummary.isNotEmpty) {
      lines.add('章节字数：$chapterLengthSummary');
    }
    final sessionConstraintMarkdown = ValueReaders.stringValue(
      writingExecutionConstraints['session_context_markdown'],
    ).trim();
    if (sessionConstraintMarkdown.isNotEmpty) {
      lines.addAll(
        sessionConstraintMarkdown
            .replaceAll('\r\n', '\n')
            .split('\n')
            .where((line) => line.trim().startsWith('- '))
            .map((line) => line.trim())
            .take(4),
      );
    }
    if (lines.isEmpty) {
      return contextPack;
    }
    return <String, Object?>{
      ...contextPack,
      'execution_constraint_summary': lines.join('\n'),
    };
  }

  JsonMap _llmRequestOptions(
    JsonMap requestOptions, {
    required String intent,
    required JsonMap toolSettings,
    required bool hasTools,
  }) {
    // 中文注释: 请求选项合并只负责把模型参数和工具策略拼成最终网关输入。
    final merged = ValueReaders.deepCopyMap(requestOptions);
    final strategyOptions = _toolStrategyService.requestOptionsForIntent(
      toolSettings,
      intent,
    );
    if (hasTools &&
        ValueReaders.boolValue(strategyOptions['force_tool_choice']) &&
        ValueReaders.stringValue(
          strategyOptions['preferred_tool'],
        ).trim().isNotEmpty) {
      merged['tool_choice'] = <String, Object?>{
        'type': 'function',
        'function': <String, Object?>{
          'name': ValueReaders.stringValue(strategyOptions['preferred_tool']),
        },
      };
    }
    return merged;
  }

  JsonMap _roundRequestOptions(
    JsonMap baseOptions, {
    required bool formalDeliveryRecoveryMode,
    required JsonMap modelProfile,
  }) {
    final options = ValueReaders.deepCopyMap(baseOptions);
    if (!formalDeliveryRecoveryMode ||
        !ValueReaders.boolValue(modelProfile['supports_tool_choice'])) {
      return options;
    }
    options['tool_choice'] = <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': AgentToolPolicyService.formalDeliveryToolName,
      },
    };
    return options;
  }

  List<JsonMap> _filterToolCallsByAllowedToolIds(
    List<JsonMap> toolCalls,
    List<String> allowedToolIds,
  ) {
    if (toolCalls.isEmpty || allowedToolIds.isEmpty) {
      return const <JsonMap>[];
    }
    final allowed = allowedToolIds.toSet();
    return toolCalls
        .where(
          (call) =>
              allowed.contains(ValueReaders.stringValue(call['name']).trim()),
        )
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  Future<List<JsonMap>> _loadAvailableAgentsSafe(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目级智能体目录是可选增强能力，读取失败时回退为空列表以保住主链路。
    final loader = _loadAvailableAgents;
    if (loader == null) {
      return const <JsonMap>[];
    }
    try {
      return await loader(project);
    } catch (_) {
      return const <JsonMap>[];
    }
  }

  Future<List<JsonMap>> _loadAvailableAgentGroupsSafe(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目级协作组加载失败时不阻塞生成，而是继续使用内置协作组兜底。
    final loader = _loadAvailableAgentGroups;
    if (loader == null) {
      return const <JsonMap>[];
    }
    try {
      return await loader(project);
    } catch (_) {
      return const <JsonMap>[];
    }
  }

  JsonMap _resolveCollaborationGroup({
    required JsonMap preferredGroup,
    required List<JsonMap> projectAvailableAgents,
    required List<JsonMap> projectAvailableGroups,
    required List<JsonMap> availableGroups,
    required JsonMap fallbackAgent,
  }) {
    // 中文注释: 当前项目显式选择的协作组优先进入运行链；只有缺失时才退回可用组或单成员兜底。
    final preferredId = ValueReaders.stringValue(preferredGroup['id']).trim();
    if (preferredId.isNotEmpty) {
      for (final group in availableGroups) {
        if (ValueReaders.stringValue(group['id']).trim() == preferredId) {
          return ValueReaders.deepCopyMap(group);
        }
      }
    }
    if (preferredGroup.isNotEmpty) {
      return ValueReaders.deepCopyMap(preferredGroup);
    }
    final projectAgentIds = projectAvailableAgents
        .map((agent) => ValueReaders.stringValue(agent['id']).trim())
        .where((agentId) => agentId.isNotEmpty)
        .toSet();
    if (projectAvailableGroups.isEmpty && projectAgentIds.length <= 1) {
      return _singleMemberCollaborationGroup(fallbackAgent);
    }
    if (availableGroups.isNotEmpty) {
      return ValueReaders.deepCopyMap(availableGroups.first);
    }
    return _singleMemberCollaborationGroup(fallbackAgent);
  }

  JsonMap _singleMemberCollaborationGroup(JsonMap agent) {
    // 中文注释: 单智能体项目统一包装成单成员协作组，避免运行时再走“有组/无组”双轨。
    final agentId = ValueReaders.stringValue(agent['id']).trim();
    if (agentId.isEmpty) {
      return <String, Object?>{};
    }
    final groupName = ValueReaders.stringValue(agent['name'], agentId).trim();
    return <String, Object?>{
      'id': 'single_agent_$agentId',
      'name': groupName,
      'description': '由当前主智能体自动包装得到的单成员协作组。',
      'orchestration': 'main_with_children',
      'source': 'derived_single_agent_group',
      'enabled': true,
      'agents': <String>[agentId],
      'primary_agent_id': agentId,
      'metadata': <String, Object?>{
        'derived_from_single_agent': true,
        'agent_id': agentId,
      },
    };
  }

  List<JsonMap> _mergeEntriesById(
    List<JsonMap> primaryEntries,
    List<JsonMap> secondaryEntries,
  ) {
    // 中文注释: 项目内生态定义优先覆盖内置定义，让用户可以项目级定制协作骨架而不改应用内置包。
    final byId = <String, JsonMap>{};
    for (final entry in secondaryEntries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = entry;
    }
    for (final entry in primaryEntries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = entry;
    }
    return byId.values.toList(growable: false);
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    // 中文注释: 探针和上层摘要需要知道显式注入了哪些文件，因此把自动选择和计划注入路径合并后返回。
    final result = <String>[...left];
    for (final item in right) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  String _toolErrorSummary(List<Object?> executedTools) {
    // 中文注释: 工具失败摘要统一从本轮执行记录提取，避免上层再次理解底层工具返回结构。
    for (final rawTool in executedTools.reversed) {
      final tool = ValueReaders.mapValue(rawTool);
      if (ValueReaders.boolValue(tool['ok'], true)) {
        continue;
      }
      final name = ValueReaders.stringValue(tool['name'], '工具');
      final result = ValueReaders.mapValue(tool['result']);
      final error = ValueReaders.stringValue(result['error']).trim();
      if (error.isNotEmpty) {
        return '$name：$error';
      }
      return '$name 执行失败。';
    }
    return '';
  }

  String _toolRoundFingerprint(List<Object?> toolCalls) {
    // 中文注释: 工具轮指纹只用于检测完全重复的只读调用，避免模型在空转场景里无限打转。
    if (toolCalls.isEmpty) {
      return '';
    }
    final normalized = toolCalls
        .map(ValueReaders.mapValue)
        .where((call) => call.isNotEmpty)
        .map(
          (call) => <String, Object?>{
            'name': ValueReaders.stringValue(call['name']),
            'arguments': ValueReaders.deepCopyMap(
              ValueReaders.mapValue(call['arguments']),
            ),
          },
        )
        .toList(growable: false);
    return jsonEncode(normalized);
  }

  bool _isReadOnlyToolRound(List<Object?> toolCalls) {
    // 中文注释: 只有纯读取型工具的连续重复才会被拦下，避免干扰真实的多步写入流程。
    const readOnlyToolNames = <String>{
      'list_project_files',
      'read_project_file',
      'get_project_file_info',
      'search_project_files',
      'load_agent_skill',
    };
    if (toolCalls.isEmpty) {
      return false;
    }
    for (final rawCall in toolCalls) {
      final call = ValueReaders.mapValue(rawCall);
      if (!readOnlyToolNames.contains(ValueReaders.stringValue(call['name']))) {
        return false;
      }
    }
    return true;
  }

  Future<ToolExecutionRoundResult> _preloadRoutedSkills({
    required ProjectDescriptor project,
    required String policyStageNote,
    required JsonMap agent,
    required String modelId,
    required JsonMap mainContext,
    required SkillLoadMemory skillLoadMemory,
    required SkillRoutingPolicy policy,
  }) async {
    // 中文注释: 技能预加载只做阶段策略要求的摘要读取，不替模型完成后续 reference 选择。
    final preloadToolCalls = _skillRoutingPolicyService.buildPreloadToolCalls(
      policy,
      skillLoadMemory,
    );
    if (preloadToolCalls.isEmpty) {
      return const ToolExecutionRoundResult(
        executedTools: <Object?>[],
        writtenPaths: <String>[],
        changedPaths: <String>[],
        transcriptMessages: <JsonMap>[],
        waitingForUserChoice: false,
        stoppedByToolError: false,
        hadPlanTool: false,
      );
    }
    return _toolExecutionService.executeRound(
      project: project,
      assistantMessage: _skillRoutingPolicyService.buildPreloadAssistantMessage(
        policy,
        preloadToolCalls,
      )..['content'] = '根据 $policyStageNote 阶段的技能路由策略，先读取必要技能摘要。',
      toolCalls: preloadToolCalls,
      agent: agent,
      modelId: modelId,
      mainContext: mainContext,
      skillLoadMemory: skillLoadMemory,
    );
  }

  bool _shouldPreloadRoutedSkills({
    required JsonMap skillRoutingContext,
    required List<String> exposedToolIds,
  }) {
    // 中文注释: 预加载技能不能绕过宿主显式收窄的工具暴露面；必要时也允许上层直接关闭。
    if (!ValueReaders.boolValue(
      skillRoutingContext['allow_skill_preload'],
      true,
    )) {
      return false;
    }
    if (exposedToolIds.isEmpty) {
      return true;
    }
    return exposedToolIds.contains('load_agent_skill');
  }

  String _skillRoutingScopeId(
    ProjectDescriptor project,
    SkillActivationSignal routingSignal,
  ) {
    // 中文注释: 作用域 ID 只用于调试和后续扩展，不参与真实路径或业务判断。
    return '${project.id}:${routingSignal.stageId}';
  }
}
