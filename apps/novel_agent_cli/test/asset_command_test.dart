import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/asset/asset_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_artifact_label_service.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AssetCommand', () {
    test('help prints shared command block', () async {
      final bundle = _buildCommand();

      final exitCode = await bundle.command.run(<String>['help']);

      expect(exitCode, 0);
      expect(
        bundle.printer.blocks,
        contains(
          predicate<_PrintedBlock>(
            (block) =>
                block.title == 'asset help' &&
                block.content.contains(
                  'asset list [--kind style|foreshadow]',
                ) &&
                block.content.contains(
                  'asset export-project-asset-bundle --target',
                ),
          ),
        ),
      );
    });

    test(
      'list returns empty-state output through shared asset service',
      () async {
        final bundle = _buildCommand();

        final exitCode = await bundle.command.run(<String>['list']);

        expect(exitCode, 0);
        expect(bundle.printer.infos, contains('当前没有风格资产。'));
      },
    );

    test('save-style formats output path through shared artifact label service', () async {
      final bundle = _buildCommand(
        projectArtifactLabelService: const _FakeArtifactLabelService(),
      );

      final exitCode = await bundle.command.run(<String>[
        'save-style',
        '--id',
        'serial_style',
        '--name',
        '连载风格',
        '--summary',
        '保持克制',
      ]);

      expect(exitCode, 0);
      expect(
        bundle.printer.infos,
        contains(predicate<String>((line) => line.startsWith('tag::'))),
      );
    });
  });
}

({AssetCommand command, _RecordingTerminalPrinter printer}) _buildCommand({
  CliProjectArtifactLabelService? projectArtifactLabelService,
}) {
  final workspacePort = _NoopProjectWorkspacePort();
  final toolHostPort = _NoopProjectToolHostPort();
  final projectRepository = _FakeProjectRepository(
    const ProjectDescriptor(
      id: 'project_1',
      name: '测试项目',
      rootPath: 'D:/Novel',
    ),
  );
  final printer = _RecordingTerminalPrinter();
  final assetLibraryService = ProjectAssetLibraryService(
    workspacePort: workspacePort,
    projectToolHostPort: toolHostPort,
  );
  final command = AssetCommand(
    assetLibraryService: assetLibraryService,
    styleBundleLibraryService: ProjectStyleBundleLibraryService(
      assetLibraryService: assetLibraryService,
      fileAccessService: ProjectBundleFileAccessService(hostPort: toolHostPort),
      applyService: ProjectBundleApplyService(hostPort: toolHostPort),
    ),
    characterBundleLibraryService: ProjectCharacterBundleLibraryService(
      characterRepository: ProjectCharacterProfileRepository(
        hostPort: toolHostPort,
      ),
      organizationRepository: ProjectOrganizationProfileRepository(
        hostPort: toolHostPort,
      ),
      fileAccessService: ProjectBundleFileAccessService(hostPort: toolHostPort),
      applyService: ProjectBundleApplyService(hostPort: toolHostPort),
    ),
    assetBundleLibraryService: ProjectAssetBundleLibraryService(
      assetLibraryService: assetLibraryService,
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
    projectArtifactLabelService: projectArtifactLabelService,
  );
  return (command: command, printer: printer);
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
  }) async => const <JsonMap>[];

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

class _FakeArtifactLabelService extends CliProjectArtifactLabelService {
  const _FakeArtifactLabelService();

  @override
  String formatPath(String relativePath) => 'tag::$relativePath';
}
