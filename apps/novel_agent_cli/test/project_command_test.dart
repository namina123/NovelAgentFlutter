import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/project/project_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_exit_codes.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectCommand', () {
    test('help prints shared command block', () async {
      final bundle = _buildCommand(
        summarySnapshot: const ProjectWorkspaceSnapshot(
          project: ProjectDescriptor(
            id: 'project_1',
            name: '测试项目',
            rootPath: 'D:/Novel',
          ),
          projectInfo: <String, Object?>{},
          entries: <JsonMap>[],
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'help',
      ], defaultProjectPath: 'D:/Novel');

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'project help' &&
                block.content.contains('project summary [--project 路径]') &&
                block.content.contains('project save-bundle [--title 标题]'),
          ),
        ),
      );
    });

    test('summary uses shared workspace snapshot loader', () async {
      final bundle = _buildCommand(
        summarySnapshot: const ProjectWorkspaceSnapshot(
          project: ProjectDescriptor(
            id: 'project_1',
            name: '测试项目',
            rootPath: 'D:/Novel',
          ),
          projectInfo: <String, Object?>{},
          entries: <JsonMap>[
            <String, Object?>{'relative_path': 'chapter/01.md'},
            <String, Object?>{'relative_path': 'chapter/02.md'},
          ],
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'summary',
      ], defaultProjectPath: 'D:/Novel');

      expect(exitCode, 0);
      expect(bundle.printer.successes, contains('已打开项目: 测试项目'));
      expect(bundle.printer.infos, contains('资源条目: 2'));
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == '项目目录' &&
                block.content.contains('chapter/01.md') &&
                block.content.contains('chapter/02.md'),
          ),
        ),
      );
    });

    test(
      'summary reports a corrupt manifest without an uncaught exception',
      () async {
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'project_1',
              name: '测试项目',
              rootPath: 'D:/Novel',
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          workspaceLoadError: const ProjectManifestCorruptionException(
            rootPath: 'D:/Novel',
          ),
        );

        final exitCode = await bundle.command.run(<String>[
          'summary',
        ], defaultProjectPath: 'D:/Novel');

        expect(exitCode, CliExitCodes.invalidInput);
        expect(bundle.printer.errors.single, contains('项目清单损坏'));
        expect(
          bundle.printer.errors.single,
          contains('.novel_agent/project_manifest.json'),
        );
      },
    );

    test('create-file annotates formal project artifact paths', () async {
      final bundle = _buildCommand(
        summarySnapshot: const ProjectWorkspaceSnapshot(
          project: ProjectDescriptor(
            id: 'project_1',
            name: '测试项目',
            rootPath: 'D:/Novel',
          ),
          projectInfo: <String, Object?>{},
          entries: <JsonMap>[],
        ),
      );

      final exitCode = await bundle.command.run(<String>[
        'create-file',
        '--path',
        'chapters/chapter_01.md',
        '--content',
        '正文',
      ], defaultProjectPath: 'D:/Novel');

      expect(exitCode, 0);
      expect(
        bundle.printer.infos,
        contains('项目路径: chapters/chapter_01.md（正式正文）'),
      );
    });

    test(
      'create-file persists SQLite primary content before its projection',
      () async {
        final events = <String>[];
        final structuredContentBridgeService =
            _RecordingStructuredContentBridgeService(events);
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'project_1',
              name: 'SQLite 项目',
              rootPath: 'D:/Novel',
              storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          fileWriteEvents: events,
          structuredContentBridgeService: structuredContentBridgeService,
        );

        final exitCode = await bundle.command.run(<String>[
          'create-file',
          '--path',
          'chapters/chapter_01.md',
          '--content',
          'SQLite 正文',
        ], defaultProjectPath: 'D:/Novel');

        expect(exitCode, 0);
        expect(structuredContentBridgeService.persistedDocumentCount, 1);
        expect(
          structuredContentBridgeService.documentPath,
          'chapters/chapter_01.md',
        );
        expect(structuredContentBridgeService.documentKind, 'chapter');
        expect(structuredContentBridgeService.content, 'SQLite 正文');
        expect(events, <String>[
          'sqlite:chapters/chapter_01.md',
          'projection:chapters/chapter_01.md',
        ]);
      },
    );

    test(
      'import persists supported SQLite text before its file projection',
      () async {
        final events = <String>[];
        final structuredContentBridgeService =
            _RecordingStructuredContentBridgeService(events);
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'project_1',
              name: 'SQLite 项目',
              rootPath: 'D:/Novel',
              storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          fileWriteEvents: events,
          externalTextFiles: <String, String>{'C:/source/chapter.md': '导入正文'},
          structuredContentBridgeService: structuredContentBridgeService,
        );

        final exitCode = await bundle.command.run(<String>[
          'import',
          '--source',
          'C:/source/chapter.md',
          '--target',
          'chapters',
        ], defaultProjectPath: 'D:/Novel');

        expect(exitCode, 0);
        expect(structuredContentBridgeService.persistedDocumentCount, 1);
        expect(
          structuredContentBridgeService.documentPath,
          'chapters/chapter.md',
        );
        expect(structuredContentBridgeService.documentKind, 'chapter');
        expect(structuredContentBridgeService.content, '导入正文');
        expect(events, <String>[
          'sqlite:chapters/chapter.md',
          'projection:chapters/chapter.md',
        ]);
      },
    );

    test(
      'import uses the storage strategy default target when omitted',
      () async {
        final events = <String>[];
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'project_1',
              name: 'SQLite 项目',
              rootPath: 'D:/Novel',
              storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          fileWriteEvents: events,
        );

        final exitCode = await bundle.command.run(<String>[
          'import',
          '--source',
          'C:/source/chapter.md',
        ], defaultProjectPath: 'D:/Novel');

        expect(exitCode, 0);
        expect(events, <String>['projection:imports/chapter.md']);
      },
    );

    test(
      'knowledge base import records default SQLite text as knowledge',
      () async {
        final events = <String>[];
        final structuredContentBridgeService =
            _RecordingStructuredContentBridgeService(events);
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'knowledge_1',
              name: '知识库',
              rootPath: 'D:/Knowledge',
              projectType: 'knowledge_base',
              storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          fileWriteEvents: events,
          externalTextFiles: <String, String>{'C:/source/reference.md': '资料正文'},
          structuredContentBridgeService: structuredContentBridgeService,
        );

        final exitCode = await bundle.command.run(<String>[
          'import',
          '--source',
          'C:/source/reference.md',
        ], defaultProjectPath: 'D:/Knowledge');

        expect(exitCode, 0);
        expect(
          structuredContentBridgeService.documentPath,
          'imports/reference.md',
        );
        expect(structuredContentBridgeService.documentKind, 'knowledge');
        expect(events, <String>[
          'sqlite:imports/reference.md',
          'projection:imports/reference.md',
        ]);
      },
    );

    test('markdown import keeps supported text as a filesystem file', () async {
      final events = <String>[];
      final structuredContentBridgeService =
          _RecordingStructuredContentBridgeService(events);
      final bundle = _buildCommand(
        summarySnapshot: const ProjectWorkspaceSnapshot(
          project: ProjectDescriptor(
            id: 'markdown_1',
            name: 'Markdown 项目',
            rootPath: 'D:/Novel',
          ),
          projectInfo: <String, Object?>{},
          entries: <JsonMap>[],
        ),
        fileWriteEvents: events,
        externalTextFiles: <String, String>{'C:/source/reference.md': '资料正文'},
        structuredContentBridgeService: structuredContentBridgeService,
      );

      final exitCode = await bundle.command.run(<String>[
        'import',
        '--source',
        'C:/source/reference.md',
      ], defaultProjectPath: 'D:/Novel');

      expect(exitCode, 0);
      expect(structuredContentBridgeService.persistedDocumentCount, 0);
      expect(events, <String>['projection:assets/reference.md']);
    });

    test(
      'import keeps unsupported binary files as filesystem attachments',
      () async {
        final events = <String>[];
        final structuredContentBridgeService =
            _RecordingStructuredContentBridgeService(events);
        final bundle = _buildCommand(
          summarySnapshot: const ProjectWorkspaceSnapshot(
            project: ProjectDescriptor(
              id: 'project_1',
              name: 'SQLite 项目',
              rootPath: 'D:/Novel',
              storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
            ),
            projectInfo: <String, Object?>{},
            entries: <JsonMap>[],
          ),
          fileWriteEvents: events,
          structuredContentBridgeService: structuredContentBridgeService,
        );

        final exitCode = await bundle.command.run(<String>[
          'import',
          '--source',
          'C:/source/cover.png',
          '--target',
          'assets',
        ], defaultProjectPath: 'D:/Novel');

        expect(exitCode, 0);
        expect(structuredContentBridgeService.persistedDocumentCount, 0);
        expect(events, <String>['projection:assets/cover.png']);
      },
    );
  });
}

