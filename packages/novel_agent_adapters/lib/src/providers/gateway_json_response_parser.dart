import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_response_normalizer.dart';

abstract class GatewayJsonResponseParser {
  const GatewayJsonResponseParser();

  JsonMap parseBody(String body);
}

class OpenAiJsonResponseParser extends GatewayJsonResponseParser {
  const OpenAiJsonResponseParser();

  @override
  JsonMap parseBody(String body) {
    final root = ValueReaders.mapValue(jsonDecode(body));
    final choices = root['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('响应中缺少 choices。');
    }
    final firstChoice = ValueReaders.mapValue(choices.first);
    final message = ValueReaders.mapValue(firstChoice['message']);
    return GatewayResponseNormalizer.buildEnvelope(
      content: GatewayContentExtractor.textFromContent(message['content']),
      reasoningContent: ValueReaders.stringValue(
        message['reasoning_content'] ?? firstChoice['reasoning_content'],
      ),
      toolCalls: GatewayResponseNormalizer.normalizeOpenAiToolCalls(
        message['tool_calls'],
      ),
      rawResponse: root,
    );
  }
}

class AnthropicJsonResponseParser extends GatewayJsonResponseParser {
  const AnthropicJsonResponseParser();

  @override
  JsonMap parseBody(String body) {
    final root = ValueReaders.mapValue(jsonDecode(body));
    final contentParts = ValueReaders.objectList(root['content']);
    final contentBuffer = StringBuffer();
    final toolCalls = <JsonMap>[];
    for (final rawPart in contentParts) {
      final part = ValueReaders.mapValue(rawPart);
      final type = ValueReaders.stringValue(part['type']);
      if (type == 'text') {
        final text = GatewayContentExtractor.textFromContentPart(part);
        if (text.isEmpty) {
          continue;
        }
        if (contentBuffer.isNotEmpty) {
          contentBuffer.write('\n');
        }
        contentBuffer.write(text);
        continue;
      }
      if (type == 'tool_use') {
        toolCalls.add(
          GatewayResponseNormalizer.buildToolCallRecord(
            id: ValueReaders.stringValue(part['id']),
            name: ValueReaders.stringValue(part['name']),
            arguments: ValueReaders.mapValue(part['input']),
          ),
        );
      }
    }
    return GatewayResponseNormalizer.buildEnvelope(
      content: contentBuffer.toString(),
      reasoningContent: GatewayContentExtractor.reasoningFromContentParts(
        contentParts,
        textKey: 'thinking',
      ),
      toolCalls: toolCalls,
      rawResponse: root,
    );
  }
}
