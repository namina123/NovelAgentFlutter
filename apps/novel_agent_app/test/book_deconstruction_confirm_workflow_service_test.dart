import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirm_workflow_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('确认 workflow 会写入预演纪要并持久化 narrative artifacts', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-1',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project',
      projectType: 'book_deconstruction',
    );
    final useCase = BuildBookDeconstructionDraftUseCase();
    final buildResult = useCase.execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '注意城邦议会与航线规则的象征关系。',
      styleSummary: '叙事节奏快，善于用港口意象制造压迫感。',
      worldRulesText: '航线印记绑定了贸易权力与超常能力',
      characterLinesText: '林砚：被迫卷入城邦风暴的主角',
      organizationLinesText: '议会：海上城邦的最高权力结构',
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .take(2)
          .map((item) => item.id)
          .toSet(),
      selectedFollowupOptionId: 'continuation_novel',
    );

    expect(result.previewPath, 'analysis/book_deconstruction_preview.md');
    expect(
      result.guidePath,
      'tasks/plans/book_deconstruction_followups/continuation_novel.md',
    );
    expect(
      workspacePort.readStoredTextFile(project.rootPath, result.previewPath),
      contains('# 拆书结构化预演'),
    );
    expect(
      workspacePort.readStoredTextFile(project.rootPath, result.guidePath),
      contains('续写'),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        '.novel_agent/state/book_deconstruction/followups/continuation_novel.plan.json',
      ),
      contains('"followup_option_id": "continuation_novel"'),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'chapters/inherited/continuation/continuation_novel/001_第一章_港口风暴.md',
      ),
      contains('主角在港口被迫卷入一场追捕'),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        '.novel_agent/continuity/claims/claims.jsonl',
      ),
      contains('analysis.deconstruction.story_outline'),
    );
  });

  test('同人路线不会把原作章节写进正文层', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-2',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project_fanfic',
      projectType: 'book_deconstruction',
    );
    final useCase = BuildBookDeconstructionDraftUseCase();
    final buildResult = useCase.execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '做成同人路线。',
      styleSummary: '叙事节奏快，善于用港口意象制造压迫感。',
      worldRulesText: '航线印记绑定了贸易权力与超常能力',
      characterLinesText: '林砚：被迫卷入城邦风暴的主角',
      organizationLinesText: '议会：海上城邦的最高权力结构',
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      selectedFollowupOptionId: 'fanfic_seed_autopilot_novel',
    );

    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'chapters/inherited/fanfic_seed_autopilot_novel/001_第一章_港口风暴.md',
      ),
      isNull,
    );
    expect(result.inheritedChapterPaths, isEmpty);
    expect(
      workspacePort.readStoredTextFile(project.rootPath, result.guidePath),
      contains('同人'),
    );
  });
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

  String? readStoredTextFile(String rootPath, String relativePath) {
    return _files[_key(rootPath, relativePath)];
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return readStoredTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[_key(rootPath, relativePath)] = content;
  }
}
