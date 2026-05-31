# NovelAgentFlutter 工作台重建会话顺序文档

最后更新：2026-05-29

关联文档：

- `agent.md`
- `docs/workbench-strict-gap-audit-2026-05-29.md`
- `docs/workbench-remaining-session-order-2026-05-28.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

---

## 0.1 Session RC-01 完成记录

- 已完成 `Session RC-01：资源树可见目录合同收口`
- 本轮只做了目录合同和默认资源树可见性边界，没有开启下一轮资源投影兼容桥，也没有改任何资源树 UI 壳。
- 本轮收口内容：
  - `ProjectWorkspaceCatalog`
    - 新增 `defaultResourceTreeDirectoryDescriptors`
    - 默认资源树目录集合正式只指向用户主目录 / 用户可见骨架目录
    - `advancedWorkspaceDirs` 与 `internalWorkspaceDirs` 保持独立，不再混进默认资源树目录集合
    - 新增纯合同判断方法：
      - `isDefaultResourceTreePath(...)`
      - `isAdvancedWorkspacePath(...)`
      - `isInternalWorkspacePath(...)`
  - `WorkspaceResourceDisplayService`
    - 默认资源树现在会隐藏高级目录：
      - `agents/`
      - `agent_groups/`
      - `skills/`
      - `skill_groups/`
      - `prompts/`
      - `tracking/`
      - `runs/`
    - 本轮刻意没有处理旧兼容目录：
      - `drafts/`
      - `specs/`
      - `characters/`
      - `inspiration/`
      这些留到 `RC-02`
- 本轮新增 focused test：
  - `packages/novel_agent_core/test/project_workspace_catalog_test.dart`
  - `apps/novel_agent_app/test/workspace_resource_display_service_test.dart`
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/src/project/project_workspace_catalog.dart test/project_workspace_catalog_test.dart`
    - `dart test test/project_workspace_catalog_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/services/workspace_resource_display_service.dart test/workspace_resource_display_service_test.dart`
    - `flutter test test/workspace_resource_display_service_test.dart`
    - 通过
- 当前结论：
  - “默认资源树看什么”已经收成单一事实源，不再默认把高级目录混进用户主树
  - 旧目录兼容还没有完成，因此这条链还不能宣称完全收口
- 下一轮可直接进入 `RC-02`
  - 做资源树投影与旧目录兼容桥

---

## 0.2 Session RC-02 完成记录

- 已完成 `Session RC-02：资源树投影与旧目录兼容桥`
- 本轮只收口了默认资源树投影规则和旧目录兼容隐藏桥，没有开启下一轮 App Shell 隔离，也没有改资源树 UI 外观。
- 本轮收口内容：
  - 新增独立纯服务：
    - `WorkspaceResourceVisibilityService`
  - 这层服务现在单独负责：
    - 默认资源树隐藏内部目录
    - 默认资源树隐藏高级目录
    - 默认资源树隐藏旧兼容根：
      - `drafts/`
      - `specs/`
      - `characters/`
      - `inspiration/`
    - 旧兼容根保留兼容识别能力：
      - `isLegacyCompatibilityPath(...)`
  - `WorkspaceResourceDisplayService`
    - `shouldHidePath(...)` 不再自己堆路径规则
    - 现在改为委托给 `WorkspaceResourceVisibilityService`
  - `WorkbenchWorkspaceController`
    - 继续只消费 `WorkspaceResourceDisplayService`
    - 没有新增路径判断分支，保持 controller 薄
- 本轮新增 focused test：
  - `apps/novel_agent_app/test/workspace_resource_visibility_service_test.dart`
  - `apps/novel_agent_app/test/workspace_resource_display_service_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/services/workspace_resource_display_service.dart lib/features/workbench/application/services/workspace_resource_visibility_service.dart test/workspace_resource_display_service_test.dart test/workspace_resource_visibility_service_test.dart`
    - `flutter test test/workspace_resource_display_service_test.dart test/workspace_resource_visibility_service_test.dart`
    - 通过
- 当前结论：
  - 默认资源树投影规则已经从展示映射逻辑中拆出，旧目录兼容不再继续污染主树
  - 旧目录读写兼容链仍保留在各自存储/业务链路中，本轮没有误删兼容能力
- 下一轮可直接进入 `RC-03`
  - 做 App Shell 旧中心存活链路审计与隔离

---

## 0.3 Session RC-03 完成记录

- 已完成 `Session RC-03：App Shell 旧中心存活链路审计与隔离`
- 本轮只处理了壳层中“已不属于主导航骨架、但仍被默认常驻构造”的旧中心控制器，没有进入左栏对象模型，也没有改工作台 UI。
- 本轮审计结论先收口为两类：
  - 当前仍需保留在壳层的最小 runtime 依赖：
    - `Workbench`
    - `ProjectOpen`
    - `LongTaskStation`
    - `Settings`
    - 以及工作台主链直接调用的共享控制器
  - 当前可推迟初始化/后续可继续迁出的旧中心边界：
    - `BookDeconstructionController`
    - `InspirationWorkbenchController`
    - `ProjectAssetsController`
    - `AgentEcosystem / ProjectCollection / TaskCenter / ReviewCenter / PromptTemplates`
      这一组目前仍有壳层级状态与 action handler 逻辑残留，但当前主路由已经不直接消费它们，后续可以继续从 `AppShellController` 迁出
- 本轮完成的一轮隔离：
  - 新增 `AppShellAuxiliaryControllers`
    - 统一托管旧辅助控制器
    - 改为按需懒创建，不再在 `AppShellController` 构造阶段默认实例化
    - 统一在壳层销毁时释放
  - `AppShellController`
    - 移除了 `ProjectAssetsController / BookDeconstructionController / InspirationWorkbenchController` 的默认常驻构造
    - 改为通过辅助控制器宿主按需获取
    - dispose 链也统一收口到宿主
- 本轮新增 focused test：
  - `apps/novel_agent_app/test/app_shell_auxiliary_controllers_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/app/state/app_shell_controller.dart lib/app/state/app_shell_auxiliary_controllers.dart test/app_shell_auxiliary_controllers_test.dart test/widget_test.dart`
    - `flutter test test/app_shell_auxiliary_controllers_test.dart test/widget_test.dart`
    - 通过
- 当前结论：
  - App Shell 已经完成第一轮“旧中心不再默认常驻构造”的隔离
  - 但 `AgentEcosystem / ProjectCollection / TaskCenter / ReviewCenter / PromptTemplates` 仍有壳层级状态与 handler 残留，这一层还不能宣称彻底收口
- 下一轮可直接进入 `RC-04`
  - 做左栏对象模型收口合同

---

## 0.4 Session RC-04 完成记录

