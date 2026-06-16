import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalSettingsRepository', () {
    test(
      'desktop mode resolves relative default project path against settings root',
      () async {
        // 中文注释: 桌面端允许配置默认项目目录时，相对路径应相对设置根目录而不是当前目录解析。
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_desktop_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final tempDirectory = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}temp',
        );
        await tempDirectory.create(recursive: true);
        final settingsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        await settingsFile.writeAsString('''
{
  "default_project_path": "temp/demo_project"
}
''');
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[sandboxRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}default_project',
        );

        final settings = await repository.load();

        expect(
          settings.defaultProjectPath,
          Directory(
            '${sandboxRoot.path}${Platform.pathSeparator}temp${Platform.pathSeparator}demo_project',
          ).absolute.path,
        );
      },
    );

    test('mobile mode ignores configured default project path', () async {
      // 中文注释: 移动端固定应用沙盒目录时，即使设置文件写了路径也不能覆盖默认项目根。
      final sandboxRoot = await Directory.systemTemp.createTemp(
        'novel_agent_settings_mobile_',
      );
      addTearDown(() async {
        if (await sandboxRoot.exists()) {
          await sandboxRoot.delete(recursive: true);
        }
      });
      final settingsFile = File(
        '${sandboxRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
      );
      await settingsFile.writeAsString('''
{
  "default_project_path": "should/not/be/used"
}
''');
      final fixedProjectRoot = Directory(
        '${sandboxRoot.path}${Platform.pathSeparator}projects${Platform.pathSeparator}default_project',
      ).absolute.path;
      final repository = LocalSettingsRepository(
        settingsSearchRoots: <String>[sandboxRoot.path],
        defaultProjectRootPath: fixedProjectRoot,
        allowConfiguredProjectPathOverride: false,
      );

      final settings = await repository.load();

      expect(settings.defaultProjectPath, fixedProjectRoot);
    });

    test(
      'desktop mode stores sibling project roots as relative paths instead of absolute paths',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_relative_save_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}settings',
        )..createSync(recursive: true);
        final projectRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}projects${Platform.pathSeparator}demo_project',
        ).absolute.path;
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[settingsRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}projects',
        );

        await repository.save(
          const AppSettings(
            defaultProviderId: '',
            defaultAgentId: 'default_generalist',
            defaultModelId: '',
            defaultProjectPath: '',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[],
          ).copyWith(defaultProjectPath: projectRoot),
        );

        final settingsFile = File(
          '${settingsRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        final raw = await settingsFile.readAsString();
        final reloaded = await repository.load();

        expect(
          raw,
          contains('"default_project_path": "../projects/demo_project"'),
        );
        expect(reloaded.defaultProjectPath, projectRoot);
      },
    );

    test(
      'environment override supplies provider api key without persisting it in settings file',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_env_override_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}settings',
        )..createSync(recursive: true);
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[settingsRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}projects',
          environment: const <String, String>{
            'NOVEL_AGENT_PROVIDER_ID': 'hfvv-wave1-provider',
            'NOVEL_AGENT_PROVIDER_API_KEY': 'env-secret-key',
            'NOVEL_AGENT_PROVIDER_BASE_URL': 'https://example.invalid/v1',
            'NOVEL_AGENT_MODEL_ID': 'env-model',
          },
        );

        await repository.save(
          const AppSettings(
            defaultProviderId: 'hfvv-wave1-provider',
            defaultAgentId: 'default_generalist',
            defaultModelId: 'env-model',
            defaultProjectPath: '',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[
              ProviderEndpointSettings(
                id: 'hfvv-wave1-provider',
                title: 'HFVV',
                protocol: 'openai_compatible',
                baseUrl: 'https://stored.invalid/v1',
                apiKey: '',
                modelId: 'stored-model',
                description: '',
                isDefault: true,
              ),
            ],
          ),
        );

        final settingsFile = File(
          '${settingsRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        final raw = await settingsFile.readAsString();
        final loaded = await repository.load();

        expect(raw, contains('"api_key": ""'));
        expect(raw, contains('"default_project_path": ""'));
        expect(loaded.providers, hasLength(1));
        expect(loaded.providers.single.apiKey, 'env-secret-key');
        expect(loaded.providers.single.baseUrl, 'https://example.invalid/v1');
        expect(loaded.providers.single.modelId, 'env-model');
      },
    );

    test(
      're-saving loaded settings does not persist environment override api key',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_env_resave_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}settings',
        )..createSync(recursive: true);
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[settingsRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}projects',
          environment: const <String, String>{
            'NOVEL_AGENT_PROVIDER_ID': 'hfvv-wave1-provider',
            'NOVEL_AGENT_PROVIDER_API_KEY': 'env-secret-key',
            'NOVEL_AGENT_PROVIDER_BASE_URL': 'https://example.invalid/v1',
            'NOVEL_AGENT_MODEL_ID': 'env-model',
          },
        );

        await repository.save(
          const AppSettings(
            defaultProviderId: 'hfvv-wave1-provider',
            defaultAgentId: 'default_generalist',
            defaultModelId: 'env-model',
            defaultProjectPath: '',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[
              ProviderEndpointSettings(
                id: 'hfvv-wave1-provider',
                title: 'HFVV',
                protocol: 'openai_compatible',
                baseUrl: 'https://stored.invalid/v1',
                apiKey: '',
                modelId: 'stored-model',
                description: '',
                isDefault: true,
              ),
            ],
          ),
        );

        final loaded = await repository.load();
        await repository.save(loaded);

        final settingsFile = File(
          '${settingsRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        final raw = await settingsFile.readAsString();

        expect(raw, contains('"api_key": ""'));
        expect(raw, isNot(contains('env-secret-key')));
      },
    );

    test(
      'workbench snapshot stores relative project root and reloads absolute path',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_workbench_snapshot_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}settings',
        )..createSync(recursive: true);
        final projectRoot = Directory(
          '${sandboxRoot.path}${Platform.pathSeparator}projects${Platform.pathSeparator}demo_project',
        ).absolute.path;
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[settingsRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}projects',
        );

        await repository.save(
          AppSettings(
            defaultProviderId: '',
            defaultAgentId: 'default_generalist',
            defaultModelId: '',
            defaultProjectPath: projectRoot,
            autoSaveDrafts: true,
            providers: const <ProviderEndpointSettings>[],
            extraSettings: <String, Object?>{
              'workbench_state': <String, Object?>{
                'project_root_path': projectRoot,
                'active_document_path': 'premise/project_brief.md',
                'expanded_directories': const <String>['chapters', 'assets'],
                'selected_conversation_agent_id': 'reviewer',
              },
            },
          ),
        );

        final settingsFile = File(
          '${settingsRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        final raw = await settingsFile.readAsString();
        final loaded = await repository.load();
        final workbenchState = Map<String, Object?>.from(
          loaded.extraSettings['workbench_state'] as Map,
        );

        expect(
          raw,
          contains('"project_root_path": "../projects/demo_project"'),
        );
        expect(workbenchState['project_root_path'], projectRoot);
        expect(
          workbenchState['active_document_path'],
          'premise/project_overview.md',
        );
      },
    );

    test(
      'legacy auto_save_drafts key still loads as draft fallback protection',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_legacy_draft_fallback_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsFile = File(
          '${sandboxRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        await settingsFile.writeAsString('''
{
  "auto_save_drafts": false
}
''');
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[sandboxRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}default_project',
        );

        final settings = await repository.load();

        expect(settings.draftFallbackProtectionEnabled, isFalse);
      },
    );

    test(
      'save writes canonical draft fallback protection key and drops legacy key',
      () async {
        final sandboxRoot = await Directory.systemTemp.createTemp(
          'novel_agent_settings_canonical_draft_fallback_',
        );
        addTearDown(() async {
          if (await sandboxRoot.exists()) {
            await sandboxRoot.delete(recursive: true);
          }
        });
        final settingsFile = File(
          '${sandboxRoot.path}${Platform.pathSeparator}novel_agent_settings.json',
        );
        await settingsFile.writeAsString('''
{
  "auto_save_drafts": false
}
''');
        final repository = LocalSettingsRepository(
          settingsSearchRoots: <String>[sandboxRoot.path],
          defaultProjectRootPath:
              '${sandboxRoot.path}${Platform.pathSeparator}default_project',
        );

        final loaded = await repository.load();
        await repository.save(loaded.copyWith(autoSaveDrafts: true));
        final raw = await settingsFile.readAsString();

        expect(raw, contains('"draft_fallback_protection": true'));
        expect(raw, isNot(contains('"auto_save_drafts"')));
      },
    );
  });
}
