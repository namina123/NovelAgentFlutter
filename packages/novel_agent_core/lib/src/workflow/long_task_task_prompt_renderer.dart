import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_transaction_contract_service.dart';

class LongTaskTaskPromptRenderer {
  LongTaskTaskPromptRenderer({
    required LongTaskTransactionContractService contractService,
  }) : _contractService = contractService;

  final LongTaskTransactionContractService _contractService;

  String renderTaskPrompt(JsonMap transaction) {
    // 中文注释: 事务提示把结构化合同翻成模型可读说明，但不自行追加宿主层私有内容。
    final lines = <String>[
      '你正在执行 NOVEL Agent 的长篇任务流单步。请按事务包行动，先判断需要读取哪些项目文件，再调用工具。',
      '不要把头脑风暴、选项或不确定内容写入正文；如果需要用户选择，调用 present_user_options。',
      '',
      '## 任务',
      '- 标题：${ValueReaders.stringValue(transaction['task_title'], '未命名任务')}',
      '- ID：${ValueReaders.stringValue(transaction['task_id'])}',
      '- 类型：${ValueReaders.stringValue(transaction['task_type'])}',
      '- 模式：${ValueReaders.stringValue(transaction['mode'])}',
      '- 智能体角色：${ValueReaders.stringValue(transaction['agent_role'])}',
      '- 章节：${ValueReaders.stringValue(transaction['chapter'])}',
      '- 目标：${ValueReaders.stringValue(transaction['goal'])}',
    ];
    final brief = ValueReaders.stringValue(transaction['brief']).trim();
    if (brief.isNotEmpty) {
      lines.add('- 简述：$brief');
    }
    lines.add(
      '- 来源路径：${_contractService.joinOrNone(ValueReaders.objectList(transaction['source_paths']))}',
    );
    lines.add(
      '- 目标输出/修订路径：${_contractService.joinOrNone(ValueReaders.objectList(transaction['output_paths']))}',
    );

    final proposed = ValueReaders.mapValue(
      transaction['proposed_output_paths'],
    );
    if (proposed.isNotEmpty) {
      lines
        ..add('')
        ..add('## 拟写入路径');
      for (final entry in proposed.entries) {
        lines.add('- ${entry.key}：${ValueReaders.stringValue(entry.value)}');
      }
    }

    lines
      ..add('')
      ..add('## 执行要求');
    _appendLines(lines, ValueReaders.stringList(transaction['instructions']));
    lines
      ..add('')
      ..add('## 上下文读取策略');
    _appendLines(lines, ValueReaders.stringList(transaction['context_needs']));
    lines
      ..add('')
      ..add('## 工具契约');
    _appendLines(lines, ValueReaders.stringList(transaction['tool_contracts']));

    final toolHint = ValueReaders.stringValue(transaction['tool_hint']).trim();
    if (toolHint.isNotEmpty) {
      lines.add('- 任务工具提示：$toolHint');
    }

    final postprocess = ValueReaders.stringList(
      transaction['postprocess_plan'],
    );
    if (postprocess.isNotEmpty) {
      lines
        ..add('')
        ..add('## 后续处理计划');
      _appendLines(lines, postprocess);
    }

    final templates = ValueReaders.mapValue(transaction['project_templates']);
    final taskType = ValueReaders.stringValue(transaction['task_type']);
    var templateKey = taskType == 'review' ? 'review_report' : 'chapter_atomic';
    if (taskType == 'planning') {
      templateKey = 'long_task_planning';
    }
    final templateText = ValueReaders.stringValue(
      templates[templateKey],
    ).trim();
    if (templateText.isNotEmpty) {
      lines
        ..add('')
        ..add('## 项目模板')
        ..add(templateText);
    }

    lines
      ..add('')
      ..add('## 单步边界')
      ..add(ValueReaders.stringValue(transaction['single_step_boundary']));
    return lines.join('\n');
  }

  void _appendLines(List<String> lines, List<String> items) {
    // 中文注释: 事务里的说明列表统一渲染成短项目符号，避免各块格式飘散。
    for (final item in items) {
      final text = item.trim();
      if (text.isNotEmpty) {
        lines.add('- $text');
      }
    }
  }
}
