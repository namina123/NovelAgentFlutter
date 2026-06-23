import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/foreshadow_record_editor_panel.dart';

ForeshadowRecordEditorViewData _record({
  required String id,
  String title = '',
}) {
  return ForeshadowRecordEditorViewData(
    id: id,
    title: title,
    status: '',
    summary: '',
    plantedChapterPath: '',
    targetPayoffPath: '',
    relatedEntityIdsText: '',
    relatedPathsText: '',
    triggerConditionsText: '',
    payoffExpectationsText: '',
    tagsText: '',
    notes: '',
    relativePath: '',
  );
}

void main() {
  testWidgets(
    'auto-saves unsaved edits to the previous record when switching records '
    'instead of silently discarding them',
    (WidgetTester tester) async {
      ForeshadowRecordEditorRequestViewData? saved;
      Widget build(ForeshadowRecordEditorViewData viewData) {
        return MaterialApp(
          home: Scaffold(
            body: ForeshadowRecordEditorPanel(
              viewData: viewData,
              onSaveRequested: (request) => saved = request,
              // 删除回调用不到；给个占位。
              onDeleteRequested: (_) {},
            ),
          ),
        );
      }

      // 中文注释: 打开记录 A，改标题，再切到记录 B——应自动把 A 的编辑落盘，
      // 而不是被 didUpdateWidget 的 _apply 静默覆盖丢失。
      await tester.pumpWidget(build(_record(id: 'foreshadow-a', title: '原标题')));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, '标题'), '改后的标题');
      await tester.pump();

      await tester.pumpWidget(build(_record(id: 'foreshadow-b', title: 'B')));
      // didUpdateWidget 在 build 期注册了 postFrame 回调，pump 一帧让它执行。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(saved, isNotNull);
      expect(saved!.id, 'foreshadow-a');
      expect(saved!.title, '改后的标题');
    },
  );

  testWidgets('does not auto-save when there are no unsaved edits', (
    WidgetTester tester,
  ) async {
    ForeshadowRecordEditorRequestViewData? saved;
    Widget build(ForeshadowRecordEditorViewData viewData) {
      return MaterialApp(
        home: Scaffold(
          body: ForeshadowRecordEditorPanel(
            viewData: viewData,
            onSaveRequested: (request) => saved = request,
            onDeleteRequested: (_) {},
          ),
        ),
      );
    }

    await tester.pumpWidget(build(_record(id: 'foreshadow-a', title: '原标题')));
    await tester.pump();
    // 不改任何字段，直接切换——不应触发自动保存。
    await tester.pumpWidget(build(_record(id: 'foreshadow-b', title: 'B')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(saved, isNull);
  });
}
