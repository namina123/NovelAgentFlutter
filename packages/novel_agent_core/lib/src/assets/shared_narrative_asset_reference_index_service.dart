import 'foreshadow_record.dart';
import 'relationship_record.dart';
import 'shared_narrative_asset_reference.dart';
import 'shared_narrative_asset_reference_index.dart';
import 'timeline_record.dart';

class SharedNarrativeAssetReferenceIndexService {
  const SharedNarrativeAssetReferenceIndexService();

  SharedNarrativeAssetReferenceIndex buildIndex({
    List<ForeshadowRecord> foreshadows = const <ForeshadowRecord>[],
    List<TimelineRecord> timelines = const <TimelineRecord>[],
    List<RelationshipRecord> relationships = const <RelationshipRecord>[],
  }) {
    // 中文注释: 这里先只做最小共享关联规则，把三类资产压成统一引用索引，供一般小说与长任务共用，而不是先做复杂图谱引擎。
    final seeds = <String, _ReferenceSeed>{};
    for (final record in foreshadows) {
      final referenceKey = _key('foreshadow', record.id);
      seeds[referenceKey] = _ReferenceSeed(
        referenceKey: referenceKey,
        assetId: record.id,
        assetKind: 'foreshadow',
        displayName: record.title,
        summary: record.summary,
        entityIds: record.relatedEntityIds,
        directReferenceKeys: <String>[
          ...record.relatedTimelineIds.map((id) => _key('timeline', id)),
          ...record.relatedRelationshipIds.map(
            (id) => _key('relationship', id),
          ),
        ],
        sourcePath: record.sourcePath,
      );
    }
    for (final record in timelines) {
      final referenceKey = _key('timeline', record.id);
      seeds[referenceKey] = _ReferenceSeed(
        referenceKey: referenceKey,
        assetId: record.id,
        assetKind: 'timeline',
        displayName: record.displayName,
        summary: record.summary,
        entityIds: record.relatedEntityIds,
        directReferenceKeys: <String>[
          ...record.relatedForeshadowIds.map((id) => _key('foreshadow', id)),
          ...record.relatedRelationshipIds.map(
            (id) => _key('relationship', id),
          ),
        ],
        sourcePath: record.sourcePath,
      );
    }
    for (final record in relationships) {
      final referenceKey = _key('relationship', record.id);
      seeds[referenceKey] = _ReferenceSeed(
        referenceKey: referenceKey,
        assetId: record.id,
        assetKind: 'relationship',
        displayName: record.displayName,
        summary: record.summary,
        entityIds: <String>[
          record.leftEntityId,
          record.rightEntityId,
          ...record.relatedEntityIds,
        ],
        directReferenceKeys: <String>[
          ...record.relatedForeshadowIds.map((id) => _key('foreshadow', id)),
          ...record.relatedTimelineIds.map((id) => _key('timeline', id)),
        ],
        sourcePath: record.sourcePath,
      );
    }

    final knownReferenceKeys = seeds.keys.toSet();
    final reverseReferenceKeys = <String, Set<String>>{};
    for (final seed in seeds.values) {
      final reverseTargets = reverseReferenceKeys.putIfAbsent(
        seed.referenceKey,
        () => <String>{},
      );
      for (final targetKey in seed.directReferenceKeys) {
        if (knownReferenceKeys.contains(targetKey)) {
          reverseTargets.add(targetKey);
          reverseReferenceKeys
              .putIfAbsent(targetKey, () => <String>{})
              .add(seed.referenceKey);
        }
      }
    }

    final references =
        seeds.values
            .map((seed) {
              final relatedKeys =
                  reverseReferenceKeys[seed.referenceKey]?.toList(
                    growable: false,
                  ) ??
                  const <String>[];
              final missingKeys = seed.directReferenceKeys
                  .where((targetKey) => !knownReferenceKeys.contains(targetKey))
                  .toList(growable: false);
              return SharedNarrativeAssetReference(
                referenceKey: seed.referenceKey,
                assetId: seed.assetId,
                assetKind: seed.assetKind,
                displayName: seed.displayName,
                summary: seed.summary,
                entityIds: _dedupe(seed.entityIds),
                relatedReferenceKeys: _sorted(_dedupe(relatedKeys)),
                missingReferenceKeys: _sorted(_dedupe(missingKeys)),
                sourcePath: seed.sourcePath,
              );
            })
            .toList(growable: false)
          ..sort((left, right) {
            final kindOrder = left.assetKind.compareTo(right.assetKind);
            if (kindOrder != 0) {
              return kindOrder;
            }
            final nameOrder = left.displayName.compareTo(right.displayName);
            if (nameOrder != 0) {
              return nameOrder;
            }
            return left.assetId.compareTo(right.assetId);
          });
    return SharedNarrativeAssetReferenceIndex(references: references);
  }

  String _key(String assetKind, String assetId) =>
      '$assetKind:${assetId.trim()}';

  List<String> _dedupe(List<String> rawValues) {
    final values = <String>[];
    for (final rawValue in rawValues) {
      final cleanValue = rawValue.trim();
      if (cleanValue.isNotEmpty && !values.contains(cleanValue)) {
        values.add(cleanValue);
      }
    }
    return values;
  }

  List<String> _sorted(List<String> rawValues) {
    final values = List<String>.from(rawValues);
    values.sort();
    return values;
  }
}

class _ReferenceSeed {
  const _ReferenceSeed({
    required this.referenceKey,
    required this.assetId,
    required this.assetKind,
    required this.displayName,
    required this.summary,
    required this.entityIds,
    required this.directReferenceKeys,
    required this.sourcePath,
  });

  final String referenceKey;
  final String assetId;
  final String assetKind;
  final String displayName;
  final String summary;
  final List<String> entityIds;
  final List<String> directReferenceKeys;
  final String sourcePath;
}
