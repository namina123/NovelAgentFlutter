import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'context_budget_constants.dart';

class ContextBudgetService {
  JsonMap defaultSettings() {
    // 中文注释: 默认预算配置集中在这里维护，保证 GUI、CLI 和测试看到同一组基线值。
    return <String, Object?>{
      'context_pack_budget_chars':
          ContextBudgetConstants.defaultContextPackBudgetChars,
      'context_pack_budget_percent':
          ContextBudgetConstants.defaultContextPackBudgetPercent,
      'max_context_file_chars':
          ContextBudgetConstants.defaultMaxContextFileChars,
      'max_context_files_per_kind':
          ContextBudgetConstants.defaultMaxContextFilesPerKind,
      'reserved_output_chars':
          ContextBudgetConstants.defaultReservedOutputChars,
    };
  }

  JsonMap normalize(JsonMap settings) {
    // 中文注释: 这里统一清洗 UI、配置文件或旧项目传入的预算参数，避免运行时出现越界值。
    final normalized = defaultSettings()
      ..addAll(ValueReaders.deepCopyMap(settings));
    normalized['context_pack_budget_chars'] = _clampInt(
      ValueReaders.intValue(
        normalized['context_pack_budget_chars'],
        ContextBudgetConstants.defaultContextPackBudgetChars,
      ),
      ContextBudgetConstants.minContextPackBudgetChars,
      1000000,
    );
    normalized['context_pack_budget_percent'] = _clampInt(
      ValueReaders.intValue(
        normalized['context_pack_budget_percent'],
        ContextBudgetConstants.defaultContextPackBudgetPercent,
      ),
      5,
      95,
    );
    normalized['max_context_file_chars'] = _clampInt(
      ValueReaders.intValue(
        normalized['max_context_file_chars'],
        ContextBudgetConstants.defaultMaxContextFileChars,
      ),
      400,
      100000,
    );
    normalized['max_context_files_per_kind'] = _clampInt(
      ValueReaders.intValue(
        normalized['max_context_files_per_kind'],
        ContextBudgetConstants.defaultMaxContextFilesPerKind,
      ),
      1,
      64,
    );
    normalized['reserved_output_chars'] = _clampInt(
      ValueReaders.intValue(
        normalized['reserved_output_chars'],
        ContextBudgetConstants.defaultReservedOutputChars,
      ),
      0,
      500000,
    );
    return normalized;
  }

