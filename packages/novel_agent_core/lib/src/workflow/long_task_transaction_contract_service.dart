import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../agents/skill_routing_policy_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';

class LongTaskTransactionContractService {
  LongTaskTransactionContractService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    SkillRoutingPolicyService? skillRoutingPolicyService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService,
       _skillRoutingPolicyService =
           skillRoutingPolicyService ?? const SkillRoutingPolicyService();

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final SkillRoutingPolicyService _skillRoutingPolicyService;

  List<String> toolContractsForTask(JsonMap task) {
    // 中文注释: 工具契约把不同任务类型下允许或要求的动作明确写死，避免模型自由发挥越权。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final contracts = <String>[];
    _addUnique(contracts, '先判断需要读取哪些项目文件，再调用工具行动；不要把未确认脑暴写入正文。');
    _addUnique(contracts, '如果需要用户选择，调用 present_user_options 并停止本步。');
    if (taskType == 'revision') {
      _addUnique(
        contracts,
        '覆盖或精确替换前必须 create_backup，优先 edit_project_file 精确修改原文件。',
      );
      _addUnique(contracts, '不要把审稿报告、修复计划或解释性文字写入正文文件。');
    } else if (taskType == 'review') {
      _addUnique(contracts, '只读取来源文件和必要上下文，不修改正文、大纲、设定或风格文件。');
      _addUnique(
        contracts,
        '正式语义审稿必须调用 submit_semantic_review，提交结构化 findings 和 recommended_disposition；不要用散文评论冒充正式交付。',
      );
      _addUnique(
        contracts,
        '如果宿主还要求保存 reviews/ 报告，把报告视为 submit_semantic_review 的镜像产物，而不是反过来用报告替代领域工具交付。',
      );
    } else if (taskType == 'planning') {
      _addUnique(
        contracts,
        '不要写正文；优先写入 specs/project_spec.md、outline/总纲.md、chapter_outlines/章节任务清单.md。',
      );
      _addUnique(contracts, '如需调整队列，可调用 create_chapter_task 补充任务，但不要删除旧任务。');
      _addUnique(
        contracts,
        '如果本轮在设计项目级 narrative profile / 解释器或长期规则，使用 propose_narrative_profile_update；关键信息不明时调用 request_profile_clarification 停下等待。',
      );
    } else if (taskType == 'checkpoint') {
      _addUnique(contracts, '检查点通常不修改文件；整理产物并让用户确认继续、修订、暂停或改方向。');
    } else {
      _addUnique(
        contracts,
        '正式章节、样章或补写结果必须通过 submit_chapter_delivery 交付；不要只写文件就宣布完成章节任务。',
      );
      _addUnique(
        contracts,
        '如果只是脑暴方案、局部片段或风险说明，不要把它们伪装成 submit_chapter_delivery 的正式交付。',
      );
    }
    return contracts;
  }

