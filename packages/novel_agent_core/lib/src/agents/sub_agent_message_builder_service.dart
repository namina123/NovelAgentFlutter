import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_string_list_service.dart';
import 'agent_task_brief_service.dart';

class SubAgentMessageBuilderService {
  SubAgentMessageBuilderService({
    AgentStringListService? stringListService,
    AgentTaskBriefService? taskBriefService,
  }) : _stringListService = stringListService ?? AgentStringListService(),
       _taskBriefService = taskBriefService ?? AgentTaskBriefService();

  final AgentStringListService _stringListService;
  final AgentTaskBriefService _taskBriefService;

  String childSystemPrompt(
    JsonMap agent,
    JsonMap agentGroup,
    JsonMap arguments,
    JsonMap mainContext,
  ) {
    // 中文注释: 子智能体系统提示必须明确它只是内部视角，不能误把自己当成直接面向用户的主智能体。
    final task = _argumentText(arguments, const <String>['task', 'query']);
    final expectedOutput = _argumentText(
      arguments,
      const <String>['expected_output', 'expectedOutput'],
      fallback: _taskBriefService.expectedOutputForAgent(
        agent,
        ValueReaders.stringValue(mainContext['intent'], 'draft'),
      ),
    );
    final groupName = ValueReaders.stringValue(
      agentGroup['name'],
      ValueReaders.stringValue(agentGroup['id'], '临时协作组'),
    );
    final agentPrompt = ValueReaders.stringValue(agent['system_prompt']).trim();
    final lines = <String>[
      '你是 NOVEL Agent 的内部子智能体视角，不是面向用户独立存在的可选主智能体。',
      '你由主智能体通过智能体组策略临时调用，只处理主智能体交给你的单个子任务。',
      '禁止假装拥有完整主会话历史；你只能使用本运行包提供的任务、摘录、结构信息，以及你通过工具读取到的项目资料。',
      '如果信息不足，输出需要主智能体补充或确认的事项，不要直接询问用户。',
      '除非任务明确要求写入文件，否则优先给可合并建议；需要读取资料时可使用项目只读工具。',
      '',
      '协作组：$groupName',
      '子智能体：${ValueReaders.stringValue(agent['name'], ValueReaders.stringValue(agent['id']))}',
      '职责：${ValueReaders.stringValue(agent['role'])}',
      if (agentPrompt.isNotEmpty) '额外提示：$agentPrompt',
      '期望产物：$expectedOutput',
      '主智能体委派任务：$task',
    ];
    return lines.join('\n');
  }

  String childStructureMessage(
    JsonMap agentGroup,
    JsonMap arguments,
    JsonMap mainContext,
  ) {
    // 中文注释: 结构化说明只保留子智能体真正需要的骨架信息，不混入完整主会话。
    final lines = <String>[
      '子智能体结构信息：',
      '- 项目：${ValueReaders.stringValue(mainContext['project_title'], '未命名项目')}',
      '- 协作策略：${ValueReaders.stringValue(agentGroup['orchestration'], 'main_with_children')}',
      '- 上下文边界：只接收主智能体整理后的摘录，不接收完整主会话。',
    ];
    final sourcePaths = _stringListService.normalize(
      arguments['source_paths'] ?? arguments['sourcePaths'],
    );
    if (sourcePaths.isNotEmpty) {
      lines.add('- 主智能体建议关注路径：${sourcePaths.join('、')}');
    }
    final constraints = _stringListService.normalize(arguments['constraints']);
    if (constraints.isNotEmpty) {
      lines.add('- 约束：${constraints.join('；')}');
    }
    final projectTree = ValueReaders.stringValue(
      mainContext['project_tree_note'],
    ).trim();
    if (projectTree.isNotEmpty) {
      lines
        ..add('')
        ..add('项目目录摘要：')
        ..add(projectTree);
    }
    final styleNote = ValueReaders.stringValue(
      mainContext['style_note'],
    ).trim();
    if (styleNote.isNotEmpty) {
      lines
        ..add('')
        ..add('风格/写作约束摘要：')
        ..add(styleNote);
    }
    return lines.join('\n');
  }

  String childUserMessage(JsonMap arguments) {
    // 中文注释: 子智能体 user 消息把任务和必要摘录分层展示，方便模型快速定位重点。
    final task = _argumentText(arguments, const <String>['task', 'query']);
    final excerpt = _argumentText(arguments, const <String>[
      'context_excerpt',
      'contextExcerpt',
      'task_excerpt',
      'taskExcerpt',
    ], fallback: task);
    final lines = <String>['请完成主智能体委派给你的子任务。', '', '子任务：', task];
    if (excerpt.trim().isNotEmpty) {
      lines
        ..add('')
        ..add('主智能体整理的必要摘录：')
        ..add(excerpt);
    }
    lines
      ..add('')
      ..add('请返回可供主智能体合并的结果，不要直接对用户发起新问题。');
    return lines.join('\n');
  }

  String _argumentText(
    JsonMap arguments,
    List<String> keys, {
    String fallback = '',
  }) {
    // 中文注释: 不同 provider 或宿主的字段命名可能不完全一致，这里集中做兼容读取。
    for (final key in keys) {
      final value = ValueReaders.stringValue(arguments[key]).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}