  int budgetChars(
    JsonMap settings, {
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 上下文预算优先按模型上下文长度粗估，没有模型信息时回退到固定预算。
    final normalized = normalize(settings);
    final modelContext = ValueReaders.intValue(modelProfile['context_length']);
    if (modelContext <= 0) {
      return ValueReaders.intValue(
        normalized['context_pack_budget_chars'],
        ContextBudgetConstants.defaultContextPackBudgetChars,
      );
    }
    final roughModelChars = modelContext * 2;
    final percentBudget =
        (roughModelChars *
            ValueReaders.intValue(
              normalized['context_pack_budget_percent'],
              ContextBudgetConstants.defaultContextPackBudgetPercent,
            )) ~/
        100;
    return _max(
      ContextBudgetConstants.minContextPackBudgetChars,
      percentBudget -
          ValueReaders.intValue(
            normalized['reserved_output_chars'],
            ContextBudgetConstants.defaultReservedOutputChars,
          ),
    );
  }

  JsonMap applyBudget(
    List<Object?> sections,
    JsonMap settings, {
    JsonMap modelProfile = const <String, Object?>{},
  }) {
    // 中文注释: 预算裁剪只处理片段选择与截断，不关心这些片段来自文件、记忆还是其他宿主。
    final normalizedSettings = normalize(settings);
    final budget = budgetChars(normalizedSettings, modelProfile: modelProfile);
    final candidates = _normalizeSections(sections);
    candidates.sort((a, b) {
      // 中文注释: 这里延续旧项目排序规则，优先 pinned，再看 priority，最后保留原始顺序。
      final aPinned = ValueReaders.boolValue(a['pinned']);
      final bPinned = ValueReaders.boolValue(b['pinned']);
      if (aPinned != bPinned) {
        return bPinned ? 1 : -1;
      }
      final priorityDiff =
          ValueReaders.intValue(b['priority']) -
          ValueReaders.intValue(a['priority']);
      if (priorityDiff != 0) {
        return priorityDiff;
      }
      return ValueReaders.intValue(
        a['_order'],
      ).compareTo(ValueReaders.intValue(b['_order']));
    });

    final included = <JsonMap>[];
    final omitted = <JsonMap>[];
    var used = 0;
    for (final section in candidates) {
      final cleanSection = ValueReaders.deepCopyMap(section)..remove('_order');
      final content = ValueReaders.stringValue(cleanSection['content']);
      final contentChars = content.length;
      final remaining = budget - used;
      if (remaining <= 0) {
        omitted.add(_omittedSummary(cleanSection, '预算已耗尽'));
        continue;
      }
      if (contentChars <= remaining) {
        cleanSection['chars'] = contentChars;
        cleanSection['truncated'] = false;
        included.add(cleanSection);
        used += contentChars;
        continue;
      }
      if (ValueReaders.boolValue(cleanSection['pinned']) || remaining >= 600) {
        cleanSection['content'] = _clipText(content, remaining);
        cleanSection['chars'] = ValueReaders.stringValue(
          cleanSection['content'],
        ).length;
        cleanSection['truncated'] = true;
        cleanSection['original_chars'] = contentChars;
        included.add(cleanSection);
        used += ValueReaders.intValue(cleanSection['chars']);
      } else {
        omitted.add(_omittedSummary(cleanSection, '剩余预算不足'));
      }
    }

    included.sort((a, b) {
      // 中文注释: 输出顺序按业务 order 恢复，避免排序优先级影响模型阅读顺序。
      return ValueReaders.intValue(
        a['order'],
      ).compareTo(ValueReaders.intValue(b['order']));
    });

    return <String, Object?>{
      'budget_chars': budget,
      'used_chars': used,
      'sections': included,
      'omitted_sections': omitted,
      'settings': normalizedSettings,
      'summary':
          '$used/$budget 字，纳入 ${included.length} 段，省略 ${omitted.length} 段',
    };
  }

  String renderSectionsMarkdown(List<Object?> sections) {
    // 中文注释: 预算后的上下文片段需要渲染成模型可读文本，这里保持来源信息清晰可审计。
    if (sections.isEmpty) {
      return '暂无上下文包。';
    }
    final blocks = <String>[];
    for (final item in sections) {
      final section = ValueReaders.mapValue(item);
      final title = ValueReaders.stringValue(
        section['title'],
        ValueReaders.stringValue(section['id'], '上下文'),
      ).trim();
      final source = ValueReaders.stringValue(section['source']).trim();
      final suffix = source.isNotEmpty ? '（$source）' : '';
      final content = ValueReaders.stringValue(section['content']).trim();
      if (content.isEmpty) {
        continue;
      }
      blocks.add('【$title$suffix】\n$content');
    }
    return blocks.isEmpty ? '暂无上下文包。' : blocks.join('\n\n');
  }

  String previewMarkdown(JsonMap contextPack, {String userPrompt = ''}) {
    // 中文注释: 预览文本给用户和调试页面看，不包含 provider 敏感配置，只展示预算结果摘要。
    final lines = <String>[
      '# 本次上下文包预览',
      '',
      '- 预算：${ValueReaders.stringValue(contextPack['summary'], '未知')}',
      '- 意图：${ValueReaders.stringValue(contextPack['intent'], 'unknown')}',
      '- ID：${ValueReaders.stringValue(contextPack['id'])}',
    ];
    final prompt = userPrompt.trim();
    if (prompt.isNotEmpty) {
      lines.add('');
      lines.add('## 用户请求');
      lines.add(prompt);
    }
    lines.add('');
    lines.add('## 已纳入片段');
    for (final section in ValueReaders.objectList(contextPack['sections'])) {
      final item = ValueReaders.mapValue(section);
      lines.add(
        '- ${ValueReaders.stringValue(item['title'], ValueReaders.stringValue(item['id']))}｜${ValueReaders.intValue(item['chars'])} 字${ValueReaders.boolValue(item['truncated']) ? '｜已截断' : ''}',
      );
    }
    final omitted = ValueReaders.objectList(contextPack['omitted_sections']);
    if (omitted.isNotEmpty) {
      lines.add('');
      lines.add('## 省略片段');
      for (final raw in omitted) {
        final item = ValueReaders.mapValue(raw);
        lines.add(
          '- ${ValueReaders.stringValue(item['title'])}：${ValueReaders.stringValue(item['reason'])}',
        );
      }
    }
    return lines.join('\n');
  }

  List<JsonMap> _normalizeSections(List<Object?> sections) {
    // 中文注释: 片段规范化负责补齐排序与显示字段，保证预算器面对脏输入也能稳定工作。
    final result = <JsonMap>[];
    for (var index = 0; index < sections.length; index += 1) {
      final raw = ValueReaders.mapValue(sections[index]);
      if (raw.isEmpty) {
        continue;
      }
      final content = ValueReaders.stringValue(raw['content']).trim();
      if (content.isEmpty) {
        continue;
      }
      final section = ValueReaders.deepCopyMap(raw);
      section['content'] = content;
      section['id'] = ValueReaders.stringValue(section['id'], 'section_$index');
      section['title'] = ValueReaders.stringValue(
        section['title'],
        ValueReaders.stringValue(section['id']),
      );
      section['priority'] = ValueReaders.intValue(section['priority'], 50);
      section['pinned'] = ValueReaders.boolValue(section['pinned']);
      section['order'] = ValueReaders.intValue(section['order'], index);
      section['_order'] = index;
      result.add(section);
    }
    return result;
  }

  JsonMap _omittedSummary(JsonMap section, String reason) {
    // 中文注释: 被省略片段只保留轻量摘要，避免调试预览把未发送正文再塞满一遍。
    return <String, Object?>{
      'id': section['id'],
      'title': section['title'] ?? section['id'],
      'source': section['source'],
      'chars': ValueReaders.stringValue(section['content']).length,
      'reason': reason,
    };
  }

  String _clipText(String value, int maxChars) {
    // 中文注释: 当前采用朴素截断策略，先保证预算安全，后续再考虑摘要式裁剪。
    if (maxChars <= 0) {
      return '';
    }
    if (value.length <= maxChars) {
      return value;
    }
    const suffix = '\n\n……（上下文预算限制，已截断）';
    final bodyChars = _max(0, maxChars - suffix.length);
    return value.substring(0, bodyChars) + suffix;
  }

  int _clampInt(int value, int min, int max) {
    // 中文注释: 整数边界裁剪放在本地实现，保持 pure Dart core 的可移植性。
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  int _max(int left, int right) {
    // 中文注释: 小型数值辅助函数单独收口，让主流程保持直白可读。
    return left > right ? left : right;
  }
}
