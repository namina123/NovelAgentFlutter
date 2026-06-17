import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_tool_call_builder.dart';
import 'gateway_json_response_parser.dart';
import 'openai_chat_response_parser.dart';
import 'openai_gateway_cancellation_scope.dart';

class OpenAiChatStreamAdapter {
  OpenAiChatStreamAdapter({
    GatewaySseEventPump? sseEventPump,
    GatewayJsonResponseParser? responseParser,
  }) : _sseEventPump = sseEventPump ?? const GatewaySseEventPump(),
       _responseParser =
           responseParser ?? const OpenAiChatResponseParser();

  final GatewaySseEventPump _sseEventPump;
  final GatewayJsonResponseParser _responseParser;

  bool responseMayStream(HttpClientResponse response, JsonMap options) {
    // 中文注释: 显式 stream 或 event-stream 响应都走增量消费，保持 OpenAI Chat 的现有行为。
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  bool looksLikeEventStream(String body) {
    // 中文注释: 这里仅识别 data: 前缀，不提前引入 Responses 的事件模型。
    return body.trimLeft().startsWith('data:');
  }

  Future<JsonMap> parseHttpStream(
    HttpClientResponse response,
    Uri requestUri, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: HTTP 字节流在这里聚合成统一 envelope，外层只拿最终结果即可。
    final toolCallBuilders = <String, GatewayToolCallBuilder>{};
    final streamAggregator = GatewayStreamResultAggregator();
    final pumpResult = await _sseEventPump.pumpResponse(
      response,
      cancellationScope: cancellationScope,
      onEventData: (eventData) => _consumeStreamingEvent(
        eventData,
        toolCallBuilders: toolCallBuilders,
        streamAggregator: streamAggregator,
        cancellationScope: cancellationScope,
        onStreamUpdate: onStreamUpdate,
      ),
    );
    final body = pumpResult.rawBody;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        '模型请求失败(${response.statusCode}): $body',
        uri: requestUri,
      );
    }
    if (!pumpResult.sawStreamEvent && !looksLikeEventStream(body)) {
      return _responseParser.parseBody(body);
    }
    if (pumpResult.sawStreamEvent &&
        !pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw HttpException('流式响应在完成前被中断。', uri: requestUri);
    }
    return _finalizeStreamResult(
      streamAggregator,
      toolCallBuilders,
      cancellationScope: cancellationScope,
      onStreamUpdate: onStreamUpdate,
    );
  }

  JsonMap parseEventStreamBody(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 已经落到字符串的 SSE 同样走同一聚合逻辑，避免和 HTTP 分支分裂。
    final toolCallBuilders = <String, GatewayToolCallBuilder>{};
    final streamAggregator = GatewayStreamResultAggregator();
    final pumpResult = _sseEventPump.pumpBody(
      body,
      onEventData: (eventData) => _consumeStreamingEvent(
        eventData,
        toolCallBuilders: toolCallBuilders,
        streamAggregator: streamAggregator,
        cancellationScope: cancellationScope,
        onStreamUpdate: onStreamUpdate,
      ),
    );
    if (!pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw const HttpException('流式响应在完成前被中断。');
    }
    return _finalizeStreamResult(
      streamAggregator,
      toolCallBuilders,
      cancellationScope: cancellationScope,
      onStreamUpdate: onStreamUpdate,
    );
  }

  JsonMap _finalizeStreamResult(
    GatewayStreamResultAggregator streamAggregator,
    Map<String, GatewayToolCallBuilder> toolCallBuilders, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 聚合结束后统一产出 envelope 与 completed update，保持上层消费面稳定。
    final toolCalls = toolCallBuilders.values
        .map((builder) => builder.build(_mapValue))
        .toList(growable: false);
    final snapshot = streamAggregator.snapshot(toolCalls: toolCalls);
    if (!cancellationScope.isCancellationRequested) {
      onStreamUpdate?.call(snapshot.toCompletedUpdate());
    }
    return snapshot.toResult();
  }

  bool _consumeStreamingEvent(
    String eventData, {
    required Map<String, GatewayToolCallBuilder> toolCallBuilders,
    required GatewayStreamResultAggregator streamAggregator,
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 这里按 OpenAI Chat delta 语义合并 content、reasoning 和 tool call 分片。
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
    final contentText = GatewayContentExtractor.textFromContent(delta['content']);
    if (contentText.isNotEmpty) {
      streamAggregator.appendContent(contentText);
    }
    final reasoningText = GatewayContentExtractor.textFromContent(
      delta['reasoning_content'] ?? firstChoice['reasoning_content'],
    );
    if (reasoningText.isNotEmpty) {
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
    // 中文注释: 流式 tool call 参数会分片返回，这里按 id / index 聚合成完整调用。
    if (value is! List) {
      return;
    }
    for (final rawCall in value) {
      final call = _mapValue(rawCall);
      final index = call['index']?.toString() ?? '';
      final callId = ValueReaders.stringValue(call['id']);
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
      builder.setName(ValueReaders.stringValue(functionData['name']));
      final argumentsChunk = ValueReaders.stringValue(functionData['arguments']);
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
    // 中文注释: 首包可能只带 id，后续只带 index，这里按两种标识收敛到同一条工具调用。
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

  Map<String, Object?> _mapValue(Object? value) {
    // 中文注释: 流式响应是动态 JSON，统一收成字符串键字典后再进入工具调用聚合。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, Object?>{};
  }
}
