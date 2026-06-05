import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information repository ports', () {
    test(
      'in-memory fakes expose append read list update semantics clearly',
      () async {
        const project = ProjectDescriptor(
          id: 'project-001',
          name: 'PIS fake repo',
          rootPath: '/workspace/project-001',
        );
        final fake = _InMemoryInformationRepositoryBundle();

        final knowledgeCard = ProjectKnowledgeCard.fromJson(<String, Object?>{
          'card_id': 'knowledge-001',
          'card_namespace': 'writing.main',
          'card_type': 'world_rule',
          'title': '月潮规则',
          'content_payload': <String, Object?>{'rule': '月潮夜会放大记忆回声'},
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
          'confidence': 0.9,
          'lifecycle_status': InformationLifecycleStatuses.active,
        });
        final designCard = DesignElementCard.fromJson(<String, Object?>{
          'design_id': 'design-001',
          'design_namespace': 'writing.main',
          'design_label': '镜潮回扣',
          'design_payload': <String, Object?>{'motif': '镜面和潮声总在章末互相解释'},
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-design-001',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': <String, Object?>{
            'activation_priority': InformationActivationPriorities.pinned,
          },
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.75,
          'uncertainty': '仍需后续章节验证。',
          'lifecycle_status': InformationLifecycleStatuses.proposed,
        });
        final researchNote = ResearchNote.fromJson(<String, Object?>{
          'research_id': 'research-001',
          'query': '海镜神话中的身份回返',
          'source_kind': 'web_article',
          'source_url_or_ref': 'https://example.com/mirror-tide',
          'citation': '《海镜神话》研究摘要',
          'summary': '镜与潮常共同承担身份映照功能。',
          'usable_facts': <Object?>['镜与潮在神话里常被并置。'],
          'creative_suggestions': <Object?>['可把镜潮作为章节结构回扣。'],
          'created_by': 'researcher.agent',
          'usage_policy': <String, Object?>{
            'usage_mode': InformationUsageModes.referenceOnly,
            'citation_risk_level': InformationCitationRiskLevels.normal,
          },
        });
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
          'relationship_to_project': 'inspiration',
          'declared_usage_intent': '仅借鉴空间结构和象征边界。',
        });
        final link = InformationLink.fromJson(<String, Object?>{
          'link_id': 'link-001',
          'link_type': 'supports_design',
          'source_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.researchNote,
            'ref_id': 'research-001',
          },
          'target_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.designElement,
            'ref_id': 'design-001',
          },
        });
        final event = InformationEvent.fromJson(<String, Object?>{
          'event_id': 'event-001',
          'event_type': 'information_proposed',
          'subject_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.designElement,
            'ref_id': 'design-001',
          },
          'lifecycle_status': InformationLifecycleStatuses.proposed,
          'actor_ref': <String, Object?>{
            'ref_type': 'writer_role',
            'ref_id': 'writer-primary',
          },
        });

        await fake.knowledgeCards.appendKnowledgeCard(project, knowledgeCard);
        await fake.designElements.appendDesignElement(project, designCard);
        await fake.researchNotes.appendResearchNote(project, researchNote);
        await fake.referenceWorks.appendReferenceWork(project, referenceWork);
        await fake.links.appendInformationLink(project, link);
        await fake.events.appendInformationEvent(project, event);

        expect(
          (await fake.knowledgeCards.readKnowledgeCard(
            project,
            cardId: 'knowledge-001',
          ))?.title,
          '月潮规则',
        );
        expect(
          (await fake.designElements.readDesignElement(
            project,
            designId: 'design-001',
          ))?.designLabel,
          '镜潮回扣',
        );
        expect(
          (await fake.researchNotes.readResearchNote(
            project,
            researchId: 'research-001',
          ))?.sourceKind,
          'web_article',
        );
        expect(
          (await fake.referenceWorks.readReferenceWork(
            project,
            referenceWorkId: 'reference-001',
          ))?.relationshipToProject,
          'inspiration',
        );
        expect(
          (await fake.links.readInformationLink(
            project,
            linkId: 'link-001',
          ))?.linkType,
          'supports_design',
        );
        expect(
          (await fake.events.readInformationEvent(
            project,
            eventId: 'event-001',
          ))?.eventType,
          'information_proposed',
        );

        expect(
          await fake.knowledgeCards.listKnowledgeCards(
            project,
            cardNamespace: 'writing.main',
          ),
          hasLength(1),
        );
        expect(
          await fake.designElements.listDesignElements(
            project,
            designNamespace: 'writing.main',
          ),
          hasLength(1),
        );
        expect(
          await fake.researchNotes.listResearchNotes(
            project,
            sourceKind: 'web_article',
          ),
          hasLength(1),
        );
        expect(
          await fake.referenceWorks.listReferenceWorks(
            project,
            relationshipToProject: 'inspiration',
          ),
          hasLength(1),
        );
        expect(
          await fake.links.listInformationLinks(
            project,
            targetRefId: 'design-001',
          ),
          hasLength(1),
        );
        expect(
          await fake.events.listInformationEvents(
            project,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
          hasLength(1),
        );

        await fake.knowledgeCards.updateKnowledgeCard(
          project,
          knowledgeCard.copyWith(title: '月潮规则（修订）'),
        );
        await fake.designElements.updateDesignElement(
          project,
          designCard.copyWith(
            lifecycleStatus: InformationLifecycleStatuses.active,
          ),
        );
        await fake.researchNotes.updateResearchNote(
          project,
          researchNote.copyWith(sourceKind: 'gateway_search'),
        );
        await fake.referenceWorks.updateReferenceWork(
          project,
          referenceWork.copyWith(relationshipToProject: 'deconstructed_source'),
        );
        await fake.links.updateInformationLink(
          project,
          link.copyWith(linkType: 'grounds_design'),
        );
        await fake.events.updateInformationEvent(
          project,
          event.copyWith(
            lifecycleStatus: InformationLifecycleStatuses.accepted,
            eventType: 'information_accepted',
          ),
        );

        expect(
          (await fake.knowledgeCards.readKnowledgeCard(
            project,
            cardId: 'knowledge-001',
          ))?.title,
          '月潮规则（修订）',
        );
        expect(
          (await fake.designElements.readDesignElement(
            project,
            designId: 'design-001',
          ))?.lifecycleStatus,
          InformationLifecycleStatuses.active,
        );
        expect(
          (await fake.researchNotes.readResearchNote(
            project,
            researchId: 'research-001',
          ))?.sourceKind,
          'gateway_search',
        );
        expect(
          (await fake.referenceWorks.readReferenceWork(
            project,
            referenceWorkId: 'reference-001',
          ))?.relationshipToProject,
          'deconstructed_source',
        );
        expect(
          (await fake.links.readInformationLink(
            project,
            linkId: 'link-001',
          ))?.linkType,
          'grounds_design',
        );
        expect(
          (await fake.events.readInformationEvent(
            project,
            eventId: 'event-001',
          ))?.lifecycleStatus,
          InformationLifecycleStatuses.accepted,
        );
      },
    );
  });
}

