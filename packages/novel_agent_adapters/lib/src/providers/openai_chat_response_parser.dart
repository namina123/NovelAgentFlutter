import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_content_extractor.dart';
import 'gateway_json_response_parser.dart';
import 'gateway_response_normalizer.dart';

class OpenAiChatResponseParser extends GatewayJsonResponseParser {
  const OpenAiChatResponseParser();

  @override
  JsonMap parseBody(String body) {
    // 中文注释: 这里只解析 OpenAI Chat Completions 的标准 JSON 包，避免把 Responses 或其他协议事件混进来。
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
