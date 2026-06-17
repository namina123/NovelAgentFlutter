import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_http_transport.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_tool_call_builder.dart';
import 'gemini_native_response_parser.dart';
import 'openai_gateway_cancellation_scope.dart';

class GeminiNativeStreamAdapter {
  GeminiNativeStreamAdapter({
    GatewaySseEventPump? sseEventPump,
    GeminiNativeResponseParser? responseParser,
  }) : _sseEventPump = sseEventPump ?? const GatewaySseEventPump(),
       _responseParser = responseParser ?? const GeminiNativeResponseParser();

  final GatewaySseEventPump _sseEventPump;
  final GeminiNativeResponseParser _responseParser;

  bool responseMayStream(HttpClientResponse response, JsonMap options) {
    // 中文注释: Gemini native 只要是 SSE 或显式 stream 就进入流式聚合。
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  bool looksLikeEventStream(String body) {
    // 中文注释: Gemini native SSE 同样以 data: 承载，事件类型再由具体字段决定。
    return body.trimLeft().startsWith('data:');
  }

  Future<JsonMap> parseHttpStream(
    HttpClientResponse response,
    Uri requestUri, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: HTTP 流先聚合成统一 envelope，再决定是否需要以非流式解析兜底。
    final aggregate = _GeminiStreamAggregate();
    final pumpResult = await _sseEventPump.pumpResponse(
      response,
      cancellationScope: cancellationScope,
      onEventData: (eventData) => _consumeEventData(
        eventData,
        aggregate,
        cancellationScope,
        onStreamUpdate,
      ),
    );
    final body = pumpResult.rawBody;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Gemini 模型请求失败(${response.statusCode}): $body',
        uri: requestUri,
      );
    }
    if (!pumpResult.sawStreamEvent && !looksLikeEventStream(body)) {
      return _responseParser.parseBody(body);
    }
    if (pumpResult.sawStreamEvent &&
        !pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw HttpException('Gemini 流式响应在完成前被中断。', uri: requestUri);
    }
    return _finalize(aggregate, cancellationScope, onStreamUpdate);
  }

  JsonMap parseEventStreamBody(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 字符串 SSE 与 HTTP SSE 共用同一套 Gemini native 聚合逻辑。
    final aggregate = _GeminiStreamAggregate();
    final pumpResult = _sseEventPump.pumpBody(
      body,
      onEventData: (eventData) => _consumeEventData(
        eventData,
        aggregate,
        cancellationScope,
        onStreamUpdate,
      ),
    );
    if (!pumpResult.reachedTerminalEvent &&
        !cancellationScope.isCancellationRequested) {
      throw const HttpException('Gemini 流式响应在完成前被中断。');
    }
    return _finalize(aggregate, cancellationScope, onStreamUpdate);
  }

  JsonMap _finalize(
    _GeminiStreamAggregate aggregate,
    OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  ) {
    // 中文注释: 聚合结束后输出统一 envelope，并补一条 completed update 给上层消费。
    final snapshot = aggregate.snapshot();
    if (!cancellationScope.isCancellationRequested) {
      onStreamUpdate?.call(snapshot.toCompletedUpdate());
    }
    return snapshot.toResult();
  }

  bool _consumeEventData(
    String eventData,
    _GeminiStreamAggregate aggregate,
    OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  ) {
    // 中文注释: Gemini native SSE 事件类型较自由，这里优先识别 candidate/content/tool/function 数据。
    if (eventData == '[DONE]') {
      return true;
    }
    final root = ValueReaders.mapValue(jsonDecode(eventData));
    aggregate.setRawResponse(root);
    if (ValueReaders.boolValue(root['done'])) {
      return true;
    }
    final candidates = ValueReaders.objectList(root['candidates']);
    for (final rawCandidate in candidates) {
      final candidate = ValueReaders.mapValue(rawCandidate);
      final content = ValueReaders.mapValue(candidate['content']);
      for (final rawPart in ValueReaders.objectList(content['parts'])) {
        final part = ValueReaders.mapValue(rawPart);
        final text = GatewayContentExtractor.textFromContentPart(part);
        if (text.isNotEmpty) {
          aggregate.appendContent(text);
          if (onStreamUpdate != null &&
              !cancellationScope.isCancellationRequested) {
            onStreamUpdate(
              aggregate.buildDeltaUpdate(
                contentDelta: text,
                reasoningDelta: '',
                toolCalls: aggregate.toolCalls(),
              ),
            );
          }
          continue;
        }
        final functionCall = ValueReaders.mapValue(part['functionCall']);
        if (functionCall.isEmpty) {
          continue;
        }
        final builder = aggregate.toolCallBuilder(
          functionCallId: ValueReaders.stringValue(functionCall['id']),
          name: ValueReaders.stringValue(functionCall['name']),
        );
        final args = functionCall['args'];
        if (args is String) {
          builder.replaceArguments(args);
        } else {
          builder.replaceArguments(jsonEncode(args ?? <String, Object?>{}));
        }
        if (onStreamUpdate != null &&
            !cancellationScope.isCancellationRequested) {
          onStreamUpdate(
            aggregate.buildDeltaUpdate(
              contentDelta: '',
              reasoningDelta: '',
              toolCalls: aggregate.toolCalls(),
            ),
          );
        }
      }
      final thoughts = ValueReaders.objectList(candidate['thoughts']);
      for (final rawThought in thoughts) {
        final thought = ValueReaders.mapValue(rawThought);
        final text = ValueReaders.stringValue(thought['text']);
        if (text.isEmpty) {
          continue;
        }
        aggregate.appendReasoning(text);
        if (onStreamUpdate != null &&
            !cancellationScope.isCancellationRequested) {
          onStreamUpdate(
            aggregate.buildDeltaUpdate(
              contentDelta: '',
              reasoningDelta: text,
              toolCalls: aggregate.toolCalls(),
            ),
          );
        }
      }
    }
    return false;
  }
}

