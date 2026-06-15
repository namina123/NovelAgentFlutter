import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_type_transition_workspace_command_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('builds selectable target type and runtime baseline options', () {
    const project = ProjectDescriptor(
      id: 'project_1',
      name: '星港档案',
      rootPath: '/tmp/project_1',
      projectType: 'novel',
    );
    final plan = const ProjectTypeTransitionPreparationService().prepare(
      project: project,
      targetProjectTypeId: 'long_novel',
    );
    final service = ProjectTypeTransitionWorkspaceCommandViewDataService();

    final viewData = service.build(
      project: project,
      plan: plan,
      runtimeBaselineId: '',
      confirmLabel: '重新检查',
    );

    expect(viewData.transitionTargetProjectTypeId, 'long_novel');
    expect(viewData.transitionTargetProjectTypeOptions, hasLength(1));
    expect(viewData.transitionTargetProjectTypeOptions.single.label, '长篇长任务');
    expect(viewData.transitionRequiresRuntimeBaselineSelection, isTrue);
    expect(viewData.transitionRuntimeBaselineOptions, isNotEmpty);
    expect(
      viewData.transitionRuntimeBaselineOptions.map((option) => option.id),
      containsAll(<String>[
        'continuous_autonomous',
        'chapter_collaboration_autorun',
      ]),
    );
    expect(viewData.status, contains('必须先选择一个可用的运行基准'));
  });
}
