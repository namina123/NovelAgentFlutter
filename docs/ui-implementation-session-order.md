# NovelAgentFlutter 前端实现会话顺序文档

最后更新：2026-05-26

## 0.1 Session UI-01 完成记录

- 已完成 `Session UI-01：主题 token 基座与共享 surface spec`
- 已落地：
  - 主题基座模型：
    - `ThemeDescriptor`
    - `ThemeColorTokens`
    - `ThemeChromeTokens`
    - `ThemeSurfaceSpec`
    - `ThemeSurfaceSpecSet`
    - `ThemeTokenSet`
  - 主题组装与注册：
    - `ThemeRegistry`
    - `ThemeResolver`
    - `NovelThemeExtension`
  - 共享读取入口：
    - `shared/theme/novel_theme_context.dart`
  - 现有明亮 / 偏暗主题已接入正式 token 注册表
  - 工作台相关共享表面已开始消费统一 surface spec：
    - `PanelSurface`
    - `AppShellActivityRail`
    - `AppShellCompactBar`
    - `PaneResizeDivider`
    - `WorkbenchPage` 的栏位表面角色
  - 基础共享按钮已开始消费统一 token：
    - `ActionButton`
    - `ToolbarIconButton`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/theme apps/novel_agent_app/lib/shared/theme apps/novel_agent_app/lib/shared/widgets/panel_surface.dart apps/novel_agent_app/lib/shared/widgets/action_button.dart apps/novel_agent_app/lib/shared/widgets/toolbar_icon_button.dart apps/novel_agent_app/lib/shared/widgets/app_shell_activity_rail.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_bar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/pane_resize_divider.dart apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart`
  - 通过
- 后续扩展点：
  - 设置页后续可以直接消费 `AppTheme.builtInDescriptors()`
  - 未来自定义主题可继续沿 `ThemeRegistry -> ThemeResolver -> NovelThemeExtension` 扩展
  - 目前仍有大量业务 widget 直接使用 `AppPalette`，后续会在各自 session 中按区域逐步迁移，不在本轮硬改
  - `ThemeSurfaceSpecSet` 目前已覆盖：
    - `panel`
    - `sidebar`
    - `inputDock`
    - `conversationEntry`
    - `toolRow`
    - `optionTile`
    - `splitter`
    后续可继续扩到资源树、标签条、状态条等 feature spec

## 0.2 Session UI-02 完成记录

- 已完成 `Session UI-02：会话栏消息条目拆分与滚动稳定化`
- 已落地：
  - 会话时间线滚动策略拆分：
    - `ConversationTimelineSnapshot`
    - `ConversationTimelineAutoRevealPolicy`
  - 会话条目 widget 组拆分：
    - `ConversationEntryPalette`
    - `ConversationDetailSection`
    - `ConversationMessageEntryTile`
    - `ConversationToolEntryRow`
    - `ConversationGeneratingPlaceholder`
  - `ConversationEntryTile` 已收窄为轻量分发壳，不再同时承载：
    - 展示分发
    - 细节折叠状态
    - 工具行布局
    - 助手 / 用户 / 系统卡片渲染
  - `ConversationTimeline` 已改为：
    - 统一滚动容器
    - 同一列表内承接正文条目 / 生成占位 / footer
    - 仅在“用户仍停留在最新输出附近”时自动追随流式内容
  - 思考细节折叠已独立成 `ConversationDetailSection`，后续可继续服务思考摘要样式微调
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/models/conversation_timeline_snapshot.dart apps/novel_agent_app/lib/features/workbench/presentation/services/conversation_timeline_auto_reveal_policy.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_entry_palette.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_detail_section.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_message_entry_tile.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_tool_entry_row.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_generating_placeholder.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_entry_tile.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_timeline.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart apps/novel_agent_app/test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
  - `flutter test test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
- 后续扩展点：
  - `ConversationTimelineAutoRevealPolicy` 后续可继续细化为：
    - 工具条目是否参与自动追随
    - footer 出现时是否总是滚到底
    - 思考展开后是否保持阅读锚点
  - 当前还没有做：
    - 工具细节显示开关
    - 选项卡折叠体系
    - 输入区 / 模型条重构
    这些继续留给后续 session

## 0.3 Session UI-03 完成记录

