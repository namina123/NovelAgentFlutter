import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/resource_tree_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resource tree card shows counts and entries', (
    WidgetTester tester,
  ) async {
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 320,
              child: ResourceTreeCard(
                entries: const [
                  ResourceEntryViewData(
                    id: 'outline',
                    title: '大纲',
                    relativePath: 'outline/outline.md',
                    depth: 0,
                    isDirectory: true,
                    childCount: 3,
                    hasChildren: true,
                    isExpanded: true,
                  ),
                  ResourceEntryViewData(
                    id: 'chapter-1',
                    title: '第一章',
                    relativePath: 'chapters/chapter_01.md',
                    depth: 1,
                    isDirectory: false,
                    isSelected: true,
                  ),
                ],
                onEntrySelected: (entryId) => selectedId = entryId,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResourceTreeCard), findsOneWidget);
    expect(find.text('大纲'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('第一章'), findsOneWidget);

    await tester.tap(find.text('第一章'));
    await tester.pumpAndSettle();

    expect(selectedId, 'chapter-1');
  });

  testWidgets('resource tree card shows sqlite projection metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: ResourceTreeCard(
                projectTypeId: 'sqlite_project_store',
                entries: const [
                  ResourceEntryViewData(
                    id: 'sqlite-index',
                    title: 'SQLite 语义树',
                    relativePath: 'premise/sqlite_projection/index.md',
                    depth: 1,
                    isDirectory: false,
                  ),
                ],
                onEntrySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SQLite 语义树'), findsOneWidget);
    expect(find.textContaining('SQLite 主事实源'), findsOneWidget);
    expect(find.textContaining('只读投影'), findsOneWidget);
  });
}
