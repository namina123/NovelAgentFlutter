import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_markdown_canvas.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode.dart';

void main() {
  testWidgets('markdown canvas supports source editing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 1280,
            height: 860,
            child: _MarkdownCanvasHarness(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '## 新标题\n\n- [x] 已勾选\n\n| 列 | 值 |\n| --- | --- |\n| A | B |',
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, contains('新标题'));
    expect(find.text('编辑'), findsOneWidget);
  });

  testWidgets('markdown canvas supports render preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 860,
            child: DocumentMarkdownCanvas(
              title: 'chapter_01.md',
              relativePath: 'chapters/chapter_01.md',
              content:
                  '## 新标题\n\n- [x] 已勾选\n\n| 列 | 值 |\n| --- | --- |\n| A | B |',
              status: '已保存',
              displayMode: DocumentWorkspaceDisplayMode.render,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('渲染'), findsOneWidget);
    expect(find.text('新标题'), findsWidgets);
    expect(find.text('已勾选'), findsWidgets);
    expect(find.byType(Table), findsWidgets);
  });
}

class _MarkdownCanvasHarness extends StatefulWidget {
  const _MarkdownCanvasHarness();

  @override
  State<_MarkdownCanvasHarness> createState() => _MarkdownCanvasHarnessState();
}

class _MarkdownCanvasHarnessState extends State<_MarkdownCanvasHarness> {
  String _content =
      '# 初始标题\n\n'
      '| 名称 | 数值 |\n'
      '| --- | --- |\n'
      '| 蒸汽机 | 1 |\n\n'
      '~~旧内容~~';

  @override
  Widget build(BuildContext context) {
    return DocumentMarkdownCanvas(
      title: 'chapter_01.md',
      relativePath: 'chapters/chapter_01.md',
      content: _content,
      status: '已保存',
      displayMode: DocumentWorkspaceDisplayMode.source,
      onChanged: (value) => setState(() => _content = value),
    );
  }
}