- 已完成 `Session UI-03：工具调用行与选项卡折叠体系`
- 已落地：
  - 工具显示状态模型：
    - `ConversationToolVisibilityState`
  - 工具细节开关组件：
    - `ToolVisibilityToggle`
  - 选项卡折叠组件：
    - `ExpandableOptionTile`
  - 会话侧栏已接入会话级工具细节显示状态：
    - 默认折叠
    - 只作用于当前会话侧栏展示
    - 不回灌控制器业务状态
  - 工具时间线已补齐细节层：
    - `ConversationToolEntryProjectionService` 现在会为工具条目投影
      - `detailTitle`
      - `detailSummary`
      - `detailBody`
    - 工具细节会展示参数与结果的结构化文本
  - 工具条目 UI 已收束为：
    - 默认单行轻量展示
    - 成功 / 失败状态图标区分
    - 打开工具细节开关后可逐条展开查看参数 / 结果
  - 选项区已收束为：
    - 折叠态等高
    - 默认紧凑摘要
    - 展开后查看完整描述与 prompt
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/models/conversation_tool_visibility_state.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/tool_visibility_toggle.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/expandable_option_tile.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/user_option_tile.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/user_option_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_tool_entry_row.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_entry_tile.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_timeline.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart apps/novel_agent_app/test/conversation_tool_entry_projection_service_test.dart`
  - 通过
  - `flutter test test/conversation_timeline_auto_reveal_policy_test.dart test/conversation_tool_entry_projection_service_test.dart`
  - 通过
- 后续扩展点：
  - 工具细节目前使用结构化文本展开，后续可继续细化为：
    - 参数区
    - 结果区
    - 差异路径区
  - 当前工具细节开关是会话侧栏本地状态；如果后续需要跨会话持久化，可单独接设置层
  - 输入区、模型条、停止按钮、附件入口仍留给下一轮 `Session UI-04`

## 0.4 Session UI-04 完成记录

- 已完成 `Session UI-04：输入区、模型条、停止按钮、附件壳重构`
- 已落地：
  - 输入区能力状态模型：
    - `ConversationInputCapabilityState`
  - 输入区能力判定服务：
    - `ConversationInputCapabilityService`
  - 模型条组件：
    - `ConversationModelStrip`
  - 输入区动作行组件：
    - `ConversationInputActionRow`
  - 正式输入坞组件：
    - `ConversationInputDock`
  - 会话侧栏已改成：
    - 底部输入坞
    - 输入坞下方模型条
    - 不再把模型/智能体选择器固定在侧栏头部
  - 动作合同已补齐：
    - `onStopRequested()`
    - `onAttachmentRequested()`
  - 停止按钮行为已切换为：
    - 生成中显示“停止”
    - 非生成态显示“发送”
  - 附件入口行为已切换为：
    - 桌面端显示
    - 移动端隐藏
  - 控制器侧当前只接入 UI 壳反馈：
    - 停止生成真实中断链尚未完全接通
    - 附件真实文件传输链尚未接通
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/models/conversation_input_capability_state.dart apps/novel_agent_app/lib/features/workbench/application/services/conversation_input_capability_service.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_dock.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart apps/novel_agent_app/lib/features/workbench/presentation/contracts/conversation_action_handler.dart apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/test/conversation_input_capability_service_test.dart`
  - 通过
  - `flutter test test/conversation_input_capability_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
- 后续扩展点：
  - `onStopRequested()` 目前只是动作合同与用户反馈，后续需要接真实取消链
  - `onAttachmentRequested()` 目前只是桌面入口壳，后续需要接真实文件选择与传输
  - `SelectorField` 目前仍沿用旧选择器形态，后续可在模型条 session 之外单独细化为更强的输入选择框
  - 窄屏单列抽拉栏与按钮密度优化继续留给下一轮 `Session UI-05`

## 0.5 Session UI-05 完成记录

- 已完成 `Session UI-05：窄屏单列抽拉功能栏与入口保活`
- 已落地：
  - 紧凑布局导航目录查询入口：
    - `AppShellNavigationCatalog.findItem()`
    - `AppShellNavigationCatalog.findSection()`
  - 紧凑抽拉栏状态控制器：
    - `AppShellCompactDrawerController`
  - 紧凑抽拉导航面板：
    - `AppShellCompactDrawer`
  - 紧凑布局壳：
    - `AppShellCompactScaffold`
  - 紧凑顶部条已重构为：
    - 轻量当前页识别
    - 菜单按钮
    - 当前页图标提示
  - 根壳层 `AppShell` 已改成：
    - compact 模式使用 `AppShellCompactScaffold`
    - expanded / medium 继续沿用既有工作台和桌面 rail 结构
  - 单列模式功能入口已改成：
    - 主视图继续保留页面正文 / 会话卷轴
    - 左下角悬浮式抽拉入口稳定保活
    - 展开后按分组展示全部主导航入口
    - 点击导航后自动收起抽拉栏
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/shared/widgets/app_shell.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_bar.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_drawer.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_drawer_controller.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_scaffold.dart apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart apps/novel_agent_app/test/app_shell_compact_scaffold_test.dart`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/conversation_input_capability_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
- 后续扩展点：
  - 抽拉栏当前负责 app 级入口，不介入 workbench 内部资源树 / 文档树细节
  - 后续如果需要加入“最近项目 / 当前运行摘要 / 未读状态点”，优先扩在 `AppShellCompactDrawer` 子组件，不回塞 `AppShell`
  - 当前左下入口会覆盖主视图一小块区域；如果后续要进一步减弱遮挡，应在 `Session UI-06` 或 `UI-07` 统一与工作台面板节奏一起收束
  - 桌面三栏风格、资源区和中间工作区样式仍留给后续 session，不在本轮顺手扩张

## 0.6 Session UI-06 完成记录

- 已完成 `Session UI-06：桌面三栏风格统一与分栏结构收束`
- 已落地：
  - 桌面工作台底板：
    - `WorkbenchDesktopSurface`
  - 桌面栏位壳：
    - `WorkbenchPaneShell`
  - 工作台页面已改成：
    - `twoPane` 使用统一桌面底板
    - `threePane` 使用统一桌面底板
    - 资源栏 / 正文栏 / 会话栏 改走独立栏位壳，而不是直接把 `PanelSurface` 平铺在页面里
  - 分隔条视觉已收束为：
    - 保留拖拽能力
    - 悬停时增强可见性
    - 更接近编辑器工作区分栏，而不是单纯一条竖线
  - `WorkbenchPage` 已补齐桌面栏位构建辅助方法：
    - `_buildDesktopResourcePane()`
    - `_buildDesktopDocumentPane()`
    - `_buildDesktopConversationPane()`
  - 双栏模式原有的 `showWorkspaceShortcuts` 已保留，不因桌面壳重构被意外丢掉
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/pane_resize_divider.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_desktop_surface.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_pane_shell.dart apps/novel_agent_app/test/workbench_page_desktop_layout_test.dart`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/app_shell_compact_scaffold_test.dart test/conversation_input_capability_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
- 后续扩展点：
  - 当前桌面壳层只收束了 workbench 外层的分栏语义，还没有深入到资源树行高、正文工具条、标签条、文档画布这些内层细节
  - `ResourceTreeCard`、`DocumentTabStrip`、`DocumentContentCanvas` 这类内部组件仍有旧的局部配色与表面写法，留给 `Session UI-07`
  - 本轮刻意没有改资源渲染器、长任务总站和主题设置页，避免桌面壳重构顺势扩成新主线

## 0.7 Session UI-07 完成记录

- 已完成 `Session UI-07：资源树与文档工作区样式收束`
- 已落地：
  - 资源面板内层分区壳：
    - `ResourcePanelSection`
  - 资源树拆分组件：
    - `ResourceTreeEntryTile`
    - `ResourceTreeEmptyState`
  - 资源面板已改成：
    - 项目与文件动作区独立分区
    - 目录树独立分区
    - 工作区入口独立分区
    - 左栏窄宽度时自动收窄横向 padding，减轻被挤压时的丢失感
  - 目录树表现已收束为：
    - 统一行高
    - 统一缩进
    - 统一选中态
    - 目录条目直接显示下级数量
  - 文档工作区新增共享基座：
    - `DocumentWorkspaceCanvasFrame`
  - 文档工作区显示模式壳：
    - `DocumentWorkspaceDisplayMode`
    - `DocumentWorkspaceDisplayModeBar`
  - 文档工具栏已改成：
    - 顶部标题与动作
    - 下方显示模式条
    - 为 `源码 / 渲染 / 结构` 三种入口预留稳定位置
  - 文档画布已统一到共享外框：
    - `DocumentEmptyCanvas`
    - `DocumentContentCanvas`
    - `DocumentMarkdownCanvas`
  - 文档标签条已改走主题 surface，而不是继续使用旧的局部 `AppPalette` 表面
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_panel_section.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_tree_card.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_toolbar_bar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_display_mode_bar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_canvas_frame.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_content_canvas.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_markdown_canvas.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_empty_canvas.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_tab_strip.dart apps/novel_agent_app/test/resource_tree_card_test.dart apps/novel_agent_app/test/document_workspace_display_mode_bar_test.dart`
  - 通过
  - 残留 `1` 条非阻塞 style info：`resource_panel_section.dart` 中对 `trailing` 的空判断写法，未影响构建与测试
  - `flutter test test/resource_tree_card_test.dart test/document_workspace_display_mode_bar_test.dart test/workbench_page_desktop_layout_test.dart test/app_shell_compact_scaffold_test.dart test/conversation_input_capability_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart`
  - 通过
