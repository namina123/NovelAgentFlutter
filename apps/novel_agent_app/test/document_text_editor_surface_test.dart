import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_text_editor_surface.dart';

void main() {
  testWidgets('document text editor surface shows line numbers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: DocumentTextEditorSurface(
              content: '第一行\n第二行\n第三行',
              isReadOnly: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('document_editor_line_number_gutter')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('1\n2\n3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('find bar locates matches and cycles through them', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 720,
            height: 420,
            child: DocumentTextEditorSurface(
              content: 'foo 第一段\n中间 foo 内容\n结尾 foo',
              isReadOnly: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 中文注释: 常驻放大镜按钮是移动端/可发现入口；点击展开查找栏。
    expect(find.byTooltip('查找（Ctrl+F）'), findsOneWidget);
    await tester.tap(find.byTooltip('查找（Ctrl+F）'));
    await tester.pumpAndSettle();

    final findField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.textInputAction == TextInputAction.search,
    );
    await tester.enterText(findField, 'foo');
    await tester.pumpAndSettle();

    // 3 处匹配，定位到第 1 处。
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.byTooltip('下一个匹配'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.byTooltip('下一个匹配'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);

    // 到末尾再下一个应回绕到第 1 处。
    await tester.tap(find.byTooltip('下一个匹配'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);

    // 关闭查找栏：关闭按钮消失，常驻入口按钮重新出现。
    await tester.tap(find.byTooltip('关闭查找（Esc）'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭查找（Esc）'), findsNothing);
    expect(find.byTooltip('查找（Ctrl+F）'), findsOneWidget);
  });
}
