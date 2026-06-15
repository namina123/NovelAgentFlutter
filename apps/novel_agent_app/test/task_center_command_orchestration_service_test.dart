import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/application/services/task_center_command_orchestration_service.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('TaskCenterCommandOrchestrationService', () {
    test('runs shared action command through the unified command environment', () async {
      // 中文注释: 这里用真实环境合同对象而不是自定义接口实现，确保测试跟服务实际调用形态一致。
      final service = TaskCenterCommandOrchestrationService();
      final commandInFlightStates = <bool>[];
      final statusMessages = <String>[];
      int refreshTaskCenterCallCount = 0;
      int refreshTaskCenterViewCallCount = 0;
      int longTaskPulseCount = 0;
      int syncWorkbenchResourcesCallCount = 0;
      int adoptSelectionsCallCount = 0;
      int refreshLongTaskStationCallCount = 0;
      String selectedTaskId = 'tasks/current.task.json';

      final environment = TaskCenterCommandEnvironment(
        currentProject: () => ProjectDescriptor(
          id: 'project_task_center',
          name: '任务中心测试项目',
          rootPath: 'D:/projects/task_center',
        ),
        settings: () => null,
        selectedTaskId: () => selectedTaskId,
        setSelectedTaskId: (value) {
          selectedTaskId = value;
        },
        setTaskCenterCommandInFlight: (value) {
          commandInFlightStates.add(value);
        },
        setTaskCenterStatusMessage: (value) {
          statusMessages.add(value);
        },
        selectedTaskSelector: () => const <String, Object?>{
          'relative_path': 'tasks/current.task.json',
          'task_id': 'task_current',
        },
        refreshTaskCenter: ({String? status}) async {
          refreshTaskCenterCallCount += 1;
        },
        refreshTaskCenterView: () async {
          refreshTaskCenterViewCallCount += 1;
        },
        requestTaskCenterLongTaskPulse: () {
          longTaskPulseCount += 1;
        },
        syncWorkbenchResources: () async {
          syncWorkbenchResourcesCallCount += 1;
        },
        adoptTaskCenterRunSelectionsFromResult: (result) async {
          adoptSelectionsCallCount += 1;
          selectedTaskId = ValueReaders.stringValue(
            ValueReaders.mapValue(result['task'])['relative_path'],
            selectedTaskId,
          );
        },
        refreshLongTaskStationAfterTaskCenterMutation: () async {
          refreshLongTaskStationCallCount += 1;
        },
      );
      final action = TaskCenterContractActionViewData(
        id: 'accept_revision',
        label: '接受修复',
        note: '',
        tone: 'success',
        invocationKind: 'checkpoint_review',
        enabled: true,
        disabledReason: '',
        ownerTaskPath: 'tasks/review_01.task.json',
        checkpointReviewPath: 'reviews/review_01.md',
      );

      await service.runSharedActionCommand(
        environment: environment,
        action: action,
        pendingMessage: '正在执行接受修复...',
        successMessage: '已接受修复结果。',
        operation: (project, settings) async {
          expect(project?.id, 'project_task_center');
          expect(settings, isNull);
          return const <String, Object?>{
            'ok': true,
            'task': <String, Object?>{
              'relative_path': 'tasks/review_followup.task.json',
            },
          };
        },
      );

      expect(commandInFlightStates, equals(<bool>[true, false]));
      expect(statusMessages.first, '正在执行接受修复...');
      expect(refreshTaskCenterCallCount, 1);
      expect(refreshTaskCenterViewCallCount, 1);
      expect(longTaskPulseCount, 1);
      expect(syncWorkbenchResourcesCallCount, 1);
      expect(adoptSelectionsCallCount, 1);
      expect(refreshLongTaskStationCallCount, 1);
      expect(selectedTaskId, 'tasks/review_followup.task.json');
    });

    test('loads checkpoint review path from task and execution contract', () {
      // 中文注释: 路径提取必须只认一条稳定合同，避免 shell 层自己再发明 checkpoint truth。
      const service = TaskCenterCommandOrchestrationService();
      final path = service.checkpointReviewPathOf(
        <String, Object?>{
          'task_type': 'chapter',
          'checkpoint_review_path': '',
        },
        <String, Object?>{
          'postprocess_checkpoint_review_path': 'reviews/checkpoint.md',
        },
      );

      expect(path, 'reviews/checkpoint.md');
    });
  });
}
