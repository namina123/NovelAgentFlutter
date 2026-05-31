import 'book_deconstruction_source_range_hint.dart';

class BookDeconstructionCoverageHint {
  const BookDeconstructionCoverageHint({
    this.sourceLabel = '',
    this.sourcePaths = const <String>[],
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.isPartial = false,
    this.sourceRanges = const <BookDeconstructionSourceRangeHint>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String sourceLabel;
  final List<String> sourcePaths;
  final int chapterStart;
  final int chapterEnd;
  final bool isPartial;
  final List<BookDeconstructionSourceRangeHint> sourceRanges;
  final String notes;
  final Map<String, Object?> metadata;
}
