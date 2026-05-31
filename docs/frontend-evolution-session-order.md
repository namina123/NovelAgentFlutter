# NovelAgentFlutter 前端演化会话顺序文档

最后更新：2026-05-27

## 0.12 Session FE-12 完成记录

- 已完成 `Session FE-12：前端总回归与性能探针`
- 本轮回归范围：
  - 会话流式更新与合帧：
    - `conversation_progress_coalescer`
    - `conversation_streaming_state`
    - `conversation_timeline_auto_reveal`
  - 会话语义块与附加区：
    - 工具块
    - pending input preview
    - 子智能体预览与详情路由
  - 主题颜色与控件风格双体系：
    - `app_theme_control_style`
    - `theme_settings`
  - 工作台桌面 / 窄屏结构：
    - `navigation sidebar`
    - `canvas workspace shell`
    - `desktop layout`
    - `compact workspace shell`
    - `compact scaffold`
    - `conversation input dock`
- 本轮真实修复：
  - 清理 `apps/novel_agent_app/tool/gateway_connect_probe.dart`
    中的 analyzer 噪音：
    - 改用 `stdout.writeln`
    - 补齐 `dart:io` 导入
  - 没有借回归之名继续改主工作台结构，也没有新开功能主线
- 本轮真实性能 / 链路探针：
  - 已运行：
    - `dart run tool/real_long_task_probe.dart`
      in `apps/novel_agent_app`
  - 结果：
    - `PASS`
  - 探针报告：
    - `artifacts/real_long_task_probe_report.json`
  - 已确认：
    - 长任务规划 -> 样章 -> 第 02 章链路可真实跑通
    - `novel-control-station` 在规划与章节阶段都被真实加载
    - 角色卡 / 时间线 / 伏笔 / world / summary / continuity review 落盘正常
    - prompt 中章节字数目标约束存在
    - 工具重复读取统计已进入报告，可继续作为后续策略优化依据
- 本轮验证结果：
  - `dart analyze lib test tool`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/conversation_progress_coalescer_service_test.dart test/conversation_streaming_state_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_transcript_block_projection_service_test.dart test/conversation_transcript_lane_projection_service_test.dart test/conversation_pending_input_preview_service_test.dart test/conversation_sub_agent_detail_route_service_test.dart test/sub_agent_run_preview_projection_service_test.dart test/conversation_timeline_auto_reveal_policy_test.dart test/conversation_sidebar_test.dart test/app_theme_control_style_test.dart test/theme_settings_view_data_service_test.dart test/theme_settings_panel_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart test/workbench_page_desktop_layout_test.dart test/workbench_compact_workspace_shell_test.dart test/app_shell_compact_scaffold_test.dart test/conversation_input_dock_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 这一轮前端演化的主要结构与回归面已形成闭环
  - 会话块系统、流式节奏、子智能体详情流、桌面/窄屏第二代工作台、主题颜色与控件风格双体系，当前代码状态和文档状态一致
  - 在这轮回归中，没有再暴露出新的前端结构性阻塞问题
- 后续剩余风险：
  - 真实长任务探针这次验证的是共享运行链，不是 Flutter 页面上的可视化逐帧体感；如果后续要继续盯“回复时整页卡顿”的体感，还需要专门做一次带 UI 运行的性能录制
  - 工具重复读取虽然已有标记，但本轮只验证并留痕，没有继续改策略层
  - 到这里为止，`docs/frontend-evolution-session-order.md` 的既定会话已全部完成

## 0.11 Session FE-11 完成记录

- 已完成 `Session FE-11：窄屏端第二代工作台组合`
- 已落地：
  - 新增窄屏主视图合同：
    - `WorkbenchCompactPrimaryView`
  - 新增窄屏主视图同步策略：
    - `WorkbenchCompactPrimaryViewResolver`
  - 新增窄屏主视图切换条：
    - `WorkbenchCompactViewSwitcher`
  - 新增窄屏第二代工作台壳：
    - `WorkbenchCompactWorkspaceShell`
  - `WorkbenchSurfaceLayoutPolicy` 已新增：
    - `compactWorkbench`
  - 窄屏模式现在不再退化成“只能直接显示会话”
  - 窄屏主视图现在已正式收束为三类可切换入口：
    - `工作`
    - `正文`
    - `会话`
  - `工作` 视图已正式复用：
    - `WorkbenchNavigationSidebar`
  - `正文` 视图已正式复用：
    - `WorkbenchCanvasWorkspaceShell`
  - `会话` 视图继续复用：
    - `ConversationSidebar`
  - 窄屏下的正文可见状态与主视图切换已接回既有动作链：
    - `onDocumentsWorkspaceRequested`
    - `onDocumentsWorkspaceDismissRequested`
  - 紧凑壳层导航抽拉入口已收束成更正式的 host：
    - `AppShellCompactDrawerHost`
    - `AppShellCompactLauncherDock`
  - 常态下抽拉 launcher 现在停靠在壳层底部独立 dock，不再压在主内容上
  - 键盘弹出时，底部 dock 自动收口，只保留浮动 launcher，继续避免展开面板挡住输入链
  - 会话输入区已正式拆出独立文本输入壳：
    - `ConversationComposerTextField`
  - 输入框现已改成：
    - 固定高度
    - `expands: true`
    - 内部滚动
  - 窄屏风格继续复用桌面端 section / pane shell 语言，没有重新长出一套独立视觉体系
- 本轮验证结果：
  - `dart analyze lib test`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_compact_workspace_shell_test.dart test/app_shell_compact_scaffold_test.dart test/conversation_input_dock_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/workbench_compact_workspace_shell_test.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart test/workbench_page_desktop_layout_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 窄屏端现在已经有正式的“工作 / 正文 / 会话”主视图切换，不再把文档与工作面板藏成会话里的次级动作
  - 常态下抽拉入口不再压住主阅读区，窄屏视觉关系也比之前更清楚
  - 输入区自身滚动已经有独立壳承接，后续继续调输入区高度或节奏时不需要回改整个 composer dock
  - 这轮刻意没有继续微调桌面端，也没有扩大移动端附件能力
- 后续扩展点：
  - `WorkbenchCompactPrimaryViewResolver` 当前只处理“正文显隐驱动的最小同步”；后续如果窄屏还要接 focus mode 或更多主视图，只需继续扩这层
  - `WorkbenchCompactWorkspaceShell` 目前仍以本地状态承接主视图切换；后续如果需要把窄屏视图记忆持久化到项目级或会话级，再继续外提
  - `AppShellCompactDrawerHost` 现在先把 dock 与 overlay 关系理顺；后续如果还要进一步吸收参考图中的窄屏抽拉动画，应优先继续改 host，而不是再回改页面
  - 下一轮自然进入 `Session FE-12`

## 0.10 Session FE-10 完成记录

