enum SqliteProjectBodyTextStorageFormat {
  plainText('plain_text'),
  segmentedText('segmented_text');

  const SqliteProjectBodyTextStorageFormat(this.id);

  final String id;

  static SqliteProjectBodyTextStorageFormat fromId(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final format in SqliteProjectBodyTextStorageFormat.values) {
      if (format.id == clean) {
        return format;
      }
    }
    return SqliteProjectBodyTextStorageFormat.plainText;
  }
}
