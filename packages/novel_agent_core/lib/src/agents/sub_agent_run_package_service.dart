import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_delegation_plan_service.dart';
import 'agent_member_directory_service.dart';
import 'agent_selection_service.dart';
import 'agent_string_list_service.dart';
import 'agent_task_brief_service.dart';
import 'sub_agent_message_builder_service.dart';

class SubAgentRunPackageService {
  SubAgentRunPackageService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentSelectionService? selectionService,
    AgentStringListService? stringListService,
    AgentTaskBriefService? taskBriefService,
    AgentDelegationPlanService? delegationPlanService,
    SubAgentMessageBuilderService? messageBuilderService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _selectionService = selectionService ?? AgentSelectionService(),
       _stringListService = stringListService ?? AgentStringListService(),
       _taskBriefService = taskBriefService ?? AgentTaskBriefService(),
       _delegationPlanService =
           delegationPlanService ?? AgentDelegationPlanService(),
       _messageBuilderService =
           messageBuilderService ?? SubAgentMessageBuilderService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentSelectionService _selectionService;
  final AgentStringListService _stringListService;
  final AgentTaskBriefService _taskBriefService;
  final AgentDelegationPlanService _delegationPlanService;
  final SubAgentMessageBuilderService _messageBuilderService;

  JsonMap buildSubAgentRunPackage(
    JsonMap agentGroup,
    List<Object?> availableAgents,
    JsonMap arguments, {
    JsonMap mainContext = const <String, Object?>{},
    String? createdAt,
  }) {
    // 中文注释: 运行包是 GUI/CLI 共用的宿主合同，因此这里只组装数据，不做实际模型调用。
    if (agentGroup.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'Agent group is empty.'};
    }
    final task = _argumentText(arguments, const <String>['task', 'query']);
    if (task.isEmpty) {
      return <String, Object?>{'ok': false, 'error': 'task is required.'};
    }