({ProjectCommand command, _RecordingTerminalPrinter printer}) _buildCommand({
  required ProjectWorkspaceSnapshot summarySnapshot,
  List<String>? fileWriteEvents,
  Map<String, String>? externalTextFiles,
  ProjectStructuredContentBridgeService? structuredContentBridgeService,
  Object? workspaceLoadError,
}) {
  final workspacePort = _NoopProjectWorkspacePort();
  final toolHostPort = _NoopProjectToolHostPort(
    eventLog: fileWriteEvents,
    externalTextFiles: externalTextFiles,
  );
  final projectRepository = _FakeProjectRepository(summarySnapshot.project);
  final printer = _RecordingTerminalPrinter();
  final loadProjectWorkspaceUseCase = _FakeLoadProjectWorkspaceUseCase(
    projectRepository: projectRepository,
    projectWorkspacePort: workspacePort,
    snapshot: summarySnapshot,
    error: workspaceLoadError,
  );
  final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
    projectWorkspacePort: workspacePort,
  );
  final projectAssetLibraryService = ProjectAssetLibraryService(
    workspacePort: workspacePort,
    projectToolHostPort: toolHostPort,
  );
  final command = ProjectCommand(
    loadProjectWorkspaceUseCase: loadProjectWorkspaceUseCase,
    createProjectEntryUseCase: CreateProjectEntryUseCase(
      projectToolHostPort: toolHostPort,
    ),
    importProjectFilesUseCase: ImportProjectFilesUseCase(
      projectToolHostPort: toolHostPort,
    ),
    updateProjectManifestUseCase: UpdateProjectManifestUseCase(
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
    ),
    projectToolHostPort: toolHostPort,
    previewCustomizationBundleImportUseCase:
        PreviewCustomizationBundleImportUseCase(),
    importCustomizationBundleUseCase: ImportCustomizationBundleUseCase(
      projectToolHostPort: toolHostPort,
      generateCustomizationIndexesUseCase: GenerateCustomizationIndexesUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
    ),
    generateCustomizationIndexesUseCase: GenerateCustomizationIndexesUseCase(
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
    ),
    saveCustomizationMarketIndexUseCase: SaveCustomizationMarketIndexUseCase(
      projectToolHostPort: toolHostPort,
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
    ),
    saveCustomizationBundleUseCase: SaveCustomizationBundleUseCase(
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
    ),
    loadAgentPackages: (_) async => const <JsonMap>[],
    loadAgentGroups: (_) async => const <JsonMap>[],
    loadSkillPackages: (_) async => const <JsonMap>[],
    loadSkillGroups: (_) async => const <JsonMap>[],
    projectPackageLibraryService: ProjectPackageLibraryService(
      workspacePort: workspacePort,
      runtimeProfileRepository: ProjectRuntimeProfileRepository(
        workspacePort: workspacePort,
      ),
      promptTemplateService: ProjectPromptTemplateService(
        workspacePort: workspacePort,
      ),
      characterRepository: ProjectCharacterProfileRepository(
        hostPort: toolHostPort,
      ),
      organizationRepository: ProjectOrganizationProfileRepository(
        hostPort: toolHostPort,
      ),
      assetLibraryService: projectAssetLibraryService,
      relationshipRepository: ProjectRelationshipRepository(
        hostPort: toolHostPort,
      ),
      timelineRepository: ProjectTimelineRepository(hostPort: toolHostPort),
      fileAccessService: ProjectBundleFileAccessService(hostPort: toolHostPort),
      applyService: ProjectBundleApplyService(hostPort: toolHostPort),
    ),
    projectContextLoader: CliProjectContextLoader(
      commandContext: CliCommandContext(
        settings: const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[],
        ),
        defaultProjectPath: 'D:/Novel',
      ),
      projectRepository: projectRepository,
      printer: printer,
    ),
    printer: printer,
    structuredContentBridgeService: structuredContentBridgeService,
  );
  return (command: command, printer: printer);
}

