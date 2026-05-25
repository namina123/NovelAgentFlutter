import 'dart:convert';

import '../assets/character_profile.dart';
import '../assets/character_profile_normalizer_service.dart';
import '../assets/organization_profile.dart';
import '../assets/organization_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_header_builder_service.dart';
import 'bundle_kind.dart';
import 'bundle_validation_result.dart';
import 'bundle_validation_service.dart';

class CharacterCardBundleDocumentService {
  CharacterCardBundleDocumentService({
    CharacterProfileNormalizerService? characterNormalizerService,
    OrganizationProfileNormalizerService? organizationNormalizerService,
    BundleHeaderBuilderService? headerBuilderService,
    BundleValidationService? validationService,
  }) : _characterNormalizerService =
           characterNormalizerService ??
           const CharacterProfileNormalizerService(),
       _organizationNormalizerService =
           organizationNormalizerService ??
           const OrganizationProfileNormalizerService(),
       _headerBuilderService =
           headerBuilderService ?? BundleHeaderBuilderService(),
       _validationService = validationService ?? BundleValidationService();

  final CharacterProfileNormalizerService _characterNormalizerService;
  final OrganizationProfileNormalizerService _organizationNormalizerService;
  final BundleHeaderBuilderService _headerBuilderService;
  final BundleValidationService _validationService;

  JsonMap buildBundle({
    required List<CharacterProfile> characters,
    required List<OrganizationProfile> organizations,
    String title = '',
    String description = '',
    String bundleVersion = '1.0.0',
    String createdAt = '',
  }) {
    // 中文注释: 角色卡包先把角色和其关联组织一起打包，满足“角色资产可迁移”，但不提前掺入项目级运行状态。
    return _headerBuilderService.attachHeader(
      bundleKind: BundleKind.characterCardBundle,
      title: title.trim().isEmpty ? 'NOVEL Agent 角色卡包' : title.trim(),
      description: description,
      bundleVersion: bundleVersion,
      createdAt: createdAt.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt.trim(),
      payload: <String, Object?>{
        'characters': characters
            .map(_characterNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'organizations': organizations
            .map(_organizationNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
      },
    );
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

  BundleValidationResult validateBundle(String content) {
    final bundle = parseBundle(content);
    if (bundle.isEmpty) {
      return const BundleValidationResult(ok: false);
    }
    return _validationService.validateBundle(
      bundle,
      expectedKind: BundleKind.characterCardBundle,
    );
  }
}
