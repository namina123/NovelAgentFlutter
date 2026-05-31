# NovelAgentFlutter 工作台左右栏重画分析

最后更新：2026-05-29

关联资料：

- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
- `docs/workbench-recovery-session-order-2026-05-29.md`

---

## 1. 这份文档解决什么问题

这份文档不处理“旧恢复链是否完成”，而是单独收口当前新的产品问题：

1. 左栏在高度压缩后存在明显割裂感
2. 右栏会话区信息归属混乱
3. 智能体组、组内智能体、模型、深度思考四者的职责边界没有正确落地
4. 工具概览既不适合常驻主界面，也不能彻底消失

这不是“再调一点 UI”能解决的问题，而是一次正式的：

- 信息层级重构
- 状态归属重构
- 左右栏职责重构

---

## 2. 用户意图的最终整理

这次用户意图已经比较明确，可以固定为以下几条：

### 2.1 右栏必须重画，不是微调

参考 `主工作台：桌面三栏模式.png`，吸收的是：

- 安静、简洁的层级
- 发送区作为底部核心
- 模型参数贴近输入区

不是照搬布局。

### 2.2 右栏不应再承担项目级配置入口

右栏是会话区，不是项目配置区。

因此以下内容不应继续占据右栏主界面：

- 项目智能体组选择
- 不可用组原因面板
- 开局配置说明块

这些应回到项目相关面板。

### 2.3 右栏顶部可以选择“当前智能体组内的智能体”

这里不是选择智能体组，而是：

- 项目已经先选定一个智能体组
- 右栏顶部只允许在该组可用成员中切换当前会话使用的智能体

这说明右栏顶部允许存在一个“会话参与智能体选择器”，但不允许继续承担“项目默认组选择器”。

### 2.4 模型和深度思考属于输入参数，不属于智能体参数

深度思考是模型级参数：

- 默认开启
- 用户改动后要记忆
- 智能体只是承载这个参数，不是这个参数的归属者

因此：

- 模型选择
- 深度思考开关

都应靠近输入框下方，作为“本次发送配置”出现。

### 2.5 工具概览不应常驻主界面，但必须保留入口

用户补充要求：

- 工具概览如果不在主界面，也必须在设置里某个地方出现
- 默认应为非细节模式

所以工具概览的正确归宿是：

- 不常驻右栏主界面
- 在设置页有稳定入口
- 默认概览，不默认细节

---

## 3. 当前实现为什么不合理

## 3.1 右栏把三种不同层级的信息混在一起了

当前右栏实际混入了三类状态：

1. 会话级
   - 时间线
   - 输入框
   - 发送
   - 当前运行状态
2. 模型级
   - 模型选择
   - 深度思考
3. 项目级
   - 智能体组选择
   - 不可用组原因
   - 开局说明

这三种层级目前被同一块 UI 容器承接，导致用户无法形成稳定心智。

