import 'dart:io';

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
  // 中文注释: 探针统一从仓库根目录读取测试接口，避免每个脚本各自维护一套解析逻辑。
  final file = File(
    '${Directory.current.parent.parent.path}${Platform.pathSeparator}test_api.txt',
  );
  final lines = await file.readAsLines();
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
