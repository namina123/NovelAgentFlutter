import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_http_transport.dart';
import 'gateway_json_response_parser.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_tool_call_builder.dart';
import 'gateway_tool_call_fallback_resolver.dart';
import 'gateway_tool_call_response_resolver.dart';
import 'openai_gateway_cancellation_scope.dart';
import 'anthropic_messages_response_parser.dart';

typedef AnthropicRetryRequest =
    Future<JsonMap> Function(
      ChatRequest request, {
      DraftGenerationCancellationToken? cancellationToken,
      void Function(LlmStreamUpdate update)? onStreamUpdate,
    });

class AnthropicMessagesStreamAdapter {
  AnthropicMessagesStreamAdapter({
    GatewaySseEventPump? sseEventPump,
    GatewayJsonResponseParser? responseParser,
    GatewayToolCallFallbackResolver? toolCallFallbackResolver,
  }) : _sseEventPump =
           sseEventPump ?? const GatewaySseEventPump(ignoreEventFields: true),
       _responseParser =
           responseParser ?? const AnthropicMessagesResponseParser(),
       _toolCallFallbackResolver =
           toolCallFallbackResolver ?? const GatewayToolCallFallbackResolver();

  final GatewaySseEventPump _sseEventPump;
  final GatewayJsonResponseParser _responseParser;
  final GatewayToolCallFallbackResolver _toolCallFallbackResolver;

