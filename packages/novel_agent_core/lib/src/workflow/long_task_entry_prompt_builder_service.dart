import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_workspace_path_service.dart';
import '../project/project_fact_acquisition_contract_service.dart';
import 'long_task_writing_mode_catalog_service.dart';

class LongTaskEntryPromptBuilderService {
  const LongTaskEntryPromptBuilderService({
    LongTaskWritingModeCatalogService longTaskWritingModeCatalogService =
        const LongTaskWritingModeCatalogService(),
    ModeGuidanceWorkspacePathService modeGuidanceWorkspacePathService =
        const ModeGuidanceWorkspacePathService(),
    ProjectFactAcquisitionContractService factAcquisitionContractService =
        const ProjectFactAcquisitionContractService(),
  }) : _longTaskWritingModeCatalogService = longTaskWritingModeCatalogService,
       _modeGuidanceWorkspacePathService = modeGuidanceWorkspacePathService,
       _factAcquisitionContractService = factAcquisitionContractService;

  final LongTaskWritingModeCatalogService _longTaskWritingModeCatalogService;
  final ModeGuidanceWorkspacePathService _modeGuidanceWorkspacePathService;
  final ProjectFactAcquisitionContractService _factAcquisitionContractService;

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
      '当你还在收集长任务开局信息时，不要一次甩出长表单；一次只确认一个维度，并给 2-4 个清晰选项。',
      '需要用户做选择时，必须调用 present_user_options；每轮问题都允许用户直接自由补充，不要把自由输入排除在外。',
      '在核心承诺、世界边界、主角驱动力、风格边界、托管边界这些长期约束还没收束前，不要直接生成庞大任务链。',
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
    lines.add(
      _factAcquisitionContractService
          .build(
            workflowId: 'long_task_opening',
            projectTypeId: ValueReaders.stringValue(
              project['project_type'],
              'long_novel',
            ),
            intent: actionId,
          )
          .renderMarkdown(),
    );
    lines.add('');
    lines.add('本次动作要求：');
    for (final item in _requirements(actionId, payload: payload)) {
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
        final mode = ValueReaders.stringValue(
          payload['mode'],
          'seed_to_full_novel',
        );
        final modeProfile = _longTaskWritingModeCatalogService.modeById(mode);
        final modeTitle = ValueReaders.stringValue(modeProfile['title'], mode);
        final bestFor = ValueReaders.stringValue(modeProfile['best_for']);
        final description = ValueReaders.stringValue(
          modeProfile['description'],
        );
        final parts = <String>['请为当前项目启动“生成长篇队列”流程，本次选定的长任务写作模式是：$modeTitle。'];
        if (description.trim().isNotEmpty) {
          parts.add(description.trim());
        }
        if (bestFor.trim().isNotEmpty) {
          parts.add('这个模式适合：$bestFor');
        }
        parts.add('请围绕该模式给出可恢复任务链，而不是退回泛泛的通用建议。');
        return parts.join(' ');
    }
  }

  List<String> _requirements(
    String actionId, {
    JsonMap payload = const <String, Object?>{},
  }) {
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
        final mode = _longTaskWritingModeCatalogService.modeById(
          ValueReaders.stringValue(payload['mode']),
        );
        final modeId = ValueReaders.stringValue(mode['id']);
        final requirements = <String>[
          '先判断当前更像“已有大纲驱动写作”还是“只有创作种子，需要先规划长篇结构”。',
          '如果资料不足，不要硬生成庞大队列；先分步收束项目种子、主线目标、阶段结构和检查点要求。',
          '收集信息时优先一轮只问一个关键轴，并用 present_user_options 给出 2-4 个可选方向；用户如果直接自由补充，也要接住并继续往下收束。',
          '如果资料足够，请生成可恢复任务链，并明确建议保存到 tasks/ 和 tracking/ 的哪些位置。',
        ];
        switch (modeId) {
          case 'seed_autopilot_novel':
            requirements.add('优先把创作种子压缩成“世界观、主线承诺、主角轨迹、结局方向、禁区”五类长期约束。');
            requirements.add('把人工确认点压低到关键世界观和总主线，不要默认逐章征求确认。');
            requirements.add(
              '如果 `${_modeGuidanceWorkspacePathService.summaryMarkdownPath(modeId)}` 已存在，必须先读取它，再决定是否补问或建队列。',
            );
            break;
          case 'full_outline_consensus':
            requirements.add('前几步必须先完成全书走向、卷结构和主要角色弧光协商，再进入正文执行任务。');
            requirements.add('把全书大纲确认设计成显式检查点，确认前不要直接大规模写正文。');
            requirements.add(
              '如果 tracking/modes/full_outline_consensus/guidance.md 已显示当前模式已进入“确认开建”或完成状态，则应把现有共识视为足够先落一个“可修订的总纲/卷纲草案”，不要无条件退回 present_user_options。',
            );
            requirements.add(
              '只有在主线、分卷结构或结局承诺明显缺失时，才退回 present_user_options；否则优先写 outlines/story/ 或 outlines/volumes/ 的结构化草案。',
            );
            break;
          case 'volume_checkpoint_handoff':
            requirements.add('任务链要按卷分段，每卷结束设置显式回合总结和人工确认点。');
            requirements.add('卷内允许智能体自主推进，但跨卷转折必须预留复核任务。');
            break;
          case 'chapter_brief_supervised':
            requirements.add('把章纲确认放在高优先级检查点，正文和后处理放到章纲确认之后自动推进。');
            requirements.add('避免把每章都拆成过细的人工逐句确认任务。');
            break;
          case 'salvage_restructure_existing':
            requirements.add('先读取并分类旧稿、旧大纲、设定碎片和断档章节，再决定重构顺序。');
            requirements.add('优先生成“旧材料盘点 -> 主线重建 -> 阶段修复 -> 正式续写”的恢复式任务链。');
            break;
          default:
            break;
        }
        return requirements;
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
