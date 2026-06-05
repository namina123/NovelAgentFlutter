import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('InformationPermissionPolicyService', () {
    test('built-in and user-declared low-risk materials can auto accept', () {
      const service = InformationPermissionPolicyService();
      final knowledgeCard = ProjectKnowledgeCard.fromJson(<String, Object?>{
        'card_id': 'knowledge-001',
        'card_namespace': 'writing.main',
        'card_type': 'world_rule',
        'title': '潮镜律',
        'content_payload': <String, Object?>{'rule': '镜面在月潮夜会保留前一夜回声'},
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': NarrativeSourceTypes.user,
              'source_id': 'user-knowledge-001',
            },
            'source_authority': InformationSourceAuthorities.userDeclared,
            'role_authority': InformationRoleAuthorities.user,
            'research_depth': InformationResearchDepths.none,
          },
        ],
        'activation_policy': <String, Object?>{
          'activation_priority': InformationActivationPriorities.required,
        },
        'usage_policy': <String, Object?>{
          'usage_mode': InformationUsageModes.normal,
          'citation_risk_level': InformationCitationRiskLevels.low,
        },
        'confidence': 0.95,
        'lifecycle_status': InformationLifecycleStatuses.active,
      });
      final designElement = DesignElementCard.fromJson(<String, Object?>{
        'design_id': 'design-001',
        'design_namespace': 'writing.main',
        'design_label': '镜潮回扣',
        'design_payload': <String, Object?>{'motif': '章末的潮声反向解释开头的镜面描写'},
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': NarrativeSourceTypes.system,
              'source_id': 'builtin-design-seed-001',
            },
            'source_authority': InformationSourceAuthorities.sourceDocument,
            'role_authority': InformationRoleAuthorities.system,
            'research_depth': InformationResearchDepths.none,
          },
        ],
        'activation_policy': <String, Object?>{
          'activation_priority': InformationActivationPriorities.pinned,
        },
        'usage_policy': <String, Object?>{
          'usage_mode': InformationUsageModes.normal,
          'citation_risk_level': InformationCitationRiskLevels.low,
        },
        'confidence': 0.9,
        'uncertainty': '',
        'lifecycle_status': InformationLifecycleStatuses.active,
      });

      expect(
        service.decideKnowledgeCard(knowledgeCard).disposition,
        InformationPermissionDispositions.autoAccept,
      );
      expect(
        service.decideDesignElement(designElement).disposition,
        InformationPermissionDispositions.autoAccept,
      );
    });

    test(
      'external research derived project rules stay proposed while notes auto accept',
      () {
        const service = InformationPermissionPolicyService();
        final knowledgeCard = ProjectKnowledgeCard.fromJson(<String, Object?>{
          'card_id': 'knowledge-002',
          'card_namespace': 'analysis.research',
          'card_type': 'cultural_reference',
          'title': '镜潮命名资料',
          'content_payload': <String, Object?>{'pattern': '镜与潮共同指向身份回返'},
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': 'research_note',
                'source_id': 'research-001',
              },
              'source_authority':
                  InformationSourceAuthorities.externalResearched,
              'role_authority': InformationRoleAuthorities.researcher,
              'research_depth': InformationResearchDepths.deep,
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.reference,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.referenceOnly,
            'citation_risk_level': InformationCitationRiskLevels.normal,
          },
          'confidence': 0.73,
          'lifecycle_status': InformationLifecycleStatuses.proposed,
        });
        final researchNote = ResearchNote.fromJson(<String, Object?>{
          'research_id': 'research-001',
          'query': '镜潮神话中的身份回返',
          'source_kind': 'web_article',
          'source_url_or_ref': 'https://example.com/mirror-tide',
          'citation': '《镜潮神话》研究摘要',
          'summary': '镜与潮在外部资料中经常被并置为身份映照意象。',
          'usable_facts': <Object?>['镜与潮常共同承担身份映照功能。'],
          'creative_suggestions': <Object?>['可用于章节开头和结尾的结构回扣。'],
          'created_by': 'researcher.agent',
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.referenceOnly,
            'citation_risk_level': InformationCitationRiskLevels.highRisk,
            'requires_confirmation': true,
          },
        });

        final knowledgeDecision = service.decideKnowledgeCard(knowledgeCard);
        final noteDecision = service.decideResearchNote(researchNote);

        expect(
          knowledgeDecision.disposition,
          InformationPermissionDispositions.proposed,
        );
        expect(
          noteDecision.disposition,
          InformationPermissionDispositions.autoAccept,
        );
        expect(
          ValueReaders.stringValue(
            noteDecision.metadata['promotion_disposition'],
          ),
          InformationPermissionDispositions.proposed,
        );
      },
    );

    test(
      'high-risk reference works and long-term rule modifications require confirmation',
      () {
        const service = InformationPermissionPolicyService();
        final referenceWork = ReferenceWorkRecord.fromJson(<String, Object?>{
          'reference_work_id': 'reference-001',
          'title': '雾海镜宫',
          'creator': '沈归舟',
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
                'source_id': 'user-reference-001',
              },
              'source_authority': InformationSourceAuthorities.userDeclared,
              'role_authority': InformationRoleAuthorities.user,
              'research_depth': InformationResearchDepths.none,
            },
          ],
          'relationship_to_project': 'fanfic_reference',
          'declared_usage_intent': '同人续写练习，借用角色与世界观骨架。',
          'requires_confirmation': true,
        });
        final designElement = DesignElementCard.fromJson(<String, Object?>{
          'design_id': 'design-002',
          'design_namespace': 'writing.main',
          'design_label': '结构换轨',
          'design_payload': <String, Object?>{'change': '从线性叙事改成双时空并行'},
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
                'source_id': 'user-design-002',
              },
              'source_authority': InformationSourceAuthorities.userDeclared,
              'role_authority': InformationRoleAuthorities.user,
              'research_depth': InformationResearchDepths.none,
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.required,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.92,
          'lifecycle_status': InformationLifecycleStatuses.proposed,
          'modifies_long_term_rule': true,
        });

        expect(
          service.decideReferenceWork(referenceWork).disposition,
          InformationPermissionDispositions.needsUserConfirmation,
        );
        expect(
          service.decideDesignElement(designElement).disposition,
          InformationPermissionDispositions.needsUserConfirmation,
        );
      },
    );

    test('external research request defaults to no auto network', () {
      const service = InformationPermissionPolicyService();

      final gated = service.decideExternalResearchRequest(
        query: '北欧神话中镜与海的并置意象',
        requestedBy: InformationRoleAuthorities.researcher,
      );
      final granted = service.decideExternalResearchRequest(
        query: '城市命名与方位象征',
        requestedBy: InformationRoleAuthorities.researcher,
        userGrantedNetworkAccess: true,
      );

      expect(
        gated.disposition,
        InformationPermissionDispositions.needsUserConfirmation,
      );
      expect(granted.disposition, InformationPermissionDispositions.autoAccept);
    });

    test('forbidden script-like payload is blocked from auto apply', () {
      const service = InformationPermissionPolicyService();
      final referenceWork = ReferenceWorkRecord.fromJson(<String, Object?>{
        'reference_work_id': 'reference-002',
        'title': '危险载荷',
        'source_refs': <Object?>[
          <String, Object?>{
            'source_ref': <String, Object?>{
              'source_type': NarrativeSourceTypes.system,
              'source_id': 'system-reference-002',
            },
            'source_authority': InformationSourceAuthorities.sourceDocument,
            'role_authority': InformationRoleAuthorities.system,
            'research_depth': InformationResearchDepths.none,
          },
        ],
        'relationship_to_project': 'inspiration',
        'declared_usage_intent': '普通参考',
        'script': 'rm -rf /',
      });

      expect(
        service.decideReferenceWork(referenceWork).disposition,
        InformationPermissionDispositions.forbiddenAutoApply,
      );
    });
  });
}
