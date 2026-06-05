import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('拆书控制器可完成预览并写入应用前确认纪要', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-1',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      projectToolHostPort: _FakeProjectToolHostPort(),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );
    controller.onBookDeconstructionOperatorNotesChanged('注意城邦议会与航线规则的象征关系。');
    controller.onBookDeconstructionStyleSummaryChanged('叙事节奏快，善于用港口意象制造压迫感。');
    controller.onBookDeconstructionWorldRulesChanged('航线印记绑定了贸易权力与超常能力');
    controller.onBookDeconstructionCharacterLinesChanged('林砚：被迫卷入城邦风暴的主角');

    await controller.onBookDeconstructionBuildPreviewRequested();

    expect(controller.viewData.previewSections, isNotEmpty);
    expect(controller.viewData.planGroups, isNotEmpty);

    final firstItemId = controller.viewData.planGroups.first.items.first.id;
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: firstItemId,
      selected: false,
    );

    await controller.onBookDeconstructionConfirmRequested();

    final content = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'analysis/book_deconstruction_preview.md',
    );
    expect(content, isNotNull);
    expect(content, contains('# 拆书结构化预演'));
    final claimsLog = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/continuity/claims/claims.jsonl',
    );
    final proposalIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/continuity/profile_proposals/index.json',
    );
    final reviewIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/continuity/reviews/index.json',
    );
    expect(claimsLog, contains('analysis.deconstruction.story_outline'));
    expect(proposalIndex, contains('proposal_'));
    expect(reviewIndex, contains('review_'));
    final knowledgeIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/information/knowledge_cards/index.json',
    );
    final designIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/information/design_elements/index.json',
    );
    final researchIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/information/research_notes/index.json',
    );
    final referenceIndex = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      '.novel_agent/information/reference_works/index.json',
    );
    final designProjection = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'knowledge/设计元素摘要.md',
    );
    final referenceProjection = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'references/引用作品边界.md',
    );
    expect(knowledgeIndex, contains('knowledge_'));
    expect(designIndex, contains('design_'));
    expect(researchIndex, contains('research_'));
    expect(referenceIndex, contains('reference_'));
    expect(
      designProjection,
      contains('analysis.deconstruction.design.system_rule'),
    );
    expect(referenceProjection, contains('deconstruction_source_work'));
    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    expect(workspacePort.syncCount, 1);

    final activationService = ProjectContextActivationService(
      workspacePort: workspacePort,
    );
    final activationReport = await activationService.buildReport(
      project: currentProject,
      taskType: 'chapter',
    );
    final selectedSections = ValueReaders.mapList(
      activationReport.metadata['selected_context_sections'],
    );
    final selectedKinds = selectedSections
        .map((item) => ValueReaders.stringValue(item['source_kind']))
        .toSet();
    expect(
      selectedKinds,
      containsAll(<String>[
        'project_knowledge_card',
        'project_design_element',
        'project_research_note',
        'project_reference_work',
      ]),
    );
    expect(
      ValueReaders.stringValue(activationReport.summary),
      contains('knowledge'),
    );
  });
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};
  int syncCount = 0;

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
