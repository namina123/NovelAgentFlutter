import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_sse_event_pump.dart';
import 'gateway_stream_result_aggregator.dart';
import 'gateway_tool_call_builder.dart';
import 'gateway_json_response_parser.dart';
import 'openai_gateway_cancellation_scope.dart';
import 'openai_responses_response_parser.dart';

class OpenAiResponsesStreamAdapter {
  OpenAiResponsesStreamAdapter({
    GatewaySseEventPump? sseEventPump,
    GatewayJsonResponseParser? responseParser,
  }) : _sseEventPump = sseEventPump ?? const GatewaySseEventPump(),
       _responseParser =
           responseParser ?? const OpenAiResponsesResponseParser();

  final GatewaySseEventPump _sseEventPump;
  final GatewayJsonResponseParser _responseParser;

  bool responseMayStream(HttpClientResponse response, JsonMap options) {
    // 中文注释: Responses 和 Chat 一样都可能用 SSE 返回，这里按 content-type 或 stream 开关进入增量消费。
    final mimeType = response.headers.contentType?.mimeType ?? '';
    if (mimeType == 'text/event-stream') {
      return true;
    }
    return options['stream'] == true;
  }

  bool looksLikeEventStream(String body) {
    // 中文注释: typed SSE 仍以 data: 开头传输，具体语义交给事件 type 解析。
    return body.trimLeft().startsWith('data:');
  }

  Future<JsonMap> parseHttpStream(
    HttpClientResponse response,
    Uri requestUri, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: HTTP 流在这里统一转成 typed event 聚合，最终输出与非流式保持同一 envelope。
    final aggregate = _ResponsesStreamAggregate();
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
    return _finalize(aggregate, cancellationScope, onStreamUpdate);
  }

  JsonMap parseEventStreamBody(
    String body, {
    required OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 字符串形式的 SSE 也走同一套 typed event 聚合，避免和 HTTP 分支分裂。
    final aggregate = _ResponsesStreamAggregate();
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
      throw const HttpException('流式响应在完成前被中断。');
    }
    return _finalize(aggregate, cancellationScope, onStreamUpdate);
  }

  JsonMap _finalize(
    _ResponsesStreamAggregate aggregate,
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
    _ResponsesStreamAggregate aggregate,
    OpenAiGatewayCancellationScope cancellationScope,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  ) {
    // 中文注释: 这里只识别 Responses typed SSE 事件 type，不再假设 Chat 的 delta 结构。
    if (eventData == '[DONE]') {
      return true;
    }
    final root = ValueReaders.mapValue(jsonDecode(eventData));
    aggregate.setRawResponse(root['response']);
    final type = ValueReaders.stringValue(root['type']);
    switch (type) {
      case 'response.created':
        aggregate.setRawResponse(root['response']);
        return false;
      case 'response.output_text.delta':
        final delta = ValueReaders.stringValue(root['delta']);
        if (delta.isEmpty) {
          return false;
        }
        aggregate.appendContent(delta);
        if (onStreamUpdate != null &&
            !cancellationScope.isCancellationRequested) {
          onStreamUpdate(
            aggregate.buildDeltaUpdate(
              contentDelta: delta,
              reasoningDelta: '',
              toolCalls: aggregate.toolCalls(),
            ),
          );
        }
        return false;
      case 'response.reasoning_text.delta':
      case 'response.reasoning.delta':
        final delta = ValueReaders.stringValue(root['delta']);
        if (delta.isEmpty) {
          return false;
        }
        aggregate.appendReasoning(delta);
        if (onStreamUpdate != null &&
            !cancellationScope.isCancellationRequested) {
          onStreamUpdate(
            aggregate.buildDeltaUpdate(
              contentDelta: '',
              reasoningDelta: delta,
              toolCalls: aggregate.toolCalls(),
            ),
          );
        }
        return false;
      case 'response.output_item.added':
        final item = ValueReaders.mapValue(root['item']);
        _seedToolCallBuilder(aggregate, item);
        return false;
      case 'response.function_call_arguments.delta':
        final callId = ValueReaders.stringValue(root['call_id']);
        final itemId = ValueReaders.stringValue(root['item_id']);
        final delta = ValueReaders.stringValue(root['delta']);
        if (delta.isEmpty) {
          return false;
        }
        final builder = aggregate.toolCallBuilder(
          callId: callId,
          itemId: itemId,
          outputIndex: ValueReaders.intValue(root['output_index'], -1),
          createIfMissing: true,
        );
        builder.appendPartialArguments(delta);
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
        return false;
      case 'response.function_call_arguments.done':
        final callId = ValueReaders.stringValue(root['call_id']);
        final itemId = ValueReaders.stringValue(root['item_id']);
        final arguments = ValueReaders.stringValue(root['arguments']);
        final builder = aggregate.toolCallBuilder(
          callId: callId,
          itemId: itemId,
          outputIndex: ValueReaders.intValue(root['output_index'], -1),
          createIfMissing: true,
        );
        if (arguments.isNotEmpty) {
          builder.replaceArguments(arguments);
        }
        return false;
      case 'response.output_item.done':
        final item = ValueReaders.mapValue(root['item']);
        _seedToolCallBuilder(aggregate, item);
        return false;
      case 'response.completed':
        aggregate.setRawResponse(root['response']);
        return true;
      case 'error':
        final error = ValueReaders.mapValue(root['error']);
        throw HttpException(
          ValueReaders.stringValue(error['message'], 'Responses 请求失败。'),
        );
      default:
        return false;
    }
  }

