import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class OpenAiLlmGateway implements LlmGateway {
  OpenAiLlmGateway({
    required String baseUrl,
    required String apiKey,
    Duration? timeout,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _apiKey = apiKey,
       _timeout = timeout ?? const Duration(seconds: 90);

  factory OpenAiLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider,
  ) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return OpenAiLlmGateway(baseUrl: provider.baseUrl, apiKey: provider.apiKey);
  }

  final String _baseUrl;
  final String _apiKey;
  final Duration _timeout;

  @override
  Future<JsonMap> requestChat({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 这里负责 OpenAI 兼容多轮消息和工具调用协议的 HTTP 往返，不承接项目上下文规则。
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl/chat/completions'))
          .timeout(_timeout);
      request.headers.contentType = ContentType.json;
      if (_apiKey.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      }
      request.write(
        jsonEncode(<String, Object?>{
          'model': modelId,
          'messages': _requestMessages(messages, options),
          if (tools.isNotEmpty) 'tools': tools,
          if (options.containsKey('tool_choice'))
            'tool_choice': options['tool_choice'],
        }),
      );
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          '模型请求失败(${response.statusCode}): $body',
          uri: Uri.parse('$_baseUrl/chat/completions'),
        );
      }
      final decoded = jsonDecode(body);
      final root = _mapValue(decoded);
      final choices = root['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const FormatException('响应中缺少 choices。');
      }
      final firstChoice = _mapValue(choices.first);
      final message = _mapValue(firstChoice['message']);
      final toolCalls = _normalizeToolCalls(message['tool_calls']);
      final content = _messageText(message['content']);
      return <String, Object?>{
        'ok': true,
        'content': content,
        'reasoning_content': _stringValue(
          message['reasoning_content'] ?? firstChoice['reasoning_content'],
        ),
        'message': <String, Object?>{
          ...message,
          'content': content,
          'tool_calls': toolCalls,
        },
        'tool_calls': toolCalls,
        'raw_response': root,
      };
    } finally {
      // 中文注释: HTTP client 生命周期由网关单次请求自行收口，避免 CLI 长时间持有空闲连接。
      client.close(force: true);
    }
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    // 中文注释: 旧接口继续委托到新的多轮聊天实现，保持 CLI/测试里的轻量调用方式不变。
    final result = await requestChat(
      messages: const <JsonMap>[],
      modelId: modelId,
      options: <String, Object?>{'prompt': prompt},
    );
    final content = _stringValue(result['content']).trim();
    if (content.isEmpty) {
      throw const FormatException('响应中缺少可读文本内容。');
    }
    return content;
  }

  static String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，避免后续拼接请求路径时出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  List<Object?> _requestMessages(List<JsonMap> messages, JsonMap options) {
    // 中文注释: 为兼容旧 requestText 包装，这里允许通过 options.prompt 构造单轮 user 消息。
    if (messages.isNotEmpty) {
      return messages
          .map((message) => Map<String, Object?>.from(message))
          .toList(growable: false);
    }
    final prompt = _stringValue(options['prompt']).trim();
    if (prompt.isEmpty) {
      return const <Object?>[];
    }
    return <Object?>[
      <String, Object?>{'role': 'user', 'content': prompt},
    ];
  }

  Map<String, Object?> _mapValue(Object? value) {
    // 中文注释: 网关响应是动态 JSON，这里统一收敛成字符串键字典。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, Object?>{};
  }

  List<Object?> _normalizeToolCalls(Object? value) {
    // 中文注释: 原生 tool_calls 会在网关层先收拢成统一结构，减少上层协议分支。
    final result = <Object?>[];
    if (value is! List) {
      return result;
    }
    for (final rawCall in value) {
      final call = _mapValue(rawCall);
      final functionData = _mapValue(call['function']);
      final argumentsValue = functionData['arguments'];
      Object? parsedArguments = argumentsValue;
      if (argumentsValue is String && argumentsValue.trim().isNotEmpty) {
        try {
          parsedArguments = jsonDecode(argumentsValue);
        } catch (_) {
          parsedArguments = <String, Object?>{};
        }
      }
      result.add(<String, Object?>{
        'id': _stringValue(call['id']),
        'name': _stringValue(functionData['name']),
        'tool_name': _stringValue(functionData['name']),
        'arguments': _mapValue(parsedArguments),
        'raw_arguments': _stringValue(argumentsValue),
        'status': 'pending',
      });
    }
    return result;
  }

  String _messageText(Object? value) {
    // 中文注释: content 既可能是字符串，也可能是 content part 数组，这里统一抽成可读正文。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final part in value) {
        final partMap = _mapValue(part);
        final text = _stringValue(partMap['text']);
        if (text.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(text);
      }
      return buffer.toString();
    }
    return _stringValue(value);
  }

  String _stringValue(Object? value) {
    // 中文注释: 文本提取在网关内部完成，避免把响应结构知识扩散到上层。
    return value == null ? '' : value.toString();
  }
}
