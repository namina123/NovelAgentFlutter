import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SharedNarrativeAssetReferenceIndexService', () {
    test(
      'builds reverse-linked shared references for foreshadow timeline and relationship assets',
      () {
        final service = SharedNarrativeAssetReferenceIndexService();
        final index = service.buildIndex(
          foreshadows: const <ForeshadowRecord>[
            ForeshadowRecord(
              id: 'tower_secret',
              title: '高塔秘密',
              status: 'planted',
              relatedEntityIds: <String>['character.protagonist'],
              relatedTimelineIds: <String>['tower_glow_night'],
            ),
          ],
          timelines: const <TimelineRecord>[
            TimelineRecord(
              id: 'tower_glow_night',
              displayName: '高塔异光之夜',
              relatedEntityIds: <String>['character.protagonist'],
            ),
          ],
          relationships: const <RelationshipRecord>[
            RelationshipRecord(
              id: 'mentor_conflict',
              displayName: '师徒裂痕',
              leftEntityId: 'character.protagonist',
              rightEntityId: 'character.mentor',
              relatedForeshadowIds: <String>['tower_secret'],
            ),
          ],
        );

        final foreshadow = index.referenceOf('foreshadow', 'tower_secret');
        final timeline = index.referenceOf('timeline', 'tower_glow_night');
        final relationship = index.referenceOf(
          'relationship',
          'mentor_conflict',
        );

        expect(foreshadow, isNotNull);
        expect(timeline, isNotNull);
        expect(relationship, isNotNull);
        expect(
          foreshadow!.relatedReferenceKeys,
          containsAll(<String>[
            'timeline:tower_glow_night',
            'relationship:mentor_conflict',
          ]),
        );
        expect(
          timeline!.relatedReferenceKeys,
          contains('foreshadow:tower_secret'),
        );
        expect(
          relationship!.relatedReferenceKeys,
          contains('foreshadow:tower_secret'),
        );
        expect(
          relationship.entityIds,
          containsAll(<String>['character.protagonist', 'character.mentor']),
        );
      },
    );

    test(
      'keeps unresolved references as missing keys without fabricating nodes',
      () {
        final service = SharedNarrativeAssetReferenceIndexService();
        final index = service.buildIndex(
          foreshadows: const <ForeshadowRecord>[
            ForeshadowRecord(
              id: 'missing_case',
              title: '失联伏笔',
              status: 'planted',
              relatedTimelineIds: <String>['unknown_timeline'],
            ),
          ],
        );

        final foreshadow = index.referenceOf('foreshadow', 'missing_case');
        expect(foreshadow, isNotNull);
        expect(
          foreshadow!.missingReferenceKeys,
          contains('timeline:unknown_timeline'),
        );
        expect(index.neighborsOf('foreshadow', 'missing_case'), isEmpty);
      },
    );

    test('can resolve a shared reference by formal reference key', () {
      final service = SharedNarrativeAssetReferenceIndexService();
      final index = service.buildIndex(
        foreshadows: const <ForeshadowRecord>[
          ForeshadowRecord(
            id: 'tower_secret',
            title: '高塔秘密',
            status: 'planted',
          ),
        ],
      );

      expect(
        index.referenceByKey('foreshadow:tower_secret')?.displayName,
        '高塔秘密',
      );
      expect(index.referenceByKey('unknown:key'), isNull);
      expect(index.referenceByKey(''), isNull);
    });
  });
}
