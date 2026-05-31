import 'package:novel_agent_core/novel_agent_core.dart';

enum OpenAiAttachmentSupportMode { unsupported, native, urlOnly }

class OpenAiAttachmentBridgeAssessment {
  const OpenAiAttachmentBridgeAssessment({
    required this.mode,
    required this.isRequestSupported,
    this.failureMessage = '',
  });

  final OpenAiAttachmentSupportMode mode;
  final bool isRequestSupported;
  final String failureMessage;
}

class OpenAiAttachmentBridgePolicy {
  const OpenAiAttachmentBridgePolicy();

  OpenAiAttachmentBridgeAssessment assess(ChatRequest request) {
    if (!request.hasAttachments) {
      return const OpenAiAttachmentBridgeAssessment(
        mode: OpenAiAttachmentSupportMode.unsupported,
        isRequestSupported: true,
      );
    }
    final capability = request.capability;
    if (!capability.supportsAnyAttachment) {
      return const OpenAiAttachmentBridgeAssessment(
        mode: OpenAiAttachmentSupportMode.unsupported,
        isRequestSupported: false,
        failureMessage: '当前 provider / model 不支持附件输入。',
      );
    }
    if (!capability.supportsMultiAttachments &&
        request.attachments.length > 1) {
      return const OpenAiAttachmentBridgeAssessment(
        mode: OpenAiAttachmentSupportMode.unsupported,
        isRequestSupported: false,
        failureMessage: '当前 provider / model 不支持多附件输入。',
      );
    }
    if (capability.supportsAttachmentUrlsOnly) {
      final allHaveUrls = request.attachments.every(
        (attachment) => attachment.hasSourceUrl,
      );
      if (!allHaveUrls) {
        return const OpenAiAttachmentBridgeAssessment(
          mode: OpenAiAttachmentSupportMode.urlOnly,
          isRequestSupported: false,
          failureMessage: '当前 provider / model 仅支持 URL 附件，不支持本地文件直传。',
        );
      }
      return const OpenAiAttachmentBridgeAssessment(
        mode: OpenAiAttachmentSupportMode.urlOnly,
        isRequestSupported: false,
        failureMessage: '当前 provider / model 声明为 URL-only 附件，但 URL 附件协议桥接尚未实现。',
      );
    }
    for (final attachment in request.attachments) {
      if (attachment.mediaKind == AttachmentMediaKind.image &&
          !capability.supportsImageAttachments) {
        return const OpenAiAttachmentBridgeAssessment(
          mode: OpenAiAttachmentSupportMode.native,
          isRequestSupported: false,
          failureMessage: '当前 provider / model 不支持图片附件输入。',
        );
      }
      if (attachment.mediaKind == AttachmentMediaKind.file &&
          !capability.supportsFileAttachments) {
        return const OpenAiAttachmentBridgeAssessment(
          mode: OpenAiAttachmentSupportMode.native,
          isRequestSupported: false,
          failureMessage: '当前 provider / model 不支持文件附件输入。',
        );
      }
    }
    return const OpenAiAttachmentBridgeAssessment(
      mode: OpenAiAttachmentSupportMode.native,
      isRequestSupported: false,
      failureMessage: '当前 provider / model 已声明支持原生附件，但 OpenAI 兼容附件协议桥接尚未实现。',
    );
  }
}
