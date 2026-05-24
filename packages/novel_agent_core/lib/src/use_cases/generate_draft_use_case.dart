import '../agents/agent_collaboration_brief_service.dart';
import '../agents/builtin_collaborator_catalog_service.dart';
import '../agents/agent_profile_catalog_service.dart';
import '../agents/agent_loop_contract_service.dart';
import '../agents/agent_tool_message_service.dart';
import '../agents/agent_tool_policy_service.dart';
import '../agents/sub_agent_execution_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../context/context_assembler_service.dart';
import '../ports/llm_gateway.dart';
import '../ports/tool_execution_port.dart';
import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_prompt_contract.dart';
import '../runtime/draft_generation_result.dart';
import '../runtime/draft_prompt_builder_service.dart';
import '../runtime/project_context_file_selection_service.dart';
import '../runtime/tool_execution_service.dart';
import '../tools/tool_call_parser_service.dart';
import '../tools/tool_schema_builder_service.dart';
import '../tools/tool_strategy_prompt_builder.dart';
import '../tools/tool_strategy_service.dart';

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
    ToolExecutionService? toolExecutionService,
    BuiltinCollaboratorCatalogService? collaboratorCatalogService,
    AgentCollaborationBriefService? collaborationBriefService,
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
       _toolCallParserService =
           toolCallParserService ?? ToolCallParserService(),
       _toolSchemaBuilderService =
           toolSchemaBuilderService ?? ToolSchemaBuilderService(),
       _agentLoopContractService =
           agentLoopContractService ?? AgentLoopContractService(),
       _agentToolPolicyService =
           agentToolPolicyService ?? AgentToolPolicyService(),
       _toolExecutionService =
           toolExecutionService ??
           ToolExecutionService(
             toolExecutionPort: toolExecutionPort,
             agentToolMessageService:
                 agentToolMessageService ?? AgentToolMessageService(),
             subAgentExecutionService: SubAgentExecutionService(
               llmGateway: llmGateway,
               toolExecutionPort: toolExecutionPort,
               loadAvailableAgents: loadAvailableAgents,
               loadAvailableGroups: loadAvailableAgentGroups,
             ),
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
  final ToolCallParserService _toolCallParserService;
  final ToolSchemaBuilderService _toolSchemaBuilderService;
  final AgentLoopContractService _agentLoopContractService;
  final AgentToolPolicyService _agentToolPolicyService;
  final ToolExecutionService _toolExecutionService;
  final ToolStrategyPromptBuilder _toolStrategyPromptBuilder;

  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    String sessionContext = '',
  }) async {
    // 中文注释: 这里负责把项目文件、上下文组装和模型调用收束成一次共享草稿生成流程。
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError.value(userPrompt, 'userPrompt', '提示词不能为空。');
    }
    final entries = await _projectWorkspacePort.listEntries(project.rootPath);
    final selectedPaths = _fileSelectionService.select(entries);
    final fileContents = <String, Object?>{};
    for (final path in selectedPaths) {
      final content = await _projectWorkspacePort.readTextFile(
        project.rootPath,
        path,
      );
      if (content == null || content.trim().isEmpty) {
        continue;
      }
      fileContents[path] = _trimContent(content);
    }
    final projectInfo = <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
      'stage': 'draft',
    };
    final resolvedAgent = agent.isEmpty
        ? _agentProfileCatalogService.fallbackDefaultAgent()
        : ValueReaders.deepCopyMap(agent);
    final optionalAgents = _mergeEntriesById(
      await _loadAvailableAgentsSafe(project),
      _collaboratorCatalogService.optionalCollaboratorProfiles(),
    );
    final optionalGroups = _mergeEntriesById(
      await _loadAvailableAgentGroupsSafe(project),
      _collaboratorCatalogService.optionalCollaboratorGroups(),
    );
    final contextPack = _contextAssemblerService.assemble(<String, Object?>{
      'project': projectInfo,
      'project_files': entries,
      'project_file_contents': fileContents,
      'user_prompt': cleanPrompt,
      'session_context': sessionContext,
      'intent': intent,
      'agent': resolvedAgent,
      'optional_agents': optionalAgents,
    });
    final prompt = _draftPromptBuilderService.build(
      project: projectInfo,
      agent: resolvedAgent,
      contextPack: contextPack,
      userPrompt: cleanPrompt,
      title: title,
      intent: intent,
    );
    final toolSettings = _toolStrategyService.defaultSettings();
    final enabledToolIds = _toolStrategyService.enabledToolIds(toolSettings);
    final toolSchemas = _toolSchemaBuilderService.buildOpenAiSchemas(
      enabledToolIds,
    );
    final collaborationGroup = optionalGroups.isEmpty
        ? <String, Object?>{}
        : optionalGroups.first;
    final collaborationBrief = collaborationGroup.isEmpty
        ? ''
        : _collaborationBriefService.collaborationBrief(
            collaborationGroup,
            optionalAgents,
          );
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
      styleNote: '当前请求已经附带上下文包；如需更多文件，请调用项目工具按需读取。',
    );
    final messages = <JsonMap>[
      <String, Object?>{'role': 'system', 'content': systemPrompt},
      <String, Object?>{'role': 'user', 'content': prompt},
    ];
    final executedTools = <Object?>[];
    final writtenPaths = <String>[];
    final changedPaths = <String>[];
    var finalContent = '';
    var waitingForUserChoice = false;
    var stoppedByToolError = false;
    var previousRoundHadPlanTool = false;
    var planContinueRetryUsed = false;
    for (var roundIndex = 0; roundIndex < 8; roundIndex++) {
      final llmResult = await _llmGateway.requestChat(
        messages: messages,
        modelId: modelId,
        tools: toolSchemas,
      );
      final toolCalls = _toolCallParserService.parseToolCalls(
        llmResult,
        allowInlineFallback: ValueReaders.boolValue(
          toolSettings['allow_inline_fallback'],
          true,
        ),
      );
      final contract = _agentLoopContractService.loopStepContract(
        llmResult,
        toolCalls,
        roundIndex: roundIndex,
        maxRounds: 8,
        waitingForUserChoice: waitingForUserChoice,
        stoppedByToolError: stoppedByToolError,
      );
      final action = ValueReaders.stringValue(contract['action']);
      if (action == 'execute_tools') {
        final toolRound = await _toolExecutionService.executeRound(
          project: project,
          assistantMessage: ValueReaders.mapValue(
            contract['assistant_message'],
          ),
          toolCalls: ValueReaders.objectList(contract['tool_calls']),
          agent: resolvedAgent,
          modelId: modelId,
          mainContext: <String, Object?>{
            'intent': intent,
            'project_title': project.name,
            'project_tree_note': _projectPromptContract.projectTreeSummary(
              entries,
            ),
            'style_note': '当前请求已经附带上下文包；如需更多文件，请调用项目工具按需读取。',
          },
        );
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
        if (stoppedByToolError || waitingForUserChoice) {
          break;
        }
        continue;
      }
      final content = ValueReaders.stringValue(llmResult['content']).trim();
      if (previousRoundHadPlanTool) {
        final afterPlan = _agentToolPolicyService.afterToolRoundDecision(
          llmResult,
          roundHasPlanTool: previousRoundHadPlanTool,
          planContinueRetryUsed: planContinueRetryUsed,
        );
        if (ValueReaders.boolValue(afterPlan['retry_after_plan']) &&
            content.isEmpty) {
          planContinueRetryUsed = true;
          messages.add(<String, Object?>{
            'role': 'user',
            'content': ValueReaders.stringValue(
              afterPlan['continue_instruction'],
            ),
          });
          previousRoundHadPlanTool = false;
          continue;
        }
      }
      finalContent = content;
      break;
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
      selectedPaths: selectedPaths,
      executedTools: executedTools,
      writtenPaths: writtenPaths,
      changedPaths: changedPaths,
      transcriptMessages: messages,
      waitingForUserChoice: waitingForUserChoice,
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
}