  void _seedToolCallBuilder(
    _ResponsesStreamAggregate aggregate,
    JsonMap item,
  ) {
    // 中文注释: function_call item 先建立占位，再由 arguments.delta / done 填满，避免依赖单一事件顺序。
    final type = ValueReaders.stringValue(item['type']);
    if (type != 'function_call') {
      if (type == 'reasoning') {
        final text = _reasoningTextFromItem(item);
        if (text.isNotEmpty) {
          aggregate.appendReasoning(text);
        }
      }
      if (type == 'message') {
        final text = _messageTextFromItem(item);
        if (text.isNotEmpty) {
          aggregate.appendContent(text);
        }
      }
      return;
    }
    final builder = aggregate.toolCallBuilder(
      callId: ValueReaders.stringValue(item['call_id']),
      itemId: ValueReaders.stringValue(item['id']),
      outputIndex: ValueReaders.intValue(item['output_index'], -1),
      createIfMissing: true,
    );
    builder.setName(ValueReaders.stringValue(item['name']));
    final arguments = ValueReaders.stringValue(item['arguments']);
    if (arguments.isNotEmpty && !builder.hasArguments) {
      builder.appendPartialArguments(arguments);
    }
  }

  String _messageTextFromItem(JsonMap item) {
    // 中文注释: Responses 的 message 输出内容按 output_text 项抽取文本，兼容字符串与 typed content。
    return _textFromContent(item['content']);
  }

  String _reasoningTextFromItem(JsonMap item) {
    // 中文注释: reasoning item 既可能有 summary，也可能有 content，这里统一合并成可读摘要。
    final buffer = StringBuffer();
    for (final rawPart in ValueReaders.objectList(item['summary'])) {
      final part = ValueReaders.mapValue(rawPart);
      final text = ValueReaders.stringValue(part['text']);
      if (text.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(text);
    }
    for (final rawPart in ValueReaders.objectList(item['content'])) {
      final part = ValueReaders.mapValue(rawPart);
      final text = ValueReaders.stringValue(part['text']);
      if (text.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(text);
    }
    final encrypted = ValueReaders.stringValue(item['encrypted_content']);
    if (buffer.isEmpty && encrypted.isNotEmpty) {
      return encrypted;
    }
    return buffer.toString();
  }

  String _textFromContent(Object? value) {
    // 中文注释: Responses content 可能是字符串或 output_text 项列表，这里统一收敛成正文。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final rawPart in value) {
        final part = ValueReaders.mapValue(rawPart);
        final type = ValueReaders.stringValue(part['type']);
        if (type != 'output_text' && type != 'input_text' && type != 'text') {
          continue;
        }
        final text = ValueReaders.stringValue(part['text']);
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
    return GatewayContentExtractor.textFromContent(value);
  }
}

class _ResponsesStreamAggregate {
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
    required String callId,
    required String itemId,
    required int outputIndex,
    required bool createIfMissing,
  }) {
    // 中文注释: Responses 的工具调用可能通过 call_id、item_id 或 output_index 关联，这里统一落到同一个 builder。
    final keys = <String>[
      if (callId.trim().isNotEmpty) callId.trim(),
      if (itemId.trim().isNotEmpty) itemId.trim(),
      if (outputIndex >= 0) outputIndex.toString(),
    ];
    for (final key in keys) {
      final existing = _toolCallBuilders[key];
      if (existing != null) {
        if (callId.trim().isNotEmpty) {
          existing.setId(callId.trim());
        }
        return existing;
      }
    }
    if (!createIfMissing) {
      return GatewayToolCallBuilder(id: callId, name: '');
    }
    final builder = GatewayToolCallBuilder(
      id: callId.trim(),
      name: '',
    );
    for (final key in keys) {
      _toolCallBuilders[key] = builder;
    }
    return builder;
  }

  void seedToolCallBuilder({
    required String callId,
    required String itemId,
    required int outputIndex,
    required String name,
    required Object? arguments,
  }) {
    // 中文注释: 先把 Responses 的 function_call item 落成稳定占位，再等待分片 arguments 补齐。
    final builder = toolCallBuilder(
      callId: callId,
      itemId: itemId,
      outputIndex: outputIndex,
      createIfMissing: true,
    );
    builder.setName(name);
    if (arguments is String) {
      final trimmed = arguments.trim();
      if (trimmed.isNotEmpty) {
        builder.replaceArguments(trimmed);
      }
      return;
    }
    final text = ValueReaders.stringValue(arguments);
    if (text.isNotEmpty) {
      builder.replaceArguments(text);
    }
  }

  List<JsonMap> toolCalls() {
    // 中文注释: 对外只返回去重后的工具调用列表，避免同一 call 同时以 call_id/item_id/index 暴露多份。
    final result = <GatewayToolCallBuilder>[];
    final seen = <GatewayToolCallBuilder>{};
    for (final builder in _toolCallBuilders.values) {
      if (seen.add(builder)) {
        result.add(builder);
      }
    }
    return result
        .map((builder) => builder.build(ValueReaders.mapValue))
        .toList(growable: false);
  }

  GatewayStreamResultSnapshot snapshot() {
    // 中文注释: 这里保留与 Chat 链一致的统一 envelope，供上层继续以 content/tool_calls 读取。
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
