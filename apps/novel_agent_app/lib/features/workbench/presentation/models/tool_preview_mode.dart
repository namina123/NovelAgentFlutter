class ToolPreviewMode {
  const ToolPreviewMode._();

  static const String compact = 'compact';
  static const String detail = 'detail';

  static String normalize(Object? raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    switch (value) {
      case detail:
        return detail;
      case compact:
      default:
        return compact;
    }
  }

  static bool showsDetails(Object? raw) {
    return normalize(raw) == detail;
  }
}