- 后续扩展点：
  - `DocumentWorkspaceDisplayModeBar` 目前只是稳定入口壳，真正 renderer 注册与模式切换留给 `Session UI-08`
  - `DocumentToolbarBar` 里的“结构”目前仍走已有 outline 动作，不等于真正结构化 renderer
  - 资源树虽然已经完成样式收束，但尚未进入更深层的虚拟滚动、拖拽重排或多列信息展示
  - 本轮没有开启 renderer registry，也没有触碰长任务或项目创建相关前端链路

## 0.8 Session UI-08 完成记录

- 已完成 `Session UI-08：资源渲染器合同与首批 renderer 接线`
- 已落地：
  - 资源渲染请求与合同：
    - `DocumentResourceRenderRequest`
    - `DocumentResourceRenderer`
  - 资源渲染器注册与解析：
    - `DocumentResourceRendererRegistry`
    - `DocumentResourceRendererResolution`
    - `DocumentResourceRendererResolver`
  - 首批 renderer：
    - `DocumentEmptyResourceRenderer`
    - `DocumentPlainTextResourceRenderer`
    - `DocumentMarkdownResourceRenderer`
    - `DocumentStructuredResourceRenderer`
  - 中间工作区已改成：
    - `DocumentWorkspacePanel` 负责构造 render request
    - 通过 resolver + registry 选择 renderer
    - 不再在页面内直接分支“空态 / markdown / 编辑态”
  - 显示模式行为已收束为：
    - `源码` 走纯文本 renderer
    - `渲染` 走 markdown renderer，且保留旧的 render toggle 兼容
    - `结构` 走真正的结构化只读占位 renderer，而不是继续借用 outline 动作假装切换
  - `DocumentContentCanvas` 已补齐只读能力，为后续非编辑型文本 renderer 复用留口
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/renderers apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_content_canvas.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_toolbar_bar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_panel.dart apps/novel_agent_app/test/document_resource_renderer_resolver_test.dart apps/novel_agent_app/test/document_workspace_panel_test.dart`
  - 通过
  - `flutter test test/document_resource_renderer_resolver_test.dart test/document_workspace_panel_test.dart test/document_workspace_display_mode_bar_test.dart test/resource_tree_card_test.dart test/workbench_page_desktop_layout_test.dart`
  - 通过
- 后续扩展点：
  - `DocumentResourceRendererResolver` 目前只覆盖首批资源识别，后续新增富媒体、关系图、资产卡片时只需新增 renderer 与 resolver 规则，不必改页面主壳
  - `结构` 视图目前仍是共享占位，后续可继续细分为章节树、角色引用、时间线、资产只读卡片等结构投影
  - `源码 / 渲染` 的用户选择目前仍主要依赖现有打开文档 render toggle 持续化；如果后续需要跨资源持久记忆更多显示模式，应单独补工作区本地 display preference 层，不要回塞页面状态机
  - 本轮没有顺手做资产中心整页重构，也没有开启图谱类复杂渲染，保持 `UI-08` 只完成资源 renderer 基座

## 0.9 Session UI-09 完成记录

- 已完成 `Session UI-09：长任务工作台 / 总站操作闭环`
- 已落地：
  - 长任务总站列表投影已补齐：
    - 所属项目路径
    - 运行基准 / 运行模式摘要
    - 最近活动时间
    - 待处理态高亮
  - 长任务总站详情已收束出独立动作部件：
    - `LongTaskRunActionBar`
    - `LongTaskRunAttentionCallout`
  - 长任务详情中的“错误后处理入口壳”已补齐：
    - `重试推进`
    - `去任务中心`
    - `去审稿中心`
    - `打开项目`
  - 工作台当前项目长任务摘要基座已建立：
    - `ProjectLongTaskSummaryViewData`
    - `ProjectLongTaskRunSummaryViewData`
    - `ProjectLongTaskSummaryViewDataService`
    - `ProjectLongTaskSummaryPanel`
  - `WorkbenchWorkspaceController` 已接入当前项目长任务摘要刷新链：
    - 项目加载后读取当前项目相关运行实例
    - 切回工作台时主动刷新摘要
    - 项目清空时同步清理摘要状态
  - 资源栏已新增“长任务运行”分区，并在矮高度场景切换为整栏可滚动布局，避免新增摘要后再次把入口挤出视口
  - 共享时间标签工具已补齐：
    - `ActivityTimeLabelService`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/features/long_task_station apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart apps/novel_agent_app/lib/features/workbench/application/models/workbench_project_runtime_state.dart apps/novel_agent_app/lib/features/workbench/application/services/project_long_task_summary_view_data_service.dart apps/novel_agent_app/lib/features/workbench/presentation/models/project_long_task_summary_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_long_task_summary_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart apps/novel_agent_app/lib/shared/services/activity_time_label_service.dart apps/novel_agent_app/test/long_task_station_view_data_service_test.dart apps/novel_agent_app/test/project_long_task_summary_view_data_service_test.dart apps/novel_agent_app/test/resource_manager_panel_test.dart`
  - 通过
  - `flutter test test/long_task_station_view_data_service_test.dart test/project_long_task_summary_view_data_service_test.dart test/resource_manager_panel_test.dart test/resource_tree_card_test.dart test/workbench_page_desktop_layout_test.dart`
  - 通过
- 新增测试：
  - `test/long_task_station_view_data_service_test.dart`
  - `test/project_long_task_summary_view_data_service_test.dart`
  - `test/resource_manager_panel_test.dart`
- 后续扩展点：
  - 当前工作台摘要只提供“项目级总览 + 打开总站”，如果后续需要直接定位某个 run，可在不扩壳层状态的前提下补“预选中 run”导航口
  - `LongTaskRunAttentionCallout` 目前仍是操作壳，真正更细的 retry / repair 分流策略继续由后续核心链与任务中心承担
  - 长任务总站本轮没有开启复杂统计图表，也没有动后台自动恢复策略，保持 `UI-09` 只完成前端闭环

## 0.10 Session UI-10 完成记录

