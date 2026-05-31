import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationAttachmentDraft {
  const ConversationAttachmentDraft({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.mediaKind,
    required this.mimeType,
    required this.sizeBytes,
    required this.isReady,
    this.failureMessage = '',
  });

  final String id;
  final String fileName;
  final String localPath;
  final AttachmentMediaKind mediaKind;
  final String mimeType;
  final int sizeBytes;
  final bool isReady;
  final String failureMessage;

  bool get hasFailure => failureMessage.trim().isNotEmpty;

  ChatInputAttachment toInputAttachment() {
    if (!isReady) {
      throw StateError('Attachment draft is not ready: $fileName');
    }
    return ChatInputAttachment(
      id: id,
      mediaKind: mediaKind,
      fileName: fileName,
      mimeType: mimeType,
      localPath: localPath,
    );
  }
}