class _InMemoryInformationRepositoryBundle {
  _InMemoryInformationRepositoryBundle()
    : knowledgeCards = _FakeKnowledgeCardRepository(),
      designElements = _FakeDesignElementRepository(),
      researchNotes = _FakeResearchNoteRepository(),
      referenceWorks = _FakeReferenceWorkRepository(),
      links = _FakeInformationLinkRepository(),
      events = _FakeInformationEventRepository();

  final _FakeKnowledgeCardRepository knowledgeCards;
  final _FakeDesignElementRepository designElements;
  final _FakeResearchNoteRepository researchNotes;
  final _FakeReferenceWorkRepository referenceWorks;
  final _FakeInformationLinkRepository links;
  final _FakeInformationEventRepository events;
}

class _FakeKnowledgeCardRepository implements KnowledgeCardRepository {
  final Map<String, Map<String, ProjectKnowledgeCard>> _cardsByProject =
      <String, Map<String, ProjectKnowledgeCard>>{};

  @override
  Future<void> appendKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) async {
    _cardsByProject.putIfAbsent(
      project.id,
      () => <String, ProjectKnowledgeCard>{},
    )[card.cardId] = card;
  }

  @override
  Future<List<ProjectKnowledgeCard>> listKnowledgeCards(
    ProjectDescriptor project, {
    String? cardNamespace,
  }) async {
    final items =
        _cardsByProject[project.id]?.values.toList(growable: false) ??
        const <ProjectKnowledgeCard>[];
    if (cardNamespace == null || cardNamespace.trim().isEmpty) {
      return items;
    }
    return items
        .where((entry) => entry.cardNamespace == cardNamespace)
        .toList(growable: false);
  }

  @override
  Future<ProjectKnowledgeCard?> readKnowledgeCard(
    ProjectDescriptor project, {
    required String cardId,
  }) async {
    return _cardsByProject[project.id]?[cardId];
  }

  @override
  Future<void> updateKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) async {
    _cardsByProject.putIfAbsent(
      project.id,
      () => <String, ProjectKnowledgeCard>{},
    )[card.cardId] = card;
  }
}

