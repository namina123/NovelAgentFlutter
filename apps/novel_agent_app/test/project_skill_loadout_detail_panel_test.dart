import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/contracts/agent_ecosystem_action_handler.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/ecosystem_editor_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/ecosystem_import_command_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/project_skill_loadout_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'keeps only three primary loadout actions and moves history capture into history section',
    (WidgetTester tester) async {
      final handler = _FakeAgentEcosystemActionHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 960,
              child: ProjectSkillLoadoutDetailPanel(
                viewData: const ProjectSkillLoadoutDetailViewData(
                  agentId: 'agent_1',
                  agentName: '审阅智能体',
                  agentDescription: '负责当前项目的结构与表达修订。',
                  sourceLabel: '项目装载',
                  summary: '技能组 1 个，额外技能 1 个，禁用技能 0 个。',
                  expressionConstraintSummary:
                      '去 AI / 真实性 / 叙事边界这类内容不属于技能装载，请从“表达限制”进入项目级约束系统，并可继续按当前智能体定向绑定。',
                  hasPendingChanges: true,
                  skillGroups: <ProjectSkillLoadoutSelectableItemViewData>[
                    ProjectSkillLoadoutSelectableItemViewData(
                      id: 'group_1',
                      title: '审阅组合',
                      subtitle: '技能组',
                      selected: true,
                    ),
                  ],
                  extraSkills: <ProjectSkillLoadoutSelectableItemViewData>[
                    ProjectSkillLoadoutSelectableItemViewData(
                      id: 'skill_1',
                      title: '语气修订',
                      subtitle: '额外技能',
                      selected: true,
                    ),
                  ],
                  resolvedSkills: <ProjectSkillLoadoutResolvedSkillViewData>[
                    ProjectSkillLoadoutResolvedSkillViewData(
                      id: 'skill_1',
                      title: '语气修订',
                      sourceSummary: '额外技能',
                      enabled: true,
                      isUnavailable: false,
                      statusLabel: '已启用',
                    ),
                  ],
                  historyEntries: <ProjectSkillLoadoutHistoryItemViewData>[
                    ProjectSkillLoadoutHistoryItemViewData(
                      id: 'history_1',
                      title: '阶段一装载',
                      subtitle: '2026-05-29T10:00:00Z',
                      summary: '1 组 / 1 额外 / 0 禁用',
                    ),
                  ],
                  issues: <String>[],
                ),
                actionHandler: handler,
                projectAvailable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('应用装载'), findsOneWidget);
      expect(find.text('回到已保存'), findsOneWidget);
      expect(find.text('另存为技能组'), findsOneWidget);
      expect(find.text('表达限制'), findsOneWidget);
      expect(find.text('记为历史快照'), findsNothing);
      expect(find.text('保存当前快照'), findsOneWidget);
      expect(find.text('恢复这次快照'), findsOneWidget);
      expect(find.textContaining('“回到已保存”只回到当前项目已保存装载'), findsOneWidget);

      await tester.tap(find.text('回到已保存'));
      await tester.pumpAndSettle();

      expect(handler.resetRequestedAgentIds, <String>['agent_1']);
      expect(handler.historyCaptureRequestedAgentIds, isEmpty);

      await tester.tap(find.text('表达限制'));
      await tester.pumpAndSettle();
      expect(handler.expressionConstraintsOpened, 1);
    },
  );

  testWidgets(
    'keeps saved reset, history restore and save-as-group semantics clearly separated',
    (WidgetTester tester) async {
      final handler = _FakeAgentEcosystemActionHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 960,
              child: ProjectSkillLoadoutDetailPanel(
                viewData: const ProjectSkillLoadoutDetailViewData(
                  agentId: 'agent_1',
                  agentName: '审阅智能体',
                  agentDescription: '负责当前项目的结构与表达修订。',
                  sourceLabel: '历史恢复',
                  summary: '技能组 1 个，额外技能 0 个，禁用技能 0 个。',
                  expressionConstraintSummary:
                      '去 AI / 真实性 / 叙事边界这类内容不属于技能装载，请从“表达限制”进入项目级约束系统，并可继续按当前智能体定向绑定。',
                  hasPendingChanges: true,
                  skillGroups: <ProjectSkillLoadoutSelectableItemViewData>[],
                  extraSkills: <ProjectSkillLoadoutSelectableItemViewData>[],
                  resolvedSkills: <ProjectSkillLoadoutResolvedSkillViewData>[],
                  historyEntries: <ProjectSkillLoadoutHistoryItemViewData>[
                    ProjectSkillLoadoutHistoryItemViewData(
                      id: 'history_1',
                      title: '阶段一装载',
                      subtitle: '2026-05-29T10:00:00Z',
                      summary: '1 组 / 0 额外 / 0 禁用',
                    ),
                  ],
                  issues: <String>[],
                ),
                actionHandler: handler,
                projectAvailable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('恢复这次快照'));
      await tester.tap(find.text('恢复这次快照'));
      await tester.pumpAndSettle();

      expect(
        handler.historyRestoreRequests,
        <({String agentId, String historyEntryId})>[
          (agentId: 'agent_1', historyEntryId: 'history_1'),
        ],
      );
      expect(handler.resetRequestedAgentIds, isEmpty);
      expect(handler.historyCaptureRequestedAgentIds, isEmpty);
      expect(handler.saveAsGroupRequestedAgentIds, isEmpty);
    },
  );

  testWidgets(
    'removes diagnostics card and keeps unavailable skills inside resolved list',
    (WidgetTester tester) async {
      final handler = _FakeAgentEcosystemActionHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 960,
              child: ProjectSkillLoadoutDetailPanel(
                viewData: const ProjectSkillLoadoutDetailViewData(
                  agentId: 'agent_1',
                  agentName: '审阅智能体',
                  agentDescription: '负责当前项目的结构与表达修订。',
                  sourceLabel: '历史恢复',
                  summary: '技能组 0 个，额外技能 1 个，禁用技能 1 个。',
                  expressionConstraintSummary:
                      '去 AI / 真实性 / 叙事边界这类内容不属于技能装载，请从“表达限制”进入项目级约束系统，并可继续按当前智能体定向绑定。',
                  hasPendingChanges: false,
                  skillGroups: <ProjectSkillLoadoutSelectableItemViewData>[],
                  extraSkills: <ProjectSkillLoadoutSelectableItemViewData>[],
                  resolvedSkills: <ProjectSkillLoadoutResolvedSkillViewData>[
                    ProjectSkillLoadoutResolvedSkillViewData(
                      id: 'available_skill',
                      title: '可用技能',
                      sourceSummary: '默认技能',
                      enabled: true,
                      isUnavailable: false,
                      statusLabel: '已启用',
                    ),
                    ProjectSkillLoadoutResolvedSkillViewData(
                      id: 'disabled_skill',
                      title: '禁用技能',
                      sourceSummary: '默认技能',
                      enabled: false,
                      isUnavailable: false,
                      statusLabel: '已停用',
                    ),
                    ProjectSkillLoadoutResolvedSkillViewData(
                      id: 'missing_skill',
                      title: '缺失技能',
                      sourceSummary: '额外技能',
                      enabled: true,
                      isUnavailable: true,
                      statusLabel: '当前不可用',
                    ),
                  ],
                  historyEntries: <ProjectSkillLoadoutHistoryItemViewData>[],
                  issues: <String>['当前不可用技能：missing_skill'],
                ),
                actionHandler: handler,
                projectAvailable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('诊断'), findsNothing);
      expect(find.text('当前不可用'), findsOneWidget);

      final resolvedSection = find.ancestor(
        of: find.text('最终技能'),
        matching: find.byType(Material),
      );
      final unavailableSkill = find.text('缺失技能');
      expect(
        find.descendant(of: resolvedSection, matching: unavailableSkill),
        findsOneWidget,
      );
    },
  );
}

