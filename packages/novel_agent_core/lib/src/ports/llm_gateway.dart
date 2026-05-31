import '../common/json_types.dart';
import '../llm/chat_input_attachment.dart';
import '../llm/chat_request.dart';
import '../runtime/draft_generation_cancellation_token.dart';
import 'llm_stream_update.dart';

abstract class LlmGateway {
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  });

  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    // 中文注释: 兼容桥只负责把旧散装参数收进 ChatRequest，避免 adapter 继续理解历史 prompt/options 语义。
    return requestChat(
      request: ChatRequest.fromLegacy(
        messages: messages,
        modelId: modelId,
        tools: tools,
        options: options,
        attachments: attachments,
      ),
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    // 中文注释: 旧的一次性文本接口保留下来，方便现有轻量用例在升级网关后继续复用。
    final result = await requestChat(
      request: ChatRequest.textPrompt(prompt: prompt, modelId: modelId),
    );
    final content = result['content']?.toString().trim() ?? '';
    if (content.isEmpty) {
      throw const FormatException('响应中缺少可读文本内容。');
    }
    return content;
  }
}
