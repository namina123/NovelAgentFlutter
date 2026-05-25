import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_conflict_item.dart';
import 'bundle_import_preview.dart';
import 'bundle_import_preview_builder_service.dart';

class BundleConflictPreviewService {
  BundleConflictPreviewService({
    BundleImportPreviewBuilderService? previewBuilderService,
  }) : _previewBuilderService =
           previewBuilderService ?? const BundleImportPreviewBuilderService();

  final BundleImportPreviewBuilderService _previewBuilderService;

  BundleImportPreview previewEntries({
    required String bundleKind,
    required String title,
    required String description,
    required String entryKind,
    required List<JsonMap> incomingEntries,
    required List<JsonMap> existingEntries,
    required bool overwrite,
    required String Function(JsonMap entry) targetPathBuilder,
  }) {
    // 中文注释: 通用冲突预检层只对“同类条目按 id 是否冲突”负责，具体 bundle 再决定传什么条目和目标路径规则。
    final existingById = <String, JsonMap>{};
    for (final entry in existingEntries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isNotEmpty) {
        existingById[id] = ValueReaders.deepCopyMap(entry);
      }
    }
    final items = <BundleConflictItem>[];
    for (final incoming in incomingEntries) {
      final id = ValueReaders.stringValue(incoming['id']).trim();
      final displayName = ValueReaders.stringValue(
        incoming['display_name'],
        ValueReaders.stringValue(
          incoming['name'],
          ValueReaders.stringValue(incoming['title'], id),
        ),
      ).trim();
      if (id.isEmpty) {
        items.add(
          BundleConflictItem(
            entryKind: entryKind,
            entryId: '',
            displayName: displayName,
            targetPath: '',
            status: 'invalid',
            action: 'skip',
          ),
        );
        continue;
      }
      final existing = existingById[id] ?? const <String, Object?>{};
      final conflict = existing.isNotEmpty;
      items.add(
        BundleConflictItem(
          entryKind: entryKind,
          entryId: id,
          displayName: displayName.isEmpty ? id : displayName,
          targetPath: targetPathBuilder(incoming),
          status: conflict ? 'project_conflict' : 'new',
          action: conflict && !overwrite
              ? 'skip'
              : (conflict ? 'overwrite' : 'import'),
          changedFields: _changedFields(existing, incoming),
        ),
      );
    }
    return _previewBuilderService.buildPreview(
      bundleKind: bundleKind,
      title: title,
      description: description,
      items: items,
    );
  }

  List<String> _changedFields(JsonMap existing, JsonMap incoming) {
    if (existing.isEmpty) {
      return const <String>[];
    }
    final keys = <String>{...existing.keys, ...incoming.keys}.toList()..sort();
    final changed = <String>[];
    for (final key in keys) {
      if (const <String>{
        'relative_path',
        'project_relative_path',
        'entry_file_path',
        'updated_at',
        'created_at',
      }.contains(key)) {
        continue;
      }
      if (jsonEncode(existing[key]) != jsonEncode(incoming[key])) {
        changed.add(key);
      }
    }
    return changed;
  }
}
