class ConversationAttachmentViewData {
  const ConversationAttachmentViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isImage,
    required this.isReady,
    required this.failureMessage,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool isImage;
  final bool isReady;
  final String failureMessage;
}
