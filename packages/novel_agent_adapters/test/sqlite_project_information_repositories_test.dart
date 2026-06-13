import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('sqlite project information repositories', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late SqliteKnowledgeCardRepository knowledgeRepository;
    late SqliteDesignElementRepository designRepository;
    late SqliteResearchNoteRepository researchRepository;
    late SqliteReferenceWorkRepository referenceRepository;
    late ProjectSqlitePathService sqlitePathService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-sqlite-project-information-repositories-',
      );
      project = ProjectDescriptor(
        id: 'project_sqlite_1',
        name: 'SQLite 信息项目',
        rootPath: tempDirectory.path,
      );
      knowledgeRepository = SqliteKnowledgeCardRepository();
      designRepository = SqliteDesignElementRepository();
      researchRepository = SqliteResearchNoteRepository();
      referenceRepository = SqliteReferenceWorkRepository();
      sqlitePathService = ProjectSqlitePathService();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'persist structured project information into sqlite-first store without default json mirrors',
      () async {
        await knowledgeRepository.appendKnowledgeCard(
          project,
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
            'lifecycle_status': InformationLifecycleStatuses.accepted,
          }),
        );
        await designRepository.appendDesignElement(
          project,
          DesignElementCard.fromJson(<String, Object?>{
            'design_id': 'design-1',
            'design_namespace': 'project.structure',
            'design_label': '潮声回扣',
            'design_payload': <String, Object?>{
              'pattern': '章末潮声回扣章首镜面',
              'unknown_payload': <String, Object?>{'phase': 'vol1'},
            },
            'source_refs': <Object?>[_sourceRefJson()],
            'activation_policy': _activationPolicyJson(),
            'usage_policy': _usagePolicyJson(),
            'lifecycle_status': InformationLifecycleStatuses.proposed,
          }),
        );
        await researchRepository.appendResearchNote(
          project,
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
            'unknown_top_level': 'preserved',
          }),
        );
        await referenceRepository.appendReferenceWork(
          project,
          ReferenceWorkRecord.fromJson(<String, Object?>{
            'reference_work_id': 'reference-1',
            'title': '雾海镜宫',
            'source_refs': <Object?>[_sourceRefJson()],
            'relationship_to_project': 'fanfic_reference',
            'declared_usage_intent': '同人练习',
            'risk_notes': <Object?>[
              <String, Object?>{'level': 'high', 'reason': '外部作品边界'},
            ],
            'future_unknown_field': <String, Object?>{'keep': true},
          }),
        );

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
        final filteredResearch = await researchRepository.listResearchNotes(
          project,
          sourceKind: 'web_article',
        );
        final filteredReference = await referenceRepository.listReferenceWorks(
          project,
          relationshipToProject: 'fanfic_reference',
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
        expect(filteredResearch, hasLength(1));
        expect(filteredReference, hasLength(1));
        expect(
          File(sqlitePathService.databasePath(project.rootPath)).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${project.rootPath}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}knowledge_cards${Platform.pathSeparator}knowledge-1.json',
          ).existsSync(),
          isFalse,
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
