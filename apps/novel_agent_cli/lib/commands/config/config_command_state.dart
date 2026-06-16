part of 'config_command.dart';

Future<int> _runConfigShow(ConfigCommand command) async {
  // 中文注释: show 只投影当前 settings 的正式字段和安全摘要，不回写任何内容。
  final settings = await command._settingsRepository.load();
  command._printer.block(
    'config show',
    _prettyJson(_projectedSettings(settings)),
  );
  return 0;
}

Future<int> _runConfigGet(ConfigCommand command, List<String> args) async {
  // 中文注释: get 只读取单个配置键，方便脚本在不解析整份 settings 的情况下取值。
  final key = _requiredKey(args);
  if (key.isEmpty) {
    command._printer.error('请通过 --key 指定配置键。');
    return CliExitCodes.invalidInput;
  }
  final settings = await command._settingsRepository.load();
  final value = _getConfigValue(settings, key);
  if (value == null) {
    command._printer.error('未找到配置键: $key');
    return CliExitCodes.notFound;
  }
  command._printer.block(
    'config get',
    _prettyJson(<String, Object?>{'key': key, 'value': value}),
  );
  return 0;
}

Future<int> _runConfigSet(ConfigCommand command, List<String> args) async {
  // 中文注释: set 只改明确的 settings 字段，并通过仓储统一保存，不在 CLI 内拼接磁盘格式。
  final key = _requiredKey(args);
  final value = _requiredValue(args);
  if (key.isEmpty || value.isEmpty) {
    command._printer.error('请通过 --key 与 --value 指定配置更新。');
    return CliExitCodes.invalidInput;
  }
  final current = await command._settingsRepository.load();
  final updated = _setConfigValue(current, key, value);
  await command._settingsRepository.save(updated);
  command._printer.success('配置已保存。');
  command._printer.block(
    'config set',
    _prettyJson(<String, Object?>{
      'key': key,
      'value': _getConfigValue(updated, key),
    }),
  );
  return 0;
}

Future<int> _runConfigProvider(ConfigCommand command, List<String> args) async {
  // 中文注释: provider 子命令只负责 provider 列表投影，避免配置命令再长出一套 provider 编辑器。
  final action = args.isEmpty ? 'list' : args.first;
  switch (action) {
    case 'list':
      final settings = await command._settingsRepository.load();
      final providers = _projectedProviders(settings);
      if (providers.isEmpty) {
        command._printer.info('当前没有 provider。');
        return 0;
      }
      command._printer.block('config provider list', providers.join('\n'));
      return 0;
    case 'help':
    case '--help':
    case '-h':
      _printConfigHelp(command);
      return 0;
    default:
      command._printer.error('未知 config provider 动作: $action');
      _printConfigHelp(command);
      return CliExitCodes.invalidInput;
  }
}

JsonMap _projectedSettings(AppSettings settings) {
  // 中文注释: show 命令只投影安全摘要和正式字段，不泄露 api key 明文。
  return <String, Object?>{
    'default_provider_id': settings.defaultProviderId,
    'default_agent_id': settings.defaultAgentId,
    'default_model_id': settings.defaultModelId,
    'default_project_path': settings.defaultProjectPath,
    AppSettings.draftFallbackProtectionConfigKey:
        settings.draftFallbackProtectionEnabled,
    'provider_count': settings.providers.length,
    'default_provider': _projectedProvider(
      settings.defaultProvider(),
      isDefaultFallback: true,
    ),
    'providers': _projectedProviders(settings),
    'permissions': settings.permissionSettings,
    'tool_strategy': settings.toolStrategySettings,
    'network': settings.networkSettings,
    'context': settings.contextSettings,
    'theme': settings.themeSettings,
    'extra': settings.extraSettings,
  };
}

List<String> _projectedProviders(AppSettings settings) {
  // 中文注释: provider 列表投影只展示识别和定位必要信息，避免设置命令变成密钥展示器。
  return settings.providers
      .map(
        (provider) =>
            '${provider.isDefault ? "*" : " "} '
            '${provider.id}｜${provider.title}｜${provider.protocol}｜${provider.baseUrl}｜${provider.modelId}',
      )
      .toList(growable: false);
}

