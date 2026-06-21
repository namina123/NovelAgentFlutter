import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/models/project_skill_loadout_workspace_snapshot.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_continuity_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_followup_group_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_followup_option_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/contracts/book_deconstruction_action_handler.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_plan_group_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_plan_item_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_preview_section_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_step_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/models/book_deconstruction_view_data.dart';
import 'package:novel_agent_app/features/book_deconstruction/presentation/widgets/book_deconstruction_preview_panel.dart';
import 'package:novel_agent_app/features/settings/application/services/theme_settings_view_data_service.dart';
import 'package:novel_agent_app/features/settings/presentation/models/settings_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/theme_settings_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_unsupported_group_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/opening_session_panel.dart';
import 'hfvv_viewmodel_harness_support.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

const List<String> _forbiddenFragments = <String>[
  '开发',
  '兼容桥',
  '宿主',
  'ProjectWorkspacePort',
  'ToolExecutionService',
  'ProjectToolDispatcher',
  '当前版本',
  '允许调用本机程序',
  '后续内置主题',
  '注册表扩展位',
  '用户自定义预留',
  '当前保留为空分组',
  '暂未返回额外适配信息',
  '表达规则：已应用',
  '后续会接独立用例',
  '共享资料桥',
  '后续工程菜单',
  'information GUI',
  '后续派生',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'user-facing projections keep leftover developer terms out of settings, theme and skill surfaces',
    () async {
      // 中文注释: 这里把几个最容易回流到用户面的投影一起扫掉，确保黑名单只约束正式展示层。
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
          resultBuilder:
              ({
                required ProjectDescriptor project,
                required String userPrompt,
                required String modelId,
              }) {
                return DraftGenerationResult(
                  project: project,
                  projectInfo: <String, Object?>{
                    'id': project.id,
                    'title': project.name,
                    'path': project.rootPath,
                    'project_type': project.projectType,
                  },
                  userPrompt: userPrompt,
                  prompt: userPrompt,
                  modelId: modelId,
                  draftMarkdown: 'regression placeholder',
                  contextPack: const <String, Object?>{},
                  selectedPaths: const <String>[],
                  executedTools: const <Object?>[],
                  writtenPaths: const <String>[],
                  changedPaths: const <String>[],
                  transcriptMessages: const <JsonMap>[],
                  waitingForUserChoice: false,
                  reasoningContent: '',
                  stoppedByToolError: false,
                  toolErrorSummary: '',
                );
              },
        ),
      );
      final settings = harness.controller.settingsPageListenable.value;
      _expectNoForbidden(_settingsStrings(settings));
      expect(settings.tabs.map((tab) => tab.id), isNot(contains('dev')));
      expect(settings.activeTabId, 'interfaces');

      final themeViewData = ThemeSettingsViewDataService().build(
        themeSettings: const <String, Object?>{},
      );
      _expectNoForbidden(<String>[
        themeViewData.selectedThemeId,
        themeViewData.currentThemeLabel,
        themeViewData.builtInSectionDescription,
        themeViewData.futureSectionDescription,
        themeViewData.customSectionDescription,
        for (final option in themeViewData.builtInThemes) ...<String>[
          option.id,
          option.label,
          option.description,
          option.badgeLabel,
        ],
      ]);

      final skillViewData = ProjectSkillLoadoutViewDataService().build(
        projectAvailable: true,
        snapshot: ProjectSkillLoadoutWorkspaceSnapshot(
          savedLoadouts: const <AgentSkillLoadout>[],
          draftLoadouts: <String, AgentSkillLoadout>{
            'agent_1': const AgentSkillLoadout(
              agentId: 'agent_1',
              source: AgentSkillLoadoutSource.projectSelection,
            ),
          },
          historyEntries: const <AgentSkillLoadoutHistoryEntry>[],
          isLoading: false,
        ),
        agents: const <JsonMap>[
          <String, Object?>{
            'id': 'agent_1',
            'name': '主智能体',
            'description': '项目主智能体',
            'skills': <String>[],
          },
        ],
        skills: const <JsonMap>[],
        skillGroups: const <JsonMap>[],
        selectedAgentId: 'agent_1',
        statusMessage: 'ok',
      );
      _expectNoForbidden(<String>[
        skillViewData.detail!.expressionConstraintSummary,
        skillViewData.detail!.summary,
        skillViewData.detail!.agentDescription,
        skillViewData.detail!.sourceLabel,
      ]);
    },
  );

  testWidgets(
    'empty opening and book preview surfaces use user-facing fallback copy',
    (WidgetTester tester) async {
      // 中文注释: 空态也要保持人话，不让“未返回额外适配信息”之类的内部态口吻漏出来。
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                OpeningSessionPanel(
                  viewData: const OpeningPanelViewData(
                    title: '开局继续',
                    summary: '这里显示开局协作的简短提示。',
                    currentGroupDisplayName: '',
                    selectionHint: '',
                    supportedGroups: <OpeningAgentGroupOptionViewData>[],
                    unsupportedGroups: <OpeningUnsupportedGroupViewData>[],
                  ),
                  actionHandler: _FakeConversationActionHandler(),
                ),
                Expanded(
                  child: BookDeconstructionPreviewPanel(
                    viewData: const BookDeconstructionViewData(
                      projectTitle: '空分组测试',
                      operationKind: 'preview',
                      importActionLabel: '导入',
                      buildPreviewActionLabel: '生成预览',
                      status: '已生成结构化预览。',
                      isLoading: false,
                      activeStepId: '',
                      steps: const <BookDeconstructionStepViewData>[],
                      sourceAbsolutePath: '',
                      sourceTitle: '',
                      sourceContent: '',
                      operatorNotes: '',
                      styleSummary: '',
                      worldRulesText: '',
                      characterLinesText: '',
                      organizationLinesText: '',
                      previewSections:
                          const <BookDeconstructionPreviewSectionViewData>[],
                      planGroups: <BookDeconstructionPlanGroupViewData>[
                        BookDeconstructionPlanGroupViewData(
                          id: 'plan_group',
                          title: '结构预览',
                          description: '仅用于打开连续预览区。',
                          items: <BookDeconstructionPlanItemViewData>[],
                        ),
                      ],
                      selectedItemCount: 0,
                      totalItemCount: 0,
                      selectedFollowupOptionId: '',
                      confirmedPreviewPath: '',
                      canBuildPreview: false,
                      canConfirmSelection: false,
                      canCreateDerivedProject: false,
                      continuity: BookDeconstructionContinuityViewData(
                        preferredDirectionLabel: '偏向长任务',
                        highlightedBuildTierLabel: '默认高亮',
                        highlightedRouteTitle: '默认路线',
                        selectedRouteOptionId: '',
                        selectedRouteTitle: '默认路线',
                        scopeHintCount: 0,
                        identityMappingCount: 0,
                        mechanicHintCount: 0,
                        summary: '空分组测试',
                        followupGroups: <BookDeconstructionFollowupGroupViewData>[
                          BookDeconstructionFollowupGroupViewData(
                            id: 'empty_group',
                            title: '空分组',
                            description: '无可用路线',
                            options: <BookDeconstructionFollowupOptionViewData>[],
                          ),
                        ],
                      ),
                    ),
                    actionHandler: _FakeBookDeconstructionActionHandler(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('暂无更多说明'), findsOneWidget);
      expect(find.text('当前暂无可用路线。'), findsOneWidget);
      for (final fragment in _forbiddenFragments) {
        expect(find.textContaining(fragment), findsNothing);
      }
    },
  );
}

Iterable<String> _settingsStrings(SettingsViewData viewData) sync* {
  yield viewData.activeTabId;
  for (final tab in viewData.tabs) {
    yield tab.id;
    yield tab.label;
  }
  for (final sections in viewData.tabSections.values) {
    for (final section in sections) {
      yield section.title;
      yield section.description;
      for (final item in section.items) {
        yield item.label;
        yield item.value;
      }
    }
  }
}

void _expectNoForbidden(Iterable<String> texts) {
  for (final text in texts) {
    for (final fragment in _forbiddenFragments) {
      expect(text.contains(fragment), isFalse);
    }
  }
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  @override
  void onAgentGroupSelected(String groupId) {}

  @override
  void onAttachmentRequested() {}

  @override
  void onConversationAgentSelected(String agentId) {}

  @override
  void onConversationSettingsRequested() {}

  @override
  void onDocumentsWorkspaceDismissRequested() {}

  @override
  void onDocumentsWorkspaceRequested() {}

  @override
  void onHistoryRequested() {}

  @override
  void onModelSelected(String modelId) {}

  @override
  void onNewSessionRequested() {}

  @override
  void onOptimizeRequested() {}

  @override
  void onPrimaryActionRequested(String actionId) {}

  @override
  void onQuickThemeRequested() {}

  @override
  void onReasoningToggleChanged(bool enabled) {}

  @override
  void onRetryLastFailedRequested() {}

  @override
  void onScreenModeRequested() {}

  @override
  void onSendRequested(String text) {}

  @override
  void onSessionHistorySelected(String sessionId) {}

  @override
  void onStopRequested() {}

  @override
  void onToolOptionsRequested() {}

  @override
  void onUserOptionSelected(UserOptionViewData option) {}
}

class _FakeBookDeconstructionActionHandler
    implements BookDeconstructionActionHandler {
  @override
  void onBookDeconstructionBackRequested() {}

  @override
  Future<void> onBookDeconstructionBuildPreviewRequested() async {}

  @override
  void onBookDeconstructionCharacterLinesChanged(String value) {}

  @override
  void onBookDeconstructionClearSelectionRequested() {}

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {}

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {}

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {}

  @override
  Future<void> onBookDeconstructionImportFileRequested() async {}

  @override
  void onBookDeconstructionOperatorNotesChanged(String value) {}

  @override
  void onBookDeconstructionOrganizationLinesChanged(String value) {}

  @override
  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  }) {}

  @override
  void onBookDeconstructionRefreshRequested() {}

  @override
  void onBookDeconstructionSelectAllRequested() {}

  @override
  void onBookDeconstructionSourceContentChanged(String value) {}

  @override
  void onBookDeconstructionSourceTitleChanged(String value) {}

  @override
  void onBookDeconstructionStepSelected(String stepId) {}

  @override
  void onBookDeconstructionStyleSummaryChanged(String value) {}

  @override
  void onBookDeconstructionWorldRulesChanged(String value) {}
}