class _GeminiStreamAggregate {
  final StringBuffer _contentBuffer = StringBuffer();
  final StringBuffer _reasoningBuffer = StringBuffer();
  JsonMap _rawResponse = const <String, Object?>{};
  final Map<String, GatewayToolCallBuilder> _toolCallBuilders =
      <String, GatewayToolCallBuilder>{};

  void appendContent(String text) {
    if (text.isEmpty) {
      return;
    }
    _contentBuffer.write(text);
  }

  void appendReasoning(String text) {
    if (text.isEmpty) {
      return;
    }
    _reasoningBuffer.write(text);
  }

  void setRawResponse(Object? value) {
    _rawResponse = ValueReaders.mapValue(value);
  }

  GatewayToolCallBuilder toolCallBuilder({
    required String functionCallId,
    required String name,
  }) {
    // 中文注释: Gemini native 的工具调用先按 id/name 收口到同一个 builder，避免流式事件分片导致重复记录。
    final key = functionCallId.trim().isNotEmpty ? functionCallId.trim() : name;
    final builder = _toolCallBuilders[key] ??= GatewayToolCallBuilder(
      id: key,
      name: name,
    );
    builder.setId(functionCallId);
    builder.setName(name);
    return builder;
  }

  List<JsonMap> toolCalls() {
    // 中文注释: 对外只返回去重后的工具调用列表，避免同一 call 被多个索引重复暴露。
    return _toolCallBuilders.values
        .map((builder) => builder.build(ValueReaders.mapValue))
        .toList(growable: false);
  }

  GatewayStreamResultSnapshot snapshot() {
    // 中文注释: Gemini native 结束时输出统一 envelope，方便上层继续按 content/tool_calls 读取。
    return GatewayStreamResultSnapshot(
      content: _contentBuffer.toString(),
      reasoningContent: _reasoningBuffer.toString(),
      toolCalls: toolCalls(),
      rawResponse: _rawResponse,
    );
  }

  LlmStreamUpdate buildDeltaUpdate({
    required String contentDelta,
    required String reasoningDelta,
    required List<JsonMap> toolCalls,
  }) {
    final snapshot = this.snapshot();
    return LlmStreamUpdate(
      contentDelta: contentDelta,
      content: snapshot.content,
      reasoningDelta: reasoningDelta,
      reasoningContent: snapshot.reasoningContent,
      toolCalls: toolCalls,
    );
  }
}