### 直接相关文件

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_composer_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_primary_agent_bar.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_session_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_header.dart`

补充问题：

- `ConversationPanelHeader` 当前副标题来自 `groupSelector.headerSubtitle`
- 这会持续把“项目默认智能体组”暴露成右栏页头语义
- 即便删除中下部组选择器，如果不处理这里，用户仍会感觉右栏顶部在承担项目级配置表达

---

## 3.2 深度思考的底层归属是对的，但展示位置是错的

当前 `onReasoningToggleChanged` 已经直接写回共享模型设置：

- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

也就是说，数据归属已经是模型级。

但 UI 现在把开关放在：

- `conversation_primary_agent_bar.dart`

这会让用户误以为深度思考是主智能体参数，而不是模型参数。

结论：

- 底层逻辑不需要推翻
- 只需要重构 UI 归属

---

## 3.3 智能体组的右栏选择器传播了旧心智

当前：

- `conversation_model_strip.dart`

里同时放了：

- 模型
- 智能体组

但按当前产品规则，智能体组应当是项目基线，而不是会话即时参数。

结论：

- 右栏里的“智能体组选择器”应删除
- 组选择保留在项目面板 / 项目智能体组配置中

---

## 3.4 工具概览不适合常驻主界面

当前 `ConversationPanelStatusGroup` 会在右栏顶部持续显示：

- 上下文
- 工具
- 运行

对应：

- `conversation_panel_status_group.dart`
- `conversation_status_summary_view_data_service.dart`

问题不在于它实现得差，而在于它占了错误的位置：

- 它更像“控制台摘要”
- 不像用户会话主界面必看信息

结论：

- 主界面移除这组常驻状态 chips
- 工具展示模式下沉到设置
- 运行状态改成更轻的就地提示

---

## 3.5 左栏割裂感来自高度和滚动模型，而不是纯视觉

当前左栏是三层嵌套：

1. `WorkbenchNavigationSidebar`
   - 对象头
   - 对象切换
   - 下方 `Expanded`
2. `WorkbenchSidePanelHost`
   - 不同对象面板切换
3. `ResourceManagerPanel`
   - 文件工具块
   - 资源树块
   - 高度不足时整块滚动
   - 高度充足时资源树单独 `Expanded`
   - 还使用 `38%` 树高估算

这会导致压缩高度后出现三种不连续感：

1. 上层对象头和下层内容像两个系统
2. 文件工具块和树块像两个卡住的层次
3. 一会整面板滚，一会树单独滚，行为不稳定

### 直接相关文件

- `workbench_navigation_sidebar.dart`
- `workbench_side_panel_host.dart`
- `resource_manager_panel.dart`
- `resource_manager_header.dart`
- `resource_panel_section.dart`
- `resource_tree_card.dart`

---

## 4. 这轮重画后的正确结构

## 4.1 右栏应拆成三层

### 顶部：会话头部 + 组内智能体选择

只保留：

- 会话标题
- 历史 / 新会话
- 当前智能体组内的智能体选择器

这里的智能体选择器只负责：

- 展示当前项目组内可用智能体
- 切换当前会话使用的智能体

不负责：

- 切换智能体组
- 修改项目协作基线

### 中部：时间线 / 空态引导

承接：

- 会话时间线
- 子智能体展开
- 开局第一句引导

不再承接：

- 组选择器
- 大块状态 chips
- 工具概览

### 底部：输入区 + 发送参数

输入区底部只放：

- 输入框
- 发送按钮
- 模型选择
- 深度思考开关

这一区域的语义应该是：

- 当前这次发送用什么模型
- 当前这次发送是否开启深度思考

---

## 4.2 左栏应改成连续对象面板

左栏结构应固定为：

1. 薄对象头
2. 紧凑对象切换
3. 单一连续内容区

其中“文件”对象面板应改成：

- 单一滚动面板
- 文件工具条作为树前导内容，而不是单独一块“卡”
- 资源树作为主内容

禁止继续保留：

- 百分比估算树高
- 高度充足/不足两套完全不同滚动模型

---

## 5. 新的状态归属建议

## 5.1 项目级

应保留在项目侧的状态：

- 当前项目默认智能体组
- 当前项目支持 / 不支持的智能体组
- 不可用原因

不应继续在右栏承担配置入口。

### 主要来源

- `OpeningSessionProjection`
- `ProjectOpeningSessionProjectionService`
- 项目智能体组绑定链

---

## 5.2 会话级

右栏顶部应新增一条独立状态：

- 当前会话使用的智能体（来自当前项目组内成员）

这不是项目默认组，也不是模型设置。

推荐归属：

- 项目作用域下的工作台运行偏好
- 不是全局设置
- 不是智能体组定义本体

推荐先保存在：

- `settings.extraSettings.workbench_state`
  的项目相关快照里

建议快照结构扩成：

- `extraSettings.workbench_state.project_root_path`
- `extraSettings.workbench_state.active_document_path`
- `extraSettings.workbench_state.expanded_directories`
- `extraSettings.workbench_state.selected_conversation_agent_id`

而不是直接写进：

- `model_settings`
- `toolStrategySettings`
- 智能体组源文件

原因：

- 它是当前项目 / 当前工作台的协作入口偏好
- 不应该污染模型默认参数
- 不应该修改智能体组原始定义
- 它和“当前项目默认智能体组”是两个概念，必须允许同时存在

---

## 5.3 模型级

模型级状态应只包括：

- 当前模型
- 深度思考开启状态
- 深度思考强度

其中：

- 默认开启
- 用户改动后记忆
- 继续写回共享 `model_settings`

当前底层链路已经基本符合，不需要推翻。

---

## 5.4 设置级

工具概览显示模式应进入设置，但不要混入执行策略本体。

推荐新增设置项：

- `extraSettings.workbench_ui.tool_preview_mode = compact | detail`

默认：

- `compact`

不要直接放进：

- `toolStrategySettings`

因为 `toolStrategySettings` 当前是执行权限与执行倾向，不是 UI 展示偏好。

---

## 6. 需要新增哪些合同 / 模型

## 6.1 新增“组内智能体选择”专用 view data

当前只有：

- `ConversationGroupSelectorViewData`

它的语义是“组选择 + 主智能体摘要”。

这已经不适合承接新的需求。

推荐新增：

- `apps/novel_agent_app/lib/features/workbench/presentation/models/conversation_agent_selector_view_data.dart`

建议字段：

- `currentAgentLabel`
- `currentAgentId`
- `currentAgentDescription`
- `agentOptions`
- `canSwitchAgent`
- `headerSubtitle` 或等价轻文案字段（可选）

不要把它继续塞进 `ConversationGroupSelectorViewData`，否则该模型会同时承载：

- 项目组基线
- 会话智能体切换

职责会再次变脏。

---

## 6.2 新增 opening / projection 里的组内智能体摘要

当前：

- `OpeningSessionProjection`
  只有 `currentPrimaryAgentSummary`

没有“当前组内可选成员列表”。

推荐新增应用层模型：

- `apps/novel_agent_app/lib/features/workbench/application/models/opening_agent_member_summary.dart`

建议字段：

- `agentId`
- `displayName`
- `role`
- `isPrimary`
- `thinkingSupported`
- `description`

然后扩展：

- `OpeningSessionProjection`

新增：

- `availableAgentSummaries`

这样右栏顶部的智能体选择器就能直接消费正式 projection，而不是 UI 自己猜组成员。

补充说明：

当前：

- `ProjectOpeningSessionProjectionService._resolveCurrentPrimaryAgentSummary`

只解析了“主智能体”，没有解析“当前组内全部成员”。

所以右栏顶部智能体选择不能只补 widget，必须同步扩：

- `project_opening_session_projection_service.dart`
- `opening_session_projection.dart`
- 新的 `opening_agent_member_summary.dart`

---

## 6.3 新增“会话智能体选择 view data service”

推荐新增：

- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_agent_selector_view_data_service.dart`

