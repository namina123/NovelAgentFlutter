import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'knowledge_base_branch_catalog_service.dart';
import 'project_manifest.dart';
import 'project_runtime_baseline_catalog_service.dart';
import 'project_storage_strategy.dart';
import 'project_type_catalog_service.dart';

class ProjectManifestCodecService {
  ProjectManifestCodecService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    ProjectRuntimeBaselineCatalogService? projectRuntimeBaselineCatalogService,
    KnowledgeBaseBranchCatalogService? knowledgeBaseBranchCatalogService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _projectRuntimeBaselineCatalogService =
           projectRuntimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService(),
       _knowledgeBaseBranchCatalogService =
           knowledgeBaseBranchCatalogService ??
           const KnowledgeBaseBranchCatalogService();

  static const String manifestRelativePath =
      '.novel_agent/project_manifest.json';
  static const int currentSchemaVersion = 1;

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final ProjectRuntimeBaselineCatalogService
  _projectRuntimeBaselineCatalogService;
  final KnowledgeBaseBranchCatalogService _knowledgeBaseBranchCatalogService;

  ProjectManifest create({
    required String title,
    required String projectType,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String projectBranchId = '',
    String runtimeBaselineId = '',
    List<String> additionalTraitIds = const <String>[],
  }) {
    // 中文注释: 新建 manifest 时在这里统一补齐标题和项目类型，避免不同创建入口写出不同结构。
    final normalizedType = _projectTypeCatalogService.normalize(projectType);
    final cleanTitle = title.trim().isEmpty
        ? _projectTypeCatalogService.defaultTitle(normalizedType)
        : title.trim();
    final normalizedStorageStrategy = _normalizeStorageStrategy(
      normalizedType,
      storageStrategy,
    );
    final normalizedRuntimeBaselineId = _projectRuntimeBaselineCatalogService
        .normalizeForProjectType(normalizedType, runtimeBaselineId);
    final normalizedProjectBranchId = _knowledgeBaseBranchCatalogService
        .normalize(normalizedType, projectBranchId);
    return ProjectManifest(
      title: cleanTitle,
      projectType: normalizedType,
      storageStrategy: normalizedStorageStrategy,
      projectBranchId: normalizedProjectBranchId,
      runtimeBaselineId: normalizedRuntimeBaselineId,
      additionalTraitIds: _normalizeAdditionalTraitIds(additionalTraitIds),
    );
  }