- 已完成 `Session FE-10：桌面端第二代工作台组合`
- 已落地：
  - 新增桌面 section 合同：
    - `WorkbenchDesktopSectionId`
    - `WorkbenchDesktopSectionSpec`
  - 新增桌面 section spec resolver：
    - `WorkbenchDesktopSectionSpecResolver`
  - `WorkbenchPaneShell` 已不再只吃 `surfaceRole`
  - 桌面三栏现已按正式 section 语义接线：
    - `navigation`
    - `primaryCanvas`
    - `collaboration`
  - `WorkbenchDesktopSurface` 已升级为更正式的 surface composition：
    - 外层统一 frame
    - 裁切后的整体圆角
    - 更克制的顶部背景层级
  - `WorkbenchDesktopStyle` 已扩成更完整的桌面组合样式基座：
    - `surfaceRadius`
    - `sectionRadius`
    - `surfaceOverlayColor`
    - navigation / canvas / collaboration / auxiliary section colors
    - divider track / handle colors
  - `PaneResizeDivider` 已改成消费桌面样式，而不是直接读取原始 splitter surface
  - `WorkbenchAuxiliaryPanelHost` 已正式对齐桌面 section 语言，不再沿用通用 panel 壳默认外观
  - `DocumentWorkspaceHeaderPanel` 已切到新的 canvas section 节奏，避免继续引用旧的 panel band 常量
  - `WorkbenchPage` 与桌面布局测试均已切到 section id 语义接线
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart test/document_workspace_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/resource_manager_panel_test.dart test/workbench_page_desktop_layout_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 桌面端整体区块语言已经明显更统一，导航层、主画布、协作区、辅助工作层不再像几套独立风格硬拼在一起
  - 这轮吸收了参考图的克制、安静、专业感，但没有照搬其布局结构
  - 后续如果继续调栏宽、位置或 section 语言，优先只需改 desktop style / section spec / composition 壳，而不必回头拆业务组件
  - 这轮刻意没有进入窄屏模式，也没有扩任何新业务能力
- 后续扩展点：
  - `WorkbenchDesktopSectionSpecResolver` 当前先服务三栏主 section；后续如果桌面端再出现更多正式区块，可以继续在这层扩展，而不必回改 pane shell
  - `WorkbenchPaneLayoutPolicy` 仍然是栏宽策略主入口；后续如果需要更细的桌面预设，只需在这层继续细化宽度策略
  - `WorkbenchDesktopSurface` 现在已经是正式组合层，后续若继续吸收参考图的背景节奏，也应优先落在这里，而不是散落到各个 pane 内部
  - 下一轮自然进入 `Session FE-11`

## 0.9 Session FE-09 完成记录

- 已完成 `Session FE-09：主画布壳与 renderer host 深化`
- 已落地：
  - 新增主画布 request factory：
    - `DocumentResourceRenderRequestFactoryService`
  - 新增正式 renderer host：
    - `DocumentResourceCanvasHost`
  - 新增正式 primary canvas host：
    - `WorkbenchPrimaryCanvasHost`
  - `DocumentWorkspacePanel` 已从“自己同时持有状态切换 + request 组装 + renderer registry + resolver”收缩成薄壳入口
  - 主画布当前已正式拆成：
    - `primary canvas host`
    - `renderer host`
    - `auxiliary child layer`
  - 新增 preview-like 资源渲染器：
    - `DocumentPreviewResourceRenderer`
    - `DocumentPreviewCanvas`
  - `DocumentResourceRendererResolver` 已新增：
    - `previewRendererId`
  - 当前已正式收束的 renderer 入口：
    - `empty`
    - `plain_text`
    - `markdown`
    - `structured`
    - `preview_like`
  - preview-like 资源当前已覆盖：
    - `png`
    - `jpg`
    - `jpeg`
    - `gif`
    - `webp`
    - `bmp`
    - `svg`
    - `pdf`
    - `db`
    - `sqlite`
  - `WorkbenchCanvasWorkspaceShell` 已正式消费 `WorkbenchPrimaryCanvasHost`
  - 主画布与辅助工作层的父子关系现在由 `canvas workspace shell -> primary canvas host + auxiliary host` 稳定承接
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/document_resource_renderer_resolver_test.dart test/document_workspace_panel_test.dart test/workbench_canvas_workspace_shell_test.dart test/workbench_page_desktop_layout_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_navigation_sidebar_test.dart test/resource_manager_panel_test.dart test/document_workspace_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 中间区现在已经更接近正式主画布，而不再只是“正文编辑器 + 页面内若干 if/else”
  - markdown / plain text / structured / preview-like 资源入口已经统一收敛到 renderer host，不需要再改大页面逻辑
  - 辅助工作层与主画布的父子关系已经明确，后续继续接 richer preview / rewrite / analysis 时不需要回改工作台主页面
  - 这轮刻意没有去做图谱完整 UI，也没有触碰底层存储策略
- 后续扩展点：
  - `preview_like` 当前先提供稳定入口和只读预览占位，后续如果要接图片、PDF 或数据库的真实预览能力，可以继续在该 renderer 家族内扩展
  - `DocumentResourceRenderRequestFactoryService` 现在还是主画布 request 的单一装配口，后续接更多资源元信息时可以继续扩进去，而不必回改 host
  - 如果后续把工作台进一步拆成 `workspace_canvas` 独立子域，`WorkbenchPrimaryCanvasHost` 可以直接成为该子域壳的起点
  - 下一轮自然进入 `Session FE-10`

## 0.8 Session FE-08 完成记录

- 已完成 `Session FE-08：导航层与辅助工作层壳`
- 已落地：
  - 新增工作台导航层合同：
    - `WorkbenchNavigationPanelId`
  - 新增辅助工作层合同：
    - `WorkbenchAuxiliaryPanelId`
  - 新增工作台壳聚合 view data：
    - `WorkbenchWorkspaceShellViewData`
  - 新增壳聚合投影服务：
    - `WorkbenchWorkspaceShellViewDataService`
  - 新增左侧活动轨：
    - `WorkbenchActivityRail`
  - 新增单面板 side panel host：
    - `WorkbenchSidePanelHost`
  - 新增导航层宿主：
    - `WorkbenchNavigationSidebar`
  - 左侧现在正式收束为：
    - `文件`
    - `工作`
    - `策略`
    - `上下文`
  - 同一时刻左侧只显示一个工作面板，不再把多个资源/策略信息直接堆开
  - 新增导航层面板族：
    - `WorkbenchWorkspaceOverviewPanel`
    - `WorkbenchPromptModesPanel`
    - `WorkbenchContextSelectionPanel`
  - 新增辅助工作层宿主：
    - `WorkbenchAuxiliaryPanelHost`
  - 新增正文区壳：
    - `WorkbenchCanvasWorkspaceShell`
  - 辅助工作层当前已正式有归属位的能力：
    - `提示预览`
    - `重写预览`
    - `审稿分析`
    - `上下文选择`
  - `DocumentWorkspaceActionHandler` 已通过轻量代理接回辅助层切换：
    - 点击 `审稿` 时，辅助工作层切到 `审稿分析`
    - 点击 `结构视图` 时，辅助工作层切到 `上下文选择`
  - `WorkbenchPage` 已正式改成：
    - 三栏 / 文档工作区模式下左侧资源栏接 `navigation sidebar`
    - 正文区接 `canvas workspace shell`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 工作台现在已经有正式的导航层和辅助工作层壳，不再只有“资源树 + 正文 + 会话”三块固定拼接
  - prompt preview / review analysis / context selection 已经开始脱离右侧会话栏，拥有更合理的归属位
  - 左侧已具备单面板切换能力，后续继续吸收更多项目能力时不必再把新内容硬塞进一个资源面板
  - 这轮刻意没有做最终桌面比例打磨，也没有扩张真实分析/重写业务
- 后续扩展点：
  - `WorkbenchWorkspaceShellViewDataService` 当前仍是轻量聚合投影；后续如果辅助层接入更真实的分析/重写对象，可以继续扩大它的聚合口径，而不必回改宿主布局
  - `WorkbenchAuxiliaryPanelHost` 现在先承接壳和归属位，后续 `FE-09` 可以继续把主画布与辅助工作层的父子关系收得更正式
  - 左侧导航层当前以 `files/workspace/prompts/context` 四类为主；后续如果再增加工作面板，也只需要补 activity item 和 panel host 分派
  - 下一轮自然进入 `Session FE-09`

