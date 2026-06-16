import 'dart:convert';

import 'package:novel_agent_cli/commands/config/config_command.dart';
import 'package:novel_agent_cli/output/cli_json_output_writer.dart';
import 'package:novel_agent_cli/output/cli_output_mode.dart';
import 'package:novel_agent_cli/output/cli_output_settings.dart';
import 'package:novel_agent_cli/output/terminal_printer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigCommand', () {
    test('show publishes a JSON projection without provider secrets', () async {
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
            ProviderEndpointSettings(
              id: 'provider_2',
              title: '备用 provider',
              protocol: 'openai_compatible',
              baseUrl: 'https://backup.invalid/v1',
              apiKey: 'backup-secret',
              modelId: 'gpt-4o-mini',
              description: 'for tests',
            ),
          ],
          networkSettings: <String, Object?>{'proxy_mode': 'system'},
          extraSettings: <String, Object?>{'custom_flag': 'enabled'},
        ),
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
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>['show']);

      expect(exitCode, 0);
      expect(stderrLines, isEmpty);
      expect(stdoutLines, hasLength(1));
      final payload = jsonDecode(stdoutLines.single) as Map<String, Object?>;
      expect(payload['type'], 'block');
      expect(payload['title'], 'config show');
      final content =
          jsonDecode(payload['content'] as String) as Map<String, Object?>;
      expect(content['default_provider_id'], 'provider_1');
      expect(content['draft_fallback_protection'], isTrue);
      expect(content['provider_count'], 2);
      final defaultProvider =
          content['default_provider'] as Map<String, Object?>;
      expect(defaultProvider['id'], 'provider_1');
      expect(defaultProvider['api_key_present'], isTrue);
      expect(stdoutLines.single, isNot(contains('secret-key')));
    });

    test('get reads nested values through the shared key contract', () async {
      final repository = _FakeSettingsRepository(
        const AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: 'default_agent',
          defaultModelId: 'gpt-4o',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
          networkSettings: <String, Object?>{'proxy_mode': 'custom'},
        ),
      );
      final printer = _RecordingTerminalPrinter();
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>[
        'get',
        '--key',
        'network.proxy_mode',
      ]);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'config get',
            '{\n  "key": "network.proxy_mode",\n  "value": "custom"\n}',
          ),
        ),
      );
    });

    test('get accepts draft fallback protection semantic key', () async {
      final repository = _FakeSettingsRepository(
        const AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: 'default_agent',
          defaultModelId: 'gpt-4o',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
        ),
      );
      final printer = _RecordingTerminalPrinter();
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>[
        'get',
        '--key',
        'draft_fallback_protection',
      ]);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'config get',
            '{\n  "key": "draft_fallback_protection",\n  "value": true\n}',
          ),
        ),
      );
    });

    test('set updates settings and persists through the repository', () async {
      final repository = _FakeSettingsRepository(
        const AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: 'default_agent',
          defaultModelId: 'gpt-4o',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
        ),
      );
      final printer = _RecordingTerminalPrinter();
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>[
        'set',
        'default_model_id',
        'gpt-4.1',
      ]);

      expect(exitCode, 0);
      expect(repository.savedSettings?.defaultModelId, 'gpt-4.1');
      expect(printer.successes, contains('配置已保存。'));
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'config set',
            '{\n  "key": "default_model_id",\n  "value": "gpt-4.1"\n}',
          ),
        ),
      );
    });

    test('set keeps legacy auto_save_drafts alias compatible', () async {
      final repository = _FakeSettingsRepository(
        const AppSettings(
          defaultProviderId: 'provider_1',
          defaultAgentId: 'default_agent',
          defaultModelId: 'gpt-4o',
          defaultProjectPath: 'D:/Novel',
          autoSaveDrafts: true,
          providers: <ProviderEndpointSettings>[],
        ),
      );
      final printer = _RecordingTerminalPrinter();
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>[
        'set',
        '--key',
        'auto_save_drafts',
        '--value',
        'false',
      ]);

      expect(exitCode, 0);
      expect(repository.savedSettings?.draftFallbackProtectionEnabled, isFalse);
    });

    test('provider list prints provider projections without api keys', () async {
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
            ProviderEndpointSettings(
              id: 'provider_2',
              title: '备用 provider',
              protocol: 'openai_compatible',
              baseUrl: 'https://backup.invalid/v1',
              apiKey: 'backup-secret',
              modelId: 'gpt-4o-mini',
              description: 'for tests',
            ),
          ],
        ),
      );
      final printer = _RecordingTerminalPrinter();
      final command = ConfigCommand(
        settingsRepository: repository,
        printer: printer,
      );

      final exitCode = await command.run(<String>['provider', 'list']);

      expect(exitCode, 0);
      expect(
        printer.blocks,
        contains(
          _PrintedBlock(
            'config provider list',
            '* provider_1｜主 provider｜openai_compatible｜https://example.invalid/v1｜gpt-4o\n'
                '  provider_2｜备用 provider｜openai_compatible｜https://backup.invalid/v1｜gpt-4o-mini',
          ),
        ),
      );
      expect(printer.blocks.single.content, isNot(contains('secret-key')));
      expect(printer.blocks.single.content, isNot(contains('backup-secret')));
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.appSettings);

  AppSettings appSettings;
  AppSettings? savedSettings;

  @override
  Future<AppSettings> load() async => appSettings;

  @override
  Future<AppSettings> save(AppSettings settings) async {
    // 中文注释: 测试里的 settings 仓储只需要记录最后一次写回，验证 config set 是否真的走了保存路径。
    savedSettings = settings;
    appSettings = settings;
    return settings;
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
