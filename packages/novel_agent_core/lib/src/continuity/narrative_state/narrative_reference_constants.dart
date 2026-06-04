abstract final class NarrativeSourceTypes {
  static const String writer = 'writer';
  static const String reviewer = 'reviewer';
  static const String deconstruction = 'deconstruction';
  static const String explainer = 'explainer';
  static const String explainerInterpreted = 'explainer_interpreted';
  static const String user = 'user';
  static const String system = 'system';
  static const String recovery = 'recovery';
}

abstract final class NarrativeRefTypes {
  static const String asset = 'asset';
  static const String chapter = 'chapter';
  static const String segment = 'segment';
  static const String toolRound = 'tool_round';
  static const String externalImportSnippet = 'external_import_snippet';
}

abstract final class NarrativeEvidenceTypes {
  static const String toolCall = 'tool_call';
  static const String assistantTranscript = 'assistant_transcript';
  static const String extractedSnippet = 'extracted_snippet';
  static const String reviewNote = 'review_note';
}