## 0.7 Session FE-07 完成记录

- 已完成 `Session FE-07：子智能体预览卡与全屏详情流`
- 已落地：
  - 新增子智能体详情路由合同：
    - `ConversationSubAgentDetailRouteState`
  - 新增子智能体详情路由服务：
    - `ConversationSubAgentDetailRouteService`
  - `ConversationSidebar` 已不再把“当前选中的子智能体 id”硬塞成局部 if/else 结构
  - 子智能体详情切换现已走：
    - `detail route state`
    - `route sanitize`
    - `active run resolve`
  - 新增会话全屏宿主：
    - `ConversationFullscreenHost`
  - 子智能体详情页现在以会话区内正式全屏态呈现：
    - 可返回主会话
    - 不携带主输入框
    - 不和 composer/model strip 混排
  - 新增子智能体预览投影合同：
    - `SubAgentRunPreviewViewData`
    - `SubAgentRunPreviewTone`
  - 新增子智能体预览投影服务：
    - `SubAgentRunPreviewProjectionService`
  - `SubAgentActivityPanel` 已改成：
    - 先投影 preview view data
    - 再渲染 `SubAgentRunPreviewCard`
  - 子智能体预览卡现已正式区分：
    - 运行中摘要
    - 完成态摘要
    - 失败态摘要
  - 工具时间线已收敛：
    - `call_sub_agent` 原始工具回显不再重复刷进主时间线
    - 子智能体委派改由专属 preview/detail 流承接
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/conversation_sidebar_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_transcript_block_projection_service_test.dart test/conversation_transcript_lane_projection_service_test.dart test/conversation_sub_agent_detail_route_service_test.dart test/sub_agent_run_preview_projection_service_test.dart test/conversation_streaming_state_service_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 子智能体现在已经有稳定的时间线预览块与会话区内全屏详情流，不再只是底部一条协作活动
  - 主会话输入链与子智能体详情阅读链已正式分离，详情态不会误带 composer
  - 主时间线对子智能体的表达已从“原始工具回显 + 详情混搭”收束成“预览卡 + 点开后详情”
  - 这轮刻意没有改底层子智能体调度，也没有进入工作台大布局升级
- 后续扩展点：
  - 当前 `ConversationFullscreenHost` 仍是轻量切换宿主；后续如果会话区继续引入更多全屏态，可以继续复用，而不必回改 `ConversationSidebar`
  - `SubAgentRunPreviewProjectionService` 目前主要负责状态归一和摘要选择；后续如果运行记录字段更丰富，可以继续扩成更细粒度的阶段投影
  - 子智能体详情现在仍展示事件轨迹原文；后续若要再吸收 DeepSeek TUI 的 phase/event 分层，可以继续在 detail projection 下沉，而不必回改 preview card
  - 下一轮自然进入 `Session FE-08`

## 0.6 Session FE-06 完成记录

- 已完成 `Session FE-06：streaming cadence / appendix / pending preview`
- 已落地：
  - 新增 transcript lane 合同：
    - `ConversationTranscriptLaneViewData`
  - 新增 lane projection：
    - `ConversationTranscriptLaneProjectionService`
  - 会话块现已正式区分：
    - `stableHistoryBlocks`
    - `currentRoundToolBlocks`
    - `streamingAppendixBlocks`
    - `footerBlocks`
  - 规则收束：
    - 仅在 `isGenerating == true` 时，将尾部工具块提升为 `current round tool strip`
    - 生成结束后，尾部工具块回归稳定历史，不再长期占据高频流式区
  - 新增待发送输入 preview 合同：
    - `ConversationPendingInputPreviewViewData`
  - 新增待发送输入 preview presenter：
    - `ConversationPendingInputPreviewService`
  - 新增待发送输入 preview widget：
    - `ConversationPendingInputPreviewPanel`
  - `WorkbenchConversationViewData` 已新增正式字段：
    - `transcriptLanes`
  - `WorkbenchPaneViewDataMapperService` 已改成：
    - 先生成 `transcriptBlocks`
    - 再基于 `isGenerating` 投影 `transcriptLanes`
  - `ConversationTimeline` 已改成基于 lane 渲染：
    - 稳定历史逐块渲染
    - 本轮工具活动以 `ConversationCurrentRoundToolStrip` 成组渲染
    - streaming appendix 与 footer 独立落位
  - `ConversationTimelineSnapshot` 与 `ConversationTimelineAutoRevealPolicy` 已改成基于 lane 展平快照判断自动追随
  - `ConversationSidebar` 已接回正式的 pending input section：
    - 只在生成中显示
    - 由 composer 本地 `TextEditingController` 驱动 preview
    - 不把未发送输入回灌到 controller / core 状态
  - 已删除过时 widget：
    - `ConversationPendingSection`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/conversation_transcript_lane_projection_service_test.dart test/conversation_pending_input_preview_service_test.dart test/conversation_sidebar_test.dart test/conversation_timeline_auto_reveal_policy_test.dart test/conversation_transcript_block_projection_service_test.dart test/conversation_streaming_state_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_session_state_service_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 会话时间线已经从“单条扁平 block 流”继续收束为“稳定历史 + 本轮工具带 + streaming appendix + footer”的分层表达
  - 高频流式区域与稳定历史区已正式分开，AI 返回时不再需要整段历史跟着一起抖动
  - pending input preview 现在是正式区块，用户在生成中可以持续看到待发送输入，而不是只能盯着输入框
  - 这轮刻意没有进入子智能体全屏详情流，也没有进入桌面 / 窄屏布局二次升级
- 后续扩展点：
  - 当前 cadence 方案是在既有 coalescer 基础上，通过 lane 分层减少无意义重排；如果后续还要更细粒度节拍器，可以继续落在独立 cadence coordinator，而不必回改 timeline
  - `pendingInput` section 现在已是正式宿主，后续若要换位到别的会话位置，只需调整 section layout policy
  - 子智能体现在仍主要依赖预览块与既有详情入口；下一轮 `Session FE-07` 可以专门把“预览卡 -> 全屏详情流”补成正式闭环
  - 下一轮自然进入 `Session FE-07`

## 0.5 Session FE-05 完成记录

