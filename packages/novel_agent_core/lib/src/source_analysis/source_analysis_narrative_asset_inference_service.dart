import '../assets/character_profile.dart';
import '../assets/foreshadow_record.dart';
import '../assets/organization_profile.dart';
import '../assets/relationship_record.dart';
import '../assets/style_profile.dart';
import '../assets/timeline_record.dart';
import '../assets/world_rule_set.dart';
import 'source_analysis_chapter_summary.dart';
import 'source_analysis_entity_extractor_service.dart';
import 'source_analysis_outline_service.dart';
import 'source_analysis_style_metrics.dart';
import 'source_analysis_style_signal_service.dart';

class SourceAnalysisNarrativeAssetInferenceService {
  const SourceAnalysisNarrativeAssetInferenceService({
    SourceAnalysisEntityExtractorService entityExtractorService =
        const SourceAnalysisEntityExtractorService(),
    SourceAnalysisOutlineService outlineService =
        const SourceAnalysisOutlineService(),
    SourceAnalysisStyleSignalService styleSignalService =
        const SourceAnalysisStyleSignalService(),
  }) : _entityExtractorService = entityExtractorService,
       _outlineService = outlineService,
       _styleSignalService = styleSignalService;

  final SourceAnalysisEntityExtractorService _entityExtractorService;
  final SourceAnalysisOutlineService _outlineService;
  final SourceAnalysisStyleSignalService _styleSignalService;

  List<StyleProfile> styleProfilesOf(String styleSummary) {
    final cleanSummary = styleSummary.trim();
    if (cleanSummary.isNotEmpty) {
      return <StyleProfile>[
        StyleProfile(
          id: 'deconstruction_style',
          displayName: '拆书风格提要',
          summary: cleanSummary,
        ),
      ];
    }
    return const <StyleProfile>[];
  }

  List<WorldRuleSet> worldRuleSetsOf(String worldRulesText) {
    final rules = _lineValues(worldRulesText);
    if (rules.isEmpty) {
      return const <WorldRuleSet>[];
    }
    return <WorldRuleSet>[
      WorldRuleSet(
        id: 'world_rules',
        displayName: '世界规则提要',
        summary: rules.first,
        rules: rules,
      ),
    ];
  }

  List<CharacterProfile> characterProfilesOf(String characterLinesText) {
    return _lineValues(characterLinesText).asMap().entries.map((entry) {
      final parsed = _nameSummaryPair(entry.value);
      return CharacterProfile(
        id: _safeId(parsed.$1, fallback: 'character_${entry.key + 1}'),
        displayName: parsed.$1,
        summary: parsed.$2,
      );
    }).toList(growable: false);
  }

  List<OrganizationProfile> organizationProfilesOf(
    String organizationLinesText,
  ) {
    return _lineValues(organizationLinesText).asMap().entries.map((entry) {
      final parsed = _nameSummaryPair(entry.value);
      return OrganizationProfile(
        id: _safeId(parsed.$1, fallback: 'organization_${entry.key + 1}'),
        displayName: parsed.$1,
        summary: parsed.$2,
      );
    }).toList(growable: false);
  }

  List<CharacterProfile> inferCharacterProfilesFromSource(
    String sourceContent, {
    int maxCount = 24,
  }) {
    final counts = _entityExtractorService.extractHanCandidateCounts(
      sourceContent,
    );
    final picked = <CharacterProfile>[];
    for (final entry in counts.entries) {
      if (picked.length >= maxCount) {
        break;
      }
      final name = entry.key;
      if (!_looksLikeCharacterName(name)) {
        continue;
      }
      final summary = _surroundingSummary(sourceContent, name, maxLength: 90);
      picked.add(
        CharacterProfile(
          id: _safeId(name, fallback: 'character_${picked.length + 1}'),
          displayName: name,
          summary: summary,
          metadata: <String, Object?>{
            'inferred_from_source': true,
            'mention_count': entry.value,
          },
        ),
      );
    }
    return picked;
  }

  List<OrganizationProfile> inferOrganizationProfilesFromSource(
    String sourceContent, {
    int maxCount = 16,
  }) {
    final counts = _entityExtractorService.extractHanCandidateCounts(
      sourceContent,
    );
    final picked = <OrganizationProfile>[];
    for (final entry in counts.entries) {
      if (picked.length >= maxCount) {
        break;
      }
      final name = entry.key;
      if (!_looksLikeOrganizationName(name)) {
        continue;
      }
      final summary = _surroundingSummary(sourceContent, name, maxLength: 90);
      picked.add(
        OrganizationProfile(
          id: _safeId(name, fallback: 'organization_${picked.length + 1}'),
          displayName: name,
          summary: summary,
          metadata: <String, Object?>{
            'inferred_from_source': true,
            'mention_count': entry.value,
          },
        ),
      );
    }
    return picked;
  }