- 已完成 `Session RC-04：左栏对象模型收口合同`
- 本轮只收口了左栏三块对象面板的语义合同与 action 边界，没有做大规模 UI 改造，也没有提前进入项目面板最终收口。
- 本轮收口内容：
  - 左栏三块对象面板现在有了显式合同：
    - `文件`
    - `项目`
    - `长任务`
  - 新增 `WorkbenchSidePanelContractService`
    - 明确每个面板的：
      - 面板语义
      - 主要职责
      - 允许承接的入口类型
      - 明确禁止承接的入口类型
    - 特别标记了这几类入口必须移出左栏对象语义：
      - 系统级中心入口
      - 项目无关入口
      - 纯跳板型入口
  - 新增更细的面板 action handler 合同：
    - `WorkbenchFilePanelActionHandler`
    - `WorkbenchProjectPanelActionHandler`
    - `WorkbenchLongTaskPanelActionHandler`
  - `ResourceManagerActionHandler`
    - 现在改为组合这三类面板合同
    - 左栏各 widget 不再直接依赖一整套混杂职责的泛化 handler
  - `WorkbenchActivityRail`
    - 不再硬编码面板标签与 tooltip
    - 现在改为消费左栏对象面板合同
- 本轮新增 focused test：
  - `apps/novel_agent_app/test/workbench_side_panel_contract_service_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/presentation/contracts/resource_manager_action_handler.dart lib/features/workbench/presentation/contracts/workbench_file_panel_action_handler.dart lib/features/workbench/presentation/contracts/workbench_project_panel_action_handler.dart lib/features/workbench/presentation/contracts/workbench_long_task_panel_action_handler.dart lib/features/workbench/presentation/models/workbench_side_panel_entry_kind.dart lib/features/workbench/presentation/models/workbench_side_panel_contract.dart lib/features/workbench/application/services/workbench_side_panel_contract_service.dart lib/features/workbench/presentation/widgets/workbench_activity_rail.dart lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart lib/features/workbench/presentation/widgets/resource_manager_panel.dart lib/features/workbench/presentation/widgets/workbench_project_panel.dart lib/features/workbench/presentation/widgets/workbench_long_task_panel.dart test/workbench_side_panel_contract_service_test.dart test/workbench_navigation_sidebar_test.dart`
    - `flutter test test/workbench_side_panel_contract_service_test.dart test/workbench_navigation_sidebar_test.dart`
    - 通过
- 当前结论：
  - 左栏已经不再完全依赖隐式语义，后续可以围绕正式合同继续收项目面板和最终简化实现
  - 但这轮没有直接删掉项目面板中的系统级入口；它们现在只是被合同层正式标记为“后续必须移出”，真正的 UI 收口留到 `RC-05`
- 下一轮可直接进入 `RC-05`
  - 做项目面板收口为最小项目对象面板

---

## 0.5 Session RC-05 完成记录

- 已完成 `Session RC-05：项目面板收口为最小项目对象面板`
- 本轮只收口了 `WorkbenchProjectPanel` 及其投影/策略层，没有动会话栏，也没有进入长任务面板或左栏最终简化实现。
- 本轮收口内容：
  - 项目面板不再直接消费 `WorkbenchWorkspaceShellViewData`
  - 新增独立模型与服务：
    - `WorkbenchProjectPanelViewData`
    - `WorkbenchProjectPanelActionViewData`
    - `WorkbenchProjectPanelActionPolicyService`
    - `WorkbenchProjectPanelViewDataService`
  - `WorkbenchSidePanelHost`
    - 现在单独把共享壳层数据投影成项目面板专属 view data
    - 项目面板后续继续收缩时，不再牵动长任务面板或其他壳层
  - `WorkbenchProjectPanel`
    - 只保留三类内容：
      - 当前项目摘要
      - 当前项目协作基线
      - 当前项目最必要的少量动作
    - 项目动作现在只保留：
      - `项目信息`
      - `刷新项目`
      - 无项目时的 `打开项目 / 新建项目`
    - 项目资料入口收成单一项目级入口：
      - `项目资产`
  - 本轮明确移出 / 降级的强入口：
    - `智能体生态`
    - `提示模板`
    - 这两项不再出现在项目面板中
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/workbench_project_panel_test.dart`
  - `apps/novel_agent_app/test/workbench_navigation_sidebar_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/services/workbench_project_panel_action_policy_service.dart lib/features/workbench/application/services/workbench_project_panel_view_data_service.dart lib/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart lib/features/workbench/presentation/models/workbench_project_panel_view_data.dart lib/features/workbench/presentation/widgets/workbench_project_panel.dart lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart test/workbench_project_panel_test.dart test/workbench_navigation_sidebar_test.dart`
    - `flutter test test/workbench_project_panel_test.dart test/workbench_navigation_sidebar_test.dart`
    - 通过
- 当前结论：
  - 左侧项目面板已经不再像“项目配置总站”
  - 系统级能力不再冒充项目对象的日常动作
  - 但项目资产入口仍保留在项目面板中，作为当前唯一保留的项目级资料入口；这不是左栏最终形态，只是当前最小可用收口
- 下一轮可直接进入 `RC-06`
  - 做会话开局状态最小合同

---

## 0.6 Session RC-06 完成记录

- 已完成 `Session RC-06：会话开局状态最小合同`
- 本轮只收口了开局状态投影合同与空态动作选择逻辑，没有直接删除空态按钮 UI，也没有进入 `RC-07` 的去菜单化实现。
- 本轮收口内容：
  - 新增独立最小开局状态模型：
    - `ConversationOpeningStateViewData`
  - 这份模型现在明确承载：
    - 当前项目是否已有基础
    - 当前项目是否已确定开局智能体组
    - 当前还缺哪些关键启动条件
    - 当前唯一最自然的下一步是什么
    - 当前是否应优先退化成单一下一步动作
  - 新增独立纯服务：
    - `ConversationOpeningStateViewDataService`
  - `ConversationGuideViewData`
    - 现在可挂载 `openingState`
    - guide 本身与“最小开局状态”不再混成一坨描述字符串
  - `ConversationGuideViewDataService`
    - 长任务模式、mode guidance、普通 opening、已有基础 continue-ready 等分支，现在都会统一挂上最小开局状态
  - `ConversationOpeningGuideViewDataService`
    - 长任务开局、普通协作、已有基础继续创作、组确认阶段，都不再只返回 workflow 文案
    - 现在会同步附带正式的最小开局状态
  - `ConversationEmptyStateActionProjectionService`
    - 不再只靠 `commandId` 和 openingPanel 粗猜是否显示一堆按钮
    - 现在优先消费 `openingState`
    - 当 `openingState` 明确标记应优先退化成“单一下一步”时，空态动作投影会正式收成唯一下一步
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/conversation_guide_view_data_service_test.dart`
  - `apps/novel_agent_app/test/conversation_empty_state_action_projection_service_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/models/conversation_guide_view_data.dart lib/features/workbench/application/services/conversation_opening_state_view_data_service.dart lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart lib/features/workbench/application/services/conversation_guide_view_data_service.dart lib/features/workbench/presentation/models/conversation_opening_state_view_data.dart lib/features/workbench/presentation/models/workbench_view_data.dart lib/features/workbench/presentation/models/workbench_conversation_view_data.dart lib/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart lib/features/workbench/application/controllers/workbench_conversation_controller.dart lib/features/workbench/presentation/services/conversation_empty_state_action_projection_service.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_guide_view_data_service_test.dart`
    - `flutter test test/conversation_empty_state_action_projection_service_test.dart test/conversation_guide_view_data_service_test.dart`
    - 通过
