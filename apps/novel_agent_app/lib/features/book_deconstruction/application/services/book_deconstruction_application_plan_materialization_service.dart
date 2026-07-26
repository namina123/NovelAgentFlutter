import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionApplicationPlanMaterializationService {
  BookDeconstructionApplicationPlanMaterializationService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    StyleProfileMarkdownCodecService? styleCodecService,
    CharacterProfileMarkdownCodecService? characterCodecService,
    OrganizationProfileMarkdownCodecService? organizationCodecService,
    ForeshadowRecordMarkdownCodecService? foreshadowCodecService,
    TimelineRecordMarkdownCodecService? timelineCodecService,
    RelationshipRecordMarkdownCodecService? relationshipCodecService,
    FrontmatterYamlWriterService? yamlWriterService,
    BookDeconstructionAssetMappingService? assetMappingService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _styleCodecService =
           styleCodecService ?? StyleProfileMarkdownCodecService(),
       _characterCodecService =
           characterCodecService ?? CharacterProfileMarkdownCodecService(),
       _organizationCodecService =
           organizationCodecService ??
           OrganizationProfileMarkdownCodecService(),
       _foreshadowCodecService =
           foreshadowCodecService ?? ForeshadowRecordMarkdownCodecService(),
       _timelineCodecService =
           timelineCodecService ?? TimelineRecordMarkdownCodecService(),
       _relationshipCodecService =
           relationshipCodecService ?? RelationshipRecordMarkdownCodecService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService(),
       _assetMappingService =
           assetMappingService ?? const BookDeconstructionAssetMappingService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final StyleProfileMarkdownCodecService _styleCodecService;
  final CharacterProfileMarkdownCodecService _characterCodecService;
  final OrganizationProfileMarkdownCodecService _organizationCodecService;
  final ForeshadowRecordMarkdownCodecService _foreshadowCodecService;
  final TimelineRecordMarkdownCodecService _timelineCodecService;
  final RelationshipRecordMarkdownCodecService _relationshipCodecService;
  final FrontmatterYamlWriterService _yamlWriterService;
  final BookDeconstructionAssetMappingService _assetMappingService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<List<String>> materialize({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
  }) async {
    final changedPaths = <String>[];
    // 预演可能在项目类型转换前构建，不能相信它当时默认的 Markdown 路径。
    // 物化时以当前项目的存储策略重新推导一次，让 SQLite 投影与主事实源使用同一 identity。
    final storageAwarePaths = <String, String>{
      for (final item in _assetMappingService.map(
        buildResult.extractionResult,
        storageStrategy: project.storageStrategy,
      ))
        item.id: item.relativePathHint,
    };
    for (final item in buildResult.applicationPlan.items) {
      if (!selectedItemIds.contains(item.id)) {
        continue;
      }
      final relativePath = (storageAwarePaths[item.id] ?? item.relativePathHint)
          .trim();
      if (relativePath.isEmpty) {
        continue;
      }
      final content = _contentFor(buildResult: buildResult, item: item);
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: relativePath,
        documentKind: _documentKindFor(item.sourceKind),
        title: item.displayName,
        content: content,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: content,
      );
      changedPaths.add(relativePath);
    }
    return changedPaths;
  }

  String _documentKindFor(String sourceKind) {
    switch (sourceKind) {
      case BookDeconstructionArtifactKind.premise:
        return 'premise';
      case BookDeconstructionArtifactKind.storyOutline:
        return 'outline';
      case BookDeconstructionArtifactKind.chapterOutline:
        return 'chapter_outline';
      case BookDeconstructionArtifactKind.styleProfile:
        return 'style';
      case BookDeconstructionArtifactKind.worldRuleSet:
        return 'setting';
      case BookDeconstructionArtifactKind.characterProfile:
        return 'character';
      case BookDeconstructionArtifactKind.organizationProfile:
        return 'organization_profile';
      case BookDeconstructionArtifactKind.foreshadowRecord:
        return 'foreshadow_record';
      case BookDeconstructionArtifactKind.timelineRecord:
        return 'timeline_record';
      case BookDeconstructionArtifactKind.relationshipRecord:
        return 'relationship_record';
      default:
        return sourceKind.trim();
    }
  }

  String _contentFor({
    required BookDeconstructionDraftBuildResult buildResult,
    required BookDeconstructionApplicationItem item,
  }) {
    switch (item.sourceKind) {
      case BookDeconstructionArtifactKind.premise:
        return _encodePremise(
          _premiseOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.storyOutline:
        return _encodeStoryOutline(buildResult.extractionResult);
      case BookDeconstructionArtifactKind.chapterOutline:
        return _encodeChapterOutline(
          _chapterOutlineOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.styleProfile:
        return _styleCodecService.encode(
          _styleProfileOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.worldRuleSet:
        return _encodeWorldRuleSet(
          _worldRuleSetOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.characterProfile:
        return _characterCodecService.encode(
          _characterProfileOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.organizationProfile:
        return _organizationCodecService.encode(
          _organizationProfileOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.foreshadowRecord:
        return _foreshadowCodecService.encode(
          _foreshadowRecordOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.timelineRecord:
        return _timelineCodecService.encode(
          _timelineRecordOf(buildResult.extractionResult, item.sourceId),
        );
      case BookDeconstructionArtifactKind.relationshipRecord:
        return _relationshipCodecService.encode(
          _relationshipRecordOf(buildResult.extractionResult, item.sourceId),
        );
      default:
        throw StateError('未支持的拆书应用条目类型：${item.sourceKind}');
    }
  }

  String _encodePremise(InspirationPremise premise) {
    final frontmatter = <String, Object?>{
      'id': premise.id,
      'display_name': premise.displayName,
      'core_promise': premise.corePromise,
      'main_conflict': premise.mainConflict,
      'boundaries': premise.boundaries,
      'source_path': premise.sourcePath,
      'metadata': premise.metadata,
    };
    final lines = <String>[
      '---',
      _yamlWriterService.write(frontmatter),
      '---',
      '',
      '# ${premise.displayName}',
      '',
      premise.summary.trim().isEmpty ? '请补充前提摘要。' : premise.summary.trim(),
    ];
    final cleanPromise = premise.corePromise.trim();
    if (cleanPromise.isNotEmpty) {
      lines.addAll(<String>['', '## 核心承诺', '', cleanPromise]);
    }
    final cleanConflict = premise.mainConflict.trim();
    if (cleanConflict.isNotEmpty) {
      lines.addAll(<String>['', '## 主要冲突', '', cleanConflict]);
    }
    if (premise.boundaries.isNotEmpty) {
      lines.addAll(<String>[
        '',
        '## 边界',
        '',
        ...premise.boundaries.map((item) => '- $item'),
      ]);
    }
    return '${lines.join('\n').trim()}\n';
  }

  String _encodeStoryOutline(BookDeconstructionExtractionResult extraction) {
    final summary = extraction.storyOutlineSummary.trim();
    return '# 拆书故事总纲\n\n${summary.isEmpty ? '请补充故事总纲。' : summary}\n';
  }

  String _encodeChapterOutline(BookDeconstructionChapterOutline outline) {
    final frontmatter = <String, Object?>{
      'id': outline.id,
      'title': outline.title,
      'sequence': outline.sequence,
      'focus_character_ids': outline.focusCharacterIds,
      'metadata': outline.metadata,
    };
    final lines = <String>[
      '---',
      _yamlWriterService.write(frontmatter),
      '---',
      '',
      '# ${outline.title}',
      '',
      outline.summary.trim().isEmpty ? '请补充章纲摘要。' : outline.summary.trim(),
    ];
    if (outline.keyEvents.isNotEmpty) {
      lines.addAll(<String>[
        '',
        '## 关键事件',
        '',
        ...outline.keyEvents.map((item) => '- $item'),
      ]);
    }
    if (outline.focusCharacterIds.isNotEmpty) {
      lines.addAll(<String>[
        '',
        '## 视角 / 重点角色',
        '',
        ...outline.focusCharacterIds.map((item) => '- $item'),
      ]);
    }
    return '${lines.join('\n').trim()}\n';
  }

  String _encodeWorldRuleSet(WorldRuleSet ruleSet) {
    final frontmatter = <String, Object?>{
      'id': ruleSet.id,
      'display_name': ruleSet.displayName,
      'rules': ruleSet.rules,
      'forbidden_assumptions': ruleSet.forbiddenAssumptions,
    };
    final lines = <String>[
      '---',
      _yamlWriterService.write(frontmatter),
      '---',
      '',
      '# ${ruleSet.displayName}',
      '',
      ruleSet.summary.trim().isEmpty ? '请补充世界规则摘要。' : ruleSet.summary.trim(),
    ];
    if (ruleSet.rules.isNotEmpty) {
      lines.addAll(<String>[
        '',
        '## 规则',
        '',
        ...ruleSet.rules.map((item) => '- $item'),
      ]);
    }
    if (ruleSet.forbiddenAssumptions.isNotEmpty) {
      lines.addAll(<String>[
        '',
        '## 禁止假设',
        '',
        ...ruleSet.forbiddenAssumptions.map((item) => '- $item'),
      ]);
    }
    return '${lines.join('\n').trim()}\n';
  }

  InspirationPremise _premiseOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final premise in extraction.premises) {
      if (premise.id == sourceId) {
        return premise;
      }
    }
    throw StateError('未找到拆书前提：$sourceId');
  }

  BookDeconstructionChapterOutline _chapterOutlineOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final outline in extraction.chapterOutlines) {
      if (outline.id == sourceId) {
        return outline;
      }
    }
    throw StateError('未找到拆书章纲：$sourceId');
  }

  StyleProfile _styleProfileOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final profile in extraction.styleProfiles) {
      if (profile.id == sourceId) {
        return profile;
      }
    }
    throw StateError('未找到拆书风格资产：$sourceId');
  }

  WorldRuleSet _worldRuleSetOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.worldRuleSets) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书世界规则：$sourceId');
  }

  CharacterProfile _characterProfileOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.characterProfiles) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书角色资产：$sourceId');
  }

  OrganizationProfile _organizationProfileOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.organizationProfiles) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书组织资产：$sourceId');
  }

  ForeshadowRecord _foreshadowRecordOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.foreshadowRecords) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书伏笔资产：$sourceId');
  }

  TimelineRecord _timelineRecordOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.timelineRecords) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书时间线资产：$sourceId');
  }

  RelationshipRecord _relationshipRecordOf(
    BookDeconstructionExtractionResult extraction,
    String sourceId,
  ) {
    for (final item in extraction.relationshipRecords) {
      if (item.id == sourceId) {
        return item;
      }
    }
    throw StateError('未找到拆书关系资产：$sourceId');
  }
}
