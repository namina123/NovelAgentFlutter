import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('local project information repositories', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectInformationPathService pathService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-project-information-repositories-',
      );
      workspacePort = LocalProjectWorkspacePort();
      pathService = ProjectInformationPathService();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'path service keeps every repository under hidden information tree',
      () {
        expect(
          pathService.knowledgeCardPath('knowledge-1'),
          '.novel_agent/information/knowledge_cards/knowledge-1.json',
        );
        expect(
          pathService.designElementPath('design-1'),
          '.novel_agent/information/design_elements/design-1.json',
        );
        expect(
          pathService.researchNotePath('research-1'),
          '.novel_agent/information/research_notes/research-1.json',
        );
        expect(
          pathService.referenceWorkPath('reference-1'),
          '.novel_agent/information/reference_works/reference-1.json',
        );
        expect(
          pathService.informationLinksLogPath(),
          '.novel_agent/information/links/links.jsonl',
        );
        expect(
          pathService.informationEventsLogPath(),
          '.novel_agent/information/events/events.jsonl',
        );
      },
    );

    test(
      'json repositories persist hidden files and keep unknown payload round trip',
      () async {
        final knowledgeRepository = LocalKnowledgeCardRepository(
          workspacePort: workspacePort,
        );
        final designRepository = LocalDesignElementRepository(
          workspacePort: workspacePort,
        );
        final researchRepository = LocalResearchNoteRepository(
          workspacePort: workspacePort,
        );
        final referenceRepository = LocalReferenceWorkRepository(
          workspacePort: workspacePort,
        );

        final knowledgeCard = ProjectKnowledgeCard.fromJson(<String, Object?>{
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
          'lifecycle_status': InformationLifecycleStatuses.accepted,
        });
        final designElement = DesignElementCard.fromJson(<String, Object?>{
          'design_id': 'design-1',
          'design_namespace': 'project.structure',
          'design_label': '潮声回扣',
          'design_payload': <String, Object?>{
            'pattern': '章末潮声回扣章首镜面',
            'unknown_payload': <String, Object?>{'phase': 'vol1'},
          },
          'source_refs': <Object?>[
            _sourceRefJson(
              sourceAuthority: InformationSourceAuthorities.aiInferred,
              roleAuthority: InformationRoleAuthorities.writer,
              researchDepth: InformationResearchDepths.quick,
            ),
          ],
          'activation_policy': _activationPolicyJson(
            priority: InformationActivationPriorities.pinned,
          ),
          'usage_policy': _usagePolicyJson(),
          'lifecycle_status': InformationLifecycleStatuses.proposed,
        });
        final researchNote = ResearchNote.fromJson(<String, Object?>{
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
          'unknown_top_level': 'preserved',
        });
        final referenceWork = ReferenceWorkRecord.fromJson(<String, Object?>{
          'reference_work_id': 'reference-1',
          'title': '雾海镜宫',
          'source_refs': <Object?>[_sourceRefJson()],
          'relationship_to_project': 'fanfic_reference',
          'declared_usage_intent': '同人练习',
          'risk_notes': <Object?>[
            <String, Object?>{'level': 'high', 'reason': '外部作品边界'},
          ],
          'future_unknown_field': <String, Object?>{'keep': true},
        });

        await knowledgeRepository.appendKnowledgeCard(project, knowledgeCard);
        await designRepository.appendDesignElement(project, designElement);
        await researchRepository.appendResearchNote(project, researchNote);
        await referenceRepository.appendReferenceWork(project, referenceWork);

        final loadedKnowledge = await knowledgeRepository.readKnowledgeCard(
          project,
          cardId: 'knowledge-1',
        );
        final loadedDesign = await designRepository.readDesignElement(
          project,
          designId: 'design-1',
        );
        final loadedResearch = await researchRepository.readResearchNote(
          project,
          researchId: 'research-1',
        );
        final loadedReference = await referenceRepository.readReferenceWork(
          project,
          referenceWorkId: 'reference-1',
        );

        expect(loadedKnowledge, isNotNull);
        expect(
          loadedKnowledge!.contentPayload['unknown_payload'],
          <String, Object?>{'rarity': 'high'},
        );
        expect(loadedDesign, isNotNull);
        expect(
          loadedDesign!.designPayload['unknown_payload'],
          <String, Object?>{'phase': 'vol1'},
        );
        expect(loadedResearch, isNotNull);
        expect(loadedResearch!.toJson()['unknown_top_level'], 'preserved');
        expect(loadedReference, isNotNull);
        expect(
          (loadedReference!.toJson()['future_unknown_field']
              as Map<String, Object?>)['keep'],
          isTrue,
        );

        final knowledgeFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}knowledge-1.json',
        );
        final designFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}design_elements${Platform.pathSeparator}design-1.json',
        );
        final researchFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}research-1.json',
        );
        final referenceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}reference_works${Platform.pathSeparator}reference-1.json',
        );
        expect(await knowledgeFile.exists(), isTrue);
        expect(await designFile.exists(), isTrue);
        expect(await researchFile.exists(), isTrue);
        expect(await referenceFile.exists(), isTrue);
      },
    );

    test(
      'json repositories support update and filtered listing inside hidden information tree',
      () async {
        final knowledgeRepository = LocalKnowledgeCardRepository(
          workspacePort: workspacePort,
        );
        final researchRepository = LocalResearchNoteRepository(
          workspacePort: workspacePort,
        );

        await knowledgeRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard.fromJson(<String, Object?>{
            'card_id': 'knowledge-1',
            'card_namespace': 'project.world',
            'card_type': 'world_rule',
            'title': '旧规则',
            'content_payload': <String, Object?>{'rule': 'old'},
            'source_refs': <Object?>[_sourceRefJson()],
            'activation_policy': _activationPolicyJson(),
            'usage_policy': _usagePolicyJson(),
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          }),
        );
        await knowledgeRepository.updateKnowledgeCard(
          project,
          ProjectKnowledgeCard.fromJson(<String, Object?>{
            'card_id': 'knowledge-1',
            'card_namespace': 'project.world',
            'card_type': 'world_rule',
            'title': '新规则',
            'content_payload': <String, Object?>{'rule': 'new'},
            'source_refs': <Object?>[_sourceRefJson()],
            'activation_policy': _activationPolicyJson(),
            'usage_policy': _usagePolicyJson(),
            'lifecycle_status': InformationLifecycleStatuses.accepted,
          }),
        );
        await researchRepository.appendResearchNote(
          project,
          ResearchNote.fromJson(<String, Object?>{
            'research_id': 'research-1',
            'query': '镜潮',
            'source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/1',
            'citation': 'One',
            'summary': 'one',
            'created_by': 'agent',
            'usage_policy': _usagePolicyJson(),
          }),
        );
        await researchRepository.appendResearchNote(
          project,
          ResearchNote.fromJson(<String, Object?>{
            'research_id': 'research-2',
            'query': '星图',
            'source_kind': 'archive',
            'source_url_or_ref': 'archive://2',
            'citation': 'Two',
            'summary': 'two',
            'created_by': 'agent',
            'usage_policy': _usagePolicyJson(),
          }),
        );

        final updatedKnowledge = await knowledgeRepository.readKnowledgeCard(
          project,
          cardId: 'knowledge-1',
        );
        final filteredResearch = await researchRepository.listResearchNotes(
          project,
          sourceKind: 'web_article',
        );

        expect(updatedKnowledge?.title, '新规则');
        expect(updatedKnowledge?.contentPayload['rule'], 'new');
        expect(filteredResearch, hasLength(1));
        expect(filteredResearch.single.researchId, 'research-1');
      },
    );

    test(
      'jsonl repositories keep unknown payload and latest record semantics',
      () async {
        final linkRepository = LocalInformationLinkRepository(
          workspacePort: workspacePort,
        );
        final eventRepository = LocalInformationEventRepository(
          workspacePort: workspacePort,
        );

        await linkRepository.appendInformationLink(
          project,
          InformationLink.fromJson(<String, Object?>{
            'link_id': 'link-1',
            'link_type': 'supports',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.researchNote,
              'ref_id': 'research-1',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.knowledgeCard,
              'ref_id': 'knowledge-1',
            },
            'future_unknown_field': <String, Object?>{'keep': true},
          }),
        );
        await linkRepository.updateInformationLink(
          project,
          InformationLink.fromJson(<String, Object?>{
            'link_id': 'link-1',
            'link_type': 'supports',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.researchNote,
              'ref_id': 'research-1',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.knowledgeCard,
              'ref_id': 'knowledge-1',
            },
            'summary': 'updated summary',
            'future_unknown_field': <String, Object?>{'keep': 'latest'},
          }),
        );
        await eventRepository.appendInformationEvent(
          project,
          InformationEvent.fromJson(<String, Object?>{
            'event_id': 'event-1',
            'event_type': 'accepted',
            'subject_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.knowledgeCard,
              'ref_id': 'knowledge-1',
            },
            'lifecycle_status': InformationLifecycleStatuses.accepted,
            'actor_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.toolRound,
              'ref_id': 'tool-round-1',
            },
            'future_unknown_field': <String, Object?>{'keep': true},
          }),
        );

        final loadedLink = await linkRepository.readInformationLink(
          project,
          linkId: 'link-1',
        );
        final loadedEvent = await eventRepository.readInformationEvent(
          project,
          eventId: 'event-1',
        );
        final filteredLinks = await linkRepository.listInformationLinks(
          project,
          sourceRefId: 'research-1',
        );
        final filteredEvents = await eventRepository.listInformationEvents(
          project,
          lifecycleStatus: InformationLifecycleStatuses.accepted,
        );

        expect(loadedLink, isNotNull);
        expect(loadedLink!.summary, 'updated summary');
        expect(
          (loadedLink.toJson()['future_unknown_field']
              as Map<String, Object?>)['keep'],
          'latest',
        );
        expect(loadedEvent, isNotNull);
        expect(
          (loadedEvent!.toJson()['future_unknown_field']
              as Map<String, Object?>)['keep'],
          isTrue,
        );
        expect(filteredLinks, hasLength(1));
        expect(filteredEvents, hasLength(1));

        final linkLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}links${Platform.pathSeparator}links.jsonl',
        );
        final eventLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}events${Platform.pathSeparator}events.jsonl',
        );
        expect(await linkLog.exists(), isTrue);
        expect(await eventLog.exists(), isTrue);
        expect(
          await linkLog.readAsString(),
          contains('"future_unknown_field"'),
        );
        expect(
          await eventLog.readAsString(),
          contains('"future_unknown_field"'),
        );
      },
    );
  });
}

Map<String, Object?> _sourceRefJson({
  String sourceType = NarrativeSourceTypes.user,
  String sourceId = 'source-1',
  String sourceAuthority = InformationSourceAuthorities.userDeclared,
  String roleAuthority = InformationRoleAuthorities.user,
  String researchDepth = InformationResearchDepths.none,
}) {
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