- 已完成 `Session UI-10：项目创建与无有效项目拦截前端闭环`
- 已落地：
  - 无有效项目默认恢复链已改成正式 guard 入口：
    - 没有默认项目
    - 默认项目失效
    - 设置尚未恢复出有效项目
    都会先把工作台重置到无项目状态，再弹出不可直接跳过的 `ProjectLauncherMode.guard`
  - guard 浮层已明确收束为两个主入口：
    - `创建新项目`
    - `打开已有项目`
  - 桌面端“打开已有项目”保持走原生目录选择：
    - 选择后立即校验是否为有效项目根目录
    - 无效目录会回到 guard 并给出状态提示
  - 移动端继续不显示“打开已有项目”入口，只允许在应用项目目录内创建项目
  - 创建向导正式改成三段式前端流程：
    - `项目类型`
    - `主存储策略`
    - `长任务运行基准`
  - `ProjectCreatePanel` 的返回链已接通：
    - `storageStrategy -> projectType`
    - `runtimeBaseline -> storageStrategy`
  - `ProjectCreationController` 已清掉旧的 `open / basics` 残留，改为只消费当前正式的：
    - `ProjectLauncherMode.guard`
    - `ProjectLauncherMode.create`
    - `ProjectCreationPhase.projectType / storageStrategy / runtimeBaseline`
  - 打开已有项目不再依赖默认目录扫描列表；前端闭环以“guard + 桌面路径选择”作为正式方案
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/bootstrap/app_bootstrap.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/features/project_creation apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_launcher_overlay.dart apps/novel_agent_app/lib/features/workbench/presentation/contracts/resource_manager_action_handler.dart apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
  - 通过
  - `flutter test test/project_creation_controller_test.dart test/app_shell_compact_scaffold_test.dart test/workbench_page_desktop_layout_test.dart test/resource_manager_panel_test.dart`
  - 通过
- 新增测试：
  - `test/project_creation_controller_test.dart`
- 后续扩展点：
  - 当前 guard / create 浮层先把领域流程闭环做实，还没有进入最终视觉精修
  - `ProjectLauncherViewData.entries` 与 `onProjectEntryOpened` 仍作为兼容口保留，但当前正式用户路径已经不是“列出项目列表”，后续若确认彻底不用，可单独做一次小清理
  - 主题样式、设置页切换和 guard/create 的统一视觉收束留给下一轮 `Session UI-11`

## 0.11 Session UI-11 完成记录

- 已完成 `Session UI-11：主题设置页与主题注册表前端闭环`
- 已落地：
  - 主题偏好解析器已独立收束：
    - `ThemePreferenceResolver`
    - 正式识别 `selected_theme_id`
    - 兼容旧的 `themeSettings.mode`
    - 提供快速亮暗切换与兼容 payload 写回
  - `AppTheme` 已补齐显式主题入口：
    - `themeDataFor(String id)`
  - 应用根已不再只靠 `ThemeMode light/dark` 二选一：
    - `NovelAgentApp` 直接消费 `controller.activeThemeData`
    - 当前激活主题成为真正的应用级事实源
  - 设置页主题子域已补齐独立 view data：
    - `ThemeSettingsViewData`
    - `ThemeOptionViewData`
    - `ThemeSettingsViewDataService`
  - 主题设置面板已正式改成：
    - 读取 `ThemeRegistry` 内置主题列表
    - 显示当前选中项
    - 内置主题 / 后续内置主题 / 自定义主题预留 三段分区
    - 保存时写回正式 `selected_theme_id`
  - 会话栏的“快速主题”按钮已改走正式主题偏好写盘链：
    - 不再只改临时 UI 状态
    - 设置页与工作台现在共用同一条主题事实源
  - `SettingsFormSection` 已开始消费统一主题表面 token，避免主题设置页本身继续停留在固定旧配色
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/theme apps/novel_agent_app/lib/app/app.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/features/settings apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart apps/novel_agent_app/test/theme_preference_resolver_test.dart apps/novel_agent_app/test/theme_settings_view_data_service_test.dart apps/novel_agent_app/test/theme_settings_panel_test.dart`
  - 通过
  - `flutter test test/theme_preference_resolver_test.dart test/theme_settings_view_data_service_test.dart test/theme_settings_panel_test.dart test/project_creation_controller_test.dart test/app_shell_compact_scaffold_test.dart test/workbench_page_desktop_layout_test.dart`
  - 通过
- 新增测试：
  - `test/theme_preference_resolver_test.dart`
  - `test/theme_settings_view_data_service_test.dart`
  - `test/theme_settings_panel_test.dart`
- 后续扩展点：
  - 当前只开放内置主题切换，自定义主题仍是预留入口壳，没有开放编辑器和导入流程
  - 还有一部分旧设置组件仍直接使用 `AppPalette`，后续如果要让设置页所有子面板完全跟随主题，需要在 `UI-12` 联调中按暴露问题继续收束
  - 主题注册表当前只有 `builtin.light / builtin.dark` 两套；后续新增内置主题时，应继续沿 `ThemeRegistry -> ThemeSettingsViewDataService -> ThemeSettingsPanel` 扩展，不回退到散落枚举

## 0.12 Session UI-12 完成记录

- 已完成 `Session UI-12：联调回归、探针、打包前修整`
- 本轮实际收口点：
  - `widget_test` 已更新到当前正式装配合同：
    - 去掉旧的 `discoverProjectsUseCase`
    - 补齐 `longTaskSupervisor`
    - 补齐 `ProjectRuntimeProfileRepository`
    - 补齐 `ProjectLongTaskStationDetailService`
    - `GenerateDraftUseCase` 测试装配已补齐
      - `hostPlatform`
      - `loadAvailableAgents`
      - `loadAvailableAgentGroups`
  - 输入区动作按钮布局回归已修复：
    - `ActionButton` 内层不再在收缩布局里使用 flex child
    - 解决了工作台挂载时的
      `RenderFlex children have non-zero flex but incoming width constraints are unbounded`
  - 资源面板分区组件的小型回归已清理：
    - `ResourcePanelSection` 的 trailing 渲染改为稳定的局部列表拼装
    - 清掉 analyzer 告警，避免 UI-12 留下噪音
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/widget_test.dart`
  - 通过
  - `flutter test`
  - 通过
- 本轮结论：
  - 前面几轮 UI 重构后的 Flutter 端挂载、主题切换、资源区与工作台主链已完成一轮集中回归
  - 当前 `apps/novel_agent_app` 已达到可以继续进入下一阶段前端实现或 Windows 打包验证的状态
- 后续扩展点：
  - `ActionButton` 现在已适配收缩布局，但如果后续要做更复杂的“图标 + 双行文案 + 角标”按钮，应优先新增专用按钮组件，而不是继续给 `ActionButton` 叠特殊布局
  - `widget_test` 现在是“真实装配可挂载”基线，后续若继续扩根控制器依赖，优先考虑抽测试装配 builder，避免测试文件再次膨胀
  - `UI-12` 本轮只做回归修整，没有开启新的 UI 主线；后续应回到新的会话顺序文档继续推进剩余实现项