- 当前结论：
  - 开局体验现在已经有了正式的“第一句提示 + 当前单一下一步”合同
  - 但这一轮还没有直接删掉旧空态按钮布局；只是先让后续去按钮化改造有了稳定事实源
- 下一轮可直接进入 `RC-07`
  - 做会话空态去菜单化，改为 AI 主引导

---

## 0.7 Session RC-07 完成记录

- 已完成 `Session RC-07：会话空态去菜单化，改为 AI 主引导`
- 本轮只收口了会话空态展示与空态动作投影，没有改 `ConversationTimeline`，也没有改子智能体详情全屏链路。
- 本轮收口内容：
  - 新增并正式接入：
    - `ConversationOpeningStateSummary`
  - `ConversationEmptyStatePanel`
    - 现在支持直接消费 `openingState`
    - 当 `openingState` 存在时，空态主体不再渲染“标题 + 描述 + 多按钮菜单”
    - 改为渲染：
      - 第一条主提示
      - 当前自然下一步
      - 缺失条件摘要
      - 单一下一步按钮
    - `openingPanel` 继续只作为补充面板挂在下方
  - `WorkflowGuideCard`
    - 现在也能消费 `openingState`
    - 在无会话但需要 fallback guide card 的场景下，不再回退成大段说明卡
    - 改为复用同一份开局摘要表达，但不重复渲染底部动作按钮
  - `ConversationSidebar`
    - 空态主面板与 fallback guide card 统一透传 `openingState`
    - 当 `openingState` 存在时，底部脱离内容区的 `PrimaryActionList` 不再继续显示
  - `ConversationEmptyStateActionProjectionService`
    - 现在把 `openingState` 视为正式优先级更高的事实源
    - 行为收口为：
      - `preferSingleAction == true && nextAction != null` 时，只显示该单一动作
      - `openingState != null && nextAction != null` 时，只显示该下一步动作
      - `openingState != null && nextAction == null` 时，不再回退成整页菜单动作
      - 只有 `openingState == null` 时，才允许继续使用旧的 `openingPanel / guided actions` 兜底逻辑
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
  - `apps/novel_agent_app/test/conversation_empty_state_action_projection_service_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/presentation/widgets/conversation_sidebar.dart lib/features/workbench/presentation/widgets/conversation_empty_state_panel.dart lib/features/workbench/presentation/widgets/workflow_guide_card.dart lib/features/workbench/presentation/widgets/conversation_opening_state_summary.dart lib/features/workbench/presentation/services/conversation_empty_state_action_projection_service.dart test/conversation_sidebar_test.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_guide_view_data_service_test.dart`
    - `flutter test test/conversation_sidebar_test.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_guide_view_data_service_test.dart`
    - 通过
- 当前结论：
  - 空白会话现在已经不再主要表现为“多入口菜单页”
  - `openingState` 已经成为空态第一句提示与当前唯一下一步的正式事实源
  - 本轮刻意没有触碰时间线结构和子智能体详情展示，因此这两条链仍留给后续任务继续演化
- 下一轮可直接进入 `RC-08`
  - 做组优先入口在会话栏中的正式落位与旧入口去重

---

## 0.8 Session RC-08 完成记录

- 已完成 `Session RC-08：组优先展示去内部化`
- 本轮只收口了会话栏顶部 / 主智能体摘要 / 项目协作基线这条展示链，没有重做生态页，也没有新增组编辑器。
- 本轮收口内容：
  - 新增独立纯策略：
    - `ConversationGroupDisplayTextPolicy`
  - 这层策略现在统一负责：
    - 当前组名稳定 fallback
    - 顶部 subtitle 是否展示
    - 主智能体名称 fallback
    - 内部 id 识别与过滤
    - 项目协作基线摘要文案
  - `ConversationGroupSelectorViewDataService`
    - 不再把内部 `agentId` 当成 `primaryAgentDescription`
    - 当 projection 未就绪或 fallback 标签像内部 id 时，主智能体名称正式退回稳定用户文案
    - 现在会同步产出 `headerSubtitle`
  - `ConversationGroupSelectorViewData`
    - 新增可选字段：
      - `headerSubtitle`
    - 会话头部不再自己猜该显示什么副标题
  - `ConversationPanelHeader`
    - 顶部副标题不再绑定主智能体名称
    - 改为消费组优先的 `headerSubtitle`
  - `ConversationSidebar`
    - 现在把 `groupSelector.headerSubtitle` 透传给 `ConversationPanelHeader`
  - `ProjectAgentGroupPanelViewDataService`
    - 项目协作基线摘要不再重复把“当前组 + 主智能体”再说一遍
    - 改为状态型文案：
      - 已配置：说明项目已绑定默认协作组
      - 未配置：说明当前项目还没有确定默认协作组
    - 协作配置动作文案也收成统一策略，不再把“会话栏轻量切换”这类实现细节写进说明
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/conversation_group_selector_view_data_service_test.dart`
  - `apps/novel_agent_app/test/project_agent_group_panel_view_data_service_test.dart`
  - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/services/conversation_group_display_text_policy.dart lib/features/workbench/application/services/conversation_group_selector_view_data_service.dart lib/features/workbench/application/services/project_agent_group_panel_view_data_service.dart lib/features/workbench/presentation/models/conversation_group_selector_view_data.dart lib/features/workbench/presentation/widgets/conversation_panel_header.dart lib/features/workbench/presentation/widgets/conversation_sidebar.dart test/conversation_group_selector_view_data_service_test.dart test/project_agent_group_panel_view_data_service_test.dart test/conversation_sidebar_test.dart`
    - `flutter test test/conversation_group_selector_view_data_service_test.dart test/project_agent_group_panel_view_data_service_test.dart test/conversation_sidebar_test.dart`
    - 通过
- 当前结论：
  - 会话头部不再把主智能体名称冒充成顶部副标题
  - 组优先展示与主智能体 fallback 文案已经有了单一事实源
  - 生产链路中不再把 `default_generalist` 这类内部 id 暴露给用户
