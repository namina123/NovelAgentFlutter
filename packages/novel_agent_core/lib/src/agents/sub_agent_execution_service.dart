import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../common/host_platform.dart';
import '../llm/chat_request.dart';
import '../ports/llm_gateway.dart';
import '../ports/tool_execution_port.dart';
import '../project/project_descriptor.dart';
import '../tools/tool_call_parser_service.dart';
import '../tools/tool_exposure_policy_service.dart';
import '../tools/tool_event_presenter_service.dart';
import '../tools/tool_schema_builder_service.dart';
import '../tools/tool_strategy_service.dart';
import 'agent_loop_contract_service.dart';
import 'agent_tool_message_service.dart';
import 'agent_tool_policy_service.dart';
import 'builtin_collaborator_catalog_service.dart';
import 'sub_agent_group_selection_service.dart';
import 'sub_agent_result_package_service.dart';
import 'sub_agent_run_package_service.dart';

class SubAgentExecutionService {
  SubAgentExecutionService({
    required LlmGateway llmGateway,
    required ToolExecutionPort toolExecutionPort,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableAgents,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableGroups,
    SubAgentRunPackageService? runPackageService,
    SubAgentResultPackageService? resultPackageService,
    BuiltinCollaboratorCatalogService? collaboratorCatalogService,
    SubAgentGroupSelectionService? groupSelectionService,
    ToolStrategyService? toolStrategyService,
    ToolSchemaBuilderService? toolSchemaBuilderService,
    ToolCallParserService? toolCallParserService,
    AgentLoopContractService? agentLoopContractService,
    AgentToolMessageService? agentToolMessageService,
    AgentToolPolicyService? agentToolPolicyService,
    ToolEventPresenterService? toolEventPresenterService,
    ToolExposurePolicyService? toolExposurePolicyService,
    HostPlatform hostPlatform = HostPlatform.unknown,
  }) : _llmGateway = llmGateway,
       _toolExecutionPort = toolExecutionPort,
       _loadAvailableAgents = loadAvailableAgents,
       _loadAvailableGroups = loadAvailableGroups,
       _runPackageService = runPackageService ?? SubAgentRunPackageService(),
       _resultPackageService =
           resultPackageService ?? SubAgentResultPackageService(),
       _collaboratorCatalogService =
           collaboratorCatalogService ?? BuiltinCollaboratorCatalogService(),
       _groupSelectionService =
           groupSelectionService ?? SubAgentGroupSelectionService(),
       _toolStrategyService = toolStrategyService ?? ToolStrategyService(),
       _toolExposurePolicyService =
           toolExposurePolicyService ?? const ToolExposurePolicyService(),
       _hostPlatform = hostPlatform,
       _toolSchemaBuilderService =
           toolSchemaBuilderService ?? ToolSchemaBuilderService(),
       _toolCallParserService =
           toolCallParserService ?? ToolCallParserService(),
       _agentLoopContractService =
           agentLoopContractService ?? AgentLoopContractService(),
       _agentToolMessageService =
           agentToolMessageService ?? AgentToolMessageService(),
       _agentToolPolicyService =
           agentToolPolicyService ?? AgentToolPolicyService(),
       _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService();

