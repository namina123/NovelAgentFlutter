# NovelAgentFlutter 工作台左右栏重画任务顺序文档

最后更新：2026-05-29

关联文档：

- `docs/workbench-sidebars-relayout-analysis-2026-05-29.md`
- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`

---

## 1. 这份任务文档解决什么

这不是旧 `workbench-recovery` 链的继续，而是一条新的专项任务链，专门解决这批问题：

1. 右栏仍把项目级、会话级、模型级状态混在一起
2. 智能体组虽然应退出右栏，但右栏顶部仍需要允许选择“当前项目组内的智能体”
3. 深度思考的位置和归属不对
4. 工具概览不应常驻主界面，但必须保留在设置里
5. 左栏在高度变化时仍有明显割裂感
6. 一些旧投影、旧文案、旧局部状态会和新设计打架

这条链的目标不是“小修小补”，而是把左右栏正式重构成：

- 层级清楚
- 状态归属清楚
- UI 更轻更稳
- 可继续为 CLI 收口
- 结构上可长期演化

---

## 2. 必须遵守的总规则

后续每个 session 都必须遵守这些规则：

1. 每次只完成一个具体任务
2. 如果上个会话停在半截，先收口，不开下一轮
3. 每个任务都必须控制在单次会话可完成的量级
   - 目标改动量：`300 ~ 1800` 行
   - 尽量不要超过 `2000` 行有效改动
4. 永远先收合同、投影、持久化，再动 UI 壳
5. 不允许把新逻辑重新堆回这些重文件：
   - `WorkbenchConversationController`
   - `ConversationSidebar`
   - `WorkbenchWorkspaceController`
   - `WorkbenchNavigationSidebar`
   - `WorkbenchPage`
6. 尽量新增小而清楚的模型、service、widget
7. 不允许让“项目级智能体组”和“会话级当前智能体”再次混成一个模型
8. 不允许做“UI 看起来切了，但请求实际上没切”的假功能
9. 合适时补 focused test，不要等最后一轮才发现链路没接通
10. 除非任务明确要求，否则不要顺手开下一轮

---

## 3. 这条链的总目标

这条链最终要达成的是：

**把工作台左右栏从“调试式混合面板”重构成正式的会话协作界面：项目级归项目、会话级归会话、模型级归发送区、设置级归设置页。**

---

## 4. 建议推进顺序

这次按 6 条轨道推进，但顺序固定：

1. `会话智能体合同轨`
2. `opening projection / 持久化轨`
3. `发送链真实生效轨`
4. `右栏结构重画轨`
5. `左栏连续化轨`
6. `设置 / 测试 / 打包轨`

其中：

- 先做结构与数据合同
- 再做 UI
- 最后做回归、截图、打包

---

## 5. Session 列表

---

## 5.1 Session SR-01：会话级智能体选择合同落地

### 本轮目标

先把“当前项目组内的当前会话智能体”变成正式概念，而不是 UI 临时猜测。

### 必须完成

1. 新增会话级智能体选择专用模型：
   - `conversation_agent_selector_view_data.dart`
2. 新增 opening 层的组内成员摘要模型：
   - `opening_agent_member_summary.dart`
3. 扩展：
   - `OpeningSessionProjection`
   - 增加 `availableAgentSummaries`
4. 修改：
   - `ConversationActionHandler`
   - 新增 `onConversationAgentSelected(String agentId)`

### 本轮不要做

- 不改右栏 UI
- 不改发送逻辑
- 不改左栏

### 本轮重点拆耦

- 项目级 group selector
- 会话级 agent selector
- opening projection 成员摘要

### 完成判定

- “项目默认智能体组”与“当前会话智能体”已经是两个正式合同
- 后续 UI 不需要再复用旧 `ConversationGroupSelectorViewData`

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-01 执行。只做“会话级智能体选择合同落地”：新增 conversation_agent_selector_view_data.dart、opening_agent_member_summary.dart，扩展 OpeningSessionProjection 增加 availableAgentSummaries，并在 ConversationActionHandler 增加 onConversationAgentSelected(String agentId)。不要改 UI，不要改发送逻辑，不开启下一任务。注意解耦合、单一职责，不要把会话级智能体选择继续塞回 ConversationGroupSelectorViewData。
```

