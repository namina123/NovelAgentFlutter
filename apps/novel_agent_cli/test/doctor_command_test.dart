import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_cli/commands/doctor/doctor_command.dart';
import 'package:novel_agent_cli/commands/shared/cli_exit_codes.dart';
import 'package:novel_agent_cli/output/cli_json_output_writer.dart';
import 'package:novel_agent_cli/output/cli_output_mode.dart';
import 'package:novel_agent_cli/output/cli_output_settings.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('DoctorCommand', () {
    test(
      'check publishes a healthy JSON report for a valid project path',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'novel_agent_doctor_command_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final repository = _FakeSettingsRepository(
          const AppSettings(
            defaultProviderId: 'provider_1',
            defaultAgentId: 'default_agent',
            defaultModelId: 'gpt-4o',
            defaultProjectPath: 'D:/Novel',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[
              ProviderEndpointSettings(
                id: 'provider_1',
                title: '主 provider',
                protocol: 'openai_compatible',
                baseUrl: 'https://example.invalid/v1',
                apiKey: 'secret-key',
                modelId: 'gpt-4o',
                description: 'for tests',
                isDefault: true,
              ),
            ],
          ).copyWith(defaultProjectPath: tempDir.path),
        );
        final stdoutLines = <String>[];
        final stderrLines = <String>[];
        final printer = TerminalPrinter(
          settings: const CliOutputSettings(mode: CliOutputMode.json),
          jsonWriter: CliJsonOutputWriter(
            stdoutSink: stdoutLines.add,
            stderrSink: stderrLines.add,
          ),
        );
        final command = DoctorCommand(
          settingsRepository: repository,
          projectRepository: _FakeProjectRepository(expectedPath: tempDir.path),
          printer: printer,
        );

        final exitCode = await command.run(<String>['check']);

        expect(exitCode, 0);
        expect(stderrLines, isEmpty);
        expect(stdoutLines, hasLength(2));
        final reportEvent =
            jsonDecode(stdoutLines.first) as Map<String, Object?>;
        expect(reportEvent['type'], 'block');
        expect(reportEvent['title'], 'doctor report');
        final report =
            jsonDecode(reportEvent['content'] as String)
                as Map<String, Object?>;
        expect(report['default_project_exists'], isTrue);
        expect(report['default_project_openable'], isTrue);
        expect(report['default_provider_present'], isTrue);
        expect(report['provider_count'], 1);
        final successEvent =
            jsonDecode(stdoutLines.last) as Map<String, Object?>;
        expect(successEvent['type'], 'success');
        expect(successEvent['message'], 'doctor 检查通过。');
      },
    );

    test('check fails when the default project cannot be opened', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'novel_agent_doctor_command_test_missing_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final repository = _FakeSettingsRepository(
        const AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: 'default_agent',
          defaultModelId: 'gpt-4o',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[
            ProviderEndpointSettings(
              id: 'provider_1',
              title: '主 provider',
              protocol: 'openai_compatible',
              baseUrl: 'https://example.invalid/v1',
              apiKey: 'secret-key',
              modelId: 'gpt-4o',
              description: 'for tests',
              isDefault: true,
            ),
          ],
        ).copyWith(defaultProjectPath: tempDir.path),
      );
      final printer = _RecordingTerminalPrinter();
      final command = DoctorCommand(
        settingsRepository: repository,
        projectRepository: _NullProjectRepository(),
        printer: printer,
      );

      final exitCode = await command.run(<String>['check']);

      expect(exitCode, CliExitCodes.configError);
      expect(printer.blocks, hasLength(1));
      expect(printer.blocks.single.title, 'doctor report');
      expect(
        printer.blocks.single.content,
        contains('"default_project_exists": true'),
      );
      expect(
        printer.blocks.single.content,
        contains('"default_project_openable": false'),
      );
      expect(
        printer.errors,
        contains('doctor 发现问题：default_project_unopenable'),
      );
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.appSettings);

  AppSettings appSettings;

  @override
  Future<AppSettings> load() async => appSettings;

  @override
  Future<AppSettings> save(AppSettings settings) async {
    // 中文注释: doctor 测试不走保存路径，但仓储实现仍要完整，避免接口契约不一致。
    appSettings = settings;
    return settings;
  }
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({required this.expectedPath});

  final String expectedPath;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    // 中文注释: 健康路径测试只接受预期的默认项目目录，避免 doctor 偷偷依赖更宽松的打开逻辑。
    if (rootPath == expectedPath) {
      return ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: rootPath,
      );
    }
    return null;
  }
}

class _NullProjectRepository implements ProjectRepository {
  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    // 中文注释: 失败路径测试明确返回空，模拟默认项目路径存在但宿主无法打开的情况。
    return null;
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
