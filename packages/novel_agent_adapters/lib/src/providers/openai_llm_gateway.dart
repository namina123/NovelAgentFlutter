import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_json_response_parser.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_tool_call_builder.dart';
import 'gateway_http_transport.dart';
import 'openai_gateway_cancellation_scope.dart';
import 'openai_chat_request_payload_builder.dart';
import 'system_proxy_resolver.dart';

class OpenAiLlmGateway extends LlmGateway {
  OpenAiLlmGateway({
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

  factory OpenAiLlmGateway.fromProviderSettings(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 通过 provider 设置创建网关可以让 composition root 保持轻量，不把 HTTP 细节带回上层。
    return OpenAiLlmGateway(
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
  final GatewaySseEventPump _sseEventPump = const GatewaySseEventPump();
  final GatewayJsonResponseParser _jsonResponseParser =
      const OpenAiJsonResponseParser();
  final OpenAiChatRequestPayloadBuilder _payloadBuilder =
      const OpenAiChatRequestPayloadBuilder();

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 这里负责 OpenAI 兼容多轮消息和工具调用协议的 HTTP 往返，不承接项目上下文规则。
    final requestUri = Uri.parse('$_baseUrl/chat/completions');
    return _transport.execute<JsonMap>(
      requestUri: requestUri,
      cancellationToken: cancellationToken,
      onCancelled: GatewayHttpTransport.cancelledChatResult,
      shouldRetryTransportError: _shouldRetryTransportError,
      writeRequest: (httpRequest) {
        httpRequest.headers.contentType = ContentType.json;
        if (_apiKey.trim().isNotEmpty) {
          httpRequest.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_apiKey',
          );
        }
        httpRequest.write(jsonEncode(_payloadBuilder.build(request)));
      },
      handleResponse: (response, requestUri, cancellationScope) async {
        if (_responseMayStream(response, request.options)) {
          return await _streamingResponseResult(
            response,
            requestUri,
            cancellationScope: cancellationScope,
            onStreamUpdate: onStreamUpdate,
          );
        }
        final body = await response.transform(utf8.decoder).join();
        if (cancellationScope.isCancellationRequested) {
          return GatewayHttpTransport.cancelledChatResult();
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            '模型请求失败(${response.statusCode}): $body',
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
        return _jsonResult(body);
      },
    );
  }

  static String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，避免后续拼接请求路径时出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
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

  String _messageText(Object? value) {
    // 中文注释: content 既可能是字符串，也可能是 content part 数组，这里统一抽成可读正文。
    return GatewayContentExtractor.textFromContent(value);
  }

  String _stringValue(Object? value) {
    // 中文注释: 文本提取在网关内部完成，避免把响应结构知识扩散到上层。
    return value == null ? '' : value.toString();
  }

  JsonMap _jsonResult(String body) {
    // 中文注释: 常规 JSON 响应继续按原有单包结构解析，保持非流式链路兼容。
    return _jsonResponseParser.parseBody(body);
  }

  bool _shouldRetryTransportError(Object error) {
    // 中文注释: 这里只对典型瞬时传输层故障做自动重试，避免把明确的业务错误误当成网络抖动。
    if (error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }
    final message = '$error'.toLowerCase();
    if (message.contains('connection closed before full header')) {
      return true;
    }
    if (message.contains('connection reset') ||
        message.contains('connection terminated') ||
        message.contains('broken pipe')) {
      return true;
    }
    if (message.contains('流式响应在完成前被中断')) {
      return true;
    }
    return message.contains('模型请求失败(502)') ||
        message.contains('模型请求失败(503)') ||
        message.contains('模型请求失败(504)') ||
        message.contains('模型请求失败(520)') ||
        message.contains('模型请求失败(522)') ||
        message.contains('模型请求失败(524)');
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
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 这里按字符流实时消费 SSE，既保留最终统一结果，也把中间增量及时吐给上层 UI。
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCallBuilders = <String, GatewayToolCallBuilder>{};
    final streamAggregator = GatewayStreamResultAggregator();
    final pumpResult = await _sseEventPump.pumpResponse(
      response,
      cancellationScope: cancellationScope,
      onEventData: (eventData) => _consumeStreamingEvent(
        eventData,
        contentBuffer: contentBuffer,
        reasoningBuffer: reasoningBuffer,
        toolCallBuilders: toolCallBuilders,
        onStreamUpdate: onStreamUpdate,
        cancellationScope: cancellationScope,
        streamAggregator: streamAggregator,
      ),
    );
    final body = pumpResult.rawBody;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '模型请求失败(${response.statusCode}): $body',
        uri: requestUri,
      );
    }
    if (!pumpResult.sawStreamEvent && !_looksLikeEventStream(body)) {
      return _jsonResult(body);
    }
    if (pumpResult.sawStreamEvent &&
        !pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw HttpException('流式响应在完成前被中断。', uri: requestUri);
    }
    final toolCalls = toolCallBuilders.values
        .map((builder) => builder.build(_mapValue))
        .toList(growable: false);
    final snapshot = streamAggregator.snapshot(toolCalls: toolCalls);
    if (onStreamUpdate != null &&
        !cancellationScope.isCancellationRequested &&
        (pumpResult.reachedTerminalEvent || pumpResult.sawStreamEvent)) {
      onStreamUpdate(snapshot.toCompletedUpdate());
    }
    return snapshot.toResult();
  }

  JsonMap _eventStreamResult(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: SSE 响应在这里聚合为与普通 JSON 一致的返回结构，避免上层再分流式和非流式两套协议。
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCallBuilders = <String, GatewayToolCallBuilder>{};
    final streamAggregator = GatewayStreamResultAggregator();
    final pumpResult = _sseEventPump.pumpBody(
      body,
      onEventData: (eventData) => _consumeStreamingEvent(
        eventData,
        contentBuffer: contentBuffer,
        reasoningBuffer: reasoningBuffer,
        toolCallBuilders: toolCallBuilders,
        onStreamUpdate: onStreamUpdate,
        cancellationScope: cancellationScope,
        streamAggregator: streamAggregator,
      ),
    );
    final toolCalls = toolCallBuilders.values
        .map((builder) => builder.build(_mapValue))
        .toList(growable: false);
    final snapshot = streamAggregator.snapshot(toolCalls: toolCalls);
    if (!pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw const HttpException('流式响应在完成前被中断。');
    }
    if (!cancellationScope.isCancellationRequested) {
      onStreamUpdate?.call(snapshot.toCompletedUpdate());
    }
    return snapshot.toResult();
  }

  bool _consumeStreamingEvent(
    String eventData, {
    required StringBuffer contentBuffer,
    required StringBuffer reasoningBuffer,
    required Map<String, GatewayToolCallBuilder> toolCallBuilders,
    required GatewayStreamResultAggregator streamAggregator,
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    if (eventData == '[DONE]') {
      return true;
    }
    final root = decodeJsonMapFromString(eventData);
    streamAggregator.setRawResponse(root);
    final choices = root['choices'];
    if (choices is! List || choices.isEmpty) {
      return false;
    }
    final firstChoice = _mapValue(choices.first);
    final delta = _mapValue(firstChoice['delta']);
    final contentText = _messageText(delta['content']);
    if (contentText.isNotEmpty) {
      contentBuffer.write(contentText);
      streamAggregator.appendContent(contentText);
    }
    final reasoningText = _messageText(
      delta['reasoning_content'] ?? firstChoice['reasoning_content'],
    );
    if (reasoningText.isNotEmpty) {
      reasoningBuffer.write(reasoningText);
      streamAggregator.appendReasoning(reasoningText);
    }
    _mergeToolCallDeltas(toolCallBuilders, delta['tool_calls']);
    if (onStreamUpdate != null &&
        !cancellationScope.isCancellationRequested &&
        (contentText.isNotEmpty ||
            reasoningText.isNotEmpty ||
            delta['tool_calls'] is List)) {
      final toolCalls = toolCallBuilders.values
          .map((builder) => builder.build(_mapValue))
          .toList(growable: false);
      onStreamUpdate(
        streamAggregator.buildDeltaUpdate(
          contentDelta: contentText,
          reasoningDelta: reasoningText,
          toolCalls: toolCalls,
        ),
      );
    }
    return false;
  }

  void _mergeToolCallDeltas(
    Map<String, GatewayToolCallBuilder> toolCallBuilders,
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
      final key = _toolCallBuilderKey(
        toolCallBuilders,
        callId: callId,
        index: index,
      );
      if (key.isEmpty) {
        continue;
      }
      final builder = toolCallBuilders[key] ??= GatewayToolCallBuilder(
        id: callId,
        name: '',
      );
      final functionData = _mapValue(call['function']);
      builder.setId(callId);
      builder.setName(_stringValue(functionData['name']));
      final argumentsChunk = _stringValue(functionData['arguments']);
      if (argumentsChunk.isNotEmpty) {
        builder.appendPartialArguments(argumentsChunk);
      }
    }
  }

  String _toolCallBuilderKey(
    Map<String, GatewayToolCallBuilder> toolCallBuilders, {
    required String callId,
    required String index,
  }) {
    // 中文注释: 兼容流式首包带 id、后续包只带 index 的情况，确保同一工具调用不会被拆成两条残缺记录。
    if (index.isNotEmpty && toolCallBuilders.containsKey(index)) {
      return index;
    }
    if (callId.isNotEmpty) {
      for (final entry in toolCallBuilders.entries) {
        if (entry.value.id == callId) {
          return entry.key;
        }
      }
    }
    if (index.isNotEmpty) {
      return index;
    }
    return callId;
  }
}

