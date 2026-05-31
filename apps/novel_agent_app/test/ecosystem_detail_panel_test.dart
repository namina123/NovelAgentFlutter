import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/widgets/agent_ecosystem_header.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/widgets/ecosystem_detail_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders ecosystem detail with compact metadata and visible actions', (
    WidgetTester tester,
  ) async {
    var editCount = 0;
    var openSourceCount = 0;
    var createAgentCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: EcosystemDetailPanel(
              entry: const EcosystemEntryViewData(
                id: 'agent_editor',
                kind: 'agents',
                title: '审阅智能体',
                subtitle: 'agent_editor',
                badge: 'project',
                description: '负责当前项目的结构审阅与表达修订。',
                sourcePath: r'D:\workspace\packages\agents\agent_editor\AGENT.md',
                projectRelativePath: r'packages/agents/agent_editor/AGENT.md',
                isEditable: true,
              ),
              onEditRequested: () => editCount++,
              onOpenSourceRequested: () => openSourceCount++,
              onCreateAgentRequested: () => createAgentCount++,
              onCreateSkillRequested: () {},
              onCreateSkillGroupRequested: () {},
              onCreateAgentGroupRequested: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('条目标识'), findsNothing);
    expect(find.text('条目类型'), findsNothing);
    expect(find.text('自定义与导入'), findsNothing);

    expect(find.text('类型'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('项目内路径'), findsOneWidget);
    expect(find.text('编辑条目'), findsOneWidget);
    expect(find.text('打开源文件'), findsOneWidget);
    expect(find.text('新建条目'), findsOneWidget);
    expect(find.text('新建智能体'), findsOneWidget);

    await tester.tap(find.text('编辑条目'));
    await tester.tap(find.text('打开源文件'));
    await tester.tap(find.text('新建智能体'));
    await tester.pumpAndSettle();

    expect(editCount, 1);
    expect(openSourceCount, 1);
    expect(createAgentCount, 1);
  });

  testWidgets('renders ecosystem header without explanatory subtitle block', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AgentEcosystemHeader(onBackRequested: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('智能体生态'), findsOneWidget);
    expect(find.text('返回工作台'), findsOneWidget);
    expect(
      find.text('生态页只负责浏览、导入和新建入口，编辑细节后续按独立表单面板接入。'),
      findsNothing,
    );
  });
}
