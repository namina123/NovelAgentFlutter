import '../continuity/continuity_mechanic_profile.dart';
import 'book_deconstruction_hint_source_kind.dart';

class BookDeconstructionMechanicHint {
  const BookDeconstructionMechanicHint({
    required this.id,
    required this.displayName,
    this.scopeHintId = '',
    this.identityModeHint,
    this.memoryModeHint,
    this.stateModeHint,
    this.causalModeHint,
    this.branchModeHint,
    this.visibilityModeHint,
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.sourcePaths = const <String>[],
    this.sourceKind = BookDeconstructionHintSourceKind.inferredHint,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String scopeHintId;
  final ContinuityIdentityMode? identityModeHint;
  final ContinuityMemoryMode? memoryModeHint;
  final ContinuityStateMode? stateModeHint;
  final ContinuityCausalMode? causalModeHint;
  final ContinuityBranchMode? branchModeHint;
  final ContinuityVisibilityMode? visibilityModeHint;
  final int chapterStart;
  final int chapterEnd;
  final List<String> sourcePaths;
  final BookDeconstructionHintSourceKind sourceKind;
  final String notes;
  final Map<String, Object?> metadata;
}