职责：

- 从 `OpeningSessionProjection`
- 当前项目工作台偏好中的 `selected_agent_id`

生成右栏顶部需要的只读 + 可选 view data。

这样可以把：

- 组成员过滤
- 当前选中恢复
- 主智能体默认回退

全部留在 service 层，不散给 widget。

---

## 7. 需要修改哪些现有合同

## 7.1 ConversationActionHandler

当前没有“切换当前会话智能体”的动作。

需要修改：

- `apps/novel_agent_app/lib/features/workbench/presentation/contracts/conversation_action_handler.dart`

新增：

- `void onConversationAgentSelected(String agentId);`

注意：

- 不要复用 `onAgentGroupSelected`
- 这两个动作的作用域已经不同
- `onAgentGroupSelected` 保留给项目级配置链
- `onConversationAgentSelected` 只用于右栏当前会话智能体切换

---

## 7.2 WorkbenchConversationViewData

当前右栏只拿到：

- `groupSelector`

但新结构至少还需要：

- `agentSelector`
- `sendConfigViewData`（若后续把模型和深度思考组合成单独 view data）

需要修改：

- `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_conversation_view_data.dart`

新增字段：

- `ConversationAgentSelectorViewData agentSelector`

---

## 7.3 WorkbenchViewData

工作台总视图状态也要新增：

- `agentSelector`

或者由 controller 在 conversation mapping 前生成。

更推荐：

- 在 `WorkbenchViewData` 中新增
- 保持全链路显式

