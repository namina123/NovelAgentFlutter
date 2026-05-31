import '../continuity/continuation_scope.dart';
import 'book_deconstruction_hint_source_kind.dart';

class BookDeconstructionScopeHint {
  const BookDeconstructionScopeHint({
    required this.id,
    required this.displayName,
    this.scopeKind = ContinuationScopeKind.custom,
    this.parentScopeId = '',
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.sourcePaths = const <String>[],
    this.sourceKind = BookDeconstructionHintSourceKind.sourceFact,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final ContinuationScopeKind scopeKind;
  final String parentScopeId;
  final int chapterStart;
  final int chapterEnd;
  final List<String> sourcePaths;
  final BookDeconstructionHintSourceKind sourceKind;
  final String notes;
  final Map<String, Object?> metadata;
}