- 下一轮可直接进入 `RC-09`
  - 做中下区会话配置条的重复信息收口与紧凑化

---

## 0.9 Session RC-09 完成记录

- 已完成 `Session RC-09：中栏对象模型收口合同`
- 本轮只收口了中栏主对象、显示模式和辅助视图的合同，没有直接重做最终视觉，也没有改动文档编辑底层存储链路。
- 本轮收口内容：
  - 新增独立纯策略：
    - `DocumentWorkspaceDisplayModePolicyService`
    - `WorkbenchCenterPanePolicyService`
  - 新增中栏专属 view data：
    - `DocumentWorkspaceDisplayModePolicy`
    - `WorkbenchCenterPaneViewData`
    - `WorkbenchCenterAuxiliaryPanelViewData`
  - 这轮正式明确了中栏职责边界：
    - `正文工作区` 是中栏主对象
    - `源码 / 渲染 / 结构` 是同一文档对象的查看方式，不再被视作并列功能中心
    - `结果面板` 被正式降级为 `辅助视图`
    - `审稿` 被正式收口为辅助视图中的一种分析面板，同时仍可从工具栏触发
    - `结构视图` 被正式收口为文档查看模式，而不是独立中栏中心
  - `WorkbenchPrimaryCanvasHost`
    - 不再自己持有“当前模式怎么选、什么时候触发 render toggle”这套隐式判断
    - 改为委托给 `DocumentWorkspaceDisplayModePolicyService`
  - `WorkbenchCanvasWorkspaceShell`
    - 不再自己判断辅助视图是否可显露
    - 改为消费 `WorkbenchCenterPanePolicyService`
  - `WorkbenchAuxiliaryPanelHost`
    - 不再硬编码 `结果面板` 这一调试味更重的概念
    - 改为消费中栏合同产出的辅助视图标题、标签和说明
    - 用户可见标签收口为：
      - `协作基线`
      - `当前文档`
      - `审稿锚点`
      - `上下文`
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/document_workspace_display_mode_policy_service_test.dart`
  - `apps/novel_agent_app/test/workbench_center_pane_policy_service_test.dart`
  - `apps/novel_agent_app/test/workbench_canvas_workspace_shell_test.dart`
  - `apps/novel_agent_app/test/document_workspace_panel_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/application/services/document_workspace_display_mode_policy_service.dart lib/features/workbench/application/services/workbench_center_pane_policy_service.dart lib/features/workbench/presentation/models/document_workspace_display_mode_policy.dart lib/features/workbench/presentation/models/workbench_center_auxiliary_panel_view_data.dart lib/features/workbench/presentation/models/workbench_center_pane_view_data.dart lib/features/workbench/presentation/widgets/workbench_primary_canvas_host.dart lib/features/workbench/presentation/widgets/workbench_auxiliary_panel_host.dart lib/features/workbench/presentation/widgets/workbench_canvas_workspace_shell.dart test/document_workspace_display_mode_policy_service_test.dart test/workbench_center_pane_policy_service_test.dart test/workbench_canvas_workspace_shell_test.dart test/document_workspace_panel_test.dart`
    - `flutter test test/document_workspace_display_mode_policy_service_test.dart test/workbench_center_pane_policy_service_test.dart test/workbench_canvas_workspace_shell_test.dart test/document_workspace_panel_test.dart`
    - 通过
- 当前结论：
  - 中栏不再被默认表述成“一个带很多分支的编辑器功能容器”
  - 后续若继续压缩 UI，已经有了正式的取舍边界：
    - 主对象是文档
    - 显示模式是文档视图
    - 审稿 / 上下文 / 协作基线 / 当前文档切片只是辅助视图
- 下一轮可直接进入 `RC-10`
  - 做中栏顶部工具与标签的去重复收口

---

## 0.10 Session RC-10 完成记录

- 已完成 `Session RC-10：中栏去调试壳第一轮实现`
- 本轮只做了中栏壳层的第一轮弱化，没有追求最终美术，也没有重做所有文档工具。
- 本轮收口内容：
  - `DocumentWorkspaceDisplayModeBar`
    - 从较重的 `SegmentedButton` 退成轻量 `ChoiceChip` 查看方式条
    - 用户可见文案从：
      - `源码 / 渲染 / 结构`
      收口为：
      - `正文 / 预览 / 结构`
    - 中栏第一眼不再更像代码编辑器模式切换器
  - `DocumentToolbarBar`
    - 顶部标题与副说明缩小
    - 旧的重复 `结构视图` 工具按钮已移除
    - 顶部只保留当前必要动作：
      - `保存`
      - `审稿`
    - 显示模式被正式降级为“查看方式”
  - `DocumentWorkspaceHeaderPanel`
    - 去掉大块包裹式头部壳
    - 改为更轻的工具区 + 标签分隔结构
  - `WorkbenchCanvasWorkspaceShell`
    - 辅助信息入口从显眼按钮退成轻量 peek bar
    - 展开后辅助区高度降低，存在感变弱
    - 中栏底部第一眼不再像另一个需要操作的大面板
  - `WorkbenchAuxiliaryPanelHost`
    - 去掉更像独立中心的厚重卡片壳
    - 顶部改为当前辅助视图标题 + 紧凑切换 chips
    - 内容块从卡片式盒子退成更轻的左侧强调块
    - `状态 chip` 也改成更轻的弱强调样式
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/document_workspace_display_mode_bar_test.dart`
  - `apps/novel_agent_app/test/workbench_canvas_workspace_shell_test.dart`
  - `apps/novel_agent_app/test/document_workspace_panel_test.dart`
  - `apps/novel_agent_app/test/widget_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/presentation/widgets/document_workspace_display_mode_bar.dart lib/features/workbench/presentation/widgets/document_toolbar_bar.dart lib/features/workbench/presentation/widgets/document_workspace_header_panel.dart lib/features/workbench/presentation/widgets/workbench_canvas_workspace_shell.dart lib/features/workbench/presentation/widgets/workbench_auxiliary_panel_host.dart test/document_workspace_display_mode_bar_test.dart test/workbench_canvas_workspace_shell_test.dart test/document_workspace_panel_test.dart test/widget_test.dart`
    - `flutter test test/document_workspace_display_mode_bar_test.dart test/workbench_canvas_workspace_shell_test.dart test/document_workspace_panel_test.dart test/widget_test.dart`
    - 通过
- 当前结论：
  - 中栏第一眼已经明显更偏“正文对象 + 轻工具”
  - 辅助视图、查看方式和顶部工具不再抢正文主心智
  - 但这还只是第一轮去壳，后续仍可继续压缩重复信息与局部按钮密度
- 下一轮可直接进入 `RC-11`
  - 做中栏正文对象信息与辅助信息的进一步去重复收口