  bool responseMayStream(HttpClientResponse response, JsonMap options) {
    // 中文注释: Anthropic Messages 在显式 stream 或 event-stream content-type 时都应进入增量消费。
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  bool looksLikeEventStream(String body) {
    // 中文注释: Anthropic 的 SSE 仍以 data: / event: 文本承载，先做轻量识别再进入事件归一化。
    final trimmed = body.trimLeft();
    return trimmed.startsWith('event:') || trimmed.startsWith('data:');
  }

  Future<JsonMap> handleResponse({
    required HttpClientResponse response,
    required Uri requestUri,
    required ChatRequest request,
    required DraftGenerationCancellationToken? cancellationToken,
    required void Function(LlmStreamUpdate update)? onStreamUpdate,
    required AnthropicRetryRequest retryRequest,
    required OpenAiGatewayCancellationScope cancellationScope,
  }) async {
    // 中文注释: 这里把 Anthropic Messages 的流式、非流式与重试收口到同一入口，gateway 只负责 transport。
    if (responseMayStream(response, request.options)) {
      final streamed = await parseHttpStream(
        response,
        requestUri,
        cancellationScope: cancellationScope,
        onStreamUpdate: onStreamUpdate,
      );
      if (_shouldRetryAsNonStreaming(request, streamed)) {
        return retryRequest(
          _retryAsNonStreamingRequest(request),
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
    if (looksLikeEventStream(body)) {
      return parseEventStreamBody(
        body,
        cancellationScope: cancellationScope,
        onStreamUpdate: onStreamUpdate,
      );
    }
    final result = _withFallbackToolCalls(_jsonResult(body));
    if (_shouldRetryWithoutSystem(request, result)) {
      return retryRequest(
        _retryWithoutSystemRequest(request),
        cancellationToken: cancellationToken,
        onStreamUpdate: onStreamUpdate,
      );
    }
    if (_shouldRetryWithRequiredToolChoice(request, result)) {
      return retryRequest(
        _retryWithRequiredToolChoiceRequest(request),
        cancellationToken: cancellationToken,
        onStreamUpdate: onStreamUpdate,
      );
    }
    return result;
  }

  Future<JsonMap> parseHttpStream(
    HttpClientResponse response,
    Uri requestUri, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: HTTP 字节流在这里聚合为 Anthropic Messages 的统一响应 envelope。
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
    if (!pumpResult.sawStreamEvent && !looksLikeEventStream(body)) {
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

  JsonMap parseEventStreamBody(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 已经落到字符串的 SSE 同样走同一套消息块聚合逻辑。
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

  JsonMap _jsonResult(String body) {
    // 中文注释: 非流式 JSON 保持 Anthropic Messages 的内容块语义，不借用 OpenAI choices 解析器。
    return _responseParser.parseBody(body);
  }

  bool _consumeEventData(
    String eventData,
    _AnthropicResponseAccumulator aggregate,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
    OpenAiGatewayCancellationScope cancellationScope,
  ) {
    // 中文注释: event data 采用 Anthropic Messages 的 named SSE 事件归一化，逐个合并成统一流式更新。
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
    // 中文注释: 若服务端返回的是原生 tool_use / tool_result 之外的工具片段，这里做一次兼容回收。
    return GatewayToolCallResponseResolver.resolveToolCalls(
      result,
      fallbackParser: _toolCallFallbackResolver.parseFallbackToolCalls,
    );
  }

  bool _shouldRetryAsNonStreaming(ChatRequest request, JsonMap result) {
    // 中文注释: Anthropic 对某些流式工具回合会返回空正文，这时可以回退成非流式补一次。
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

  ChatRequest _retryAsNonStreamingRequest(ChatRequest request) {
    // 中文注释: 重试请求只改变 stream 开关，不引入第二套协议输入结构。
    final retryOptions = ValueReaders.deepCopyMap(request.options)
      ..['stream'] = false;
    return ChatRequest(
      modelId: request.modelId,
      messages: request.messages,
      tools: request.tools,
      options: retryOptions,
      attachments: request.attachments,
      capability: request.capability,
    );
  }

  bool _shouldRetryWithoutSystem(ChatRequest request, JsonMap result) {
    // 中文注释: 没有 tool calls 但 system 可能导致 Anthropic 空回时，保留原有回退策略。
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

  ChatRequest _retryWithoutSystemRequest(ChatRequest request) {
    // 中文注释: 这里把 system 内容折叠进首条 user 消息，保持既有兼容行为。
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
    return ChatRequest(
      modelId: request.modelId,
      messages: mergedMessages,
      tools: request.tools,
      options: request.options,
      attachments: request.attachments,
      capability: request.capability,
    );
  }

  bool _shouldRetryWithRequiredToolChoice(ChatRequest request, JsonMap result) {
    // 中文注释: 工具回合若完全落空，再尝试一次强制 tool_choice，保留原有 Anthropic 兼容兜底。
    if (request.tools.isEmpty) {
      return false;
    }
    final content = ValueReaders.stringValue(result['content']).trim();
    final toolCalls = ValueReaders.objectList(result['tool_calls']);
    return content.isEmpty && toolCalls.isEmpty;
  }

  ChatRequest _retryWithRequiredToolChoiceRequest(ChatRequest request) {
    // 中文注释: 强制工具回合只在请求 options 上加 required 标记，不改变上下文输入形状。
    final retryOptions = ValueReaders.deepCopyMap(request.options)
      ..['stream'] = false
      ..['tool_choice'] = <String, Object?>{'type': 'required'};
    final guidedMessages = _withToolTagFallbackInstruction(
      request.messages,
      request.tools,
    );
    return ChatRequest(
      modelId: request.modelId,
      messages: guidedMessages,
      tools: request.tools,
      options: retryOptions,
      attachments: request.attachments,
      capability: request.capability,
    );
  }

  List<JsonMap> _withToolTagFallbackInstruction(
    List<JsonMap> messages,
    List<JsonMap> tools,
  ) {
    // 中文注释: 当 Anthropic 没有主动产出 tool_use 时，增加一段最小指导语以提高工具触发率。
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

  String _messageText(Object? value) {
    // 中文注释: 复用统一的可读文本抽取，确保回退和 prompt guidance 仍可读。
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
}

class _AnthropicResponseAccumulator {
  final GatewayStreamResultAggregator _streamAggregator =
      GatewayStreamResultAggregator();
  final Map<int, GatewayToolCallBuilder> _toolBuilders =
      <int, GatewayToolCallBuilder>{};

  LlmStreamUpdate? consume(JsonMap event) {
    // 中文注释: Anthropic streaming events 在这里按 event type 逐个落到统一流式状态。
    final type = ValueReaders.stringValue(event['type']);
    switch (type) {
      case 'message_start':
        _streamAggregator.setRawResponse(
          ValueReaders.mapValue(event['message']),
        );
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
          return _streamAggregator.buildStateOnlyUpdate(
            toolCalls: _toolCalls(),
          );
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
