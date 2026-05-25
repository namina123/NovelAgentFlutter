import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskTransactionContractService {
  LongTaskTransactionContractService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService;

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;

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
      _addUnique(contracts, '调用 run_continuity_check 保存结构化审稿报告。');
      _addUnique(contracts, '本步结束前必须至少写出一份 reviews/ 下的报告文件；没有保存报告就不算完成。');
    } else if (taskType == 'planning') {
      _addUnique(
        contracts,
        '不要写正文；优先写入 specs/project_spec.md、outline/总纲.md、chapter_outlines/章节任务清单.md。',
      );
      _addUnique(contracts, '如需调整队列，可调用 create_chapter_task 补充任务，但不要删除旧任务。');
    } else if (taskType == 'checkpoint') {
      _addUnique(contracts, '检查点通常不修改文件；整理产物并让用户确认继续、修订、暂停或改方向。');
    } else {
      _addUnique(
        contracts,
        '能产出章节正文时调用 write_project_file 自动保存；未确认草稿写 drafts/，确认或指定正文写 chapters/。',
      );
      _addUnique(
        contracts,
        '目标路径已存在且是在修正同一文件时必须传 overwrite=true，或改用 edit_project_file 精确修改。',
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
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    final instructions = <String>[];
    if (taskType == 'revision') {
      _addUnique(instructions, '这是修订任务：读取审稿报告和待修订文件，备份后做最小必要修改。');
      _addUnique(instructions, '最终只简短说明改了什么、写入了哪里、仍需人工确认什么。');
    } else if (taskType == 'review') {
      _addUnique(instructions, '这是独立审稿任务：读取来源，定位问题，保存报告，不重写正文。');
      _addUnique(
        instructions,
        '必须实际调用工具把报告写到 reviews/，最终只告诉用户报告路径和最重要风险，不要把口头分析冒充成已保存报告。',
      );
    } else if (taskType == 'planning') {
      _addUnique(instructions, '这是长篇规划任务：把种子扩展为可执行的作品规格、总纲、卷纲/章纲和任务清单。');
      _addUnique(instructions, '如项目已有规划，先判断是否兼容；不兼容时提出迁移或修订选项。');
    } else if (taskType == 'checkpoint') {
      _addUnique(instructions, '这是人工检查点：阅读前序产物，概括当前风险和推荐下一步。');
      _addUnique(instructions, '不要自动推进后续章节；用户确认后再由任务系统继续。');
    } else {
      _addUnique(instructions, '这是长篇章节写作单步：只推进当前章节，不跨章节抢写。');
      _addUnique(instructions, '写作前先对齐项目规格、章纲、最近摘要、人物状态和风格边界。');
      _addUnique(instructions, '如果上下文不满足写作条件，先保存/呈现需要补齐的选择，而不是硬写。');
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel ||
        mode == TaskRuntimeConstants.modeHumanOutlineAiDraft) {
      _addUnique(
        instructions,
        '这是长篇主链任务；本轮开始前优先调用 load_agent_skill 读取 novel-control-station，再按其中适合当前阶段的方法执行。',
      );
    }
    return instructions;
  }

  List<String> postprocessPlanForTask(JsonMap task) {
    // 中文注释: 后处理计划只描述下一轮应该做什么，不直接在这里触发任何工具。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final plan = <String>[];
    if (taskType == 'chapter') {
      _addUnique(plan, '正文写入后，下一步应读取草稿并保存章节摘要。');
      _addUnique(plan, '若出现明确设定事实，更新世界状态；若角色状态改变，更新角色状态。');
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
