import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/models/book_deconstruction_snapshot.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_view_data_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/contracts/book_deconstruction_action_handler.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  testWidgets(
    'preview panel shows follow-up routes and shared information bridge',
    (WidgetTester tester) async {
      final draftBuilder = BookDeconstructionDraftBuilderService();
      final viewDataService = BookDeconstructionViewDataService();
      final buildResult = draftBuilder.build(
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

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 840,
              child: BookDeconstructionPreviewPanel(
                viewData: viewData,
                actionHandler: _FakeBookDeconstructionActionHandler(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('后续用途与共享资料桥'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('后续用途与共享资料桥'), findsOneWidget);
      expect(find.text('普通续写'), findsOneWidget);
      expect(find.text('长任务续写'), findsOneWidget);
      expect(find.text('共享资料沉淀'), findsOneWidget);
      expect(find.text('解说与分析'), findsOneWidget);
      expect(find.text('本次已生成的可复用资料'), findsOneWidget);
      expect(find.textContaining('information 资料 · 5'), findsOneWidget);
      expect(find.textContaining('design 巧思 · 2'), findsOneWidget);
      expect(find.textContaining('资料与设定'), findsAtLeastNWidgets(1));
    },
  );
}

class _FakeBookDeconstructionActionHandler
    implements BookDeconstructionActionHandler {
  @override
  void onBookDeconstructionBackRequested() {}

  @override
  Future<void> onBookDeconstructionBuildPreviewRequested() async {}

  @override
  void onBookDeconstructionCharacterLinesChanged(String value) {}

  @override
  void onBookDeconstructionClearSelectionRequested() {}

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {}

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
