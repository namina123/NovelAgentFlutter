import '../assets/character_profile.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import 'inspiration_field_key.dart';
import 'inspiration_premise.dart';
import 'inspiration_projection.dart';
import 'inspiration_record.dart';

class InspirationProjectionService {
  const InspirationProjectionService();

  InspirationProjection build(InspirationRecord record) {
    return InspirationProjection(
      inspirationId: record.id,
      premises: buildPremises(record),
      styleProfiles: buildStyleProfiles(record),
      worldRuleSets: buildWorldRuleSets(record),
      characterProfiles: buildCharacterProfiles(record),
    );
  }

  List<InspirationPremise> buildPremises(InspirationRecord record) {
    final values = _values(record);
    final seedMaterial = _value(values, InspirationFieldKey.seedMaterial);
    final premise = _value(values, InspirationFieldKey.premise);
    final corePromise = _value(values, InspirationFieldKey.corePromise);
    final mainArc = _value(values, InspirationFieldKey.mainArc);
    final endingCommitment = _value(
      values,
      InspirationFieldKey.endingCommitment,
    );
    final autonomyGuardrails = _value(
      values,
      InspirationFieldKey.autonomyGuardrails,
    );
    final summary = _firstNonEmpty(<String>[
      premise,
      _nonEmpty(<String>[corePromise, mainArc]).join(' '),
      seedMaterial,
    ]);
    if (summary.isEmpty) {
      return const <InspirationPremise>[];
    }
    final safeBaseId = _safeId(record.id);
    return <InspirationPremise>[
      InspirationPremise(
        id: '$safeBaseId.premise.primary',
        displayName: '核心故事前提',
        summary: summary,
        corePromise: corePromise,
        mainConflict: mainArc,
        boundaries: _nonEmpty(<String>[endingCommitment, autonomyGuardrails]),
      ),
    ];
  }

  List<StyleProfile> buildStyleProfiles(InspirationRecord record) {
    final values = _values(record);
    final styleTarget = _firstNonEmpty(<String>[
      _value(values, InspirationFieldKey.styleTarget),
      _value(values, InspirationFieldKey.styleBoundaries),
    ]);
    if (styleTarget.isEmpty) {
      return const <StyleProfile>[];
    }
    final safeBaseId = _safeId(record.id);
    return <StyleProfile>[
      StyleProfile(
        id: '$safeBaseId.style.primary',
        displayName: '灵感风格锚点',
        summary: styleTarget,
        guardrails: _nonEmpty(<String>[
          _value(values, InspirationFieldKey.corePromise),
          _value(values, InspirationFieldKey.autonomyGuardrails),
          _value(values, InspirationFieldKey.endingCommitment),
        ]),
      ),
    ];
  }

  List<WorldRuleSet> buildWorldRuleSets(InspirationRecord record) {
    final values = _values(record);
    final worldAnchor = _value(values, InspirationFieldKey.worldAnchor);
    if (worldAnchor.isEmpty) {
      return const <WorldRuleSet>[];
    }
    final safeBaseId = _safeId(record.id);
    return <WorldRuleSet>[
      WorldRuleSet(
        id: '$safeBaseId.world.primary',
        displayName: '世界锚点',
        summary: worldAnchor,
        rules: _splitSentences(worldAnchor),
      ),
    ];
  }

  List<CharacterProfile> buildCharacterProfiles(InspirationRecord record) {
    final values = _values(record);
    final protagonistDrive = _value(
      values,
      InspirationFieldKey.protagonistDrive,
    );
    final coreCharacters = _value(values, InspirationFieldKey.coreCharacters);
    final mainArc = _value(values, InspirationFieldKey.mainArc);
    final premise = _value(values, InspirationFieldKey.premise);
    final summary = _firstNonEmpty(<String>[
      protagonistDrive,
      coreCharacters,
      _nonEmpty(<String>[premise, mainArc]).join(' '),
    ]);
    if (summary.isEmpty) {
      return const <CharacterProfile>[];
    }
    final safeBaseId = _safeId(record.id);
    return <CharacterProfile>[
      CharacterProfile(
        id: '$safeBaseId.character.primary',
        displayName: protagonistDrive.isNotEmpty ? '主角' : '核心角色锚点',
        summary: summary,
        storyRole: protagonistDrive.isNotEmpty ? 'protagonist' : 'story_focus',
      ),
    ];
  }

  Map<String, String> _values(InspirationRecord record) {
    final values = <String, String>{};
    for (final fieldValue in record.fieldValues) {
      final cleanFieldKey = fieldValue.fieldKey.trim();
      final cleanValue = fieldValue.value.trim();
      if (cleanFieldKey.isEmpty || cleanValue.isEmpty) {
        continue;
      }
      values[cleanFieldKey] = cleanValue;
    }
    return values;
  }

  String _value(Map<String, String> values, String key) {
    return values[key] ?? '';
  }

  String _firstNonEmpty(List<String> candidates) {
    for (final candidate in candidates) {
      final cleanCandidate = candidate.trim();
      if (cleanCandidate.isNotEmpty) {
        return cleanCandidate;
      }
    }
    return '';
  }

  List<String> _nonEmpty(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final cleanValue = value.trim();
      if (cleanValue.isNotEmpty) {
        result.add(cleanValue);
      }
    }
    return result;
  }

  List<String> _splitSentences(String rawText) {
    // 中文注释: 灵感世界锚点通常是自由描述，这里只做轻量切句，避免过早引入重分析器。
    final normalized = rawText
        .replaceAll('；', '。')
        .replaceAll(';', '.')
        .replaceAll('\r', '\n');
    final fragments = normalized.split(RegExp(r'[。\n]+'));
    final result = <String>[];
    for (final fragment in fragments) {
      final cleanFragment = fragment.trim();
      if (cleanFragment.isNotEmpty) {
        result.add(cleanFragment);
      }
    }
    return result;
  }

  String _safeId(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  }
}