- 已完成 `Session FE-05：会话语义块合同与渲染注册表`
- 已落地：
  - 新增 transcript block 合同：
    - `TranscriptBlockKind`
    - `TranscriptBlockViewData`
    - `TranscriptMessageBlockViewData`
    - `TranscriptToolBlockViewData`
    - `TranscriptChoiceGroupBlockViewData`
    - `TranscriptRuntimeNoticeBlockViewData`
    - `TranscriptRetryBannerBlockViewData`
    - `TranscriptCheckpointCardBlockViewData`
    - `TranscriptSubAgentPreviewBlockViewData`
  - 新增 transcript block projection：
    - `ConversationTranscriptBlockProjectionService`
  - `WorkbenchPaneViewDataMapperService` 已在 conversation slice 映射时生成：
    - `transcriptBlocks`
  - `WorkbenchConversationViewData` 已新增正式字段：
    - `transcriptBlocks`
  - `ConversationTimeline` 已不再接收：
    - `entries + footer + isGenerating`
  - `ConversationTimeline` 现已只负责排列：
    - `List<TranscriptBlockViewData>`
  - 新增 block renderer registry：
    - `TranscriptBlockRendererRegistry`
    - `TranscriptBlockRenderContext`
  - 当前已正式接入的 block 类型：
    - `message.user`
    - `message.assistant.streaming`
    - `message.assistant.final`
    - `tool.compact`
    - `choice.group`
    - `runtime.notice`
    - `retry.banner`
    - `subagent.preview`
  - `checkpoint.card` 合同与基础 renderer 已立，但本轮没有正式业务投影来源
  - 会话 appendix 已从“timeline footer 特判”改成正式 block：
    - pending options
    - retry banner
    - sub-agent preview
  - `ConversationTimelineSnapshot` 与 `ConversationTimelineAutoRevealPolicy` 已改成基于 block 快照判断滚动追随
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `dart analyze apps/novel_agent_app/lib/features/workbench apps/novel_agent_app/test`
  - 通过
  - `flutter test test/conversation_transcript_block_projection_service_test.dart test/conversation_sidebar_test.dart test/conversation_timeline_auto_reveal_policy_test.dart test/conversation_streaming_state_service_test.dart test/conversation_tool_entry_projection_service_test.dart test/conversation_session_state_service_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 会话时间线已经从“弱结构 entry 列表 + footer 特判”升级为正式的 block 排列系统
  - timeline 主体不再理解 tool/choice/retry/sub-agent 的业务细节，新增块类型时不必继续改 timeline 主循环
  - 这轮刻意没有做 streaming cadence 分轨，也没有做子智能体全屏详情流
- 后续扩展点：
  - `TranscriptBlockRendererRegistry` 现在仍以 switch 分派为主；后续如果 block 家族继续扩张，可以继续收束成可注册 renderer 映射，而不必回改 timeline
  - `checkpoint.card` 目前只有合同和基础渲染，后续在真实 checkpoint workflow 接入时直接补 projection 即可
  - 当前 `pendingInput` section 已不再承载 retry/choice/sub-agent appendix；真正的“待发送输入 preview”仍留到 `Session FE-06`
  - 下一轮自然进入 `Session FE-06`

## 0.4 Session FE-04 完成记录

- 已完成 `Session FE-04：可重排布局槽位合同`
- 已落地：
  - 新增通用 section placement 合同：
    - `SectionPlacement`
  - 新增工作台 slot 合同：
    - `WorkbenchSlotId`
    - `WorkbenchSlotEntry`
    - `WorkbenchSlotLookup`
    - `WorkbenchSlotHost`
  - `WorkbenchPage` 已改成通过 `WorkbenchSlotHost` 组装 pane：
    - `resourcePane`
    - `canvasPane`
    - `conversationPane`
    - `overlayPane` 先保留为预留 slot id
  - 新增会话区 section / slot / layout 合同：
    - `ConversationSectionId`
    - `ConversationSectionSlot`
    - `ConversationSectionSlotSpec`
    - `ConversationSectionLayout`
    - `ConversationSectionLayoutPolicy`
  - 新增会话 section composition host：
    - `ConversationSectionEntry`
    - `ConversationSectionHost`
  - `ConversationSidebar` 已不再把头部、状态、主体、附加区、输入区、模型条写死在一个固定 `Column` 顺序中
  - 当前已进入可组合合同的 section：
    - `panelHeader`
    - `runtimeStatus`
    - `timeline`
    - `pendingInput`
    - `composer`
    - `modelStrip`
  - 当前已新增独立 section widget：
    - `ConversationPendingSection`
    - `ConversationComposerDockPanel`
  - `ConversationModelStrip` 已从“只能藏在 composer 组合里”变成正式独立 section，可由 layout 政策换位
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/conversation_sidebar_test.dart test/workbench_page_desktop_layout_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 会话区关键 section 已正式走 layout contract，而不是固定 widget 树
  - 后续如果要把模型条、输入区、状态带、pending 区换位，已经不需要重写整个 `ConversationSidebar`
  - 工作台顶层 pane 也已有正式 slot lookup，不再完全靠页面内部临时变量硬拼
  - 这轮刻意没有进入 transcript block 渲染，也没有做桌面三栏整体视觉改版
- 后续扩展点：
  - `ConversationSectionLayoutPolicy` 现在仍提供单套默认布局；后续可以按桌面/窄屏、focus mode、长任务协作态继续派生不同布局策略
  - 当前 `pendingInput` section 先承载 retry / pending option / sub-agent activity 这类 appendix；真正的待发送输入 preview 仍留到 `Session FE-06`
  - `WorkbenchSlotId.overlayPane` 已作为合同预留，后续如果 overlay 也进入正式 slot composition，可直接接入而不必改枚举语义
  - 下一轮自然进入 `Session FE-05`

## 0.3 Session FE-03 完成记录

- 已完成 `Session FE-03：颜色主题与控件风格双体系`
- 已落地：
  - 新增独立控件风格合同：
    - `ControlStyleDescriptor`
    - `ControlStyleTokenSet`
    - `ControlStyleRegistry`
    - `ControlStyleResolver`
  - 新增共享控件风格规格：
    - `PanelChromeSpec`
    - `ButtonChromeSpec`
    - `ToolbarChromeSpec`
    - `InputChromeSpec`
    - `ChipChromeSpec`
    - `CardChromeSpec`
  - `ThemeRegistry` 已从“颜色 + 控件几何 + surface”一体式注册，收缩成：
    - 只负责 `ThemeDescriptor + ThemeColorTokens`
  - `AppTheme` 已改成正式组合器：
    - 从 `ThemeRegistry` 读取颜色主题
    - 从 `ControlStyleRegistry` 读取控件风格
    - 通过 `ControlStyleResolver` 组合出最终 `ThemeTokenSet`
  - `ThemeTokenSet` 已改成同时承载：
    - `descriptor`
    - `colors`
    - `controlStyle`
    - `surfaces`
  - `NovelThemeContext` 已补齐控件风格访问口：
    - `novelControlStyleTokenSet`
    - `novelPanelChrome`
    - `novelButtonChrome`
    - `novelToolbarChrome`
    - `novelInputChrome`
    - `novelChipChrome`
    - `novelCardChrome`
  - 以下共享组件已切到“颜色 token + 控件风格 token”双消费：
    - `ActionButton`
    - `ToolbarIconButton`
    - `PanelSurface`
  - `ThemeResolver` 已改成从 `ControlStyleTokenSet` 驱动：
    - `cardTheme`
    - `inputDecorationTheme`
    - 输入边框 / 半径 / 内边距 / 最小高度
  - 当前内置控件风格已提供：
    - `builtin.linear`
    - `builtin.gentle`
    - 默认仍走 `builtin.linear`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/theme apps/novel_agent_app/lib/shared/theme apps/novel_agent_app/lib/shared/widgets apps/novel_agent_app/test/app_theme_control_style_test.dart`
  - 通过
  - `flutter test test/app_theme_control_style_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/widget_test.dart test/theme_settings_view_data_service_test.dart test/theme_settings_panel_test.dart test/conversation_sidebar_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 颜色主题与控件风格已经成为两套独立注册合同
  - 当前 app 即便仍只持有 `activeThemeId`，也已经具备“同色不同控件风格”组合能力
  - 这轮刻意没有进入主题设置页和大面积页面换皮，只把基座与共享消费链立正
- 后续扩展点：
  - `AppShellController` / 设置页后续可以正式新增 `activeControlStyleId`，直接复用当前 `ControlStyleRegistry`
  - 仍在使用 `AppChrome` 静态常量的旧组件，可在后续会话分批迁入 `NovelThemeContext` 的控件风格 token
  - 现在的 `ThemeSurfaceSpecSet` 已是“颜色语义 + 风格几何”的组合投影，后续如果继续做更细粒度的 component style adapter，可以在不回改页面代码的前提下继续下沉
  - 下一轮自然进入 `Session FE-04`

## 0.1 Session FE-01 完成记录

- 已完成 `Session FE-01：壳层监听边界拆分`
- 已落地：
  - 新增壳层细粒度监听基座：
    - `AppShellListenableState`
  - `NovelAgentApp` 已改成：
    - 只监听 `activeThemeIdListenable`
    - 不再因为工作台局部变化重建整棵 `MaterialApp`
  - `AppShell` 已改成：
    - 只监听 `destinationListenable`
    - 不再直接 `AnimatedBuilder(animation: controller, ...)`
  - `AppRouter` 已改成：
    - `Workbench / Settings / AgentEcosystem / ProjectCollection / TaskCenter / ReviewCenter / PromptTemplates`
      都通过各自 page-scope `ValueListenable` 渲染
    - 页面内容更新不再依赖根壳层重新 build
  - `AppShellController` 已补齐对外 page-level listenable：
    - `destinationListenable`
    - `activeThemeIdListenable`
    - `workbenchPageListenable`
    - `settingsPageListenable`
    - `agentEcosystemPageListenable`
    - `projectCollectionPageListenable`
    - `taskCenterPageListenable`
    - `reviewCenterPageListenable`
    - `promptTemplatesPageListenable`
  - 当前仍保留 `AppShellController.notifyListeners()` 作为兼容通知链，但壳层主渲染已不再直接依赖它
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/app.dart apps/novel_agent_app/lib/shared/widgets/app_shell.dart apps/novel_agent_app/lib/app/routing/app_router.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/app/state/app_shell_listenable_state.dart`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/workbench_page_desktop_layout_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 根壳层已经不再被工作台流式更新直接拖着重建
  - 工作台 page data 已有正式 page-scope 监听出口
  - 这轮刻意没有提前进入 `WorkbenchViewData` 大拆，也没有做视觉改版
