import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectContextActivationService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late LocalNarrativeProfileRepository profileRepository;
    late LocalNarrativeClaimRepository claimRepository;
    late LocalConstraintBindingRepository bindingRepository;
    late ProjectContextActivationService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-context-activation-',
      );
      workspacePort = LocalProjectWorkspacePort();
      profileRepository = LocalNarrativeProfileRepository(
        workspacePort: workspacePort,
      );
      claimRepository = LocalNarrativeClaimRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = LocalConstraintBindingRepository(
        workspacePort: workspacePort,
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '上下文桥接测试',
        rootPath: tempDirectory.path,
      );
      service = ProjectContextActivationService(
        workspacePort: workspacePort,
        profileRepository: profileRepository,
        claimRepository: claimRepository,
        bindingRepository: bindingRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'buildPlan converts project files and structured sources into activation candidates',
      () async {
        await _writeFile(
          tempDirectory.path,
          'specs/story_rules.md',
          '设定规则：所有角色都必须记住月蚀之夜发生的事。',
        );
        await _writeFile(
          tempDirectory.path,
          'outlines/story/main_outline.md',
          '第一卷大纲：主角在遗迹中发现自我循环的证据。',
        );
        await profileRepository.appendProfile(
          project,
          NarrativeProfile(
            profileId: 'hero',
            profileNamespace: 'character',
            profileLabel: '主角',
            lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
            profilePayload: const <String, Object?>{
              'goal': '打破循环',
              'fear': '再次失去同伴',
            },
            profileExtensions: const <String, Object?>{'pinned': true},
            source: _source(),
            confidence: 0.97,
          ),
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-eclipse',
            claimNamespace: 'continuity',
            claimLabel: '月蚀记忆一致',
            claimPayload: const <String, Object?>{'fact': '所有核心角色保留上一轮记忆'},
            contextRefs: const <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.chapter,
                refId: 'chapter-12',
                relativePath: 'chapters/chapter_12.md',
                displayName: '第12章',
              ),
            ],
            source: _source(),
            confidence: 0.91,
          ),
        );
        await bindingRepository.appendBinding(
          project,
          NarrativeConstraintBindingProposal(
            bindingId: 'constraint-style',
            constraintType: 'style_rule',
            constraintLabel: '禁止全知旁白',
            constraintPayload: const <String, Object?>{
              'forbidden_patterns': <Object?>['作者解释', '全知上帝视角'],
            },
            scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
            policy: const ConstraintBindingPolicy(
              requiresUserConfirmation: true,
            ),
            source: _source(),
            reason: '保持沉浸感',
          ),
        );

        final plan = await service.buildPlan(
          project: project,
          taskType: 'chapter_draft',
          maxFiles: 4,
          pinnedRelativePaths: const <String>['specs/story_rules.md'],
        );

        expect(plan.items, isNotEmpty);
        expect(
          plan.items.map((item) => item.source),
          containsAll(<String>[
            'project_file',
            'narrative_profile',
            'narrative_claim',
            'narrative_constraint',
          ]),
        );
        final fileItem = plan.items.singleWhere(
          (item) => item.itemId == 'file:specs/story_rules.md',
        );
        final profileItem = plan.items.singleWhere(
          (item) => item.itemId == 'profile:hero',
        );
        final claimItem = plan.items.singleWhere(
          (item) => item.itemId == 'claim:claim-eclipse',
        );
        final constraintItem = plan.items.singleWhere(
          (item) => item.itemId == 'constraint:constraint-style',
        );

        expect(
          fileItem.activationReasons,
          contains(ContextActivationReasonCodes.manualPin),
        );
        expect(
          ValueReaders.stringValue(fileItem.metadata['relative_path']),
          'specs/story_rules.md',
        );
        expect(
          profileItem.activationReasons,
          contains(ContextActivationReasonCodes.profilePolicy),
        );
        expect(
          ValueReaders.stringValue(profileItem.metadata['profile_namespace']),
          'character',
        );
        expect(claimItem.refs.single.relativePath, 'chapters/chapter_12.md');
        expect(constraintItem.reasonDetails['required'], isTrue);
        expect(
          ValueReaders.mapValue(plan.metadata['candidate_source_counts']),
          <String, Object?>{
            'project_file': 2,
            'narrative_profile': 1,
            'narrative_claim': 1,
            'narrative_constraint': 1,
          },
        );
      },
    );

    test(
      'buildReport exposes selected omitted and truncated sections with visible budget trimming',
      () async {
        await _writeFile(
          tempDirectory.path,
          'specs/core_rules.md',
          '核心规则：每次轮回结束后，主角会回到钟楼苏醒。'
              '这个设定不可被遗忘，也不可由旁白直接解释。',
        );
        await profileRepository.appendProfile(
          project,
          NarrativeProfile(
            profileId: 'hero',
            profileNamespace: 'character',
            profileLabel: '主角',
            lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
            profilePayload: const <String, Object?>{
              'mission': '守住钟楼',
              'secret': '知道终局真相',
            },
            profileExtensions: const <String, Object?>{'pinned': true},
            source: _source(),
            confidence: 0.98,
          ),
        );
        await claimRepository.appendClaim(
          project,
          NarrativeStateClaim(
            claimId: 'claim-heavy',
            claimNamespace: 'continuity',
            claimLabel: '轮回规则补充',
            claimPayload: const <String, Object?>{
              'details':
                  '这是一个很长的说明，用来制造预算裁剪效果。'
                  '主角必须记住三次失败、两次背叛和一次失控。'
                  '每次轮回都会在钟声响起前十五分钟重置。'
                  '任何旁人都不知道重置已经发生。',
            },
            source: _source(),
            confidence: 0.88,
          ),
        );
        await bindingRepository.appendBinding(
          project,
          NarrativeConstraintBindingProposal(
            bindingId: 'constraint-required',
            constraintType: 'style_rule',
            constraintLabel: '不允许全知解释',
            constraintPayload: const <String, Object?>{
              'rule': '叙述只能停留在角色感知范围内',
            },
            scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
            policy: const ConstraintBindingPolicy(
              requiresUserConfirmation: true,
            ),
            source: _source(),
          ),
        );

        final report = await service.buildReport(
          project: project,
          taskType: 'chapter_draft',
          budgetChars: 420,
          reservedOutputChars: 120,
          maxFiles: 3,
          pinnedRelativePaths: const <String>['specs/core_rules.md'],
        );

        expect(report.budgetChars, 300);
        expect(report.selectedItemIds, isNotEmpty);
        expect(report.truncatedItemIds, isNotEmpty);
        expect(report.omittedItemIds, isNotEmpty);

        final truncatedItems = report.items
            .where((item) => item.truncated)
            .toList(growable: false);
        final omittedItems = report.items
            .where((item) => item.omitted)
            .toList(growable: false);
        final truncatedItem = truncatedItems.first;
        final omittedItem = omittedItems.first;
        final selectedSections = ValueReaders.mapList(
          report.metadata['selected_context_sections'],
        );
        final omittedSections = ValueReaders.mapList(
          report.metadata['omitted_context_sections'],
        );
        final truncatedSections = ValueReaders.mapList(
          report.metadata['truncated_context_sections'],
        );

        expect(
          ValueReaders.stringValue(
            truncatedItem.metadata['selected_text'],
          ).length,
          truncatedItem.includedChars,
        );
        expect(
          ValueReaders.intValue(truncatedItem.metadata['trimmed_chars']) > 0,
          isTrue,
        );
        expect(
          ValueReaders.stringValue(truncatedItem.metadata['explanation']),
          contains('Selected with'),
        );
        expect(
          ValueReaders.stringValue(omittedItem.metadata['explanation']),
          contains('Omitted because'),
        );
        expect(
          truncatedItems.every(
            (item) => ValueReaders.stringValue(
              item.metadata['explanation'],
            ).contains('Selected with'),
          ),
          isTrue,
        );
        expect(
          omittedItems.every(
            (item) => ValueReaders.stringValue(
              item.metadata['explanation'],
            ).contains('Omitted because'),
          ),
          isTrue,
        );
        expect(
          selectedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.selectedItemIds),
        );
        expect(
          omittedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.omittedItemIds),
        );
        expect(
          truncatedSections.map(
            (entry) => ValueReaders.stringValue(entry['item_id']),
          ),
          containsAll(report.truncatedItemIds),
        );
        expect(report.summary, contains('selected profiles'));
      },
    );
  });
}

Future<void> _writeFile(
  String rootPath,
  String relativePath,
  String content,
) async {
  final normalizedPath = relativePath.replaceAll('/', Platform.pathSeparator);
  final file = File('$rootPath${Platform.pathSeparator}$normalizedPath');
  await file.parent.create(recursive: true);
  await file.writeAsString(content, flush: true);
}

NarrativeSourceRef _source() {
  return const NarrativeSourceRef(
    sourceType: 'tool_call',
    sourceId: 'source-1',
    label: 'tool',
  );
}