---

## 0.11 Session RC-11 完成记录

- 已完成 `Session RC-11：左栏最终简化实现`
- 本轮只收口了左栏对象切换壳和内容宿主，没有动全局顶层导航，也没有改会话区。
- 本轮收口内容：
  - `WorkbenchNavigationSidebar`
    - 从 `垂直 rail + 右侧面板` 结构改为单一左栏对象区
    - 顶部现在只保留：
      - `工作台对象`
      - 当前对象标题
      - 当前对象语义摘要
    - 左栏第一眼不再像工作台内又套了一层后台导航
  - `WorkbenchActivityRail`
    - 从竖排大图标按钮改为轻量对象切换 pills
    - 交互语义从“系统入口切换”收成“对象切换”
    - 图标与标签现在同处一个紧凑切换条里，不再占一整列宽度
  - `WorkbenchSidePanelHost`
    - 现在显式消费 `selectedContract`
    - 内容区正式以“当前对象面板”语义承载，不再只是一个被 rail 驱动的匿名容器
    - 保留原有三个对象面板：
      - `文件`
      - `项目`
      - `长任务`
      但不再把它们排成第二层导航系统
- 本轮新增 / 更新 focused test：
  - `apps/novel_agent_app/test/workbench_navigation_sidebar_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/presentation/widgets/workbench_activity_rail.dart lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart test/workbench_navigation_sidebar_test.dart test/workbench_side_panel_contract_service_test.dart`
    - `flutter test test/workbench_navigation_sidebar_test.dart test/workbench_side_panel_contract_service_test.dart test/workbench_project_panel_test.dart`
    - 通过
  - 追加聚焦验证：
    - `flutter analyze test/workbench_navigation_sidebar_test.dart lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart lib/features/workbench/presentation/widgets/workbench_activity_rail.dart lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart`
    - `flutter test test/workbench_navigation_sidebar_test.dart`
    - 通过
- 当前结论：
  - 左栏已经更像工作台内部对象区，而不是“进入工作台后又来一套导航系统”
  - 文件 / 项目 / 长任务 现在是对象切换，不再是第二层系统入口
- 下一轮可直接进入 `RC-12`
  - 做工作台视觉收口前的最后一轮结构级去重复审查

---

## 0.12 Session RC-12 完成记录

- 已完成 `Session RC-12：视觉语言与控件风格统一收口`
- 本轮只做了视觉规格收口与组件换皮，没有改业务合同、没有补新功能。
- 本轮收口内容：
  - 新增 `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_visual_style.dart`
    - 把工作台级的：
      - 间距
      - 字号层级
      - 圆角映射
      - 边框 / 底色透明度
      - chip / badge / 弱化态视觉规则
      收口为单独视觉规格层
    - 明确保持：
      - 主题颜色系统继续来自 theme surface / color token
      - 控件几何继续来自 control style token
      - 工作台只在中间做自己的视觉映射，不把规则散回 widget
  - `WorkbenchDesktopStyle`
    - 改为消费 `WorkbenchVisualStyle`
    - 桌面壳、分栏底色、分隔条透明度不再各写各的 magic number
  - 左栏与对象面板相关组件：
    - `WorkbenchNavigationSidebar`
    - `WorkbenchActivityRail`
    - `WorkbenchProjectPanel`
    - `WorkbenchLongTaskPanel`
    - `ProjectPanelActionTile`
    - 标题 / 摘要 / 标签 / 紧凑切换条的比例统一收口
  - 中栏文档头部相关组件：
    - `DocumentToolbarBar`
    - `DocumentWorkspaceDisplayModeBar`
    - `DocumentWorkspaceHeaderPanel`
    - 顶部标题、说明、查看方式 chips 的字重与密度统一
  - 辅助与分栏壳相关组件：
    - `WorkbenchAuxiliaryPanelHost`
    - `ResourcePanelSection`
    - `ResourceManagerHeader`
    - `WorkbenchDesktopSectionSpecResolver`
    - 边框强弱、辅助区底色、内部 panel block 与状态 badge 的噪音进一步压低
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze lib/features/workbench/presentation/widgets lib/shared/widgets lib/shared/theme test/document_workspace_display_mode_bar_test.dart`
    - `flutter test test/document_workspace_display_mode_bar_test.dart`
    - `flutter test test/workbench_navigation_sidebar_test.dart`
    - `flutter test test/workbench_project_panel_test.dart`
    - `flutter test test/workbench_page_desktop_layout_test.dart`
    - `flutter test test/document_workspace_display_mode_bar_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_project_panel_test.dart test/workbench_page_desktop_layout_test.dart`
    - 通过
- 当前结论：
  - 工作台主要分栏已经更接近“简洁、克制、正式”的统一气质
  - 视觉规则开始真正从 widget 里抽离，后续继续调 theme / control style 时，不需要回到每个组件里逐个找字号和透明度
  - 这一轮没有用更多盒子和更多说明文字去掩盖结构问题，而是在现有结构之上做了正式的视觉收口
- 下一轮可直接进入 `RC-13`
  - 做探针、focused 回归、截图与重新打包前核验

---

## 0.13 Session RC-13 完成记录

- 已完成 `Session RC-13：探针、回归、截图与重新打包前核验`
- 本轮没有补新业务，只把最终缺口收成了正式可复跑的验证闭环。
- 本轮收口内容：
  - 新增 probe：
    - `apps/novel_agent_app/test/workbench_rc13_probe_test.dart`
    - 生成报告：
      - `artifacts/workbench_rc13_probe_report.json`
    - 覆盖：
      - 默认资源树不暴露内部 / 高级目录
      - 旧目录兼容路径继续可识别，但默认隐藏
      - group-first 投影不回退为内部 agent id 文案
      - advanced / internal 路径分类仍稳定
  - 新增整页 workbench regression + screenshot：
    - `apps/novel_agent_app/test/workbench_rc13_regression_test.dart`
    - 生成截图基线：
      - `artifacts/workbench_rc13_screenshots/workbench_desktop_recovery.png`
    - 这条回归把以下事实钉住：
      - 左栏是对象区，不是第二套系统导航
      - 中栏仍是正文主位，没有重新长出“结果面板”
      - 右栏不泄露内部 agent id
      - 默认资源树不再显示 `智能体配置 / 提示词模板 / 执行追踪 / 生成记录`
  - 复用并纳入最终核验链的 focused tests：
    - `apps/novel_agent_app/test/workspace_resource_visibility_service_test.dart`
    - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
    - `apps/novel_agent_app/test/workbench_navigation_sidebar_test.dart`
    - `apps/novel_agent_app/test/workbench_canvas_workspace_shell_test.dart`
    - `apps/novel_agent_app/test/resource_manager_panel_test.dart`
    - `apps/novel_agent_app/test/workbench_page_desktop_layout_test.dart`
    - `packages/novel_agent_core/test/project_workspace_catalog_test.dart`
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `flutter analyze test/workbench_rc13_probe_test.dart test/workbench_rc13_regression_test.dart`
    - `flutter test test/workbench_rc13_probe_test.dart`
    - `flutter test test/workbench_rc13_regression_test.dart --update-goldens`
    - `flutter test test/workbench_rc13_probe_test.dart test/workbench_rc13_regression_test.dart test/workspace_resource_visibility_service_test.dart test/conversation_sidebar_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart test/resource_manager_panel_test.dart test/workbench_page_desktop_layout_test.dart`
    - `flutter build windows`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/project_workspace_catalog_test.dart`
    - 通过
