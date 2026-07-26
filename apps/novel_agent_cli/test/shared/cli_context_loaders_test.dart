import 'package:novel_agent_cli/commands/shared/cli_command_context.dart';
import 'package:novel_agent_cli/commands/shared/cli_exit_codes.dart';
import 'package:novel_agent_cli/commands/shared/cli_project_context_loader.dart';
import 'package:novel_agent_cli/commands/shared/cli_settings_context_loader.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CliSettingsContextLoader', () {
    test('loads command context from settings repository', () async {
      final settings = AppSettings(
        defaultProviderId: 'provider-a',
        defaultAgentId: 'agent-a',
        defaultModelId: 'model-a',
        defaultProjectPath: 'D:/Novel',
        autoSaveDrafts: true,
        providers: const <ProviderEndpointSettings>[],
      );
      final loader = CliSettingsContextLoader(
        settingsRepository: _FakeSettingsRepository(settings),
      );

      final context = await loader.load();

      expect(context.settings.defaultProjectPath, 'D:/Novel');
      expect(context.defaultProjectPath, 'D:/Novel');
    });
  });

  group('CliProjectContextLoader', () {
    test('loads project from explicit project flag', () async {
      final settings = _buildSettings(defaultProjectPath: 'D:/Fallback');
      final project = const ProjectDescriptor(
        id: 'project-a',
        name: 'Novel',
        rootPath: 'D:/Novel',
      );
      final printer = _RecordingTerminalPrinter();
      final loader = CliProjectContextLoader(
        commandContext: CliCommandContext(
          settings: settings,
          defaultProjectPath: settings.defaultProjectPath,
        ),
        projectRepository: _FakeProjectRepository({'D:/Novel': project}),
        printer: printer,
      );

      final context = await loader.load(const <String>[
        '--project',
        'D:/Novel',
      ]);

      expect(context, isNotNull);
      expect(context!.project.rootPath, 'D:/Novel');
      expect(context.projectPath, 'D:/Novel');
      expect(printer.errors, isEmpty);
    });

    test('reports missing project path and missing project', () async {
      final settings = _buildSettings(defaultProjectPath: '');
      final printer = _RecordingTerminalPrinter();
      final repository = _FakeProjectRepository(
        const <String, ProjectDescriptor?>{},
      );
      final loader = CliProjectContextLoader(
        commandContext: CliCommandContext(
          settings: settings,
          defaultProjectPath: settings.defaultProjectPath,
        ),
        projectRepository: repository,
        printer: printer,
      );

      final missingPath = await loader.load(const <String>[]);
      expect(missingPath, isNull);
      expect(printer.errors.last, contains('请通过 --project 指定项目路径。'));

      final missingProject = await loader.load(const <String>[
        '--project',
        'D:/Missing',
      ]);
      expect(missingProject, isNull);
      expect(printer.errors.last, contains('项目不存在: D:/Missing'));
    });

    test(
      'reports a corrupt manifest without exposing the repository exception',
      () async {
        final settings = _buildSettings(defaultProjectPath: 'D:/Damaged');
        final printer = _RecordingTerminalPrinter();
        final loader = CliProjectContextLoader(
          commandContext: CliCommandContext(
            settings: settings,
            defaultProjectPath: settings.defaultProjectPath,
          ),
          projectRepository: _CorruptManifestProjectRepository(),
          printer: printer,
        );

        final context = await loader.load(const <String>[]);

        expect(context, isNull);
        expect(printer.errors.single, contains('项目清单损坏'));
        expect(
          printer.errors.single,
          contains('.novel_agent/project_manifest.json'),
        );
      },
    );
  });

  test('keeps shared exit code contract stable', () {
    expect(CliExitCodes.success, 0);
    expect(CliExitCodes.executionFailure, 1);
    expect(CliExitCodes.invalidInput, 2);
    expect(CliExitCodes.notFound, 3);
  });
}

AppSettings _buildSettings({required String defaultProjectPath}) {
  return AppSettings(
    defaultProviderId: 'provider-a',
    defaultAgentId: 'agent-a',
    defaultModelId: 'model-a',
    defaultProjectPath: defaultProjectPath,
    autoSaveDrafts: false,
    providers: const <ProviderEndpointSettings>[],
  );
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  final AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<AppSettings> save(AppSettings settings) async => settings;
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this._projects);

  final Map<String, ProjectDescriptor?> _projects;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    return _projects[rootPath];
  }
}

class _CorruptManifestProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    throw ProjectManifestCorruptionException(rootPath: rootPath);
  }
}

class _RecordingTerminalPrinter extends TerminalPrinter {
  final List<String> errors = <String>[];
  final List<String> infos = <String>[];
  final List<String> successes = <String>[];
  final List<String> blocks = <String>[];

  @override
  void error(String message) {
    errors.add(message);
  }

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void success(String message) {
    successes.add(message);
  }

  @override
  void block(String title, String content) {
    blocks.add('$title\n$content');
  }
}
