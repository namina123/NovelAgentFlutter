import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_json_response_parser.dart';
import 'gateway_response_normalizer.dart';

class OpenAiResponsesResponseParser extends GatewayJsonResponseParser {
  const OpenAiResponsesResponseParser();

  @override
  JsonMap parseBody(String body) {
    // 中文注释: Responses 的非流式结果是 typed output items，这里按 item.type 归一化，不再读 choices。
    final root = ValueReaders.mapValue(jsonDecode(body));
    final outputItems = ValueReaders.objectList(root['output']);
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCalls = <JsonMap>[];
    for (final rawItem in outputItems) {
      final item = ValueReaders.mapValue(rawItem);
      final type = ValueReaders.stringValue(item['type']);
      if (type == 'message') {
        final text = _textFromMessageContent(item['content']);
        if (text.isNotEmpty) {
          if (contentBuffer.isNotEmpty) {
            contentBuffer.writeln();
          }
          contentBuffer.write(text);
        }
        continue;
      }
      if (type == 'reasoning') {
        final reasoningText = _reasoningTextFromItem(item);
        if (reasoningText.isNotEmpty) {
          if (reasoningBuffer.isNotEmpty) {
            reasoningBuffer.writeln();
          }
          reasoningBuffer.write(reasoningText);
        }
        continue;
      }
      if (type == 'function_call') {
        final callId = ValueReaders.stringValue(
          item['call_id'],
          ValueReaders.stringValue(item['id']),
        );
        final name = ValueReaders.stringValue(item['name']);
        final arguments = item['arguments'];
        toolCalls.add(
          GatewayResponseNormalizer.buildToolCallRecord(
            id: callId,
            name: name,
            arguments: _argumentsValue(arguments),
            rawArguments: ValueReaders.stringValue(arguments),
          ),
        );
      }
    }
    return GatewayResponseNormalizer.buildEnvelope(
      content: contentBuffer.toString(),
      reasoningContent: reasoningBuffer.toString(),
      toolCalls: toolCalls,
      rawResponse: root,
    );
  }

  String _textFromMessageContent(Object? value) {
    // 中文注释: Responses 的 assistant message content 可以是字符串或 output_text 项列表，这里统一抽成正文。
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final part in value) {
        final partMap = ValueReaders.mapValue(part);
        final type = ValueReaders.stringValue(partMap['type']);
        if (type != 'output_text' && type != 'text') {
          continue;
        }
        final text = ValueReaders.stringValue(partMap['text']);
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

  String _reasoningTextFromItem(JsonMap item) {
    // 中文注释: reasoning item 可能带 summary 或 content，这里优先提取可读摘要。
    final summaryParts = ValueReaders.objectList(item['summary']);
    final buffer = StringBuffer();
    for (final rawPart in summaryParts) {
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
    final contentParts = ValueReaders.objectList(item['content']);
    for (final rawPart in contentParts) {
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
    if (encrypted.isNotEmpty && buffer.isEmpty) {
      return encrypted;
    }
    return buffer.toString();
  }

  Object _argumentsValue(Object? value) {
    // 中文注释: function_call.arguments 在 Responses 中通常是字符串；若出现结构化值也保持为原样。
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return <String, Object?>{};
      }
      try {
        return ValueReaders.mapValue(jsonDecode(trimmed));
      } catch (_) {
        return trimmed;
      }
    }
    return value ?? <String, Object?>{};
  }
}