  List<String> domainToolContractsForTask(JsonMap task) {
    // 中文注释: 领域工具契约单独成段，专门告诉模型本轮必须用哪类 domain tool 收口。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final contracts = <String>[
      '示例只用于说明调用形态，不是题材、机制或世界观范本；未知变化、非常规设定和未来扩展字段都要保留，不要擅自归类成固定套路。',
    ];
    if (taskType == 'review') {
      _addUnique(
        contracts,
        '本轮 reviewer 的正式结论必须通过 submit_semantic_review 提交；不要把自然语言点评、修文建议或任务调度冒充为已完成的审稿交付。',
      );
      _addUnique(
        contracts,
        '如果本轮发现来源证据、引用边界或资料缺口，优先用 link_information_evidence、submit_research_note 或 propose_reference_work 收口；不要只把证据缺口留在散文评语里。',
      );
    } else if (taskType == 'planning') {
      _addUnique(
        contracts,
        '如果本轮承担 profile architect / 规则架构职责，使用 propose_narrative_profile_update 提交长期规则提案；适用范围、保留策略或未知字段存在关键歧义时改用 request_profile_clarification。',
      );
      _addUnique(
        contracts,
        '如果本轮沉淀的是长期设定，用 propose_knowledge_card；如果沉淀的是结构巧思、象征系统、命名暗线或章节回扣，用 propose_design_element；外部资料先 request_external_research / submit_research_note，再决定是否提升。',
      );
    } else if (taskType == 'revision') {
      _addUnique(
        contracts,
        '本轮 recovery / repair 只解决当前修订目标，不扩展成新章节、总纲改写或多目标规划；如果需要重新形成正式章节交付，只围绕当前目标收口。',
      );
    } else if (taskType != 'checkpoint') {
      _addUnique(
        contracts,
        '本轮 writer 的正式章节收口必须调用 submit_chapter_delivery；不要只靠 write_project_file、散文说明或多文件拼装来冒充交付成功。',
      );
      _addUnique(
        contracts,
        '如果写作中确定了新的长期世界事实，用 propose_knowledge_card；如果确定了可复用巧思、结构回扣或符号系统，必须用 propose_design_element；没有显著信息变化时不要编造信息卡。',
      );
    }
    return contracts;
  }

  List<String> primaryInstructionsForTask(JsonMap task) {
    // 中文注释: 主要执行要求为模型提供本轮工作的任务边界和收口方式。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final instructions = <String>[];
    if (taskType == 'revision') {
      _addUnique(instructions, '这是修订任务：读取审稿报告和待修订文件，备份后做最小必要修改。');
      _addUnique(
        instructions,
        '本轮 recovery / repair 目标单一：只修当前缺口，不顺手改下一章、总纲或无关设定。',
      );
      _addUnique(instructions, '最终只简短说明改了什么、写入了哪里、仍需人工确认什么。');
    } else if (taskType == 'review') {
      _addUnique(instructions, '这是独立审稿任务：读取来源，定位问题，保存报告，不重写正文。');
      _addUnique(
        instructions,
        '必须实际调用 submit_semantic_review 提交结构化结论；最终只告诉用户最重要风险和是否建议 repair，不要把口头分析冒充成已完成审稿。',
      );
    } else if (taskType == 'planning') {
      _addUnique(instructions, '这是长篇规划任务：把种子扩展为可执行的作品规格、总纲、卷纲/章纲和任务清单。');
      _addUnique(
        instructions,
        '如果本轮涉及项目级 narrative profile / 规则架构，使用 profile architect 契约：提案走 propose_narrative_profile_update，缺口走 request_profile_clarification。',
      );
      _addUnique(instructions, '如项目已有规划，先判断是否兼容；不兼容时提出迁移或修订选项。');
    } else if (taskType == 'checkpoint') {
      _addUnique(instructions, '这是人工检查点：阅读前序产物，概括当前风险和推荐下一步。');
      _addUnique(instructions, '不要自动推进后续章节；用户确认后再由任务系统继续。');
    } else {
      _addUnique(instructions, '这是长篇章节写作单步：只推进当前章节，不跨章节抢写。');
      _addUnique(
        instructions,
        '当正文已经达到正式交付条件时，用 submit_chapter_delivery 收口，而不是停留在“已写好但未交付”的口头状态。',
      );
      _addUnique(instructions, '写作前先对齐项目规格、章纲、最近摘要、人物状态和风格边界。');
      _addUnique(instructions, '如果上下文不满足写作条件，先保存/呈现需要补齐的选择，而不是硬写。');
    }
    return instructions;
  }

  List<String> skillRoutingForTask(JsonMap task) {
    // 中文注释: 长任务页和 CLI 共享同一套技能路由提示，避免每个入口各自硬编码 skill 名。
    final metadata = ValueReaders.mapValue(task['metadata']);
    final signal = _skillRoutingPolicyService.buildActivationSignal(
      intent: 'workflow_task',
      projectType: 'novel',
      userPrompt: [
        ValueReaders.stringValue(task['title']),
        ValueReaders.stringValue(task['goal']),
        ValueReaders.stringValue(task['brief']),
      ].where((item) => item.trim().isNotEmpty).join('\n'),
      routeContext: <String, Object?>{
        'task_type': ValueReaders.stringValue(task['task_type']),
        'mode': ValueReaders.stringValue(task['mode']),
        'title': ValueReaders.stringValue(task['title']),
        'goal': ValueReaders.stringValue(task['goal']),
        'brief': ValueReaders.stringValue(task['brief']),
        'review_type': ValueReaders.stringValue(metadata['review_type']),
      },
    );
    final policy = _skillRoutingPolicyService.resolvePolicy(signal);
    return _skillRoutingPolicyService.buildGuidanceLines(policy);
  }

  List<String> postprocessPlanForTask(JsonMap task) {
    // 中文注释: 后处理计划只描述下一轮应该做什么，不直接在这里触发任何工具。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final plan = <String>[];
    if (taskType == 'chapter') {
      _addUnique(plan, '正文写入后，下一步应读取最新正文并保存章节摘要。');
      _addUnique(
        plan,
        '若出现明确设定事实，更新世界状态；若角色状态改变，更新角色状态；若伏笔、时间线或关系发生推进，也要回填对应共享资产。',
      );
      _addUnique(plan, '保存连续性、剧情或文风风险报告，供用户确认。');
    } else if (taskType == 'revision') {
      _addUnique(plan, '修订后需要复核目标文件、原审稿报告和 diff，保存修订检查报告。');
    } else if (taskType == 'planning') {
      _addUnique(plan, '规划完成后停在人工检查点，等待用户确认总纲、样章策略和章节任务。');
    }
    return plan;
  }

  String singleStepBoundary(JsonMap task, {String runMode = ''}) {
    // 中文注释: 单步边界是长任务稳定性的关键提示，明确告诉模型别连续抢跑。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    _modeService.normalizeMode(ValueReaders.stringValue(task['mode'], runMode));
    return taskType == 'checkpoint'
        ? '本次只整理检查点，不自动推进后续章节。'
        : '本次只执行一个可审计安全单步；不要连续抢跑后续任务。';
  }

  String joinOrNone(List<Object?> items) {
    // 中文注释: 提示渲染时空数组统一显示“暂无”，避免出现空白行让用户误判。
    final joined = _pathPolicyService.joinStrings(items, '、');
    return joined.isEmpty ? '暂无' : joined;
  }

  void _addUnique(List<String> items, String value) {
    // 中文注释: 这里保持顺序去重，让契约项在提示里稳定排序。
    final clean = value.trim();
    if (clean.isNotEmpty && !items.contains(clean)) {
      items.add(clean);
    }
  }
}
