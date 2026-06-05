import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_record_constants.dart';

class SessionGoalPromptBuilderService {
  const SessionGoalPromptBuilderService();

  String build({
    required String mode,
    JsonMap project = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentExcerpt = '',
  }) {
    // 中文注释: 会话目标按钮对应的启动提示词统一在 core 生成，保证 GUI 和 CLI 触发的是同一流程语义。
    final cleanMode = normalizeMode(mode);
    final lines = <String>[
      _openingLine(cleanMode),
      '',
      '请先判断当前项目是否满足这个流程的前置条件；不要为了完成按钮动作而硬写、硬总结或伪造不存在的资料。',
      '如果资料不足，请用面向普通作者的方式说明缺口，并给出下一步可执行引导；如果资料足够，再推进真正产物。',
      '优先按需读取项目文件、摘要、设定、大纲、场景片段和正文；需要真实读写时必须调用工具。',
      '如果你需要给用户几个方向、开局、题材、补充路径或下一步选择，必须调用 present_user_options；不要把这些选项只写成普通正文列表。',
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
    lines.add('本次流程要求：');
    for (final item in _requirements(cleanMode)) {
      lines.add('- $item');
    }
    lines.add('');
    lines.add('回复方式：');
    lines.add('- 先判断当前项目是适合直接推进、需要补资料，还是建议切换流程。');
    lines.add('- 如果需要用户补充，不要甩长表单；给出 2-4 个清晰选项或一个最小输入请求。给出选项时使用 present_user_options。');
    lines.add('- 如果已经可以推进，请直接产出当前阶段最有价值的内容，并说明建议保存到哪个中文目录。');
    return lines.join('\n');
  }

  String normalizeMode(String mode) {
    // 中文注释: 会话目标模式统一走这里归一化，避免动作按钮和会话记录出现不一致值。
    switch (mode.trim()) {
      case SessionRecordConstants.modeSummarizeBook:
      case SessionRecordConstants.modeChapterDraft:
      case SessionRecordConstants.modeImportArticle:
      case SessionRecordConstants.modeContinueWriting:
      case SessionRecordConstants.modeSmartOpening:
        return mode.trim();
      default:
        return SessionRecordConstants.modeSmartOpening;
    }
  }

  String label(String mode) {
    // 中文注释: 目标标签给 UI 和日志复用，避免每个宿主都手写中文名称。
    switch (normalizeMode(mode)) {
      case SessionRecordConstants.modeSummarizeBook:
        return '总结全书';
      case SessionRecordConstants.modeChapterDraft:
        return '单章创作';
      case SessionRecordConstants.modeImportArticle:
        return '导入文章';
      case SessionRecordConstants.modeContinueWriting:
        return '继续创作';
      case SessionRecordConstants.modeSmartOpening:
      default:
        return '智能开局';
    }
  }

  String _openingLine(String mode) {
    switch (mode) {
      case SessionRecordConstants.modeSummarizeBook:
        return '请启动“总结全书”流程，先判断项目里是否已有足够正文、场景片段、导入材料或章节摘要。';
      case SessionRecordConstants.modeChapterDraft:
        return '请启动“单章创作”流程，先判断当前是否具备写一章所需的大纲、目标、角色状态和风格约束。';
      case SessionRecordConstants.modeImportArticle:
        return '请启动“导入文章”流程，先判断用户是否已经提供或导入了需要整理的文章材料。';
      case SessionRecordConstants.modeContinueWriting:
        return '请启动“继续创作”流程，先判断项目里是否有可续写的最近章节、摘要、场景片段或当前打开片段。';
      case SessionRecordConstants.modeSmartOpening:
      default:
        return '请启动“智能开局”流程，帮助我把这个小说项目从零推进到真正可写的状态。';
    }
  }

  List<String> _requirements(String mode) {
    switch (mode) {
      case SessionRecordConstants.modeSummarizeBook:
        return const <String>[
          '检查 chapters/、scenes/、summaries/、outline/ 等目录是否有可总结材料。',
          '材料不足时，引导我先导入文章、写首章或建立大纲，不要编造全书内容。',
          '材料足够时，输出分层摘要：一句话定位、主线、角色状态、世界规则、伏笔和待续写问题。',
        ];
      case SessionRecordConstants.modeChapterDraft:
        return const <String>[
          '判断是否有明确章节目标、前情、角色状态、场景约束和输出目录。',
          '信息不足时，先给出最小补全问题或可选章节方向。',
          '信息足够时，优先判断应写完整章节还是局部场景；完整章节建议写入 chapters/，局部片段建议写入 scenes/。',
        ];
      case SessionRecordConstants.modeImportArticle:
        return const <String>[
          '判断当前是否已有打开文件、导入文件或我直接粘贴的内容。',
          '没有材料时，说明可以使用导入入口或直接粘贴文本；正文/片段仍归档到 chapters/ 或 scenes/，抽取出的长期设定与巧思应保存为结构化结果，不要直接归档到 knowledge/ 投影。',
          '有材料时，先分类、摘要、抽取可复用设定，再询问是否保存结构化结果。',
        ];
      case SessionRecordConstants.modeContinueWriting:
        return const <String>[
          '查找最近可续写的正文、场景片段、摘要和当前打开文件。',
          '没有前文时，不要假装续写；建议改走智能开局或单章创作。',
          '有前文时，先概括当前承接点，再给出续写方向，必要时直接续写一个短段落或场景。',
        ];
      case SessionRecordConstants.modeSmartOpening:
      default:
        return const <String>[
          '判断项目是否已有题材、主角、核心矛盾、读者期待和第一章钩子。',
          '信息不足时，用少量选项帮我做选择，不要一开始要求填写长表单。',
          '信息足够时，产出项目规格、开局方案和下一步建议；需要保存时使用合适工具。',
        ];
    }
  }

  String _projectLine(JsonMap project) {
    if (project.isEmpty) {
      return '- 未检测到项目；请提醒我先创建或打开项目。';
    }
    final parts = <String>[
      '名称：${ValueReaders.stringValue(project['title'], '未命名项目')}',
    ];
    final projectType = ValueReaders.stringValue(
      project['project_type'],
      'novel',
    );
    if (projectType.trim().isNotEmpty) {
      parts.add('类型：$projectType');
    }
    final genre = ValueReaders.stringValue(project['genre']);
    if (genre.trim().isNotEmpty) {
      parts.add('题材：$genre');
    }
    final seed = _compact(
      ValueReaders.stringValue(project['seed_prompt']),
      140,
    );
    if (seed.isNotEmpty) {
      parts.add('创作种子：$seed');
    }
    return '- ${parts.join('；')}';
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
