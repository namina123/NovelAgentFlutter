import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_json_response_parser.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_tool_call_builder.dart';
import 'gateway_tool_call_fallback_resolver.dart';
import 'gateway_tool_call_response_resolver.dart';
import 'gateway_http_transport.dart';
import 'openai_gateway_cancellation_scope.dart';
import 'system_proxy_resolver.dart';

class AnthropicLlmGateway extends LlmGateway {
  AnthropicLlmGateway({
    required String baseUrl,
    required String apiKey,
    Duration? timeout,
    String proxyRule = '',
    String proxyUsername = '',
    String proxyPassword = '',
    bool transportRetryEnabled = true,
    int transportRetryAttempts = 2,
    SystemProxyResolver? systemProxyResolver,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _apiKey = apiKey,
       _transport = GatewayHttpTransport(
         timeout: timeout ?? const Duration(seconds: 90),
         proxyRule: proxyRule.trim(),
         proxyUsername: proxyUsername.trim(),
         proxyPassword: proxyPassword,
         transportRetryEnabled: transportRetryEnabled,
         transportRetryAttempts: transportRetryAttempts.clamp(0, 5),
         systemProxyResolver: systemProxyResolver ?? const SystemProxyResolver(),
       );

  factory AnthropicLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    return AnthropicLlmGateway(
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      timeout: GatewayNetworkSettings.timeoutFromNetworkSettings(
        networkSettings,
      ),
      proxyRule: GatewayNetworkSettings.proxyRuleFromNetworkSettings(
        networkSettings,
      ),
      proxyUsername: '${networkSettings['proxy_username'] ?? ''}',
      proxyPassword: '${networkSettings['proxy_password'] ?? ''}',
      transportRetryEnabled:
          GatewayNetworkSettings.transportRetryEnabledFromNetworkSettings(
        networkSettings,
      ),
      transportRetryAttempts:
          GatewayNetworkSettings.transportRetryAttemptsFromNetworkSettings(
        networkSettings,
      ),
    );
  }

  final String _baseUrl;
  final String _apiKey;
  final GatewayHttpTransport _transport;
  final GatewaySseEventPump _sseEventPump = const GatewaySseEventPump(
    ignoreEventFields: true,
  );
  final GatewayJsonResponseParser _jsonResponseParser =
      const AnthropicJsonResponseParser();
  final GatewayToolCallFallbackResolver _toolCallFallbackResolver =
      const GatewayToolCallFallbackResolver();

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    final requestUri = Uri.parse('$_baseUrl/messages');
    return _transport.execute<JsonMap>(
      requestUri: requestUri,
      cancellationToken: cancellationToken,
      onCancelled: GatewayHttpTransport.cancelledChatResult,
      shouldRetryTransportError: _shouldRetryTransportError,
      writeRequest: (httpRequest) {
        httpRequest.headers.contentType = ContentType.json;
        if (_apiKey.trim().isNotEmpty) {
          httpRequest.headers.set('x-api-key', _apiKey);
        }
        httpRequest.headers.set('anthropic-version', '2023-06-01');
        if (request.options['stream'] == true) {
          httpRequest.headers.set(
            HttpHeaders.acceptHeader,
            'text/event-stream',
          );
        }
        httpRequest.write(jsonEncode(_buildPayload(request)));
      },
      handleResponse: (response, requestUri, cancellationScope) async {
        if (_responseMayStream(response, request.options)) {
          final streamed = await _streamingResponseResult(
            response,
            requestUri,
            request: request,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
          if (_shouldRetryAsNonStreaming(request, streamed)) {
            return _retryAsNonStreaming(
              request,
              cancellationToken: cancellationToken,
              onStreamUpdate: onStreamUpdate,
            );
          }
          return streamed;
        }
        final body = await response.transform(utf8.decoder).join();
        if (cancellationScope.isCancellationRequested) {
          return GatewayHttpTransport.cancelledChatResult();
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Anthropic 模型请求失败(${response.statusCode}): $body',
            uri: requestUri,
          );
        }
        if (_looksLikeEventStream(body)) {
          return _eventStreamResult(
            body,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
        }
        final result = _withFallbackToolCalls(_jsonResult(body));
        if (_shouldRetryWithoutSystem(request, result)) {
          return _retryWithoutSystem(
            request,
            cancellationToken: cancellationToken,
            onStreamUpdate: onStreamUpdate,
          );
        }
        if (_shouldRetryWithRequiredToolChoice(request, result)) {
          return _retryWithRequiredToolChoice(
            request,
            cancellationToken: cancellationToken,
            onStreamUpdate: onStreamUpdate,
          );
        }
        return result;
      },
    );
  }

  JsonMap _buildPayload(ChatRequest request) {
    final options = ValueReaders.deepCopyMap(request.options);
    final messages = _requestMessages(request.messages);
    final payload = <String, Object?>{
      'model': request.modelId,
      'messages': messages,
      'max_tokens': ValueReaders.intValue(options.remove('max_tokens'), 4096),
      if (request.tools.isNotEmpty) 'tools': _requestTools(request.tools),
    };
    final systemPrompt = _systemPromptOf(request.messages);
    if (systemPrompt.isNotEmpty) {
      payload['system'] = systemPrompt;
    }
    _copyIfPresent(options, payload, 'temperature');
    _copyIfPresent(options, payload, 'top_p');
    _copyIfPresent(options, payload, 'top_k');
    _copyIfPresent(options, payload, 'stop_sequences');
    _copyIfPresent(options, payload, 'metadata');
    _copyIfPresent(options, payload, 'tool_choice');
    _copyIfPresent(options, payload, 'thinking');
    _copyIfPresent(options, payload, 'reasoning_effort');
    if (ValueReaders.boolValue(options['stream'])) {
      payload['stream'] = true;
    }
    return payload;
  }

  List<JsonMap> _requestMessages(List<JsonMap> source) {
    final result = <JsonMap>[];
    for (final rawMessage in source) {
      final message = ValueReaders.mapValue(rawMessage);
      final role = ValueReaders.stringValue(message['role']);
      if (role == 'system') {
        continue;
      }
      if (role == 'tool') {
        result.add(_toolResultMessage(message));
        continue;
      }
      if (role == 'assistant' &&
          ValueReaders.objectList(message['tool_calls']).isNotEmpty) {
        result.add(_assistantToolUseMessage(message));
        continue;
      }
      result.add(<String, Object?>{
        'role': role == 'assistant' ? 'assistant' : 'user',
        'content': _contentBlocksFromMessage(message),
      });
    }
    return result;
  }

  JsonMap _assistantToolUseMessage(JsonMap message) {
    final blocks = <Object?>[];
    final text = _messageText(message['content']);
    if (text.isNotEmpty) {
      blocks.add(<String, Object?>{'type': 'text', 'text': text});
    }
    for (final rawToolCall in ValueReaders.objectList(message['tool_calls'])) {
      final call = ValueReaders.mapValue(rawToolCall);
      blocks.add(<String, Object?>{
        'type': 'tool_use',
        'id': ValueReaders.stringValue(call['id']),
        'name': ValueReaders.stringValue(
          call['name'],
          ValueReaders.stringValue(call['tool_name']),
        ),
        'input': ValueReaders.mapValue(call['arguments']),
      });
    }
    return <String, Object?>{'role': 'assistant', 'content': blocks};
  }

  JsonMap _toolResultMessage(JsonMap message) {
    final toolCallId = ValueReaders.stringValue(message['tool_call_id']);
    final text = _messageText(message['content']);
    return <String, Object?>{
      'role': 'user',
      'content': <Object?>[
        <String, Object?>{
          'type': 'tool_result',
          'tool_use_id': toolCallId,
          'content': text,
        },
      ],
    };
  }

  List<Object?> _contentBlocksFromMessage(JsonMap message) {
    final content = message['content'];
    if (content is List) {
      return content
          .map<Object?>((part) {
            final partMap = ValueReaders.mapValue(part);
            final type = ValueReaders.stringValue(partMap['type'], 'text');
            if (type == 'text') {
              return <String, Object?>{
                'type': 'text',
                'text': ValueReaders.stringValue(partMap['text']),
              };
            }
            return partMap;
          })
          .toList(growable: false);
    }
    final text = _messageText(content);
    return <Object?>[
      <String, Object?>{'type': 'text', 'text': text},
    ];
  }

  String _systemPromptOf(List<JsonMap> source) {
    final buffer = StringBuffer();
    for (final rawMessage in source) {
      final message = ValueReaders.mapValue(rawMessage);
      if (ValueReaders.stringValue(message['role']) != 'system') {
        continue;
      }
      final text = _messageText(message['content']);
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

  List<JsonMap> _requestTools(List<JsonMap> source) {
    return source
        .map((rawTool) {
          final tool = ValueReaders.mapValue(rawTool);
          final function = ValueReaders.mapValue(tool['function']);
          return <String, Object?>{
            'type': 'function',
            'function': <String, Object?>{
              'name': ValueReaders.stringValue(
                function['name'],
                ValueReaders.stringValue(tool['name']),
              ),
              'description': ValueReaders.stringValue(
                function['description'],
                ValueReaders.stringValue(tool['description']),
              ),
              'parameters': ValueReaders.mapValue(
                function['parameters'] ?? tool['input_schema'],
              ),
            },
          };
        })
        .toList(growable: false);
  }

  JsonMap _jsonResult(String body) {
    return _jsonResponseParser.parseBody(body);
  }

  Future<JsonMap> _streamingResponseResult(
    HttpClientResponse response,
    Uri requestUri, {
    required ChatRequest request,
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    final aggregate = _AnthropicResponseAccumulator();
    final pumpResult = await _sseEventPump.pumpResponse(
      response,
      cancellationScope: cancellationScope,
      onEventData: (eventData) => _consumeEventData(
        eventData,
        aggregate,
        onStreamUpdate,
        cancellationScope,
      ),
    );
    final body = pumpResult.rawBody;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Anthropic 模型请求失败(${response.statusCode}): $body',
        uri: requestUri,
      );
    }
    if (!pumpResult.sawStreamEvent && !_looksLikeEventStream(body)) {
      return _withFallbackToolCalls(_jsonResult(body));
    }
    if (pumpResult.sawStreamEvent &&
        !pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw HttpException('Anthropic 流式响应在完成前被中断。', uri: requestUri);
    }
    final snapshot = aggregate.snapshot();
    if (onStreamUpdate != null && !cancellationScope.isCancellationRequested) {
      onStreamUpdate(snapshot.toCompletedUpdate());
    }
    return _withFallbackToolCalls(snapshot.toResult());
  }

  JsonMap _eventStreamResult(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    final aggregate = _AnthropicResponseAccumulator();
    final pumpResult = _sseEventPump.pumpBody(
      body,
      onEventData: (eventData) => _consumeEventData(
        eventData,
        aggregate,
        onStreamUpdate,
        cancellationScope,
      ),
    );
    if (!pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw const HttpException('Anthropic 流式响应在完成前被中断。');
    }
    final snapshot = aggregate.snapshot();
    if (!cancellationScope.isCancellationRequested) {
      onStreamUpdate?.call(snapshot.toCompletedUpdate());
    }
    return _withFallbackToolCalls(snapshot.toResult());
  }

  bool _consumeEventData(
    String eventData,
    _AnthropicResponseAccumulator aggregate,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
    OpenAiGatewayCancellationScope cancellationScope,
  ) {
    if (eventData == '[DONE]') {
      return true;
    }
    final root = ValueReaders.mapValue(jsonDecode(eventData));
    final eventType = ValueReaders.stringValue(root['type']);
    final update = aggregate.consume(root);
    if (update != null &&
        onStreamUpdate != null &&
        !cancellationScope.isCancellationRequested) {
      onStreamUpdate(update);
    }
    return eventType == 'message_stop';
  }

  JsonMap _withFallbackToolCalls(JsonMap result) {
    return GatewayToolCallResponseResolver.resolveToolCalls(
      result,
      fallbackParser: _toolCallFallbackResolver.parseFallbackToolCalls,
    );
  }

  bool _shouldRetryAsNonStreaming(ChatRequest request, JsonMap result) {
    if (!ValueReaders.boolValue(request.options['stream'])) {
      return false;
    }
    if (request.tools.isEmpty) {
      return false;
    }
    final content = ValueReaders.stringValue(result['content']).trim();
    final toolCalls = ValueReaders.objectList(result['tool_calls']);
    return content.isEmpty && toolCalls.isEmpty;
  }

  Future<JsonMap> _retryAsNonStreaming(
    ChatRequest request, {
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    final retryOptions = ValueReaders.deepCopyMap(request.options)
      ..['stream'] = false;
    final retriedRequest = ChatRequest(
      modelId: request.modelId,
      messages: request.messages,
      tools: request.tools,
      options: retryOptions,
      attachments: request.attachments,
      capability: request.capability,
    );
    final result = await requestChat(
      request: retriedRequest,
      cancellationToken: cancellationToken,
    );
    if (onStreamUpdate != null) {
      onStreamUpdate(
        LlmStreamUpdate(
          content: ValueReaders.stringValue(result['content']),
          reasoningContent: ValueReaders.stringValue(
            result['reasoning_content'],
          ),
          toolCalls: ValueReaders.mapList(result['tool_calls']),
          isCompleted: true,
        ),
      );
    }
    return result;
  }

  bool _shouldRetryWithoutSystem(ChatRequest request, JsonMap result) {
    if (request.tools.isNotEmpty) {
      return false;
    }
    final hasSystem = request.messages.any(
      (message) => ValueReaders.stringValue(message['role']) == 'system',
    );
    if (!hasSystem) {
      return false;
    }
    final content = ValueReaders.stringValue(result['content']).trim();
    final toolCalls = ValueReaders.objectList(result['tool_calls']);
    return content.isEmpty && toolCalls.isEmpty;
  }

  Future<JsonMap> _retryWithoutSystem(
    ChatRequest request, {
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    final mergedMessages = <JsonMap>[];
    final systemParts = <String>[];
    for (final message in request.messages) {
      final role = ValueReaders.stringValue(message['role']);
      if (role == 'system') {
        final text = _messageText(message['content']).trim();
        if (text.isNotEmpty) {
          systemParts.add(text);
        }
        continue;
      }
      mergedMessages.add(ValueReaders.deepCopyMap(message));
    }
    if (systemParts.isNotEmpty && mergedMessages.isNotEmpty) {
      final first = ValueReaders.deepCopyMap(mergedMessages.first);
      final content = _messageText(first['content']).trim();
      first['content'] = '${systemParts.join('\n')}\n\n$content'.trim();
      mergedMessages[0] = first;
    }
    final retriedRequest = ChatRequest(
      modelId: request.modelId,
      messages: mergedMessages,
      tools: request.tools,
      options: request.options,
      attachments: request.attachments,
      capability: request.capability,
    );
    final result = await requestChat(
      request: retriedRequest,
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
    return result;
  }

  bool _shouldRetryWithRequiredToolChoice(ChatRequest request, JsonMap result) {
    if (request.tools.isEmpty) {
      return false;
    }
    final content = ValueReaders.stringValue(result['content']).trim();
    final toolCalls = ValueReaders.objectList(result['tool_calls']);
    return content.isEmpty && toolCalls.isEmpty;
  }

  Future<JsonMap> _retryWithRequiredToolChoice(
    ChatRequest request, {
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    final retryOptions = ValueReaders.deepCopyMap(request.options)
      ..['stream'] = false
      ..['tool_choice'] = <String, Object?>{'type': 'required'};
    final guidedMessages = _withToolTagFallbackInstruction(
      request.messages,
      request.tools,
    );
    final retriedRequest = ChatRequest(
      modelId: request.modelId,
      messages: guidedMessages,
      tools: request.tools,
      options: retryOptions,
      attachments: request.attachments,
      capability: request.capability,
    );
    final result = await requestChat(
      request: retriedRequest,
      cancellationToken: cancellationToken,
    );
    if (onStreamUpdate != null) {
      onStreamUpdate(
        LlmStreamUpdate(
          content: ValueReaders.stringValue(result['content']),
          reasoningContent: ValueReaders.stringValue(
            result['reasoning_content'],
          ),
          toolCalls: ValueReaders.mapList(result['tool_calls']),
          isCompleted: true,
        ),
      );
    }
    return result;
  }

  List<JsonMap> _withToolTagFallbackInstruction(
    List<JsonMap> messages,
    List<JsonMap> tools,
  ) {
    if (messages.isEmpty || tools.isEmpty) {
      return messages;
    }
    final toolNames = tools
        .map((tool) {
          final map = ValueReaders.mapValue(tool);
          final function = ValueReaders.mapValue(map['function']);
          return ValueReaders.stringValue(
            function['name'],
            ValueReaders.stringValue(map['name']),
          ).trim();
        })
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (toolNames.isEmpty) {
      return messages;
    }
    final guidance = StringBuffer()
      ..writeln()
      ..writeln()
      ..writeln('Tool output rule:')
      ..writeln('- Do not write code.')
      ..writeln('- Do not describe the tool.')
      ..writeln(
        '- If you need a tool, reply with exactly one XML tag and nothing else.',
      )
      ..writeln(
        '- Format: <tool_call>{"name":"${toolNames.first}","arguments":{...}}</tool_call>',
      )
      ..writeln('- Allowed tool names: ${toolNames.join(', ')}');
    final result = messages
        .map(ValueReaders.deepCopyMap)
        .toList(growable: true);
    for (var index = result.length - 1; index >= 0; index -= 1) {
      final message = ValueReaders.deepCopyMap(result[index]);
      final role = ValueReaders.stringValue(message['role']).trim();
      if (role != 'user') {
        continue;
      }
      final content = _messageText(message['content']).trim();
      message['content'] = content.isEmpty
          ? guidance.toString().trim()
          : '$content${guidance.toString()}';
      result[index] = message;
      return result;
    }
    final first = ValueReaders.deepCopyMap(result.first);
    final content = _messageText(first['content']).trim();
    first['content'] = content.isEmpty
        ? guidance.toString().trim()
        : '$content${guidance.toString()}';
    result[0] = first;
    return result;
  }

  bool _responseMayStream(HttpClientResponse response, JsonMap options) {
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  bool _looksLikeEventStream(String body) {
    return body.trimLeft().startsWith('event:') ||
        body.trimLeft().startsWith('data:');
  }

  void _copyIfPresent(JsonMap source, JsonMap target, String key) {
    if (!source.containsKey(key)) {
      return;
    }
    final value = source[key];
    if (value == null) {
      return;
    }
    target[key] = value;
  }

  String _messageText(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final rawPart in value) {
        final part = ValueReaders.mapValue(rawPart);
        final type = ValueReaders.stringValue(part['type'], 'text');
        if (type == 'text') {
          final text = ValueReaders.stringValue(part['text']);
          if (text.isEmpty) {
            continue;
          }
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
          continue;
        }
        if (type == 'tool_result') {
          final text = ValueReaders.stringValue(part['content']);
          if (text.isEmpty) {
            continue;
          }
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
        }
      }
      return buffer.toString();
    }
    return ValueReaders.stringValue(value);
  }

  bool _shouldRetryTransportError(Object error) {
    if (error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }
    final message = '$error'.toLowerCase();
    return message.contains('502') ||
        message.contains('503') ||
        message.contains('504') ||
        message.contains('520') ||
        message.contains('522') ||
        message.contains('524') ||
        message.contains('connection reset') ||
        message.contains('broken pipe') ||
        message.contains('中断');
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

class _AnthropicResponseAccumulator {
  final GatewayStreamResultAggregator _streamAggregator =
      GatewayStreamResultAggregator();
  final Map<int, GatewayToolCallBuilder> _toolBuilders =
      <int, GatewayToolCallBuilder>{};

  LlmStreamUpdate? consume(JsonMap event) {
    final type = ValueReaders.stringValue(event['type']);
    switch (type) {
      case 'message_start':
        _streamAggregator.setRawResponse(ValueReaders.mapValue(event['message']));
        return null;
      case 'content_block_start':
        final index = ValueReaders.intValue(event['index'], -1);
        final block = ValueReaders.mapValue(event['content_block']);
        final blockType = ValueReaders.stringValue(block['type']);
        if (blockType == 'tool_use' && index >= 0) {
          final builder = GatewayToolCallBuilder(
            id: ValueReaders.stringValue(block['id']),
            name: ValueReaders.stringValue(block['name']),
          );
          builder.setFallbackInput(ValueReaders.mapValue(block['input']));
          _toolBuilders[index] = builder;
        }
        if (blockType == 'text') {
          final text = ValueReaders.stringValue(block['text']);
          if (text.isNotEmpty) {
            _streamAggregator.appendContent(text);
            return _streamAggregator.buildDeltaUpdate(
              contentDelta: text,
              reasoningDelta: '',
              toolCalls: _toolCalls(),
            );
          }
        }
        if (blockType == 'thinking' || blockType == 'reasoning') {
          final text = ValueReaders.stringValue(
            block['thinking'],
            ValueReaders.stringValue(block['text']),
          );
          if (text.isNotEmpty) {
            _streamAggregator.appendReasoning(text);
            return _streamAggregator.buildDeltaUpdate(
              contentDelta: '',
              reasoningDelta: text,
              toolCalls: _toolCalls(),
            );
          }
        }
        return null;
      case 'content_block_delta':
        final index = ValueReaders.intValue(event['index'], -1);
        final delta = ValueReaders.mapValue(event['delta']);
        final deltaType = ValueReaders.stringValue(delta['type']);
        if (deltaType == 'text_delta') {
          final text = ValueReaders.stringValue(delta['text']);
          if (text.isEmpty) {
            return null;
          }
          _streamAggregator.appendContent(text);
          return _streamAggregator.buildDeltaUpdate(
            contentDelta: text,
            reasoningDelta: '',
            toolCalls: _toolCalls(),
          );
        }
        if (deltaType == 'thinking_delta' || deltaType == 'reasoning_delta') {
          final text = ValueReaders.stringValue(
            delta['thinking'],
            ValueReaders.stringValue(delta['text']),
          );
          if (text.isEmpty) {
            return null;
          }
          _streamAggregator.appendReasoning(text);
          return _streamAggregator.buildDeltaUpdate(
            contentDelta: '',
            reasoningDelta: text,
            toolCalls: _toolCalls(),
          );
        }
        if (deltaType == 'input_json_delta' && index >= 0) {
          final builder = _toolBuilders[index];
          if (builder == null) {
            return null;
          }
          builder.appendPartialJson(
            ValueReaders.stringValue(delta['partial_json']),
          );
          return _streamAggregator.buildStateOnlyUpdate(toolCalls: _toolCalls());
        }
        return null;
      case 'content_block_stop':
      case 'message_delta':
      case 'message_stop':
      default:
        return null;
    }
  }

  GatewayStreamResultSnapshot snapshot() {
    return _streamAggregator.snapshot(toolCalls: _toolCalls());
  }

  List<JsonMap> _toolCalls() {
    return _toolBuilders.values
        .map((builder) => builder.build(ValueReaders.mapValue))
        .toList(growable: false);
  }
}
