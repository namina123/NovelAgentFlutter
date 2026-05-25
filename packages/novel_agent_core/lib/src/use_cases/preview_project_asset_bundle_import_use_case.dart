import '../assets/project_asset_bundle_document_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';

class PreviewProjectAssetBundleImportUseCase {
  PreviewProjectAssetBundleImportUseCase({
    ProjectAssetBundleDocumentService? bundleDocumentService,
  }) : _bundleDocumentService =
           bundleDocumentService ?? ProjectAssetBundleDocumentService();

  final ProjectAssetBundleDocumentService _bundleDocumentService;

  JsonMap execute({
    required String bundleContent,
    List<JsonMap> projectStyles = const <JsonMap>[],
    List<JsonMap> projectForeshadows = const <JsonMap>[],
    bool overwrite = false,
  }) {
    // 中文注释: 资产导入预检在 core 内统一判断冲突，让宿主层只负责展示和确认。
    final bundle = _bundleDocumentService.parseBundle(bundleContent);
    if (bundle.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'errors': <String>['资产包内容无效。'],
        'items': const <Object?>[],
      };
    }
    final styleIds = projectStyles
        .map((item) => ValueReaders.stringValue(item['id']).trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final foreshadowIds = projectForeshadows
        .map((item) => ValueReaders.stringValue(item['id']).trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final items = <JsonMap>[];
    for (final rawStyle in ValueReaders.mapList(bundle['styles'])) {
      final style = ValueReaders.mapValue(rawStyle);
      final id = ValueReaders.stringValue(style['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      final conflict = styleIds.contains(id);
      items.add(<String, Object?>{
        'kind': 'style',
        'id': id,
        'title': ValueReaders.stringValue(style['display_name'], id),
        'relative_path': 'styles/$id.style.md',
        'status': conflict ? 'project_conflict' : 'new',
        'action': conflict && !overwrite ? 'skip' : 'import',
      });
    }
    for (final rawRecord in ValueReaders.mapList(bundle['foreshadows'])) {
      final record = ValueReaders.mapValue(rawRecord);
      final id = ValueReaders.stringValue(record['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      final conflict = foreshadowIds.contains(id);
      items.add(<String, Object?>{
        'kind': 'foreshadow',
        'id': id,
        'title': ValueReaders.stringValue(record['title'], id),
        'relative_path': 'world/foreshadows/$id.foreshadow.md',
        'status': conflict ? 'project_conflict' : 'new',
        'action': conflict && !overwrite ? 'skip' : 'import',
      });
    }
    return <String, Object?>{
      'ok': true,
      'title': ValueReaders.stringValue(bundle['title']),
      'description': ValueReaders.stringValue(bundle['description']),
      'items': items,
    };
  }
}
