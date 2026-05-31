import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workspace panel can switch to structure renderer', (
    WidgetTester tester,
  ) async {
    final handler = _FakeDocumentWorkspaceActionHandler();
    const mapper = WorkbenchPaneViewDataMapperService();
    final baseViewData = WorkbenchViewData.initial().copyWith(
      documents: const [
        DocumentTabViewData(
          id: 'doc-1',
          title: '第一章',
          relativePath: 'chapters/chapter_01.md',
          isActive: true,
        ),
      ],
      activeDocumentTitle: '第一章',
      activeDocumentPath: 'chapters/chapter_01.md',
      activeDocumentBody: '# 标题\n\n正文',
      activeDocumentCanRender: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DocumentWorkspacePanel(
            viewData: mapper.toCanvasViewData(baseViewData),
            actionHandler: handler,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('结构摘要'), findsNothing);

    await tester.tap(find.text('结构'));
    await tester.pumpAndSettle();

    expect(find.text('结构摘要'), findsOneWidget);
    expect(find.textContaining('当前资源正在以结构摘要方式查看'), findsOneWidget);
    expect(handler.requestedActions, isEmpty);
  });

  testWidgets(
    'workspace panel routes preview-like resources to preview renderer',
    (WidgetTester tester) async {
      final handler = _FakeDocumentWorkspaceActionHandler();
      const mapper = WorkbenchPaneViewDataMapperService();
      final baseViewData = WorkbenchViewData.initial().copyWith(
        documents: const [
          DocumentTabViewData(
            id: 'doc-2',
            title: '城市地图',
            relativePath: 'assets/maps/city_overview.png',
            isActive: true,
          ),
        ],
        activeDocumentTitle: '城市地图',
        activeDocumentPath: 'assets/maps/city_overview.png',
        activeDocumentBody: '',
        activeDocumentCanRender: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: DocumentWorkspacePanel(
              viewData: mapper.toCanvasViewData(baseViewData),
              actionHandler: handler,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PNG 预览'), findsOneWidget);
      expect(find.textContaining('当前资源更适合直接预览'), findsOneWidget);
    },
  );
}

class _FakeDocumentWorkspaceActionHandler
    implements DocumentWorkspaceActionHandler {
  final List<DocumentToolbarAction> requestedActions =
      <DocumentToolbarAction>[];

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    requestedActions.add(action);
  }

  @override
  void onDocumentBodyChanged(String value) {}

  @override
  void onDocumentClosed(String documentId) {}

  @override
  void onDocumentSelected(String documentId) {}
}
