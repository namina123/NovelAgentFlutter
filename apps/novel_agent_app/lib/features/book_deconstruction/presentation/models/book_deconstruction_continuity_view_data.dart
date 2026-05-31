import 'book_deconstruction_followup_group_view_data.dart';

class BookDeconstructionContinuityViewData {
  const BookDeconstructionContinuityViewData({
    required this.preferredDirectionLabel,
    required this.highlightedBuildTierLabel,
    required this.highlightedRouteTitle,
    required this.scopeHintCount,
    required this.identityMappingCount,
    required this.mechanicHintCount,
    required this.followupGroups,
    required this.summary,
  });

  final String preferredDirectionLabel;
  final String highlightedBuildTierLabel;
  final String highlightedRouteTitle;
  final int scopeHintCount;
  final int identityMappingCount;
  final int mechanicHintCount;
  final List<BookDeconstructionFollowupGroupViewData> followupGroups;
  final String summary;
}