---

## 5.2 Session SR-02：opening projection 组内成员解析接通

### 本轮目标

把当前组选中的全部成员真正从 projection 层解析出来，不能只停留在“主智能体摘要”。

### 必须完成

1. 重构：
   - `project_opening_session_projection_service.dart`
2. 让当前组选中结果除了 `currentPrimaryAgentSummary` 外，还能产出：
   - `availableAgentSummaries`
3. 成员摘要至少包含：
   - `agentId`
   - `displayName`
   - `role`
   - `isPrimary`
   - `thinkingSupported`
   - `description`
4. 补 focused test，覆盖：
   - 正常组成员列表
   - 无主智能体时的回退
   - 当前组切换后的成员变化

### 本轮不要做

- 不改 controller
- 不改右栏 widget

### 本轮重点拆耦

- opening projection 构建
- 组成员解析
- 主智能体摘要与全部成员摘要分层

### 完成判定

- 当前组成员列表已经是 projection 的正式输出
- UI 不需要自己猜 agent group member

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-02 执行。只做“opening projection 组内成员解析接通”：重构 project_opening_session_projection_service.dart，让 OpeningSessionProjection 正式输出 availableAgentSummaries，而不是只有 currentPrimaryAgentSummary。补 focused test，不改 controller，不改右栏 widget，不开启下一任务。
```

---

## 5.3 Session SR-03：会话智能体选择 view-data service 与映射接通

### 本轮目标

把“当前组选哪个智能体用于当前会话”的恢复、回退、显示逻辑收口到 service，不散落到 widget。

### 必须完成

1. 新增：
   - `conversation_agent_selector_view_data_service.dart`
2. 规则至少包括：
   - 优先读取已保存的 `selected_conversation_agent_id`
   - 若该 agent 不再可用，回退当前组主智能体
   - 若 projection 未就绪，给稳定 fallback 文案
3. 扩展：
   - `WorkbenchViewData`
   - `WorkbenchConversationViewData`
   - `WorkbenchPaneViewDataMapperService`
4. 让右栏会话 view-data 能拿到：
   - `agentSelector`

### 本轮不要做

- 不改右栏布局
- 不改发送请求逻辑

### 本轮重点拆耦

- 选择恢复逻辑
- fallback 逻辑
- view-data 映射链

### 完成判定

- 当前会话智能体显示链已经完整，但还未落到 UI
- widget 后续只消费正式 `agentSelector`

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-03 执行。只做“会话智能体选择 view-data service 与映射接通”：新增 conversation_agent_selector_view_data_service.dart，收口 selected_conversation_agent_id 的恢复、回退、fallback 逻辑，并扩展 WorkbenchViewData / WorkbenchConversationViewData / WorkbenchPaneViewDataMapperService 让右栏拿到正式 agentSelector。不改右栏布局，不改发送请求链，不开启下一任务。
```

---

## 5.4 Session SR-04：工作台快照持久化接入当前会话智能体

### 本轮目标

让当前项目当前会话智能体选择真正可记忆、可恢复。

### 必须完成

1. 扩展：
   - `WorkbenchWorkspaceController`
2. 更新：
   - `restoreWorkbenchSnapshot`
   - `_persistWorkbenchSnapshot`
3. 在 `extraSettings.workbench_state` 中正式接入：
   - `selected_conversation_agent_id`
4. 保持旧字段不被破坏：
   - `project_root_path`
   - `active_document_path`
   - `expanded_directories`
5. 补 focused test，覆盖：
   - 保存
   - 重启恢复
   - 当前项目变化时不串项目

### 本轮不要做

- 不改右栏 UI
- 不改发送链

### 本轮重点拆耦

- 工作台快照结构
- 项目作用域恢复
- 会话选择偏好持久化

### 完成判定

