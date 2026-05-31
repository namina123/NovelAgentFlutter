import 'book_deconstruction_hint_source_kind.dart';

class BookDeconstructionSourceRangeHint {
  const BookDeconstructionSourceRangeHint({
    required this.id,
    required this.displayName,
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.sourcePaths = const <String>[],
    this.sourceKind = BookDeconstructionHintSourceKind.sourceFact,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final int chapterStart;
  final int chapterEnd;
  final List<String> sourcePaths;
  final BookDeconstructionHintSourceKind sourceKind;
  final String notes;
  final Map<String, Object?> metadata;
}
