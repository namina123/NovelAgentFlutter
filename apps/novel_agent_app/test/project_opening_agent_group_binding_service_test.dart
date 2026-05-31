import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_agent_group_binding_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectOpeningAgentGroupBindingService', () {
    test('selects project-level default group without disturbing scoped items', () async {
      final savedSnapshots = <List<ProjectAgentGroupSelection>>[];
      final service = ProjectOpeningAgentGroupBindingService(
        loadSelections: (_) async => const [
          ProjectAgentGroupSelection(
            groupId: 'starter_long_task',
            displayName: '长篇总控组',
            selectedByDefault: true,
          ),
          ProjectAgentGroupSelection(
            groupId: 'seed_long_task',
            displayName: '灵感托管组',
          ),
          ProjectAgentGroupSelection(
            groupId: 'scoped_group',
            displayName: '阶段组',
            selectedByDefault: true,
            modeIds: ['seed_autopilot_novel'],
          ),
        ],
        saveSelections: (_, selections) async {
          savedSnapshots.add(selections);
        },
      );

      await service.selectProjectDefaultGroup(
        project: const ProjectDescriptor(
          id: 'project_1',
          name: '测试项目',
          rootPath: 'D:/projects/test',
        ),
        groupId: 'seed_long_task',
        displayName: '灵感托管组',
      );

      final saved = savedSnapshots.single;
      final projectLevelDefault = saved
          .where(
            (selection) =>
                selection.modeIds.isEmpty &&
                selection.stageIds.isEmpty &&
                selection.selectedByDefault,
          )
          .toList(growable: false);
      expect(projectLevelDefault, hasLength(1));
      expect(projectLevelDefault.single.groupId, 'seed_long_task');
      expect(
        saved.where((selection) => selection.groupId == 'scoped_group').single
            .selectedByDefault,
        isTrue,
      );
    });
  });
}
