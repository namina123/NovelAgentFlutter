import 'bundle_conflict_item.dart';

class BundleImportPreview {
  const BundleImportPreview({
    required this.bundleKind,
    required this.title,
    required this.description,
    required this.items,
    required this.totalCount,
    required this.newCount,
    required this.conflictCount,
    required this.overwriteCount,
    required this.skippedCount,
    required this.invalidCount,
  });

  final String bundleKind;
  final String title;
  final String description;
  final List<BundleConflictItem> items;
  final int totalCount;
  final int newCount;
  final int conflictCount;
  final int overwriteCount;
  final int skippedCount;
  final int invalidCount;
}