- 当前会话智能体选择能稳定恢复
- 不污染全局模型设置、不污染智能体组定义

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-04 执行。只做“工作台快照持久化接入当前会话智能体”：扩展 WorkbenchWorkspaceController 的 restoreWorkbenchSnapshot 和 _persistWorkbenchSnapshot，把 selected_conversation_agent_id 正式接入 extraSettings.workbench_state，并补 focused test。不要改 UI，不要改发送链，不开启下一任务。
```

---

## 5.5 Session SR-05：发送链真实接入当前会话智能体

### 本轮目标

防止出现“UI 选了会话智能体，实际请求还是主智能体”的假切换。

### 必须完成

1. 重构：
   - `WorkbenchConversationController`
2. 新增：
   - `onConversationAgentSelected`
3. 发送请求时，优先把：
   - `selected_conversation_agent_id`
   带入请求上下文或运行参数
4. 回退策略：
   - 若无当前选择，回退 `currentPrimaryAgentSummary`
5. 补 focused test，至少覆盖：
   - 当前会话智能体已选时发送
   - 当前会话智能体失效时回退
   - UI 切换后 controller 真实使用新 agent id

### 本轮不要做

- 不重画右栏
- 不改左栏

### 本轮重点拆耦

- UI 选择动作
- controller 当前会话智能体状态
- 请求上下文拼装

### 完成判定

- 当前会话智能体切换已经不是假功能
- 后续右栏 UI 可以安全接入

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-05 执行。只做“发送链真实接入当前会话智能体”：重构 WorkbenchConversationController，新增 onConversationAgentSelected，并让发送请求时优先使用 selected_conversation_agent_id，失效时回退 currentPrimaryAgentSummary。补 focused test，不重画右栏，不开启下一任务。
```

---

## 5.6 Session SR-06：项目级投影与会话级投影去打架

### 本轮目标

把旧的误导投影和旧文案清掉，避免右栏刚改好，左栏和项目浮层又把旧语义带回来。

### 必须完成

1. 审查并重构：
   - `workbench_workspace_shell_view_data_service.dart`
   - `project_agent_group_workspace_view_data_service.dart`
   - 必要时 `project_agent_group_panel_view_data_service.dart`
2. 保证：
   - 项目级摘要继续表达默认智能体组
   - 会话级摘要表达当前会话智能体
   - 两者不互相回填
3. 更新旧文案，例如：
   - “会话栏里的组入口只做快速切换”
   必须改掉
4. 补 focused test，防止项目级组信息被会话级选择覆盖

### 本轮不要做

- 不重画 widget
- 不改 settings

### 本轮重点拆耦

- 左栏项目摘要投影
- 项目组配置浮层文案
- 会话级与项目级事实源分离

### 完成判定

- 旧文案和旧投影不再与新设计冲突
- 右栏后续重画时不会被壳层摘要拖回去

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-06 执行。只做“项目级投影与会话级投影去打架”：重构 workbench_workspace_shell_view_data_service.dart、project_agent_group_workspace_view_data_service.dart 等，把项目级默认组和会话级当前智能体彻底分开，并更新旧文案。补 focused test，不改 widget 壳，不开启下一任务。
```

---

## 5.7 Session SR-07：右栏顶部会话智能体条落位

### 本轮目标

先把右栏顶部结构改对，让“当前会话智能体”出现在正确位置，同时把组从右栏顶部语义里清出去。

### 必须完成

1. 新增或重构：
   - `conversation_agent_header_strip.dart`
   - `conversation_panel_header.dart`
2. 右栏顶部只保留：
   - 会话标题
   - 历史 / 新会话
   - 当前项目组内的会话智能体选择
3. 删除或移除页头中的项目级组副标题表达
4. 不允许顶部继续出现项目级组切换入口
5. 更新：
   - `conversation_sidebar_test.dart`

### 本轮不要做

- 不下沉模型和思考开关
- 不处理左栏

### 本轮重点拆耦

- 顶部会话头
- 顶部会话智能体选择
- 项目级组信息退出页头

### 完成判定

- 右栏顶部已经表达“当前会话智能体”
- 不再表达“当前项目默认智能体组”

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-07 执行。只做“右栏顶部会话智能体条落位”：新增或重构 conversation_agent_header_strip.dart 和 conversation_panel_header.dart，让右栏顶部只保留会话标题、历史/新会话和当前项目组内的会话智能体选择，移除项目级组副标题与组入口。更新 conversation_sidebar_test.dart，不开启下一任务。
```