  ProjectManifest parse(
    String source, {
    String fallbackTitle = '',
    String fallbackProjectType = 'novel',
    ProjectStorageStrategy fallbackStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String fallbackProjectBranchId = '',
    String fallbackRuntimeBaselineId = '',
    List<String> fallbackAdditionalTraitIds = const <String>[],
  }) {
    // 中文注释: 此宽容入口只适用于已持有 descriptor 的更新/恢复路径；冷启动必须使用
    // tryParseStrict，不能把损坏 manifest 静默降级成一个可写的普通小说。
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return create(
        title: fallbackTitle,
        projectType: fallbackProjectType,
        storageStrategy: fallbackStorageStrategy,
        projectBranchId: fallbackProjectBranchId,
        runtimeBaselineId: fallbackRuntimeBaselineId,
        additionalTraitIds: fallbackAdditionalTraitIds,
      );
    }
    try {
      final parsed = jsonDecode(cleanSource);
      if (parsed is! Map<Object?, Object?>) {
        return create(
          title: fallbackTitle,
          projectType: fallbackProjectType,
          storageStrategy: fallbackStorageStrategy,
          projectBranchId: fallbackProjectBranchId,
          runtimeBaselineId: fallbackRuntimeBaselineId,
          additionalTraitIds: fallbackAdditionalTraitIds,
        );
      }
      return fromJson(
        Map<String, Object?>.from(parsed),
        fallbackTitle: fallbackTitle,
        fallbackProjectType: fallbackProjectType,
        fallbackStorageStrategy: fallbackStorageStrategy,
        fallbackProjectBranchId: fallbackProjectBranchId,
        fallbackRuntimeBaselineId: fallbackRuntimeBaselineId,
        fallbackAdditionalTraitIds: fallbackAdditionalTraitIds,
      );
    } catch (_) {
      return create(
        title: fallbackTitle,
        projectType: fallbackProjectType,
        storageStrategy: fallbackStorageStrategy,
        projectBranchId: fallbackProjectBranchId,
        runtimeBaselineId: fallbackRuntimeBaselineId,
        additionalTraitIds: fallbackAdditionalTraitIds,
      );
    }
  }

  /// Parses only a complete, known project contract.
  ///
  /// This is the cold-open boundary. It accepts legacy omitted fields, but a
  /// malformed document, unknown type/strategy/baseline, or invalid knowledge
  /// branch returns null rather than inventing a writable fallback project.
  ProjectManifest? tryParseStrict(
    String source, {
    String fallbackTitle = '',
    String fallbackProjectType = 'novel',
    ProjectStorageStrategy fallbackStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String fallbackProjectBranchId = '',
    String fallbackRuntimeBaselineId = '',
    List<String> fallbackAdditionalTraitIds = const <String>[],
  }) {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(cleanSource);
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      final json = Map<String, Object?>.from(decoded);
      if (!_hasKnownContractFields(
        json,
        fallbackProjectType: fallbackProjectType,
      )) {
        return null;
      }
      return fromJson(
        json,
        fallbackTitle: fallbackTitle,
        fallbackProjectType: fallbackProjectType,
        fallbackStorageStrategy: fallbackStorageStrategy,
        fallbackProjectBranchId: fallbackProjectBranchId,
        fallbackRuntimeBaselineId: fallbackRuntimeBaselineId,
        fallbackAdditionalTraitIds: fallbackAdditionalTraitIds,
      );
    } catch (_) {
      return null;
    }
  }

  ProjectManifest fromJson(
    JsonMap json, {
    String fallbackTitle = '',
    String fallbackProjectType = 'novel',
    ProjectStorageStrategy fallbackStorageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String fallbackProjectBranchId = '',
    String fallbackRuntimeBaselineId = '',
    List<String> fallbackAdditionalTraitIds = const <String>[],
  }) {
    // 中文注释: JSON 到 manifest 的转换保持纯规则，方便仓储、测试和未来迁移脚本共用。
    final fallbackType = _projectTypeCatalogService.normalize(
      fallbackProjectType,
    );
    final rawProjectType = ValueReaders.stringValue(
      json['project_type'],
    ).trim();
    final normalizedType =
        rawProjectType.isEmpty ||
            !_projectTypeCatalogService.contains(rawProjectType)
        ? fallbackType
        : rawProjectType;
    final title = ValueReaders.stringValue(
      json['title'],
      fallbackTitle.trim().isEmpty
          ? _projectTypeCatalogService.defaultTitle(normalizedType)
          : fallbackTitle.trim(),
    );
    final rawStorageStrategyId = ValueReaders.stringValue(
      json['storage_strategy'],
    ).trim();
    final rawStorageStrategy = rawStorageStrategyId.isEmpty
        ? fallbackStorageStrategy
        : ProjectStorageStrategy.tryFromId(rawStorageStrategyId) ??
              fallbackStorageStrategy;
    // 中文注释: 重开路径也必须遵守类型的存储合同；旧文件或手工编辑不能把 SQLite-only
    // 知识库重新带回 Markdown 主存储。
    final storageStrategy = _normalizeStorageStrategy(
      normalizedType,
      rawStorageStrategy,
    );
    final fallbackRuntimeBaseline = _projectRuntimeBaselineCatalogService
        .normalizeForProjectType(normalizedType, fallbackRuntimeBaselineId);
    final hasRuntimeBaselineValue =
        json.containsKey('runtime_baseline_id') &&
        json['runtime_baseline_id'] != null;
    final rawRuntimeBaselineId = ValueReaders.stringValue(
      json['runtime_baseline_id'],
    ).trim();
    final runtimeBaselineId = !hasRuntimeBaselineValue
        ? fallbackRuntimeBaseline
        : rawRuntimeBaselineId.isEmpty
        ? fallbackRuntimeBaseline
        : _projectRuntimeBaselineCatalogService.containsForProjectType(
            normalizedType,
            rawRuntimeBaselineId,
          )
        ? rawRuntimeBaselineId
        : fallbackRuntimeBaseline;
    final fallbackProjectBranch = _knowledgeBaseBranchCatalogService.normalize(
      normalizedType,
      fallbackProjectBranchId,
    );
    final hasProjectBranchValue =
        json.containsKey('project_branch_id') &&
        json['project_branch_id'] != null;
    final rawProjectBranchId = ValueReaders.stringValue(
      json['project_branch_id'],
    ).trim();
    final projectBranchId =
        !_knowledgeBaseBranchCatalogService.usesBranchSelection(normalizedType)
        ? ''
        : !hasProjectBranchValue
        ? fallbackProjectBranch
        : rawProjectBranchId.isEmpty
        ? fallbackProjectBranch
        : _knowledgeBaseBranchCatalogService.contains(rawProjectBranchId)
        ? rawProjectBranchId
        : fallbackProjectBranch;
    // 中文注释: additional_trait_ids 是可选追加字段（复合项目类型保留拆书能力用）；
    // 旧 manifest 没有该 key 时读出空列表，行为等同升级前，无需迁移。
    final rawTraitIds = json['additional_trait_ids'];
    final additionalTraitIds = rawTraitIds is List
        ? _normalizeAdditionalTraitIds(rawTraitIds)
        : _normalizeAdditionalTraitIds(fallbackAdditionalTraitIds);
    return ProjectManifest(
      title: title.trim().isEmpty
          ? _projectTypeCatalogService.defaultTitle(normalizedType)
          : title.trim(),
      projectType: normalizedType,
      storageStrategy: storageStrategy,
      projectBranchId: projectBranchId,
      runtimeBaselineId: runtimeBaselineId,
      schemaVersion: ValueReaders.intValue(
        json['schema_version'],
        currentSchemaVersion,
      ),
      additionalTraitIds: additionalTraitIds,
    );
  }

  JsonMap toJson(ProjectManifest manifest) {
    // 中文注释: manifest 输出结构固定在这里，避免不同模块写出字段名不一致的项目描述文件。
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      manifest.projectType,
    );
    final normalizedStorageStrategy = _normalizeStorageStrategy(
      normalizedProjectType,
      manifest.storageStrategy,
    );
    return <String, Object?>{
      // Only the current schema is supported by strict cold-open. Do not let a
      // manually constructed manifest write a version this build cannot reopen.
      'schema_version': currentSchemaVersion,
      'title': manifest.title,
      'project_type': normalizedProjectType,
      'storage_strategy': normalizedStorageStrategy.id,
      'project_branch_id': _knowledgeBaseBranchCatalogService.normalize(
        normalizedProjectType,
        manifest.projectBranchId,
      ),
      'runtime_baseline_id': _projectRuntimeBaselineCatalogService
          .normalizeForProjectType(
            normalizedProjectType,
            manifest.runtimeBaselineId,
          ),
      'additional_trait_ids': _normalizeAdditionalTraitIds(
        manifest.additionalTraitIds,
      ),
    };
  }

  String encode(ProjectManifest manifest) {
    // 中文注释: 持久化格式统一使用可读缩进 JSON，方便用户和调试工具直接查看。
    return const JsonEncoder.withIndent('  ').convert(toJson(manifest));
  }

  bool _hasKnownContractFields(
    JsonMap json, {
    required String fallbackProjectType,
  }) {
    // A missing field is a supported legacy shape. A field that is present but
    // null, non-string, or blank is different: accepting it would make the
    // cold-open path invent a fallback contract and can demote the project.
    if (!_isOmittedOrNonEmptyString(json, 'project_type') ||
        !_isOmittedOrNonEmptyString(json, 'storage_strategy') ||
        !_isOmittedOrString(json, 'runtime_baseline_id') ||
        !_isOmittedOrString(json, 'project_branch_id')) {
      return false;
    }
    if (json.containsKey('schema_version') && json['schema_version'] is! int) {
      return false;
    }
    if (json.containsKey('schema_version') &&
        (json['schema_version'] as int) != currentSchemaVersion) {
      return false;
    }
    final fallbackType = _projectTypeCatalogService.normalize(
      fallbackProjectType,
    );
    final rawProjectType = ValueReaders.stringValue(
      json['project_type'],
    ).trim();
    if (rawProjectType.isNotEmpty &&
        !_projectTypeCatalogService.contains(rawProjectType)) {
      return false;
    }
    final projectType = rawProjectType.isEmpty ? fallbackType : rawProjectType;
    final rawStorageStrategyId = ValueReaders.stringValue(
      json['storage_strategy'],
    ).trim();
    if (rawStorageStrategyId.isNotEmpty) {
      final storageStrategy = ProjectStorageStrategy.tryFromId(
        rawStorageStrategyId,
      );
      if (storageStrategy == null ||
          !_isCompatibleStorageStrategy(projectType, storageStrategy)) {
        return false;
      }
    }
    final rawRuntimeBaselineId = ValueReaders.stringValue(
      json['runtime_baseline_id'],
    ).trim();
    if (rawRuntimeBaselineId.isNotEmpty &&
        !_projectRuntimeBaselineCatalogService.containsForProjectType(
          projectType,
          rawRuntimeBaselineId,
        )) {
      return false;
    }
    final rawProjectBranchId = ValueReaders.stringValue(
      json['project_branch_id'],
    ).trim();
    final usesBranchSelection = _knowledgeBaseBranchCatalogService
        .usesBranchSelection(projectType);
    if (!usesBranchSelection && rawProjectBranchId.isNotEmpty) {
      return false;
    }
    if (usesBranchSelection &&
        rawProjectBranchId.isNotEmpty &&
        !_knowledgeBaseBranchCatalogService.contains(rawProjectBranchId)) {
      return false;
    }
    if (json.containsKey('additional_trait_ids') &&
        json['additional_trait_ids'] is! List) {
      return false;
    }
    return true;
  }

  bool _isOmittedOrNonEmptyString(JsonMap json, String fieldName) {
    if (!json.containsKey(fieldName)) {
      return true;
    }
    final value = json[fieldName];
    return value is String && value.trim().isNotEmpty;
  }

  bool _isOmittedOrString(JsonMap json, String fieldName) {
    if (!json.containsKey(fieldName)) {
      return true;
    }
    return json[fieldName] is String;
  }

  bool _isCompatibleStorageStrategy(
    String projectType,
    ProjectStorageStrategy storageStrategy,
  ) {
    final definition = _projectTypeCatalogService.definitionOf(projectType);
    if (definition.supportedStorageStrategies.contains(storageStrategy)) {
      return true;
    }
    // Older knowledge-base manifests used Markdown before the type became
    // SQLite-only. It is the one intentional read-time normalization.
    return projectType == 'knowledge_base' &&
        storageStrategy == ProjectStorageStrategy.markdownProjectStore;
  }

  ProjectStorageStrategy _normalizeStorageStrategy(
    String projectType,
    ProjectStorageStrategy storageStrategy,
  ) {
    // 中文注释: manifest 创建阶段需要跟随项目类型收束存储策略，避免知识库等受限类型在 core 层写出错误组合。
    final definition = _projectTypeCatalogService.definitionOf(projectType);
    if (definition.supportedStorageStrategies.isEmpty) {
      return ProjectStorageStrategy.markdownProjectStore;
    }
    for (final supportedStrategy in definition.supportedStorageStrategies) {
      if (supportedStrategy == storageStrategy) {
        return supportedStrategy;
      }
    }
    return definition.supportedStorageStrategies.first;
  }

  List<String> _normalizeAdditionalTraitIds(Iterable<Object?> traitIds) {
    // 中文注释: trait 是能力合同而非展示列表；在所有 manifest 出入口去空、去重并保持
    // 首次出现顺序，避免手工编辑或不同写入入口制造等价但漂移的项目能力状态。
    final normalizedIds = <String>[];
    for (final rawTraitId in traitIds) {
      if (rawTraitId == null) {
        continue;
      }
      final traitId = rawTraitId.toString().trim();
      if (traitId.isNotEmpty && !normalizedIds.contains(traitId)) {
        normalizedIds.add(traitId);
      }
    }
    return List<String>.unmodifiable(normalizedIds);
  }
}
