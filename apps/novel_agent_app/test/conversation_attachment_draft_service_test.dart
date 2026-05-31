import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_attachment_draft_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationAttachmentDraftService', () {
    test(
      'creates ready drafts and classifies image/file attachments',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'attachment_draft_service_test',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final imageFile = File(
          '${tempDir.path}${Platform.pathSeparator}cover.png',
        )..writeAsBytesSync(<int>[1, 2, 3, 4]);
        final markdownFile = File(
          '${tempDir.path}${Platform.pathSeparator}brief.md',
        )..writeAsStringSync('# brief');
        final service = ConversationAttachmentDraftService();

        final drafts = await service.createDrafts([
          imageFile.path,
          markdownFile.path,
        ]);

        expect(drafts, hasLength(2));
        expect(drafts.first.mediaKind, AttachmentMediaKind.image);
        expect(drafts.first.mimeType, 'image/png');
        expect(drafts.first.isReady, isTrue);
        expect(drafts.last.mediaKind, AttachmentMediaKind.file);
        expect(drafts.last.mimeType, 'text/markdown');
        expect(drafts.last.isReady, isTrue);
      },
    );

    test(
      'marks missing file as unavailable and keeps merge de-duplicated',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'attachment_draft_missing_test',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final readyFile = File(
          '${tempDir.path}${Platform.pathSeparator}notes.txt',
        )..writeAsStringSync('hello');
        final missingPath =
            '${tempDir.path}${Platform.pathSeparator}missing.pdf';
        final service = ConversationAttachmentDraftService();

        final currentDrafts = await service.createDrafts([readyFile.path]);
        final incomingDrafts = await service.createDrafts([
          readyFile.path,
          missingPath,
        ]);
        final merged = service.mergeDrafts(
          currentDrafts: currentDrafts,
          incomingDrafts: incomingDrafts,
        );

        expect(incomingDrafts.last.isReady, isFalse);
        expect(incomingDrafts.last.failureMessage, contains('不存在'));
        expect(merged, hasLength(2));
        expect(
          service.readyInputAttachments(merged).map((item) => item.fileName),
          ['notes.txt'],
        );
      },
    );
  });
}
