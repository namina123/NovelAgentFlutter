import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/contracts/book_deconstruction_action_handler.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_continuity_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_followup_group_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_followup_option_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_plan_group_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_plan_item_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_preview_section_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_step_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  testWidgets(
    'preview panel shows follow-up routes and structured deconstruction preview',
    (WidgetTester tester) async {
      final viewDataService = BookDeconstructionViewDataService();
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: '海上城邦',
        sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        operatorNotes: '先保留章纲和角色。',
        styleSummary: '节奏偏商业，冲突推进快。',
        worldRulesText: '城邦权力依靠航线垄断。',
        characterLinesText: '林砚：主角',
        organizationLinesText: '黑潮议会：港口势力',
        preferredContinuationDirection:
            BookDeconstructionContinuationDirection.longTaskPreferred,
      );
      final viewData = viewDataService.build(
        projectTitle: '拆书测试项目',
        snapshot: BookDeconstructionSnapshot.initial().copyWith(
          buildResult: buildResult,
          selectedItemIds: buildResult.applicationPlan.items
              .map((item) => item.id)
              .toSet(),
          confirmedPreviewPath: 'analysis/book_deconstruction_preview.md',
        ),
        status: '已生成结构化预览。',
      );
      final actionHandler = _FakeBookDeconstructionActionHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 840,
              child: BookDeconstructionPreviewPanel(
                viewData: viewData,
                actionHandler: actionHandler,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final fanficOptionFinder = find.byKey(
        const ValueKey(
          'book_deconstruction_followup_option_fanfic_seed_autopilot_novel',
        ),
      );
      expect(fanficOptionFinder, findsOneWidget);

      await tester.tap(fanficOptionFinder);
      await tester.pumpAndSettle();

      expect(actionHandler.lastFollowupOptionId, 'fanfic_seed_autopilot_novel');

      expect(find.text('续写基座与后续方案'), findsOneWidget);
      expect(find.text('章节骨架'), findsOneWidget);
      expect(find.text('角色资产'), findsOneWidget);
      expect(find.text('关系资产'), findsOneWidget);
      expect(find.text('知识沉淀'), findsNothing);
      expect(find.text('巧思与设计'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '派生并打开项目'), findsOneWidget);
    },
  );

  testWidgets('preview panel shows dedicated loading state during extraction', (
    WidgetTester tester,
  ) async {
    final actionHandler = _FakeBookDeconstructionActionHandler();
    const loadingViewData = BookDeconstructionViewData(
      projectTitle: '拆书测试项目',
      status: '正在生成结构化预览...',
      isLoading: true,
      operationKind: 'building_preview',
      activeStepId: 'preview_structure',
      steps: <BookDeconstructionStepViewData>[],
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      operatorNotes: '',
      styleSummary: '',
      worldRulesText: '',
      characterLinesText: '',
      organizationLinesText: '',
      previewSections: <BookDeconstructionPreviewSectionViewData>[],
      planGroups: <BookDeconstructionPlanGroupViewData>[],
      selectedItemCount: 0,
      totalItemCount: 0,
      selectedFollowupOptionId: '',
      confirmedPreviewPath: '',
      canBuildPreview: false,
      canConfirmSelection: false,
      canCreateDerivedProject: false,
      importActionLabel: '导入文件',
      buildPreviewActionLabel: '正在拆书',
      continuity: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 840,
            child: BookDeconstructionPreviewPanel(
              viewData: loadingViewData,
              actionHandler: actionHandler,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('正在提取拆书结构资产...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('preview panel uses a natural note for empty follow-up groups', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 840,
            child: BookDeconstructionPreviewPanel(
              viewData: BookDeconstructionViewData(
                projectTitle: '空分组测试',
                status: '已生成结构化预览。',
                isLoading: false,
                operationKind: '',
                activeStepId: '',
                steps: const <BookDeconstructionStepViewData>[],
                sourceAbsolutePath: '',
                sourceTitle: '',
                sourceContent: '',
                operatorNotes: '',
                styleSummary: '',
                worldRulesText: '',
                characterLinesText: '',
                organizationLinesText: '',
                previewSections:
                    const <BookDeconstructionPreviewSectionViewData>[],
                planGroups: const <BookDeconstructionPlanGroupViewData>[
                  BookDeconstructionPlanGroupViewData(
                    id: 'plan_group',
                    title: '结构预览',
                    description: '仅用于打开连续预览区。',
                    items: <BookDeconstructionPlanItemViewData>[],
                  ),
                ],
                selectedItemCount: 0,
                totalItemCount: 0,
                selectedFollowupOptionId: '',
                confirmedPreviewPath: '',
                canBuildPreview: false,
                canConfirmSelection: false,
                canCreateDerivedProject: false,
                importActionLabel: '导入文件',
                buildPreviewActionLabel: '生成结构化预览',
                continuity: const BookDeconstructionContinuityViewData(
                  preferredDirectionLabel: '偏向长任务',
                  highlightedBuildTierLabel: '默认高亮',
                  highlightedRouteTitle: '默认路线',
                  selectedRouteOptionId: '',
                  selectedRouteTitle: '默认路线',
                  scopeHintCount: 0,
                  identityMappingCount: 0,
                  mechanicHintCount: 0,
                  summary: '空分组测试',
                  followupGroups: <BookDeconstructionFollowupGroupViewData>[
                    BookDeconstructionFollowupGroupViewData(
                      id: 'empty_group',
                      title: '空分组',
                      description: '无可用路线',
                      options: <BookDeconstructionFollowupOptionViewData>[],
                    ),
                  ],
                ),
              ),
              actionHandler: _FakeBookDeconstructionActionHandler(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('当前暂无可用路线。'), findsOneWidget);
    expect(find.text('当前保留为空分组，后续新增路线会继续挂到这里。'), findsNothing);
  });
}

class _FakeBookDeconstructionActionHandler
    implements BookDeconstructionActionHandler {
  String lastFollowupOptionId = '';

  @override
  void onBookDeconstructionBackRequested() {}

  @override
  Future<void> onBookDeconstructionBuildPreviewRequested() async {}

  @override
  void onBookDeconstructionCharacterLinesChanged(String value) {}

  @override
  void onBookDeconstructionClearSelectionRequested() {}

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {
    lastFollowupOptionId = optionId;
  }

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {}

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {}

  @override
  Future<void> onBookDeconstructionImportFileRequested() async {}

  @override
  void onBookDeconstructionOperatorNotesChanged(String value) {}

  @override
  void onBookDeconstructionOrganizationLinesChanged(String value) {}

  @override
  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  }) {}

  @override
  void onBookDeconstructionRefreshRequested() {}

  @override
  void onBookDeconstructionSelectAllRequested() {}

  @override
  void onBookDeconstructionSourceContentChanged(String value) {}

  @override
  void onBookDeconstructionSourceTitleChanged(String value) {}

  @override
  void onBookDeconstructionStepSelected(String stepId) {}

  @override
  void onBookDeconstructionStyleSummaryChanged(String value) {}

  @override
  void onBookDeconstructionWorldRulesChanged(String value) {}
}
