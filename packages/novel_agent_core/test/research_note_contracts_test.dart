import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ResearchNote contracts', () {
    test(
      'round-trips external research with separated facts and suggestions',
      () {
        const codec = ResearchNoteCodecService();
        final note = codec.fromJson(<String, Object?>{
          'research_id': 'research-001',
          'query': '古代城门命名与方位象征',
          'source_kind': 'web_article',
          'source_url_or_ref': 'https://example.com/gates-and-directions',
          'citation': '《城门与方位象征》, 2025-09-12',
          'summary': '资料整理了古代城门命名与方位隐喻之间的常见对应关系。',
          'usable_facts': <Object?>[
            <String, Object?>{'fact': '东门常与迎新、启明相关联', 'confidence': 0.81},
            '西门常与归返和落日意象关联。',
          ],
          'creative_suggestions': <Object?>[
            <String, Object?>{'idea': '可把主角姓氏与城门方位对应，形成命名暗线。'},
          ],
          'uncertainty': '不同朝代的象征映射并不完全一致。',
          'license_or_usage_note': '只保留摘要与事实点，不直接引用原文段落。',
          'created_by': 'researcher.agent',
          'linked_cards': <Object?>[
            <String, Object?>{
              'ref_type': InformationLinkedRefTypes.knowledgeCard,
              'ref_id': 'knowledge-001',
            },
            <String, Object?>{
              'ref_type': InformationLinkedRefTypes.designElement,
              'ref_id': 'design-001',
            },
          ],
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.referenceOnly,
            'citation_risk_level': InformationCitationRiskLevels.highRisk,
            'requires_confirmation': true,
          },
          'future_extension': <String, Object?>{'preserve': true},
        });

        final encoded = codec.toJson(note);

        expect(note.validateBasics(), isEmpty);
        expect(note.sourceKind, 'web_article');
        expect(note.usableFacts, hasLength(2));
        expect(note.creativeSuggestions, hasLength(1));
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(note.usableFacts.first)['fact'],
          ),
          '东门常与迎新、启明相关联',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(note.creativeSuggestions.first)['idea'],
          ),
          '可把主角姓氏与城门方位对应，形成命名暗线。',
        );
        expect(note.linkedCards, hasLength(2));
        expect(
          note.linkedCards.first.refType,
          InformationLinkedRefTypes.knowledgeCard,
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(encoded['future_extension'])['preserve'],
          ),
          isTrue,
        );
      },
    );

    test(
      'round-trips gateway note and copyWith preserves separated payloads',
      () {
        const codec = ResearchNoteCodecService();
        final note = codec.fromJson(<String, Object?>{
          'research_id': 'research-002',
          'query': '镜像意象在神话叙事中的常见含义',
          'source_kind': 'gateway_search',
          'source_url_or_ref': 'gateway:search-result:mirror-symbolism',
          'citation': 'gateway search digest / mirror symbolism',
          'summary': '搜索摘要显示镜像常被用于身份反照与真伪辨识。',
          'usable_facts': <Object?>['镜像经常承担身份自省或真假辨识功能。'],
          'creative_suggestions': <Object?>['可让镜面意象与角色记忆错位反复并置。'],
          'created_by': 'gateway.researcher',
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.normal,
          },
        });

        final copied = note.copyWith(
          summary: '搜索摘要显示镜像常被用于身份反照、真伪辨识与命运回声。',
          creativeSuggestions: <Object?>[
            '可让镜面意象与角色记忆错位反复并置。',
            '章节标题也可周期性回扣镜像词汇。',
          ],
        );

        expect(note.validateBasics(), isEmpty);
        expect(copied.summary, '搜索摘要显示镜像常被用于身份反照、真伪辨识与命运回声。');
        expect(copied.usableFacts, hasLength(1));
        expect(copied.creativeSuggestions, hasLength(2));
        expect(
          ValueReaders.stringValue(copied.creativeSuggestions.last),
          '章节标题也可周期性回扣镜像词汇。',
        );
      },
    );

    test('codec service supports empty note lists', () {
      const codec = ResearchNoteCodecService();

      expect(codec.fromJsonList(const <Object?>[]), isEmpty);
      expect(codec.toJsonList(const <ResearchNote>[]), isEmpty);
    });

    test('validator reports missing traceability and invalid linked cards', () {
      const validator = ResearchNoteValidator();
      final note = ResearchNote.fromJson(<String, Object?>{
        'research_id': '',
        'query': '',
        'source_kind': '',
        'source_url_or_ref': '',
        'citation': '',
        'summary': '',
        'created_by': '',
        'linked_cards': <Object?>[
          <String, Object?>{'ref_type': '', 'ref_id': ''},
        ],
        'usage_policy': <String, Object?>{},
      });

      expect(
        validator.validate(note),
        containsAll(<String>[
          InformationValidationCodes.missingResearchNoteId,
          InformationValidationCodes.missingResearchNoteQuery,
          InformationValidationCodes.missingResearchNoteSourceKind,
          InformationValidationCodes.missingResearchNoteSourceUrlOrRef,
          InformationValidationCodes.missingResearchNoteCitation,
          InformationValidationCodes.missingResearchNoteSummary,
          InformationValidationCodes.missingResearchNoteCreatedBy,
          InformationValidationCodes.invalidResearchNoteLinkedCardRef,
          InformationValidationCodes.missingInformationUsageMode,
          InformationValidationCodes.missingInformationCitationRiskLevel,
        ]),
      );
    });
  });
}