class _FakeLoadProjectWorkspaceUseCase extends LoadProjectWorkspaceUseCase {
  _FakeLoadProjectWorkspaceUseCase({
    required super.projectRepository,
    required super.projectWorkspacePort,
    required ProjectWorkspaceSnapshot snapshot,
    Object? error,
  }) : _snapshot = snapshot,
       _error = error;

  final ProjectWorkspaceSnapshot _snapshot;
  final Object? _error;

  @override
  Future<ProjectWorkspaceSnapshot?> execute(String rootPath) async {
    final error = _error;
    if (error != null) {
      throw error;
    }
    return _snapshot;
  }
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.project);

  final ProjectDescriptor project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async => project;
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  _NoopProjectToolHostPort({
    List<String>? eventLog,
    Map<String, String>? externalTextFiles,
  }) : _eventLog = eventLog,
       _externalTextFiles = externalTextFiles ?? const <String, String>{};

  final List<String>? _eventLog;
  final Map<String, String> _externalTextFiles;

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {
    _eventLog?.add('projection:$targetRelativePath');
  }

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
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async =>
      _externalTextFiles[absolutePath];

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
  ) async {
    _eventLog?.add('projection:$relativePath');
  }
}

class _RecordingStructuredContentBridgeService
    extends ProjectStructuredContentBridgeService {
  _RecordingStructuredContentBridgeService(this._events);

  final List<String> _events;
  int persistedDocumentCount = 0;
  String documentPath = '';
  String documentKind = '';
  String content = '';

  @override
  Future<void> persistStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required String documentKind,
    required String title,
    required String content,
    String statePath = '',
    String status = 'applied',
  }) async {
    persistedDocumentCount += 1;
    this.documentPath = documentPath;
    this.documentKind = documentKind;
    this.content = content;
    _events.add('sqlite:$documentPath');
  }
}

class _RecordingTerminalPrinter extends TerminalPrinter {
  final List<String> infos = <String>[];
  final List<String> successes = <String>[];
  final List<String> errors = <String>[];
  final List<_PrintedBlock> blocks = <_PrintedBlock>[];

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void success(String message) {
    successes.add(message);
  }

  @override
  void error(String message) {
    errors.add(message);
  }

  @override
  void block(String title, String content) {
    blocks.add(_PrintedBlock(title, content));
  }
}

class _PrintedBlock {
  const _PrintedBlock(this.title, this.content);

  final String title;
  final String content;

  @override
  bool operator ==(Object other) {
    return other is _PrintedBlock &&
        other.title == title &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(title, content);
}
