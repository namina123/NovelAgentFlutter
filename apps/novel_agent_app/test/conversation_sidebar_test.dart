import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_context_compaction_segment_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_context_projection_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/conversation_section_id.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/conversation_section_layout.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/conversation_section_slot.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/section_placement.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_opening_state_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_unsupported_group_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/tool_preview_mode.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_composer_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_composer_dock_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_agent_header_strip.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_model_strip.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_pending_input_preview_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_panel_header.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_send_config_bar.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_sidebar.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/primary_action_list.dart';
import 'package:novel_agent_app/shared/widgets/panel_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'conversation sidebar renders grouped header status and composer',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            groupSelector: const ConversationGroupSelectorViewData(
              currentGroupLabel: '默认组',
              groupOptions: [],
              primaryAgentLabel: '创作助手',
              primaryAgentDescription: '',
              canSwitchGroup: false,
            ),
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '审阅智能体',
              currentAgentId: 'reviewer',
              currentAgentDescription: '负责当前会话的审阅与修订建议',
              agentOptions: <SelectorOptionViewData>[
                SelectorOptionViewData(
                  id: 'reviewer',
                  label: '审阅智能体',
                  note: '负责当前会话的审阅与修订建议',
                ),
              ],
              canSwitchAgent: false,
            ),
            contextSummary: '已载入角色、世界观与章节约束',
            toolCoreStatus: '正在整理上下文与工具可见性',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ConversationPanelHeader), findsOneWidget);
      expect(find.byType(ConversationAgentHeaderStrip), findsOneWidget);
      expect(find.byType(ConversationComposerPanel), findsOneWidget);
      expect(find.byType(ConversationComposerDockPanel), findsOneWidget);
      expect(find.byType(ConversationModelStrip), findsOneWidget);
      expect(find.byType(ConversationSendConfigBar), findsOneWidget);
      expect(find.text('审阅智能体'), findsOneWidget);
      expect(find.text('主智能体'), findsNothing);
      expect(find.text('默认组'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('conversation_header_agent_selector'),
        ),
        findsOneWidget,
      );
      expect(find.text('当前协作智能体'), findsNothing);
      expect(find.textContaining('上下文 '), findsNothing);
      expect(find.textContaining('工具 '), findsNothing);
    },
  );

  testWidgets(
    'conversation sidebar removes system-like menu entries from empty state',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(viewData: WorkbenchViewData.initial()),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('快速主题'), findsNothing);
      expect(find.byTooltip('屏幕模式'), findsNothing);
      expect(find.text('工作台设置'), findsNothing);
      expect(find.text('刷新项目'), findsNothing);
      expect(find.text('继续生成'), findsNothing);
    },
  );

  testWidgets(
    'conversation sidebar keeps only real composer actions while generating',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(isGenerating: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('优化'), findsNothing);
      expect(find.text('工具'), findsNothing);
      expect(find.text('附件'), findsNothing);
      expect(find.text('停止'), findsNothing);
      expect(find.text('生成中'), findsOneWidget);
    },
  );

  testWidgets('conversation sidebar tool detail follows saved preview mode', (
    tester,
  ) async {
    _setLargeTestViewport(tester);
    await tester.pumpWidget(
      _buildSidebarHost(
        viewData: WorkbenchViewData.initial().copyWith(
          conversationEntries: const [
            ConversationEntryViewData(
              id: 'tool_1',
              kind: ConversationEntryKind.tool,
              title: '读取文件',
              body: 'chapters/001.md',
              detailTitle: '工具调用',
              detailSummary: '读取了一次文件内容',
              detailBody: '这里是工具调用的详细内容。',
            ),
          ],
          toolPreviewMode: ToolPreviewMode.compact,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('这里是工具调用的详细内容。'), findsNothing);

    await tester.pumpWidget(
      _buildSidebarHost(
        viewData: WorkbenchViewData.initial().copyWith(
          conversationEntries: const [
            ConversationEntryViewData(
              id: 'tool_1',
              kind: ConversationEntryKind.tool,
              title: '读取文件',
              body: 'chapters/001.md',
              detailTitle: '工具调用',
              detailSummary: '读取了一次文件内容',
              detailBody: '这里是工具调用的详细内容。',
            ),
          ],
          toolPreviewMode: ToolPreviewMode.detail,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工具调用 · 读取了一次文件内容'), findsOneWidget);
    await tester.tap(find.text('工具调用 · 读取了一次文件内容'));
    await tester.pumpAndSettle();
    expect(find.text('这里是工具调用的详细内容。'), findsOneWidget);
  });

  testWidgets('conversation sidebar opens sub-agent detail without composer', (
    tester,
  ) async {
    _setLargeTestViewport(tester);
    await tester.pumpWidget(
      _buildSidebarHost(
        viewData: WorkbenchViewData.initial().copyWith(
          subAgentRuns: const [
            SubAgentRunViewData(
              id: 'sub_1',
              agentName: '资料考据员',
              task: '补完第二章的时代背景与贸易细节',
              status: '完成',
              summary: '已返回可直接合并的设定建议。',
              content: '这里是详细结果。',
              reasoning: '先校验世界观，再补齐贸易逻辑。',
              toolCount: 2,
              events: ['接收主智能体任务。', '完成资料整理并返回。'],
              expertOpinion: '建议把贸易摩擦提前到场景开头。',
              evidenceItems: ['第二段才出现关键贸易背景。'],
              adoptionSummary: '主链可以先复核这条建议，再决定是否吸收。',
              diagnosticItems: ['run_id: sub_1', 'agent_id: evidence_reader'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('资料考据员'), findsOneWidget);
    expect(find.byType(ConversationComposerDockPanel), findsOneWidget);

    await tester.tap(find.text('资料考据员').first);
    await tester.pumpAndSettle();

    expect(find.text('委派任务'), findsOneWidget);
    expect(find.text('专家意见'), findsOneWidget);
    expect(find.text('证据'), findsOneWidget);
    expect(find.text('采纳情况'), findsOneWidget);
    expect(find.text('run_id: sub_1'), findsNothing);
    expect(find.byType(ConversationComposerDockPanel), findsNothing);

    await tester.tap(find.text('运行诊断'));
    await tester.pumpAndSettle();

    expect(find.text('run_id: sub_1'), findsOneWidget);
    expect(find.text('agent_id: evidence_reader'), findsOneWidget);

    await tester.tap(find.byTooltip('返回主会话'));
    await tester.pumpAndSettle();

    expect(find.byType(ConversationComposerDockPanel), findsOneWidget);
  });

  testWidgets(
    'sub-agent fullscreen registers then clears the system back handler',
    (tester) async {
      _setLargeTestViewport(tester);
      final handler = _RecordingConversationActionHandler();
      await tester.pumpWidget(
        _buildSidebarHost(
          actionHandler: handler,
          viewData: WorkbenchViewData.initial().copyWith(
            subAgentRuns: const [
              SubAgentRunViewData(
                id: 'sub_1',
                agentName: '资料考据员',
                task: '补完第二章的时代背景与贸易细节',
                status: '完成',
                summary: '已返回可直接合并的设定建议。',
                content: '这里是详细结果。',
                reasoning: '先校验世界观，再补齐贸易逻辑。',
                toolCount: 2,
                events: ['接收主智能体任务。', '完成资料整理并返回。'],
                expertOpinion: '建议把贸易摩擦提前到场景开头。',
                evidenceItems: ['第二段才出现关键贸易背景。'],
                adoptionSummary: '主链可以先复核这条建议，再决定是否吸收。',
                diagnosticItems: ['run_id: sub_1', 'agent_id: evidence_reader'],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 中文注释: 未打开全屏时不应接管系统返回键。
      expect(handler.lastForegroundBackHandler, isNull);

      await tester.tap(find.text('资料考据员').first);
      await tester.pumpAndSettle();

      // 打开子智能体全屏后应注册返回键接管（Android 返回键会先关闭全屏而非退出应用）。
      expect(find.byTooltip('返回主会话'), findsOneWidget);
      expect(handler.lastForegroundBackHandler, isNotNull);

      // 模拟系统返回键调用注册的回调——应关闭全屏并取消接管。
      handler.lastForegroundBackHandler!();
      await tester.pumpAndSettle();

      expect(find.byTooltip('返回主会话'), findsNothing);
      expect(handler.lastForegroundBackHandler, isNull);
    },
  );

  testWidgets(
    'conversation sidebar keeps model strip above text field and send action below it',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            conversationEntries: const [],
            pendingOptions: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldTop = tester.getTopLeft(find.byType(TextField));
      final configBarTop = tester.getTopLeft(
        find.byType(ConversationSendConfigBar),
      );
      final sendButtonTop = tester.getTopLeft(find.text('发送'));

      expect(configBarTop.dy, lessThan(textFieldTop.dy));
      expect(textFieldTop.dy, lessThan(sendButtonTop.dy));
      expect(find.text('主智能体'), findsNothing);
    },
  );

  testWidgets(
    'conversation sidebar exposes reasoning toggle and keeps attachment hidden',
    (tester) async {
      _setLargeTestViewport(tester);
      final handler = _RecordingConversationActionHandler();
      await tester.pumpWidget(
        _buildSidebarHost(
          actionHandler: handler,
          viewData: WorkbenchViewData.initial().copyWith(
            projectPath: 'D:/projects/novel',
            groupSelector: const ConversationGroupSelectorViewData(
              currentGroupLabel: '长篇总控组',
              groupOptions: [],
              primaryAgentLabel: '综合创作智能体',
              primaryAgentDescription: '负责统筹当前长篇协作。',
              canSwitchGroup: false,
            ),
            inputCapabilityContext: const ConversationInputCapabilityContext(
              hasActiveProject: true,
              isGenerating: false,
              hostSupportsAttachmentPicking: true,
              modelSupportsReasoning: true,
              modelReasoningCanToggle: true,
              modelSupportsFileAttachments: false,
              modelSupportsImageAttachments: false,
              modelSupportsAttachmentUrlsOnly: false,
              modelSupportsMultiAttachments: false,
              collaborationSupportsReasoning: true,
              collaborationSupportsAttachments: false,
              collaborationSupportsToolOptions: false,
              reasoningEnabled: true,
              productExposesReasoningToggle: true,
              productExposesAttachmentEntry: false,
              productExposesStopAction: false,
              productExposesToolOptionsAction: false,
              productExposesOptimizeAction: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('深度思考'), findsOneWidget);
      expect(find.text('附件'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(ConversationReasoningToggleChip), findsOneWidget);

      await tester.tap(
        find.byKey(ConversationReasoningToggleChip.containerKey),
      );
      await tester.pumpAndSettle();

      expect(handler.lastReasoningEnabled, isFalse);
    },
  );

  testWidgets(
    'conversation sidebar header routes conversation agent selection separately from project group',
    (tester) async {
      _setLargeTestViewport(tester);
      final handler = _RecordingConversationActionHandler();
      await tester.pumpWidget(
        _buildSidebarHost(
          actionHandler: handler,
          viewData: WorkbenchViewData.initial().copyWith(
            groupSelector: const ConversationGroupSelectorViewData(
              currentGroupLabel: '长篇总控组',
              groupOptions: <SelectorOptionViewData>[
                SelectorOptionViewData(id: 'starter_long_task', label: '长篇总控组'),
              ],
              primaryAgentLabel: '综合创作智能体',
              primaryAgentDescription: '负责统筹当前长篇协作。',
              canSwitchGroup: true,
            ),
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '综合创作智能体',
              currentAgentId: 'writer',
              currentAgentDescription: '负责当前会话的正文推进',
              agentOptions: <SelectorOptionViewData>[
                SelectorOptionViewData(id: 'writer', label: '综合创作智能体'),
                SelectorOptionViewData(id: 'reviewer', label: '审阅智能体'),
              ],
              canSwitchAgent: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('conversation_header_agent_selector'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('conversation_header_agent_selector'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('审阅智能体').last);
      await tester.pumpAndSettle();

      expect(handler.selectedConversationAgentId, 'reviewer');
      expect(handler.selectedGroupId, isEmpty);
    },
  );

  testWidgets(
    'conversation sidebar shows pending input preview while generating',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            isGenerating: true,
            conversationEntries: const [
              ConversationEntryViewData(
                id: 'assistant_streaming',
                kind: ConversationEntryKind.assistant,
                title: '综合创作智能体',
                body: '正在生成中',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ConversationPendingInputPreviewPanel), findsNothing);

      await tester.enterText(find.byType(TextField), '等这轮结束后，补一个更冷的收束句。');
      await tester.pump();

      expect(find.byType(ConversationPendingInputPreviewPanel), findsOneWidget);
      expect(find.text('待发送输入'), findsOneWidget);
    },
  );

  testWidgets(
    'conversation sidebar removes opening supplement from the main pane',
    (tester) async {
      _setLargeTestViewport(tester);
      final handler = _RecordingConversationActionHandler();
      await tester.pumpWidget(
        _buildSidebarHost(
          actionHandler: handler,
          viewData: WorkbenchViewData.initial().copyWith(
            workflowTitle: '长任务开局',
            workflowDescription: '继续确认本项目开局配置。',
            openingPanel: const OpeningPanelViewData(
              title: '项目智能体组',
              summary: '当前默认组：长篇总控组。当前仍需补充长任务开局信息。',
              currentGroupDisplayName: '长篇总控组',
              selectionHint: '默认只显示当前项目可直接使用的智能体组。',
              supportedGroups: [
                OpeningAgentGroupOptionViewData(
                  groupId: 'starter_long_task',
                  displayName: '长篇总控组',
                  description: '负责长篇开局与节奏收束。',
                  isCurrent: true,
                  isDegraded: false,
                  isStarterGroup: true,
                ),
                OpeningAgentGroupOptionViewData(
                  groupId: 'seed_long_task',
                  displayName: '灵感托管组',
                  description: '更强调 seed 驱动与边写边收束。',
                  isCurrent: false,
                  isDegraded: false,
                  isStarterGroup: false,
                ),
              ],
              unsupportedGroups: [
                OpeningUnsupportedGroupViewData(
                  groupId: 'deconstruction',
                  displayName: '拆书组',
                  description: '只适用于拆书项目。',
                  reasonSummary: '项目类型与该智能体组的适用范围不匹配。',
                  reasonDetails: ['项目类型与该智能体组的适用范围不匹配。'],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('项目智能体组'), findsNothing);
      expect(find.text('适配状态'), findsNothing);
      expect(find.text('项目级智能体组配置与适配详情请到项目面板查看。'), findsNothing);
      expect(find.text('当前项目有 2 个可用智能体组，另有 1 个需到项目层查看原因'), findsNothing);
      expect(find.text('查看不可用项与原因'), findsNothing);
      expect(find.text('拆书组'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('opening_group_seed_long_task')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('opening_unsupported_groups')),
        findsNothing,
      );
      expect(handler.selectedGroupId, isEmpty);
    },
  );

  testWidgets(
    'conversation sidebar keeps conversation agent independent after removing opening supplement',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            agentSelector: const ConversationAgentSelectorViewData(
              currentAgentLabel: '审阅智能体',
              currentAgentId: 'reviewer',
              currentAgentDescription: '负责当前会话的审阅与修订建议',
              agentOptions: <SelectorOptionViewData>[
                SelectorOptionViewData(id: 'reviewer', label: '审阅智能体'),
              ],
              canSwitchAgent: false,
            ),
            openingPanel: const OpeningPanelViewData(
              title: '项目智能体组',
              summary: '当前默认组：长篇总控组。当前项目协作基线已就绪。',
              currentGroupDisplayName: '长篇总控组',
              selectionHint: '默认只显示当前项目可直接使用的智能体组。',
              supportedGroups: [
                OpeningAgentGroupOptionViewData(
                  groupId: 'starter_long_task',
                  displayName: '长篇总控组',
                  description: '负责长篇开局与节奏收束。',
                  isCurrent: true,
                  isDegraded: false,
                  isStarterGroup: true,
                ),
              ],
              unsupportedGroups: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前协作智能体'), findsNothing);
      expect(find.text('审阅智能体'), findsOneWidget);
      expect(find.text('项目智能体组'), findsNothing);
      expect(find.textContaining('当前默认组：长篇总控组。'), findsNothing);
      expect(find.text('项目级智能体组配置与适配详情请到项目面板查看。'), findsNothing);
    },
  );

  testWidgets(
    'conversation sidebar shows only opening-state next action in empty state',
    (tester) async {
      _setLargeTestViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            projectPath: 'D:/projects/novel',
            projectName: '测试项目',
            workflowTitle: '协作开局',
            workflowDescription: '这里不该再像菜单页。',
            primaryActions: const [
              PrimaryActionViewData(
                id: 'session.goal.smart_opening',
                title: '智能开局',
                description: '第一步。',
                commandId: 'session.goal',
              ),
              PrimaryActionViewData(
                id: 'session.goal.chapter_continue',
                title: '章节续写',
                description: '第二步。',
                commandId: 'session.goal',
              ),
            ],
            openingState: const ConversationOpeningStateViewData(
              firstPrompt: '先告诉我你想从哪个方向开始，我会继续追问直到能正式开工。',
              nextStepLabel: '智能开局',
              hasProjectFoundation: false,
              hasResolvedGroup: true,
              missingRequirementTitles: [],
              preferSingleAction: true,
              nextAction: PrimaryActionViewData(
                id: 'session.goal.smart_opening',
                title: '智能开局',
                description: '第一步。',
                commandId: 'session.goal',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('智能开局'), findsOneWidget);
      expect(find.text('续写下一章'), findsNothing);
      expect(find.byType(PrimaryActionList), findsOneWidget);
    },
  );

  testWidgets('conversation sidebar keeps runtime strip in pending state', (
    tester,
  ) async {
    _setLargeTestViewport(tester);
    await tester.pumpWidget(
      _buildSidebarHost(
        viewData: WorkbenchViewData.initial().copyWith(
          pendingOptions: const [
            UserOptionViewData(
              label: '先补资料',
              description: '先补资料再继续。',
              prompt: '请先补资料',
              sourceQuestion: '请先确认资料研究方向。',
              allOptions: <Map<String, Object?>>[],
            ),
          ],
          toolCoreStatus: '请先确认资料研究方向。',
          generationStatus: '智能体需要你先确认下一步选项。',
          conversationEntries: const [
            ConversationEntryViewData(
              id: 'tool_pending_1',
              kind: ConversationEntryKind.tool,
              title: '资料研究请求',
              body: '已发起，正在整理待确认项',
              toolLifecycleStatus:
                  ConversationToolLifecycleStatus.pendingConfirmation,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('待确认'), findsWidgets);
    expect(find.text('请先确认资料研究方向。'), findsWidgets);
  });

  testWidgets(
    'conversation sidebar shows context pressure chips and archive folds from the stable projection',
    (tester) async {
      _setLargeTestViewport(tester);
      final projection = ConversationContextProjectionViewData(
        pressureSnapshot: SessionContextPressureSnapshot(
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 1000,
            reservedOutputTokens: 100,
          ),
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 20,
            messageTokens: 820,
            framingTokens: 12,
          ),
        ),
        transcriptMessageCount: 7,
        workingContextMessageCount: 4,
        compactionSegments: const [
          ConversationContextCompactionSegmentViewData(
            id: 'segment_1',
            title: '发送前压缩',
            summary: '已压缩保存更早历史',
            sourceMessageCount: 3,
            createdAt: '2026-06-14T00:00:00.000Z',
            sourceMessageRoles: ['user', 'assistant'],
          ),
        ],
      );

      await tester.pumpWidget(
        _buildSidebarHost(
          viewData: WorkbenchViewData.initial().copyWith(
            conversationContextProjection: projection,
            conversationEntries: const [
              ConversationEntryViewData(
                id: 'user_1',
                kind: ConversationEntryKind.user,
                title: '你',
                body: '继续写。',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('上下文概览'), findsOneWidget);
      expect(find.textContaining('压力'), findsWidgets);
      expect(find.textContaining('完整历史'), findsWidgets);
      expect(find.textContaining('归档压缩'), findsWidgets);
      expect(find.textContaining('工作窗口'), findsWidgets);
      expect(find.textContaining('预警'), findsWidgets);
      expect(find.textContaining('1 段 / 3 条'), findsWidgets);
      expect(find.text('发送前压缩'), findsOneWidget);
      expect(find.text('已压缩保存更早历史'), findsOneWidget);
    },
  );
}

Widget _buildSidebarHost({
  required WorkbenchViewData viewData,
  ConversationActionHandler actionHandler =
      const _FakeConversationActionHandler(),
  ConversationSectionLayout? sectionLayout,
}) {
  const mapper = WorkbenchPaneViewDataMapperService();
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          height: 920,
          child: PanelSurface(
            role: PanelSurfaceRole.sidebar,
            child: ConversationSidebar(
              viewData: mapper.toConversationViewData(viewData),
              actionHandler: actionHandler,
              showWorkspaceShortcuts: true,
              sectionLayout:
                  sectionLayout ??
                  const ConversationSectionLayout(
                    slotSpecs: [
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.header,
                      ),
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.status,
                      ),
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.body,
                        expand: true,
                      ),
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.appendix,
                      ),
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.composer,
                      ),
                      ConversationSectionSlotSpec(
                        slotId: ConversationSectionSlot.composerAccessory,
                      ),
                    ],
                    placements: [
                      SectionPlacement(
                        sectionId: ConversationSectionId.panelHeader,
                        slotId: ConversationSectionSlot.header,
                        order: 0,
                      ),
                      SectionPlacement(
                        sectionId: ConversationSectionId.runtimeStatus,
                        slotId: ConversationSectionSlot.status,
                        order: 0,
                      ),
                      SectionPlacement(
                        sectionId: ConversationSectionId.timeline,
                        slotId: ConversationSectionSlot.body,
                        order: 0,
                      ),
                      SectionPlacement(
                        sectionId: ConversationSectionId.pendingInput,
                        slotId: ConversationSectionSlot.appendix,
                        order: 0,
                      ),
                      SectionPlacement(
                        sectionId: ConversationSectionId.composer,
                        slotId: ConversationSectionSlot.composer,
                        order: 0,
                      ),
                      SectionPlacement(
                        sectionId: ConversationSectionId.modelStrip,
                        slotId: ConversationSectionSlot.composerAccessory,
                        order: 0,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _setLargeTestViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1800);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  const _FakeConversationActionHandler();

  @override
  void onAgentGroupSelected(String groupId) {}

  @override
  void onConversationAgentSelected(String agentId) {}

  @override
  void onAttachmentRequested() {}

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
  void onReasoningToggleChanged(bool enabled) {}

  @override
  void onQuickThemeRequested() {}

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

  @override
  void setForegroundBackHandler(VoidCallback? handler) {}
}

class _RecordingConversationActionHandler
    extends _FakeConversationActionHandler {
  String selectedGroupId = '';
  String selectedConversationAgentId = '';
  bool? lastReasoningEnabled;
  // 中文注释: 记录侧栏注册的"系统返回键接管"回调——子智能体全屏打开时非空，关闭时为 null。
  VoidCallback? lastForegroundBackHandler;

  @override
  void onAgentGroupSelected(String groupId) {
    selectedGroupId = groupId;
  }

  @override
  void onConversationAgentSelected(String agentId) {
    selectedConversationAgentId = agentId;
  }

  @override
  void onReasoningToggleChanged(bool enabled) {
    lastReasoningEnabled = enabled;
  }

  @override
  void setForegroundBackHandler(VoidCallback? handler) {
    lastForegroundBackHandler = handler;
  }
}