---

## 5.8 Session SR-08：右栏底部发送配置条重画

### 本轮目标

把模型选择和深度思考收到底部输入区附近，回到正确归属。

### 必须完成

1. 重构：
   - `conversation_composer_panel.dart`
   - `conversation_input_dock.dart`
   - `conversation_input_action_row.dart`
2. 新增或替代：
   - `conversation_send_config_bar.dart`
3. 处理：
   - `conversation_model_strip.dart`
   - `conversation_primary_agent_bar.dart`
4. 底部区域至少承接：
   - 输入框
   - 发送按钮
   - 模型选择
   - 深度思考开关
5. 保持：
   - 深度思考仍写回共享 `model_settings`

### 本轮不要做

- 不移除工具状态 chips
- 不改左栏

### 本轮重点拆耦

- 输入坞布局装配
- 发送按钮行
- 模型/深度思考配置条

### 完成判定

- 模型与深度思考已经贴近输入区
- 深度思考不再挂在“主智能体条”上

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-08 执行。只做“右栏底部发送配置条重画”：重构 conversation_composer_panel.dart、conversation_input_dock.dart、conversation_input_action_row.dart，并新增或替代 conversation_send_config_bar.dart，让模型选择和深度思考位于输入区附近，同时保持深度思考仍写回共享 model_settings。不移除工具状态 chips，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增 `conversation_send_config_bar.dart`
2. 已把模型选择与深度思考下沉到输入区附近
3. 已将深度思考从 `ConversationPrimaryAgentBar` 中移出，主智能体条改回纯只读摘要职责
4. 已移除底部发送区中的项目级智能体组选择入口
5. 已验证：
   - `flutter analyze`（SR-08 相关 widget / test 文件）
   - `flutter test test/conversation_input_dock_test.dart`
   - `flutter test test/conversation_sidebar_test.dart`

---

## 5.9 Session SR-09：右栏空态与 opening 补充块去项目级配置化

### 本轮目标

把右栏空态补充块从“项目配置入口”改成真正的会话引导补充。

### 必须完成

1. 重构：
   - `opening_session_panel.dart`
   - `conversation_empty_state_panel.dart`
   - `workflow_guide_card.dart`
2. 右栏空态补充块只允许：
   - 一句短提示
   - 补充说明
   - 必要时只读状态
3. 移除：
   - 项目级智能体组选择职责
   - 不可用组原因的主界面配置入口语义
4. 项目级组配置入口回到项目面板/项目组配置区

### 本轮不要做

- 不改左栏连续化
- 不改 tool preview 设置

### 本轮重点拆耦

- 空态引导
- opening 补充信息
- 项目级组配置入口

### 完成判定

- 右栏空态不再承担项目级正式配置
- opening 补充块成为轻提示，不是配置站

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-09 执行。只做“右栏空态与 opening 补充块去项目级配置化”：重构 opening_session_panel.dart、conversation_empty_state_panel.dart、workflow_guide_card.dart，让右栏空态补充块只保留轻提示和只读状态，移除项目级智能体组选择职责。不要改左栏，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已将 `OpeningSessionPanel` 改为只读项目状态补充块
2. 已移除右栏空态中的项目级智能体组选择器与不可用组展开入口
3. 已把补充块说明样式抽到 `conversation_supplement_section.dart`
4. 已让 `ConversationEmptyStatePanel` / `WorkflowGuideCard` 统一通过补充说明区承接 opening 补充块
5. 已验证：
   - `flutter analyze`（SR-09 相关 widget / test 文件）
   - `flutter test test/conversation_sidebar_test.dart`

---

## 5.10 Session SR-10：工具概览退出主界面并转入设置偏好

### 本轮目标

把现在这个局部的、临时的、主界面常驻的工具概览处理方式正式收口。

### 必须完成

1. 重构：
   - `conversation_panel_status_group.dart`
   - `conversation_status_summary_view_data_service.dart`
   - `conversation_sidebar.dart`
