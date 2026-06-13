import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/workflow/project_long_task_chapter_queue_runtime_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskChapterQueueRuntimeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectDescriptor project;
    late ProjectLongTaskChapterQueueRuntimeService service;
    late BuildLongTaskPlanUseCase buildPlanUseCase;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-long-task-queue-',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      service = ProjectLongTaskChapterQueueRuntimeService(
        taskRepository: taskRepository,
      );

      final modeService = LongTaskModeService();
      final pathPolicyService = LongTaskPathPolicyService();
      buildPlanUseCase = BuildLongTaskPlanUseCase(
        taskFactoryService: LongTaskTaskFactoryService(
          modeService: modeService,
          pathPolicyService: pathPolicyService,
        ),
        planRecordService: LongTaskPlanRecordService(modeService: modeService),
        changedPathsService: LongTaskPlanChangedPathsService(),
        markdownRenderer: LongTaskPlanMarkdownRenderer(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'ensureMaterializedQueueForNextTask keeps chapter length metadata for dynamically appended chapters',
      () async {
        const planId = 'plan_seed_dynamic';
        final planResult = buildPlanUseCase.execute(
          TaskRuntimeConstants.modeSeedToFullNovel,
          planId,
          options: const <String, Object?>{
            'runtime_baseline_id': 'continuous_autonomous',
            'seed_prompt': '历史科技轻喜剧长篇种子。',
            'chapter_count': 60,
            'checkpoint_interval': 4,
            'enable_chapter_word_constraints': true,
            'chapter_word_target': 2000,
            'chapter_word_min': 1600,
            'chapter_word_max': 2600,
            'sample_chapter_word_target': 1800,
            'sample_chapter_word_min': 1400,
            'sample_chapter_word_max': 2400,
            'chapter_length_rolling_window': 4,
            'chapter_length_mild_deviation_ratio': 0.18,
            'chapter_length_severe_deviation_ratio': 0.35,
            'chapter_length_mild_adjacent_delta_ratio': 0.22,
            'chapter_length_severe_adjacent_delta_ratio': 0.45,
          },
          createdAt: '2026-06-13T00:30:00Z',
        );

        final fullPlan = ValueReaders.mapValue(planResult['plan']);
        final fullTasks = ValueReaders.mapList(planResult['tasks']);
        final materialized = service.materializeInitialPlanWindow(
          TaskRuntimeConstants.modeSeedToFullNovel,
          fullPlan,
          fullTasks,
        );
        final initialTasks = ValueReaders.mapList(materialized['tasks'])
            .map(
              (task) =>
                  ValueReaders.deepCopyMap(task)
                    ..['status'] = TaskRuntimeConstants.statusSucceeded,
            )
            .toList(growable: false);

        await taskRepository.saveTasks(project, initialTasks);
        await taskRepository.saveRecord(
          project,
          'tracking/long_task/$planId.plan.json',
          fullPlan,
        );

        final currentTasks = await taskRepository.listTasks(project);
        final result = await service.ensureMaterializedQueueForNextTask(
          project,
          currentTasks,
        );

        expect(result['ok'], isTrue);
        expect(result['materialized'], isTrue);

        final chapter003 = await taskRepository.loadTask(
          project,
          <String, Object?>{'task_id': '${planId}_chapter_003'},
        );
        final metadata = ValueReaders.mapValue(chapter003['metadata']);
        final profile = ValueReaders.mapValue(
          metadata['chapter_length_profile'],
        );
        final policy = ValueReaders.mapValue(
          metadata['chapter_length_distribution_policy'],
        );

        expect(chapter003, isNotEmpty);
        expect(ValueReaders.intValue(metadata['chapter_word_target']), 2000);
        expect(ValueReaders.intValue(metadata['chapter_word_min']), 1600);
        expect(ValueReaders.intValue(metadata['chapter_word_max']), 2600);
        expect(ValueReaders.boolValue(profile['enabled']), isTrue);
        expect(ValueReaders.intValue(profile['target_length']), 2000);
        expect(ValueReaders.intValue(profile['preferred_min']), 1600);
        expect(ValueReaders.intValue(profile['preferred_max']), 2600);
        expect(ValueReaders.stringValue(profile['stage']), 'draft');
        expect(ValueReaders.intValue(policy['rolling_window']), 4);
      },
    );
  });
}
