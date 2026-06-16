import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/models/project_skill_loadout_workspace_snapshot.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectSkillLoadoutViewDataService', () {
    test(
      'build projects draft, resolved skills and history into UI view data',
      () {
        final service = ProjectSkillLoadoutViewDataService();
        final snapshot = ProjectSkillLoadoutWorkspaceSnapshot(
          savedLoadouts: const <AgentSkillLoadout>[],
          draftLoadouts: <String, AgentSkillLoadout>{
            'agent_1': const AgentSkillLoadout(
              agentId: 'agent_1',
              source: AgentSkillLoadoutSource.projectSelection,
              skillGroupIds: <String>['combo'],
              extraSkillIds: <String>['extra_skill'],
              disabledSkillIds: <String>['base_skill'],
            ),
          },
          historyEntries: const <AgentSkillLoadoutHistoryEntry>[
            AgentSkillLoadoutHistoryEntry(
              id: 'history_1',
              agentId: 'agent_1',
              title: '历史装载',
              createdAt: '2026-05-27T00:00:00.000Z',
              loadout: AgentSkillLoadout(
                agentId: 'agent_1',
                source: AgentSkillLoadoutSource.historyRestore,
                skillGroupIds: <String>['combo'],
              ),
            ),
          ],
          isLoading: false,
        );

        final viewData = service.build(
          projectAvailable: true,
          snapshot: snapshot,
          agents: const <JsonMap>[
            <String, Object?>{
              'id': 'agent_1',
              'name': '主智能体',
              'description': '项目主智能体',
              'skills': <String>['base_skill'],
            },
          ],
          skills: const <JsonMap>[
            <String, Object?>{
              'id': 'base_skill',
              'name': '基础技能',
              'description': '默认技能',
            },
            <String, Object?>{
              'id': 'group_skill',
              'name': '组合技能',
              'description': '来自技能组',
            },
            <String, Object?>{
              'id': 'extra_skill',
              'name': '附加技能',
              'description': '临时追加',
            },
          ],
          skillGroups: const <JsonMap>[
            <String, Object?>{
              'id': 'combo',
              'name': '组合装载',
              'description': '技能组合',
              'skills': <String>['group_skill'],
            },
          ],
          selectedAgentId: 'agent_1',
          statusMessage: 'ok',
        );

        expect(viewData.browserItems, hasLength(1));
        expect(viewData.browserItems.single.badge, '项目装载');
        expect(
          viewData.browserItems.single.description,
          contains('1 组 / 1 额外 / 1 禁用'),
        );

        final detail = viewData.detail;
        expect(detail, isNotNull);
        expect(detail!.agentName, '主智能体');
        expect(
          detail.expressionConstraintSummary,
          contains('表达限制由项目级约束系统统一管理'),
        );
        expect(detail.hasPendingChanges, isTrue);
        expect(detail.skillGroups.single.selected, isTrue);
        expect(
          detail.extraSkills
              .singleWhere((item) => item.id == 'extra_skill')
              .selected,
          isTrue,
        );
        expect(detail.historyEntries.single.title, '历史装载');
        expect(detail.issues, isEmpty);
        expect(detail.permissionBoundarySummary, contains('当前装载没有额外权限需求'));

        final disabledBaseSkill = detail.resolvedSkills.singleWhere(
          (item) => item.id == 'base_skill',
        );
        expect(disabledBaseSkill.enabled, isFalse);
        expect(disabledBaseSkill.isUnavailable, isFalse);
        expect(disabledBaseSkill.statusLabel, '已停用');
        expect(disabledBaseSkill.sourceSummary, contains('默认技能'));

        final groupedSkill = detail.resolvedSkills.singleWhere(
          (item) => item.id == 'group_skill',
        );
        expect(groupedSkill.statusLabel, '已启用');
        expect(groupedSkill.sourceSummary, contains('项目组:组合装载'));
      },
    );

    test(
      'build moves unavailable skills to the end of resolved list while keeping them visible',
      () {
        final service = ProjectSkillLoadoutViewDataService();
        final snapshot = ProjectSkillLoadoutWorkspaceSnapshot(
          savedLoadouts: const <AgentSkillLoadout>[],
          draftLoadouts: <String, AgentSkillLoadout>{
            'agent_1': const AgentSkillLoadout(
              agentId: 'agent_1',
              source: AgentSkillLoadoutSource.projectSelection,
              extraSkillIds: <String>['missing_skill'],
              disabledSkillIds: <String>['base_skill'],
            ),
          },
          historyEntries: const <AgentSkillLoadoutHistoryEntry>[],
          isLoading: false,
        );

        final viewData = service.build(
          projectAvailable: true,
          snapshot: snapshot,
          agents: const <JsonMap>[
            <String, Object?>{
              'id': 'agent_1',
              'name': '主智能体',
              'description': '项目主智能体',
              'skills': <String>['base_skill', 'missing_skill'],
            },
          ],
          skills: const <JsonMap>[
            <String, Object?>{
              'id': 'base_skill',
              'name': '基础技能',
              'description': '默认技能',
            },
          ],
          skillGroups: const <JsonMap>[],
          selectedAgentId: 'agent_1',
          statusMessage: 'ok',
        );

        final detail = viewData.detail!;
        expect(detail.issues, contains('当前不可用技能：missing_skill'));
        expect(
          detail.resolvedSkills.map((item) => item.id).toList(growable: false),
          <String>['base_skill', 'missing_skill'],
        );

        final unavailableSkill = detail.resolvedSkills.last;
        expect(unavailableSkill.isUnavailable, isTrue);
        expect(unavailableSkill.statusLabel, '当前不可用');
      },
    );

    test('prefers display_name alias for skills and groups when available', () {
      final service = ProjectSkillLoadoutViewDataService();
      final viewData = service.build(
        projectAvailable: true,
        snapshot: ProjectSkillLoadoutWorkspaceSnapshot.initial(),
        agents: const <JsonMap>[
          <String, Object?>{
            'id': 'default_generalist',
            'display_name': '综合创作智能体',
            'description': '项目主智能体',
            'skills': <String>['artifact_routing'],
          },
        ],
        skills: const <JsonMap>[
          <String, Object?>{
            'id': 'artifact_routing',
            'display_name': '资料流转',
            'description': '默认技能',
          },
        ],
        skillGroups: const <JsonMap>[
          <String, Object?>{
            'id': 'project_io',
            'display_name': '项目资料与归档方法',
            'description': '技能组合',
            'skills': <String>['artifact_routing'],
          },
        ],
        selectedAgentId: 'default_generalist',
        statusMessage: 'ok',
      );

      expect(viewData.browserItems.single.title, '综合创作智能体');
      expect(viewData.detail!.extraSkills.single.title, '资料流转');
      expect(viewData.detail!.skillGroups.single.title, '项目资料与归档方法');
    });

    test(
      'build projects capability mismatch issues and permission boundary summary',
      () {
        final service = ProjectSkillLoadoutViewDataService();
        final viewData = service.build(
          projectAvailable: true,
          snapshot: ProjectSkillLoadoutWorkspaceSnapshot.initial(),
          agents: const <JsonMap>[
            <String, Object?>{
              'id': 'reviewer',
              'name': '审稿智能体',
              'description': '负责审稿',
              'skills': <String>['external_research_strict'],
            },
          ],
          skills: const <JsonMap>[
            <String, Object?>{
              'id': 'external_research_strict',
              'name': '严格外部检索',
              'source': 'builtin',
              'required_capabilities': <String>['network_access'],
              'safe_without_tools': false,
            },
          ],
          skillGroups: const <JsonMap>[],
          selectedAgentId: 'reviewer',
          statusMessage: 'ok',
        );

        final detail = viewData.detail!;
        expect(detail.issues.single, contains('需要联网权限'));
        expect(detail.issues.single, contains('已阻止装载'));
        expect(detail.permissionBoundarySummary, contains('必需能力：联网权限'));
      },
    );
  });
}
