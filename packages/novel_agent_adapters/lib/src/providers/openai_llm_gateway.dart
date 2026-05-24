import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'system_proxy_resolver.dart';

class OpenAiLlmGateway implements LlmGateway {
  OpenAiLlmGateway({
    required String baseUrl,
    required String apiKey,
    Duration? timeout,
    String proxyRule = '',
    String proxyUsername = '',
    String proxyPassword = '',
    SystemProxyResolver? systemProxyResolver,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _apiKey = apiKey,
       _timeout = timeout ?? const Duration(seconds: 90),
       _proxyRule = proxyRule.trim(),
       _proxyUsername = proxyUsername.trim(),
       _proxyPassword = proxyPassword,
       _systemProxyResolver =
           systemProxyResolver ?? const SystemProxyResolver();

  factory OpenAiLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return OpenAiLlmGateway(
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      timeout: _timeoutFromNetworkSettings(networkSettings),
      proxyRule: _proxyRuleFromNetworkSettings(networkSettings),
      proxyUsername: '${networkSettings['proxy_username'] ?? ''}',
      proxyPassword: '${networkSettings['proxy_password'] ?? ''}',
    );
  }

  final String _baseUrl;
  final String _apiKey;
  final Duration _timeout;
  final String _proxyRule;
  final String _proxyUsername;
  final String _proxyPassword;
  final SystemProxyResolver _systemProxyResolver;

  @override
  Future<JsonMap> requestChat({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 这里负责 OpenAI 兼容多轮消息和工具调用协议的 HTTP 往返，不承接项目上下文规则。
    final requestUri = Uri.parse('$_baseUrl/chat/completions');
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      await _configureProxy(client, requestUri);
      final request = await client.postUrl(requestUri).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      if (_apiKey.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey');
      }
      request.write(
        jsonEncode(_requestPayload(messages, modelId, tools, options)),
      );
      final response = await request.close().timeout(_timeout);
      if (_responseMayStream(response, options)) {
        return await _streamingResponseResult(
          response,
          requestUri,
          onStreamUpdate: onStreamUpdate,
        );
      }
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          '模型请求失败(${response.statusCode}): $body',
          uri: requestUri,
        );
      }
      if (_looksLikeEventStream(body)) {
        return _eventStreamResult(body, onStreamUpdate: onStreamUpdate);
      }
      return _jsonResult(body);
    } finally {
      // 中文注释: HTTP client 生命周期由网关单次请求自行收口，避免 CLI 长时间持有空闲连接。
      client.close(force: true);
    }
  }

  Future<void> _configureProxy(HttpClient client, Uri requestUri) async {
    // 中文注释: 默认优先尊重系统网络环境；若用户在设置里明确填写自定义代理，则以设置为准。
    final proxyRule = _proxyRule.isNotEmpty
        ? _proxyRule
        : (await _systemProxyResolver.resolveFor(requestUri)).trim();
    if (proxyRule.isEmpty || proxyRule.toUpperCase() == 'DIRECT') {
      return;
    }
    client.findProxy = (_) => proxyRule;
    if (_proxyUsername.isEmpty) {
      return;
    }
    client.authenticateProxy = (host, port, scheme, realm) async {
      client.addProxyCredentials(
        host,
        port,
        realm ?? '',
        HttpClientBasicCredentials(_proxyUsername, _proxyPassword),
      );
      return true;
    };
  }

  static Duration _timeoutFromNetworkSettings(JsonMap networkSettings) {
    // 中文注释: 网络超时优先取设置页值，未配置时退回稳定默认值。
    final seconds = int.tryParse(
      '${networkSettings['timeout_seconds'] ?? ''}'.trim(),
    );
    if (seconds == null || seconds <= 0) {
      return const Duration(seconds: 90);
    }
    return Duration(seconds: seconds);
  }

  static String _proxyRuleFromNetworkSettings(JsonMap networkSettings) {
    // 中文注释: 自定义代理只在这里转成 HttpClient 可识别规则，宿主层不需要理解底层格式。
    final mode =
        '${networkSettings['proxy_mode'] ?? 'system'}'.trim().toLowerCase();
    if (mode != 'custom') {
      return '';
    }
    final protocol =
        '${networkSettings['proxy_protocol'] ?? ''}'.trim().toLowerCase();
    final host = '${networkSettings['proxy_host'] ?? ''}'.trim();
    final port = '${networkSettings['proxy_port'] ?? ''}'.trim();
    if (host.isEmpty || port.isEmpty) {
      return '';
    }
    if (protocol == 'socks5') {
      return 'SOCKS $host:$port';
    }
    if (protocol.isEmpty) {
      // 中文注释: UI 允许协议头留空；这里把纯 address:port 输入按通用代理地址解释给 HttpClient。
      return 'PROXY $host:$port';
    }
    return 'PROXY $host:$port';
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

  JsonMap _requestPayload(
    List<JsonMap> messages,
    String modelId,
    List<JsonMap> tools,
    JsonMap options,
  ) {
    // 中文注释: 请求体组装与 HTTP 往返拆开，方便后续继续扩展不同 API 模式。
    final payload = <String, Object?>{
      'model': modelId,
      'messages': _requestMessages(messages, options),
      if (tools.isNotEmpty) 'tools': tools,
      if (options.containsKey('tool_choice'))
        'tool_choice': options['tool_choice'],
    };
    options.forEach((key, value) {
      if (_reservedOptionKeys.contains(key)) {
        return;
      }
      payload[key] = value;
    });
    return payload;
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

  JsonMap _jsonResult(String body) {
    // 中文注释: 常规 JSON 响应继续按原有单包结构解析，保持非流式链路兼容。
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
  }

  bool _looksLikeEventStream(String body) {
    // 中文注释: 有些兼容服务会直接回 SSE 文本，这里按 data: 前缀做轻量识别。
    final trimmed = body.trimLeft();
    return trimmed.startsWith('data:');
  }

  bool _responseMayStream(HttpClientResponse response, JsonMap options) {
    // 中文注释: 对显式 stream 请求和 event-stream content-type 先走增量消费，避免 UI 只能等整包返回。
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  Future<JsonMap> _streamingResponseResult(
    HttpClientResponse response,
    Uri requestUri, {
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 这里按字符流实时消费 SSE，既保留最终统一结果，也把中间增量及时吐给上层 UI。
    final rawBody = StringBuffer();
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCallBuilders = <String, _ToolCallBuilder>{};
    JsonMap lastChunk = const <String, Object?>{};
    var sawStreamEvent = false;
    var reachedDone = false;
    final parser = _SseEventTextParser();
    await for (final chunk in response.transform(utf8.decoder)) {
      rawBody.write(chunk);
      for (final eventData in parser.addChunk(chunk)) {
        sawStreamEvent = true;
        if (eventData == '[DONE]') {
          reachedDone = true;
          continue;
        }
        final decoded = jsonDecode(eventData);
        final root = _mapValue(decoded);
        lastChunk = root;
        final choices = root['choices'];
        if (choices is! List || choices.isEmpty) {
          continue;
        }
        final firstChoice = _mapValue(choices.first);
        final delta = _mapValue(firstChoice['delta']);
        final contentText = _messageText(delta['content']);
        if (contentText.isNotEmpty) {
          contentBuffer.write(contentText);
        }
        final reasoningText = _messageText(
          delta['reasoning_content'] ?? firstChoice['reasoning_content'],
        );
        if (reasoningText.isNotEmpty) {
          reasoningBuffer.write(reasoningText);
        }
        _mergeToolCallDeltas(toolCallBuilders, delta['tool_calls']);
        if (onStreamUpdate != null &&
            (contentText.isNotEmpty ||
                reasoningText.isNotEmpty ||
                delta['tool_calls'] is List)) {
          onStreamUpdate(
            LlmStreamUpdate(
              contentDelta: contentText,
              content: contentBuffer.toString(),
              reasoningDelta: reasoningText,
              reasoningContent: reasoningBuffer.toString(),
              toolCalls: toolCallBuilders.values
                  .map((builder) => builder.build(_mapValue))
                  .toList(growable: false),
            ),
          );
        }
      }
    }
    for (final eventData in parser.close()) {
      sawStreamEvent = true;
      if (eventData == '[DONE]') {
        reachedDone = true;
        continue;
      }
      final decoded = jsonDecode(eventData);
      final root = _mapValue(decoded);
      lastChunk = root;
      final choices = root['choices'];
      if (choices is! List || choices.isEmpty) {
        continue;
      }
      final firstChoice = _mapValue(choices.first);
      final delta = _mapValue(firstChoice['delta']);
      final contentText = _messageText(delta['content']);
      if (contentText.isNotEmpty) {
        contentBuffer.write(contentText);
      }
      final reasoningText = _messageText(
        delta['reasoning_content'] ?? firstChoice['reasoning_content'],
      );
      if (reasoningText.isNotEmpty) {
        reasoningBuffer.write(reasoningText);
      }
      _mergeToolCallDeltas(toolCallBuilders, delta['tool_calls']);
      if (onStreamUpdate != null &&
          (contentText.isNotEmpty ||
              reasoningText.isNotEmpty ||
              delta['tool_calls'] is List)) {
        onStreamUpdate(
          LlmStreamUpdate(
            contentDelta: contentText,
            content: contentBuffer.toString(),
            reasoningDelta: reasoningText,
            reasoningContent: reasoningBuffer.toString(),
            toolCalls: toolCallBuilders.values
                .map((builder) => builder.build(_mapValue))
                .toList(growable: false),
          ),
        );
      }
    }
    final body = rawBody.toString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '模型请求失败(${response.statusCode}): $body',
        uri: requestUri,
      );
    }
    if (!sawStreamEvent && !_looksLikeEventStream(body)) {
      return _jsonResult(body);
    }
    final toolCalls = toolCallBuilders.values
        .map((builder) => builder.build(_mapValue))
        .toList(growable: false);
    final content = contentBuffer.toString();
    final reasoning = reasoningBuffer.toString();
    if (onStreamUpdate != null && (reachedDone || sawStreamEvent)) {
      onStreamUpdate(
        LlmStreamUpdate(
          content: content,
          reasoningContent: reasoning,
          toolCalls: toolCalls,
          isCompleted: true,
        ),
      );
    }
    return <String, Object?>{
      'ok': true,
      'content': content,
      'reasoning_content': reasoning,
      'message': <String, Object?>{
        'role': 'assistant',
        'content': content,
        'tool_calls': toolCalls,
      },
      'tool_calls': toolCalls,
      'raw_response': lastChunk,
    };
  }

  JsonMap _eventStreamResult(
    String body, {
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: SSE 响应在这里聚合为与普通 JSON 一致的返回结构，避免上层再分流式和非流式两套协议。
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCallBuilders = <String, _ToolCallBuilder>{};
    JsonMap lastChunk = const <String, Object?>{};
    for (final eventData in _eventDataLines(body)) {
      if (eventData == '[DONE]') {
        break;
      }
      final decoded = jsonDecode(eventData);
      final root = _mapValue(decoded);
      lastChunk = root;
      final choices = root['choices'];
      if (choices is! List || choices.isEmpty) {
        continue;
      }
      final firstChoice = _mapValue(choices.first);
      final delta = _mapValue(firstChoice['delta']);
      final contentText = _messageText(delta['content']);
      if (contentText.isNotEmpty) {
        contentBuffer.write(contentText);
      }
      final reasoningText = _messageText(
        delta['reasoning_content'] ?? firstChoice['reasoning_content'],
      );
      if (reasoningText.isNotEmpty) {
        reasoningBuffer.write(reasoningText);
      }
      _mergeToolCallDeltas(toolCallBuilders, delta['tool_calls']);
      if (onStreamUpdate != null &&
          (contentText.isNotEmpty ||
              reasoningText.isNotEmpty ||
              delta['tool_calls'] is List)) {
        onStreamUpdate(
          LlmStreamUpdate(
            contentDelta: contentText,
            content: contentBuffer.toString(),
            reasoningDelta: reasoningText,
            reasoningContent: reasoningBuffer.toString(),
            toolCalls: toolCallBuilders.values
                .map((builder) => builder.build(_mapValue))
                .toList(growable: false),
          ),
        );
      }
    }
    final toolCalls = toolCallBuilders.values
        .map((builder) => builder.build(_mapValue))
        .toList(growable: false);
    final content = contentBuffer.toString();
    final reasoning = reasoningBuffer.toString();
    onStreamUpdate?.call(
      LlmStreamUpdate(
        content: content,
        reasoningContent: reasoning,
        toolCalls: toolCalls,
        isCompleted: true,
      ),
    );
    return <String, Object?>{
      'ok': true,
      'content': content,
      'reasoning_content': reasoning,
      'message': <String, Object?>{
        'role': 'assistant',
        'content': content,
        'tool_calls': toolCalls,
      },
      'tool_calls': toolCalls,
      'raw_response': lastChunk,
    };
  }

  Iterable<String> _eventDataLines(String body) sync* {
    // 中文注释: SSE 只取 data 行并自动拼接同一事件的多行数据，其它字段当前忽略。
    final buffer = StringBuffer();
    for (final line in body.split(RegExp(r'\r?\n'))) {
      final trimmedRight = line.trimRight();
      if (trimmedRight.isEmpty) {
        if (buffer.isNotEmpty) {
          yield buffer.toString();
          buffer.clear();
        }
        continue;
      }
      if (!trimmedRight.startsWith('data:')) {
        continue;
      }
      final payload = trimmedRight.substring(5).trimLeft();
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(payload);
    }
    if (buffer.isNotEmpty) {
      yield buffer.toString();
    }
  }

  void _mergeToolCallDeltas(
    Map<String, _ToolCallBuilder> toolCallBuilders,
    Object? value,
  ) {
    // 中文注释: 流式 tool call 会分片返回参数字符串，这里按 index / id 聚合成完整调用。
    if (value is! List) {
      return;
    }
    for (final rawCall in value) {
      final call = _mapValue(rawCall);
      final index = call['index']?.toString() ?? '';
      final callId = _stringValue(call['id']);
      final key = callId.isNotEmpty ? callId : index;
      if (key.isEmpty) {
        continue;
      }
      final builder = toolCallBuilders[key] ??= _ToolCallBuilder(
        id: callId,
        index: index,
      );
      final functionData = _mapValue(call['function']);
      if (callId.isNotEmpty) {
        builder.id = callId;
      }
      final functionName = _stringValue(functionData['name']);
      if (functionName.isNotEmpty) {
        builder.name = functionName;
      }
      final argumentsChunk = _stringValue(functionData['arguments']);
      if (argumentsChunk.isNotEmpty) {
        builder.argumentsBuffer.write(argumentsChunk);
      }
    }
  }

  static const Set<String> _reservedOptionKeys = <String>{
    'prompt',
    'api_mode',
    'tool_choice',
    'stream_scope',
    'sub_session_id',
    'allow_inline_tools',
    'force_tool_choice',
    'preferred_tool',
  };
}

class _ToolCallBuilder {
  _ToolCallBuilder({required this.id, required this.index});

  String id;
  final String index;
  String name = '';
  final StringBuffer argumentsBuffer = StringBuffer();

  JsonMap build(Map<String, Object?> Function(Object? value) mapValue) {
    final rawArguments = argumentsBuffer.toString();
    Object? parsedArguments = rawArguments;
    if (rawArguments.trim().isNotEmpty) {
      try {
        parsedArguments = jsonDecode(rawArguments);
      } catch (_) {
        parsedArguments = <String, Object?>{};
      }
    }
    return <String, Object?>{
      'id': id,
      'name': name,
      'tool_name': name,
      'arguments': mapValue(parsedArguments),
      'raw_arguments': rawArguments,
      'status': 'pending',
    };
  }
}

class _SseEventTextParser {
  final StringBuffer _eventBuffer = StringBuffer();
  String _lineBuffer = '';

  List<String> addChunk(String chunk) {
    final events = <String>[];
    _lineBuffer += chunk;
    while (true) {
      final lineBreakIndex = _lineBuffer.indexOf('\n');
      if (lineBreakIndex < 0) {
        break;
      }
      final rawLine = _lineBuffer.substring(0, lineBreakIndex);
      _lineBuffer = _lineBuffer.substring(lineBreakIndex + 1);
      _consumeLine(rawLine, events);
    }
    return events;
  }

  List<String> close() {
    final events = <String>[];
    if (_lineBuffer.isNotEmpty) {
      _consumeLine(_lineBuffer, events);
      _lineBuffer = '';
    }
    if (_eventBuffer.isNotEmpty) {
      events.add(_eventBuffer.toString());
      _eventBuffer.clear();
    }
    return events;
  }

  void _consumeLine(String line, List<String> events) {
    final normalized = line.endsWith('\r')
        ? line.substring(0, line.length - 1)
        : line;
    if (normalized.isEmpty) {
      if (_eventBuffer.isNotEmpty) {
        events.add(_eventBuffer.toString());
        _eventBuffer.clear();
      }
      return;
    }
    if (!normalized.startsWith('data:')) {
      return;
    }
    final payload = normalized.substring(5).trimLeft();
    if (_eventBuffer.isNotEmpty) {
      _eventBuffer.write('\n');
    }
    _eventBuffer.write(payload);
  }
}
