import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_attachment_draft.dart';
import '../../presentation/models/conversation_attachment_view_data.dart';

class ConversationAttachmentViewDataService {
  const ConversationAttachmentViewDataService();

  List<ConversationAttachmentViewData> build(
    List<ConversationAttachmentDraft> drafts,
  ) {
    return drafts
        .map(
          (draft) => ConversationAttachmentViewData(
            id: draft.id,
            title: draft.fileName,
            subtitle: draft.isReady
                ? _readySubtitle(draft)
                : draft.failureMessage.trim().isEmpty
                ? '附件暂不可用'
                : draft.failureMessage.trim(),
            isImage: draft.mediaKind == AttachmentMediaKind.image,
            isReady: draft.isReady,
            failureMessage: draft.failureMessage,
          ),
        )
        .toList(growable: false);
  }

  String _readySubtitle(ConversationAttachmentDraft draft) {
    final mime = draft.mimeType.trim();
    final sizeLabel = _formatBytes(draft.sizeBytes);
    if (mime.isEmpty) {
      return sizeLabel;
    }
    return '$mime · $sizeLabel';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
