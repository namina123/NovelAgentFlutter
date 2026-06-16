import 'package:novel_agent_core/novel_agent_core.dart';

import 'cli_command_context.dart';

class CliSettingsContextLoader {
  const CliSettingsContextLoader({
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  Future<CliCommandContext> load() async {
    // 中文注释: settings 读取集中在共享 loader，CLI 命令层不再各自重复打开设置并拆解默认项目路径。
    final settings = await _settingsRepository.load();
    return CliCommandContext(
      settings: settings,
      defaultProjectPath: settings.defaultProjectPath,
    );
  }
}
