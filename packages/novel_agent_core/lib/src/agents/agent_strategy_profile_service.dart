import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_member_directory_service.dart';
import 'agent_orchestration_service.dart';

class AgentStrategyProfileService {
  AgentStrategyProfileService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentOrchestrationService? orchestrationService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _orchestrationService =
           orchestrationService ?? AgentOrchestrationService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentOrchestrationService _orchestrationService;

  JsonMap multiAgentStrategyProfile(
    String strategy,
    JsonMap agentGroup,
    List<Object?> availableAgents,
  ) {
    // 中文注释: 这里只输出策略阶段合同，不关心网络、工具执行和 UI 停顿恢复。
    var cleanStrategy = strategy.trim().toLowerCase();
    if (cleanStrategy.isEmpty) {
      cleanStrategy = _orchestrationService.normalizeOrchestration(
        ValueReaders.stringValue(
          agentGroup['orchestration'],
          'main_with_children',
        ),
      );
    }
    if (cleanStrategy == 'supervised') {
      cleanStrategy = 'main_with_children';
    }
    if (!const <String>{
      'main_with_children',
      'pipeline',
      'debate',
      'voting',
    }.contains(cleanStrategy)) {
      cleanStrategy = 'main_with_children';
    }

    final byId = _memberDirectoryService.agentsById(availableAgents);
    final members = <JsonMap>[];
    for (final agentId in ValueReaders.stringList(agentGroup['agents'])) {
      final rawAgent = ValueReaders.mapValue(byId[agentId]);
      if (rawAgent.isEmpty) {
        continue;
      }
      members.add(<String, Object?>{
        'id': ValueReaders.stringValue(rawAgent['id']),
        'name': ValueReaders.stringValue(rawAgent['name'], agentId),
        'role': ValueReaders.stringValue(rawAgent['role']),
        'description': ValueReaders.stringValue(rawAgent['description']),
      });
    }

    final phases = <JsonMap>[];
    if (cleanStrategy == 'pipeline') {
      phases.add(_phaseItem('prepare', '主智能体拆解任务', 'main_only'));
      for (var index = 0; index < members.length; index += 1) {
        final member = members[index];
        phases.add(
          _phaseItem(
            'stage_${index + 1}',
            '顺序子任务：${ValueReaders.stringValue(member['name'])}',
            'child_agent',
            ValueReaders.stringValue(member['id']),
          ),
        );
      }
      phases.add(_phaseItem('merge', '主智能体合并产物', 'main_only'));
    } else if (cleanStrategy == 'debate') {
      phases
        ..add(_phaseItem('brief', '主智能体给出争议点和评判标准', 'main_only'))
        ..add(_phaseItem('positions', '子智能体并行提出立场', 'parallel_children'))
        ..add(_phaseItem('rebuttal', '主智能体整理交叉质询', 'main_mediated'))
        ..add(_phaseItem('synthesis', '主智能体裁决并输出结论', 'main_only'));
    } else if (cleanStrategy == 'voting') {
      phases
        ..add(_phaseItem('options', '主智能体列出候选方案', 'main_only'))
        ..add(_phaseItem('votes', '子智能体独立评分/投票', 'parallel_children'))
        ..add(_phaseItem('tally', '主智能体汇总票数、少数意见和风险', 'main_only'));
    } else {
      phases
        ..add(_phaseItem('delegate', '主智能体按需调用子智能体', 'main_with_children'))
        ..add(_phaseItem('resume', '子智能体结束后主智能体继续', 'main_only'));
    }

    return <String, Object?>{
      'ok': true,
      'strategy': cleanStrategy,
      'group_id': ValueReaders.stringValue(agentGroup['id']),
      'group_name': ValueReaders.stringValue(agentGroup['name']),
      'members': members,
      'phases': phases,
      'context_policy': <String, Object?>{
        'include_full_main_conversation': false,
        'include_parent_messages': false,
        'child_input': '只接收主智能体整理的任务、摘录、约束、项目结构摘要和必要路径。',
        'return_to_main_agent': true,
        'user_can_message_children': false,
      },
      'host_contract': 'Core 只输出策略和阶段合同；GUI/CLI 宿主负责网络、工具执行、暂停继续、展示和持久化。',
      'visibility': 'internal_runtime_only',
    };
  }

  JsonMap _phaseItem(
    String id,
    String name,
    String mode, [
    String agentId = '',
  ]) {
    // 中文注释: phase 是跨宿主共享的轻量阶段描述，字段必须尽量稳定和扁平。
    return <String, Object?>{
      'id': id,
      'name': name,
      'mode': mode,
      if (agentId.trim().isNotEmpty) 'agent_id': agentId,
    };
  }
}
