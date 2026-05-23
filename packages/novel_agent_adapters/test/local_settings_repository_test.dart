import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
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
  });
}
