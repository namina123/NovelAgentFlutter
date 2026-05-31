import 'inspiration_workbench_preview_item_view_data.dart';

class InspirationWorkbenchPreviewSectionViewData {
  const InspirationWorkbenchPreviewSectionViewData({
    required this.id,
    required this.title,
    required this.emptyHint,
    required this.items,
  });

  final String id;
  final String title;
  final String emptyHint;
  final List<InspirationWorkbenchPreviewItemViewData> items;
}
