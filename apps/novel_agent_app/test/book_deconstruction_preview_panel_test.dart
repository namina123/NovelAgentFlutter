import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_operation_kind.dart';
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
  test(
    'long_novel target requires a valid runtime baseline before confirmation',
    () {
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: '海上城邦',
        sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        extractKnowledge: false,
      );
      final service = BookDeconstructionViewDataService();
      final selectedItems = buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet();
      const targetOptions = <SelectorOptionViewData>[
        SelectorOptionViewData(id: 'long_novel', label: '长篇长任务'),
      ];
      const baselineOptions = <SelectorOptionViewData>[
        SelectorOptionViewData(id: 'continuous_autonomous', label: '连续托管式'),
      ];
      final missingBaseline = service.build(
        projectTitle: '拆书测试项目',
        snapshot: BookDeconstructionSnapshot.initial().copyWith(
          buildResult: buildResult,
          selectedItemIds: selectedItems,
          selectedTargetWritingTypeId: 'long_novel',
        ),
        status: '',
        targetWritingTypeOptions: targetOptions,
        targetRuntimeBaselineOptions: baselineOptions,
      );
      final selectedBaseline = service.build(
        projectTitle: '拆书测试项目',
        snapshot: BookDeconstructionSnapshot.initial().copyWith(
          buildResult: buildResult,
          selectedItemIds: selectedItems,
          selectedTargetWritingTypeId: 'long_novel',
          selectedTargetRuntimeBaselineId: 'continuous_autonomous',
        ),
        status: '',
        targetWritingTypeOptions: targetOptions,
        targetRuntimeBaselineOptions: baselineOptions,
      );

      expect(missingBaseline.canConfirmSelection, isFalse);
      expect(selectedBaseline.canConfirmSelection, isTrue);
    },
  );

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
      // 纯分章下，分章结果分组应当出现（折叠态标题含条目数，如"分章结果（2）"）。
      expect(find.textContaining('分章结果'), findsWidgets);
    },
  );

  testWidgets(
    'preview selections lock while confirmation writes are in progress',
    (WidgetTester tester) async {
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: '海上城邦',
        sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
        sourceAbsolutePath: 'D:/books/harbor_story.txt',
        extractKnowledge: false,
      );
      final actionHandler = _FakeBookDeconstructionActionHandler();
      final viewData = BookDeconstructionViewDataService().build(
        projectTitle: '拆书测试项目',
        snapshot: BookDeconstructionSnapshot.initial().copyWith(
          buildResult: buildResult,
          selectedItemIds: buildResult.applicationPlan.items
              .map((item) => item.id)
              .toSet(),
          isLoading: true,
          operationKind: BookDeconstructionOperationKind.confirmingSelection,
        ),
        status: '正在保存拆书结果...',
      );

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

      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '全选'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '清空'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.textContaining('分章结果').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .onChanged,
        isNull,
      );

      await tester.tap(find.text('全选'));
      expect(actionHandler.selectAllRequestCount, 0);
    },
  );

  testWidgets('split-result panel shows dedicated loading state during split', (
    WidgetTester tester,
  ) async {
    const loadingViewData = BookDeconstructionViewData(
      projectTitle: '拆书测试项目',
      status: '正在拆书...',
      isLoading: true,
      operationKind: 'splitting_chapters',
      activeStepId: '',
      steps: <BookDeconstructionStepViewData>[],
      sourceAbsolutePath: '',
      sourceTitle: '',
      sourceContent: '',
      importActionLabel: '选择文件...',
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
      selectedTargetWritingTypeId: '',
      targetWritingTypeOptions: <SelectorOptionViewData>[],
      selectedTargetRuntimeBaselineId: '',
      targetRuntimeBaselineOptions: <SelectorOptionViewData>[],
      inheritAsLiveNarrative: false,
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

    expect(find.text('正在拆书（分章 + 去噪）...'), findsOneWidget);
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
  int selectAllRequestCount = 0;

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
  void onBookDeconstructionSelectAllRequested() {
    selectAllRequestCount += 1;
  }

  @override
  void onBookDeconstructionClearSelectionRequested() {}

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {}

  @override
  void onBookDeconstructionTargetWritingTypeSelected(
    String targetWritingTypeId,
  ) {}

  @override
  void onBookDeconstructionTargetRuntimeBaselineSelected(
    String runtimeBaselineId,
  ) {}

  @override
  void onBookDeconstructionInheritAsLiveNarrativeChanged(bool value) {}

  @override
  void onBookDeconstructionApplyStagedAnalysisResultsChanged(bool value) {}

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {}

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {}

  @override
  void onBookDeconstructionRefreshRequested() {}

  @override
  void onBookDeconstructionStepSelected(String stepId) {}
}
