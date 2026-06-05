import 'book_deconstruction_asset_status_view_data.dart';
import 'book_deconstruction_followup_route_view_data.dart';

class BookDeconstructionInformationBridgeViewData {
  const BookDeconstructionInformationBridgeViewData({
    required this.summary,
    required this.followupRoutes,
    required this.assetStatuses,
    required this.reuseSummary,
  });

  final String summary;
  final List<BookDeconstructionFollowupRouteViewData> followupRoutes;
  final List<BookDeconstructionAssetStatusViewData> assetStatuses;
  final String reuseSummary;
}