- 当前结论：
  - 这条恢复链现在不再只是“文档任务完成”，而是：
    - 有 probe 报告
    - 有 focused widget / service 回归
    - 有整页桌面工作台截图基线
    - 有 Windows 重新打包成功结果
  - 也就是说，当前这轮恢复链已经形成正式的最终核验闭环
- 本文件中的恢复任务链到此完成

---

## 1. 这份文档取代什么

从这份文档开始：

- `docs/workbench-remaining-session-order-2026-05-28.md`
  不再作为“工作台已经接近收口”的推进总纲
- 后续工作台相关会话，统一以本文件为准

原因已经在：

- `docs/workbench-strict-gap-audit-2026-05-29.md`

里确认：

- 旧文档最后一轮完成，不等于产品目标完成
- 当前仍有结构级缺口，不适合继续沿用旧收尾逻辑

---

## 2. 继续推进的总规则

后续每个 session 都必须遵守这些规则：

1. 每次只完成一个具体任务
2. 如果上个会话停在该任务的一半，先收口，不开启下一任务
3. 每个任务必须控制在单会话可完成的量级
   - 目标改动量：`300 ~ 1800` 行
   - 上限原则：尽量不要超过 `2000` 行有效改动
4. 永远优先解耦合、单一职责、薄控制器、薄 widget
5. 不允许为了图快，把新逻辑重新塞回：
   - `AppShellController`
   - `WorkbenchConversationController`
   - `ConversationSidebar`
   - `WorkbenchPage`
6. 先改合同和投影，再改 UI 壳
7. 探针和回归要放在合适时机做，不要最后才发现主链认知错了
8. 不把“文档任务完成”误报成“产品目标完成”

---

## 3. 本轮重建的总目标

这条新任务链的目标不是“再补几个小问题”，而是：

**把当前工作台从“任务文档完成但产品仍像调试台”的状态，重建为一个真正面向用户、组优先、AI 主引导、CLI 可收口的正式前端。**

---

## 4. 建议推进顺序

本次重建按 5 条轨道交错推进，但顺序固定：

1. `资源树与可见目录合同轨`
2. `工作台对象模型收口轨`
3. `AI 引导替代硬编码入口轨`
4. `组优先产品化收口轨`
5. `中栏与整体视觉收口轨`

其中：

- 前 4 条优先于最终 UI 美化
- 探针 / 回归安排在中后段，不提前假设已经对

---

## 5. Session 列表

---

## 5.1 Session RC-01：资源树可见目录合同收口

### 本轮目标

先把“什么目录允许直接给用户看”这件事收成单一事实源。

### 必须完成

1. 审查并重构：
   - `ProjectWorkspaceCatalog`
2. 明确分成至少三层：
   - 用户主目录
   - 高级但可选目录
   - 内部目录
3. 资源树默认只消费“用户主目录”
4. 明确：
   - `agents/`
   - `agent_groups/`
   - `skills/`
   - `skill_groups/`
   - `prompts/`
   - `tracking/`
   - `runs/`
   不再属于默认资源树主目录

### 本轮不要做

- 不改资源树 UI 外观
- 不改项目面板
- 不顺手删除旧目录读写逻辑

### 本轮重点拆耦

- 目录合同定义
- 资源树默认可见集合
- 高级目录和内部目录边界

### 完成判定

- 资源树是否可见，不再散落在多个 service / controller / widget 猜测
- 默认资源树不再天然暴露内部 / 高级目录

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-01 执行。只做“资源树可见目录合同收口”：重构 ProjectWorkspaceCatalog，把用户主目录、高级目录、内部目录分层，默认资源树只消费用户主目录，不要顺手改 UI 壳，不要开启下一任务。注意解耦合、单一职责，不要把规则散回 controller 和 widget。
```

---

## 5.2 Session RC-02：资源树投影与旧目录兼容桥

### 本轮目标

把 RC-01 的目录合同真正接到工作台资源投影上，同时保留旧目录兼容读写。

### 必须完成

1. 审查并重构资源树投影链：
   - `WorkbenchWorkspaceController`
   - `ResourceEntryViewData` 相关映射
2. 把“默认可见目录过滤”下沉到独立 service
3. 保证旧目录兼容仍可读，但不默认显露
4. 为以下路径建立 focused test：
   - `inspiration/`
   - `drafts/`
   - `characters/`
   - `specs/`
   - 新主目录路径

### 本轮不要做

- 不重构整个资源树 widget
- 不改项目导入 / 创建流程

### 本轮重点拆耦

- 目录兼容判断 service
- 资源树可见性投影 service
- controller 只消费结果，不直接拼规则

### 完成判定

- 用户默认看到的新目录集合稳定
- 旧目录不会丢数据，但不再直接污染主树

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-02 执行。只做“资源树投影与旧目录兼容桥”：把默认可见目录过滤下沉为独立 service，接入 WorkbenchWorkspaceController，并保留 drafts/specs/characters/inspiration 等旧目录兼容读写但不默认显露。补 focused test，不做 UI 美化，不开启下一任务。
```

---

## 5.3 Session RC-03：App Shell 旧中心存活链路审计与隔离

### 本轮目标

先处理代码结构上仍在长期存活、但产品上已不该继续强化的旧中心链路。

### 必须完成

1. 审查并收口这些对象在 app shell 中的长期存活方式：
   - `InspirationWorkbench`
   - `BookDeconstruction`
   - `TaskCenter`
   - `ReviewCenter`
   - `PromptTemplates`
   - `AgentEcosystem`
2. 输出“当前仍需保留的最小 runtime 依赖”和“可推迟初始化/可迁出”的边界
3. 至少完成一轮隔离：
   - 能延迟初始化的不要常驻构造
   - 和工作台主链无关的不要继续作为默认骨架状态长期持有

### 本轮不要做

- 不删整套 feature
- 不重做路由
- 不改工作台 UI

### 本轮重点拆耦

- app shell 持有边界
- 长期存活控制器与页面状态隔离
- 非当前导航骨架对象的惰性装配

### 完成判定