- 后续扩展点：
  - `AppShellListenableState` 当前仍是“page snapshot 同步器”，下一轮 `FE-02` 可以继续把 `workbench` 内部 slice 再拆细
  - 其他持有 view data 快照的页面，如果后续继续演化成更复杂的子域控制器，也可以直接替换当前 page notifier，而不必回改 `AppShell`
  - `notifyListeners()` 仍在控制器中保留，等 `FE-02` 和后续页内 slice 拆分完成后，再判断是否继续收缩其职责
  - 下一轮自然进入 `Session FE-02`

## 0.2 Session FE-02 完成记录

- 已完成 `Session FE-02：工作台视图数据与 pane controller 拆分`
- 已落地：
  - 新增工作台 pane slice 模型：
    - `WorkbenchResourceViewData`
    - `WorkbenchCanvasViewData`
    - `WorkbenchConversationViewData`
    - `WorkbenchOverlayViewData`
  - 新增工作台 pane mapper：
    - `WorkbenchPaneViewDataMapperService`
  - `AppShellListenableState` 已从“单个 workbench page snapshot”扩展为：
    - `workbenchResourceListenable`
    - `workbenchCanvasListenable`
    - `workbenchConversationListenable`
    - `workbenchOverlayListenable`
  - `AppShellController` 已对外暴露对应的 pane-level listenable
  - `AppRouter` 的工作台入口已改成直接挂多 listenable 的 `WorkbenchPage`
  - `WorkbenchPage` 已重构为多 host 结构：
    - `resource` pane 自己监听 `WorkbenchResourceViewData`
    - `document/canvas` pane 只监听 `WorkbenchCanvasViewData`
    - `conversation` pane 自己监听 `WorkbenchConversationViewData`
    - overlay host 单独监听 `WorkbenchOverlayViewData`
  - 以下组件已切换到各自 slice，而不是继续吃整份 `WorkbenchViewData`：
    - `ResourceManagerPanel`
    - `DocumentWorkspacePanel`
    - `ConversationSidebar`
    - `ConversationComposerPanel`
    - `ConversationModelStrip`
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/app/routing/app_router.dart apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_composer_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart apps/novel_agent_app/lib/app/state/app_shell_controller.dart apps/novel_agent_app/lib/app/state/app_shell_listenable_state.dart apps/novel_agent_app/lib/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_resource_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_canvas_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_conversation_view_data.dart apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_overlay_view_data.dart`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/conversation_sidebar_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/workbench_page_desktop_layout_test.dart test/conversation_sidebar_test.dart test/document_workspace_panel_test.dart test/resource_manager_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
- 本轮结论：
  - 工作台主结构已经不再由单份 `WorkbenchViewData` 直接驱动 UI 渲染
  - 会话区流式变化现在不会再天然把资源树和 overlay 一起拖进重建
  - 当前仍保留聚合 `WorkbenchViewData` 作为 controller 内部共享写模型，属于兼容过渡，不再直接作为页面渲染输入
- 后续扩展点：
  - `WorkbenchPaneViewDataMapperService` 当前还是从聚合 `WorkbenchViewData` 派生 slice；如果后续 controller 内部也继续分裂，可以直接替换 mapper 输入，而不必回改 pane host
  - `WorkbenchCanvasViewData` 目前仍承载 `generationStatus`，后续如果要进一步收紧正文区刷新面，可以把文档状态提示再独立成更细的 canvas status slice
  - `workbenchPageListenable` 仍被保留作为兼容监听口，后续如果确认没有消费方，可在更后续会话里清理
  - 下一轮自然进入 `Session FE-03`

## 0. 文档目的

这份文档承接：

- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/conversation-system-audit-2026-05-27.md`
- `docs/ui-absorption-analysis-2026-05-26.md`
- 已完成的：
  - `docs/ui-implementation-session-order.md`
  - `docs/ui-second-wave-session-order.md`

它的目标不是继续做“零散补 UI”，而是把当前前端重构明确拆成：

- 一次会话内可以完成
- 预计改动量尽量控制在 `<= 2000` 行
- 重点只处理一件事或一类事
- 有清楚的“本轮要做 / 不要做 / 重点拆耦 / 完成判定”
- 每轮都附带一个可直接复制给 Codex 的提示词

---

## 1. 适用范围

本文件只负责前端下一阶段的正式演化，重点覆盖：

1. 会话系统性能与状态边界治理
2. `AppShell / Workbench` 监听边界拆分
3. `Theme` 与 `Control Style` 双体系正式分离
4. 可重排、可替换、不可写死的布局槽位合同
5. 会话时间线从字符串条目升级为语义块系统
6. streaming、工具、子智能体、待发送输入的低干扰运行表达
7. 工作台从静态三栏升级为：
   - 导航层
   - 主画布层
   - 协作层
   - 辅助工作层
8. 桌面端与窄屏端的第二代工作台结构
9. 最终联调、探针、打包前回归

---

## 2. 全局硬约束

后续每一轮都必须继续遵守以下规则。

## 2.1 空间位置不能写死

这条是硬约束。

我们不能把以下关系写死在页面结构里：

- 智能体选项永远在输入框下
- 思考区永远在输入框上
- 工具状态永远插在消息列表某个固定位置
- 某个控制条永远只能在右栏顶部

因为后续很可能继续调整，例如：