2. 移除右栏主界面常驻：
   - 上下文 / 工具 / 运行 chips 组
3. 新增设置级展示偏好：
   - `extraSettings.workbench_ui.tool_preview_mode`
4. 在：
   - `tool_strategy_settings_panel.dart`
   中补“工具展示”小节
5. 默认模式：
   - `compact`
6. 移除局部 `_toolVisibility` 之类的临时页面状态

### 本轮不要做

- 不重画左栏
- 不改发送链

### 本轮重点拆耦

- 工具展示偏好
- 会话主界面展示
- 设置与执行策略分层

### 完成判定

- 工具概览不再常驻主界面
- 设置中有稳定入口
- 默认非细节模式

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-10 执行。只做“工具概览退出主界面并转入设置偏好”：移除 conversation_panel_status_group.dart 在主界面的常驻位，删除 conversation_sidebar.dart 里的局部 _toolVisibility 状态，并在 tool_strategy_settings_panel.dart 中新增 tool_preview_mode 设置，默认 compact。不要改左栏，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已移除右栏主界面的上下文 / 工具 / 运行常驻 chips
2. 已删除 `ConversationSidebar` 中的局部 `_toolVisibility` 页面状态
3. 已将 `tool_preview_mode` 接入 `extraSettings.workbench_ui.tool_preview_mode`
4. 已在 `tool_strategy_settings_panel.dart` 增加“工具展示”设置小节，默认 `compact`
5. 已让 transcript 工具细节展示改为跟随保存后的全局偏好
6. 已验证：
   - `flutter analyze`（SR-10 相关文件）
   - `flutter test test/conversation_status_summary_view_data_service_test.dart test/tool_strategy_settings_panel_test.dart`
   - `flutter test test/conversation_sidebar_test.dart`

---

## 5.11 Session SR-11：左栏内容壳连续化

### 本轮目标

先把左栏整体壳收成连续内容区，解决“对象头 / 切换条 / 内容区像三套系统”的问题。

### 必须完成

1. 新增：
   - `workbench_object_panel_body.dart`
   或等价统一内容壳
2. 重构：
   - `workbench_navigation_sidebar.dart`
   - `workbench_side_panel_host.dart`
3. 让左栏固定成：
   - 薄对象头
   - 紧凑对象切换
   - 单一连续内容区
4. 弱化没有必要的分栏线和断裂节奏

### 本轮不要做

- 不改资源树具体滚动模型
- 不顺手改右栏

### 本轮重点拆耦

- 左栏壳层布局
- 对象头与对象切换
- 内容宿主统一壳

### 完成判定

- 左栏整体观感已经连续
- 各对象面板不再像被塞进三段不同容器

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-11 执行。只做“左栏内容壳连续化”：新增 workbench_object_panel_body.dart 或等价统一内容壳，重构 workbench_navigation_sidebar.dart 和 workbench_side_panel_host.dart，让左栏固定成薄对象头、紧凑对象切换和单一连续内容区。不要改资源树具体滚动模型，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增 `workbench_object_panel_body.dart` 作为左栏统一内容壳
2. 已重构 `workbench_side_panel_host.dart`，让三个对象面板统一挂到同一内容宿主中
3. 已重构 `workbench_navigation_sidebar.dart`，收成薄对象头、紧凑对象切换和连续内容区
4. 已弱化左栏外侧与内容区之间的硬分割线与断裂节奏
5. 已验证：
   - `flutter analyze`（SR-11 相关文件）
   - `flutter test test/workbench_navigation_sidebar_test.dart test/resource_manager_panel_test.dart`

---

## 5.12 Session SR-12：文件对象面板单一滚动模型

### 本轮目标

把左栏文件对象面板从“两套滚动语义 + 百分比树高估算”改成单一滚动模型。

### 必须完成

1. 重构：
   - `resource_manager_panel.dart`
   - `resource_manager_header.dart`
   - 必要时 `resource_panel_section.dart`
2. 移除：
   - `useScrollableLayout`
   - `treeHeight = constraints.maxHeight * 0.38`
   - 整块滚 / 树单独滚的双模型
