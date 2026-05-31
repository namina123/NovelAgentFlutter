import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_response_normalizer.dart';

class GatewayStreamResultSnapshot {
  const GatewayStreamResultSnapshot({
    required this.content,
    required this.reasoningContent,
    required this.toolCalls,
    required this.rawResponse,
  });

  final String content;
  final String reasoningContent;
  final List<JsonMap> toolCalls;
  final JsonMap rawResponse;

  JsonMap toResult() {
    return GatewayResponseNormalizer.buildEnvelope(
      content: content,
      reasoningContent: reasoningContent,
      toolCalls: toolCalls,
      rawResponse: rawResponse,
    );
  }

  LlmStreamUpdate toCompletedUpdate() {
    return LlmStreamUpdate(
      content: content,
      reasoningContent: reasoningContent,
      toolCalls: toolCalls,
      isCompleted: true,
    );
  }
}

class GatewayStreamResultAggregator {
  final StringBuffer _contentBuffer = StringBuffer();
  final StringBuffer _reasoningBuffer = StringBuffer();
  JsonMap _rawResponse = const <String, Object?>{};

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

  void setRawResponse(JsonMap value) {
    _rawResponse = value;
  }

  GatewayStreamResultSnapshot snapshot({
    required List<JsonMap> toolCalls,
  }) {
    return GatewayStreamResultSnapshot(
      content: _contentBuffer.toString(),
      reasoningContent: _reasoningBuffer.toString(),
      toolCalls: List<JsonMap>.unmodifiable(toolCalls),
      rawResponse: _rawResponse,
    );
  }

  LlmStreamUpdate buildDeltaUpdate({
    required String contentDelta,
    required String reasoningDelta,
    required List<JsonMap> toolCalls,
  }) {
    final snapshot = this.snapshot(toolCalls: toolCalls);
    return LlmStreamUpdate(
      contentDelta: contentDelta,
      content: snapshot.content,
      reasoningDelta: reasoningDelta,
      reasoningContent: snapshot.reasoningContent,
      toolCalls: snapshot.toolCalls,
    );
  }

  LlmStreamUpdate buildStateOnlyUpdate({
    required List<JsonMap> toolCalls,
  }) {
    final snapshot = this.snapshot(toolCalls: toolCalls);
    return LlmStreamUpdate(
      content: snapshot.content,
      reasoningContent: snapshot.reasoningContent,
      toolCalls: snapshot.toolCalls,
    );
  }
}

JsonMap decodeJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return <String, Object?>{};
}

JsonMap decodeJsonMapFromString(String source) {
  return decodeJsonMap(jsonDecode(source));
}
