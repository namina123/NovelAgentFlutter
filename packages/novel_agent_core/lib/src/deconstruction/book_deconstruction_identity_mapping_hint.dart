import 'book_deconstruction_hint_source_kind.dart';

class BookDeconstructionIdentityMappingHint {
  const BookDeconstructionIdentityMappingHint({
    required this.id,
    required this.canonicalEntityId,
    required this.scopedEntityId,
    this.scopedDisplayName = '',
    this.scopeHintId = '',
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.sourcePaths = const <String>[],
    this.sourceKind = BookDeconstructionHintSourceKind.inferredHint,
    this.mappingReason = '',
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String canonicalEntityId;
  final String scopedEntityId;
  final String scopedDisplayName;
  final String scopeHintId;
  final int chapterStart;
  final int chapterEnd;
  final List<String> sourcePaths;
  final BookDeconstructionHintSourceKind sourceKind;
  final String mappingReason;
  final String notes;
  final Map<String, Object?> metadata;
}