class _FakeAgentEcosystemActionHandler implements AgentEcosystemActionHandler {
  final List<String> resetRequestedAgentIds = <String>[];
  final List<String> historyCaptureRequestedAgentIds = <String>[];
  final List<({String agentId, String historyEntryId})> historyRestoreRequests =
      <({String agentId, String historyEntryId})>[];
  final List<String> saveAsGroupRequestedAgentIds = <String>[];
  var expressionConstraintsOpened = 0;

  @override
  void onAgentEcosystemBackRequested() {}

  @override
  void onCreateAgentGroupRequested() {}

  @override
  void onCreateAgentRequested() {}

  @override
  void onCreateSkillGroupRequested() {}

  @override
  void onCreateSkillRequested() {}

  @override
  void onEditEcosystemEntryRequested(String entryId) {}

  @override
  void onEcosystemEditorDeleteRequested(
    EcosystemEditorRequestViewData request,
  ) {}

  @override
  void onEcosystemEditorDismissed() {}

  @override
  void onEcosystemEditorSubmitted(EcosystemEditorRequestViewData request) {}

  @override
  void onEcosystemEntrySelected(String entryId) {}

  @override
  void onEcosystemImportDismissed() {}

  @override
  void onEcosystemImportSubmitted(EcosystemImportRequestViewData request) {}

  @override
  void onEcosystemRefreshRequested() {}

  @override
  void onEcosystemTabSelected(String tabId) {}

  @override
  void onGenerateIndexRequested() {}

  @override
  void onImportEcosystemPackageRequested() {}

  @override
  void onOpenEcosystemEntrySourceRequested(String entryId) {}

  @override
  void onProjectExpressionConstraintsRequested() {
    expressionConstraintsOpened += 1;
  }

  @override
  void onProjectSkillLoadoutApplyRequested(String agentId) {}

  @override
  void onProjectSkillLoadoutDisabledSkillToggled(
    String agentId,
    String skillId,
    bool disabled,
  ) {}

  @override
  void onProjectSkillLoadoutExtraSkillToggled(
    String agentId,
    String skillId,
    bool selected,
  ) {}

  @override
  void onProjectSkillLoadoutHistoryCaptureRequested(
    String agentId,
    String title,
  ) {
    historyCaptureRequestedAgentIds.add(agentId);
  }

  @override
  void onProjectSkillLoadoutHistoryRestoreRequested(
    String agentId,
    String historyEntryId,
  ) {
    historyRestoreRequests.add((
      agentId: agentId,
      historyEntryId: historyEntryId,
    ));
  }

  @override
  void onProjectSkillLoadoutResetRequested(String agentId) {
    resetRequestedAgentIds.add(agentId);
  }

  @override
  void onProjectSkillLoadoutSaveAsGroupRequested(
    String agentId,
    String groupId,
    String displayName,
    String description,
  ) {
    saveAsGroupRequestedAgentIds.add(agentId);
  }

  @override
  void onProjectSkillLoadoutSkillGroupToggled(
    String agentId,
    String groupId,
    bool selected,
  ) {}
}
