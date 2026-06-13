import 'dart:convert';
import 'dart:io';

class LocalProbeApiConfig {
  const LocalProbeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    required this.sourceLabel,
  });

  final String baseUrl;
  final String apiKey;
  final String modelId;
  final String sourceLabel;
}

const String _realProbeOptInEnv = 'NOVEL_AGENT_ENABLE_REAL_PROBES';
const String _probeApiFileEnv = 'NOVEL_AGENT_PROBE_API_FILE';

Future<void> ensureLocalRealProbeOptIn({required String probeName}) async {
  // 中文注释: 真实计费探针默认关闭，只有显式开启环境变量时才允许继续，避免误跑消耗额度。
  await ensureLocalRealProbeOptInWithEnvironment(
    probeName: probeName,
    environment: Platform.environment,
  );
}

Future<void> ensureLocalRealProbeOptInWithEnvironment({
  required String probeName,
  required Map<String, String> environment,
}) async {
  // 中文注释: 环境映射允许测试注入和宿主覆写，避免把真实机器环境绑死在工具函数内部。
  final rawFlag = environment[_realProbeOptInEnv] ?? '';
  final normalizedFlag = rawFlag.trim().toLowerCase();
  if (normalizedFlag == '1' ||
      normalizedFlag == 'true' ||
      normalizedFlag == 'yes') {
    return;
  }
  throw StateError(
    '真实探针 "$probeName" 默认已禁用。'
    '运行前请先设置环境变量 $_realProbeOptInEnv=1，'
    '并把接口配置放到 local/probe_api.txt 或通过 $_probeApiFileEnv 指定。',
  );
}