3. 改成：
   - 单一 `CustomScrollView` / sliver
   - 文件工具条作为树前导内容
   - 树成为真正主内容
4. 删除文件面板头部错误的模型设置按钮
5. 补 focused test，覆盖窄高布局

### 本轮不要做

- 不重构项目面板
- 不改右栏

### 本轮重点拆耦

- 文件面板滚动模型
- 文件工具条
- 资源树主内容地位

### 完成判定

- 左栏高度压缩时不再突然切换滚动语义
- 文件对象面板不再有明显割裂感

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-12 执行。只做“文件对象面板单一滚动模型”：重构 resource_manager_panel.dart 和 resource_manager_header.dart，移除 useScrollableLayout、treeHeight 百分比估算和双滚动语义，改成单一 CustomScrollView/sliver，并删除文件面板头部错误的模型设置按钮。补 focused test，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已将 `resource_manager_panel.dart` 改为单一 `CustomScrollView` 滚动模型
2. 已移除 `useScrollableLayout`、`treeHeight` 百分比估算与整块滚 / 树单独滚双模型
3. 已把文件工具条改为资源树前导内容，资源树成为主内容
4. 已删除 `resource_manager_header.dart` 中错误的模型设置按钮
5. 已让 `resource_tree_card.dart` 支持嵌入父滚动而不再自带第二套滚动语义
6. 已验证：
   - `flutter analyze`（SR-12 相关文件）
   - `flutter test test/resource_manager_panel_test.dart test/resource_tree_card_test.dart`

---

## 5.13 Session SR-13：会话栏与左栏综合回归测试

### 本轮目标

在结构改完后，先做一轮正式回归，确认左右栏新链路不是表面成立。

### 必须完成

1. 更新或新增 focused test：
   - `conversation_sidebar_test.dart`
   - `conversation_agent_selector_view_data_service_test.dart`
   - `workbench_left_sidebar_compact_height_test.dart`
   - `tool_preview_settings_test.dart`
   - 项目组文案相关测试
2. 至少验证：
   - 右栏顶部是组内智能体选择，不是组选择
   - 模型和深度思考在输入区附近
   - 工具概览不再常驻主界面
   - 左栏窄高布局不割裂
   - 项目级组信息未被会话级智能体覆盖

### 本轮不要做

- 不补新需求
- 不做视觉大修

### 本轮重点拆耦

- focused 测试覆盖点
- 新旧语义边界回归

### 完成判定

- 左右栏新结构已有自动化回归兜底
- 不再靠肉眼和记忆判断是否实现

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-13 执行。只做“会话栏与左栏综合回归测试”：更新 conversation_sidebar_test.dart，并新增/补齐 conversation_agent_selector_view_data_service_test.dart、workbench_left_sidebar_compact_height_test.dart、tool_preview_settings_test.dart 等 focused test，验证右栏顶部是组内智能体选择、模型与深度思考位于输入区附近、工具概览已退出主界面、左栏窄高布局不割裂。不要补新需求，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已补强 `conversation_agent_selector_view_data_service_test.dart`
   - 覆盖单智能体时不可切换
   - 覆盖无角色时 `headerSubtitle` 为空、描述回退到成员说明
2. 已新增 `workbench_left_sidebar_compact_height_test.dart`
   - 覆盖左栏窄高布局下连续内容壳仍只有一层
   - 覆盖文件面板仍保持单一 `CustomScrollView`
   - 覆盖文件 / 项目 / 长任务三类对象切换仍正常
3. 已新增 `tool_preview_settings_test.dart`
   - 覆盖已保存 `detail` 模式可稳定回显并保存
   - 覆盖非法值会归一化回 `compact`
4. 已更新 `conversation_sidebar_test.dart`
   - 覆盖“当前会话智能体”和“项目智能体组基线”同时存在且语义分离
5. 已更新项目级文案边界测试
   - `workbench_project_panel_test.dart` 明确断言项目面板不混入会话级智能体文案
