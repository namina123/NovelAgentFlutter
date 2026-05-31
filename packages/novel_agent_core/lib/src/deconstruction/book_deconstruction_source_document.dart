class BookDeconstructionSourceDocument {
  const BookDeconstructionSourceDocument({
    required this.id,
    required this.title,
    required this.content,
    this.mediaType = 'text/plain',
    this.relativePathHint = '',
    this.sequence = 0,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String content;
  final String mediaType;
  final String relativePathHint;
  final int sequence;
  final Map<String, Object?> metadata;
}
