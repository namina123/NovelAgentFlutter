import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../customization/customization_bundle_import_preview_service.dart';

class PreviewCustomizationBundleImportUseCase {
  PreviewCustomizationBundleImportUseCase({
    CustomizationBundleImportPreviewService? previewService,
  }) : _previewService =
           previewService ?? CustomizationBundleImportPreviewService();

  final CustomizationBundleImportPreviewService _previewService;

  JsonMap execute({
    required String bundleContent,
    bool overwrite = true,
    bool allowBuiltinShadow = true,
    List<JsonMap> projectAgents = const <JsonMap>[],
    List<JsonMap> projectSkills = const <JsonMap>[],
    List<JsonMap> projectSkillGroups = const <JsonMap>[],
    List<JsonMap> projectAgentGroups = const <JsonMap>[],
    List<JsonMap> builtinAgents = const <JsonMap>[],
    List<JsonMap> builtinSkills = const <JsonMap>[],
    List<JsonMap> builtinSkillGroups = const <JsonMap>[],
    List<JsonMap> builtinAgentGroups = const <JsonMap>[],
  }) {
    // 中文注释: 预览用例只负责把 bundle 文本转为结构化预检结果，不承担写盘职责。
    final bundle = _parseBundle(bundleContent);
    if (bundle.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '生态包内容无效。',
        'items': const <Object?>[],
        'summary': const <String, Object?>{},
      };
    }
    return _previewService.previewBundle(
      bundle: bundle,
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      projectAgents: projectAgents,
      projectSkills: projectSkills,
      projectSkillGroups: projectSkillGroups,
      projectAgentGroups: projectAgentGroups,
      builtinAgents: builtinAgents,
      builtinSkills: builtinSkills,
      builtinSkillGroups: builtinSkillGroups,
      builtinAgentGroups: builtinAgentGroups,
    );
  }

  JsonMap _parseBundle(String bundleContent) {
    try {
      return ValueReaders.mapValue(jsonDecode(bundleContent));
    } catch (_) {
      return const <String, Object?>{};
    }
  }
}
