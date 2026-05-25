class SqliteProjectBodyTextSegment {
  const SqliteProjectBodyTextSegment({
    required this.segmentId,
    required this.ordinal,
    required this.text,
    this.segmentKind = 'paragraph',
  });

  final String segmentId;
  final int ordinal;
  final String text;
  final String segmentKind;
}
