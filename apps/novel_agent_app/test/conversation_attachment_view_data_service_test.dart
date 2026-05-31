import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_attachment_draft.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_attachment_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationAttachmentViewDataService', () {
    test('builds readable subtitles for ready and failed drafts', () {
      const service = ConversationAttachmentViewDataService();

      final viewData = service.build(const [
        ConversationAttachmentDraft(
          id: 'a1',
          fileName: 'cover.png',
          localPath: 'D:/demo/cover.png',
          mediaKind: AttachmentMediaKind.image,
          mimeType: 'image/png',
          sizeBytes: 2048,
          isReady: true,
        ),
        ConversationAttachmentDraft(
          id: 'a2',
          fileName: 'missing.pdf',
          localPath: 'D:/demo/missing.pdf',
          mediaKind: AttachmentMediaKind.file,
          mimeType: 'application/pdf',
          sizeBytes: 0,
          isReady: false,
          failureMessage: '附件文件不存在。',
        ),
      ]);

      expect(viewData, hasLength(2));
      expect(viewData.first.subtitle, 'image/png · 2.0 KB');
      expect(viewData.first.isImage, isTrue);
      expect(viewData.last.subtitle, '附件文件不存在。');
      expect(viewData.last.isReady, isFalse);
    });
  });
}
