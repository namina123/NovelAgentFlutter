import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

// 中文注释: 这组测试专门覆盖 P0-1 长任务队列健壮性改造：
// 并发守卫、watchdog 生产生命周期收口、以及显式恢复路径下运行记录缺失的如实返回。
// 通过真实 workflowRuntimeService（注入真实 watchdog）端到端验证，避免直接重造队列服务的庞大依赖。

void main() {
  group('ProjectWorkflowRuntimeService runWorkflowTaskQueue P0-1 hardening', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectPromptTemplateService promptTemplateService;
    late LocalLongTaskRunRegistry runRegistry;
    late LongTaskWatchdog longTaskWatchdog;
    late ProjectWorkflowRuntimeService workflowRuntimeService;
    late ProjectDescriptor project;

    const settings = AppSettings(
      defaultProviderId: '',
      defaultAgentId: '',
      defaultModelId: '',
      defaultProjectPath: '',
      autoSaveDrafts: false,
      providers: <ProviderEndpointSettings>[],
    );

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_queue_hardening_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      promptTemplateService = ProjectPromptTemplateService(
        workspacePort: workspacePort,
      );
      runRegistry = LocalLongTaskRunRegistry(
        settingsRootPath: tempDirectory.path,
      );
      longTaskWatchdog = LongTaskWatchdog(
        runRegistry: runRegistry,
        heartbeatScheduler: LongTaskHeartbeatScheduler(
          runRegistry: runRegistry,
          runtimeBaselineCatalogService: const RuntimeBaselineCatalogService(),
        ),
      );
      workflowRuntimeService = ProjectWorkflowRuntimeService(
        taskRepository: taskRepository,
        promptTemplateService: promptTemplateService,
        generateDraftUseCaseFactory: (_, __) {
          throw UnimplementedError('queue hardening test only');
        },
        longTaskWatchdog: longTaskWatchdog,
      );
      project = ProjectDescriptor(
        id: 'queue_hardening_project',
        name: '队列健壮性测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
      );
    });

    tearDown(() async {
      await longTaskWatchdog.stop();
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'resumeLongTaskRun returns long_task_run_record_missing when the run record is absent '
      'instead of silently starting an empty queue',
      () async {
        final result = await workflowRuntimeService.resumeLongTaskRun(
          project,
          settings,
          'tracking/long_task_runs/does_not_exist.json',
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          'long_task_run_record_missing',
        );
        expect(
          ValueReaders.stringValue(result['continue_long_task_run_path']),
          'tracking/long_task_runs/does_not_exist.json',
        );
      },
    );

    test(
      'runWorkflowTaskQueue rejects a concurrent same-project call with already_running',
      () async {
        // 中文注释: Set.add 在首个 await 之前同步完成，因此并发发起的两个调用里，
        // 后到的那个会读到已登记的 projectId 并直接返回 already_running。
        final first = workflowRuntimeService.runWorkflowTaskQueue(
          project,
          settings,
        );
        final second = workflowRuntimeService.runWorkflowTaskQueue(
          project,
          settings,
        );
        final results = await Future.wait(<Future<JsonMap>>[first, second]);

        final errors = results
            .map((result) => ValueReaders.stringValue(result['error']))
            .toSet();
        expect(errors, contains('already_running'));
        // 中文注释: 先到的那次在没有任务的项目上应正常落到 no_runnable_task，而不是也被拒绝。
        expect(
          results.any(
            (result) =>
                ValueReaders.stringValue(result['stop_reason']) ==
                'no_runnable_task',
          ),
          isTrue,
        );
        // 中文注释: 守卫在 finally 中释放，结束后再次单发不应被拒绝。
        final again = await workflowRuntimeService.runWorkflowTaskQueue(
          project,
          settings,
        );
        expect(
          ValueReaders.stringValue(again['error']) == 'already_running',
          isFalse,
        );
      },
    );

    test(
      'runWorkflowTaskQueue starts and stops the watchdog so it does not leak after a run',
      () async {
        expect(longTaskWatchdog.isWatchdogRunning, isFalse);

        final result = await workflowRuntimeService.runWorkflowTaskQueue(
          project,
          settings,
        );

        // 中文注释: 空项目落在 no_runnable_task，但更重要的是 watchdog 在 finally 里被停掉，
        // 不残留为运行状态。
        expect(
          ValueReaders.stringValue(result['stop_reason']),
          'no_runnable_task',
        );
        expect(longTaskWatchdog.isWatchdogRunning, isFalse);
      },
    );
  });
}
