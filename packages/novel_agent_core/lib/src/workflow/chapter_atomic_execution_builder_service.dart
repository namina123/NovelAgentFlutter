import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../context/context_assembler_service.dart';
import 'chapter_atomic_constants.dart';
import 'chapter_atomic_intent_service.dart';
import 'chapter_atomic_output_path_service.dart';
import 'chapter_atomic_prompt_builder_service.dart';
import 'chapter_atomic_step_state_service.dart';
import 'chapter_atomic_event_service.dart';
import 'task_execution_plan_service.dart';
import 'task_runtime_constants.dart';

class ChapterAtomicExecutionBuilderService {
  ChapterAtomicExecutionBuilderService({
    required ChapterAtomicPromptBuilderService promptBuilderService,
    required ChapterAtomicIntentService intentService,
    required ChapterAtomicOutputPathService outputPathService,
    required ChapterAtomicStepStateService stepStateService,
    required ChapterAtomicEventService eventService,
    required ContextAssemblerService contextAssemblerService,
    required TaskExecutionPlanService executionPlanService,
  }) : _promptBuilderService = promptBuilderService,
       _intentService = intentService,
       _outputPathService = outputPathService,
       _stepStateService = stepStateService,
       _eventService = eventService,
       _contextAssemblerService = contextAssemblerService,
       _executionPlanService = executionPlanService;

  final ChapterAtomicPromptBuilderService _promptBuilderService;
  final ChapterAtomicIntentService _intentService;
  final ChapterAtomicOutputPathService _outputPathService;
  final ChapterAtomicStepStateService _stepStateService;
  final ChapterAtomicEventService _eventService;
  final ContextAssemblerService _contextAssemblerService;
  final TaskExecutionPlanService _executionPlanService;

  JsonMap prepareExecution(JsonMap input) {
    // 中文注释: 这个入口把任务、上下文和步骤合同拼成纯内存执行包，不涉及任何宿主存储。
    final project = ValueReaders.mapValue(input['project']);
    if (project.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Project is empty.',
        'relative_path': '',
      };
    }
    final normalized = _promptBuilderService.normalizeTask(
      ValueReaders.mapValue(input['task']),
    );
    final taskId = ValueReaders.stringValue(normalized['id']).trim();
    if (taskId.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task id is required.',
        'relative_path': '',
      };
    }

    final intent = _intentService.intentForTask(normalized);
    final contextPack = _contextAssemblerService.assemble(<String, Object?>{
      'project': project,
      'project_files': ValueReaders.objectList(input['project_files']),
      'session_context': ValueReaders.stringValue(input['session_context']),
      'current_file_body': ValueReaders.stringValue(input['current_file_body']),
      'current_file_path': ValueReaders.stringValue(input['current_file_path']),
      'user_prompt': _promptBuilderService.taskPrompt(normalized),
      'intent': intent,
      'agent': ValueReaders.mapValue(input['agent']),
      'optional_agents': ValueReaders.objectList(input['optional_agents']),
      'context_settings': ValueReaders.mapValue(input['context_settings']),
      'model_profile': ValueReaders.mapValue(input['model_profile']),
      'memory_sections': ValueReaders.objectList(input['memory_sections']),
      'expression_constraint_profiles': ValueReaders.objectList(
        input['expression_constraint_profiles'],
      ),
      'project_expression_constraint_bindings': ValueReaders.objectList(
        input['project_expression_constraint_bindings'],
      ),
      'project_file_section_plan': ValueReaders.objectList(
        input['project_file_section_plan'],
      ),
      'project_file_contents': ValueReaders.mapValue(
        input['project_file_contents'],
      ),
      'project_spec_markdown': ValueReaders.stringValue(
        input['project_spec_markdown'],
      ),
    });
    final plan = _executionPlanService.executionPlan(normalized);
    final execution = _executionRecord(
      task: normalized,
      plan: plan,
      contextPack: contextPack,
      data: input,
    );
    final safeId = _outputPathService.safeId(
      ValueReaders.stringValue(execution['id']),
    );
    final executionPath =
        '${ChapterAtomicConstants.executionRoot}/$safeId.execution.json';
    final checklistPath =
        '${ChapterAtomicConstants.executionRoot}/$safeId.checklist.md';
    execution['relative_path'] = executionPath;
    execution['checklist_path'] = checklistPath;

    return <String, Object?>{
      'ok': true,
      'relative_path': executionPath,
      'execution_path': executionPath,
      'checklist_path': checklistPath,
      'context_pack_id': contextPack['id'],
      'proposed_output_paths': execution['proposed_output_paths'],
      'execution': execution,
    };
  }

  JsonMap _executionRecord({
    required JsonMap task,
    required JsonMap plan,
    required JsonMap contextPack,
    required JsonMap data,
  }) {
    // 中文注释: 执行记录只表达当前任务的可恢复运行状态和计划，不承担持久化职责。
    final taskId = ValueReaders.stringValue(task['id']);
    final executionId =
        'chapter_atomic_${_outputPathService.safeId(taskId)}_${DateTime.now().microsecondsSinceEpoch}';
    final steps = _stepStateService.prepareSteps(
      ValueReaders.objectList(plan['steps']),
    );
    final now = DateTime.now().toIso8601String();
    return <String, Object?>{
      'schema_version': 1,
      'id': executionId,
      'task_id': taskId,
      'task_title': ValueReaders.stringValue(task['title'], '未命名任务'),
      'task_relative_path': ValueReaders.stringValue(task['relative_path']),
      'mode': ValueReaders.stringValue(
        task['mode'],
        TaskRuntimeConstants.modeSingleChapterAtomic,
      ),
      'task_type': ValueReaders.stringValue(task['task_type'], 'chapter'),
      'chapter': ValueReaders.stringValue(task['chapter']),
      'goal': ValueReaders.stringValue(task['goal']),
      'brief': ValueReaders.stringValue(task['brief']),
      'status': 'prepared',
      'safe_to_run_unattended': false,
      'requires_model': true,
      'requires_user_checkpoint': ValueReaders.boolValue(
        data['requires_user_checkpoint'],
      ),
      'context_pack_id': ValueReaders.stringValue(contextPack['id']),
      'context_pack_summary': ValueReaders.stringValue(contextPack['summary']),
      'context_pack': contextPack,
      'proposed_output_paths': _outputPathService.proposedOutputPaths(task),
      'steps': steps,
      'events': _eventService.appendEvent(
        const <Object?>[],
        'prepared',
        '章节原子执行包已准备；尚未调用模型。',
        const <String, Object?>{},
        createdAt: now,
      ),
      'created_at': now,
      'updated_at': now,
    };
  }
}
