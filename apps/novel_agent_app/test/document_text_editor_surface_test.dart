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
}