class _FakeDesignElementRepository implements DesignElementRepository {
  final Map<String, Map<String, DesignElementCard>> _cardsByProject =
      <String, Map<String, DesignElementCard>>{};

  @override
  Future<void> appendDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) async {
    _cardsByProject.putIfAbsent(
      project.id,
      () => <String, DesignElementCard>{},
    )[card.designId] = card;
  }

  @override
  Future<List<DesignElementCard>> listDesignElements(
    ProjectDescriptor project, {
    String? designNamespace,
  }) async {
    final items =
        _cardsByProject[project.id]?.values.toList(growable: false) ??
        const <DesignElementCard>[];
    if (designNamespace == null || designNamespace.trim().isEmpty) {
      return items;
    }
    return items
        .where((entry) => entry.designNamespace == designNamespace)
        .toList(growable: false);
  }

  @override
  Future<DesignElementCard?> readDesignElement(
    ProjectDescriptor project, {
    required String designId,
  }) async {
    return _cardsByProject[project.id]?[designId];
  }

  @override
  Future<void> updateDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) async {
    _cardsByProject.putIfAbsent(
      project.id,
      () => <String, DesignElementCard>{},
    )[card.designId] = card;
  }
}

class _FakeResearchNoteRepository implements ResearchNoteRepository {
  final Map<String, Map<String, ResearchNote>> _notesByProject =
      <String, Map<String, ResearchNote>>{};

  @override
  Future<void> appendResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) async {
    _notesByProject.putIfAbsent(
      project.id,
      () => <String, ResearchNote>{},
    )[note.researchId] = note;
  }

  @override
  Future<List<ResearchNote>> listResearchNotes(
    ProjectDescriptor project, {
    String? sourceKind,
  }) async {
    final items =
        _notesByProject[project.id]?.values.toList(growable: false) ??
        const <ResearchNote>[];
    if (sourceKind == null || sourceKind.trim().isEmpty) {
      return items;
    }
    return items
        .where((entry) => entry.sourceKind == sourceKind)
        .toList(growable: false);
  }

  @override
  Future<ResearchNote?> readResearchNote(
    ProjectDescriptor project, {
    required String researchId,
  }) async {
    return _notesByProject[project.id]?[researchId];
  }

  @override
  Future<void> updateResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) async {
    _notesByProject.putIfAbsent(
      project.id,
      () => <String, ResearchNote>{},
    )[note.researchId] = note;
  }
}

class _FakeReferenceWorkRepository implements ReferenceWorkRepository {
  final Map<String, Map<String, ReferenceWorkRecord>> _recordsByProject =
      <String, Map<String, ReferenceWorkRecord>>{};