## 0. 文档目的

这份文档只负责接下来的前端实现顺序。

它承接：

- `agent.md`
- `docs/ui-absorption-analysis-2026-05-26.md`
- `docs/remaining-implementation-session-order.md`

目标不是写抽象愿景，而是把后续 UI / 前端改造拆成：

- 一次会话内可完成
- 单轮改动量大致控制在 `500 ~ 2000` 行
- 每轮尽量只处理一件事或一类紧密相关的事
- 每轮都附可直接复制的执行提示词
- 每轮都明确“要做什么 / 不要做什么 / 重点拆哪里”

---

## 1. 适用范围

本文件覆盖以下前端主题：

1. 工作台视觉与结构统一
2. 会话栏的显示、滚动、工具调用、选项卡与输入区重构
3. 窄屏单列模式与可抽拉功能栏
4. 桌面三栏风格统一与分栏结构整理
5. 资源工作区与资源渲染器接线
6. 主题体系正式抽象
7. 长任务工作台 / 总站的前端闭环
8. 项目创建与无项目状态的前端闭环
9. 最终联调、探针、Windows 打包前回归

本文件不负责：

- 新增底层 provider 协议
- 新增核心写作策略
- 重做项目存储方案
- 改写现有 core / adapter 已稳定的合同

如果某轮前端实现暴露的是底层真实 bug，可以顺手修边界层，但不能顺势开启新的主线。

---

## 2. 全局硬约束

后续每一轮前端实现都必须继续遵守：

- 单一职责
- 单文件不要过重
- 复用优先
- 组合优先于堆条件分支
- UI 状态与业务状态分离
- Flutter 壳不偷吃 core / adapter 业务规则
- 视觉统一必须建立在组件合同统一之上，而不是靠页面内零散微调

### 2.1 文件与职责约束

- 单文件超过 `400` 行必须自检
- 单文件接近 `700` 行必须拆分
- 不允许继续把新职责塞回：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - 已经过重的工作台 page / controller / sidebar 文件

优先拆分方向：

- 页面壳
- 布局策略
- 视图模型
- 小型状态控制器
- 纯样式 / token / surface helper
- 面向单一区域的 widget 组

### 2.2 图片吸收边界

允许参考：

- `references/assets/ai_images_052601/主工作台：窄屏单列模式.png`
- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
- `references/assets/ai_images_052601/资产中心.png`

但必须遵守：

- 只能吸收合理理念
- 不能照搬整体结构、具体排版、具体装饰
- 不能让项目变成“半旧方案 + 半图片方案”的拼贴
- 一切吸收都要先服从我们自己的信息架构和现有三栏 / 卷轴主视图基线

### 2.3 UI 实现约束

所有实现都要优先保证：

1. 可滚动性正确
2. 功能入口不消失
3. 信息层级清楚
4. 工具调用不压住正文阅读
5. 单列 / 双列 / 三列切换逻辑不写死在单个 widget 里
6. 深浅主题切换不是“局部变黑”，而是完整 token 切换

### 2.4 注释约束

新引入的复杂状态转换、布局决策和主题解析逻辑，保留简短中文注释。

## 2.5 已吸收的总体要求清单

本文件不是只吸收“主题”这一项。

它已经把 `docs/ui-absorption-analysis-2026-05-26.md` 和本轮之前你明确提出的总体要求，一并视为正式约束。

后续执行时必须同时满足下面这些要求：

1. 前端也必须解耦，不能因为是 UI 就默认允许堆大文件
2. 单一类、单一 widget、单一 controller 尽量职责近似
3. 会话栏、资源栏、正文栏、长任务栏的职责边界要清楚
4. 允许参考吸收图片，但只能吸收合理理念，不能整图照搬
5. 风格必须统一，不能一半旧样式、一半新样式
6. 会话卷轴模式、三栏模式、文件夹栏是稳定基线，其它可以重构
7. 窄屏、双栏、三栏等布局策略不能写死在单个页面里
8. 输入区、模型条、工具调用、选项区、资源渲染都应有独立合同或至少独立子层
9. 所有任务都优先复用已有结构，不凭空制造新的万能中心
10. 主题只是其中一个子系统，不能让“主题改造”挤占掉会话交互、布局模式、资源工作区这些同样重要的主线

换句话说：

- `docs/ui-absorption-analysis-2026-05-26.md` 是吸收边界和问题定义
- 本文件是执行顺序和拆任务方式

两者后续必须一起看，不能只看其一。

---

## 3. 主题体系的正式设计决策

## 3.1 不采用“纯策略模式主题”

主题不是一个“运行流程策略”问题。

如果把主题做成纯策略模式，后面很容易出现：

- 一个主题类包办颜色、间距、边框、阴影、组件特例
- 每新增一种主题就复制一整套分支
- 用户自定义主题很难局部覆写

所以主题这里不建议走“单一 ThemeStrategy 接口 + 多个实现类”的重策略路线。

## 3.2 推荐方案：`ThemeDescriptor + ThemeTokenSet + ThemeRegistry + ThemeResolver`

前端主题体系建议正式采用：

1. `ThemeDescriptor`
   - 定义主题身份、显示名、类别、是否内置、可否编辑
2. `ThemeTokenSet`
   - 只承载 token
   - 如颜色、描边、分隔线、面板表面、强调色、危险色、选中态、文字层级、圆角级别、阴影级别、间距档位
3. `ThemeRegistry`
   - 维护内置主题与未来自定义主题的注册表
4. `ThemeResolver`
   - 负责把 token 解析成 Flutter `ThemeData`、组件 surface spec、会话条目 spec、分栏 spec 等
5. `ThemePreferenceStore`
   - 只负责持久化当前选择，不负责算样式

## 3.3 为什么这套更适合本项目

因为它同时满足：

- 当前只有 `明亮 / 偏暗` 两个内置主题
- 未来可能继续增加更多官方主题
- 未来可能开放用户自定义主题
- 某些组件可基于同一 token 集得到不同外观
- 不会把所有组件差异硬写成 theme if/else

也就是说：

- 主题扩展靠注册
- 样式落地靠解析
- 组件消费的是稳定 token / spec

这比“页面里判断深色浅色”或者“ThemeStrategy 大类包打一切”更稳。

## 3.4 主题层级建议

建议至少分成四层：

1. `core tokens`
   - 颜色、间距、圆角、线宽、字号层级
2. `surface specs`
   - 面板、列表项、输入区、工具行、选项卡、标签条、分隔线