JsonMap? _projectedProvider(
  ProviderEndpointSettings? provider, {
  bool isDefaultFallback = false,
}) {
  // 中文注释: 默认 provider 投影也要避免输出 api key 明文，只保留存在性和定位信息。
  if (provider == null) {
    return null;
  }
  return <String, Object?>{
    'id': provider.id,
    'title': provider.title,
    'protocol': provider.protocol,
    'base_url': provider.baseUrl,
    'model_id': provider.modelId,
    'is_default': provider.isDefault || isDefaultFallback,
    'api_key_present': provider.apiKey.trim().isNotEmpty,
  };
}

Object? _getConfigValue(AppSettings settings, String key) {
  // 中文注释: get 命令统一走同一条字段映射，确保脚本和人类看到的是同一份配置合同。
  final cleanKey = key.trim();
  switch (cleanKey) {
    case 'default_provider_id':
      return settings.defaultProviderId;
    case 'default_agent_id':
      return settings.defaultAgentId;
    case 'default_model_id':
      return settings.defaultModelId;
    case 'default_project_path':
      return settings.defaultProjectPath;
    case AppSettings.draftFallbackProtectionConfigKey:
    case 'auto_save_drafts':
      return settings.draftFallbackProtectionEnabled;
    case 'providers':
      return _projectedProviders(settings);
  }
  final segments = cleanKey
      .split('.')
      .where((item) => item.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return null;
  }
  final head = segments.first;
  final tail = segments.skip(1).toList(growable: false);
  switch (head) {
    case 'permissions':
      return _deepGet(settings.permissionSettings, tail);
    case 'tool_strategy':
      return _deepGet(settings.toolStrategySettings, tail);
    case 'network':
      return _deepGet(settings.networkSettings, tail);
    case 'context':
      return _deepGet(settings.contextSettings, tail);
    case 'theme':
      return _deepGet(settings.themeSettings, tail);
    case 'extra':
      return _deepGet(settings.extraSettings, tail);
    default:
      return _deepGet(settings.extraSettings, segments);
  }
}

AppSettings _setConfigValue(AppSettings settings, String key, String value) {
  // 中文注释: set 命令只更新显式指定的字段，并尽量保留未识别的扩展设置段。
  final cleanKey = key.trim();
  final parsedValue = _coerceSettingValue(value);
  switch (cleanKey) {
    case 'default_provider_id':
      return settings.copyWith(defaultProviderId: parsedValue.toString());
    case 'default_agent_id':
      return settings.copyWith(defaultAgentId: parsedValue.toString());
    case 'default_model_id':
      return settings.copyWith(defaultModelId: parsedValue.toString());
    case 'default_project_path':
      return settings.copyWith(defaultProjectPath: parsedValue.toString());
    case AppSettings.draftFallbackProtectionConfigKey:
    case 'auto_save_drafts':
      return settings.copyWith(
        draftFallbackProtectionEnabled: _coerceBooleanSettingValue(
          value,
          fallback: settings.draftFallbackProtectionEnabled,
        ),
      );
  }
  final segments = cleanKey
      .split('.')
      .where((item) => item.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return settings;
  }
  final head = segments.first;
  final tail = segments.skip(1).toList(growable: false);
  switch (head) {
    case 'permissions':
      return settings.copyWith(
        permissionSettings: _setNestedValue(
          settings.permissionSettings,
          tail,
          parsedValue,
        ),
      );
    case 'tool_strategy':
      return settings.copyWith(
        toolStrategySettings: _setNestedValue(
          settings.toolStrategySettings,
          tail,
          parsedValue,
        ),
      );
    case 'network':
      return settings.copyWith(
        networkSettings: _setNestedValue(
          settings.networkSettings,
          tail,
          parsedValue,
        ),
      );
    case 'context':
      return settings.copyWith(
        contextSettings: _setNestedValue(
          settings.contextSettings,
          tail,
          parsedValue,
        ),
      );
    case 'theme':
      return settings.copyWith(
        themeSettings: _setNestedValue(
          settings.themeSettings,
          tail,
          parsedValue,
        ),
      );
    case 'extra':
      return settings.copyWith(
        extraSettings: _setNestedValue(
          settings.extraSettings,
          tail,
          parsedValue,
        ),
      );
    default:
      return settings.copyWith(
        extraSettings: _setNestedValue(
          settings.extraSettings,
          segments,
          parsedValue,
        ),
      );
  }
}

