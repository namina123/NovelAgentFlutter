import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({
    required List<String> settingsSearchRoots,
    required String defaultProjectRootPath,
    bool allowConfiguredProjectPathOverride = true,
    Map<String, String>? environment,
  }) : _settingsSearchRoots = settingsSearchRoots,
       _defaultProjectRootPath = defaultProjectRootPath,
       _allowConfiguredProjectPathOverride = allowConfiguredProjectPathOverride,
       _environment = environment ?? Platform.environment;

  final List<String> _settingsSearchRoots;
  final String _defaultProjectRootPath;
  final bool _allowConfiguredProjectPathOverride;
  final Map<String, String> _environment;
  String _lastSettingsFilePath = '';
  String _lastSettingsBasePath = '';
  Map<String, Object?> _lastLoadedDocument = <String, Object?>{};

  @override
  Future<AppSettings> load() async {
    // 中文注释: 本地设置仓储统一处理配置文件与环境变量兜底，避免宿主层散写读取优先级。
    final record = await _loadDocument();
    final document = record.document;
    final documentBasePath = record.basePath;
    final providers = _resolveProviders(document);
    final defaultProviderId = _env('NOVEL_AGENT_PROVIDER_ID').isNotEmpty
        ? _env('NOVEL_AGENT_PROVIDER_ID')
        : _stringValue(document['default_provider_id']);
    final defaultAgentId = _env('NOVEL_AGENT_AGENT_ID').isNotEmpty
        ? _env('NOVEL_AGENT_AGENT_ID')
        : _stringValue(document['default_agent_id'], 'default_generalist');
    final defaultModelId = _env('NOVEL_AGENT_MODEL_ID').isNotEmpty
        ? _env('NOVEL_AGENT_MODEL_ID')
        : _stringValue(document['default_model_id']);
    final defaultProjectPath = _resolveDefaultProjectPath(
      document,
      basePath: documentBasePath,
    );
    return AppSettings(
      defaultProviderId: defaultProviderId,
      defaultAgentId: defaultAgentId,
      defaultModelId: defaultModelId,
      defaultProjectPath: defaultProjectPath,
      autoSaveDrafts: _boolValue(document['auto_save_drafts'], true),
      providers: providers,
      permissionSettings: _mapValue(document['permissions']),
      toolStrategySettings: _mapValue(document['tool_strategy']),
      networkSettings: _mapValue(document['network']),
      contextSettings: _mapValue(document['context']),
      themeSettings: _mapValue(document['theme']),
      extraSettings: _remainingSettings(document),
    );
  }

  @override
  Future<AppSettings> save(AppSettings settings) async {
    // 中文注释: 设置保存统一写回同一份 JSON 文档，并保留无法识别的附加字段，避免 GUI 改写掉用户自己的扩展段。
    if (_lastSettingsBasePath.trim().isEmpty) {
      await load();
    }
    final basePath = _lastSettingsBasePath.trim().isEmpty
        ? Directory(_defaultProjectRootPath).absolute.parent.path
        : _lastSettingsBasePath;
    final filePath = _resolvedSettingsFilePath(basePath);
    final document = <String, Object?>{
      ..._lastLoadedDocument,
      ...settings.extraSettings,
      'default_provider_id': settings.defaultProviderId,
      'default_agent_id': settings.defaultAgentId,
      'default_model_id': settings.defaultModelId,
      'default_project_path': _storedProjectPath(
        settings.defaultProjectPath,
        basePath: basePath,
      ),
      'auto_save_drafts': settings.autoSaveDrafts,
      'providers': settings.providers
          .map(_providerToDocument)
          .toList(growable: false),
      'permissions': Map<String, Object?>.from(settings.permissionSettings),
      'tool_strategy': Map<String, Object?>.from(settings.toolStrategySettings),
      'network': _normalizedNetworkDocument(settings.networkSettings),
      'context': Map<String, Object?>.from(settings.contextSettings),
      'theme': Map<String, Object?>.from(settings.themeSettings),
    };
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(document)}\n');
    _lastSettingsFilePath = file.absolute.path;
    _lastSettingsBasePath = file.absolute.parent.path;
    _lastLoadedDocument = Map<String, Object?>.from(document);
    return load();
  }

  JsonMap _remainingSettings(Map<String, Object?> document) {
    // 中文注释: 未被当前设置模型直接理解的键统一保留下来，方便未来扩展而不丢失用户手写配置。
    final next = Map<String, Object?>.from(document);
    for (final key in <String>[
      'default_provider_id',
      'default_agent_id',
      'default_model_id',
      'default_project_path',
      'auto_save_drafts',
      'providers',
      'permissions',
      'tool_strategy',
      'network',
      'context',
      'theme',
    ]) {
      next.remove(key);
    }
    return next;
  }

  Map<String, Object?> _providerToDocument(ProviderEndpointSettings provider) {
    // 中文注释: provider 写回 JSON 时统一从模型投影，保持 GUI 与 CLI 使用同一份磁盘结构。
    return <String, Object?>{
      'id': provider.id,
      'title': provider.title,
      'protocol': provider.protocol,
      'base_url': provider.baseUrl,
      'api_key': provider.apiKey,
      'model_id': provider.modelId,
      'description': provider.description,
      'is_default': provider.isDefault,
    };
  }

  Map<String, Object?> _normalizedNetworkDocument(JsonMap networkSettings) {
    // 中文注释: 网络设置持久化前在这里统一收敛，保证代理模式、协议和端口范围都落在稳定结构里。
    final normalized = Map<String, Object?>.from(networkSettings);
    final mode = _stringValue(normalized['proxy_mode'], 'system')
        .toLowerCase();
    final protocol = _stringValue(normalized['proxy_protocol']).toLowerCase();
    final host = _stringValue(normalized['proxy_host']);
    final port = NetworkProxyPortPolicy.normalizeText(
      _stringValue(normalized['proxy_port']),
    );
    normalized['proxy_mode'] = mode == 'custom' ? 'custom' : 'system';
    normalized['proxy_protocol'] =
        protocol == 'http' || protocol == 'socks5' ? protocol : '';
    normalized['proxy_port'] = port;
    if (mode != 'custom' || host.isEmpty || port.isEmpty) {
      normalized['proxy_mode'] = 'system';
      normalized['proxy_protocol'] = '';
      normalized['proxy_host'] = '';
      normalized['proxy_port'] = '';
      normalized['proxy_username'] = '';
      normalized['proxy_password'] = '';
    } else {
      normalized['proxy_host'] = host;
      normalized['proxy_username'] = _stringValue(normalized['proxy_username']);
      normalized['proxy_password'] = _stringValue(normalized['proxy_password']);
    }
    return normalized;
  }

  String _resolvedSettingsFilePath(String basePath) {
    // 中文注释: 没有现成设置文件时，默认把配置写到首选设置根目录下的标准文件名。
    if (_lastSettingsFilePath.trim().isNotEmpty) {
      return _lastSettingsFilePath;
    }
    if (_settingsSearchRoots.isNotEmpty &&
        _settingsSearchRoots.first.trim().isNotEmpty) {
      return '${Directory(_settingsSearchRoots.first).absolute.path}${Platform.pathSeparator}novel_agent_settings.json';
    }
    return '$basePath${Platform.pathSeparator}novel_agent_settings.json';
  }

  String _storedProjectPath(String projectPath, {required String basePath}) {
    // 中文注释: 保存项目路径时尽量写成相对设置根的形式，保持桌面端配置可搬移；移动端仍可被固定根策略忽略。
    final absoluteProjectPath = Directory(projectPath).absolute.path;
    final absoluteBasePath = Directory(basePath).absolute.path;
    if (!absoluteProjectPath.startsWith(absoluteBasePath)) {
      return absoluteProjectPath;
    }
    var relative = absoluteProjectPath.substring(absoluteBasePath.length);
    if (relative.startsWith(Platform.pathSeparator)) {
      relative = relative.substring(1);
    }
    return relative.replaceAll(Platform.pathSeparator, '/');
  }

  Future<({Map<String, Object?> document, String basePath})>
  _loadDocument() async {
    // 中文注释: 配置文件发现规则集中在这里，并返回项目相对路径解析所需的基准目录。
    final explicitPath = _env('NOVEL_AGENT_SETTINGS_PATH');
    final candidates = <({String filePath, String basePath})>[
      if (explicitPath.isNotEmpty)
        (
          filePath: explicitPath,
          basePath: File(explicitPath).absolute.parent.path,
        ),
      for (final rootPath in _settingsSearchRoots)
        (
          filePath:
              '$rootPath${Platform.pathSeparator}novel_agent_settings.json',
          basePath: rootPath,
        ),
      for (final rootPath in _settingsSearchRoots)
        (
          filePath:
              '$rootPath${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
          basePath: rootPath,
        ),
    ];
    for (final candidate in candidates) {
      final file = File(candidate.filePath);
      if (!await file.exists()) {
        continue;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        final document = Map<String, Object?>.from(decoded);
        _rememberLoadedDocument(
          filePath: file.absolute.path,
          basePath: Directory(candidate.basePath).absolute.path,
          document: document,
        );
        return (
          document: document,
          basePath: Directory(candidate.basePath).absolute.path,
        );
      }
      if (decoded is Map) {
        final document = decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        _rememberLoadedDocument(
          filePath: file.absolute.path,
          basePath: Directory(candidate.basePath).absolute.path,
          document: document,
        );
        return (
          document: document,
          basePath: Directory(candidate.basePath).absolute.path,
        );
      }
    }
    final basePath = Directory(_defaultProjectRootPath).absolute.parent.path;
    _rememberLoadedDocument(
      filePath: _resolvedSettingsFilePath(basePath),
      basePath: basePath,
      document: <String, Object?>{},
    );
    return (document: <String, Object?>{}, basePath: basePath);
  }

  void _rememberLoadedDocument({
    required String filePath,
    required String basePath,
    required Map<String, Object?> document,
  }) {
    // 中文注释: 最近一次载入结果缓存在仓储内部，供后续保存时保留原文件位置和扩展字段。
    _lastSettingsFilePath = filePath;
    _lastSettingsBasePath = basePath;
    _lastLoadedDocument = Map<String, Object?>.from(document);
  }

  List<ProviderEndpointSettings> _resolveProviders(
    Map<String, Object?> document,
  ) {
    // 中文注释: provider 列表归一化统一在仓储内部完成，避免上层重复填默认值和环境变量覆盖。
    final rawProviders = document['providers'];
    final providers = <ProviderEndpointSettings>[];
    if (rawProviders is List) {
      for (final rawProvider in rawProviders) {
        final normalized = _mapValue(rawProvider);
        if (normalized.isEmpty) {
          continue;
        }
        providers.add(_providerFromMap(normalized));
      }
    }
    final envProviderId = _env('NOVEL_AGENT_PROVIDER_ID');
    final envBaseUrl = _env('NOVEL_AGENT_PROVIDER_BASE_URL');
    final envApiKey = _env('NOVEL_AGENT_PROVIDER_API_KEY');
    final envModelId = _env('NOVEL_AGENT_MODEL_ID');
    if (envProviderId.isEmpty &&
        envBaseUrl.isEmpty &&
        envApiKey.isEmpty &&
        envModelId.isEmpty) {
      return providers;
    }
    final overridden = <ProviderEndpointSettings>[];
    for (final provider in providers) {
      final shouldOverride =
          envProviderId.isEmpty || provider.id == envProviderId;
      if (!shouldOverride) {
        overridden.add(provider);
        continue;
      }
      overridden.add(
        ProviderEndpointSettings(
          id: envProviderId.isEmpty ? provider.id : envProviderId,
          title: provider.title,
          protocol: provider.protocol,
          baseUrl: envBaseUrl.isEmpty ? provider.baseUrl : envBaseUrl,
          apiKey: envApiKey.isEmpty ? provider.apiKey : envApiKey,
          modelId: envModelId.isEmpty ? provider.modelId : envModelId,
          description: provider.description,
          isDefault: true,
        ),
      );
    }
    return overridden;
  }

  ProviderEndpointSettings _providerFromMap(Map<String, Object?> document) {
    // 中文注释: 单个 provider 条目在这里完成字段归一化，保持设置模型的稳定结构。
    return ProviderEndpointSettings(
      id: _stringValue(document['id'], 'local-openai'),
      title: _stringValue(document['title'], '本地 OpenAI Compatible'),
      protocol: _stringValue(document['protocol'], 'openai_compatible'),
      baseUrl: _stringValue(document['base_url'], ''),
      apiKey: _stringValue(document['api_key']),
      modelId: _stringValue(document['model_id'], ''),
      description: _stringValue(
        document['description'],
        '请改成你的 OpenAI 兼容模型接口地址。',
      ),
      isDefault: _boolValue(document['is_default'], false),
    );
  }

  String _resolveDefaultProjectPath(
    Map<String, Object?> document, {
    required String basePath,
  }) {
    // 中文注释: 默认项目路径在这里统一处理环境变量、配置覆盖和移动端固定根目录策略。
    final environmentProjectPath = _env('NOVEL_AGENT_PROJECT_PATH');
    if (environmentProjectPath.isNotEmpty) {
      return _resolveProjectPath(environmentProjectPath, basePath: basePath);
    }
    if (!_allowConfiguredProjectPathOverride) {
      return Directory(_defaultProjectRootPath).absolute.path;
    }
    final configuredProjectPath = _stringValue(
      document['default_project_path'],
    );
    if (configuredProjectPath.isEmpty) {
      return Directory(_defaultProjectRootPath).absolute.path;
    }
    return _resolveProjectPath(configuredProjectPath, basePath: basePath);
  }

  String _resolveProjectPath(String rawPath, {required String basePath}) {
    // 中文注释: 相对项目路径总是相对设置基准目录解析，避免再偷偷回到当前目录。
    if (rawPath.trim().isEmpty) {
      return Directory(_defaultProjectRootPath).absolute.path;
    }
    if (rawPath.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(rawPath)) {
      return rawPath;
    }
    return Directory(
      '$basePath${Platform.pathSeparator}${rawPath.replaceAll('/', Platform.pathSeparator)}',
    ).absolute.path;
  }

  String _env(String key) {
    // 中文注释: 环境变量读取单独收口，方便后续扩展大小写兼容或其他来源。
    return (_environment[key] ?? '').trim();
  }

  Map<String, Object?> _mapValue(Object? value) {
    // 中文注释: 配置源来自动态 JSON，这里统一转成字符串键字典，减少类型噪音。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, Object?>{};
  }

  String _stringValue(Object? value, [String fallback = '']) {
    // 中文注释: 简单标量读取留在仓储内部，避免为少量配置解析把业务工具类耦合进来。
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value, bool fallback) {
    // 中文注释: 布尔值兼容字符串与数字输入，便于手写 JSON 和环境变量。
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return fallback;
    }
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