  List<WorldRuleSet> inferWorldRuleSetsFromSource(
    String sourceContent,
    List<SourceAnalysisChapterSummary> chapterSummaries,
  ) {
    final rules = <String>[];
    for (final chapter in chapterSummaries.take(12)) {
      final text = chapter.summary.trim();
      if (text.isEmpty) {
        continue;
      }
      if (_containsAny(text, _worldRuleSignals)) {
        rules.add(_truncate(text, 120));
      }
    }
    if (rules.isEmpty) {
      final outline = _outlineService.analyze(sourceContent);
      for (final chapter in outline.chapterSummaries.take(8)) {
        if (_containsAny(chapter.summary, _worldRuleSignals)) {
          rules.add(_truncate(chapter.summary, 120));
        }
      }
    }
    if (rules.isEmpty) {
      return const <WorldRuleSet>[];
    }
    return <WorldRuleSet>[
      WorldRuleSet(
        id: 'world_rules_inferred',
        displayName: '原文推断世界规则',
        summary: rules.first,
        rules: rules.take(8).toList(growable: false),
      ),
    ];
  }

  List<TimelineRecord> inferTimelineRecordsFromChapterSummaries(
    List<SourceAnalysisChapterSummary> chapterSummaries,
  ) {
    final result = <TimelineRecord>[];
    for (final chapter in chapterSummaries) {
      final clean = chapter.summary.trim();
      if (clean.isEmpty) {
        continue;
      }
      result.add(
        TimelineRecord(
          id: 'timeline_${chapter.sequence}',
          displayName: chapter.title,
          summary: _truncate(clean, 120),
          phaseLabel: '章节 ${chapter.sequence}',
          sequence: chapter.sequence,
          status: 'observed',
          metadata: <String, Object?>{
            'inferred_from_chapter_outline': true,
          },
        ),
      );
    }
    return result;
  }

  List<ForeshadowRecord> inferForeshadowRecordsFromChapterSummaries(
    List<SourceAnalysisChapterSummary> chapterSummaries,
  ) {
    final result = <ForeshadowRecord>[];
    for (final chapter in chapterSummaries) {
      final clean = chapter.summary.trim();
      if (clean.isEmpty) {
        continue;
      }
      final looksLikeForeshadow =
          _containsAny(clean, _foreshadowSignals) ||
          clean.contains('议会') ||
          clean.contains('真相') ||
          clean.contains('追捕') ||
          clean.contains('阴影');
      if (!looksLikeForeshadow) {
        continue;
      }
      result.add(
        ForeshadowRecord(
          id: 'foreshadow_${chapter.sequence}',
          title: '${chapter.title} 的潜在线索',
          status: 'planted',
          summary: _truncate(clean, 120),
          plantedChapterPath:
              'outlines/chapters/book_deconstruction_chapter_${chapter.sequence}.md',
          notes: '由章节摘要自动识别为可能的伏笔/未完成线索。',
          metadata: <String, Object?>{
            'inferred_from_chapter_outline': true,
          },
        ),
      );
    }
    return result;
  }

  List<RelationshipRecord> inferRelationshipRecords(
    List<CharacterProfile> characters,
    List<SourceAnalysisChapterSummary> chapterSummaries,
    List<OrganizationProfile> organizations,
  ) {
    final result = <RelationshipRecord>[];
    final names = characters
        .map((item) => item.displayName)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final seen = <String>{};
    for (final chapter in chapterSummaries.take(24)) {
      final text = chapter.summary;
      final present = names
          .where((name) => text.contains(name))
          .toList(growable: false);
      if (present.length < 2) {
        continue;
      }
      for (var index = 0; index < present.length - 1; index += 1) {
        final left = present[index];
        final right = present[index + 1];
        final pairKey = '$left::$right';
        if (seen.contains(pairKey) || seen.contains('$right::$left')) {
          continue;
        }
        seen.add(pairKey);
        result.add(
          RelationshipRecord(
            id: 'relationship_${result.length + 1}',
            displayName: '$left / $right',
            leftEntityId: _safeId(left, fallback: left),
            rightEntityId: _safeId(right, fallback: right),
            summary: _truncate(text.trim(), 120),
            relationshipType: 'co_occurrence',
            notes: '由章节摘要中的共同出现自动提取。',
            metadata: <String, Object?>{
              'inferred_from_chapter_outline': true,
            },
          ),
        );
      }
    }
    if (result.isEmpty && characters.length >= 2) {
      final left = characters.first;
      final right = characters[1];
      result.add(
        RelationshipRecord(
          id: 'relationship_1',
          displayName: '${left.displayName} / ${right.displayName}',
          leftEntityId: left.id,
          rightEntityId: right.id,
          summary: '原文角色条目共同构成当前拆书的核心互动关系。',
          relationshipType: 'character_pair',
          notes: '由角色条目兜底生成，后续可在正式分析中继续细化。',
          metadata: const <String, Object?>{
            'fallback_generated': true,
          },
        ),
      );
    }
    if (result.isEmpty && characters.isNotEmpty && organizations.isNotEmpty) {
      final character = characters.first;
      final organization = organizations.first;
      result.add(
        RelationshipRecord(
          id: 'relationship_1',
          displayName: '${character.displayName} / ${organization.displayName}',
          leftEntityId: character.id,
          rightEntityId: organization.id,
          summary: '当前拆书结果显示该角色与该组织存在基础关联，后续可继续细化。',
          relationshipType: 'character_organization',
          notes: '由角色与组织条目兜底生成，避免正式分析前关系层完全空白。',
          metadata: const <String, Object?>{
            'fallback_generated': true,
          },
        ),
      );
    }
    return result;
  }

