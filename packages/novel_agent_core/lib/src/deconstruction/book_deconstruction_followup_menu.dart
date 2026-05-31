import '../continuity/continuity_build_spec.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_followup_group.dart';

class BookDeconstructionFollowupMenu {
  const BookDeconstructionFollowupMenu({
    required this.preferredDirection,
    this.groups = const <BookDeconstructionFollowupGroup>[],
    this.highlightedGroupId = '',
    this.highlightedOptionId = '',
    this.highlightedBuildTier = ContinuityBuildTier.standardFoundation,
    this.allowsMultipleDerivedProjects = true,
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final BookDeconstructionContinuationDirection preferredDirection;
  final List<BookDeconstructionFollowupGroup> groups;
  final String highlightedGroupId;
  final String highlightedOptionId;
  final ContinuityBuildTier highlightedBuildTier;
  final bool allowsMultipleDerivedProjects;
  final String notes;
  final Map<String, Object?> metadata;
}
