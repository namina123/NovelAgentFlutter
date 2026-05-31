import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/layout/app_layout_metrics.dart';
import 'package:novel_agent_app/app/layout/app_layout_mode.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/workbench_surface_layout.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/workbench_surface_layout_policy.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_compact_workspace_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('compact layout policy prefers compact workbench shell', () {
    final metrics = AppLayoutMetrics(
      size: const Size(390, 844),
      shortestSide: 390,
      orientation: Orientation.portrait,
      viewInsetsBottom: 0,
      devicePixelRatio: 3,
      mode: AppLayoutMode.compact,
      isTabletLike: false,
    );

    final layout = WorkbenchSurfaceLayoutPolicy.resolve(
      metrics: metrics,
      isDocumentsWorkspaceVisible: true,
    );

    expect(layout.mode, WorkbenchSurfaceMode.compactWorkbench);
    expect(layout.showWorkspaceShortcuts, isFalse);
  });

  testWidgets('compact workspace shell starts from conversation and switches panes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHost(
        shell: WorkbenchCompactWorkspaceShell(
          workspacePane: const Center(child: Text('workspace-pane')),
          documentPane: const Center(child: Text('document-pane')),
          conversationPane: const Center(child: Text('conversation-pane')),
          isDocumentsWorkspaceVisible: false,
          onDocumentViewRequested: () {},
          onNonDocumentViewRequested: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('conversation-pane'), findsOneWidget);
    expect(find.text('workspace-pane'), findsNothing);

    await tester.tap(find.text('工作'));
    await tester.pumpAndSettle();

    expect(find.text('workspace-pane'), findsOneWidget);
    expect(find.text('conversation-pane'), findsNothing);

    await tester.tap(find.text('正文'));
    await tester.pumpAndSettle();

    expect(find.text('document-pane'), findsOneWidget);
  });

  testWidgets('compact workspace shell syncs external document focus and callbacks', (
    tester,
  ) async {
    var documentRequestCount = 0;
    var dismissRequestCount = 0;
    var documentsVisible = false;

    await tester.pumpWidget(
      _buildHost(
        shell: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Expanded(
                  child: WorkbenchCompactWorkspaceShell(
                    workspacePane: const Center(child: Text('workspace-pane')),
                    documentPane: const Center(child: Text('document-pane')),
                    conversationPane: const Center(
                      child: Text('conversation-pane'),
                    ),
                    isDocumentsWorkspaceVisible: documentsVisible,
                    onDocumentViewRequested: () {
                      documentRequestCount += 1;
                      setState(() {
                        documentsVisible = true;
                      });
                    },
                    onNonDocumentViewRequested: () {
                      dismissRequestCount += 1;
                      setState(() {
                        documentsVisible = false;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('正文'));
    await tester.pumpAndSettle();

    expect(documentRequestCount, 1);
    expect(find.text('document-pane'), findsOneWidget);

    await tester.tap(find.text('会话'));
    await tester.pumpAndSettle();

    expect(dismissRequestCount, 1);
    expect(find.text('conversation-pane'), findsOneWidget);
  });
}

Widget _buildHost({required Widget shell}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(width: 390, height: 820, child: shell),
      ),
    ),
  );
}