3. `feature specs`
   - 会话条目、资源树、长任务状态条、项目创建卡片
4. `flutter theme bridge`
   - 把上面这些喂给 Material / 自定义 widget

---

## 4. 前端会话顺序总览

建议按下面顺序推进：

1. Session UI-01：主题 token 基座与共享 surface spec
2. Session UI-02：会话栏消息条目拆分与滚动稳定化
3. Session UI-03：工具调用行与选项卡折叠体系
4. Session UI-04：输入区、模型条、停止按钮、附件壳重构
5. Session UI-05：窄屏单列抽拉功能栏与入口保活
6. Session UI-06：桌面三栏风格统一与分栏结构收束
7. Session UI-07：资源树与文档工作区样式收束
8. Session UI-08：资源渲染器合同与首批 renderer 接线
9. Session UI-09：长任务工作台 / 总站操作闭环
10. Session UI-10：项目创建与无有效项目拦截前端闭环
11. Session UI-11：主题设置页与主题注册表前端闭环
12. Session UI-12：联调回归、探针、打包前修整

---

## 5. Session UI-01：主题 token 基座与共享 surface spec

### 本轮目标

把当前零散的主题 / 面板 / 分割线 / 表面色收束成正式 token 与 spec 基座，为后续所有 UI 改造先打地基。

### 预计改动量

- 约 `700 ~ 1600` 行

### 重点触达层

- `app/theme/`
- `shared/theme/`
- 少量共享 widget 外观接线

### 必做项

1. 建立 `ThemeDescriptor / ThemeTokenSet / ThemeRegistry / ThemeResolver` 基础结构
2. 建立至少以下共享 surface spec：
   - panel
   - sidebar
   - input dock
   - conversation entry
   - tool row
   - option tile
   - splitter
3. 把现有明亮 / 偏暗主题接入新体系
4. 让工作台至少开始消费统一的分隔线、背景层级、面板表面 token

### 本轮不要做

- 不做主题设置页
- 不做用户自定义主题编辑器
- 不顺手重构全部工作台布局

### 解耦重点

- token、resolver、registry、preference storage 分文件
- 不把所有 spec 塞进单一 theme 文件
- widget 只吃 spec，不自己拼大段颜色逻辑

### 完成判定

- 明亮 / 偏暗主题能通过同一注册表切换
- 工作台基础表面色、分隔线、边框层级开始统一
- 后续会话条目 / 输入区 / 资源树可以直接消费 spec

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-01` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`、`docs/remaining-implementation-session-order.md`。把 Flutter 端主题体系正式收束成 `ThemeDescriptor + ThemeTokenSet + ThemeRegistry + ThemeResolver`，并补齐共享 surface spec。只动主题基座与少量共享接线，不做主题设置页，不做大面积页面改版。注意单一职责、不要让主题文件过重、不要把组件特例硬塞进 theme resolver。

---

## 6. Session UI-02：会话栏消息条目拆分与滚动稳定化

### 本轮目标

解决“工具调用顶掉出字框”“超出后无法正常下滑”“消息内容区结构混乱”这类最影响可用性的基础问题。

### 预计改动量

- 约 `800 ~ 1800` 行

### 重点触达层

- `features/workbench/presentation/widgets/conversation_*`
- 相关 timeline / entry / scroll state 组件

### 必做项

1. 把会话条目拆成独立类型化 widget：
   - 普通用户消息
   - 智能体输出
   - 思考摘要 / 展开体
   - 工具调用区域
   - 选项区域
2. 修复滚动容器层级，让消息流、工具区、选项区不会互相抢占滚动
3. 保证流式输出时正文区域持续可见，不被工具状态条挤掉
4. 让思考内容默认折叠为简短摘要，但可在会话内展开

### 本轮不要做

- 不做输入区重构
- 不做模型选择区迁移
- 不做窄屏抽拉栏

### 解耦重点

- timeline 负责排列，不负责具体条目样式
- 各类 entry widget 分开
- 滚动行为不要继续写在大 sidebar 中

### 完成判定

- 流式输出时用户能持续阅读
- 工具条不会顶掉正文显示区
- 超出内容后能自然上下滚动
- 思考与输出视觉层次清楚

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-02` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只处理会话栏条目拆分与滚动稳定化：把用户消息、智能体输出、思考摘要、工具调用、选项区拆成独立 widget，并修复滚动容器层级，保证流式输出时正文持续可见。不要顺手做输入区、模型条、窄屏布局。注意不要再把职责塞回一个大 sidebar 文件。

---

## 7. Session UI-03：工具调用行与选项卡折叠体系

### 本轮目标

把工具调用与选项呈现从“能显示”推进到“可读、可收起、不会过大、状态清楚”。

### 预计改动量

- 约 `700 ~ 1500` 行

### 重点触达层

- 会话条目子组件
- tool projection / option projection 对应的前端展示层

### 必做项

1. 工具调用一行化、轻量化、竖直堆叠化
2. 支持工具完成状态、失败状态、运行中状态的轻量展示
3. 增加“是否显示工具调用细节”的会话级显示状态
4. 选项区改成支持折叠 / 展开细节的统一卡片
5. 折叠态下选项卡高度、间距、标题区统一
6. 如果工具是多次读不同文件，前端可展示目标差异信息

### 本轮不要做

- 不做真实工具链修复
- 不做输入区与发送按钮
- 不做主题设置页

### 解耦重点

- 工具行样式与数据映射分开
- 选项显示状态独立成小状态对象，不散落多个 widget bool

### 完成判定

- 工具调用不会再显得像大卡片把正文挤碎
- 用户能一眼看见工具做了什么、是否成功
- 选项区默认更紧凑，可展开看细节

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-03` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只处理工具调用行与选项卡折叠体系：把工具调用压缩成一行式轻量条目，支持完成/失败/运行中状态，加入工具细节显示开关，并把选项区改成统一的可折叠卡片。不要顺手修底层工具链，不要做输入区重构。注意前端状态单独抽出，不要在多个 widget 内 scattered bool。

---

## 8. Session UI-04：输入区、模型条、停止按钮、附件壳重构

### 本轮目标

把会话输入区整理成一个正式的 `input dock`，并把模型选择、智能体选择、深度思考、发送 / 停止、桌面附件入口摆到正确层级。

### 预计改动量

- 约 `900 ~ 1900` 行

### 重点触达层

- composer / selector / input dock 相关 widget
- 少量 capability state

### 必做项

1. 模型与智能体选择区移到输入区相邻的独立条带
2. 输入框内部右下放发送按钮
3. 发送中切换成停止按钮
4. 深度思考开关放到输入区相关区域，按能力显示
5. 桌面端显示附件入口，移动端不显示
6. 附件能力先做 UI 壳与 host capability 判定，不急着做完整传输
7. 修正单列模式下功能入口消失时输入区挤压的问题