String resolveLocalProbeRepoRoot({Directory? startDirectory}) {
  // 中文注释: 探针脚本可能从仓库根、app 包或 package 包执行，这里统一沿父目录回溯真实仓库根。
  var current = (startDirectory ?? Directory.current).absolute;
  for (var depth = 0; depth < 8; depth += 1) {
    final agentFile = File('${current.path}${Platform.pathSeparator}agent.md');
    final gitIgnoreFile = File(
      '${current.path}${Platform.pathSeparator}.gitignore',
    );
    final appsDirectory = Directory(
      '${current.path}${Platform.pathSeparator}apps',
    );
    final packagesDirectory = Directory(
      '${current.path}${Platform.pathSeparator}packages',
    );
    if (agentFile.existsSync() &&
        gitIgnoreFile.existsSync() &&
        appsDirectory.existsSync() &&
        packagesDirectory.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

Future<LocalProbeApiConfig> loadLocalProbeApiConfig({
  bool requireRealProbeOptIn = true,
  String probeName = 'probe',
  bool allowLegacyTestApi = false,
  bool allowTempSettingsFallback = false,
  String? repoRootOverride,
  Directory? startDirectory,
  Map<String, String>? environment,
}) async {
  // 中文注释: 真实探针默认只认 local/probe_api.txt 或环境变量显式指定的文件；旧 test_api/temp 回退仅在兼容场景下显式放开。
  final resolvedEnvironment = environment ?? Platform.environment;
  if (requireRealProbeOptIn) {
    await ensureLocalRealProbeOptInWithEnvironment(
      probeName: probeName,
      environment: resolvedEnvironment,
    );
  }
  final repoRoot =
      repoRootOverride ??
      resolveLocalProbeRepoRoot(startDirectory: startDirectory);
  final overrideFile = _resolveOverrideFile(
    repoRoot,
    environment: resolvedEnvironment,
  );
  final candidateTextFiles = <MapEntry<File, String>>[
    if (overrideFile != null)
      MapEntry<File, String>(overrideFile, _probeApiFileEnv),
    MapEntry<File, String>(
      File(
        '$repoRoot${Platform.pathSeparator}local${Platform.pathSeparator}probe_api.txt',
      ),
      'local/probe_api.txt',
    ),
    if (allowLegacyTestApi)
      MapEntry<File, String>(
        File('$repoRoot${Platform.pathSeparator}test_api.txt'),
        'test_api.txt',
      ),
  ];
  for (final entry in candidateTextFiles) {
    final config = await _loadFromProbeTextFile(
      entry.key,
      sourceLabel: entry.value,
    );
    if (config != null) {
      return config;
    }
  }
  if (allowTempSettingsFallback) {
    final tempSettingsFile = File(
      '$repoRoot${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
    );
    final config = await _loadFromTempSettings(
      tempSettingsFile,
      sourceLabel: 'temp/novel_agent_settings.json',
    );
    if (config != null) {
      return config;
    }
  }
  throw StateError(
    '未找到可用探针配置。'
    '请优先创建 local/probe_api.txt，'
    '或通过 $_probeApiFileEnv 指向本地配置文件。'
    '如确需兼容旧 test_api.txt / temp 设置，请在脚本里显式开启对应 fallback。',
  );
}

File? _resolveOverrideFile(
  String repoRoot, {
  required Map<String, String> environment,
}) {
  // 中文注释: 环境变量允许开发者把真实探针配置放到仓库外或其他本地位置，避免重复复制密钥文件。
  final rawPath = environment[_probeApiFileEnv] ?? '';
  final trimmedPath = rawPath.trim();
  if (trimmedPath.isEmpty) {
    return null;
  }
  final candidate = File(trimmedPath);
  if (candidate.isAbsolute) {
    return candidate;
  }
  final normalizedRelativePath = trimmedPath.replaceAll(
    '/',
    Platform.pathSeparator,
  );
  return File('$repoRoot${Platform.pathSeparator}$normalizedRelativePath');
}

Future<LocalProbeApiConfig?> _loadFromProbeTextFile(
  File file, {
  required String sourceLabel,
}) async {
  // 中文注释: 文本配置只接受 baseUrl/apiKey/modelId 三行，保持本地探针入口足够小且易于人工检查。
  if (!await file.exists()) {
    return null;
  }
  final cleanLines = (await file.readAsLines())
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (cleanLines.length < 3) {
    throw StateError('$sourceLabel 至少需要 baseUrl、apiKey、modelId 三行。');
  }
  return LocalProbeApiConfig(
    baseUrl: cleanLines[0],
    apiKey: cleanLines[1],
    modelId: cleanLines[2],
    sourceLabel: sourceLabel,
  );
}

Future<LocalProbeApiConfig?> _loadFromTempSettings(
  File file, {
  required String sourceLabel,
}) async {
  // 中文注释: 旧 temp 设置只保留为兼容回退，避免已有本地工作流在迁移前完全失效。
  if (!await file.exists()) {
    return null;
  }
  final rawDocument = jsonDecode(await file.readAsString());
  if (rawDocument is! Map) {
    throw StateError('$sourceLabel 结构无效。');
  }
  final root = rawDocument.map((key, value) => MapEntry(key.toString(), value));
  final providers = _objectList(root['providers']);
  final defaultProviderId = _stringValue(
    root['defaultProviderId'],
    _stringValue(root['default_provider_id']),
  );
  Map<String, Object?>? selectedProvider;
  for (final candidate in providers) {
    final provider = _mapValue(candidate);
    if (_stringValue(provider['id']) == defaultProviderId) {
      selectedProvider = provider;
      break;
    }
  }
  selectedProvider ??= providers.isEmpty ? null : _mapValue(providers.first);
  if (selectedProvider == null) {
    throw StateError('$sourceLabel 中没有可用 provider。');
  }
  final baseUrl = _stringValue(
    selectedProvider['baseUrl'],
    _stringValue(selectedProvider['base_url']),
  );
  final apiKey = _stringValue(
    selectedProvider['apiKey'],
    _stringValue(selectedProvider['api_key']),
  );
  final modelId = _stringValue(
    selectedProvider['modelId'],
    _stringValue(
      selectedProvider['model_id'],
      _stringValue(
        root['defaultModelId'],
        _stringValue(root['default_model_id']),
      ),
    ),
  );
  if (baseUrl.isEmpty || apiKey.isEmpty || modelId.isEmpty) {
    throw StateError('$sourceLabel 缺少 baseUrl/apiKey/modelId。');
  }
  return LocalProbeApiConfig(
    baseUrl: baseUrl,
    apiKey: apiKey,
    modelId: modelId,
    sourceLabel: sourceLabel,
  );
}

String _stringValue(Object? value, [String fallback = '']) {
  // 中文注释: 配置读取统一把动态 JSON 字段安全收口成字符串，避免在探针边缘散落类型判断。
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

List<Object?> _objectList(Object? value) {
  // 中文注释: providers 可能来自动态 JSON，需要统一成只读对象列表后再做字段解析。
  if (value is List) {
    return List<Object?>.from(value);
  }
  return const <Object?>[];
}

Map<String, Object?> _mapValue(Object? value) {
  // 中文注释: 兼容 Map<dynamic, dynamic> 形态，避免探针配置回退时因为键类型不同而失效。
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, Object?>{};
}
