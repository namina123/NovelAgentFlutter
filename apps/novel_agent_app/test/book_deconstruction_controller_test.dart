import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_derived_project_creation_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
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
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
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
    expect(controller.viewData.selectedFollowupOptionId, 'continuation_novel');

    final firstItemId = controller.viewData.planGroups.first.items.first.id;
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: firstItemId,
      selected: false,
    );
    controller.onBookDeconstructionFollowupOptionSelected(
      'fanfic_seed_autopilot_novel',
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
    final structuredSource = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'analysis/book_deconstruction_structured_source.md',
    );
    expect(structuredSource, isNotNull);
    expect(structuredSource, contains('## 规范化正文'));
    expect(structuredSource, contains('第一章 港口风暴'));
    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    expect(
      workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        'tasks/plans/book_deconstruction_followups/fanfic_seed_autopilot_novel.md',
      ),
      contains('同人'),
    );
    expect(
      workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        'chapters/inherited/fanfic_seed_autopilot_novel/001_第一章_港口风暴.md',
      ),
      isNull,
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
    expect(selectedKinds, isNotEmpty);
    expect(selectedKinds, contains('narrative_claim_submission'));
    expect(ValueReaders.stringValue(activationReport.summary), isNotEmpty);
  });

  test('拆书控制器导入时会把原文归档到来源层并把预演留在 analysis 层', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_controller_archive_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}source_book.md',
    );
    await sourceFile.writeAsString('第一章 港口风暴\n主角在港口被迫卷入一场追捕。');
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-2',
      name: '拆书测试项目二',
      rootPath: 'D:/Projects/deconstruction_project_archive',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
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
      sourcePickerService: _FakeDesktopBookDeconstructionSourcePickerService(
        sourceFile.path,
      ),
    );

    await controller.initialize();
    await controller.onBookDeconstructionImportFileRequested();

    final archivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(sourceFile.path);
    expect(
      workspacePort.readStoredTextFile(currentProject.rootPath, archivePath),
      contains('第一章 港口风暴'),
    );
    expect(controller.viewData.sourceAbsolutePath, sourceFile.path);
    expect(controller.viewData.sourceContent, contains('港口风暴'));

    controller.onBookDeconstructionOperatorNotesChanged('只归档原文，不混写到正文层。');
    await controller.onBookDeconstructionBuildPreviewRequested();
    controller.onBookDeconstructionFollowupOptionSelected('continuation_novel');
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: controller.viewData.planGroups.first.items.first.id,
      selected: true,
    );
    await controller.onBookDeconstructionConfirmRequested();

    expect(
      workspacePort.readStoredTextFile(
        currentProject.rootPath,
        'analysis/book_deconstruction_preview.md',
      ),
      contains('# 拆书结构化预演'),
    );
    expect(
      workspacePort.readStoredTextFile(
        currentProject.rootPath,
        'chapters/book_deconstruction_preview.md',
      ),
      isNull,
    );
    expect(
      workspacePort.readStoredTextFile(
        currentProject.rootPath,
        'chapters/inherited/continuation/continuation_novel/001_第一章_港口风暴.md',
      ),
      contains('主角在港口被迫卷入一场追捕'),
    );
  });

  test('拆书控制器会读取项目级默认承接路线作为初始选项', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-setup',
      name: '拆书测试项目默认路线',
      rootPath: 'D:/Projects/deconstruction_project_setup',
      projectType: 'book_deconstruction',
    );
    await workspacePort.writeTextFile(
      currentProject.rootPath,
      BookDeconstructionProjectSetupDocumentService.relativePath,
      BookDeconstructionProjectSetupDocumentService().encode(
        const BookDeconstructionProjectSetup(
          followupRouteId: 'fanfic',
          preferredFollowupOptionId: 'fanfic_seed_autopilot_novel',
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        ),
      ),
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
    );

    await controller.initialize();

    expect(
      controller.viewData.selectedFollowupOptionId,
      'fanfic_seed_autopilot_novel',
    );
  });

  test('拆书控制器可直接派生并打开后续项目', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-3',
      name: '拆书测试项目三',
      rootPath: 'D:/Projects/deconstruction_project_derived',
      projectType: 'book_deconstruction',
    );
    ProjectDescriptor? openedProject;
    String openedPath = '';
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
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
      projectsRootPath: 'D:/Projects',
      derivedProjectCreationService:
          BookDeconstructionDerivedProjectCreationService(
            createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
              projectRepository: _FakeProjectRepository(
                workspacePort: workspacePort,
                manifestCodecService: ProjectManifestCodecService(),
              ),
              projectWorkspacePort: workspacePort,
              projectContentRepository: _FakeProjectContentRepository(),
              projectReadableProjectionService:
                  _FakeProjectReadableProjectionService(),
            ),
            writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
              projectWorkspacePort: workspacePort,
            ),
            narrativePersistenceService:
                BookDeconstructionNarrativePersistenceService(
                  workspacePort: workspacePort,
                ),
          ),
      openDerivedProjectRequested: (project, preferredOpenPath) async {
        openedProject = project;
        openedPath = preferredOpenPath;
      },
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );
    controller.onBookDeconstructionOperatorNotesChanged('继续拆书并派生。');
    controller.onBookDeconstructionStyleSummaryChanged('节奏明快。');
    controller.onBookDeconstructionWorldRulesChanged('港口贸易绑定超常权力。');
    controller.onBookDeconstructionCharacterLinesChanged('林砚：主角');

    await controller.onBookDeconstructionBuildPreviewRequested();
    controller.onBookDeconstructionSelectAllRequested();
    controller.onBookDeconstructionFollowupOptionSelected('continuation_novel');
    expect(controller.viewData.selectedFollowupOptionId, 'continuation_novel');
    expect(controller.viewData.canCreateDerivedProject, isTrue);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();

    final expectedBuildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent:
          '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: '',
      operatorNotes: '继续拆书并派生。',
      styleSummary: '节奏明快。',
      worldRulesText: '港口贸易绑定超常权力。',
      characterLinesText: '林砚：主角',
      organizationLinesText: '',
    );
    final expectedPremisePath = expectedBuildResult.applicationPlan.items
        .firstWhere(
          (item) => item.sourceKind == BookDeconstructionArtifactKind.premise,
        )
        .relativePathHint;

    expect(
      controller.viewData.status,
      isNot(anyOf(contains('派生项目失败'), contains('暂不可用'), contains('请先'))),
    );
    expect(openedProject, isNotNull);
    expect(openedProject!.projectType, 'novel');
    expect(openedProject!.name, '海上城邦 - 一般小说');
    expect(
      openedPath,
      'tasks/plans/book_deconstruction_followups/continuation_novel.md',
    );
    expect(
      workspacePort.readStoredTextFile(
        openedProject!.rootPath,
        'tasks/plans/book_deconstruction_followups/continuation_novel.md',
      ),
      contains('续写'),
    );
    expect(
      workspacePort.readStoredTextFile(
        openedProject!.rootPath,
        expectedPremisePath,
      ),
      isNotNull,
    );
  });

  test('拆书控制器在派生项目接线缺失时保持禁用而不回吐未接入文案', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-4',
      name: '拆书测试项目四',
      rootPath: 'D:/Projects/deconstruction_project_unwired',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
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

    expect(controller.viewData.canCreateDerivedProject, isFalse);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();
    expect(controller.viewData.status, '当前派生项目创建暂不可用。');
    expect(controller.viewData.status, isNot(contains('未接入')));
  });
}

