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
      _openingBoundaryLine(transaction),
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
    final reviewType = ValueReaders.stringValue(
      transaction['review_type'],
    ).trim();
    if (reviewType.isNotEmpty && reviewType != 'general') {
      lines.add('- 审稿类型：$reviewType');
    }
    final chapterWordConstraints = ValueReaders.mapValue(
      transaction['chapter_word_constraints'],
    );
    if (chapterWordConstraints.isNotEmpty) {
      final parts = <String>[];
      final target = ValueReaders.intValue(chapterWordConstraints['target']);
      final min = ValueReaders.intValue(chapterWordConstraints['min']);
      final max = ValueReaders.intValue(chapterWordConstraints['max']);
      if (target > 0) {
        parts.add('目标约 $target 字');
      }
      if (min > 0) {
        parts.add('不少于 $min 字');
      }
      if (max > 0) {
        parts.add('尽量不超过 $max 字');
      }
      if (parts.isNotEmpty) {
        lines.add('- 字数约束：${parts.join('；')}');
      }
    }

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
    final domainToolContracts = ValueReaders.stringList(
      transaction['domain_tool_contracts'],
    );
    if (domainToolContracts.isNotEmpty) {
      lines
        ..add('')
        ..add('## 领域工具契约');
      _appendLines(lines, domainToolContracts);
    }
    final skillRouting = ValueReaders.stringList(transaction['skill_routing']);
    if (skillRouting.isNotEmpty) {
      lines
        ..add('')
        ..add('## 技能路由策略');
      _appendLines(lines, skillRouting);
    }

    final toolHint = ValueReaders.stringValue(transaction['tool_hint']).trim();
    if (toolHint.isNotEmpty) {
      lines.add('- 任务工具提示：$toolHint');
    }
    final reviewFocuses = ValueReaders.stringList(
      transaction['review_focuses'],
    );
    if (reviewFocuses.isNotEmpty) {
      lines
        ..add('')
        ..add('## 审稿重点');
      _appendLines(lines, reviewFocuses);
    }
    final authenticityPassLevel = ValueReaders.stringValue(
      transaction['authenticity_pass_level'],
    ).trim();
    if (authenticityPassLevel.isNotEmpty) {
      lines
        ..add('')
        ..add('## 真实性复核强度')
        ..add('- 当前表达限制要求按 $authenticityPassLevel 强度执行真实性 / 去模板复核。');
    }
    final miniRecheckItems = ValueReaders.stringList(
      transaction['mini_recheck_items'],
    );
    if (miniRecheckItems.isNotEmpty) {
      lines
        ..add('')
        ..add('## Mini Recheck');
      _appendLines(lines, miniRecheckItems);
    }

    final creativeRuleSummary = ValueReaders.stringValue(
      transaction['creative_rule_summary'],
    ).trim();
    if (creativeRuleSummary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 创作约束栈')
        ..add(creativeRuleSummary);
    }
    final expressionConstraintSections = ValueReaders.mapList(
      transaction['expression_constraint_prompt_sections'],
    );
    if (expressionConstraintSections.isNotEmpty) {
      lines
        ..add('')
        ..add('## 表达限制细则');
      for (final section in expressionConstraintSections) {
        final title = ValueReaders.stringValue(
          section['title'],
          '表达限制规范',
        ).trim();
        final content = ValueReaders.stringValue(section['content']).trim();
        if (content.isEmpty) {
          continue;
        }
        lines
          ..add('### $title')
          ..add(content);
      }
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

  String _openingBoundaryLine(JsonMap transaction) {
    if (_isAutonomousSeedPlanning(transaction)) {
      return '不要把头脑风暴、选项或不确定内容写入正文；当前是 continuous_autonomous 的种子长篇规划，先落可修订草案，除非主线承诺、结局方向和世界边界都缺失到无法成稿，否则不要退回 present_user_options。';
    }
    if (_isAutonomousFormalChapter(transaction)) {
      return '不要把头脑风暴、选项或不确定内容写入正文；当前是 continuous_autonomous 的正式章节/修订单步，优先读取既有规划与必要前文并完成 submit_chapter_delivery，除非关键输入真实缺失到无法成稿，否则不要退回 present_user_options。';
    }
    return '不要把头脑风暴、选项或不确定内容写入正文；如果需要用户选择，调用 present_user_options。';
  }

  bool _isAutonomousSeedPlanning(JsonMap transaction) {
    return _isContinuousAutonomousSeedTask(
      transaction,
      const <String>{'planning'},
    );
  }

  bool _isAutonomousFormalChapter(JsonMap transaction) {
    return _isContinuousAutonomousSeedTask(
      transaction,
      const <String>{'chapter', 'revision'},
    );
  }

  bool _isContinuousAutonomousSeedTask(
    JsonMap transaction,
    Set<String> taskTypes,
  ) {
    final metadata = ValueReaders.mapValue(transaction['metadata']);
    return taskTypes.contains(
          ValueReaders.stringValue(transaction['task_type']).trim(),
        ) &&
        ValueReaders.stringValue(transaction['mode']).trim() ==
            'seed_to_full_novel' &&
        ValueReaders.stringValue(metadata['runtime_baseline_id']).trim() ==
            'continuous_autonomous';
  }
}
