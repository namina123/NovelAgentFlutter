import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information markdown projection services', () {
    test('renders stable information projection documents', () {
      final service = InformationMarkdownProjectionService();
      final source = InformationProjectionSource(
        knowledgeCards: <ProjectKnowledgeCard>[
          ProjectKnowledgeCard.fromJson(<String, Object?>{
            'card_id': 'knowledge-1',
            'card_namespace': 'project.world',
            'card_type': 'world_rule',
            'title': '雾潮夜记忆回声',
            'summary': '雾潮夜会放大失去的记忆。',
            'content_payload': <String, Object?>{
              'rule': '雾潮夜会放大失去的记忆',
              'unknown_payload': <String, Object?>{'rarity': 'high'},
            },
            'source_refs': <Object?>[_sourceRefJson()],
            'activation_policy': _activationPolicyJson(),
            'usage_policy': _usagePolicyJson(),
            'confidence': 0.92,
            'lifecycle_status': InformationLifecycleStatuses.accepted,
          }),
        ],
        designElements: <DesignElementCard>[
          DesignElementCard.fromJson(<String, Object?>{
            'design_id': 'design-1',
            'design_namespace': 'project.structure',
            'design_label': '潮声回扣',
            'design_payload': <String, Object?>{
              'pattern': '章末潮声回扣章首镜面',
              'unknown_payload': <String, Object?>{'phase': 'vol1'},
            },
            'source_refs': <Object?>[_sourceRefJson()],
            'linked_refs': <Object?>[
              <String, Object?>{
                'ref_type': InformationLinkedRefTypes.knowledgeCard,
                'ref_id': 'knowledge-1',
              },
            ],
            'activation_policy': _activationPolicyJson(
              priority: InformationActivationPriorities.pinned,
            ),
            'usage_policy': _usagePolicyJson(),
            'confidence': 0.74,
            'uncertainty': 'medium',
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          }),
        ],
        researchNotes: <ResearchNote>[
          ResearchNote.fromJson(<String, Object?>{
            'research_id': 'research-1',
            'query': '镜潮母题',
            'source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/mirror-tide',
            'citation': 'Mirror Tide',
            'summary': '整理出镜与潮的并置用法。',
            'usable_facts': <Object?>['镜与潮常共同承担身份映照'],
            'creative_suggestions': <Object?>['可用于章节标题'],
            'created_by': 'researcher-agent',
            'usage_policy': _usagePolicyJson(
              usageMode: InformationUsageModes.referenceOnly,
            ),
          }),
        ],
        referenceWorks: <ReferenceWorkRecord>[
          ReferenceWorkRecord.fromJson(<String, Object?>{
            'reference_work_id': 'reference-1',
            'title': '雾海镜宫',
            'creator': '海岚',
            'source_refs': <Object?>[_sourceRefJson()],
            'relationship_to_project': 'fanfic_reference',
            'declared_usage_intent': '同人练习',
            'allowed_usage_summary': '只允许抽象借鉴，不允许直接引句。',
            'risk_notes': <Object?>[
              <String, Object?>{'level': 'high', 'reason': '外部作品边界'},
            ],
            'requires_confirmation': true,
          }),
        ],
      );

      final documents = service.buildDocuments(source);
      final repeated = service.buildDocuments(source);

      expect(documents.map((item) => item.relativePath), <String>[
        'knowledge/项目知识摘要.md',
        'knowledge/设计元素摘要.md',
        'research/资料研究摘要.md',
        'references/引用作品边界.md',
      ]);
      expect(documents.first.markdown, contains('这份 Markdown 只是结构化信息事实源的可读投影'));
      expect(
        documents.first.markdown,
        contains(InformationMarkdownProjectionService.knowledgeDraftBlockId),
      );
      expect(
        documents[1].markdown,
        contains(
          '`{"pattern":"章末潮声回扣章首镜面","unknown_payload":{"phase":"vol1"}}`',
        ),
      );
      expect(documents[2].markdown, contains('可用事实数：1'));
      expect(documents[3].markdown, contains('Requires Confirmation：true'));
      expect(
        repeated.map((item) => item.markdown).toList(growable: false),
        documents.map((item) => item.markdown).toList(growable: false),
      );
    });

    test('bridge parses edited draft blocks into structured drafts only', () {
      final projectionService = InformationMarkdownProjectionService();
      final bridgeService = InformationMarkdownBridgeService();
      final documents = projectionService.buildDocuments(
        const InformationProjectionSource(),
      );

      final editedKnowledgeMarkdown = documents
          .firstWhere(
            (item) =>
                item.relativePath ==
                InformationProjectionDocument.knowledgeSummaryRelativePath,
          )
          .markdown
          .replaceFirst(
            '```json ${InformationMarkdownProjectionService.knowledgeDraftBlockId}\n[]\n```',
            '''```json ${InformationMarkdownProjectionService.knowledgeDraftBlockId}
[
  {
    "card_id": "knowledge-draft-1",
    "card_namespace": "project.world",
    "card_type": "world_rule",
    "title": "潮镜夜航",
    "summary": "补充夜航规则",
    "content_payload": {
      "rule": "潮镜夜航时不能直视镜面",
      "unknown_payload": {
        "severity": "high"
      }
    },
    "source_refs": [
      ${_inlineSourceRefJson('knowledge-md')}
    ],
    "activation_policy": ${_inlineActivationPolicyJson()},
    "usage_policy": ${_inlineUsagePolicyJson()},
    "confidence": 0.66,
    "lifecycle_status": "${InformationLifecycleStatuses.proposed}",
    "unknown_top_level": "kept"
  }
]
```''',
          );
      final editedDesignMarkdown = documents
          .firstWhere(
            (item) =>
                item.relativePath ==
                InformationProjectionDocument.designSummaryRelativePath,
          )
          .markdown
          .replaceFirst(
            '```json ${InformationMarkdownProjectionService.designDraftBlockId}\n[]\n```',
            '''```json ${InformationMarkdownProjectionService.designDraftBlockId}
[
  {
    "design_id": "design-draft-1",
    "design_namespace": "project.structure",
    "design_label": "镜潮双回环",
    "design_payload": {
      "pattern": "章首章尾双回环"
    },
    "source_refs": [
      ${_inlineSourceRefJson('design-md')}
    ],
    "activation_policy": ${_inlineActivationPolicyJson(priority: InformationActivationPriorities.pinned)},
    "usage_policy": ${_inlineUsagePolicyJson()},
    "confidence": 0.58,
    "uncertainty": "medium",
    "lifecycle_status": "${InformationLifecycleStatuses.proposed}"
  }
]
```''',
          );
      final editedResearchMarkdown = documents
          .firstWhere(
            (item) =>
                item.relativePath ==
                InformationProjectionDocument.researchSummaryRelativePath,
          )
          .markdown
          .replaceFirst(
            '```json ${InformationMarkdownProjectionService.researchDraftBlockId}\n[]\n```',
            '''```json ${InformationMarkdownProjectionService.researchDraftBlockId}
[
  {
    "research_id": "research-draft-1",
    "query": "镜潮互文",
    "source_kind": "archive",
    "source_url_or_ref": "archive://mirror-tide",
    "citation": "Mirror Tide Archive",
    "summary": "补充互文资料",
    "usable_facts": ["镜潮共振常用于身份错位"],
    "creative_suggestions": ["可用于卷末题记"],
    "created_by": "researcher-agent",
    "usage_policy": ${_inlineUsagePolicyJson(usageMode: InformationUsageModes.referenceOnly)},
    "unknown_top_level": "preserved"
  }
]
```''',
          );
      final editedReferenceMarkdown = documents
          .firstWhere(
            (item) =>
                item.relativePath ==
                InformationProjectionDocument.referenceBoundaryRelativePath,
          )
          .markdown
          .replaceFirst(
            '```json ${InformationMarkdownProjectionService.referenceWorkDraftBlockId}\n[]\n```',
            '''```json ${InformationMarkdownProjectionService.referenceWorkDraftBlockId}
[
  {
    "reference_work_id": "reference-draft-1",
    "title": "雾海镜宫",
    "source_refs": [
      ${_inlineSourceRefJson('reference-md')}
    ],
    "relationship_to_project": "fanfic_reference",
    "declared_usage_intent": "同人练习",
    "requires_confirmation": true,
    "future_unknown_field": {
      "keep": true
    }
  }
]
```''',
          );

      final knowledgeDrafts = bridgeService.parseDocument(
        editedKnowledgeMarkdown,
        relativePath:
            InformationProjectionDocument.knowledgeSummaryRelativePath,
      );
      final designDrafts = bridgeService.parseDocument(
        editedDesignMarkdown,
        relativePath: InformationProjectionDocument.designSummaryRelativePath,
      );
      final researchDrafts = bridgeService.parseDocument(
        editedResearchMarkdown,
        relativePath: InformationProjectionDocument.researchSummaryRelativePath,
      );
      final referenceDrafts = bridgeService.parseDocument(
        editedReferenceMarkdown,
        relativePath:
            InformationProjectionDocument.referenceBoundaryRelativePath,
      );

      expect(knowledgeDrafts.projectionOnly, isTrue);
      expect(knowledgeDrafts.knowledgeCardDrafts, hasLength(1));
      expect(
        knowledgeDrafts.knowledgeCardDrafts.single
            .toJson()['unknown_top_level'],
        'kept',
      );
      expect(knowledgeDrafts.designElementDrafts, isEmpty);
      expect(designDrafts.designElementDrafts.single.designLabel, '镜潮双回环');
      expect(
        researchDrafts.researchNoteDrafts.single.toJson()['unknown_top_level'],
        'preserved',
      );
      expect(
        (referenceDrafts.referenceWorkDrafts.single
                .toJson()['future_unknown_field']
            as Map<String, Object?>)['keep'],
        isTrue,
      );
    });
  });
}

