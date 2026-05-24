import 'dart:convert';

import 'customization_root_catalog_service.dart';

class CustomizationIndexDocumentService {
  CustomizationIndexDocumentService({
    CustomizationRootCatalogService? rootCatalogService,
  }) : _rootCatalogService =
           rootCatalogService ?? const CustomizationRootCatalogService();

  final CustomizationRootCatalogService _rootCatalogService;

  String buildIndexDocument(String root) {
    // 中文注释: 自定义生态索引统一在这里生成，保证创建项目、导入生态和手动重建索引使用同一结构。
    for (final descriptor in _rootCatalogService.roots()) {
      if (descriptor['root'] != root) {
        continue;
      }
      return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema_version': 1,
        'root': descriptor['root'],
        'package_layout':
            '${descriptor['root']}/<id>/${descriptor['entry_file']}',
        'entry_files': <String>[
          descriptor['entry_file'] ?? 'entry.json',
          descriptor['legacy_file'] ?? 'entry.json',
        ],
        'legacy_layout': '${descriptor['root']}/<id>.json',
        'description': descriptor['description'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema_version': 1,
      'root': root,
      'package_layout': '$root/<id>/entry.json',
      'entry_files': const <String>['entry.json'],
      'legacy_layout': '$root/<id>.json',
      'description': '',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
