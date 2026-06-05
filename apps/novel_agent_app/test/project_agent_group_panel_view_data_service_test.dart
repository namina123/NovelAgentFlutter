import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_agent_group_panel_view_data_service.dart';

void main() {
  const service = ProjectAgentGroupPanelViewDataService();

  test(
    'shows stable project-level configuration summary for active project',
    () {
      final viewData = service.build(
        hasActiveProject: true,
        currentGroupLabel: '长篇总控组',
        primaryAgentLabel: '综合创作智能体',
      );

      expect(viewData.currentGroupLabel, '长篇总控组');
      expect(viewData.primaryAgentLabel, '综合创作智能体');
      expect(viewData.summary, '当前项目已确定默认协作组，写作时会沿用这套协作摘要。');
      expect(viewData.actionTitle, '项目智能体组');
      expect(viewData.actionDescription, '查看当前项目协作摘要，并按需调整默认协作组。');
      expect(viewData.canConfigure, isTrue);
    },
  );

  test('falls back to open-project guidance when no project is active', () {
    final viewData = service.build(
      hasActiveProject: false,
      currentGroupLabel: '',
      primaryAgentLabel: '',
    );

    expect(viewData.currentGroupLabel, '未打开项目');
    expect(viewData.summary, '先打开项目，再为当前项目确定默认智能体组。');
    expect(viewData.actionDescription, '打开项目后，这里会成为当前项目的正式协作配置入口。');
    expect(viewData.canConfigure, isFalse);
  });

  test('uses stable copy when current project group is not resolved yet', () {
    final viewData = service.build(
      hasActiveProject: true,
      currentGroupLabel: '未确定智能体组',
      primaryAgentLabel: 'default_generalist',
    );

    expect(viewData.currentGroupLabel, '未确定智能体组');
    expect(viewData.primaryAgentLabel, '综合创作智能体');
    expect(viewData.summary, '当前项目还没有确定默认协作组，建议先补上再开始正式写作。');
    expect(viewData.actionDescription, '先确认当前项目该由哪组协作方式负责开局和后续写作。');
  });
}
