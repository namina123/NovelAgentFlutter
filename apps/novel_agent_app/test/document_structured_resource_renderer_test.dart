import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/renderers/document_resource_render_request.dart';
import 'package:novel_agent_app/features/workbench/presentation/renderers/document_structured_resource_renderer.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/document_workspace_display_mode.dart';

void main() {
  testWidgets('structured renderer shows sqlite resource metadata', (
    WidgetTester tester,
  ) async {
    final renderer = DocumentStructuredResourceRenderer();
    final request = DocumentResourceRenderRequest(
      title: 'SQLite 语义树',
      relativePath: 'premise/sqlite_projection/index.md',
      content: '''---
projection_id: sqlite_project_semantic_tree_index
title: SQLite 语义树
projection_only: true
source_of_truth_paths:
  - premise/project_brief.md
  - .novel_agent/sqlite/novel_agent.db
---

# SQLite 语义树

- 来源身份：SQLite 主事实源 / truth:sqlite_project_store / role:sqlite_projection / readonly
''',
      status: '结构化资料',
      displayMode: DocumentWorkspaceDisplayMode.source,
      canRender: false,
      isDirty: false,
      isBufferedDraft: false,
      hasDocument: true,
      onChanged: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(builder: (context) => renderer.build(context, request)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('结构化资料'), findsWidgets);
    expect(find.text('来源类型'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('只读'), findsOneWidget);
    expect(find.text('sqlite_project_semantic_tree_index'), findsNothing);
    expect(find.textContaining('投影'), findsNothing);
  });
}