  @override
  Future<void> appendReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) async {
    _recordsByProject.putIfAbsent(
      project.id,
      () => <String, ReferenceWorkRecord>{},
    )[record.referenceWorkId] = record;
  }

  @override
  Future<List<ReferenceWorkRecord>> listReferenceWorks(
    ProjectDescriptor project, {
    String? relationshipToProject,
  }) async {
    final items =
        _recordsByProject[project.id]?.values.toList(growable: false) ??
        const <ReferenceWorkRecord>[];
    if (relationshipToProject == null || relationshipToProject.trim().isEmpty) {
      return items;
    }
    return items
        .where((entry) => entry.relationshipToProject == relationshipToProject)
        .toList(growable: false);
  }

  @override
  Future<ReferenceWorkRecord?> readReferenceWork(
    ProjectDescriptor project, {
    required String referenceWorkId,
  }) async {
    return _recordsByProject[project.id]?[referenceWorkId];
  }

  @override
  Future<void> updateReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) async {
    _recordsByProject.putIfAbsent(
      project.id,
      () => <String, ReferenceWorkRecord>{},
    )[record.referenceWorkId] = record;
  }
}

class _FakeInformationLinkRepository implements InformationLinkRepository {
  final Map<String, Map<String, InformationLink>> _linksByProject =
      <String, Map<String, InformationLink>>{};

  @override
  Future<void> appendInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  ) async {
    _linksByProject.putIfAbsent(
      project.id,
      () => <String, InformationLink>{},
    )[link.linkId] = link;
  }

  @override
  Future<List<InformationLink>> listInformationLinks(
    ProjectDescriptor project, {
    String? linkType,
    String? sourceRefId,
    String? targetRefId,
  }) async {
    final items =
        _linksByProject[project.id]?.values.toList(growable: false) ??
        const <InformationLink>[];
    return items
        .where((entry) {
          final matchesLinkType =
              linkType == null ||
              linkType.trim().isEmpty ||
              entry.linkType == linkType;
          final matchesSource =
              sourceRefId == null ||
              sourceRefId.trim().isEmpty ||
              entry.sourceRef.refId == sourceRefId;
          final matchesTarget =
              targetRefId == null ||
              targetRefId.trim().isEmpty ||
              entry.targetRef.refId == targetRefId;
          return matchesLinkType && matchesSource && matchesTarget;
        })
        .toList(growable: false);
  }

  @override
  Future<InformationLink?> readInformationLink(
    ProjectDescriptor project, {
    required String linkId,
  }) async {
    return _linksByProject[project.id]?[linkId];
  }

  @override
  Future<void> updateInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  ) async {
    _linksByProject.putIfAbsent(
      project.id,
      () => <String, InformationLink>{},
    )[link.linkId] = link;
  }
}

class _FakeInformationEventRepository implements InformationEventRepository {
  final Map<String, Map<String, InformationEvent>> _eventsByProject =
      <String, Map<String, InformationEvent>>{};

  @override
  Future<void> appendInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  ) async {
    _eventsByProject.putIfAbsent(
      project.id,
      () => <String, InformationEvent>{},
    )[event.eventId] = event;
  }

  @override
  Future<List<InformationEvent>> listInformationEvents(
    ProjectDescriptor project, {
    String? eventType,
    String? lifecycleStatus,
    String? subjectRefId,
  }) async {
    final items =
        _eventsByProject[project.id]?.values.toList(growable: false) ??
        const <InformationEvent>[];
    return items
        .where((entry) {
          final matchesEventType =
              eventType == null ||
              eventType.trim().isEmpty ||
              entry.eventType == eventType;
          final matchesLifecycle =
              lifecycleStatus == null ||
              lifecycleStatus.trim().isEmpty ||
              entry.lifecycleStatus == lifecycleStatus;
          final matchesSubject =
              subjectRefId == null ||
              subjectRefId.trim().isEmpty ||
              entry.subjectRef.refId == subjectRefId;
          return matchesEventType && matchesLifecycle && matchesSubject;
        })
        .toList(growable: false);
  }

  @override
  Future<InformationEvent?> readInformationEvent(
    ProjectDescriptor project, {
    required String eventId,
  }) async {
    return _eventsByProject[project.id]?[eventId];
  }

  @override
  Future<void> updateInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  ) async {
    _eventsByProject.putIfAbsent(
      project.id,
      () => <String, InformationEvent>{},
    )[event.eventId] = event;
  }
}
