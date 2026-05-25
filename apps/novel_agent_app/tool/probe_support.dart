import 'dart:io';
import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

typedef ProbeResultValidator =
    Future<Map<String, Object?>> Function(DraftGenerationResult result);

class ProbeApiConfig {
  const ProbeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  final String baseUrl;
  final String apiKey;
  final String modelId;
}

Future<ProbeApiConfig> loadProbeApiConfig() async {
  // 中文注释: 真实探针优先读取 test_api.txt；若当前机器只保留项目设置文件，则自动回退到 temp 设置。
  final repoRoot = _resolveProbeRepoRoot();
  final testApiFile = File(
    '$repoRoot${Platform.pathSeparator}test_api.txt',
  );
  if (await testApiFile.exists()) {
    final lines = await testApiFile.readAsLines();
    final cleanLines = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (cleanLines.length < 3) {
      throw StateError('test_api.txt 至少需要 baseUrl、apiKey、modelId 三行。');
    }
    return ProbeApiConfig(
      baseUrl: cleanLines[0],
      apiKey: cleanLines[1],
      modelId: cleanLines[2],
    );
  }
  final settingsFile = File(
    '$repoRoot${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
  );
  if (!await settingsFile.exists()) {
    throw StateError('未找到 test_api.txt，也未找到 temp/novel_agent_settings.json。');
  }
  final raw = jsonDecode(await settingsFile.readAsString());
  if (raw is! Map) {
    throw StateError('temp/novel_agent_settings.json 结构无效。');
  }
  final root = raw.map((key, value) => MapEntry(key.toString(), value));
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
    throw StateError('temp/novel_agent_settings.json 中没有可用 provider。');
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
      _stringValue(root['defaultModelId'], _stringValue(root['default_model_id'])),
    ),
  );
  if (baseUrl.isEmpty || apiKey.isEmpty || modelId.isEmpty) {
    throw StateError('temp/novel_agent_settings.json 缺少 baseUrl/apiKey/modelId。');
  }
  return ProbeApiConfig(baseUrl: baseUrl, apiKey: apiKey, modelId: modelId);
}

Future<Map<String, Object?>> runDraftProbeCase({
  required GenerateDraftUseCase useCase,
  required ProjectDescriptor project,
  required String modelId,
  required String prompt,
  required ProbeResultValidator validator,
  int maxAttempts = 2,
}) async {
  // 中文注释: 真实 API 探针允许对可判定的传输层抖动做小次数重试，避免把瞬时网络问题误判成实现回归。
  var lastError = '';
  var lastStackTrace = '';
  List<String> lastPhases = const <String>[];
  for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
    final phases = <String>[];
    try {
      final result = await useCase.execute(
        project: project,
        userPrompt: prompt,
        modelId: modelId,
        title: 'Mode Probe',
        requestOptions: const <String, Object?>{'stream': true},
        contextSettings: const <String, Object?>{},
        modelProfile: const <String, Object?>{},
        onProgress: (progress) {
          phases.add(progress.phase);
        },
      );
      final validation = await validator(result);
      return <String, Object?>{
        ...validation,
        'attempt': attempt,
        'progress_phases': phases,
        'executed_tools': result.executedTools,
        'written_paths': result.writtenPaths,
        'changed_paths': result.changedPaths,
        'waiting_for_user_choice': result.waitingForUserChoice,
        'reasoning_content': result.reasoningContent,
        'draft_markdown': result.draftMarkdown,
      };
    } catch (error, stackTrace) {
      lastError = '$error';
      lastStackTrace = '$stackTrace';
      lastPhases = phases;
      if (!_isRetryableTransportError(error) || attempt >= maxAttempts) {
        break;
      }
    }
  }
  return <String, Object?>{
    'ok': false,
    'summary': lastError,
    'stack_trace': lastStackTrace,
    'progress_phases': lastPhases,
  };
}

bool _isRetryableTransportError(Object error) {
  if (error is HttpException) {
    return true;
  }
  if (error is SocketException) {
    return true;
  }
  final message = '$error'.toLowerCase();
  return message.contains('connection closed before full header') ||
      message.contains('connection terminated') ||
      message.contains('connection reset');
}

String _resolveProbeRepoRoot() {
  // 中文注释: 探针既可能从 app 目录启动，也可能从仓库根启动，因此统一向上查找真实仓库根。
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final testApi = File(
      '${current.path}${Platform.pathSeparator}test_api.txt',
    );
    final settings = File(
      '${current.path}${Platform.pathSeparator}temp${Platform.pathSeparator}novel_agent_settings.json',
    );
    if (testApi.existsSync() || settings.existsSync()) {
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

String _stringValue(Object? value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

List<Object?> _objectList(Object? value) {
  if (value is List) {
    return List<Object?>.from(value);
  }
  return const <Object?>[];
}

Map<String, Object?> _mapValue(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, Object?>{};
}