- `AppShellController` 不再无差别背负旧时代全部中心
- 后续 UI 收口时不会继续被旧中心骨架牵制

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-03 执行。只做“App Shell 旧中心存活链路审计与隔离”：收口 InspirationWorkbench、BookDeconstruction、TaskCenter、ReviewCenter、PromptTemplates、AgentEcosystem 在 app shell 的长期持有方式，优先做惰性装配和边界隔离，不删整套 feature，不改工作台 UI。注意单一职责，不要让 AppShellController 更重。
```

---

## 5.4 Session RC-04：左栏对象模型收口合同

### 本轮目标

先明确左栏到底是什么，而不是继续让它同时像导航、文件区、项目配置区。

### 必须完成

1. 审查并定义左栏对象模型：
   - `文件`
   - `项目`
   - `长任务`
2. 明确每个对象面板各自只承接什么职责
3. 明确哪些入口必须移出左栏：
   - 系统级中心入口
   - 项目无关入口
   - 纯跳板型入口
4. 若当前代码中职责已经混杂，先抽 view-data / policy service，不急着改 UI

### 本轮不要做

- 不大改左栏视觉
- 不改全局导航

### 本轮重点拆耦

- `WorkbenchNavigationSidebar`
- `WorkbenchSidePanelHost`
- 各面板 view-data service

### 完成判定

- 左栏不再是“导航套导航”的语义混合区
- 后续实现可按对象职责单独推进

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-04 执行。只做“左栏对象模型收口合同”：明确文件/项目/长任务三个对象面板的职责边界，把系统级中心入口、纯跳板入口从左栏职责里剥离，必要时先抽 policy 或 view-data service，不做大规模 UI 改造，不开启下一任务。
```

---

## 5.5 Session RC-05：项目面板收口为最小项目对象面板

### 本轮目标

把 `WorkbenchProjectPanel` 从“配置入口中心”收成真正的项目对象面板。

### 必须完成

1. 重构 `WorkbenchProjectPanel`
2. 只保留：
   - 当前项目是什么
   - 当前项目当前协作基线是什么
   - 当前项目最必要的少量动作
3. 降级或移出这些强入口：
   - `智能体生态`
   - `提示模板`
   - 其他系统级入口
4. 把项目协作配置动作和项目摘要彻底分层

### 本轮不要做

- 不动会话栏
- 不动长任务面板

### 本轮重点拆耦

- 项目摘要投影
- 项目动作策略
- 项目协作配置入口

### 完成判定

- 左侧项目面板不再像“项目配置总站”
- 系统级功能不再冒充项目日常动作

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-05 执行。只做“项目面板收口为最小项目对象面板”：重构 WorkbenchProjectPanel，只保留项目摘要、协作基线和少量必要动作，移出或降级智能体生态、提示模板等系统级入口。注意解耦合，不要把更多状态拼回 widget。
```

---

## 5.6 Session RC-06：会话开局状态最小合同

### 本轮目标

在改会话 UI 之前，先把“AI 主引导开局”需要的最小状态合同立住。

### 必须完成

1. 审查并重构：
   - `ConversationGuideViewDataService`
   - `ConversationOpeningGuideViewDataService`
   - `ConversationEmptyStateActionProjectionService`
2. 明确最小开局状态只需要哪些信息：
   - 当前项目是否已具备基础
   - 当前组是否已确定
   - 是否还缺关键启动条件
   - 当前唯一最自然的下一步
3. 建立“第一句提示 + 当前单一下一步”的投影模型
4. 为后续去按钮化保留合同

### 本轮不要做

- 不直接删按钮 UI
- 不改 composer

### 本轮重点拆耦

- 开局状态投影
- 空态动作投影
- opening 补充信息投影

### 完成判定

- 开局体验不再默认依赖多按钮菜单
- 后续 UI 可以改成 AI 主引导而不重写控制器

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-06 执行。只做“会话开局状态最小合同”：重构 ConversationGuideViewDataService、ConversationOpeningGuideViewDataService、ConversationEmptyStateActionProjectionService，建立‘第一句提示 + 单一下一步’的最小开局投影模型，不直接删 UI，不开启下一任务。
```

---

## 5.7 Session RC-07：会话空态去菜单化，改为 AI 主引导

### 本轮目标

把右栏空态从“说明书 + 入口盒子”改成“AI 主引导起点”。

### 必须完成

1. 重构：
   - `ConversationEmptyStatePanel`
   - `WorkflowGuideCard`
   - `PrimaryActionList` 在空态中的使用方式
2. 默认只保留：
   - 一句极短引导
   - 当前唯一最自然的下一步
   - 输入框
3. 去掉或显著降级：
   - `智能开局`
   - `导入文资`
   - 一组并列的大按钮菜单

### 本轮不要做

- 不重做时间线
- 不处理子智能体详情

### 本轮重点拆耦

- 空态视觉组件
- 空态动作渲染策略
- AI 引导提示与按钮渲染解耦

### 完成判定

- 空态第一眼更像“可以直接开始对话”
- 不再像一个系统入口菜单页

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-07 执行。只做“会话空态去菜单化，改为 AI 主引导”：重构 ConversationEmptyStatePanel 和 WorkflowGuideCard，让右栏空态只保留极短引导、单一下一步和输入框，降级智能开局/导入文资等硬编码大按钮，不动时间线和子智能体详情，不开启下一任务。
```

---

## 5.8 Session RC-08：组优先展示去内部化

### 本轮目标

把“组优先”从合同层推进到真正的产品展示层，彻底消掉内部 ID 泄露和重复组说明。

### 必须完成

1. 收口这些展示链：
   - `ConversationPanelHeader`
   - `ConversationPrimaryAgentBar`
   - `ConversationGroupSelectorViewDataService`
   - `ProjectAgentGroupPanelViewDataService`
2. 保证：
   - 不再向用户展示 `default-generalist` 这类内部 ID
   - 顶部副标题不再粗暴强调内部主智能体标识
   - 组、主智能体、组说明不在三四处重复表述
3. 如果 projection 未就绪，给稳定用户文案，不回退内部 id

### 本轮不要做

- 不重做生态页
- 不新增组编辑器

### 本轮重点拆耦

- 组优先展示投影
- 主智能体摘要投影
- fallback 文案策略

### 完成判定

- 用户不再看到内部 `agentId`
- 组优先展示链路收成单一事实源

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-08 执行。只做“组优先展示去内部化”：收口 ConversationPanelHeader、ConversationPrimaryAgentBar、ConversationGroupSelectorViewDataService、ProjectAgentGroupPanelViewDataService，确保不再向用户泄露 default-generalist 这类内部 id，减少组与主智能体信息重复，不重做生态页，不开启下一任务。
```

---

## 5.9 Session RC-09：中栏对象模型收口合同