对应文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_view_data.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart`

补充约束：

- 不要把“项目级 groupSelector”直接改造成“会话级 agentSelector”
- `WorkbenchPaneViewDataMapperService.toConversationViewData` 应显式映射新字段
- `WorkbenchWorkspaceShellViewDataService` 不应继续从会话级选择器反推项目级标题

---

## 8. 右栏实现层建议怎么改

## 8.1 ConversationComposerPanel 需要拆

当前：

- `ConversationComposerPanel`
  同时装配：
  - 状态摘要
  - 模型/组选择
  - 主智能体条
  - 输入区

这是当前最重的混合点。

文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_composer_panel.dart`

建议拆成：

1. `conversation_agent_header_strip.dart`
   - 顶部智能体选择
2. `conversation_send_config_bar.dart`
   - 模型 + 深度思考
3. 保留 `ConversationComposerDockPanel`
   - 专心承接输入框和发送

这样 `ConversationComposerPanel` 本身就能退成一个薄装配层。

同时需要处理：

- `conversation_input_action_row.dart`
- `conversation_input_dock.dart`

原因：

- 模型与深度思考下沉到底部后，输入坞将不再只是“文本框 + 按钮”
- 它还需要承接：
  - 文本输入
  - 发送按钮
  - 模型选择
  - 深度思考开关

建议让 `ConversationInputDock` 只负责底部区布局装配，再把发送动作行继续保持成独立组件，避免输入文件重新变重。

---

## 8.2 ConversationModelStrip 要改名并降职责

当前：

- `conversation_model_strip.dart`
  同时包含模型和智能体组

建议：

- 改造成只包含模型
- 或直接废弃，改成新的 `conversation_send_config_bar.dart`

需要修改：

- `conversation_model_strip.dart`
- 引用它的：
  - `conversation_composer_panel.dart`
  - `conversation_sidebar_test.dart`

---

## 8.3 ConversationPrimaryAgentBar 不应继续放 reasoning

当前：

- `conversation_primary_agent_bar.dart`
  里混了：
  - 主智能体摘要
  - 深度思考开关

建议：

- 删除 reasoning 开关职责
- 如保留该组件，则只承接“当前会话智能体摘要”
- 或直接被新的 `conversation_agent_header_strip.dart` 替代

注意：

- 这个组件当前消费的是 `ConversationGroupSelectorViewData`
- 如果继续沿用，会把“当前组主智能体”误当成“当前会话选中智能体”
- 更安全的做法是新建顶部智能体条，而不是继续给旧组件打补丁

---

## 8.4 ConversationPanelStatusGroup 退出主界面常驻位

当前：

- `conversation_panel_status_group.dart`

建议：

- 从 `ConversationComposerPanel` 中移除
- 不再放在主界面常驻区域

处理方式：

1. 主界面只保留最轻量的运行提示
2. 工具概览模式进入设置
3. 若未来还需要开发态摘要，可放在可折叠调试区，而不是默认主界面

---

## 8.5 OpeningSessionPanel 退出右栏主界面配置位

当前：

- `opening_session_panel.dart`
  直接出现在右栏空态补充区

建议：

- 移出智能体组选择职责
- 右栏只保留第一句引导
- 项目智能体组配置入口回到项目对象面板

如果还保留 `OpeningSessionPanel`：

- 只能作为只读小提示，不再包含组切换器

并且需要同步修改：

- `conversation_empty_state_panel.dart`
- `workflow_guide_card.dart`

因为它们当前都会把 `OpeningSessionPanel` 当作右栏空态补充块挂进来。

---

## 9. 左栏实现层建议怎么改

## 9.1 ResourceManagerPanel 改成单一滚动模型

当前问题文件：

- `resource_manager_panel.dart`

问题点：

- `useScrollableLayout`
- `treeHeight = constraints.maxHeight * 0.38`
- 高度不足时整块滚动
- 高度足够时树单独滚

建议：

- 改成单一 `CustomScrollView` / sliver 方案
- 文件工具条成为树前导内容
- 不再切换两套滚动语义

这样左栏高度变化时不会突然出现割裂感。

---

## 9.2 ResourceManagerHeader 去掉“模型与接口设置”按钮

文件：

