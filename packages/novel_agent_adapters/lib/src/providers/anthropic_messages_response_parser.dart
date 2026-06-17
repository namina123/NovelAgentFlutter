import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_json_response_parser.dart';
import 'gateway_response_normalizer.dart';

class AnthropicMessagesResponseParser extends GatewayJsonResponseParser {
  const AnthropicMessagesResponseParser();

  @override
  JsonMap parseBody(String body) {
    // 中文注释: Anthropic 非流式响应按 content blocks + tool_use 结构归一化，不再走 OpenAI 的 choices/message。
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
