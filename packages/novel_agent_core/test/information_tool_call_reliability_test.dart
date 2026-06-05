import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information tool call reliability', () {
    test(
      'writer can submit knowledge and design deltas through structured information tools',
      () async {
        final harness = _MockInformationToolCallHarness();

        final knowledgeOutcome = await harness.invoke(
          callId: 'writer-knowledge-001',
          toolName: NarrativeDomainToolNames.proposeKnowledgeCard,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
            sourceId: 'writer-agent',
          ),
          arguments: <String, Object?>{
            'card_id': 'knowledge-001',
            'card_namespace': 'project.world',
            'card_type': 'world_rule',
            'title': '雾潮夜的记忆回声',
            'summary': '雾潮夜会放大最近失去的记忆。',
            'content_payload': <String, Object?>{'rule': '雾潮夜会放大最近失去的记忆'},
            'source_refs': <Object?>[
              _informationSourceRefJson(
                sourceType: NarrativeSourceTypes.user,
                sourceId: 'user-seed-001',
                sourceAuthority: InformationSourceAuthorities.userDeclared,
                roleAuthority: InformationRoleAuthorities.user,
                researchDepth: InformationResearchDepths.none,
              ),
            ],
            'activation_policy': _activationPolicyJson(
              InformationActivationPriorities.required,
            ),
            'usage_policy': _usagePolicyJson(
              InformationUsageModes.normal,
              InformationCitationRiskLevels.low,
            ),
            'confidence': 0.91,
          },
        );
        final designOutcome = await harness.invoke(
          callId: 'writer-design-001',
          toolName: NarrativeDomainToolNames.proposeDesignElement,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
            sourceId: 'writer-agent',
          ),
          arguments: <String, Object?>{
            'design_id': 'design-001',
            'design_namespace': 'project.structure',
            'design_label': '潮声回扣',
            'design_payload': <String, Object?>{
              'pattern': '每章结尾的潮声反向解释开头的镜像描写',
            },
            'source_refs': <Object?>[
              _informationSourceRefJson(
                sourceType: NarrativeSourceTypes.writer,
                sourceId: 'writer-agent',
                sourceAuthority: InformationSourceAuthorities.aiInferred,
                roleAuthority: InformationRoleAuthorities.writer,
                researchDepth: InformationResearchDepths.quick,
              ),
            ],
            'linked_refs': <Object?>[
              <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'knowledge-001',
              },
            ],
            'activation_policy': _activationPolicyJson(
              InformationActivationPriorities.pinned,
            ),
            'usage_policy': _usagePolicyJson(
              InformationUsageModes.normal,
              InformationCitationRiskLevels.low,
            ),
            'confidence': 0.77,
            'uncertainty': '后续章节仍需验证呼应密度。',
          },
        );

        expect(
          knowledgeOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.accepted,
        );
        expect(
          knowledgeOutcome.outcomePayload.containsKey('knowledge_card'),
          isTrue,
        );
        expect(
          knowledgeOutcome.outcomePayload.containsKey('written_paths'),
          isFalse,
        );
        expect(designOutcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        expect(
          designOutcome.outcomePayload.containsKey('design_element'),
          isTrue,
        );
        expect(
          designOutcome.outcomePayload.containsKey('prompt_hint'),
          isFalse,
        );
      },
    );

    test(
      'deconstructor can reliably submit first class design element proposals',
      () async {
        final harness = _MockInformationToolCallHarness();

        final outcome = await harness.invoke(
          callId: 'deconstructor-design-001',
          toolName: NarrativeDomainToolNames.proposeDesignElement,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.deconstruction,
            sourceId: 'deconstructor-agent',
          ),
          arguments: <String, Object?>{
            'design_id': 'design-002',
            'design_namespace': 'analysis.symbolism',
            'design_label': '命名暗线',
            'design_payload': <String, Object?>{'pattern': '地名都与潮汐方向相呼应'},
            'source_refs': <Object?>[
              _informationSourceRefJson(
                sourceType: NarrativeSourceTypes.deconstruction,
                sourceId: 'source-book',
                sourceAuthority:
                    InformationSourceAuthorities.deconstructionExtracted,
                roleAuthority: InformationRoleAuthorities.deconstructor,
                researchDepth: InformationResearchDepths.none,
              ),
            ],
            'evidence_refs': <Object?>[
              <String, Object?>{
                'evidence_type': NarrativeEvidenceTypes.extractedSnippet,
                'evidence_id': 'snippet-001',
                'summary': '拆书片段摘要',
              },
            ],
            'activation_policy': _activationPolicyJson(
              InformationActivationPriorities.reference,
            ),
            'usage_policy': _usagePolicyJson(
              InformationUsageModes.referenceOnly,
              InformationCitationRiskLevels.normal,
            ),
            'confidence': 0.72,
          },
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        expect(outcome.outcomePayload.containsKey('design_element'), isTrue);
        expect(outcome.outcomePayload.containsKey('proposal'), isFalse);
        expect(outcome.outcomePayload['linked_ref_count'], 0);
      },
    );

    test(
      'researcher style flow can request research then submit note without raw gateway execution',
      () async {
        final harness = _MockInformationToolCallHarness();

        final requestOutcome = await harness.invoke(
          callId: 'researcher-request-001',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.system,
            sourceId: 'researcher-agent',
          ),
          arguments: <String, Object?>{
            'query': '古典星图中的命运三联象征',
            'purpose': '补充章节标题与命运母题的外部资料',
            'requested_depth': InformationResearchDepths.standard,
            'reference_relationship': 'inspiration',
            'user_granted_network_access': true,
            'metadata': <String, Object?>{'agent_role': 'researcher'},
          },
        );
        final noteOutcome = await harness.invoke(
          callId: 'researcher-note-001',
          toolName: NarrativeDomainToolNames.submitResearchNote,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.system,
            sourceId: 'researcher-agent',
          ),
          arguments: <String, Object?>{
            'research_id': 'research-001',
            'query': '古典星图中的命运三联象征',
            'source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/star-symbols',
            'citation': 'Classical Star Symbols',
            'summary': '整理出三联星象常用于命运提示的写法。',
            'usable_facts': <Object?>['三联星经常承担命运并置提示'],
            'creative_suggestions': <Object?>['可映射为卷标题结构'],
            'created_by': 'researcher-agent',
            'usage_policy': _usagePolicyJson(
              InformationUsageModes.referenceOnly,
              InformationCitationRiskLevels.normal,
            ),
          },
        );

        expect(
          requestOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.accepted,
        );
        expect(
          requestOutcome.outcomePayload['network_execution_performed'],
          isFalse,
        );
        expect(requestOutcome.outcomePayload['request_registered'], isTrue);
        expect(noteOutcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        expect(noteOutcome.outcomePayload['stored_as_research_note'], isTrue);
        expect(
          noteOutcome.outcomePayload['promotion_disposition'],
          InformationPermissionDispositions.proposed,
        );
      },
    );

    test('reviewer can link evidence through information link tool', () async {
      final harness = _MockInformationToolCallHarness();

      final outcome = await harness.invoke(
        callId: 'reviewer-link-001',
        toolName: NarrativeDomainToolNames.linkInformationEvidence,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.reviewer,
          sourceId: 'reviewer-agent',
        ),
        arguments: <String, Object?>{
          'link_id': 'link-001',
          'link_type': 'supports_knowledge',
          'source_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.researchNote,
            'ref_id': 'research-001',
          },
          'target_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.knowledgeCard,
            'ref_id': 'knowledge-001',
          },
          'summary': '研究资料支持知识卡中的命名规则。',
          'created_by': 'reviewer-agent',
        },
      );

      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
      expect(outcome.outcomePayload['link_registered'], isTrue);
      expect(
        (outcome.outcomePayload['source_ref']
            as Map<String, Object?>)['ref_type'],
        InformationLinkedRefTypes.researchNote,
      );
    });

    test(
      'high risk reference work stays in waiting user confirmation instead of silent ingestion',
      () async {
        final harness = _MockInformationToolCallHarness();

        final outcome = await harness.invoke(
          callId: 'reference-work-001',
          toolName: NarrativeDomainToolNames.proposeReferenceWork,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.user,
            sourceId: 'user-001',
          ),
          arguments: <String, Object?>{
            'reference_work_id': 'reference-001',
            'title': '雾海镜宫',
            'source_refs': <Object?>[
              _informationSourceRefJson(
                sourceType: NarrativeSourceTypes.user,
                sourceId: 'user-001',
                sourceAuthority: InformationSourceAuthorities.userDeclared,
                roleAuthority: InformationRoleAuthorities.user,
                researchDepth: InformationResearchDepths.none,
              ),
            ],
            'relationship_to_project': 'fanfic_reference',
            'declared_usage_intent': '同人续写练习',
            'risk_notes': <Object?>['沿用外部角色与世界观骨架'],
          },
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(outcome.outcomePayload['requires_user_confirmation'], isTrue);
        expect(outcome.outcomePayload.containsKey('reference_work'), isTrue);
      },
    );

    test(
      'raw write project file and request gateway tool are not equivalent to information ingestion',
      () async {
        final harness = _MockInformationToolCallHarness();

        final rawWriteProjectFile = harness.catalog.parseRequest(
          callId: 'raw-write-001',
          toolName: 'write_project_file',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
          arguments: <String, Object?>{
            'relative_path': 'knowledge/世界观.md',
            'content': '只是写了一个文件，并没有形成结构化信息卡。',
          },
        );
        final rawRequestGatewayTool = harness.catalog.parseRequest(
          callId: 'raw-gateway-001',
          toolName: 'request_gateway_tool',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.system,
          ),
          arguments: <String, Object?>{
            'tool_name': 'search_internet',
            'arguments': <String, Object?>{'query': '雾潮象征'},
          },
        );

        expect(rawWriteProjectFile.isSuccess, isFalse);
        expect(rawRequestGatewayTool.isSuccess, isFalse);
        expect(
          rawWriteProjectFile.issues.single.code,
          NarrativeDomainToolValidationCodes.unknownToolName,
        );
        expect(
          rawRequestGatewayTool.issues.single.code,
          NarrativeDomainToolValidationCodes.unknownToolName,
        );
      },
    );
  });
}

