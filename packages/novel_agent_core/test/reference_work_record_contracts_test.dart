import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceWorkRecord contracts', () {
    test(
      'round-trips deconstructed source record with open relationship strings',
      () {
        const codec = ReferenceWorkRecordCodecService();
        final record = codec.fromJson(<String, Object?>{
          'reference_work_id': 'reference-001',
          'title': '雾海城纪',
          'creator': '林照野',
          'version': 'first-edition',
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
                'source_id': 'deconstruction-source-001',
              },
              'source_authority':
                  InformationSourceAuthorities.deconstructionExtracted,
              'role_authority': InformationRoleAuthorities.deconstructor,
              'research_depth': InformationResearchDepths.standard,
            },
          ],
          'relationship_to_project': 'deconstructed_source',
          'declared_usage_intent': '作为拆书来源作品，用于提炼结构巧思与设定边界。',
          'allowed_usage_summary': '保留摘要、证据定位和续写边界，不直接复制原文段落。',
          'risk_notes': <Object?>[
            <String, Object?>{
              'risk': 'source_text_quote',
              'note': '原文片段引用需要用户确认。',
            },
          ],
          'requires_confirmation': true,
          'future_extension': <String, Object?>{'keep': 'yes'},
        });

        final encoded = codec.toJson(record);

        expect(record.validateBasics(), isEmpty);
        expect(record.relationshipToProject, 'deconstructed_source');
        expect(record.requiresConfirmation, isTrue);
        expect(record.sourceRefs, hasLength(1));
        expect(record.riskNotes, hasLength(1));
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(record.riskNotes.first)['risk'],
          ),
          'source_text_quote',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(encoded['future_extension'])['keep'],
          ),
          'yes',
        );
      },
    );

    test(
      'round-trips fanfic and crossover style relationships without enums',
      () {
        const codec = ReferenceWorkRecordCodecService();
        final fanficRecord = codec.fromJson(<String, Object?>{
          'reference_work_id': 'reference-002',
          'title': '星港旧梦',
          'creator': '季渊',
          'version': 'web-serialization',
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
                'source_id': 'user-reference-002',
              },
              'source_authority': InformationSourceAuthorities.userDeclared,
              'role_authority': InformationRoleAuthorities.user,
              'research_depth': InformationResearchDepths.none,
            },
          ],
          'relationship_to_project': 'fanfic_reference',
          'declared_usage_intent': '同人续写练习，只借用人物关系与世界观轮廓。',
          'allowed_usage_summary': '仅作灵感与关系边界参考。',
          'risk_notes': <Object?>['正式发布前需要再次确认授权边界。'],
          'requires_confirmation': true,
        });

        final copied = fanficRecord.copyWith(
          relationshipToProject: 'crossover_reference',
          declaredUsageIntent: '跨作品混合参考，只借鉴两部作品的空间秩序设计。',
          requiresConfirmation: false,
        );

        expect(fanficRecord.validateBasics(), isEmpty);
        expect(fanficRecord.relationshipToProject, 'fanfic_reference');
        expect(copied.relationshipToProject, 'crossover_reference');
        expect(copied.requiresConfirmation, isFalse);
        expect(
          ValueReaders.stringValue(copied.riskNotes.first),
          '正式发布前需要再次确认授权边界。',
        );
      },
    );

    test('codec service supports empty record lists', () {
      const codec = ReferenceWorkRecordCodecService();

      expect(codec.fromJsonList(const <Object?>[]), isEmpty);
      expect(codec.toJsonList(const <ReferenceWorkRecord>[]), isEmpty);
    });

    test('validator reports missing identity and invalid source refs', () {
      const validator = ReferenceWorkRecordValidator();
      final record = ReferenceWorkRecord.fromJson(<String, Object?>{
        'reference_work_id': '',
        'title': '',
        'source_refs': <Object?>[
          <String, Object?>{'source_ref': <String, Object?>{}},
        ],
        'relationship_to_project': '',
        'declared_usage_intent': '',
      });

      expect(
        validator.validate(record),
        containsAll(<String>[
          InformationValidationCodes.missingReferenceWorkId,
          InformationValidationCodes.missingReferenceWorkTitle,
          InformationValidationCodes.missingReferenceWorkRelationshipToProject,
          InformationValidationCodes.missingReferenceWorkDeclaredUsageIntent,
          InformationValidationCodes.invalidReferenceWorkSourceRef,
        ]),
      );
    });
  });
}