- `resource_manager_header.dart`

这个按钮本身就在错误位置：

- 左栏文件对象面板不该承担模型设置入口

建议：

- 删除该按钮
- 模型设置入口回到设置页 / 会话发送区模型行

---

## 9.3 ResourceTreeCard 应成为真正主内容

文件：

- `resource_tree_card.dart`

建议：

- 保持树作为文件对象面板主位
- 文件动作退成树前的前导工具条
- 不要再让树成为“下面剩下多少空间就给多少”的附属块

---

## 9.4 可以新增统一对象内容壳

建议新增：

- `workbench_object_panel_body.dart`

职责：

- 统一左栏三类对象面板的滚动、内边距、分区节奏

这样：

- 文件
- 项目
- 长任务

三个对象面板不会再各写各的滚动与高度策略。

还需要同步检查：

- `workbench_navigation_sidebar.dart`
- `workbench_side_panel_host.dart`

因为左栏割裂感不只来自文件面板，也来自：

- 上方对象头
- 中间对象切换
- 下方内容容器

这三层节奏彼此独立。

建议后续重构时让：

- 对象头高度更薄
- 切换器和内容区之间弱化分栏线
- 内容区成为真正连续的一块内容壳

---

## 10. 设置页需要补什么

## 10.1 在工具策略页补“工具展示”小节

文件：

- `apps/novel_agent_app/lib/features/settings/presentation/widgets/tool_strategy_settings_panel.dart`

建议新增小节：

- 工具展示
  - 默认概览
  - 显示细节

对应存储建议：

- `extraSettings.workbench_ui.tool_preview_mode`

不要写入：

- `toolStrategySettings`

避免“执行策略”和“展示偏好”继续耦合。

另外需要同步移除当前会话栏中的局部临时切换逻辑：

- `conversation_tool_visibility_state.dart`
- `conversation_status_summary_view_data_service.dart`
- `conversation_sidebar.dart` 中的 `_toolVisibility`

原因：

- 现状是工具细节模式只存在于右栏组件局部状态
- 新要求是它应成为设置偏好，而不是这一次页面打开时的临时翻转

---

## 10.2 模型页继续作为深度思考的正式设置源

文件：

- `model_settings_panel.dart`

这里已经是模型级参数正式入口，应该继续保留。

右栏里的深度思考开关只是：

- 一个会话近端快捷入口
- 实际仍写回这里的共享模型设置

---

## 11. 控制器与持久化层需要改什么

## 11.1 WorkbenchConversationController

需要新增职责：

1. `onConversationAgentSelected`
2. 读取 / 保存当前项目当前工作台的 `selected_agent_id`
3. 在发送请求时，把当前会话智能体选择结果带入 runtime 解析链

文件：

- `workbench_conversation_controller.dart`

### 注意

这一步不能直接“只改 UI”。

如果 UI 能切智能体，但发送时仍只看 `currentPrimaryAgentSummary`，那就会出现：

- UI 显示切了
- 实际执行没切

这是必须避免的假切换。

因此除了 `WorkbenchConversationController`，还要补查并改造真正拼装请求输入的链路：

- `conversation_request_runtime_service.dart` 本身只是句柄调度，不承担业务选择
- 真正要确认的是 `WorkbenchConversationController` 发起请求时构造给生成用例的上下文
- 需要把“当前会话智能体 id”显式带入请求上下文或运行参数

如果当前发送链还只依赖：

- `openingProjection.currentPrimaryAgentSummary`
- 或项目默认 group

那么必须同步替换为：

- `selected_conversation_agent_id` 优先
- 找不到时回退主智能体

---

## 11.2 WorkbenchWorkspaceController

当前已经负责：

- `workbench_state`
  快照持久化

文件：

- `workbench_workspace_controller.dart`

建议扩展快照：

- `selected_conversation_agent_id`

这样它是：

- 项目相关
- 工作台恢复友好
- 不污染全局模型设置

并且需要同步更新：

- `restoreWorkbenchSnapshot`
- `_persistWorkbenchSnapshot`

否则只写入不恢复，或只恢复不持久化，都会让右栏顶部智能体选择显得不稳定。

---