  final LlmGateway _llmGateway;
  final ToolExecutionPort _toolExecutionPort;
  final Future<List<JsonMap>> Function(ProjectDescriptor project)?
  _loadAvailableAgents;
  final Future<List<JsonMap>> Function(ProjectDescriptor project)?
  _loadAvailableGroups;
  final SubAgentRunPackageService _runPackageService;
  final SubAgentResultPackageService _resultPackageService;
  final BuiltinCollaboratorCatalogService _collaboratorCatalogService;
  final SubAgentGroupSelectionService _groupSelectionService;
  final ToolStrategyService _toolStrategyService;
  final ToolExposurePolicyService _toolExposurePolicyService;
  final HostPlatform _hostPlatform;
  final ToolSchemaBuilderService _toolSchemaBuilderService;
  final ToolCallParserService _toolCallParserService;
  final AgentLoopContractService _agentLoopContractService;
  final AgentToolMessageService _agentToolMessageService;
  final AgentToolPolicyService _agentToolPolicyService;
  final ToolEventPresenterService _toolEventPresenterService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap parentAgent,
    required JsonMap toolCall,
    required String modelId,
    required JsonMap mainContext,
  }) async {
    // 中文注释: 子智能体执行服务只负责一次内部子回合的包构建、模型调用和结果回收，不直接碰宿主 UI。
    final arguments = ValueReaders.mapValue(toolCall['arguments']);
    final availableAgents = _mergeEntriesById(
      await _loadAvailableAgentsSafe(project),
      _collaboratorCatalogService.optionalCollaboratorProfiles(),
    );
    final availableGroups = _mergeEntriesById(
      await _loadAvailableGroupsSafe(project),
      _collaboratorCatalogService.optionalCollaboratorGroups(),
    );
    final task = ValueReaders.stringValue(
      arguments['task'],
      ValueReaders.stringValue(arguments['query']),
    ).trim();
    final group = _groupSelectionService.selectGroup(
      parentAgent: parentAgent,
      task: task,
      availableGroups: availableGroups,
    );
    final package = _runPackageService.buildSubAgentRunPackage(
      group,
      availableAgents,
      arguments,
      mainContext: <String, Object?>{
        ...mainContext,
        'intent': ValueReaders.stringValue(mainContext['intent'], 'draft'),
        'project_title': project.name,
      },
    );
    if (!ValueReaders.boolValue(package['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          package['error'],
          'Sub-agent package build failed.',
        ),
        'not_executed': true,
        'available_agents': availableAgents,
      };
    }

    final subSessionId = ValueReaders.stringValue(package['sub_session_id']);
    final runId = subSessionId.isEmpty
        ? 'sub_${DateTime.now().microsecondsSinceEpoch}'
        : subSessionId;
    final events = <Object?>[
      _subAgentEvent(
        package,
        phase: 'started',
        summary: '子智能体开始执行，主智能体正在等待结果。',
        runId: runId,
      ),
    ];

    final toolSettings = _toolStrategyService.defaultSettings();
    final blockedTools = ValueReaders.stringList(
      ValueReaders.mapValue(package['tool_scope'])['blocked_tools'],
    );
    final childToolIds = _toolStrategyService
        .enabledToolIds(toolSettings)
        .where((toolId) => !blockedTools.contains(toolId))
        .toList(growable: false);
    final exposedChildToolIds = _toolExposurePolicyService.filterExposedToolIds(
      childToolIds,
      hostPlatform: _hostPlatform,
      projectType: project.projectType,
      isSubAgent: true,
    );
    final toolSchemas = _toolSchemaBuilderService.buildOpenAiSchemas(
      exposedChildToolIds,
    );
    final messages = ValueReaders.mapList(
      package['messages'],
    ).toList(growable: true);
    final executedTools = <Object?>[];
    var finalContent = '';
    var waitingForUserChoice = false;
    var stoppedByToolError = false;
    var previousRoundHadPlanTool = false;
    var planContinueRetryUsed = false;
    final maxRounds = ValueReaders.intValue(
      ValueReaders.mapValue(package['execution'])['max_tool_rounds'],
      2,
    ).clamp(1, 6);

    for (var roundIndex = 0; roundIndex < maxRounds; roundIndex += 1) {
      final llmResult = await _llmGateway.requestChat(
        request: ChatRequest(
          modelId: modelId,
          messages: messages,
          tools: toolSchemas,
          options: <String, Object?>{
            'stream_scope': 'sub_agent',
            'sub_session_id': subSessionId,
          },
        ),
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
        maxRounds: maxRounds,
        waitingForUserChoice: waitingForUserChoice,
        stoppedByToolError: stoppedByToolError,
      );
      final action = ValueReaders.stringValue(contract['action']);
      if (action == 'execute_tools') {
        previousRoundHadPlanTool =
            ValueReaders.objectList(contract['tool_calls'])
                .map(ValueReaders.mapValue)
                .any(
                  (call) =>
                      ValueReaders.stringValue(call['name']) ==
                      'set_agent_tasks',
                );
        messages.add(ValueReaders.mapValue(contract['assistant_message']));
        for (final rawCall in ValueReaders.objectList(contract['tool_calls'])) {
          final call = ValueReaders.mapValue(rawCall);
          final toolName = ValueReaders.stringValue(call['name']);
          final result = blockedTools.contains(toolName)
              ? _blockedToolResult(toolName)
              : await _executeChildTool(
                  project: project,
                  toolCall: call,
                  childAgent: ValueReaders.mapValue(package['agent']),
                );
          final executedTool = <String, Object?>{
            'id': call['id'],
            'name': toolName,
            'arguments': ValueReaders.deepCopyMap(
              ValueReaders.mapValue(call['arguments']),
            ),
            'result': ValueReaders.deepCopyMap(result),
            'ok': ValueReaders.boolValue(result['ok'], true),
          };
          executedTools.add(executedTool);
          events.add(
            _subAgentEvent(
              package,
              phase: 'tool_event',
              summary: _toolEventPresenterService.textForExecutedTool(
                executedTool,
              ),
              runId: runId,
              extra: <String, Object?>{
                'tool_event': <String, Object?>{
                  'phase': ValueReaders.boolValue(result['ok'], true)
                      ? 'finished'
                      : 'failed',
                  'name': toolName,
                  'ok': ValueReaders.boolValue(result['ok'], true),
                  'arguments': ValueReaders.deepCopyMap(
                    ValueReaders.mapValue(call['arguments']),
                  ),
                  'result': ValueReaders.deepCopyMap(result),
                },
              },
            ),
          );
          waitingForUserChoice =
              waitingForUserChoice ||
              ValueReaders.boolValue(result['waiting_for_user_choice']);
          final isHardToolError =
              !ValueReaders.boolValue(result['ok'], true) &&
              !ValueReaders.boolValue(result['not_executed']);
          if (isHardToolError) {
            stoppedByToolError = true;
          }
          messages.add(
            _agentToolMessageService.toolResultMessage(call, result),
          );
        }
        if (waitingForUserChoice || stoppedByToolError) {
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

    final resolvedContent = _resultPackageService.subAgentFinalContent(
      finalContent,
      stoppedByToolError: stoppedByToolError,
    );
    if (waitingForUserChoice) {
      final failure = _resultPackageService.subAgentFailureResultPackage(
        package: package,
        errorDetail: 'Sub-agent requested user choice, which is not allowed.',
        executedTools: executedTools,
        cancelled: false,
      );
      events.add(
        _subAgentEvent(
          package,
          phase: 'failed',
          summary: '子智能体需要直接向用户提问，已终止并返回主智能体处理。',
          runId: runId,
        ),
      );
      return <String, Object?>{
        ...failure,
        'sub_agent_run_id': runId,
        'sub_agent_events': events,
      };
    }

    final success = _resultPackageService.subAgentSuccessResultPackage(
      package: package,
      task: task,
      content: resolvedContent,
      llmResult: <String, Object?>{'reasoning_content': ''},
      executedTools: executedTools,
    );
    events.add(
      _subAgentEvent(
        package,
        phase: stoppedByToolError ? 'failed' : 'finished',
        summary: stoppedByToolError
            ? '子智能体工具执行后未完成理想输出，已返回可合并结果。'
            : '子智能体已返回结果。',
        runId: runId,
        extra: <String, Object?>{
          'content': resolvedContent,
          'tool_count': executedTools.length,
        },
      ),
    );
    return <String, Object?>{
      ...success,
      'ok': !stoppedByToolError || resolvedContent.trim().isNotEmpty,
      'sub_agent_run_id': runId,
      'sub_agent_events': events,
      'tool_count': executedTools.length,
      'summary': ValueReaders.stringValue(success['summary'], '子智能体已返回。'),
    };
  }

  JsonMap _blockedToolResult(String toolName) {
    // 中文注释: 子智能体越权调用被禁止工具时，返回稳定错误结果供主智能体自行恢复。
    return <String, Object?>{
      'ok': false,
      'error': 'Blocked sub-agent tool: $toolName',
      'not_executed': false,
    };
  }

  Future<JsonMap> _executeChildTool({
    required ProjectDescriptor project,
    required JsonMap toolCall,
    required JsonMap childAgent,
  }) {
    // 中文注释: 子智能体读取技能时也要带上当前子智能体上下文，避免执行器回退到默认智能体。
    if (ValueReaders.stringValue(toolCall['name']) != 'load_agent_skill') {
      return _toolExecutionPort.execute(project: project, toolCall: toolCall);
    }
    final enrichedArguments = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(toolCall['arguments']),
    )..['_agent'] = ValueReaders.deepCopyMap(childAgent);
    final enrichedCall = ValueReaders.deepCopyMap(toolCall)
      ..['arguments'] = enrichedArguments;
    return _toolExecutionPort.execute(project: project, toolCall: enrichedCall);
  }

  Future<List<JsonMap>> _loadAvailableAgentsSafe(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目级协作智能体加载失败时回退为空，保证运行时仍可使用内置协作素材。
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

  Future<List<JsonMap>> _loadAvailableGroupsSafe(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 项目级智能体组属于增强能力，读取失败不应该让整个草稿生成链中断。
    final loader = _loadAvailableGroups;
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
    // 中文注释: 项目内定义优先覆盖内置同名条目，保证用户可在项目范围内替换协作角色与协作组。
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

  JsonMap _subAgentEvent(
    JsonMap package, {
    required String phase,
    required String summary,
    required String runId,
    JsonMap extra = const <String, Object?>{},
  }) {
    // 中文注释: 子智能体事件统一带齐运行标识和视角信息，方便 GUI/CLI 直接回放。
    return <String, Object?>{
      'id': 'sub_agent_event_${DateTime.now().microsecondsSinceEpoch}',
      'phase': phase,
      'summary': summary,
      'stream_scope': 'sub_agent',
      'sub_agent_run_id': runId,
      'sub_session_id': ValueReaders.stringValue(package['sub_session_id']),
      'sub_agent_id': ValueReaders.stringValue(package['agent_id']),
      'sub_agent_name': ValueReaders.stringValue(
        package['agent_name'],
        ValueReaders.stringValue(package['agent_id'], '子智能体'),
      ),
      'task': ValueReaders.stringValue(package['task']),
      ...ValueReaders.deepCopyMap(extra),
    };
  }
}
