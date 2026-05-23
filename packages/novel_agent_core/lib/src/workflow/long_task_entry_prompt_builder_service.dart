import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskEntryPromptBuilderService {
  const LongTaskEntryPromptBuilderService();

  String build({
    required String actionId,
    JsonMap project = const <String, Object?>{},
    JsonMap payload = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentExcerpt = '',
  }) {
    // 中文注释: 长任务入口按钮先统一转成显式提示词，让 GUI 和 CLI 都能复用同一组启动语义。
    final lines = <String>[
      _openingLine(actionId, payload),
      '',
      '请先检查当前项目是否已有 tasks/、tracking/、相关大纲、章纲或任务执行记录；不要假装已经生成或运行过队列。',
      '如果资料不足，请先说明缺口并给出最小补全方案；如果资料足够，再按当前动作推进。',
      '涉及任务、运行记录、计划快照、状态更新或文件写入时，必须通过真实工具完成。',
      '',
      '当前项目线索：',
      _projectLine(project),
    ];
    if (activeDocumentPath.trim().isNotEmpty) {
      lines.add('- 当前打开文件：${activeDocumentPath.trim()}');
    }
    final excerpt = _compact(activeDocumentExcerpt, 900);
    if (excerpt.isNotEmpty) {
      lines.add('- 当前文件片段：$excerpt');
    }
    lines.add('');
    lines.add('本次动作要求：');
    for (final item in _requirements(actionId)) {
      lines.add('- $item');
    }
    return lines.join('\n');
  }

  String _openingLine(String actionId, JsonMap payload) {
    switch (actionId.trim()) {
      case 'long_task.run_next':
        return '请检查当前长任务队列，并只推进“下一条安全单步”。如果没有可运行任务，请明确说明阻塞点。';
      case 'long_task.run_controlled':
        return '请检查当前长任务队列，按受控连续运行方式小步推进，遇到确认点、失败或无输出时停下并汇报。';
      case 'long_task.open_detail':
        return '请检查当前项目的长任务队列、依赖、执行包和 tracking/ 运行记录，并给出可读详情摘要。';
      case 'long_task.create_queue':
      default:
        final mode = ValueReaders.stringValue(payload['mode'], 'seed_to_full_novel');
        return '请为当前项目启动“生成长篇队列”流程，优先判断适合的长任务模式，并围绕 $mode 给出可恢复任务链。';
    }
  }

  List<String> _requirements(String actionId) {
    switch (actionId.trim()) {
      case 'long_task.run_next':
        return const <String>[
          '优先找下一条可运行任务，说明它依赖什么、为什么现在能跑。',
          '只推进一个安全单步；如果会覆盖或大改内容，先停下来要求确认。',
          '没有可运行任务时，明确指出是缺大纲、缺任务、任务阻塞还是运行记录异常。',
        ];
      case 'long_task.run_controlled':
        return const <String>[
          '先说明本轮允许连续推进的范围，不要无上限连续运行。',
          '每次推进都保留检查点意识；遇到确认点、失败、无输出或高风险覆盖时立即停下。',
          '结束时汇报已经推进到哪里、下一步会是什么、是否建议人工确认。',
        ];
      case 'long_task.open_detail':
        return const <String>[
          '读取并总结当前项目的 tasks/、tracking/、执行包和相关摘要。',
          '按“当前状态、下一步、主要阻塞、建议动作”四个部分说明。',
          '如果还没有队列，不要假装有数据；直接建议先生成长篇队列。',
        ];
      case 'long_task.create_queue':
      default:
        return const <String>[
          '先判断当前更像“已有大纲驱动写作”还是“只有创作种子，需要先规划长篇结构”。',
          '如果资料不足，不要硬生成庞大队列；先收束项目种子、主线目标、阶段结构和检查点要求。',
          '如果资料足够，请生成可恢复任务链，并明确建议保存到 tasks/ 和 tracking/ 的哪些位置。',
        ];
    }
  }

  String _projectLine(JsonMap project) {
    if (project.isEmpty) {
      return '- 未检测到项目；请先提醒我创建或打开长篇项目。';
    }
    return '- 名称：${ValueReaders.stringValue(project['title'], '未命名项目')}；类型：${ValueReaders.stringValue(project['project_type'], 'novel')}';
  }

  String _compact(String text, int maxChars) {
    var cleanText = text.trim().replaceAll('\r', ' ').replaceAll('\n', ' ');
    while (cleanText.contains('  ')) {
      cleanText = cleanText.replaceAll('  ', ' ');
    }
    if (cleanText.length <= maxChars) {
      return cleanText;
    }
    return '${cleanText.substring(0, maxChars)}...';
  }
}
