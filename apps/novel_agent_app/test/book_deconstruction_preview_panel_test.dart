import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/contracts/book_deconstruction_action_handler.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_plan_group_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_preview_section_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_step_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  testWidgets(
    'split-result panel renders pure chapter plan groups and toggles selection',
    (WidgetTester tester) async {
      final viewDataService = BookDeconstructionViewDataService();
      // 中文注释: 拆书 = extractKnowledge:false，只产出分章；这里直接用该路径构造结果。
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: '海上城邦',
        sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        extractKnowledge: false,
      );
      final viewData = viewDataService.build(
        projectTitle: '拆书测试项目',
        snapshot: BookDeconstructionSnapshot.initial().copyWith(
          buildResult: buildResult,
          selectedItemIds: buildResult.applicationPlan.items
              .map((item) => item.id)
              .toSet(),
        ),
        status: '已完成拆书。',
      );
      final actionHandler = _FakeBookDeconstructionActionHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 840,
              child: SingleChildScrollView(
                child: BookDeconstructionPreviewPanel(
                  viewData: viewData,
                  actionHandler: actionHandler,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('拆书结果（分章）'), findsOneWidget);
      expect(find.text('全选'), findsOneWidget);
      // 纯分章下，资产类章纲分组（章纲）应当出现（折叠态标题含条目数，如"章纲（2）"）。
      expect(find.textContaining('章纲'), findsWidgets);
    },
  );

  testWidgets('split-result panel shows dedicated loading state during split', (
    WidgetTester tester,
  ) async {
    const loadingViewData = BookDeconstructionViewData(
      projectTitle: '拆书测试项目',
      status: '正在拆书…',
      isLoading: true,
      operationKind: 'splitting_chapters',
      activeStepId: '',
      steps: <BookDeconstructionStepViewData>[],
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      importActionLabel: '选择文件…',
      canSplit: false,
      splitUseModel: false,
      splitModelOptionKey: '',
      splitModelOptions: <SelectorOptionViewData>[],
      canUseSplitModel: false,
      canAnalyze: false,
      analysisUseModel: false,
      analysisModelOptionKey: '',
      analysisModelOptions: <SelectorOptionViewData>[],
      analysisStatusMessage: '',
      analysisCompleted: false,
      previewSections: <BookDeconstructionPreviewSectionViewData>[],
      planGroups: <BookDeconstructionPlanGroupViewData>[],
      selectedItemCount: 0,
      totalItemCount: 0,
      selectedFollowupOptionId: '',
      confirmedPreviewPath: '',
      canConfirmSelection: false,
      canCreateDerivedProject: false,
      continuity: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 200,
            child: BookDeconstructionPreviewPanel(
              viewData: loadingViewData,
              actionHandler: _FakeBookDeconstructionActionHandler(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('正在拆书（分章 + 去噪）…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('split-result panel shows guidance before any split', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 200,
            child: BookDeconstructionPreviewPanel(
              viewData: BookDeconstructionViewData.initial(),
              actionHandler: _FakeBookDeconstructionActionHandler(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('导入源文稿后点'), findsOneWidget);
  });
}

class _FakeBookDeconstructionActionHandler
    implements BookDeconstructionActionHandler {
  @override
  void onBookDeconstructionBackRequested() {}

  @override
  void onBookDeconstructionCancelRequested() {}

  @override
  Future<void> onBookDeconstructionImportFileRequested() async {}

  @override
  void onBookDeconstructionSourceTitleChanged(String value) {}

  @override
  void onBookDeconstructionSourceContentChanged(String value) {}

  @override
  void onBookDeconstructionSplitUseModelChanged(bool value) {}

  @override
  void onBookDeconstructionSplitModelSelected(String optionKey) {}

  @override
  Future<void> onBookDeconstructionSplitRequested() async {}

  @override
  void onBookDeconstructionAnalysisUseModelChanged(bool value) {}

  @override
  void onBookDeconstructionAnalysisModelSelected(String optionKey) {}

  @override
  Future<void> onBookDeconstructionAnalysisRequested() async {}

  @override
  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  }) {}

  @override
  void onBookDeconstructionSelectAllRequested() {}

  @override
  void onBookDeconstructionClearSelectionRequested() {}

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {}

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {}

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {}

  @override
  void onBookDeconstructionRefreshRequested() {}

  @override
  void onBookDeconstructionStepSelected(String stepId) {}
}
