import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_response_normalizer.dart';

class GeminiNativeResponseParser {
  const GeminiNativeResponseParser();

  JsonMap parseBody(String body) {
    // 中文注释: Gemini native response 按 candidates/content/parts 收敛，不借用 OpenAI 的 choices 结构。
    final root = ValueReaders.mapValue(jsonDecode(body));
    final candidates = ValueReaders.objectList(root['candidates']);
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final toolCalls = <JsonMap>[];
    for (final rawCandidate in candidates) {
      final candidate = ValueReaders.mapValue(rawCandidate);
      final content = ValueReaders.mapValue(candidate['content']);
      final parts = ValueReaders.objectList(content['parts']);
      for (final rawPart in parts) {
        final part = ValueReaders.mapValue(rawPart);
        final functionCall = ValueReaders.mapValue(part['functionCall']);
        if (functionCall.isNotEmpty) {
          toolCalls.add(
            GatewayResponseNormalizer.buildToolCallRecord(
              id: ValueReaders.stringValue(
                functionCall['id'],
                ValueReaders.stringValue(functionCall['name']),
              ),
              name: ValueReaders.stringValue(functionCall['name']),
              arguments: functionCall['args'],
            ),
          );
          continue;
        }
        final functionResponse = ValueReaders.mapValue(
          part['functionResponse'],
        );
        if (functionResponse.isNotEmpty) {
          continue;
        }
        final text = GatewayContentExtractor.textFromContentPart(part);
        if (text.isEmpty) {
          continue;
        }
        if (contentBuffer.isNotEmpty) {
          contentBuffer.writeln();
        }
        contentBuffer.write(text);
      }
      final thoughts = ValueReaders.objectList(candidate['thoughts']);
      for (final rawThought in thoughts) {
        final thought = ValueReaders.mapValue(rawThought);
        final text = ValueReaders.stringValue(thought['text']);
        if (text.isEmpty) {
          continue;
        }
        if (reasoningBuffer.isNotEmpty) {
          reasoningBuffer.writeln();
        }
        reasoningBuffer.write(text);
      }
    }
    return GatewayResponseNormalizer.buildEnvelope(
      content: contentBuffer.toString(),
      reasoningContent: reasoningBuffer.toString(),
      toolCalls: toolCalls,
      rawResponse: root,
    );
  }
}
