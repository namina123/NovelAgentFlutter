import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_runtime_baseline_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_storage_strategy_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_type_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/project_create_panel.dart';

void main() {
  testWidgets('一般项目创建面板会提交轻量 continuity 输入', (tester) async {
    ProjectCreateRequestViewData? submitted;
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProjectCreatePanel(
            title: '第一步：选择项目类型',
            description: '测试用创建面板',
            projectsRootPath: 'D:/Projects',
            status: '',
            draftTitle: '海城续写',
            projectTypeOptions: const <ProjectTypeOptionViewData>[
              ProjectTypeOptionViewData(
                id: 'novel',
                title: '新建小说',
                description: '普通小说',
                defaultTitle: '未命名小说',
                requiresRuntimeBaselineSelection: false,
              ),
            ],
            selectedProjectTypeId: 'novel',
            storageStrategyOptions:
                const <ProjectStorageStrategyOptionViewData>[
                  ProjectStorageStrategyOptionViewData(
                    id: 'markdown_project_store',
                    title: 'Markdown 项目',
                    description: '文件树主导',
                  ),
                ],
            selectedStorageStrategyId: 'markdown_project_store',
            creationPhase: ProjectCreationPhase.projectType,
            runtimeBaselineOptions:
                const <ProjectRuntimeBaselineOptionViewData>[],
            selectedRuntimeBaselineId: '',
            selectedProjectTypeRequiresRuntimeBaseline: false,
            allowOpenExisting: true,
            onOpenExistingRequested: () {},
            onBackRequested: () {},
            onCreateSubmitted: (request) {
              submitted = request;
            },
          ),
        ),
      ),
    );

    expect(find.text('剧情机制与连续性'), findsNothing);
    expect(find.text('高级设置'), findsOneWidget);

    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();

    expect(find.text('剧情机制与连续性'), findsOneWidget);

    await tester.tap(find.text('包含多世界/多舞台切换'));
    await tester.pump();
    await tester.tap(find.text('包含回档/回归/重跑机制'));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, '世界/舞台标签'),
      '主世界 / 梦境线',
    );
    await tester.enterText(find.widgetWithText(TextField, '补充说明'), '主角保留记忆。');

    await tester.tap(find.text('下一步'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.continuityInput.usesMultipleWorlds, isTrue);
    expect(submitted!.continuityInput.usesReplayResets, isTrue);
    expect(submitted!.continuityInput.worldLabels, <String>['主世界', '梦境线']);
    expect(submitted!.continuityInput.notes, '主角保留记忆。');
  });
}
