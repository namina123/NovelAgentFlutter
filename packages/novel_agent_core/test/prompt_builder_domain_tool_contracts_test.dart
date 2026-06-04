import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt builder domain tool contracts', () {
    final projectPromptContract = ProjectPromptContract();
    final draftPromptBuilder = DraftPromptBuilderService(
      projectPromptContract: projectPromptContract,
    );
    final modeService = LongTaskModeService();
    final pathPolicyService = LongTaskPathPolicyService();
    final contractService = LongTaskTransactionContractService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    final taskPromptRenderer = LongTaskTaskPromptRenderer(
      contractService: contractService,
    );
    final postprocessPromptRenderer = LongTaskPostprocessPromptRenderer(
      contractService: contractService,
    );

    test(
      'draft prompt tells writer to use submit_chapter_delivery without fixed genre templates',
      () {
        final prompt = draftPromptBuilder.build(
          project: const <String, Object?>{
            'title': '项目A',
            'project_type': 'novel',
          },
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '作者',
            'role': '负责正文',
          },
          contextPack: const <String, Object?>{'context_text': '上下文摘要'},
          userPrompt: '写出第一章',
          title: '第01章',
          intent: 'draft',
        );

        expect(prompt, contains('submit_chapter_delivery'));
        expect(prompt, contains('示例只用于说明调用形态'));
        expect(prompt, isNot(contains('快穿')));
        expect(prompt, isNot(contains('死亡回归')));
      },
    );

    test(
      'draft prompt gives reviewer and recovery distinct domain tool contracts',
      () {
        final reviewerPrompt = draftPromptBuilder.build(
          project: const <String, Object?>{'title': '项目B'},
          agent: const <String, Object?>{
            'id': 'reviewer',
            'name': '审稿',
            'role': '负责审稿',
          },
          contextPack: const <String, Object?>{'context_text': '上下文摘要'},
          userPrompt: '检查这一章的问题',
          title: '',
          intent: 'review',
        );
        final recoveryPrompt = draftPromptBuilder.build(
          project: const <String, Object?>{'title': '项目C'},
          agent: const <String, Object?>{
            'id': 'recovery',
            'name': '恢复',
            'role': '负责修复缺失交付',
          },
          contextPack: const <String, Object?>{'context_text': '上下文摘要'},
          userPrompt: '补回当前章节交付',
          title: '第09章',
          intent: 'recovery',
        );

        expect(reviewerPrompt, contains('submit_semantic_review'));
        expect(recoveryPrompt, contains('本轮目标只能有一个'));
        expect(recoveryPrompt, contains('submit_chapter_delivery'));
      },
    );

    test(
      'draft prompt exposes profile architect contract through profile proposal and clarification tools',
      () {
        final prompt = draftPromptBuilder.build(
          project: const <String, Object?>{'title': '项目D'},
          agent: const <String, Object?>{
            'id': 'profile_architect',
            'name': 'Profile Architect',
            'role': '负责叙事规则与长期 profile 设计',
          },
          contextPack: const <String, Object?>{'context_text': '上下文摘要'},
          userPrompt: '整理项目级叙事解释器规则',
          title: '',
          intent: 'profile_architect',
        );

        expect(prompt, contains('propose_narrative_profile_update'));
        expect(prompt, contains('request_profile_clarification'));
        expect(prompt, contains('例子不是范本'));
      },
    );

    test(
      'long task prompts require chapter delivery review submission and profile architect contracts',
      () {
        final chapterPrompt = taskPromptRenderer.renderTaskPrompt(
          _taskTransaction(
            contractService: contractService,
            task: const <String, Object?>{
              'task_type': 'chapter',
              'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
            },
            taskTitle: '写第一章',
            goal: '完成第一章',
            agentRole: 'chapter_writer',
          ),
        );
        final reviewPrompt = taskPromptRenderer.renderTaskPrompt(
          _taskTransaction(
            contractService: contractService,
            task: const <String, Object?>{
              'task_type': 'review',
              'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            },
            taskTitle: '审稿第一章',
            goal: '给出结构化语义审稿',
            agentRole: 'reviewer',
          ),
        );
        final planningPrompt = taskPromptRenderer.renderTaskPrompt(
          _taskTransaction(
            contractService: contractService,
            task: const <String, Object?>{
              'task_type': 'planning',
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            },
            taskTitle: '规划项目规则',
            goal: '扩展项目规格与叙事规则',
            agentRole: 'planner',
          ),
        );

        expect(chapterPrompt, contains('submit_chapter_delivery'));
        expect(reviewPrompt, contains('submit_semantic_review'));
        expect(planningPrompt, contains('propose_narrative_profile_update'));
        expect(planningPrompt, contains('request_profile_clarification'));
      },
    );

    test(
      'revision postprocess prompt keeps recovery target singular and reviewer structured',
      () {
        final prompt = postprocessPromptRenderer.renderPostprocessPrompt(
          const <String, Object?>{
            'phase': 'revision_review',
            'task_title': '修订第一章',
            'task_id': 'revision-001',
            'chapter': '第01章',
            'goal': '修复当前章节',
            'execution_path': 'tracking/chapter_atomic/revision.execution.json',
            'revision_targets': <Object?>['chapters/ch01.md'],
            'original_review_path': 'reviews/general/ch01.md',
            'revision_diff_path': 'tracking/revision_diffs/ch01.md',
            'project_templates': <String, Object?>{},
          },
        );

        expect(prompt, contains('本轮目标只能有一个'));
        expect(prompt, contains('submit_semantic_review'));
        expect(prompt, contains('不要继续重写正文'));
      },
    );
  });
}

Map<String, Object?> _taskTransaction({
  required LongTaskTransactionContractService contractService,
  required Map<String, Object?> task,
  required String taskTitle,
  required String goal,
  required String agentRole,
}) {
  return <String, Object?>{
    'task_title': taskTitle,
    'task_id': '$taskTitle-id',
    'task_type': task['task_type'],
    'mode': task['mode'],
    'agent_role': agentRole,
    'chapter': '第01章',
    'goal': goal,
    'brief': 'brief',
    'source_paths': const <Object?>['outline/总纲.md'],
    'output_paths': const <Object?>['chapters/ch01.md'],
    'instructions': contractService.primaryInstructionsForTask(task),
    'context_needs': const <String>['先读取必要上下文。'],
    'tool_contracts': contractService.toolContractsForTask(task),
    'domain_tool_contracts': contractService.domainToolContractsForTask(task),
    'skill_routing': const <String>[],
    'postprocess_plan': const <String>[],
    'project_templates': const <String, Object?>{},
    'single_step_boundary': '本次只执行一个安全单步。',
  };
}
