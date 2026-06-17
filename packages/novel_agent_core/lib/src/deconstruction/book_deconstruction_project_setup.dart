import 'book_deconstruction_continuation_direction.dart';

class BookDeconstructionProjectSetup {
  const BookDeconstructionProjectSetup({
    this.followupRouteId = 'continuation',
    this.preferredFollowupOptionId = 'continuation_novel',
    this.preferredContinuationDirection =
        BookDeconstructionContinuationDirection.generalNovelPreferred,
    this.schemaVersion = 1,
  });

  final String followupRouteId;
  final String preferredFollowupOptionId;
  final BookDeconstructionContinuationDirection preferredContinuationDirection;
  final int schemaVersion;

  static const BookDeconstructionProjectSetup initial =
      BookDeconstructionProjectSetup();

  BookDeconstructionProjectSetup copyWith({
    String? followupRouteId,
    String? preferredFollowupOptionId,
    BookDeconstructionContinuationDirection? preferredContinuationDirection,
    int? schemaVersion,
  }) {
    return BookDeconstructionProjectSetup(
      followupRouteId: followupRouteId ?? this.followupRouteId,
      preferredFollowupOptionId:
          preferredFollowupOptionId ?? this.preferredFollowupOptionId,
      preferredContinuationDirection:
          preferredContinuationDirection ??
          this.preferredContinuationDirection,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
