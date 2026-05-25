import 'bundle_conflict_item.dart';
import 'bundle_import_preview.dart';

class BundleImportPreviewBuilderService {
  const BundleImportPreviewBuilderService();

  BundleImportPreview buildPreview({
    required String bundleKind,
    required String title,
    required String description,
    required List<BundleConflictItem> items,
  }) {
    // 中文注释: 预检摘要统计统一集中在这里，避免每种 bundle 预检服务各自重复维护计数字段。
    var newCount = 0;
    var conflictCount = 0;
    var overwriteCount = 0;
    var skippedCount = 0;
    var invalidCount = 0;
    for (final item in items) {
      switch (item.status) {
        case 'new':
          newCount += 1;
          break;
        case 'project_conflict':
          conflictCount += 1;
          break;
        case 'invalid':
          invalidCount += 1;
          break;
      }
      switch (item.action) {
        case 'overwrite':
          overwriteCount += 1;
          break;
        case 'skip':
          skippedCount += 1;
          break;
      }
    }
    return BundleImportPreview(
      bundleKind: bundleKind,
      title: title,
      description: description,
      items: items,
      totalCount: items.length,
      newCount: newCount,
      conflictCount: conflictCount,
      overwriteCount: overwriteCount,
      skippedCount: skippedCount,
      invalidCount: invalidCount,
    );
  }
}
