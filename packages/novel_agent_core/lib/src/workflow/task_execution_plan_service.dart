import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_chapter_gate_policy_service.dart';
import 'task_definition_service.dart';
import 'task_runtime_constants.dart';

class TaskExecutionPlanService {
  TaskExecutionPlanService({
    required TaskDefinitionService taskDefinitionService,
    LongTaskChapterGatePolicyService? chapterGatePolicyService,
  }) : _taskDefinitionService = taskDefinitionService,
       _chapterGatePolicyService =
           chapterGatePolicyService ?? const LongTaskChapterGatePolicyService();

  final TaskDefinitionService _taskDefinitionService;
  final LongTaskChapterGatePolicyService _chapterGatePolicyService;

  JsonMap executionPlan(JsonMap task) {
    // 中文注释: 执行计划只生成步骤骨架，不直接调用模型或存储，是纯领域规则的一部分。
    final normalized = _taskDefinitionService.normalizeTask(task);
    final mode = ValueReaders.stringValue(
      normalized['mode'],
      TaskRuntimeConstants.modeSingleChapterAtomic,
    );
    final taskType = ValueReaders.stringValue(
      normalized['task_type'],
      'chapter',
    );
    final steps = List<JsonMap>.from(_baseStepsForTask(taskType));
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      steps.insert(
        0,
        _step('confirm_queue_position', '确认章节队列位置', '确认依赖任务、前序摘要和本章目标。'),
      );
      steps.add(
        _step('wait_user_checkpoint', '等待用户检查点', '完成章节后等待用户确认是否继续下一章。'),
      );
    } else if (mode == TaskRuntimeConstants.modeHumanOutlineAiDraft &&
        !<String>['planning', 'checkpoint'].contains(taskType)) {
      steps.insert(
        0,
        _step(
          'read_human_outline',
          '读取用户确认的大纲',
          '优先读取 outline/volume_outlines/chapter_outlines。',
        ),
      );
    } else if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        !<String>['planning', 'checkpoint'].contains(taskType)) {
      steps.insert(
        0,
        _step('expand_seed_spec', '扩展创作规格', '从主题、世界观和走向拆出作品规格和章节队列。'),
      );
      steps.add(_step('major_checkpoint', '关键节点确认', '在大纲、样章或卷末要求用户确认。'));
    }
    if (taskType == 'chapter' &&
        _chapterGatePolicyService.requiresChapterGate(normalized)) {
      steps.addAll(<JsonMap>[
        _step(
          'run_chapter_gate_review',
          '执行章级审稿闸门',
          '对当前章节运行结构化审稿，检查连续性、剧情推进和风格守恒。',
        ),
        _step(
          'repair_if_gate_failed',
          '必要时自动返工',
          '若审稿报告指出问题，则沿用共享 repair 链创建返工任务并修复当前章。',
        ),
        _step('advance_after_gate', '通过闸门后推进下一章', '仅当本章闸门通过时，才允许自动解锁下一章任务。'),
      ]);
    }
    return <String, Object?>{
      'task_id': normalized['id'],
      'mode': mode,
      'task_type': taskType,
      'steps': steps,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  List<JsonMap> _baseStepsForTask(String taskType) {
    // 中文注释: 不同任务类型的默认步骤模板在这里集中维护，便于后续替换成更细粒度规划器。
    switch (taskType) {
      case 'summary':
        return <JsonMap>[
          _step('read_sources', '读取来源', '读取需要总结的章节、文章或摘要。'),
          _step('assemble_context', '组装上下文', '生成摘要专用 context pack。'),
          _step('save_summary', '保存摘要', '写入 summaries/ 并记录来源。'),
        ];
      case 'revision':
        return <JsonMap>[
          _step('read_target', '读取待修订文件', '读取原文和相关风格/设定。'),
          _step('create_backup', '创建备份', '覆盖或替换前创建 backups/ 检查点。'),
          _step('edit_target', '执行修订', '按精确替换或追加写回。'),
          _step('review_changes', '检查修订', '保存修订检查报告。'),
        ];
      case 'review':
        return <JsonMap>[
          _step('read_sources', '读取审稿来源', '读取需要检查的正文、大纲、设定或风格文件。'),
          _step('assemble_context', '组装审稿上下文', '纳入相关摘要、设定和风格约束。'),
          _step('run_review', '执行审稿', '分析连续性、剧情、文风或综合质量问题。'),
          _step('save_report', '保存审稿报告', '调用连续性检查工具写入 reviews/。'),
        ];
      case 'planning':
        return <JsonMap>[
          _step('read_seed', '读取创作种子', '读取用户种子、项目规格、灵感参考和已有风格。'),
          _step('assemble_context', '组装规划上下文', '纳入项目规格、世界书、风格、知识库和灵感参考。'),
          _step('expand_seed_spec', '扩展作品规格', '把少量种子扩展为题材、主题、主线、角色与世界观规则。'),
          _step(
            'save_project_spec',
            '保存项目规格',
            '写入 specs/project_spec.md 或相关规格文件。',
          ),
          _step(
            'save_outline',
            '保存总纲/章纲',
            '写入 outline/、volume_outlines/ 或 chapter_outlines/。',
          ),
          _step('create_followup_tasks', '创建后续任务', '必要时补充或修正章节任务。'),
          _step('wait_user_checkpoint', '等待用户确认', '规划完成后等待用户确认样章或继续队列。'),
        ];
      case 'checkpoint':
        return <JsonMap>[
          _step('read_outputs', '读取检查点产物', '读取前序章节、摘要、审稿报告或规划文件。'),
          _step('present_checkpoint', '展示检查点', '向用户说明当前成果、风险和可选方向。'),
          _step('wait_user_decision', '等待用户决策', '由用户确认、修改、暂停或创建修复任务。'),
        ];
      case 'world_update':
        return <JsonMap>[
          _step('extract_facts', '提取设定事实', '从来源文本提取世界书或角色状态。'),
          _step(
            'update_memory',
            '更新长期记忆',
            '写入 world/、characters/ 或 tracking/。',
          ),
        ];
      default:
        return <JsonMap>[
          _step('read_task', '读取任务', '读取章节目标、依赖、章纲和来源路径。'),
          _step('assemble_context', '组装上下文', '按任务目标生成 context pack。'),
          _step('draft_chapter', '生成正文草稿', '调用模型生成章节或场景正文。'),
          _step('save_draft', '保存草稿', '未确认正文写入 drafts/；确认后的正式正文再进入 chapters/。'),
          _step('summarize_chapter', '保存章节摘要', '写入 summaries/。'),
          _step(
            'update_memory',
            '更新世界书与角色',
            '更新 world/、characters/ 和 tracking/。',
          ),
          _step('continuity_check', '连续性检查', '保存验证报告。'),
          _step('mark_done', '标记完成', '更新任务状态与输出路径。'),
        ];
    }
  }

  JsonMap _step(String id, String title, String description) {
    // 中文注释: 统一步骤结构能让 UI 和 CLI 直接渲染，不必再猜字段名称。
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'status': 'pending',
    };
  }
}
