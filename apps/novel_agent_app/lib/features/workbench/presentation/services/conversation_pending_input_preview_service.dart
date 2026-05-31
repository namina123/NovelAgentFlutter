import '../models/conversation_pending_input_preview_view_data.dart';

class ConversationPendingInputPreviewService {
  const ConversationPendingInputPreviewService();

  ConversationPendingInputPreviewViewData? build({
    required String rawText,
    required bool isGenerating,
  }) {
    final text = rawText.trim();
    if (!isGenerating || text.isEmpty) {
      return null;
    }
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList(
      growable: false,
    );
    return ConversationPendingInputPreviewViewData(
      text: text,
      previewText: _previewText(text),
      characterCount: text.length,
      lineCount: lines.isEmpty ? 1 : lines.length,
    );
  }

  String _previewText(String text) {
    const maxChars = 140;
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, maxChars)}...';
  }
}
