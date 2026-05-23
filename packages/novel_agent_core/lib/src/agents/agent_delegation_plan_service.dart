import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_member_directory_service.dart';
import 'agent_string_list_service.dart';
import 'agent_task_brief_service.dart';

class AgentDelegationPlanService {
  AgentDelegationPlanService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentStringListService? stringListService,
    AgentTaskBriefService? taskBriefService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _stringListService = stringListService ?? AgentStringListService(),
       _taskBriefService = taskBriefService ?? AgentTaskBriefService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentStringListService _stringListService;
  final AgentTaskBriefService _taskBriefService;

  JsonMap buildDelegationPlan(
    JsonMap agentGroup,
    List<Object?> availableAgents, {
    JsonMap request = const <String, Object?>{},
    String? createdAt,
  }) {
    // 中文注释: 这里仅生成可审计委派计划，不直接调用模型，也不接触真实工具执行。
    if (agentGroup.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Agent group is empty.',
        'tasks': <Object?>[],
      };
    }
    final byId = _memberDirectoryService.agentsById(availableAgents);
    final warnings = <String>[];
    final tasks = <JsonMap>[];
    final groupAgents = _stringListService.normalize(agentGroup['agents']);
    if (groupAgents.isEmpty) {
      warnings.add('智能体组没有配置成员。');
    }
    for (final agentId in groupAgents) {
      final agent = ValueReaders.mapValue(byId[agentId]);
      if (agent.isEmpty) {
        warnings.add('找不到智能体：$agentId');
        continue;
      }
      tasks.add(_delegationTask(agent, request, tasks.length));
    }

    return <String, Object?>{
      'ok': warnings.isEmpty || tasks.isNotEmpty,
      'error': warnings.isEmpty || tasks.isNotEmpty
          ? ''
          : 'No usable agents in group.',
      'group_id': ValueReaders.stringValue(agentGroup['id']),
      'group_name': ValueReaders.stringValue(agentGroup['name']),
      'orchestration': ValueReaders.stringValue(
        agentGroup['orchestration'],
        'supervised',
      ),
      'context_policy': <String, Object?>{
        'mode': 'main_agent_mediated',
        'include_full_main_conversation': false,
        'include_private_memory': true,
        'description': '子智能体只接收主智能体整理过的任务摘录、约束和期望输出，不读取完整主会话上下文。',
      },
      'tasks': tasks,
      'warnings': warnings,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  JsonMap _delegationTask(JsonMap agent, JsonMap request, int order) {
    // 中文注释: 每个子任务都显式写出输入摘录、技能边界和上下文约束，方便后续调试和验收。
    final intent = ValueReaders.stringValue(request['intent'], 'draft').trim();
    var excerpt = ValueReaders.stringValue(
      request['task_excerpt'],
      ValueReaders.stringValue(request['prompt']),
    ).trim();
    if (excerpt.isEmpty) {
      excerpt = '等待主智能体提供本轮任务摘录。';
    }
    return <String, Object?>{
      'id':
          'delegate_${ValueReaders.stringValue(agent['id'], 'agent')}_${order + 1}',
      'agent_id': ValueReaders.stringValue(agent['id']),
      'agent_name': ValueReaders.stringValue(agent['name']),
      'role': ValueReaders.stringValue(agent['role']).trim(),
      'task': _taskBriefService.taskTextForAgent(agent, intent, excerpt),
      'input_excerpt': excerpt,
      'constraints': _stringListService.normalize(request['constraints']),
      'expected_output': _taskBriefService.expectedOutputForAgent(
        agent,
        intent,
      ),
      'skills': _stringListService.normalize(agent['skills']),
      'skill_groups': _stringListService.normalize(agent['skill_groups']),
      'context_policy': '主智能体摘录输入；不读取完整主会话上下文。',
      'status': 'planned',
    };
  }
}