- 选项移到会话靠上
- 思考区上移
- 控件文字缩小
- 模型条与输入区重新换位

所以本轮之后的前端必须优先支持：

- `slot-based layout`
- `section composition`
- `repositionable block host`

禁止继续把空间关系写成大段固定 widget 树。

## 2.2 只吸收风格，不照搬布局

重点参考：

- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
- `references/assets/ai_images_052601/主工作台：窄屏单列模式.png`

吸收的是：

- 配色节奏
- 区块层级
- 信息密度
- 控件克制感
- 状态呈现方式
- 输入区与会话区的整体气质

不吸收：

- 像素级位置
- 具体栏宽比例写死
- 某张图里的布局就是最终产品结构

## 2.3 颜色主题与控件风格必须分离

这是本轮新增正式约束。

以后不能再把以下东西混在一起：

- 背景色 / 文本色 / 边框色 / 强调色
- 按钮圆角 / 阴影 / 分隔线厚度 / 输入框 chrome / 芯片样式 / 卡片密度

正确方向是分成两套：

1. `Theme Color System`
2. `Control Style System`

后续即便只有内置：

- 明亮主题
- 偏暗主题

也必须允许它们共享或切换不同的控件风格。

也就是说，未来用户自定义不仅可能换颜色，也可能换：

- 按钮风格
- 面板边框语言
- 输入区密度
- 工具条样式

## 2.4 继续遵守解耦与单一职责

尤其注意：

- 不再把职责塞回 `app_shell_controller.dart`
- 不再让 `workbench_page.dart` 重新长成总控页
- 不再让 `conversation_sidebar.dart` 继续吞结构、状态、样式、交互

最低要求：

- 单文件超过 `400` 行必须复核
- 单文件接近 `700` 行必须拆
- 状态、投影、布局、样式、具体 widget 分层

## 2.5 先解决性能与状态边界，再做纯视觉吸收

必须保持顺序：

1. 监听边界拆分
2. 流式更新节奏治理
3. 会话语义块合同
4. 布局与样式升级

不能反过来，否则只会得到“更好看但更卡”的前端。

## 2.6 前端也要为多策略模式服务

前端结构不能只为当前工作台服务。

必须为这些未来差异留口：

- 一般小说
- 长任务模式 1 / 2 / 后续模式
- 拆书
- 灵感工作台
- 资产中心
- 审稿 / 重写 / 修订

也就是说：

- 页面只是宿主
- 结构应该由注册表、槽位和子域壳承接
- 不是把所有模式都塞进一个右栏聊天区

---

## 3. 新阶段总览

建议按下面顺序推进：

### 第一组：先把性能和状态边界收紧

- `Session FE-01`：壳层监听边界拆分
- `Session FE-02`：工作台视图数据与 pane controller 拆分
- `Session FE-03`：颜色主题与控件风格双体系

### 第二组：把布局合同和会话合同做成正式结构

- `Session FE-04`：可重排布局槽位合同
- `Session FE-05`：会话语义块合同与渲染注册表
- `Session FE-06`：streaming cadence / appendix / pending preview
- `Session FE-07`：子智能体预览卡与全屏详情流

### 第三组：把工作台升级成新结构

- `Session FE-08`：导航层与辅助工作层壳
- `Session FE-09`：主画布壳与 renderer host 深化
- `Session FE-10`：桌面端第二代工作台组合
- `Session FE-11`：窄屏端第二代工作台组合

### 第四组：联调、探针、打包前收尾

- `Session FE-12`：前端总回归与性能探针

---

## 4. Session FE-01：壳层监听边界拆分

### 本轮目标

把 `AppShell` 从“监听整个大控制器”改成只监听真正属于壳层的状态，阻止会话流式更新穿透整个应用骨架。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/conversation-system-audit-2026-05-27.md`

### 必须完成

1. 拆出壳层专属状态边界，例如：
   - `destination`
   - `shell chrome`
   - `layout mode`
2. 让 `WorkbenchPage` 不再依附整个 `AppShellController` 重建
3. 建立 page-scope listenable 或等价边界
4. 确认会话流式更新不会再触发整个壳层 rebuild

### 本轮不要做

- 不做会话栏视觉改版
- 不做 transcript block
- 不做主题和控件风格体系

### 本轮重点拆耦

- `shell state`
- `destination state`
- `page-level presenter`

### 完成判定

- `AppShell` 不再监听整份工作台状态
- 会话流式更新的影响范围明显收窄
- 没有把新的广播逻辑又塞回别的万能控制器

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-01 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/conversation-system-audit-2026-05-27.md。只处理壳层监听边界拆分：把 AppShell 从监听整个大控制器改成只监听 destination、shell chrome、layout mode 等真正属于壳层的状态，并给 WorkbenchPage 建立 page-scope listenable。不要做会话栏视觉改版，不要顺手改 transcript block、主题体系。注意不要再造新的万能控制器。
```

---

## 5. Session FE-02：工作台视图数据与 pane controller 拆分

### 本轮目标

把 `WorkbenchViewData` 一类一体化大对象拆开，让资源区、主画布、会话区、overlay 只消费自己的 slice。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/conversation-system-audit-2026-05-27.md`

### 必须完成

1. 拆分工作台 view data，例如：
   - `WorkbenchResourceViewData`
   - `WorkbenchCanvasViewData`
   - `WorkbenchConversationViewData`
   - `WorkbenchOverlayViewData`
2. 建立 pane-specific controller / presenter / mapper
3. 让三栏各自只监听自己的数据切片
4. 保证流式会话更新不再把资源树和主画布一起拖进重投影

### 本轮不要做

- 不做最终布局重排
- 不做 activity rail
- 不做 streaming appendix

### 本轮重点拆耦

- `view data slice`
- `pane presenter`
- `pane-specific listenable`

### 完成判定

- 工作台主结构不再靠一个大 view data 驱动
- 会话区流式更新时，其他 pane 基本不跟着重算
- 没有把拆分后的 slice 又重新包回一个大壳对象

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-02 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/conversation-system-audit-2026-05-27.md。只处理工作台视图数据与 pane controller 拆分：把资源区、主画布、会话区、overlay 的 view data 分开，并让各自 pane 只监听自己的 slice。不要做最终布局重排，不要顺手引入 activity rail 或 streaming appendix。注意 presenter、view data、listenable 分层。
```

---

## 6. Session FE-03：颜色主题与控件风格双体系

### 本轮目标

在已有主题基座之上，正式把“颜色主题”和“控件风格”拆成两条独立注册体系。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/ui-implementation-session-order.md`

### 必须完成

1. 在现有主题体系之外建立控件风格体系，例如：
   - `ControlStyleDescriptor`
   - `ControlStyleTokenSet`
   - `ControlStyleRegistry`
   - `ControlStyleResolver`
2. 把共享 chrome 规格抽出来，例如：
   - panel chrome
   - chip chrome
   - input chrome
   - toolbar chrome
   - card density / radius / divider weight
3. 让核心共享组件开始同时消费：
   - color tokens
   - control style tokens
4. 保留未来用户自定义控件风格的扩展口

### 本轮不要做

- 不做主题设置页 UI
- 不做大面积页面改版
- 不把具体业务组件特例写死到 resolver

### 本轮重点拆耦

- `theme color`
- `control chrome`
- `surface spec`
- `component style adapter`

### 完成判定

- 颜色主题与控件风格已成为两套独立合同
- 核心共享组件可以不改颜色前提下替换控件风格
- 后续自定义扩展已经有明确入口

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-03 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/ui-implementation-session-order.md。只处理颜色主题与控件风格双体系：在现有 theme 基座上新增 ControlStyleDescriptor + ControlStyleTokenSet + ControlStyleRegistry + ControlStyleResolver，并补齐共享 chrome spec。不要做主题设置页，不做大面积页面改版，不要把业务特例硬塞进 resolver。注意颜色 token 和控件风格 token 完全分层。
```

