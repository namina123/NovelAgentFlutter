import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chat_input_attachment.dart';
import 'chat_request_capability.dart';

class ChatRequest {
  ChatRequest({
    required this.modelId,
    required List<JsonMap> messages,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    this.capability = const ChatRequestCapability.none(),
  }) : messages = List<JsonMap>.unmodifiable(
         messages.map(ValueReaders.deepCopyMap),
       ),
       tools = List<JsonMap>.unmodifiable(tools.map(ValueReaders.deepCopyMap)),
       options = ValueReaders.deepCopyMap(options),
       attachments = List<ChatInputAttachment>.unmodifiable(attachments);

  factory ChatRequest.fromLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    ChatRequestCapability capability = const ChatRequestCapability.none(),
  }) {
    final normalizedOptions = ValueReaders.deepCopyMap(options)
      ..remove('prompt');
    final normalizedMessages = messages.isNotEmpty
        ? messages
        : _promptMessagesFromLegacyOptions(options);
    return ChatRequest(
      modelId: modelId,
      messages: normalizedMessages,
      tools: tools,
      options: normalizedOptions,
      attachments: attachments,
      capability: capability,
    );
  }

  factory ChatRequest.textPrompt({
    required String prompt,
    required String modelId,
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    ChatRequestCapability capability = const ChatRequestCapability.none(),
  }) {
    return ChatRequest(
      modelId: modelId,
      messages: <JsonMap>[
        <String, Object?>{'role': 'user', 'content': prompt},
      ],
      options: options,
      attachments: attachments,
      capability: capability,
    );
  }

  final String modelId;
  final List<JsonMap> messages;
  final List<JsonMap> tools;
  final JsonMap options;
  final List<ChatInputAttachment> attachments;
  final ChatRequestCapability capability;

  bool get hasAttachments => attachments.isNotEmpty;

  static List<JsonMap> _promptMessagesFromLegacyOptions(JsonMap options) {
    // 中文注释: 历史 prompt bridge 统一收在 core，请求适配层以后只处理正式消息列表。
    final prompt = '${options['prompt'] ?? ''}'.trim();
    if (prompt.isEmpty) {
      return const <JsonMap>[];
    }
    return <JsonMap>[
      <String, Object?>{'role': 'user', 'content': prompt},
    ];
  }
}