## 11.3 还需要清理哪些旧投影，避免新旧语义打架

### `WorkbenchWorkspaceShellViewDataService`

文件：

- `apps/novel_agent_app/lib/features/workbench/application/services/workbench_workspace_shell_view_data_service.dart`

当前它用：

- `conversation.groupSelector.currentGroupLabel`
- `conversation.groupSelector.primaryAgentLabel`

去构造左栏壳层摘要。

问题：

- 新方案里 `groupSelector` 应继续表达项目级默认组
- `agentSelector` 应表达当前会话智能体
- 如果这里仍然无差别读会话视图数据，左栏项目面板可能会错误展示成“当前会话智能体”

建议：

- 左栏项目摘要继续读取项目级 group 数据
- 右栏顶部单独读取会话级 agent 数据
- 两者不要互相回填

### `ProjectAgentGroupWorkspaceViewDataService`

文件：

- `apps/novel_agent_app/lib/features/workbench/application/services/project_agent_group_workspace_view_data_service.dart`

当前文案：

- `selectionHint: '这里负责项目级正式配置；会话栏里的组入口只做快速切换。'`

这是旧规则，必须改。

新文案语义应变成：

- 项目面板负责选择项目默认智能体组
- 右栏顶部负责在当前组内切换本次会话智能体

---

## 12. 推荐的实现顺序

这次不要一口气直接重写完全部，建议按下面顺序切：

### 第 1 步：分析落地 + 合同清理

- 新增分析文档
- 确定：
  - 组选择离开右栏
  - 右栏新增组内智能体选择
  - 工具概览进入设置

### 第 2 步：补组内智能体选择合同

- 新增 `ConversationAgentSelectorViewData`
- 新增 `OpeningAgentMemberSummary`
- 扩展 `OpeningSessionProjection`
- 新增 `ConversationAgentSelectorViewDataService`

### 第 3 步：右栏结构重画

- 拆 `ConversationComposerPanel`
- 顶部加入会话智能体选择
- 底部加入模型 + 深度思考
- 移除右栏中的智能体组选择与顶部状态组
- 改 `ConversationPanelHeader`，不再继续把组信息当页头副标题

### 第 4 步：左栏连续化

- 重写 `ResourceManagerPanel` 滚动模型
- 删除左栏无关设置按钮
- 统一对象面板内容壳

### 第 5 步：设置页补工具展示

- 在 `ToolStrategySettingsPanel` 增加工具展示偏好
- 默认概览
- 可切细节
- 移除会话栏组件级的临时 tool detail toggle 逻辑

### 第 6 步：focused test / golden / 打包验证

- 会话栏布局 focused test
- 左栏高度压缩回归
- 工作台整页 golden
- Windows 打包

---

## 13. 需要新增或修改的测试

### 需要修改

- `apps/novel_agent_app/test/conversation_sidebar_test.dart`
  - 取消“右栏选择智能体组”的旧断言
  - 增加“右栏顶部选择组内智能体”的新断言
  - 增加“模型与深度思考位于输入区下方”的新断言
- `project_agent_group_workspace_view_data_service` 相关测试
  - 更新旧文案断言
- `workbench_workspace_shell_view_data_service` 相关测试
  - 防止项目级组信息被会话级智能体覆盖

### 需要新增

- `conversation_agent_selector_view_data_service_test.dart`
- `workbench_left_sidebar_compact_height_test.dart`
- `tool_preview_settings_test.dart`

### 需要更新 golden

- 右栏会话区
- 工作台三栏整页

---

## 14. 最后结论

这次的问题本质不是几个控件太大太小，而是四个概念没有分层：

1. 项目默认智能体组
2. 当前会话使用的组内智能体
3. 当前发送使用的模型
4. 当前模型是否开启深度思考

当前实现把它们混在了一处，所以无论怎么微调都会继续显得不合理。

正确演化方向是：

- **项目级基线回项目面板**
- **会话级智能体留右栏顶部**
- **模型级参数收到底部输入区**
- **工具概览退出主界面，转入设置偏好**
- **左栏改成连续对象面板，而不是三段硬拼**

这份文档可以直接作为下一轮任务拆分的分析底稿。
