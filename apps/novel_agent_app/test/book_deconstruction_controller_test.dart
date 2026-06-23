import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_derived_project_creation_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

const String _splitModelKey = 'provider-1::test-model';

List<SelectorOptionViewData> _modelOptions() {
  return const <SelectorOptionViewData>[
    SelectorOptionViewData(
      id: _splitModelKey,
      label: 'Provider · test-model',
      note: 'provider-1',
    ),
  ];
}

void main() {
  test('拆书控制器可完成纯净分章并写入应用前确认纪要', () async {
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
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );

    // 中文注释: 拆书 = 纯净分章（extractKnowledge:false），不产出知识抽取资产。
    await controller.onBookDeconstructionSplitRequested();

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
    expect(workspacePort.syncCount, 1);
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
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
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

    await controller.onBookDeconstructionSplitRequested();
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
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
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
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
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
            narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
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

    await controller.onBookDeconstructionSplitRequested();
    controller.onBookDeconstructionSelectAllRequested();
    controller.onBookDeconstructionFollowupOptionSelected('continuation_novel');
    expect(controller.viewData.selectedFollowupOptionId, 'continuation_novel');
    expect(controller.viewData.canCreateDerivedProject, isTrue);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();

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
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
    );

    await controller.initialize();

    expect(controller.viewData.canCreateDerivedProject, isFalse);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();
    expect(controller.viewData.status, '当前派生项目创建暂不可用。');
    expect(controller.viewData.status, isNot(contains('未接入')));
  });

  test('分析（可选）勾选模型后会用所选模型调用内置智能体并如实呈现', () async {
    // 中文注释: 分析是可选阶段：必须先拆书（产出 buildResult），再勾"使用模型"+选模型，
    // 才能分析。委托隐藏内置智能体，provider/model 由用户选择透传（与 app 默认解耦）。
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-analyze',
      name: '拆书分析测试',
      rootPath: 'D:/Projects/deconstruction_analyze',
      projectType: 'book_deconstruction',
    );
    String? capturedProvider;
    String? capturedModel;
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      extractKnowledgeHandler: (
        project, {
        required String providerId,
        required String modelId,
      }) async {
        capturedProvider = providerId;
        capturedModel = modelId;
        return (ok: true, message: '已分析并写入 3 条知识卡片');
      },
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
    );
    await controller.onBookDeconstructionSplitRequested();
    // 拆书后才有 buildResult，分析才可用。
    expect(controller.viewData.canAnalyze, isTrue);

    controller.onBookDeconstructionAnalysisUseModelChanged(true);
    controller.onBookDeconstructionAnalysisModelSelected(_splitModelKey);
    await controller.onBookDeconstructionAnalysisRequested();

    expect(capturedProvider, 'provider-1');
    expect(capturedModel, 'test-model');
    expect(controller.viewData.analysisCompleted, isTrue);
    expect(controller.viewData.status, contains('已分析并写入 3 条知识卡片'));
  });

  test('分析未选模型时不调用内置智能体并如实提示', () async {
    // 中文注释: spec：不选模型则不分析。未勾选/未选模型时点分析，如实提示，不触发回调。
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-analyze-no-model',
      name: '拆书分析无模型测试',
      rootPath: 'D:/Projects/deconstruction_analyze_no_model',
      projectType: 'book_deconstruction',
    );
    var handlerCalls = 0;
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
        workspacePort: workspacePort,
      ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      extractKnowledgeHandler: (
        project, {
        required String providerId,
        required String modelId,
      }) async {
        handlerCalls += 1;
        return (ok: true, message: '不应到达');
      },
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
    );
    await controller.onBookDeconstructionSplitRequested();
    // 未勾"使用模型"、未选模型，直接点分析。
    await controller.onBookDeconstructionAnalysisRequested();
    expect(handlerCalls, 0);
    expect(controller.viewData.status, contains('选择一个模型'));
  });
}

class _FakeDesktopBookDeconstructionSourcePickerService
    extends DesktopBookDeconstructionSourcePickerService {
  _FakeDesktopBookDeconstructionSourcePickerService(this._sourceFilePath);

  final String _sourceFilePath;

  @override
  Future<String?> pickSourceFile() async {
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
