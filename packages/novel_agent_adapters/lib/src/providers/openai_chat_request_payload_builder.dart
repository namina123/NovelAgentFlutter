import 'package:novel_agent_core/novel_agent_core.dart';

import 'openai_attachment_bridge_policy.dart';

class OpenAiChatRequestPayloadBuilder {
  const OpenAiChatRequestPayloadBuilder({
    OpenAiAttachmentBridgePolicy? attachmentBridgePolicy,
  }) : _attachmentBridgePolicy =
           attachmentBridgePolicy ?? const OpenAiAttachmentBridgePolicy();

  final OpenAiAttachmentBridgePolicy _attachmentBridgePolicy;

  JsonMap build(ChatRequest request) {
    _assertAttachmentBridgeReadiness(request);
    final payload = <String, Object?>{
      'model': request.modelId,
      'messages': _requestMessages(request),
      if (request.tools.isNotEmpty) 'tools': request.tools,
      if (request.options.containsKey('tool_choice'))
        'tool_choice': request.options['tool_choice'],
    };
    request.options.forEach((key, value) {
      if (_reservedOptionKeys.contains(key)) {
        return;
      }
      payload[key] = value;
    });
    return payload;
  }

  List<Object?> _requestMessages(ChatRequest request) {
    return request.messages
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  void _assertAttachmentBridgeReadiness(ChatRequest request) {
    // 中文注释: adapter 先做能力评估和稳定失败，不在未桥接完成前默默吞掉附件或伪装为文本请求。
    final assessment = _attachmentBridgePolicy.assess(request);
    if (assessment.isRequestSupported) {
      return;
    }
    if (assessment.failureMessage.trim().isEmpty) {
      return;
    }
    throw UnsupportedError(assessment.failureMessage);
  }

  static const Set<String> _reservedOptionKeys = <String>{
    'prompt',
    'api_mode',
    'tool_choice',
    'stream_scope',
    'sub_session_id',
    'allow_inline_tools',
    'force_tool_choice',
    'preferred_tool',
  };
}