---

## 7. Session FE-04：可重排布局槽位合同

### 本轮目标

为工作台建立可重排 section/slot 合同，确保后续会话区、模型条、思考区、选项区等位置都可调整，而不是依赖固定 widget 树。

### 预计改动量

- 约 `900 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/ui-absorption-analysis-2026-05-26.md`

### 必须完成

1. 定义正式布局槽位模型，例如：
   - `WorkbenchSlotId`
   - `ConversationSectionId`
   - `SectionPlacement`
2. 建立 conversation / workbench 的 section composition host
3. 让以下区域至少走可组合合同：
   - 头部
   - runtime status
   - timeline
   - pending input
   - composer
   - model strip
4. 避免在此轮就绑定最终位置

### 本轮不要做

- 不做最终视觉细化
- 不做 transcript block 渲染
- 不做桌面三栏整体改版

### 本轮重点拆耦

- `slot contract`
- `section registry`
- `placement resolver`

### 完成判定

- 会话区关键 section 已能通过合同重排
- 后续调整位置不需要重写整个 sidebar widget 树
- 页面代码不再直接假定所有区块的固定顺序

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-04 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/ui-absorption-analysis-2026-05-26.md。只处理可重排布局槽位合同：为 workbench 和 conversation 建立 slot/section/placement 体系，让头部、runtime status、timeline、pending input、composer、model strip 都走可组合合同，不要在这一轮绑定最终位置。不要做视觉细化，不要顺手改桌面三栏整体布局。注意 slot contract、section registry、placement resolver 分开。
```

---

## 8. Session FE-05：会话语义块合同与渲染注册表

### 本轮目标

把会话时间线从展示字符串条目升级成正式的语义块系统。

### 预计改动量

- 约 `1000 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/conversation-system-audit-2026-05-27.md`
- `references/DeepSeek-TUI-main/docs/TOOL_SURFACE.md`

### 必须完成

1. 定义 transcript block 合同，例如：
   - `message.user`
   - `message.assistant.streaming`
   - `message.assistant.final`
   - `tool.compact`
   - `choice.group`
   - `runtime.notice`
   - `retry.banner`
   - `checkpoint.card`
2. 建立 block renderer registry
3. 让 timeline 只排列 block，不再理解每类细节
4. 工具、选项、检查点、重试等都成为一等块类型

### 本轮不要做

- 不做 streaming cadence
- 不做子智能体全屏流
- 不做主工作台布局重排

### 本轮重点拆耦

- `transcript block model`
- `block projection`
- `block renderer registry`

### 完成判定

- 时间线不再依赖弱结构 message tile
- 新增块类型时不需要改 timeline 主体逻辑
- 工具、选项、重试、检查点都有清晰归属

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-05 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/conversation-system-audit-2026-05-27.md、references/DeepSeek-TUI-main/docs/TOOL_SURFACE.md。只处理会话语义块合同与渲染注册表：建立 transcript block model、block projection 和 renderer registry，让 message、tool、choice、runtime notice、retry、checkpoint 等都成为一等块类型。不要做 streaming cadence，不要做子智能体全屏流。注意 timeline 只负责排列 block。
```

---

## 9. Session FE-06：streaming cadence / appendix / pending preview

### 本轮目标

正式把高频流式更新和稳定历史区分开，吸收 DeepSeek TUI 的 commit-tick 思路与 pending input preview 思想。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/conversation-system-audit-2026-05-27.md`
- `references/DeepSeek-TUI-main/docs/ARCHITECTURE.md`
- `references/DeepSeek-TUI-main/crates/tui/src/tui/streaming/commit_tick.rs`

### 必须完成

1. 正式区分：
   - stable history
   - streaming assistant appendix
   - current round tool strip
   - footer / pending area
2. 建立 streaming cadence 模型
3. 建立 pending input preview 区
4. 工具状态、正文流、运行状态走不同刷新节奏
5. 尽量消除 AI 返回时整页闪烁

### 本轮不要做

- 不做新的主题吸收
- 不做子智能体详情页
- 不做桌面 / 窄屏布局大改

### 本轮重点拆耦

- `streaming appendix model`
- `cadence coordinator`
- `pending preview presenter`

### 完成判定

- 会话流式输出与稳定历史已彻底分层
- AI 返回时的闪烁和重建范围明显下降
- 用户可以看到待发送输入，而不是只能盯着输入框

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-06 执行。先阅读 agent.md、docs/conversation-system-audit-2026-05-27.md、references/DeepSeek-TUI-main/docs/ARCHITECTURE.md、references/DeepSeek-TUI-main/crates/tui/src/tui/streaming/commit_tick.rs。只处理 streaming cadence、streaming appendix 和 pending input preview：把 stable history、streaming assistant appendix、current round tool strip、footer/pending area 分开，并让正文流、工具流、运行状态流走不同刷新节奏。不要顺手做布局大改或子智能体详情页。注意 cadence coordinator 和 pending preview presenter 分离。
```

---

## 10. Session FE-07：子智能体预览卡与全屏详情流

### 本轮目标

把子智能体调用从“最后只在底部冒一条协作活动”升级为正式的预览卡与全屏详情流。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `references/DeepSeek-TUI-main/docs/SUBAGENTS.md`

### 必须完成

1. 建立子智能体预览块：
   - 运行中摘要
   - 完成态摘要
   - 失败态摘要
2. 点击后进入会话区内的全屏详情视图
3. 详情页可返回
4. 子智能体详情页内不提供输入框
5. 子智能体运行过程不刷出低层细节垃圾文本

### 本轮不要做

- 不做新的子智能体调度逻辑
- 不改底层 agent runtime
- 不做长任务总站改版

### 本轮重点拆耦

- `subagent preview projection`
- `subagent detail route/state`
- `conversation fullscreen host`

### 完成判定

- 子智能体调用在时间线里有稳定预览块
- 用户可以点开查看全过程，但不会污染主会话输入流
- 子智能体详情页不误带主输入框

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-07 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、references/DeepSeek-TUI-main/docs/SUBAGENTS.md。只处理子智能体预览卡与全屏详情流：让子智能体在会话时间线中以预览块出现，点击后在会话区域进入全屏详情视图，可返回，且详情页内没有输入框。不要改底层调度，不要顺手做长任务总站改版。注意 preview projection、detail route/state、fullscreen host 分离。
```

---

## 11. Session FE-08：导航层与辅助工作层壳

### 本轮目标

把工作台正式升级成“活动轨 + 可切换侧栏 + 主区 + 辅助工作层”的结构壳，但先不追求最终视觉。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `references/Writingway-main/README.md`
- `references/Writingway-main/project_window/activity_bar.py`
- `references/Writingway-main/project_window/bottom_stack.py`

### 必须完成

1. 建立稳定的 activity rail / side panel host
2. 左侧一次只显示一个工作面板
3. 建立辅助工作层壳，例如：
   - prompt preview
   - rewrite preview
   - review / analysis
   - context selection
4. 保证这些能力不再全塞右栏会话

### 本轮不要做

- 不做最终桌面三栏比例微调
- 不做主题美化大扫除
- 不做具体 analysis/rewrite 业务扩张

### 本轮重点拆耦

- `activity rail`
- `side panel host`
- `auxiliary work host`

### 完成判定

- 工作台已拥有正式导航层和辅助工作层壳
- 左侧不再是多个面板同时堆开
- 分析 / 重写 / 预览开始有合理归属

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-08 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、references/Writingway-main/README.md、references/Writingway-main/project_window/activity_bar.py、references/Writingway-main/project_window/bottom_stack.py。只处理导航层与辅助工作层壳：建立 activity rail、单面板 side panel host、auxiliary work host，让 prompt preview、rewrite preview、review/analysis、context selection 不再全塞右栏会话。不要做最终视觉大扫除，不要扩新业务主线。注意 rail、panel host、auxiliary host 分开。
```