### 本轮目标

先定义中栏到底是什么，防止继续在“正文区 vs 编辑器壳 vs 调试面板”之间摇摆。

### 必须完成

1. 审查并定义中栏主对象职责
2. 明确以下哪些应保留、哪些应降级、哪些应移出主心智：
   - `源码 / 渲染 / 结构`
   - `结果面板`
   - `审稿`
   - `结构视图`
   - `文档工作区`
3. 先抽合同 / policy，不急着一轮全改 UI

### 本轮不要做

- 不直接做最终视觉
- 不顺手改文档编辑底层

### 本轮重点拆耦

- 文档主对象模型
- 中栏辅助面板策略
- 中栏模式切换策略

### 完成判定

- 中栏不再默认被视作一个编辑器功能容器
- 后续实现会有明确的取舍边界

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-09 执行。只做“中栏对象模型收口合同”：审查源码/渲染/结构、结果面板、审稿、结构视图、文档工作区这些概念在中栏里的地位，先抽 policy 和职责边界，不急着一轮做完 UI，不开启下一任务。
```

---

## 5.10 Session RC-10：中栏去调试壳第一轮实现

### 本轮目标

落实 RC-09 的第一轮实现，把最像调试台的中栏壳先拆掉。

### 必须完成

1. 重构：
   - `WorkbenchCanvasWorkspaceShell`
   - `WorkbenchAuxiliaryPanelHost`
   - `DocumentToolbarBar`
   - `DocumentWorkspaceDisplayModeBar`
2. 优先处理：
   - `结果面板` 的主界面存在感
   - `源码 / 渲染 / 结构` 的壳层重量
   - 文档区顶部过强的“工具台”感
3. 不破坏正文区基本可用性

### 本轮不要做

- 不在这一轮追求最终美术效果
- 不重做所有文档工具

### 本轮重点拆耦

- 中栏辅助信息的弱化呈现
- 文档显示模式与主心智解耦
- 文档工具动作与布局壳解耦

### 完成判定

- 中栏第一眼不再像调试/编辑器面板
- 正文对象感明显高于工具壳感

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-10 执行。只做“中栏去调试壳第一轮实现”：重构 WorkbenchCanvasWorkspaceShell、WorkbenchAuxiliaryPanelHost、DocumentToolbarBar、DocumentWorkspaceDisplayModeBar，优先削弱结果面板、源码/渲染/结构和过重工具壳的存在感，保持正文区可用，不追求最终美术，不开启下一任务。
```

---

## 5.11 Session RC-11：左栏最终简化实现

### 本轮目标

把左栏最终收成真正的对象面板，而不是“第二套工作台导航”。

### 必须完成

1. 重构：
   - `WorkbenchNavigationSidebar`
   - `WorkbenchActivityRail`
   - `WorkbenchSidePanelHost`
2. 解决：
   - 导航感过强
   - 图标栏像第二层系统入口
   - 左栏对象面板和全局导航重复竞争
3. 若需要，改成更轻的对象切换方式

### 本轮不要做

- 不动全局顶层导航
- 不重做会话区

### 本轮重点拆耦

- 左栏对象切换控件
- 左栏内容宿主
- 左栏“对象切换”与“系统导航”语义分离

### 完成判定

- 左栏更像工作台内部对象区
- 不再像“进入工作台后又来一套导航系统”

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-11 执行。只做“左栏最终简化实现”：重构 WorkbenchNavigationSidebar、WorkbenchActivityRail、WorkbenchSidePanelHost，削弱第二层导航感，让左栏更像工作台对象面板，不动全局导航，不改会话区，不开启下一任务。
```

---

## 5.12 Session RC-12：视觉语言与控件风格统一收口

### 本轮目标

在前面结构收口之后，最后再做真正的视觉统一，不提前用视觉掩盖结构问题。

### 必须完成

1. 对照参考风格，只吸收风格不照搬布局
2. 收口：
   - 边框密度
   - 卡片感
   - 控件尺寸与文字比例
   - 深浅对比与噪音
3. 保持：
   - 主题颜色系统
   - 控件风格系统
   相互独立
4. 避免把一堆视觉规则再次散回 widget

### 本轮不要做

- 不改业务合同
- 不顺手扩更多功能

### 本轮重点拆耦

- 控件风格 token / spec
- 组件级视觉配置
- 页面布局与视觉皮肤分层

### 完成判定

- 工作台整体气质接近你要的简洁、克制、正式风格
- 不是靠更多盒子和更多说明文字撑界面

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-12 执行。只做“视觉语言与控件风格统一收口”：在结构收口之后，对照参考风格只吸收风格不照搬布局，统一边框密度、卡片感、控件尺寸和文字比例，同时保持主题颜色系统与控件风格系统解耦，不改业务合同，不开启下一任务。
```

---

## 5.13 Session RC-13：探针、回归、截图与重新打包前核验

### 本轮目标

在前面所有收口做完后，重新建立新的最终核验闭环。

### 必须完成

1. 回归至少这些场景：
   - 默认资源树不暴露内部/高级目录
   - 旧目录兼容仍可读
   - 会话空态不再是菜单页
   - 顶部不再泄露内部 agent id
   - 中栏不再保留重调试壳
   - 左栏不再像第二套导航
2. 新增 probe / focused widget / screenshot
3. 回填文档
4. 确认可重新打包

### 本轮不要做

- 不补新业务
- 不临时为了测试再加一堆调试入口

### 本轮重点拆耦

- probe 脚本
- focused 回归测试
- 截图基线

### 完成判定

- 这轮重建链不再只是“代码做了”
- 而是对最终用户体验缺口有正式回归证明

### 建议提示词

```text
按 docs/workbench-recovery-session-order-2026-05-29.md 的 Session RC-13 执行。只做“探针、回归、截图与重新打包前核验”：回归资源树默认可见目录、旧目录兼容、空态去菜单化、去内部 agent id、左栏去二级导航感、中栏去调试壳，并新增 probe、focused test 与截图基线，回填文档，不补新业务，不开启下一任务。
```

---

## 6. 使用方式

从现在开始，建议统一用下面这种方式继续：

```text
根据目前的进度和文档：docs/workbench-recovery-session-order-2026-05-29.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体的任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务，如果已经确认可以开启下一轮任务，那么可以直接开始，你需要直接识别相关的提示词、任务内容、任务约束等等并出色地完成。注意解耦合、单一职责、不要让单文件过重，必要时补 focused test 或 probe。开始吧。
```

---

## 7. 最后一句话定义

这条新任务链的最终目标不是“把旧工作台修顺眼一点”，而是：

**把当前这套仍带着编辑器壳、内部目录泄露和多入口残留的工作台，重建成真正以用户任务、AI 协作和稳定对象模型为核心的正式前端。**
