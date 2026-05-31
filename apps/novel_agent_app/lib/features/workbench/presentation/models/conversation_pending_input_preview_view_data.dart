import 'package:flutter/foundation.dart';

@immutable
class ConversationPendingInputPreviewViewData {
  const ConversationPendingInputPreviewViewData({
    required this.text,
    required this.previewText,
    required this.characterCount,
    required this.lineCount,
  });

  final String text;
  final String previewText;
  final int characterCount;
  final int lineCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationPendingInputPreviewViewData &&
            other.text == text &&
            other.previewText == previewText &&
            other.characterCount == characterCount &&
            other.lineCount == lineCount;
  }

  @override
  int get hashCode => Object.hash(text, previewText, characterCount, lineCount);
}