class _FakeDesktopBookDeconstructionSourcePickerService
    extends DesktopBookDeconstructionSourcePickerService {
  _FakeDesktopBookDeconstructionSourcePickerService(this._sourceFilePath);

  final String _sourceFilePath;

  @override
  Future<String?> pickSourceFile() async {
    // 中文注释: 测试假 picker 只返回预设路径，不在这里引入任何平台对话框行为。
    return _sourceFilePath;
  }
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

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    required _InMemoryProjectWorkspacePort workspacePort,
    required ProjectManifestCodecService manifestCodecService,
  }) : _workspacePort = workspacePort,
       _manifestCodecService = manifestCodecService;

  final _InMemoryProjectWorkspacePort _workspacePort;
  final ProjectManifestCodecService _manifestCodecService;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    final manifestContent = _workspacePort.readStoredTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (manifestContent == null) {
      return null;
    }
    final projectName = rootPath
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty)
        .last;
    final manifest = _manifestCodecService.parse(
      manifestContent,
      fallbackTitle: projectName,
    );
    return ProjectDescriptor(
      id: projectName,
      name: manifest.title,
      rootPath: rootPath,
      projectType: manifest.projectType,
      storageStrategy: manifest.storageStrategy,
      runtimeBaselineId: manifest.runtimeBaselineId,
    );
  }
}

class _FakeProjectContentRepository implements ProjectContentRepository {
  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}

class _FakeProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}