class _MockInformationToolCallHarness {
  _MockInformationToolCallHarness()
    : catalog = NarrativeDomainToolCatalog(),
      _handlers = <String, NarrativeDomainToolHandler>{
        NarrativeDomainToolNames.requestExternalResearch:
            const RequestExternalResearchHandler(),
        NarrativeDomainToolNames.submitResearchNote:
            const SubmitResearchNoteHandler(),
        NarrativeDomainToolNames.proposeKnowledgeCard:
            const ProposeKnowledgeCardHandler(),
        NarrativeDomainToolNames.proposeDesignElement:
            const ProposeDesignElementHandler(),
        NarrativeDomainToolNames.linkInformationEvidence:
            const LinkInformationEvidenceHandler(),
        NarrativeDomainToolNames.proposeReferenceWork:
            const ProposeReferenceWorkHandler(),
      };

  final NarrativeDomainToolCatalog catalog;
  final Map<String, NarrativeDomainToolHandler> _handlers;

  Future<DomainToolOutcome> invoke({
    required String callId,
    required String toolName,
    required NarrativeSourceRef source,
    required Map<String, Object?> arguments,
  }) async {
    // 中文注释: 这里模拟一次纯 core toolcall 链，只走 schema parse + handler，不依赖 dispatcher、provider 或 adapters。
    final parsed = catalog.parseRequest(
      callId: callId,
      toolName: toolName,
      source: source,
      arguments: arguments,
    );
    expect(parsed.isSuccess, isTrue, reason: 'mock toolcall 应先通过 catalog 解析。');
    final handler = _handlers[toolName];
    expect(
      handler,
      isNotNull,
      reason: '每个 PIS-13 场景都必须命中对应 information handler。',
    );
    return handler!.handle(
      request: parsed.request!,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
    );
  }
}

Map<String, Object?> _informationSourceRefJson({
  required String sourceType,
  required String sourceId,
  required String sourceAuthority,
  required String roleAuthority,
  required String researchDepth,
}) {
  // 中文注释: 测试里统一构造信息来源引用，避免每个场景手写一套近似但略有偏差的 source_ref。
  return <String, Object?>{
    'source_ref': <String, Object?>{
      'source_type': sourceType,
      'source_id': sourceId,
    },
    'source_authority': sourceAuthority,
    'role_authority': roleAuthority,
    'research_depth': researchDepth,
  };
}

Map<String, Object?> _activationPolicyJson(String priority) {
  // 中文注释: reliability tests 只关心策略壳层是否稳定存在，不在这里重复激活算法细节。
  return <String, Object?>{
    'activation_priority': priority,
    'preferred_budget_chars': 240,
  };
}

Map<String, Object?> _usagePolicyJson(String usageMode, String citationRisk) {
  // 中文注释: 统一最小使用策略，确保 mock tests 聚焦工具提交通路而不是重复铺开 policy 变体。
  return <String, Object?>{
    'usage_mode': usageMode,
    'citation_risk_level': citationRisk,
    'allows_derivative_use': true,
  };
}