### 本轮不要做

- 不做真实停止全链路，如果底层取消口还不完整，只先把前端合同接清楚
- 不做窄屏抽拉栏完整布局
- 不做资源工作区

### 解耦重点

- `conversation_model_strip`
- `conversation_input_dock`
- `conversation_action_buttons`
- `conversation_capability_state`

分文件拆开，不把这些重新塞进一个 composer 大文件。

### 完成判定

- 输入区在桌面与窄屏都不会互相压扁
- 模型 / 智能体选择可正常显示与操作
- 发送中按钮状态正确变化
- 桌面附件入口可见，移动端不显示

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-04` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只重构会话输入区与模型条：建立正式 input dock，把模型/智能体选择放到输入区相邻条带，发送按钮放进输入区内部右下，发送中变停止按钮，深度思考按能力显示，桌面端显示附件入口、移动端隐藏。不要顺手做资源区或完整窄屏布局。注意 capability state、action button、selector、composer 分文件。

---

## 9. Session UI-05：窄屏单列抽拉功能栏与入口保活

### 本轮目标

把窄屏单列模式正式改成“主会话 + 可抽拉功能栏”，保证单列模式下功能入口不消失。

### 预计改动量

- 约 `800 ~ 1700` 行

### 重点触达层

- workbench compact layout
- compact drawer / rail controller
- 入口按钮排布

### 必做项

1. 建立单列模式正式布局壳
2. 左下或合适位置提供可抽拉 / 缩回的功能栏入口
3. 会话卷轴继续是单列主视图
4. 在抽拉态里保留目录、会话、资产等关键入口
5. 解决单列模式中按钮消失、被压扁、不可点击的问题

### 本轮不要做

- 不做桌面三栏大改
- 不做资源渲染器
- 不做项目创建流程

### 解耦重点

- 抽拉栏控制器独立
- 紧凑布局策略独立
- 功能入口集合组件独立

### 完成判定

- 单列模式不再丢失功能入口
- 抽拉栏可以稳定展开 / 收回
- 会话仍然保持为主视图

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-05` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只处理窄屏单列模式：把它重构为“主会话 + 可抽拉功能栏”，保证目录、会话、资产等入口不会消失，并修复按钮被压扁或不可点的问题。不要顺手改桌面三栏，不要碰资源 renderer。注意抽拉控制器、紧凑布局策略、入口组件分开。

---

## 10. Session UI-06：桌面三栏风格统一与分栏结构收束

### 本轮目标

把桌面三栏模式从“卡片间加竖线”收束成更接近编辑器工作台的稳定分栏风格，但不照搬外部界面。

### 预计改动量

- 约 `700 ~ 1600` 行

### 重点触达层

- workbench desktop layout
- splitter / pane surface / sidebar shell

### 必做项

1. 统一三栏背景层级、面板表面、边界线与分栏感
2. 清理模糊轮廓和不必要的卡片感
3. 让分栏视觉更像稳定工作区，而不是多个浮卡
4. 确保横向三栏主结构保持清晰
5. 为后续布局策略变更保留策略入口，不写死比例和样式

### 本轮不要做

- 不做资源渲染器
- 不做长任务总站联动
- 不做主题设置页

### 解耦重点

- 分栏 surface spec 与布局策略分开
- sidebar / document / conversation 的面板壳分开

### 完成判定

- 桌面三栏视觉统一
- 分栏边界清楚但不生硬
- 后续如果布局策略再变，不需要大改单个页面文件

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-06` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只做桌面三栏风格统一与分栏结构收束：把工作台从卡片感收回到稳定编辑器式分栏，统一背景层级、面板表面、边界线与分隔感，但不要照搬参考图。不要做资源渲染器，不要碰长任务总站。注意把分栏 surface spec 和布局策略拆开。

---

## 11. Session UI-07：资源树与文档工作区样式收束

### 本轮目标

把左侧资源树和中间文档工作区先做成统一、可用、可扩的壳，为后续资源 renderer 铺路。

### 预计改动量

- 约 `700 ~ 1500` 行

### 重点触达层

- resource tree
- document workspace shell
- resource toolbar / display mode shell

### 必做项

1. 统一资源树行高、展开态、选中态、计数展示
2. 处理左栏过小导致元素消失的问题
3. 文档工作区表面、工具条、标签区与工作台风格统一
4. 为“资源按类型渲染”预留稳定显示模式壳
5. 明确当前打开文档、渲染视图、源码视图等基础入口结构

### 本轮不要做

- 不做首个 renderer 注册体系
- 不做完整资产中心新功能
- 不做长任务特化

### 解耦重点

- resource tree item
- resource tree section
- workspace surface
- display mode selector shell

分开实现，不把资源树所有逻辑继续塞一个文件。

### 完成判定

- 左栏缩小时仍保持基本可用
- 资源树与文档工作区风格统一
- 文档区具备承接多类型 renderer 的壳

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-07` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只处理资源树与文档工作区样式收束：统一左栏资源树的行高、展开态、计数与选中态，修复左栏缩小时元素消失的问题，并整理中间工作区的表面、标签与工具条，为后续多类型资源渲染预留显示模式壳。不要现在就做 renderer 注册体系。

---

## 12. Session UI-08：资源渲染器合同与首批 renderer 接线

### 本轮目标

把“中间栏不仅能看 markdown”正式推进成资源渲染合同，而不是继续在工作区里堆 if/else。

### 预计改动量

- 约 `900 ~ 1900` 行

### 重点触达层

- resource renderer contract
- registry
- workspace resolver
- 首批 renderer widget

### 必做项

1. 建立资源渲染器合同与注册表
2. 默认按资源类型智能适配 renderer
3. 同时保留显示模式手动切换入口
4. 首批至少接通：
   - markdown 渲染
   - 纯文本渲染
   - 结构化只读视图占位
5. 工作区通过 registry 选 renderer，而不是页面内类型分支

### 本轮不要做

- 不做所有资源类型
- 不做复杂可视化图谱
- 不做资产中心整页重做

### 解耦重点

- renderer contract、registry、resolver、具体 renderer 分离
- 页面只发起请求，不直接判断全部类型

### 完成判定

- 中间工作区已经是“资源工作区”而不只是 markdown 面板
- 新增 renderer 时不需要改大页面逻辑

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-08` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`。把中间栏正式收束成资源渲染器体系：建立 renderer contract、registry、resolver 和首批 markdown / 纯文本 / 结构化只读 renderer，默认智能适配并保留手动显示模式切换。不要顺手做图谱和复杂资产中心。注意不要在 workspace page 内堆类型分支。

---