  List<StyleProfile> inferStyleProfilesFromSource(
    String sourceContent, {
    String targetLanguage = 'zh-CN',
  }) {
    final structure = _outlineService.chapterSummariesOf(sourceContent);
    final paragraphCount = sourceContent
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .where((entry) => entry.trim().isNotEmpty)
        .length;
    final dialogueQuoteCount = RegExp(r'["“”]').allMatches(sourceContent).length;
    final summary = _styleSignalService.localizedSummary(
      SourceAnalysisStyleMetrics(
        sectionCount: structure.length,
        paragraphCount: paragraphCount,
        dialogueQuoteCount: dialogueQuoteCount,
        averageSectionLengthChars:
            structure.isEmpty ? sourceContent.length : (sourceContent.length / structure.length).round(),
      ),
      targetLanguage: targetLanguage,
    );
    if (summary.trim().isEmpty) {
      return const <StyleProfile>[];
    }
    return <StyleProfile>[
      StyleProfile(
        id: 'deconstruction_style_inferred',
        displayName: '原文推断叙事风格',
        summary: summary,
        metadata: const <String, Object?>{'inferred_from_source': true},
      ),
    ];
  }

  List<String> _lineValues(String rawText) {
    return rawText
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool _looksLikeCharacterName(String name) {
    if (name.length < 2 || name.length > 4) {
      return false;
    }
    if (_containsAny(name, _stopPhrases)) {
      return false;
    }
    return !_looksLikeOrganizationName(name);
  }

  bool _looksLikeOrganizationName(String name) {
    return _organizationSuffixes.any(name.endsWith);
  }

  bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  String _surroundingSummary(
    String sourceContent,
    String keyword, {
    int maxLength = 90,
  }) {
    final index = sourceContent.indexOf(keyword);
    if (index < 0) {
      return '';
    }
    final start = index - 24 < 0 ? 0 : index - 24;
    final end = index + keyword.length + 40 > sourceContent.length
        ? sourceContent.length
        : index + keyword.length + 40;
    final snippet = sourceContent.substring(start, end).replaceAll('\n', ' ').trim();
    return _truncate(snippet, maxLength);
  }

  String _truncate(String value, int maxLength) {
    final clean = value.trim();
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength)}...';
  }

  (String, String) _nameSummaryPair(String rawLine) {
    final match = RegExp(r'^([^:：\-]+)\s*[:：\-]\s*(.+)$').firstMatch(rawLine);
    if (match == null) {
      return (rawLine.trim(), '');
    }
    return ((match.group(1) ?? '').trim(), (match.group(2) ?? '').trim());
  }

  String _safeId(String value, {required String fallback}) {
    final clean = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (clean.isEmpty) {
      return fallback;
    }
    return clean;
  }
}

const List<String> _organizationSuffixes = <String>[
  '王国',
  '帝国',
  '公国',
  '议会',
  '骑士团',
  '商会',
  '学院',
  '学园',
  '神殿',
  '教会',
  '阵营',
  '家族',
  '一族',
  '军',
  '队',
];

const List<String> _worldRuleSignals = <String>[
  '规则',
  '仪式',
  '加护',
  '契约',
  '诅咒',
  '魔法',
  '禁忌',
  '王选',
  '能力',
  '精灵',
  '术式',
];

const List<String> _foreshadowSignals = <String>[
  '似乎',
  '隐约',
  '预感',
  '伏笔',
  '秘密',
  '尚未',
  '以后',
  '迟早',
  '真相',
  '谜团',
];

const List<String> _stopPhrases = <String>[
  '我们',
  '他们',
  '自己',
  '时候',
  '因为',
  '如果',
  '但是',
  '然后',
  '这个',
  '那个',
  '一种',
  '什么',
  '这样',
  '已经',
];
