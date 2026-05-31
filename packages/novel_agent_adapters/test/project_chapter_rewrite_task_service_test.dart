import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('materializes revision task from chapter rewrite plan', () async {
    final workspacePort = LocalProjectWorkspacePort();
    final rootDir = await Directory.systemTemp.createTemp('rewrite_task_test_');
    final project = ProjectDescriptor(
      id: 'demo',
      name: 'Demo',
      rootPath: rootDir.path,
      projectType: 'novel',
    );
    await workspacePort.writeTextFile(
      project.rootPath,
      'chapters/ch01.md',
      '第一行\n第二行\n第三行',
    );
    final taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
    final service = ProjectChapterRewriteTaskService(
      taskRepository: taskRepository,
    );
    final plan = const ChapterRewritePlan(
      id: 'plan_01',
      analysisResultId: 'analysis_01',
      actionKind: ChapterRewriteActionKind.rewriteFull,
      title: '整章重写：第一章',
      chapterPath: 'chapters/ch01.md',
      instructions: '根据分析结果重写整章。',
      sourcePaths: <String>['chapters/ch01.md'],
      outputPaths: <String>['chapters/ch01.md'],
    );

    final created = await service.createRevisionTaskFromPlan(
      project,
      plan,
      analysisPath: 'reviews/plot/ch01.md',
    );

    expect(ValueReaders.boolValue(created['ok']), isTrue);
    expect(ValueReaders.stringValue(created['relative_path']), contains('tasks/'));
    final task = ValueReaders.mapValue(created['task']);
    expect(ValueReaders.stringValue(task['task_type']), 'revision');
    expect(
      ValueReaders.mapValue(task['metadata'])['rewrite_action_kind'],
      ChapterRewriteActionKind.rewriteFull,
    );
    await rootDir.delete(recursive: true);
  });
}
