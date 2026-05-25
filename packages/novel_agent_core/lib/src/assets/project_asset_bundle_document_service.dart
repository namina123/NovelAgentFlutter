import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'foreshadow_record.dart';
import 'foreshadow_record_normalizer_service.dart';
import 'style_profile.dart';
import 'style_profile_normalizer_service.dart';

class ProjectAssetBundleDocumentService {
  ProjectAssetBundleDocumentService({
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
  }) : _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService();

  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;

  JsonMap buildBundle({
    required List<StyleProfile> styles,
    required List<ForeshadowRecord> foreshadows,
    String title = '',
    String description = '',
  }) {
    // 中文注释: 项目资产包和生态包分离，专门服务风格、伏笔等写作资产迁移。
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'novel_agent_project_asset_bundle',
      'title': title.trim().isEmpty ? 'NOVEL Agent 项目资产包' : title.trim(),
      'description': description.trim(),
      'styles': styles
          .map(_styleNormalizerService.toDocument)
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      'foreshadows': foreshadows
          .map(_foreshadowNormalizerService.toDocument)
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  String encodeBundle(JsonMap bundle) {
    return '${const JsonEncoder.withIndent('  ').convert(bundle)}\n';
  }

  JsonMap parseBundle(String content) {
    try {
      return ValueReaders.mapValue(jsonDecode(content));
    } catch (_) {
      return const <String, Object?>{};
    }
  }
}
