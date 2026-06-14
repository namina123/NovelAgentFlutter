final class SessionRecordConstants {
  static const int minThresholdChars = 1000;
  static const int maxThresholdChars = 1000000;
  static const int defaultThresholdChars = 24000;

  static const String transcriptMessagesField = 'transcript_messages';
  static const String workingContextMessagesField = 'working_context_messages';
  static const String compactionSegmentsField = 'compaction_segments';
  static const String pinnedContextRefsField = 'pinned_context_refs';
  static const String legacyContextMessagesField = 'context_messages';
  static const String legacyCompressedContextField = 'compressed_context';
  static const String compressionCountField = 'compression_count';
  static const String transcriptContextCharsField = 'transcript_context_chars';
  static const String workingContextCharsField = 'working_context_chars';
  static const String compactionArchiveCharsField = 'compaction_archive_chars';

  static const String modeSmartOpening = 'smart_opening';
  static const String modeSummarizeBook = 'summarize_book';
  static const String modeChapterDraft = 'chapter_draft';
  static const String modeImportArticle = 'import_article';
  static const String modeContinueWriting = 'continue_writing';
  static const String modeUnselected = 'new_session';
}
