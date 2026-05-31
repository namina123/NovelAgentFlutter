import '../agents/agent_tool_message_service.dart';
import '../agents/agent_tool_round_state_service.dart';
import '../agents/skill_load_memory.dart';
import '../agents/skill_load_memory_service.dart';
import '../agents/sub_agent_execution_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../ports/tool_execution_port.dart';
import '../project/project_descriptor.dart';
import 'tool_execution_round_result.dart';

class ToolExecutionService {
  ToolExecutionService({
    required ToolExecutionPort toolExecutionPort,
    AgentToolMessageService? agentToolMessageService,
    AgentToolRoundStateService? agentToolRoundStateService,
    SkillLoadMemoryService? skillLoadMemoryService,
    SubAgentExecutionService? subAgentExecutionService,
  }) : _toolExecutionPort = toolExecutionPort,
       _agentToolMessageService =
           agentToolMessageService ?? AgentToolMessageService(),
       _agentToolRoundStateService =
           agentToolRoundStateService ?? AgentToolRoundStateService(),
       _skillLoadMemoryService =
           skillLoadMemoryService ?? const SkillLoadMemoryService(),
       _subAgentExecutionService = subAgentExecutionService;

  final ToolExecutionPort _toolExecutionPort;
  final AgentToolMessageService _agentToolMessageService;
  final AgentToolRoundStateService _agentToolRoundStateService;
  final SkillLoadMemoryService _skillLoadMemoryService;
  final SubAgentExecutionService? _subAgentExecutionService;