    final child = _selectChildAgent(agentGroup, availableAgents, arguments);
    if (child.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'No usable child agent in group.',
        'available_children': <Object?>[],
      };
    }

    final continueSessionId = _argumentText(arguments, const <String>[
      'continue_session_id',
      'continueSessionId',
    ]);
    final subSessionId = continueSessionId.isNotEmpty
        ? continueSessionId
        : 'sub_${ValueReaders.stringValue(child['id'], 'agent')}_${DateTime.now().microsecondsSinceEpoch}';
    final intent = ValueReaders.stringValue(
      mainContext['intent'],
      _argumentText(arguments, const <String>['intent'], fallback: 'draft'),
    ).trim();
    final constraints = _stringListService.normalize(arguments['constraints']);
    final sourcePaths = _stringListService.normalize(
      arguments['source_paths'] ?? arguments['sourcePaths'],
    );
    final expectedOutput = _argumentText(arguments, const <String>[
      'expected_output',
      'expectedOutput',
    ], fallback: _taskBriefService.expectedOutputForAgent(child, intent));

    final request = <String, Object?>{
      'intent': intent,
      'task_excerpt': _argumentText(arguments, const <String>[
        'context_excerpt',
        'contextExcerpt',
        'task_excerpt',
        'taskExcerpt',
      ], fallback: task),
      'constraints': constraints,
    };
    final singleGroup = <String, Object?>{
      ...agentGroup,
      'agents': <String>[ValueReaders.stringValue(child['id'])],
    };
    final plan = _delegationPlanService.buildDelegationPlan(
      singleGroup,
      availableAgents,
      request: request,
      createdAt: createdAt,
    );
    final tasks = ValueReaders.mapList(plan['tasks']);
    final delegation = tasks.isNotEmpty
        ? ValueReaders.deepCopyMap(tasks.first)
        : <String, Object?>{};
    delegation['task'] = task;
    delegation['source_paths'] = sourcePaths;
    delegation['expected_output'] = expectedOutput;

    final blockedTools = _stringListService.normalize(
      arguments['blocked_tools'],
    );
    if (!blockedTools.contains('call_sub_agent')) {
      blockedTools.add('call_sub_agent');
    }
    if (!blockedTools.contains('present_user_options')) {
      blockedTools.add('present_user_options');
    }

    return <String, Object?>{
      'ok': true,
      'interaction_type': 'sub_agent_run_package',
      'strategy': 'main_with_children',
      'group_id': ValueReaders.stringValue(agentGroup['id']),
      'group_name': ValueReaders.stringValue(agentGroup['name']),
      'agent_id': ValueReaders.stringValue(child['id']),
      'agent_name': ValueReaders.stringValue(
        child['name'],
        ValueReaders.stringValue(child['id']),
      ),
      'agent': ValueReaders.deepCopyMap(child),
      'sub_session_id': subSessionId,
      'continue_session_id': continueSessionId,
      'task': task,
      'expected_output': expectedOutput,
      'delegation': delegation,
      'messages': <Object?>[
        <String, Object?>{
          'role': 'system',
          'content': _messageBuilderService.childSystemPrompt(
            child,
            agentGroup,
            arguments,
            mainContext,
          ),
        },
        <String, Object?>{
          'role': 'system',
          'content': _messageBuilderService.childStructureMessage(
            agentGroup,
            arguments,
            mainContext,
          ),
        },
        <String, Object?>{
          'role': 'user',
          'content': _messageBuilderService.childUserMessage(arguments),
        },
      ],
      'tool_scope': <String, Object?>{
        'agent_id': ValueReaders.stringValue(child['id']),
        'skills': _stringListService.normalize(child['skills']),
        'skill_groups': _stringListService.normalize(child['skill_groups']),
        'blocked_tools': blockedTools,
        'reason': '子智能体可以调用自己范围内的项目工具，但不能递归委派子智能体，也不能直接向用户提问。',
      },
      'context_policy': <String, Object?>{
        'mode': 'main_with_children',
        'include_full_main_conversation': false,
        'include_parent_messages': false,
        'include_project_structure': true,
        'description': '子智能体只接收主智能体整理的任务、摘录、结构信息和必要路径，不接收完整主会话。',
      },
      'source_paths': sourcePaths,
      'execution': <String, Object?>{
        'strategy': 'main_with_children',
        'run_model': true,
        'return_to_main_agent': true,
        'max_tool_rounds': ValueReaders.intValue(
          mainContext['sub_agent_max_tool_rounds'],
          2,
        ),
        'visibility': 'internal_runtime_only',
      },
      'response_contract': '返回给主智能体的内容应是可合并结论、风险、建议或草稿片段；不要要求用户直接回答子智能体。',
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  JsonMap _selectChildAgent(
    JsonMap agentGroup,
    List<Object?> availableAgents,
    JsonMap arguments,
  ) {
    // 中文注释: 先尊重显式指定的 agent_id，再退回规则选人，最后才用第一候选兜底。
    final candidates = _memberDirectoryService.agentsInGroup(
      agentGroup,
      availableAgents,
    );
    final byId = _memberDirectoryService.agentsById(candidates);
    final requestedId = _argumentText(arguments, const <String>[
      'agent_id',
      'agentId',
      'target_agent_id',
      'targetAgentId',
    ]);
    if (requestedId.isNotEmpty && byId.containsKey(requestedId)) {
      return ValueReaders.mapValue(byId[requestedId]);
    }
    final task = _argumentText(arguments, const <String>['task', 'query']);
    final selectedId = _selectionService.selectAgentIdForTask(task, candidates);
    if (selectedId.isNotEmpty && byId.containsKey(selectedId)) {
      return ValueReaders.mapValue(byId[selectedId]);
    }
    return candidates.isEmpty
        ? <String, Object?>{}
        : ValueReaders.deepCopyMap(candidates.first);
  }

  String _argumentText(
    JsonMap arguments,
    List<String> keys, {
    String fallback = '',
  }) {
    // 中文注释: 字段兼容读取集中放这里，避免运行包服务里散落大量命名分支。
    for (final key in keys) {
      final value = ValueReaders.stringValue(arguments[key]).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}