Object? _coerceSettingValue(String value) {
  // 中文注释: 简单类型自动推断只服务 config set，避免把所有配置值都强制写成字符串。
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final lowered = trimmed.toLowerCase();
  if (lowered == 'true') {
    return true;
  }
  if (lowered == 'false') {
    return false;
  }
  final intValue = int.tryParse(trimmed);
  if (intValue != null) {
    return intValue;
  }
  final doubleValue = double.tryParse(trimmed);
  if (doubleValue != null) {
    return doubleValue;
  }
  return trimmed;
}

bool _coerceBooleanSettingValue(String value, {required bool fallback}) {
  // 中文注释: 布尔字段单独走专用解析，避免 config set 在 true/false 之外的常见写法上失真。
  final lowered = value.trim().toLowerCase();
  if (lowered.isEmpty) {
    return fallback;
  }
  if (lowered == 'true' ||
      lowered == '1' ||
      lowered == 'yes' ||
      lowered == 'on') {
    return true;
  }
  if (lowered == 'false' ||
      lowered == '0' ||
      lowered == 'no' ||
      lowered == 'off') {
    return false;
  }
  return fallback;
}

JsonMap _setNestedValue(JsonMap source, List<String> path, Object? value) {
  // 中文注释: 嵌套配置写入采用纯 JSON map 递归复制，避免 CLI 直接拼接磁盘结构。
  if (path.isEmpty) {
    return <String, Object?>{};
  }
  final next = Map<String, Object?>.from(source);
  if (path.length == 1) {
    next[path.first] = value;
    return next;
  }
  final head = path.first;
  final tail = path.skip(1).toList(growable: false);
  next[head] = _setNestedValue(_mapValue(next[head]), tail, value);
  return next;
}

Object? _deepGet(JsonMap source, List<String> path) {
  // 中文注释: 读取与写入使用同一条路径规则，确保 config get/set 的行为对称。
  if (path.isEmpty) {
    return source;
  }
  Object? current = source;
  for (final segment in path) {
    if (current is Map) {
      final map = current.map((key, value) => MapEntry(key.toString(), value));
      current = map[segment];
      continue;
    }
    return null;
  }
  return current;
}

Map<String, Object?> _mapValue(Object? value) {
  // 中文注释: 嵌套 map 写入前先统一成字符串键字典，避免配置树中保留动态类型壳层。
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, Object?>{};
}

String _requiredKey(List<String> args) {
  // 中文注释: 配置键既支持 flag，也支持第一个位置参数，方便脚本和人工输入共享。
  return CliArguments(args).value('--key') ?? _firstPositional(args) ?? '';
}

String _requiredValue(List<String> args) {
  // 中文注释: 配置值优先读取 --value，其次读取剩余位置参数并保留空格。
  final explicit = CliArguments(args).value('--value');
  if (explicit != null && explicit.trim().isNotEmpty) {
    return explicit.trim();
  }
  final positionals = _positionalTokens(args);
  if (positionals.length >= 2) {
    return positionals.skip(1).join(' ').trim();
  }
  return '';
}

String? _firstPositional(List<String> args) {
  // 中文注释: 这里只抓第一个非 flag token，避免把 value 合并成单个字符串时丢掉 key 边界。
  for (var index = 0; index < args.length; index += 1) {
    final token = args[index];
    if (token.startsWith('-')) {
      if (!token.contains('=') &&
          index + 1 < args.length &&
          !args[index + 1].startsWith('-')) {
        index += 1;
      }
      continue;
    }
    return token.trim();
  }
  return null;
}

List<String> _positionalTokens(List<String> args) {
  // 中文注释: 位置参数列表用于 set 命令，保证 value 里带空格时还能准确还原。
  final result = <String>[];
  for (var index = 0; index < args.length; index += 1) {
    final token = args[index];
    if (!token.startsWith('-')) {
      result.add(token);
      continue;
    }
    if (token.contains('=')) {
      continue;
    }
    if (index + 1 < args.length && !args[index + 1].startsWith('-')) {
      index += 1;
    }
  }
  return result;
}
