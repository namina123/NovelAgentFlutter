import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChatRequestCapability {
  const ChatRequestCapability({
    required this.supportsFileAttachments,
    required this.supportsImageAttachments,
    required this.supportsAttachmentUrlsOnly,
    required this.supportsMultiAttachments,
  });

  const ChatRequestCapability.none()
    : supportsFileAttachments = false,
      supportsImageAttachments = false,
      supportsAttachmentUrlsOnly = false,
      supportsMultiAttachments = false;

  factory ChatRequestCapability.fromModelProfile(JsonMap modelProfile) {
    return ChatRequestCapability(
      supportsFileAttachments: ValueReaders.boolValue(
        modelProfile['supports_file_attachments'],
      ),
      supportsImageAttachments: ValueReaders.boolValue(
        modelProfile['supports_image_attachments'],
      ),
      supportsAttachmentUrlsOnly: ValueReaders.boolValue(
        modelProfile['supports_attachment_urls_only'],
      ),
      supportsMultiAttachments: ValueReaders.boolValue(
        modelProfile['supports_multi_attachments'],
      ),
    );
  }

  final bool supportsFileAttachments;
  final bool supportsImageAttachments;
  final bool supportsAttachmentUrlsOnly;
  final bool supportsMultiAttachments;

  bool get supportsAnyAttachment =>
      supportsFileAttachments ||
      supportsImageAttachments ||
      supportsAttachmentUrlsOnly;
}
