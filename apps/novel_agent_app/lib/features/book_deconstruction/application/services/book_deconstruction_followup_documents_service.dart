import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionFollowupDocumentsService {
  const BookDeconstructionFollowupDocumentsService({
    ReferenceSourceDocumentStructureService? structureService,
  }) : _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService();

  final ReferenceSourceDocumentStructureService _structureService;

  String renderPlanJson({
    required BookDeconstructionDerivedProjectPlan plan,
    required BookDeconstructionFollowupOption option,
    required BookDeconstructionDraftBuildResult buildResult,
  }) {
    final json = <String, Object?>{
      'plan_id': plan.planId,
      'source_extraction_id': plan.sourceExtractionId,
      'source_project_title': plan.sourceProjectTitle,
      'followup_option_id': plan.followupOptionId,
      'followup_group_id': _groupIdOf(option.id),
      'target_project_type_id': plan.targetProjectTypeId,
      'target_project_strategy_id': plan.targetProjectStrategyId,
      'target_mode_id': plan.targetModeId,
      'source_inheritance_mode': plan.sourceInheritanceMode.name,
      'preferred_direction': plan.preferredDirection.name,
      'recommended_build_tier': plan.recommendedBuildTier.name,
      'suggested_project_title': plan.suggestedProjectTitle,
      'route_title': option.title,
      'route_summary': option.summary,
      'writer_bias': _writerBias(option.sourceInheritanceMode),
      'metadata': <String, Object?>{
        ...plan.metadata,
        'source_title': buildResult.input.title,
        'source_document_count': buildResult.input.sourceDocuments.length,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  String renderGuideMarkdown({
    required BookDeconstructionDerivedProjectPlan plan,
    required BookDeconstructionFollowupOption option,
    required BookDeconstructionDraftBuildResult buildResult,
    required String inheritedChapterRootPath,
  }) {
    final sourceContent = buildResult.input.sourceDocuments.isEmpty
        ? ''
        : buildResult.input.sourceDocuments.first.content;
    final structure = _structureService.analyze(sourceContent);
    final sections = structure.sections;
    final charCounts = sections
        .map((section) => section.charCount)
        .toList(growable: false);
    final avgChars = charCounts.isEmpty
        ? 0
        : (charCounts.reduce((a, b) => a + b) / charCounts.length).round();
    final minChars = charCounts.isEmpty
        ? 0
        : charCounts.reduce((a, b) => a < b ? a : b);
    final maxChars = charCounts.isEmpty
        ? 0
        : charCounts.reduce((a, b) => a > b ? a : b);
    final styleSummary = buildResult.extractionResult.styleProfiles
        .map((entry) => entry.summary.trim())
        .where((entry) => entry.isNotEmpty)
        .join('；');
    final lines = <String>[
      '# 拆书后续路线说明',
      '',
      '- 路线：${_routeLabel(option.sourceInheritanceMode)} / ${option.title}',
      '- 建议派生项目标题：${plan.suggestedProjectTitle}',
      '- 目标项目类型：${plan.targetProjectTypeId}',
      '- 目标策略：${plan.targetProjectStrategyId}',
      if (plan.targetModeId.trim().isNotEmpty) '- 目标模式：${plan.targetModeId}',
      '- 导向倾向：${_writerBias(option.sourceInheritanceMode)}',
      '- 来源处理：${_sourceHandlingSummary(option.sourceInheritanceMode, inheritedChapterRootPath)}',
      '',
      '## 写作导向',
      '',
      _writingDirection(option.sourceInheritanceMode),
      '',
      '## 继承到的知识与约束',
      '',
      '- 已提取结构资产：前提 ${buildResult.extractionResult.premises.length} 项，章纲 ${buildResult.extractionResult.chapterOutlines.length} 项，角色 ${buildResult.extractionResult.characterProfiles.length} 项，组织 ${buildResult.extractionResult.organizationProfiles.length} 项。',
      '- 已沉淀 narrative / information 资产，可继续作为后续写作的共用资料层。',
      if (sections.isNotEmpty)
        '- 原作切分：${sections.length} 段${structure.structureKind == ReferenceSourceDocumentStructureKinds.explicitChapter ? '（按显式章节识别）' : '（按段落聚类识别）'}。'
      else
        '- 原作切分：当前未识别出稳定章节结构，后续需更依赖拆书摘要与资料层。',
      if (avgChars > 0)
        '- 建议章节字数带：均值约 $avgChars 字，参考波动区间 $minChars - $maxChars 字。',
      if (styleSummary.isNotEmpty) '- 继承风格限制：$styleSummary',
      if (styleSummary.isEmpty) '- 继承风格限制：当前未录入额外风格摘要，后续应以原作正文与章纲节奏为主。',
      '',
      '## 续写 / 同人差异提醒',
      '',
      if (option.sourceInheritanceMode ==
          BookDeconstructionSourceInheritanceMode.continuation)
        '当前路线会把原作章节镜像到 `chapters/inherited/`，后续正文需要把这些原作章节视为已经存在的连续正文前情。'
      else
        '当前路线不会把原作正文混入 `chapters/`，原作保持在来源与参考层；新作应以原作设定、人物、关系和风格为参照，允许重新开辟剧情。',
    ];
    return '${lines.join('\n')}\n';
  }

  String _groupIdOf(String optionId) {
    if (optionId.startsWith('continuation_')) {
      return 'continuation';
    }
    if (optionId.startsWith('fanfic_')) {
      return 'fanfic';
    }
    return 'unknown';
  }

  String _routeLabel(BookDeconstructionSourceInheritanceMode mode) {
    switch (mode) {
      case BookDeconstructionSourceInheritanceMode.continuation:
        return '续写';
      case BookDeconstructionSourceInheritanceMode.fanfic:
        return '同人';
    }
  }

  String _writerBias(BookDeconstructionSourceInheritanceMode mode) {
    switch (mode) {
      case BookDeconstructionSourceInheritanceMode.continuation:
        return '优先忠实承接原作节奏、字数带与叙事气质，不主动改写原作基础。';
      case BookDeconstructionSourceInheritanceMode.fanfic:
        return '优先把原作当作 canon / reference boundary，在尊重设定的前提下允许分支展开。';
    }
  }

  String _sourceHandlingSummary(
    BookDeconstructionSourceInheritanceMode mode,
    String inheritedChapterRootPath,
  ) {
    switch (mode) {
      case BookDeconstructionSourceInheritanceMode.continuation:
        return '原作正文会镜像到 `$inheritedChapterRootPath`，作为连续正文前情。';
      case BookDeconstructionSourceInheritanceMode.fanfic:
        return '原作留在来源与参考层，不进入当前项目正文。';
    }
  }

  String _writingDirection(BookDeconstructionSourceInheritanceMode mode) {
    switch (mode) {
      case BookDeconstructionSourceInheritanceMode.continuation:
        return '延续写作时，应把原作章节当成已经存在的章节正文，从原作结尾或指定承接点继续推进；人物语气、章节密度、叙事镜头和信息揭露速度都应尽量贴近原作。';
      case BookDeconstructionSourceInheritanceMode.fanfic:
        return '同人写作时，原作的角色、世界规则、象征物和关键关系要保留可识别性，但正文不需要沿用原作章节顺序，也不应把原作文本机械拼接到新作正文里。';
    }
  }
}
