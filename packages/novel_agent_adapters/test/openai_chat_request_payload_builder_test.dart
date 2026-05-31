import 'package:novel_agent_adapters/src/providers/openai_chat_request_payload_builder.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiChatRequestPayloadBuilder', () {
    test('builds payload from typed request and filters reserved options', () {
      final builder = const OpenAiChatRequestPayloadBuilder();

      final payload = builder.build(
        ChatRequest(
          modelId: 'demo-model',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'user', 'content': 'hi'},
          ],
          tools: const <JsonMap>[
            <String, Object?>{
              'type': 'function',
              'function': <String, Object?>{'name': 'demo_tool'},
            },
          ],
          options: const <String, Object?>{
            'stream': true,
            'tool_choice': 'auto',
            'stream_scope': 'sub_agent',
          },
        ),
      );

      expect(payload['model'], 'demo-model');
      expect(ValueReaders.objectList(payload['messages']), hasLength(1));
      expect(ValueReaders.objectList(payload['tools']), hasLength(1));
      expect(payload['stream'], isTrue);
      expect(payload['tool_choice'], 'auto');
      expect(payload.containsKey('stream_scope'), isFalse);
    });

    test('rejects attachments until provider bridge is implemented', () {
      final builder = const OpenAiChatRequestPayloadBuilder();

      expect(
        () => builder.build(
          ChatRequest(
            modelId: 'demo-model',
            messages: const <JsonMap>[
              <String, Object?>{'role': 'user', 'content': 'hi'},
            ],
            attachments: <ChatInputAttachment>[
              ChatInputAttachment(
                id: 'a1',
                mediaKind: AttachmentMediaKind.file,
                fileName: 'outline.md',
                localPath: 'D:/demo/outline.md',
              ),
            ],
            capability: const ChatRequestCapability(
              supportsFileAttachments: true,
              supportsImageAttachments: false,
              supportsAttachmentUrlsOnly: false,
              supportsMultiAttachments: false,
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('桥接尚未实现'),
          ),
        ),
      );
    });

    test(
      'rejects url-only provider when local file attachment is selected',
      () {
        final builder = const OpenAiChatRequestPayloadBuilder();

        expect(
          () => builder.build(
            ChatRequest(
              modelId: 'demo-model',
              messages: const <JsonMap>[
                <String, Object?>{'role': 'user', 'content': 'hi'},
              ],
              attachments: <ChatInputAttachment>[
                ChatInputAttachment(
                  id: 'a1',
                  mediaKind: AttachmentMediaKind.file,
                  fileName: 'outline.md',
                  localPath: 'D:/demo/outline.md',
                ),
              ],
              capability: const ChatRequestCapability(
                supportsFileAttachments: false,
                supportsImageAttachments: false,
                supportsAttachmentUrlsOnly: true,
                supportsMultiAttachments: false,
              ),
            ),
          ),
          throwsA(
            isA<UnsupportedError>().having(
              (error) => error.message,
              'message',
              contains('仅支持 URL 附件'),
            ),
          ),
        );
      },
    );
  });
}