## 13. Session UI-09：长任务工作台 / 总站操作闭环

### 本轮目标

把已落地的长任务 core / registry / supervisor 进一步接成用户真能操作的前端链。

### 预计改动量

- 约 `700 ~ 1600` 行

### 重点触达层

- long_task_station 子域
- workbench 中与长任务运行态相关的入口

### 必做项

1. 长任务实例列表显示状态、所属项目、运行基准、最近活动时间
2. 暂停 / 恢复 / 停止 / 打开所属项目入口
3. 工作台内能看到当前项目相关长任务的运行态摘要
4. 错误后可见重试 / 手动处理入口壳
5. 不把这些状态重新堆进 `app_shell_controller`

### 本轮不要做

- 不做长任务新策略
- 不做复杂统计图表
- 不做后台自动恢复策略改造

### 解耦重点

- station controller
- run list item
- run action bar
- project-level summary strip

### 完成判定

- 用户能在前端查看和控制全局长任务
- 工作台和总站之间职责清楚

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-09` 执行。先阅读 `agent.md`、`docs/remaining-implementation-session-order.md` 中长任务相关完成记录。只把长任务总站与工作台联动做成前端可操作闭环：显示实例列表、状态、运行基准、最近活动时间，并提供暂停/恢复/停止/打开所属项目入口，同时在工作台内给出当前项目相关长任务摘要。不要扩展新策略，不要把逻辑堆回 app_shell_controller。

---

## 14. Session UI-10：项目创建与无有效项目拦截前端闭环

### 本轮目标

把“无有效项目必须先创建或打开已有项目”的前端流程做扎实，并把三段式创建链真正体现在 UI 上。

### 预计改动量

- 约 `800 ~ 1700` 行

### 重点触达层

- project creation flow
- no-project guard page / shell
- desktop open-existing flow shell

### 必做项

1. 无有效项目时，阻止直接进入工作台
2. 提供两个主入口：
   - 创建新项目
   - 打开已有项目
3. 桌面端打开已有项目时走路径选择
4. 移动端不提供打开已有项目入口
5. 创建新项目体现三段式领域流程：
   - 项目类型
   - 主存储策略
   - 长任务运行基准预留
6. 项目类型铺开展示，不做下拉

### 本轮不要做

- 不做最终视觉精修
- 不做新的项目类型策略实现
- 不做项目导入导出整页

### 解耦重点

- creation step view model
- no-project guard shell
- desktop host picker bridge

### 完成判定

- 没有有效项目时用户不能“空进工作台”
- 创建 / 打开已有项目路径清楚
- 三段式创建链在 UI 上可见

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-10` 执行。先阅读 `agent.md`、`docs/major-redesign-session-order.md` 中项目创建相关 session 完成内容。只处理项目创建与无有效项目拦截前端闭环：无项目时必须先创建或打开已有项目，桌面端提供路径选择打开已有项目，移动端不提供该入口；创建流程正式体现“项目类型 + 主存储策略 + 长任务运行基准预留”的三段式。不要顺手做新项目类型策略实现。

---

## 15. Session UI-11：主题设置页与主题注册表前端闭环

### 本轮目标

把 Session UI-01 建好的主题基座真正接到设置页，并为未来内置更多主题与用户自定义主题预留入口。

### 预计改动量

- 约 `600 ~ 1400` 行

### 重点触达层

- settings/theme
- theme preference view model

### 必做项

1. 设置页消费 `ThemeRegistry`
2. 显示当前内置主题列表与当前选中项
3. 清楚区分：
   - 内置主题
   - 未来可扩展主题
   - 预留的自定义主题入口壳
4. 切换主题后工作台各核心表面同步变化
5. 不再出现“只有发送框变黑”的半切换现象

### 本轮不要做

- 不做完整自定义主题编辑器
- 不做主题导入导出
- 不做复杂主题预览市场

### 解耦重点

- settings page
- theme selection list
- theme preference state

### 完成判定

- 用户可以正式切换内置主题
- 整个工作台而不是局部控件发生一致变化
- 未来加主题不需要重写设置页逻辑

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-11` 执行。先阅读 `agent.md`、`docs/ui-implementation-session-order.md` 的 `Session UI-01`。把主题基座正式接到设置页：消费 ThemeRegistry，显示当前内置主题列表和选中项，切换后让工作台核心表面整体同步变化，并预留未来自定义主题入口壳。不要做完整主题编辑器，不要做导入导出。注意设置页、选择列表、偏好状态分离。

---

## 16. Session UI-12：联调回归、探针、打包前修整

### 本轮目标

对前面前端链路做一次集中联调，只修真实暴露的问题，不再扩主线。

### 预计改动量

- 约 `500 ~ 1200` 行

### 重点触达层

- 已改过的 workbench / long_task_station / project_creation / theme settings
- 探针与回归脚本

### 必做项

1. 回归单列 / 双列 / 三列布局切换
2. 回归主题切换
3. 回归流式输出、工具调用、选项卡、停止按钮、附件入口
4. 回归无项目拦截与创建流程
5. 回归资源渲染切换
6. 回填文档和验证结果
7. 为 Windows 打包前清掉明显 UI 缺口

### 本轮不要做

- 不再扩功能
- 不再启动新的大规模 UI 改造

### 解耦重点

- 修问题以局部收束为主
- 不允许“为修一个 bug 再造新中心文件”

### 完成判定

- 主要前端闭环可用
- 文档有回填
- 可以进入 Windows 打包测试

### 执行提示词

按 `docs/ui-implementation-session-order.md` 的 `Session UI-12` 执行。先阅读本文件前面各 session 和 `docs/remaining-implementation-session-order.md`。只做前端联调回归：回归单列/双列/三列、主题切换、流式输出、工具调用、选项卡、停止按钮、附件入口、无项目拦截、项目创建、资源渲染，并回填文档与验证结果。不要再扩新功能，不要为了修小问题造新的大中心文件。

---

## 17. 执行规则

后续按本文件推进时，默认遵循以下规则：

1. 一次会话只完成一个 session
2. 如果上轮停在半截或暴露强关联回归，先补完，不开启下一轮
3. 每轮开始前至少复读：
   - `agent.md`
   - 本文件对应 session
   - 该 session 指向的相关设计文档
4. 每轮结束时都要说明：
   - 本轮完成了什么
   - 哪些文件是后续扩展点
   - 是否有未闭环但被明确延期的点

---

## 18. 当前推荐起点

从当前状态看，最自然的下一步是：

1. `Session UI-12`

原因：

- 项目入口与主题切换两条前端主链都已经闭环
- 现在最适合做一轮只修真实联调问题的回归
- `UI-12` 完成后就可以更安心地进入 Windows 打包测试
