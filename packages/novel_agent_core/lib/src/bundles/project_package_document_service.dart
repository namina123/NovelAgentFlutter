import 'dart:convert';

import '../assets/character_profile.dart';
import '../assets/character_profile_normalizer_service.dart';
import '../assets/foreshadow_record.dart';
import '../assets/foreshadow_record_normalizer_service.dart';
import '../assets/organization_profile.dart';
import '../assets/organization_profile_normalizer_service.dart';
import '../assets/relationship_record.dart';
import '../assets/relationship_record_normalizer_service.dart';
import '../assets/style_profile.dart';
import '../assets/style_profile_normalizer_service.dart';
import '../assets/timeline_record.dart';
import '../assets/timeline_record_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../prompts/prompt_template_normalizer_service.dart';
import '../project/project_manifest.dart';
import '../project/project_manifest_codec_service.dart';
import '../project/project_runtime_profile.dart';
import '../project/project_runtime_profile_document_service.dart';
import 'bundle_header_builder_service.dart';
import 'bundle_kind.dart';
import 'bundle_validation_result.dart';
import 'bundle_validation_service.dart';

class ProjectPackageDocumentService {
  ProjectPackageDocumentService({
    ProjectManifestCodecService? manifestCodecService,
    ProjectRuntimeProfileDocumentService? runtimeProfileDocumentService,
    CharacterProfileNormalizerService? characterNormalizerService,
    OrganizationProfileNormalizerService? organizationNormalizerService,
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    RelationshipRecordNormalizerService? relationshipNormalizerService,
    TimelineRecordNormalizerService? timelineNormalizerService,
    PromptTemplateNormalizerService? templateNormalizerService,
    BundleHeaderBuilderService? headerBuilderService,
    BundleValidationService? validationService,
  }) : _manifestCodecService =
           manifestCodecService ?? ProjectManifestCodecService(),
       _runtimeProfileDocumentService =
           runtimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService(),
       _characterNormalizerService =
           characterNormalizerService ??
           const CharacterProfileNormalizerService(),
       _organizationNormalizerService =
           organizationNormalizerService ??
           const OrganizationProfileNormalizerService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _relationshipNormalizerService =
           relationshipNormalizerService ??
           const RelationshipRecordNormalizerService(),
       _timelineNormalizerService =
           timelineNormalizerService ?? const TimelineRecordNormalizerService(),
       _templateNormalizerService =
           templateNormalizerService ?? PromptTemplateNormalizerService(),
       _headerBuilderService =
           headerBuilderService ?? BundleHeaderBuilderService(),
       _validationService = validationService ?? BundleValidationService();

  final ProjectManifestCodecService _manifestCodecService;
  final ProjectRuntimeProfileDocumentService _runtimeProfileDocumentService;
  final CharacterProfileNormalizerService _characterNormalizerService;
  final OrganizationProfileNormalizerService _organizationNormalizerService;
  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final RelationshipRecordNormalizerService _relationshipNormalizerService;
  final TimelineRecordNormalizerService _timelineNormalizerService;
  final PromptTemplateNormalizerService _templateNormalizerService;
  final BundleHeaderBuilderService _headerBuilderService;
  final BundleValidationService _validationService;

  JsonMap buildBundle({
    required String projectId,
    required ProjectManifest manifest,
    required ProjectRuntimeProfile runtimeProfile,
    List<CharacterProfile> characters = const <CharacterProfile>[],
    List<OrganizationProfile> organizations = const <OrganizationProfile>[],
    List<StyleProfile> styles = const <StyleProfile>[],
    List<ForeshadowRecord> foreshadows = const <ForeshadowRecord>[],
    List<RelationshipRecord> relationships = const <RelationshipRecord>[],
    List<TimelineRecord> timelines = const <TimelineRecord>[],
    List<JsonMap> promptTemplates = const <JsonMap>[],
    String title = '',
    String description = '',
    String bundleVersion = '1.0.0',
    String createdAt = '',
  }) {
    // 中文注释: 项目包先立成“项目元数据 + 共享资产 + 模板”的统一合同，不提前决定最终是 zip 还是目录导出。
    return _headerBuilderService.attachHeader(
      bundleKind: BundleKind.projectPackage,
      title: title.trim().isEmpty ? manifest.title : title.trim(),
      description: description,
      bundleVersion: bundleVersion,
      createdAt: createdAt.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt.trim(),
      payload: <String, Object?>{
        'project': <String, Object?>{
          'project_id': projectId.trim(),
          'title': manifest.title,
          'project_type': manifest.projectType,
          'storage_strategy': manifest.storageStrategy.id,
          'runtime_baseline_id': manifest.runtimeBaselineId,
        },
        'project_manifest': _manifestCodecService.toJson(manifest),
        'runtime_profile': _runtimeProfileDocumentService.toJson(
          runtimeProfile,
        ),
        'characters': characters
            .map(_characterNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'organizations': organizations
            .map(_organizationNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'styles': styles
            .map(_styleNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'foreshadows': foreshadows
            .map(_foreshadowNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'relationships': relationships
            .map(_relationshipNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'timelines': timelines
            .map(_timelineNormalizerService.toDocument)
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
        'prompt_templates': promptTemplates
            .map(_templateNormalizerService.normalizeTemplate)
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
      expectedKind: BundleKind.projectPackage,
    );
  }
}
