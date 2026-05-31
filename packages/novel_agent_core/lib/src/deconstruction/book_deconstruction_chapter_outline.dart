class BookDeconstructionChapterOutline {
  const BookDeconstructionChapterOutline({
    required this.id,
    required this.title,
    this.summary = '',
    this.sequence = 0,
    this.keyEvents = const <String>[],
    this.focusCharacterIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String summary;
  final int sequence;
  final List<String> keyEvents;
  final List<String> focusCharacterIds;
  final Map<String, Object?> metadata;
}
