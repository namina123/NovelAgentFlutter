import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectBundlePreviewMapperService {
  const ProjectBundlePreviewMapperService();

  JsonMap toJson(BundleImportPreview preview) {
    return <String, Object?>{
      'bundle_kind': preview.bundleKind,
      'title': preview.title,
      'description': preview.description,
      'summary': <String, Object?>{
        'total': preview.totalCount,
        'new': preview.newCount,
        'conflicts': preview.conflictCount,
        'overwrite': preview.overwriteCount,
        'skipped': preview.skippedCount,
        'invalid': preview.invalidCount,
      },
      'items': preview.items
          .map(
            (item) => <String, Object?>{
              'entry_kind': item.entryKind,
              'entry_id': item.entryId,
              'display_name': item.displayName,
              'target_path': item.targetPath,
              'status': item.status,
              'action': item.action,
              'changed_fields': item.changedFields.toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }
}