  Future<ToolExecutionRoundResult> executeRound({
    required ProjectDescriptor project,
    required JsonMap assistantMessage,
    required List<Object?> toolCalls,
    JsonMap agent = const <String, Object?>{},
    String modelId = '',
    JsonMap mainContext = const <String, Object?>{},
    SkillLoadMemory? skillLoadMemory,
  }) async {
    // 中文注释: 工具轮执行服务统一收口一轮工具调用的执行、副作用回收和转录消息拼装。
    final toolRoundState = _agentToolRoundStateService.toolRoundState(
      toolCalls,
    );
    final executedTools = <Object?>[];
    final writtenPaths = <String>[];
    final changedPaths = <String>[];
    final transcriptMessages = <JsonMap>[assistantMessage];
    var waitingForUserChoice = false;
    var stoppedByToolError = false;
    for (final rawCall in toolCalls) {
      final call = _enrichToolCallWithContext(
        ValueReaders.mapValue(rawCall),
        mainContext,
      );
      final result =
          _duplicateSkillLoadResult(call, skillLoadMemory) ??
          await _executeToolCall(
            project: project,
            call: call,
            agent: agent,
            modelId: modelId,
            mainContext: mainContext,
          );
      if (skillLoadMemory != null) {
        _skillLoadMemoryService.recordCallResult(call, result, skillLoadMemory);
      }
      executedTools.add(<String, Object?>{
        'id': call['id'],
        'name': call['name'],
        'arguments': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(call['arguments']),
        ),
        'result': ValueReaders.deepCopyMap(result),
        'ok': ValueReaders.boolValue(result['ok'], true),
        'not_executed': ValueReaders.boolValue(result['not_executed']),
      });
      for (final rawPath in ValueReaders.stringList(result['changed_paths'])) {
        if (!changedPaths.contains(rawPath)) {
          changedPaths.add(rawPath);
        }
      }
      final relativePath = ValueReaders.stringValue(
        result['relative_path'],
      ).trim();
      if (_shouldRecordWrittenPath(call, result, relativePath) &&
          !writtenPaths.contains(relativePath)) {
        writtenPaths.add(relativePath);
      }
      waitingForUserChoice =
          waitingForUserChoice ||
          ValueReaders.boolValue(result['waiting_for_user_choice']);
      final isHardToolError =
          !ValueReaders.boolValue(result['ok'], true) &&
          !ValueReaders.boolValue(result['not_executed']);
      if (isHardToolError) {
        stoppedByToolError = true;
      }
      transcriptMessages.add(
        _agentToolMessageService.toolResultMessage(call, result),
      );
    }
    return ToolExecutionRoundResult(
      executedTools: executedTools,
      writtenPaths: writtenPaths,
      changedPaths: changedPaths,
      transcriptMessages: transcriptMessages,
      waitingForUserChoice: waitingForUserChoice,
      stoppedByToolError: stoppedByToolError,
      hadPlanTool: ValueReaders.boolValue(toolRoundState['has_plan_tool']),
    );
  }

  JsonMap? _duplicateSkillLoadResult(
    JsonMap call,
    SkillLoadMemory? skillLoadMemory,
  ) {
    // 中文注释: 技能读取去重放在执行层统一判断，避免调用方自己维护一套重复加载规则。
    if (skillLoadMemory == null) {
      return null;
    }
    if (!_skillLoadMemoryService.isDuplicateCall(call, skillLoadMemory)) {
      return null;
    }
    return _skillLoadMemoryService.duplicateResult(call, skillLoadMemory);
  }

  JsonMap _enrichToolCallWithContext(JsonMap call, JsonMap mainContext) {
    // 中文注释: 某些模型会在“读取当前打开文件”时把 relative_path 丢成空对象，这里用宿主已知活动文档做最小兜底。
    final toolName = ValueReaders.stringValue(call['name']);
    if (!const <String>{
      'read_project_file',
      'get_project_file_info',
      'edit_project_file',
    }.contains(toolName)) {
      return call;
    }
    final arguments = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(call['arguments']),
    );
    if (ValueReaders.stringValue(
      arguments['relative_path'],
    ).trim().isNotEmpty) {
      return call;
    }
    final activeDocumentPath = ValueReaders.stringValue(
      mainContext['active_document_path'],
    ).trim();
    if (activeDocumentPath.isEmpty) {
      return call;
    }
    return ValueReaders.deepCopyMap(call)
      ..['arguments'] = <String, Object?>{
        ...arguments,
        'relative_path': activeDocumentPath,
      };
  }

  bool _shouldRecordWrittenPath(
    JsonMap call,
    JsonMap result,
    String relativePath,
  ) {
    // 中文注释: 写入路径判断集中在这里，避免用例层散落一串工具名和 changed_paths 规则。
    if (relativePath.isEmpty || !ValueReaders.boolValue(result['ok'], true)) {
      return false;
    }
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.contains(relativePath)) {
      return true;
    }
    return const <String>{
      'write_project_file',
      'create_project_entry',
      'move_project_file',
      'rename_project_file',
      'edit_project_file',
      'manipulate_project_file_lines',
      'update_world_state',
      'update_character_state',
      'update_foreshadow_state',
      'update_timeline_state',
      'update_relationship_state',
      'summarize_context',
      'run_continuity_check',
      'create_chapter_task',
      'mark_task_status',
      'restore_backup',
    }.contains(ValueReaders.stringValue(call['name']));
  }

  Future<JsonMap> _executeToolCall({
    required ProjectDescriptor project,
    required JsonMap call,
    required JsonMap agent,
    required String modelId,
    required JsonMap mainContext,
  }) {
    // 中文注释: 特殊工具在这里走专门运行服务，其余工具继续委托给宿主端口。
    final toolName = ValueReaders.stringValue(call['name']);
    if (toolName == 'call_sub_agent' && _subAgentExecutionService != null) {
      return _subAgentExecutionService.execute(
        project: project,
        parentAgent: agent,
        toolCall: call,
        modelId: modelId,
        mainContext: mainContext,
      );
    }
    if (toolName == 'load_agent_skill') {
      final enrichedArguments = ValueReaders.deepCopyMap(
        ValueReaders.mapValue(call['arguments']),
      )..['_agent'] = ValueReaders.deepCopyMap(agent);
      final enrichedCall = ValueReaders.deepCopyMap(call)
        ..['arguments'] = enrichedArguments;
      return _toolExecutionPort.execute(
        project: project,
        toolCall: enrichedCall,
      );
    }
    return _toolExecutionPort.execute(project: project, toolCall: call);
  }
}
