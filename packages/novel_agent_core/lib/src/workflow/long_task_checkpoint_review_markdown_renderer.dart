import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskCheckpointReviewMarkdownRenderer {
  const LongTaskCheckpointReviewMarkdownRenderer();

  String renderMarkdown(JsonMap review) {
    // 中文注释: 该渲染器面向用户直接阅读复盘结果，强调确认重点和下一步，而不是完整流水账。
    final task = ValueReaders.mapValue(review['task']);
    final lines = <String>[
      '# ${ValueReaders.stringValue(task['title'], '长任务检查点复盘')}',
      '',
      '- 任务类型：${ValueReaders.stringValue(review['task_type'])}',
      '- 模式：${ValueReaders.stringValue(review['mode'])}',
      '- 阶段：${ValueReaders.stringValue(review['stage'], '未标记')}',
      '- 风险级别：${ValueReaders.stringValue(review['severity_label'], ValueReaders.stringValue(review['severity'], '未评估'))}',
      '- 时间：${ValueReaders.stringValue(review['created_at'])}',
      '- 结果：${ValueReaders.boolValue(review['result_ok']) ? '成功' : '失败'}',
    ];
    final summary = ValueReaders.stringValue(review['summary']).trim();
    if (summary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 摘要')
        ..add(summary);
    }
    _appendList(lines, '当前产物', ValueReaders.stringList(review['output_paths']));
    _appendList(
      lines,
      '长期约束路径',
      ValueReaders.stringList(review['persistent_context_paths']),
    );
    _appendList(
      lines,
      '本轮关注点',
      ValueReaders.stringList(review['confirmation_focus']),
    );
    _appendList(
      lines,
      '漂移警戒',
      ValueReaders.stringList(review['drift_watch_items']),
    );
    _appendExpressionConstraintReview(
      lines,
      ValueReaders.mapValue(review['expression_constraint_review']),
    );
    _appendWritingExecutionConstraints(
      lines,
      ValueReaders.mapValue(review['writing_execution_constraints']),
      ValueReaders.mapValue(review['expression_constraint_signal']),
    );
    _appendList(
      lines,
      'Mini Recheck',
      ValueReaders.stringList(review['mini_recheck_items']),
    );
    _appendDriftSignals(lines, ValueReaders.mapList(review['drift_signals']));
    _appendInformationSignal(
      lines,
      ValueReaders.mapValue(review['information_signal']),
    );
    _appendCollaborationSignal(
      lines,
      ValueReaders.mapValue(review['collaboration_signal']),
    );
    _appendList(
      lines,
      '风险依据',
      ValueReaders.stringList(review['severity_reasons']),
    );
    _appendChapterLengthEvaluation(
      lines,
      ValueReaders.mapValue(review['chapter_length_evaluation']),
    );
    _appendList(
      lines,
      '下一步建议',
      ValueReaders.stringList(review['next_actions']),
    );
    _appendActionList(
      lines,
      '建议动作',
      ValueReaders.mapList(review['suggested_actions']),
    );
    _appendDisposition(lines, ValueReaders.mapValue(review['disposition']));
    _appendList(lines, '本轮工具', ValueReaders.stringList(review['tool_names']));
    final preview = ValueReaders.stringValue(review['response_preview']).trim();
    if (preview.isNotEmpty) {
      lines
        ..add('')
        ..add('## 返回摘要')
        ..add(preview);
    }
    final error = ValueReaders.stringValue(review['error']).trim();
    if (error.isNotEmpty) {
      lines
        ..add('')
        ..add('## 错误')
        ..add(error);
    }
    return lines.join('\n');
  }

  void _appendList(List<String> lines, String title, List<String> items) {
    if (items.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## $title');
    for (final item in items) {
      final text = item.trim();
      if (text.isNotEmpty) {
        lines.add('- $text');
      }
    }
  }

  void _appendActionList(
    List<String> lines,
    String title,
    List<JsonMap> items,
  ) {
    if (items.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## $title');
    for (final item in items) {
      final label = ValueReaders.stringValue(item['label']).trim();
      if (label.isEmpty) {
        continue;
      }
      final enabled = ValueReaders.boolValue(item['enabled']);
      final note = ValueReaders.stringValue(item['note']).trim();
      lines.add(
        '- ${enabled ? '[可用]' : '[不可用]'} $label${note.isEmpty ? '' : '：$note'}',
      );
    }
  }

  void _appendDriftSignals(List<String> lines, List<JsonMap> signals) {
    if (signals.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## 漂移信号');
    for (final signal in signals) {
      final domain = ValueReaders.stringValue(signal['domain']).trim();
      final severity = ValueReaders.stringValue(signal['severity']).trim();
      final title = ValueReaders.stringValue(signal['title']).trim();
      final note = ValueReaders.stringValue(signal['note']).trim();
      if (domain.isEmpty && title.isEmpty && note.isEmpty) {
        continue;
      }
      lines.add(
        '- ${title.isEmpty ? domain : title}'
        '${severity.isEmpty ? '' : ' [$severity]'}'
        '${note.isEmpty ? '' : '：$note'}',
      );
    }
  }

  void _appendDisposition(List<String> lines, JsonMap disposition) {
    if (disposition.isEmpty) {
      return;
    }
    final type = ValueReaders.stringValue(disposition['disposition']).trim();
    final summary = ValueReaders.stringValue(disposition['summary']).trim();
    if (type.isEmpty && summary.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## 放行判断');
    if (type.isNotEmpty) {
      lines.add('- 类型：$type');
    }
    final reason = ValueReaders.stringValue(disposition['reason']).trim();
    if (reason.isNotEmpty) {
      lines.add('- 原因：$reason');
    }
    if (summary.isNotEmpty) {
      lines.add('- 说明：$summary');
    }
  }

  void _appendInformationSignal(List<String> lines, JsonMap signal) {
    if (signal.isEmpty || !ValueReaders.boolValue(signal['present'])) {
      return;
    }
    lines
      ..add('')
      ..add('## Information 信号');
    final summary = ValueReaders.stringValue(signal['summary']).trim();
    if (summary.isNotEmpty) {
      lines.add('- 摘要：$summary');
    }
    final category = ValueReaders.stringValue(signal['category']).trim();
    if (category.isNotEmpty) {
      lines.add('- 类别：$category');
    }
    _appendList(
      lines,
      '待研究请求',
      ValueReaders.stringList(signal['pending_research_requests']),
    );
    _appendList(
      lines,
      '高风险引用',
      ValueReaders.stringList(signal['high_risk_reference_ids']),
    );
    _appendList(
      lines,
      '设计冲突',
      ValueReaders.stringList(signal['design_conflict_ids']),
    );
    _appendList(
      lines,
      'Required 信息省略',
      ValueReaders.stringList(signal['required_omitted_titles']),
    );
    _appendList(
      lines,
      'Information 改动路径',
      ValueReaders.stringList(signal['changed_paths']),
    );
  }

  void _appendCollaborationSignal(List<String> lines, JsonMap signal) {
    if (signal.isEmpty || !ValueReaders.boolValue(signal['present'])) {
      return;
    }
    lines
      ..add('')
      ..add('## 协作冲突');
    final summary = ValueReaders.stringValue(signal['summary']).trim();
    if (summary.isNotEmpty) {
      lines.add('- 摘要：$summary');
    }
    final highestRisk = ValueReaders.stringValue(signal['highest_risk']).trim();
    if (highestRisk.isNotEmpty) {
      lines.add('- 最高风险：$highestRisk');
    }
    final category = ValueReaders.stringValue(signal['category']).trim();
    if (category.isNotEmpty) {
      lines.add('- 处理类型：$category');
    }
    final arbitrationResults = ValueReaders.mapList(
      signal['arbitration_results'],
    );
    if (arbitrationResults.isNotEmpty) {
      lines.add('- 仲裁结果：');
      for (final item in arbitrationResults) {
        final summary = ValueReaders.stringValue(item['summary']).trim();
        if (summary.isNotEmpty) {
          lines.add('  - $summary');
        }
      }
    }
  }

  void _appendChapterLengthEvaluation(List<String> lines, JsonMap evaluation) {
    if (evaluation.isEmpty) {
      return;
    }
    final current = ValueReaders.intValue(evaluation['current_length']);
    final target = ValueReaders.intValue(evaluation['target_length']);
    if (current <= 0 || target <= 0) {
      return;
    }
    lines
      ..add('')
      ..add('## 字数评价')
      ..add('- 当前章：约 $current 字')
      ..add('- 目标基准：约 $target 字');
    final min = ValueReaders.intValue(evaluation['preferred_min']);
    final max = ValueReaders.intValue(evaluation['preferred_max']);
    if (min > 0 || max > 0) {
      lines.add(
        '- 柔性区间：${min > 0 ? min : '未设下限'} ~ ${max > 0 ? max : '未设上限'} 字',
      );
    }
    final rollingAverage = ValueReaders.intValue(
      evaluation['rolling_average_length'],
    );
    if (rollingAverage > 0) {
      lines.add('- 最近滚动均值：约 $rollingAverage 字');
    }
    final previous = ValueReaders.intValue(evaluation['previous_length']);
    final delta = ValueReaders.intValue(evaluation['adjacent_delta']);
    if (previous > 0 && delta > 0) {
      lines.add('- 与上一章差值：约 $delta 字');
    }
    final level = ValueReaders.stringValue(evaluation['level']).trim();
    if (level.isNotEmpty) {
      lines.add('- 评价等级：$level');
    }
    final action = ValueReaders.stringValue(
      evaluation['recommended_action'],
    ).trim();
    if (action.isNotEmpty) {
      lines.add('- 建议动作：$action');
    }
    _appendList(lines, '字数说明', ValueReaders.stringList(evaluation['notes']));
  }

  void _appendExpressionConstraintReview(List<String> lines, JsonMap raw) {
    if (raw.isEmpty) {
      return;
    }
    final authenticityPassLevel = ValueReaders.stringValue(
      raw['authenticity_pass_level'],
    ).trim();
    final reviewFocuses = ValueReaders.stringList(raw['review_focuses']);
    final voiceNotes = ValueReaders.stringList(raw['voice_protection_notes']);
    if (authenticityPassLevel.isEmpty &&
        reviewFocuses.isEmpty &&
        voiceNotes.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## 表达限制联动');
    if (authenticityPassLevel.isNotEmpty &&
        authenticityPassLevel != 'disabled') {
      lines.add('- 真实性复核强度：$authenticityPassLevel');
    }
    for (final item in reviewFocuses) {
      final text = item.trim();
      if (text.isNotEmpty) {
        lines.add('- 审稿重点：$text');
      }
    }
    for (final item in voiceNotes) {
      final text = item.trim();
      if (text.isNotEmpty) {
        lines.add('- 保真提醒：$text');
      }
    }
  }

  void _appendWritingExecutionConstraints(
    List<String> lines,
    JsonMap constraints,
    JsonMap signal,
  ) {
    if (constraints.isEmpty && signal.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add('## 表达限制执行策略');
    final policyMode = ValueReaders.stringValue(
      constraints['policy_mode'],
    ).trim();
    if (policyMode.isNotEmpty) {
      lines.add('- 策略模式：$policyMode');
    }
    final injectionStrength = ValueReaders.stringValue(
      constraints['injection_strength'],
    ).trim();
    if (injectionStrength.isNotEmpty) {
      lines.add('- 注入强度：$injectionStrength');
    }
    final injectionMode = ValueReaders.stringValue(
      constraints['injection_mode'],
    ).trim();
    if (injectionMode.isNotEmpty) {
      lines.add('- 注入形态：$injectionMode');
    }
    final reviewRequirement = ValueReaders.stringValue(
      constraints['review_requirement'],
    ).trim();
    if (reviewRequirement.isNotEmpty) {
      lines.add('- 复核要求：$reviewRequirement');
    }
    if (ValueReaders.boolValue(constraints['runtime_escalated'])) {
      lines.add('- 连续风险升级：已触发');
    }
    final signalCategory = ValueReaders.stringValue(signal['category']).trim();
    if (signalCategory.isNotEmpty) {
      lines.add('- Supervisor 信号：$signalCategory');
    }
    final signalSummary = ValueReaders.stringValue(signal['summary']).trim();
    if (signalSummary.isNotEmpty) {
      lines.add('- 信号摘要：$signalSummary');
    }
    _appendList(
      lines,
      '策略命中原因',
      ValueReaders.stringList(signal['applied_reasons']),
    );
    _appendList(
      lines,
      '策略跳过原因',
      ValueReaders.stringList(signal['skipped_reasons']),
    );
    _appendList(
      lines,
      '表达限制风险',
      ValueReaders.stringList(signal['risk_signals']),
    );
  }
}