Map<String, Object?> _sourceRefJson([String sourceId = 'source-1']) {
  return <String, Object?>{
    'source_ref': <String, Object?>{
      'source_type': NarrativeSourceTypes.user,
      'source_id': sourceId,
    },
    'source_authority': InformationSourceAuthorities.userDeclared,
    'role_authority': InformationRoleAuthorities.user,
    'research_depth': InformationResearchDepths.none,
  };
}

Map<String, Object?> _activationPolicyJson({
  String priority = InformationActivationPriorities.required,
}) {
  return <String, Object?>{
    'activation_priority': priority,
    'preferred_budget_chars': 240,
  };
}

Map<String, Object?> _usagePolicyJson({
  String usageMode = InformationUsageModes.normal,
}) {
  return <String, Object?>{
    'usage_mode': usageMode,
    'citation_risk_level': InformationCitationRiskLevels.low,
    'allows_derivative_use': true,
  };
}

String _inlineSourceRefJson(String sourceId) {
  return '''
{
  "source_ref": {
    "source_type": "${NarrativeSourceTypes.user}",
    "source_id": "$sourceId"
  },
  "source_authority": "${InformationSourceAuthorities.userDeclared}",
  "role_authority": "${InformationRoleAuthorities.user}",
  "research_depth": "${InformationResearchDepths.none}"
}''';
}

String _inlineActivationPolicyJson({
  String priority = InformationActivationPriorities.required,
}) {
  return '''
{
  "activation_priority": "$priority",
  "preferred_budget_chars": 180
}''';
}

String _inlineUsagePolicyJson({
  String usageMode = InformationUsageModes.normal,
}) {
  return '''
{
  "usage_mode": "$usageMode",
  "citation_risk_level": "${InformationCitationRiskLevels.low}",
  "allows_derivative_use": true
}''';
}
