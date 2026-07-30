import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('display mode bar exposes reading preview and structure modes', (
    WidgetTester tester,
  ) async {
    DocumentWorkspaceDisplayMode? selectedMode;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: DocumentWorkspaceDisplayModeBar(
                selectedMode: DocumentWorkspaceDisplayMode.source,
                canRender: true,
                hasDocument: true,
                onModeSelected: (mode) => selectedMode = mode,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('渲染'), findsOneWidget);
    expect(find.text('信息'), findsOneWidget);

    await tester.tap(find.text('信息'));
    await tester.pumpAndSettle();

    expect(selectedMode, DocumentWorkspaceDisplayMode.structure);
  });
}
