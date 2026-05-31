import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_canvas_frame.dart';

void main() {
  testWidgets('document workspace canvas frame keeps header compact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 320,
            child: DocumentWorkspaceCanvasFrame(
              title: 'project_brief.md',
              relativePath: '未命名小说/specs/project_brief.md',
              status: '未保存修改',
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final titleTop = tester.getTopLeft(find.text('project_brief.md'));
    final pathTop = tester.getTopLeft(find.text('未命名小说/specs/project_brief.md'));
    final statusTop = tester.getTopLeft(find.text('未保存修改'));

    expect(pathTop.dy - titleTop.dy, lessThan(28));
    expect((statusTop.dy - titleTop.dy).abs(), lessThan(8));
  });
}
