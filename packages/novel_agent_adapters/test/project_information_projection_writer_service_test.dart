import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationProjectionWriterService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late LocalKnowledgeCardRepository knowledgeRepository;
    late LocalDesignElementRepository designRepository;
    late LocalResearchNoteRepository researchRepository;
    late LocalReferenceWorkRepository referenceRepository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-information-projection-writer-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      knowledgeRepository = LocalKnowledgeCardRepository(
        workspacePort: workspacePort,
      );
      designRepository = LocalDesignElementRepository(
        workspacePort: workspacePort,
      );
      researchRepository = LocalResearchNoteRepository(
        workspacePort: workspacePort,
      );
      referenceRepository = LocalReferenceWorkRepository(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes visible information projections without mutating hidden fact sources',
      () async {
        await knowledgeRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard.fromJson(<String, Object?>{
            'card_id': 'knowledge-1',
            'card_namespace': 'project.world',
            'card_type': 'world_rule',
            'title': '雾潮夜记忆回声',
            'summary': '雾潮夜会放大失去的记忆。',
            'content_payload': <String, Object?>{'rule': '雾潮夜会放大失去的记忆'},
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
            'design_payload': <String, Object?>{'pattern': '章末潮声回扣章首镜面'},
            'source_refs': <Object?>[_sourceRefJson()],
            'activation_policy': _activationPolicyJson(
              priority: InformationActivationPriorities.pinned,
            ),
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
            'requires_confirmation': true,
            'future_unknown_field': <String, Object?>{'keep': true},
          }),
        );

        final writer = ProjectInformationProjectionWriterService(
          workspacePort: workspacePort,
          knowledgeCardRepository: knowledgeRepository,
          designElementRepository: designRepository,
          researchNoteRepository: researchRepository,
          referenceWorkRepository: referenceRepository,
        );

        final documents = await writer.writeProjection(project);

        expect(documents, hasLength(4));
        final knowledgeFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        );
        final designFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}设计元素摘要.md',
        );
        final researchFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}research${Platform.pathSeparator}资料研究摘要.md',
        );
        final referenceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}references${Platform.pathSeparator}引用作品边界.md',
        );
        expect(await knowledgeFile.exists(), isTrue);
        expect(await designFile.exists(), isTrue);
        expect(await researchFile.exists(), isTrue);
        expect(await referenceFile.exists(), isTrue);
        final knowledgeMarkdown = await knowledgeFile.readAsString();
        expect(knowledgeMarkdown, contains('这份 Markdown 只保留轻摘要与人工补充入口'));
        expect(
          knowledgeMarkdown,
          contains(
            '来源类型：来源-source-1 / `imports/reference/source-1.txt` / kind:`user`',
          ),
        );
        expect(
          knowledgeMarkdown,
          contains('project-information://knowledge_cards'),
        );
        expect(knowledgeMarkdown, isNot(contains('结构化参考快照')));
        expect(
          knowledgeMarkdown,
          isNot(contains(r'D:\reference\source-1.txt')),
        );

        await knowledgeFile.delete();
        await designFile.delete();
        await researchFile.delete();
        await referenceFile.delete();

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
        expect(loadedDesign, isNotNull);
        expect(loadedResearch?.toJson()['unknown_top_level'], 'preserved');
        expect(
          (loadedReference!.toJson()['future_unknown_field']
              as Map<String, Object?>)['keep'],
          isTrue,
        );
      },
    );
  });
}

Map<String, Object?> _sourceRefJson() {
  return <String, Object?>{
    'source_ref': <String, Object?>{
      'source_type': NarrativeSourceTypes.user,
      'source_id': 'source-1',
      'source_asset_id': 'imports/reference/source-1.txt',
      'display_name': '来源-source-1',
      'source_kind': NarrativeSourceTypes.user,
      'resolver_uri': 'project-source://source-1',
      'local_hint_path': r'D:\reference\source-1.txt',
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
