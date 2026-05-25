final class ChapterRewriteActionKind {
  static const String rewriteFull = 'rewrite_full';
  static const String rewritePartial = 'rewrite_partial';
  static const String suggestionsOnly = 'suggestions_only';

  static String normalize(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (const <String>{
      rewriteFull,
      'full',
      'full_chapter',
      'rewrite_chapter',
    }.contains(value)) {
      return rewriteFull;
    }
    if (const <String>{
      rewritePartial,
      'partial',
      'partial_rewrite',
      'rewrite_selection',
    }.contains(value)) {
      return rewritePartial;
    }
    return suggestionsOnly;
  }
}