---

## 12. Session FE-09：主画布壳与 renderer host 深化

### 本轮目标

把主画布正式收束成资源主画布，而不是“正文编辑器 + 一些 if/else”。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/ui-absorption-analysis-2026-05-26.md`

### 必须完成

1. 强化 primary canvas host
2. 让主画布与 auxiliary work layer 形成稳定父子关系
3. 继续收束资源 renderer 入口：
   - markdown
   - plain text
   - structured resource
   - preview-like resource
4. 让主画布不再只服务章节正文

### 本轮不要做

- 不做图谱完整 UI
- 不做资产中心整页重构
- 不改底层存储策略

### 本轮重点拆耦

- `canvas host`
- `renderer host`
- `auxiliary child layer`

### 完成判定

- 中间区已经是正式主画布，不再只是文档编辑器
- 新资源类型接入不需要改大页面逻辑
- 辅助工作层与主画布关系清楚

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-09 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/ui-absorption-analysis-2026-05-26.md。只处理主画布壳与 renderer host 深化：强化 primary canvas host，让主画布与 auxiliary work layer 形成稳定父子关系，并继续收束 markdown/plain text/structured/preview 类资源的 renderer 入口。不要做图谱完整 UI，不要改底层存储策略。注意 canvas host、renderer host、auxiliary child layer 分离。
```

---

## 13. Session FE-10：桌面端第二代工作台组合

### 本轮目标

在前面结构与合同都立住之后，正式做桌面端第二代工作台组合，吸收参考图的风格语言，而不是照搬布局。

### 预计改动量

- 约 `1100 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`

### 必须完成

1. 收束桌面端整体区块层级与背景节奏
2. 统一：
   - 左侧导航 / 面板
   - 主画布
   - 协作区
   - 辅助工作层
3. 吸收参考图的克制、安静、专业感
4. 继续保持布局参数可调整，不写死最终比例

### 本轮不要做

- 不做窄屏模式
- 不做新的业务功能
- 不为了美化把结构重新耦合

### 本轮重点拆耦

- `desktop layout policy`
- `desktop surface composition`
- `desktop section spec`

### 完成判定

- 桌面端整体气质明显统一
- 工作台不再显得五颜六色、区块语言分裂
- 后续如果调整比例或位置，不需要回头拆大文件

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-10 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、references/assets/ai_images_052601/主工作台：桌面三栏模式.png。只处理桌面端第二代工作台组合：统一左侧导航/面板、主画布、协作区、辅助工作层的区块层级和背景节奏，吸收参考图的克制、安静、专业感，但不要照搬布局，也不要把比例写死。不要扩新业务功能。注意 desktop layout policy、surface composition、section spec 分开。
```

---

## 14. Session FE-11：窄屏端第二代工作台组合

### 本轮目标

把窄屏模式升级为真正好用的第二代结构，解决输入区滚动、视野遮挡、入口组织、滚动稳定性等问题。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `references/assets/ai_images_052601/主工作台：窄屏单列模式.png`

### 必须完成

1. 收束窄屏模式的主要视图优先级
2. 保持稳定的抽拉入口，但不遮挡主要阅读区域
3. 修复输入框自身滚动体验
4. 保持会话、正文、工作面板之间的切换清楚
5. 让窄屏风格与桌面端属于同一套产品语言

### 本轮不要做

- 不做桌面端继续微调
- 不做新的主画布功能
- 不顺手扩大移动端附件能力

### 本轮重点拆耦

- `compact layout policy`
- `compact drawer host`
- `compact composer shell`

### 完成判定

- 窄屏模式不再遮挡主内容
- 输入框可自然滚动
- 入口、主视图、抽拉面板三者关系清楚
- 风格上与桌面端统一

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-11 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、references/assets/ai_images_052601/主工作台：窄屏单列模式.png。只处理窄屏端第二代工作台组合：收束主要视图优先级，保留稳定抽拉入口但不遮挡主阅读区，修复输入框自身滚动体验，并让窄屏风格与桌面端统一。不要继续微调桌面端，不要扩大移动端附件能力。注意 compact layout policy、drawer host、composer shell 分开。
```

---

## 15. Session FE-12：前端总回归与性能探针

### 本轮目标

对这一整轮前端演化做一次联调回归，只修真实暴露的问题，不开新主线。

### 预计改动量

- 约 `600 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/frontend-evolution-synthesis-2026-05-27.md`
- `docs/conversation-system-audit-2026-05-27.md`
- 本文件前面各 session

### 必须完成

1. 回归流式输出卡顿与闪烁
2. 回归工具条、选项条、pending preview、子智能体块
3. 回归桌面端 / 窄屏端工作台
4. 回归主题颜色与控件风格双体系是否都成立
5. 做真实性能探针或至少真实长任务前端链路验证
6. 回填文档与验证结果

### 本轮不要做

- 不开新功能主线
- 不借回归之名大改架构
- 不继续吸收新参考项目

### 本轮重点拆耦

- 只修局部真实问题
- 不允许为了救火再造新中心文件

### 完成判定

- 前端主要体验问题已被真实验证
- 性能与结构都达到可继续打包测试的状态
- 文档状态与代码状态一致

### 建议提示词

```text
按 docs/frontend-evolution-session-order.md 的 Session FE-12 执行。先阅读 agent.md、docs/frontend-evolution-synthesis-2026-05-27.md、docs/conversation-system-audit-2026-05-27.md 和本文件前面各 session。只做前端总回归与性能探针：回归流式输出卡顿和闪烁、工具条/选项条/pending preview/子智能体块、桌面端/窄屏端工作台，以及颜色主题与控件风格双体系是否都成立。不要开新功能主线，不要借回归之名大改架构，完成后回填文档与验证结果。
```

---

## 16. 执行规则

后续按本文件推进时，默认遵循以下规则：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或者暴露了强关联回归，先补完，不开启下一轮。
3. 每轮开始前至少复读：
   - `agent.md`
   - 本文件对应 session
   - 该 session 指向的分析文档
4. 每轮结束时都要说明：
   - 本轮完成了什么
   - 哪些文件是后续扩展点
   - 哪些点被明确延期
5. 即便是 UI 工作，也继续遵守：
   - 单一职责
   - 不让文件过重
   - presenter / state / widget / style / layout 分层

---

## 17. 当前推荐起点

从当前状态看，最自然的下一步是：

1. `Session FE-01`
2. `Session FE-02`
3. `Session FE-03`

原因很明确：

- 当前最痛的问题仍是会话流式带来的卡顿、闪烁和大范围 rebuild
- 在这之前直接做大面积视觉吸收，收益不稳
- 先把壳层边界、pane 边界、主题/控件风格双体系立住，后面桌面和窄屏的重构会轻松很多