6. 已验证：
   - `flutter analyze`
     - `test/conversation_agent_selector_view_data_service_test.dart`
     - `test/conversation_sidebar_test.dart`
     - `test/workbench_left_sidebar_compact_height_test.dart`
     - `test/tool_preview_settings_test.dart`
     - `test/workbench_project_panel_test.dart`
   - `flutter test`
     - `test/conversation_agent_selector_view_data_service_test.dart`
     - `test/tool_preview_settings_test.dart`
     - `test/workbench_left_sidebar_compact_height_test.dart`
     - `test/conversation_sidebar_test.dart`
     - `test/workbench_project_panel_test.dart`
     - `test/workbench_navigation_sidebar_test.dart`
     - `test/resource_manager_panel_test.dart`
     - `test/project_agent_group_workspace_view_data_service_test.dart`

---

## 5.14 Session SR-14：截图核验、文档回填与 Windows 打包

### 本轮目标

在所有左右栏任务完成后，做最后一轮视觉与产物核验。

### 必须完成

1. 做截图核验，至少看：
   - 桌面三栏
   - 左栏较窄高度
   - 右栏空态
   - 右栏有会话状态
2. 回填文档：
   - 完成记录
   - 残留问题
   - 是否还有待后续优化的视觉项
3. 打包 Windows 版本
4. 明确告诉用户：
   - 这轮是“左右栏重画链”的完成状态
   - 是否还有残余但不阻塞的优化项

### 本轮不要做

- 不顺手再改业务合同
- 不加新入口

### 本轮重点拆耦

- 视觉核验
- 产物打包
- 文档闭环

### 完成判定

- 左右栏重画链有正式结束点
- 用户可以直接拿到新包体验

### 直接可用提示词

```text
按 docs/workbench-sidebars-relayout-session-order-2026-05-29.md 的 Session SR-14 执行。只做“截图核验、文档回填与 Windows 打包”：完成桌面三栏、左栏窄高、右栏空态和会话态截图核验，回填完成记录与残留问题，然后打包 Windows 版本。不要顺手改新需求，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增 `test/workbench_sr14_visual_regression_test.dart`
   - 用最终回归壳直接产出 `SR-14` 视觉核验截图
2. 已生成并校验以下截图产物：
   - `artifacts/workbench_sr14_screenshots/sr14_workbench_desktop_three_pane.png`
   - `artifacts/workbench_sr14_screenshots/sr14_left_sidebar_compact_height.png`
   - `artifacts/workbench_sr14_screenshots/sr14_conversation_empty_state.png`
   - `artifacts/workbench_sr14_screenshots/sr14_conversation_active_state.png`
3. 已验证截图链路：
   - `flutter analyze test/workbench_sr14_visual_regression_test.dart`
   - `flutter test test/workbench_sr14_visual_regression_test.dart --update-goldens`
   - `flutter test test/workbench_sr14_visual_regression_test.dart`
4. 已完成 Windows release 构建：
   - `flutter build windows --release`
   - 主产物：`apps/novel_agent_app/build/windows/x64/runner/Release/novel_agent_app.exe`
5. 已完成 Windows 包归档：
   - `artifacts/windows/novel_agent_app-windows-release-2026-05-29-037ee48-sidebars-relayout.zip`

### 残留问题（不阻塞本链收口）

1. 本轮截图核验基于 Flutter widget 回归壳生成，已能稳定验证三栏、左栏窄高、右栏空态和会话态结构；但它不覆盖原生 Windows 窗口边框、系统缩放和真实桌面窗口管理层行为。
2. 若后续要继续做“发版前体验验收”，建议单独补一轮真实 Windows 运行态人工核看，而不是把它重新揉回当前这条重画链。

---

## 6. 使用方式

接下来建议统一使用下面这段话继续推进：

```text
根据目前的进度和文档：docs/workbench-sidebars-relayout-session-order-2026-05-29.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体的任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务，如果已经确认可以开启下一轮任务，那么可以直接开始，你需要直接识别相关的提示词、任务内容、任务约束等等并出色地完成。注意解耦合、单一职责、不要让单文件过重，必要时补 focused test。开始吧。
```

---

## 7. 最后一句定义

这条任务链最终不是为了“把右栏摆顺一点”，而是为了：

**把工作台真正收口为一个项目级、会话级、模型级、设置级边界清楚的正式前端。**
