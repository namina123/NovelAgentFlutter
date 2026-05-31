import 'attachment_media_kind.dart';

class ChatInputAttachment {
  ChatInputAttachment({
    required this.id,
    required this.mediaKind,
    required this.fileName,
    this.mimeType = '',
    this.localPath = '',
    this.sourceUrl = '',
  }) : assert(
         localPath.trim().isNotEmpty || sourceUrl.trim().isNotEmpty,
         'Attachment must provide a localPath or sourceUrl.',
       );

  final String id;
  final AttachmentMediaKind mediaKind;
  final String fileName;
  final String mimeType;
  final String localPath;
  final String sourceUrl;

  bool get hasLocalPath => localPath.trim().isNotEmpty;
  bool get hasSourceUrl => sourceUrl.trim().isNotEmpty;
}
