import 'package:novel_agent_adapters/src/providers/openai_attachment_bridge_policy.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAiAttachmentBridgePolicy', () {
    test(
      'reports unsupported when provider/model has no attachment capability',
      () {
        const policy = OpenAiAttachmentBridgePolicy();

        final assessment = policy.assess(
          ChatRequest(
            modelId: 'demo-model',
            messages: const <JsonMap>[
              <String, Object?>{'role': 'user', 'content': 'hi'},
            ],
            attachments: <ChatInputAttachment>[
              ChatInputAttachment(
                id: 'a1',
                mediaKind: AttachmentMediaKind.file,
                fileName: 'brief.md',
                localPath: 'D:/demo/brief.md',
              ),
            ],
          ),
        );

        expect(assessment.mode, OpenAiAttachmentSupportMode.unsupported);
        expect(assessment.isRequestSupported, isFalse);
        expect(assessment.failureMessage, contains('不支持附件输入'));
      },
    );

    test('reports url-only provider mismatch for local files', () {
      const policy = OpenAiAttachmentBridgePolicy();

      final assessment = policy.assess(
        ChatRequest(
          modelId: 'demo-model',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'user', 'content': 'hi'},
          ],
          attachments: <ChatInputAttachment>[
            ChatInputAttachment(
              id: 'a1',
              mediaKind: AttachmentMediaKind.file,
              fileName: 'brief.md',
              localPath: 'D:/demo/brief.md',
            ),
          ],
          capability: const ChatRequestCapability(
            supportsFileAttachments: false,
            supportsImageAttachments: false,
            supportsAttachmentUrlsOnly: true,
            supportsMultiAttachments: false,
          ),
        ),
      );

      expect(assessment.mode, OpenAiAttachmentSupportMode.urlOnly);
      expect(assessment.isRequestSupported, isFalse);
      expect(assessment.failureMessage, contains('仅支持 URL 附件'));
    });

    test('reports native capability as not yet bridged', () {
      const policy = OpenAiAttachmentBridgePolicy();

      final assessment = policy.assess(
        ChatRequest(
          modelId: 'demo-model',
          messages: const <JsonMap>[
            <String, Object?>{'role': 'user', 'content': 'hi'},
          ],
          attachments: <ChatInputAttachment>[
            ChatInputAttachment(
              id: 'a1',
              mediaKind: AttachmentMediaKind.image,
              fileName: 'cover.png',
              localPath: 'D:/demo/cover.png',
            ),
          ],
          capability: const ChatRequestCapability(
            supportsFileAttachments: false,
            supportsImageAttachments: true,
            supportsAttachmentUrlsOnly: false,
            supportsMultiAttachments: false,
          ),
        ),
      );

      expect(assessment.mode, OpenAiAttachmentSupportMode.native);
      expect(assessment.isRequestSupported, isFalse);
      expect(assessment.failureMessage, contains('桥接尚未实现'));
    });
  });
}
