# NovelAgentFlutter 输入区与智能体面板美学重构任务顺序文档

最后更新：2026-05-29

关联文档：

- `docs/workbench-sidebars-relayout-session-order-2026-05-29.md`
- 本轮用户反馈截图（线程内）

---

## 1. 这份任务文档解决什么

上一条 `workbench-sidebars-relayout` 链已经完成结构收口，但从真实界面体验看，仍有一批明显“能用但很丑”的问题：

1. 输入区层级不对，发送、模型、深度思考之间像三块拼起来的调试条
2. 深度思考的控件形态和位置都不符合人类直觉
3. 三个主栏之间还有空隙，不是纯分割线
4. 智能体组入口过深，用户需要绕到项目动作里
5. 智能体组面板中“可选 / 不可选”是两套视觉语言，不统一，也不高级
6. 不可用项折叠块样式很糙，像临时排错面板

这条链的目标不是修补，而是把这批问题作为一组完整的“美学与交互一致性问题”来收口。

---

## 2. 本轮为什么不直接一口气实现

这次不适合在一个会话里硬做完，原因很明确：

1. **输入区改动不是单一 widget 微调**
   - 会牵连：
     - `conversation_input_dock.dart`
     - `conversation_send_config_bar.dart`
     - `conversation_input_action_row.dart`
     - `conversation_composer_text_field.dart`
     - 以及相关测试
2. **三栏无缝化会动桌面骨架**
   - 会牵连：
     - `workbench_desktop_surface.dart`
     - `resizable_workbench_layout.dart`
     - `pane_resize_divider.dart`
     - `workbench_pane_layout_policy.dart`
3. **智能体入口上移意味着左栏对象体系要扩展**
   - 这不是“加一个按钮”那么简单，而是要决定：
     - 它是否成为左栏一级对象
     - 如何与现有 `文件 / 项目 / 长任务` 并列
     - 不可用项如何共用同一种卡片组件但带禁用态

如果现在把这三条链混着做，很容易出现：

- 输入区刚变顺眼，三栏骨架又被拖坏
- 智能体入口上移后，合同和命名继续混乱
- 不可用项只是换个颜色，但结构依旧丑

因此这轮只产出新的顺序文档，后续按链路逐段推进。

---

## 3. 本轮先冻结的设计决策

为了避免后续每轮又反复猜用户意图，这里先把本轮需求冻结成明确设计：

### 3.1 输入区

1. 模型选择放在输入框**上方**
2. 模型条与输入框距离更近
3. 模型条保留分割线，但更轻更贴近输入框
4. 发送按钮**嵌入输入框右下角**
5. 发送按钮允许占一整横行的底部操作位，但**不再额外有一条分割线**
6. 正在处理时，发送按钮原位切成停止按钮
7. 深度思考位于发送按钮左边
8. 深度思考不是传统系统 `Switch` 视觉，而是更像工作台内联开关：
   - 开启：蓝色高亮
   - 关闭：白色 / 中性

### 3.2 三栏桌面骨架

1. 左栏 / 正文栏 / 会话栏之间**不能再有视觉空隙**
2. 只保留纯分割线
3. 仍保留拖拽改宽
4. 分割线的视觉宽度应接近 1px 线
5. 拖拽命中区可以比视觉线宽，但命中区不能显出额外空隙

### 3.3 智能体入口

这里采用一个明确解释：

**“智能体按钮显示在左侧功能栏” = 成为左栏一级对象，与 `文件 / 项目 / 长任务` 同级，而不是藏在项目动作列表里。**

原因：

1. 这最符合“点进去之后显示条目”的描述
2. 也最符合后续 CLI 收口思路
3. 比“继续塞在项目动作里”更浅、更直接

### 3.4 智能体组列表

1. 可选项与不可选项使用**同一种卡片结构**
2. 不可选项不再是另一套说明块
3. 差异只体现在状态：
   - 可选：高对比、可点击
   - 不可选：灰阶、禁用态、不可点击
4. 不可用项依然折叠，但折叠头与内容样式必须重做
5. 折叠后展开的禁用项列表，仍然是“禁用卡片列表”，不是纯文本堆积

---

## 4. 总规则

后续每个 session 必须遵守：

1. 每次只完成一个具体任务
2. 如果上轮卡在半截，先收口
3. 先做结构与复用组件，再改装配层
4. 不允许把新逻辑继续堆进这些文件：
   - `ConversationSidebar`
   - `WorkbenchPage`
   - `WorkbenchNavigationSidebar`
   - `ProjectAgentGroupOverlay`
5. 优先新增小组件：
   - 输入区子组件
   - 分割线壳组件
   - 智能体组卡片组件
6. 视觉状态与业务含义分离：
   - “是否可选”
   - “是否当前”
   - “是否降级”
   必须是正式字段，不靠 UI 猜
7. 必须补 focused test
8. 视觉核验要有截图产物，不只靠口头说“好看了”

---

## 5. Session 列表

---

## 5.1 Session IA-01：输入区布局合同重排

### 本轮目标

先把输入区结构改对，但不急着美化全部细节。

### 必须完成

1. 重构：
   - `conversation_input_dock.dart`
   - `conversation_send_config_bar.dart`
   - `conversation_input_action_row.dart`
2. 新布局固定为：
   - 顶部：模型条
   - 中部：输入框
   - 底部内联：深度思考 + 发送/停止
3. 删除输入框底部与发送区之间的额外分割线
4. 保留模型条顶部/底部必要边界，但距离输入框更近

### 本轮不要做

- 不改深度思考最终视觉风格
- 不改三栏骨架
- 不改智能体入口

### 本轮重点拆耦

- 模型条
- 输入框主体
- 底部内联操作带

### 完成判定

- 发送/停止已经进入输入框底部语义区域
- 旧的“下方独立动作条”视觉结构消失

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-01 执行。只做输入区布局合同重排：重构 conversation_input_dock.dart、conversation_send_config_bar.dart、conversation_input_action_row.dart，让模型条位于输入框上方、发送/停止与深度思考进入输入框底部内联区域，去掉输入框与发送区之间的分割线。不改三栏骨架，不改智能体入口，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已完成 `ConversationInputDock` 结构重排：
   - 顶部保留 `ConversationSendConfigBar` 作为模型条
   - 中部保留 `ConversationComposerTextField`
   - 底部改为同一输入表面内的 `ConversationInputActionRow`
2. 已移除输入框与发送区之间的独立分割结构，并清掉模型条下方重复边线，只保留模型条自身的贴边分割
3. 已将深度思考入口移入底部内联动作带，但暂时仍沿用现有 `Switch` 视觉
4. 已补 focused test，明确校验：
   - 模型条位于输入框上方
   - 发送动作位于输入框下方
   - 深度思考不再属于 `ConversationSendConfigBar`
5. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_dock.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_send_config_bar.dart`
   - `apps/novel_agent_app/test/conversation_input_dock_test.dart`
   - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
6. 已验证：
   - `dart format lib/features/workbench/presentation/widgets/conversation_input_dock.dart lib/features/workbench/presentation/widgets/conversation_send_config_bar.dart lib/features/workbench/presentation/widgets/conversation_input_action_row.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`
   - `flutter analyze lib/features/workbench/presentation/widgets/conversation_input_dock.dart lib/features/workbench/presentation/widgets/conversation_send_config_bar.dart lib/features/workbench/presentation/widgets/conversation_input_action_row.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`
   - `flutter test test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`

---

## 5.2 Session IA-02：深度思考控件改成工作台内联开关

### 本轮目标

把现在这个默认 `Switch` 视觉彻底换掉。

### 必须完成

1. 新增独立组件，例如：
   - `conversation_reasoning_toggle_chip.dart`
2. 状态规则：
   - 关闭：白色/中性
   - 开启：蓝色高亮
3. 位置固定：
   - 发送按钮左边
4. 处理：
   - `showReasoningToggle`
   - `reasoningEnabled`
   仍然只由能力层与设置层决定

### 本轮不要做

- 不改模型条结构
- 不改三栏布局

### 本轮重点拆耦

- reasoning 控件外观
- reasoning 状态语义
- 输入区装配

### 完成判定

- 不再出现系统默认 `Switch` 风格
- 视觉上像工作台内部状态按钮

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-02 执行。只做深度思考控件重做：新增独立的 conversation_reasoning_toggle_chip.dart，把深度思考改成开启蓝色、关闭白色的工作台内联开关，并固定在发送按钮左边。不要改三栏布局，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增独立组件 `ConversationReasoningToggleChip`
   - 文件：`apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart`
2. 已将 `ConversationInputActionRow` 中的旧 `_InlineReasoningToggle + Switch` 替换为独立 chip 组件
3. 已完成视觉状态收口：
   - 关闭：输入区中性浅底、常规边框、弱对比文字
   - 开启：蓝色高亮底、蓝色边框、反白文字
4. 已保持原有业务合同不变：
   - 仍由 `showReasoningToggle` 控制是否显示
   - 仍由 `reasoningEnabled` 控制开关状态
   - 仍通过 `onReasoningToggleChanged` 回写设置层
5. 已补 focused test，明确校验：
   - 输入区不再出现系统 `Switch`
   - reasoning 入口仍位于发送按钮左侧的内联动作区
   - 关闭态与开启态的 chip 颜色发生预期切换
   - 会话栏点击 chip 后仍能触发 reasoning 状态变更
6. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart`
   - `apps/novel_agent_app/test/conversation_input_dock_test.dart`
   - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
7. 已验证：
   - `dart format lib/features/workbench/presentation/widgets/conversation_input_action_row.dart lib/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`
   - `flutter analyze lib/features/workbench/presentation/widgets/conversation_input_action_row.dart lib/features/workbench/presentation/widgets/conversation_reasoning_toggle_chip.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`
   - `flutter test test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart`

---

## 5.3 Session IA-03：三栏无缝化与细分割线拖拽壳

### 本轮目标

把三栏之间的空隙彻底去掉，同时保留拖拽。

### 必须完成

1. 重构：
   - `workbench_desktop_surface.dart`
   - `resizable_workbench_layout.dart`
   - `pane_resize_divider.dart`
   - `workbench_pane_layout_policy.dart`
2. 视觉规则：
   - 三栏之间无空隙
   - 只剩纯分割线
3. 交互规则：
   - 分割线视觉细
   - 拖拽命中区可宽
   - 但命中区透明，不制造视觉缝

### 本轮不要做

- 不改左栏对象体系
- 不改智能体组卡片

### 本轮重点拆耦

- 桌面总底板
- 拖拽命中壳
- 视觉分割线

### 完成判定

- 三栏从视觉上连成一个整体
- 仍可正常拖拽改宽

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-03 执行。只做三栏无缝化：重构 workbench_desktop_surface.dart、resizable_workbench_layout.dart、pane_resize_divider.dart、workbench_pane_layout_policy.dart，去掉三栏间空隙，只保留细分割线，同时保持拖拽改宽功能。不要改智能体入口，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已完成三栏分隔策略收口：
   - `WorkbenchPaneLayoutPolicy.dividerWidth` 改为 `1`
   - 新增 `dividerHitWidth = 12`
   - 视觉宽度与拖拽命中宽度正式拆分
2. 已重构 `PaneResizeDivider`：
   - 布局中只占用 1px 可见分割线宽度
   - 通过溢出的透明 hit area 保留更宽拖拽区域
   - 悬停时只增强线条颜色，不再生成整条实色“缝”
3. 已重构 `WorkbenchPaneShell`：
   - 内侧边缘取消圆角
   - 只保留左右最外侧的外轮廓圆角
   - 避免三栏交界处顶部和底部出现弧口裂缝
4. 已审查 `WorkbenchDesktopSurface`
   - 当前外层只承担整体底板与外边距
   - 本轮无需继续修改即可满足“三栏之间只保留纯分割线”的目标
5. 已补 focused test，明确校验：
   - 三栏结构仍然存在
   - divider 可见宽度为 1px
   - divider hit area 宽度大于可见宽度
   - 左栏、divider、正文栏在桌面布局中首尾紧贴
6. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/layout/workbench_pane_layout_policy.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/pane_resize_divider.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_pane_shell.dart`
   - `apps/novel_agent_app/test/workbench_page_desktop_layout_test.dart`
7. 已验证：
   - `dart format lib/features/workbench/presentation/layout/workbench_pane_layout_policy.dart lib/features/workbench/presentation/widgets/pane_resize_divider.dart lib/features/workbench/presentation/widgets/workbench_pane_shell.dart test/workbench_page_desktop_layout_test.dart`
   - `flutter analyze lib/features/workbench/presentation/layout/workbench_pane_layout_policy.dart lib/features/workbench/presentation/widgets/pane_resize_divider.dart lib/features/workbench/presentation/widgets/workbench_pane_shell.dart test/workbench_page_desktop_layout_test.dart`
   - `flutter test test/workbench_page_desktop_layout_test.dart`

---

## 5.4 Session IA-04：左栏新增一级“智能体”对象入口

### 本轮目标

把智能体入口从项目动作里上移为左栏一级对象。

### 必须完成

1. 扩展：
   - `WorkbenchNavigationPanelId`
   - `WorkbenchSidePanelContractService`
2. 新增：
   - `workbench_agent_panel.dart`
   或等价专用面板
3. 更新：
   - `workbench_activity_rail.dart`
   - `workbench_side_panel_host.dart`
4. 入口语义：
   - 与 `文件 / 项目 / 长任务` 同级
   - 不再依赖项目动作列表才能进入

### 本轮不要做

- 不重做不可用项卡片细节
- 不做最终视觉 polish

### 本轮重点拆耦

- 左栏对象体系
- 智能体面板宿主
- 项目级智能体配置入口语义

### 完成判定

- 智能体成为左栏一级对象
- 项目面板不再承担唯一入口职责

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-04 执行。只做左栏一级“智能体”对象入口：扩展 WorkbenchNavigationPanelId、WorkbenchSidePanelContractService，并新增 workbench_agent_panel.dart 或等价面板，让智能体成为与 文件/项目/长任务 同级的左栏对象入口。不重做不可用项样式，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已扩展左栏对象体系：
   - `WorkbenchNavigationPanelId` 新增 `agent`
   - `WorkbenchSidePanelContractService` 新增“智能体”一级对象合同
   - 新增正式 entry kind：`conversationAgentSummary`
2. 已新增独立智能体面板链路：
   - `WorkbenchAgentPanelViewData`
   - `WorkbenchAgentPanelViewDataService`
   - `WorkbenchAgentPanel`
3. 已完成宿主接线：
   - `WorkbenchActivityRail` 新增“智能体”按钮与图标
   - `WorkbenchNavigationSidebar` 组装 agent panel view data
   - `WorkbenchSidePanelHost` 新增智能体面板分支
4. 已将“智能体”收口为左栏一级对象入口，而不是继续依赖项目面板中的单一动作入口
5. 当前智能体面板职责已明确为：
   - 当前会话智能体只读摘要
   - 当前项目智能体组基线摘要
   - 项目级智能体组配置入口
6. 本轮刻意未做：
   - 没有重做不可用项卡片
   - 没有把当前会话智能体选择器从右栏顶部搬走
   - 没有开启智能体组列表视觉重构
7. 已补 focused test，明确校验：
   - side panel contract 现已稳定包含四个一级对象
   - 左栏可以切到“智能体”面板
   - 智能体面板显示当前会话智能体摘要与项目智能体组入口
   - 点击“项目智能体组”仍会走原有配置动作链路
8. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_navigation_panel_id.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_side_panel_entry_kind.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/workbench/application/services/workbench_side_panel_contract_service.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_activity_rail.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_agent_panel.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart`
   - `apps/novel_agent_app/test/workbench_side_panel_contract_service_test.dart`
   - `apps/novel_agent_app/test/workbench_navigation_sidebar_test.dart`
   - `apps/novel_agent_app/test/workbench_agent_panel_test.dart`
9. 已验证：
   - `dart format lib/features/workbench/presentation/models/workbench_navigation_panel_id.dart lib/features/workbench/presentation/models/workbench_side_panel_entry_kind.dart lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart lib/features/workbench/application/services/workbench_side_panel_contract_service.dart lib/features/workbench/presentation/widgets/workbench_activity_rail.dart lib/features/workbench/presentation/widgets/workbench_agent_panel.dart lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart test/workbench_side_panel_contract_service_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_agent_panel_test.dart`
   - `flutter analyze lib/features/workbench/presentation/models/workbench_navigation_panel_id.dart lib/features/workbench/presentation/models/workbench_side_panel_entry_kind.dart lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart lib/features/workbench/application/services/workbench_side_panel_contract_service.dart lib/features/workbench/presentation/widgets/workbench_activity_rail.dart lib/features/workbench/presentation/widgets/workbench_agent_panel.dart lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart test/workbench_side_panel_contract_service_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_agent_panel_test.dart`
   - `flutter test test/workbench_side_panel_contract_service_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_agent_panel_test.dart`

---

## 5.5 Session IA-05：智能体组列表统一卡片化

### 本轮目标

把“可选 / 不可选”从两套表现收口成一套卡片系统。

### 必须完成

1. 新增共享卡片组件，例如：
   - `agent_group_option_card.dart`
2. 共享字段至少包含：
   - 标题
   - 描述
   - 是否当前
   - 是否可选
   - 是否降级
   - 原因摘要
3. 支持项与不支持项都走同一张卡片
4. 不支持项：
   - 使用禁用态色板
   - 保持与可选项相同结构
   - 明显灰阶/弱对比

### 本轮不要做

- 不做折叠头样式最终 polish
- 不改输入区

### 本轮重点拆耦

- 卡片视觉
- 可选/禁用状态
- 数据映射层

### 完成判定

- 不再出现“支持项是卡片，不支持项是文本堆”的断裂

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-05 执行。只做智能体组列表统一卡片化：新增共享 agent_group_option_card.dart，让可选与不可选项共用同一种卡片结构，不可选项仅通过禁用态颜色和不可点击表达。不要改输入区，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增共享卡片组件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/agent_group_option_card.dart`
2. 已将可选项列表接入共享卡片：
   - `OpeningAgentGroupPicker` 不再自行拼装一套选择项外观
   - 当前组、降级可用、内置开局 等状态都改由共享卡片统一承接
3. 已将不可选项列表接入共享卡片：
   - `OpeningUnsupportedGroupPanel` 展开后不再是纯文本堆叠
   - 现在使用与可选项同一种 `AgentGroupOptionCard`
   - 差异仅通过禁用态颜色、`当前不可用` 状态标签和无点击行为表达
4. 已完成这轮最关键的语义收口：
   - 可选项与不可选项使用同一张卡片结构
   - 共享字段已覆盖：
     - 标题
     - 描述
     - 是否当前
     - 是否可选
     - 是否降级
     - 原因摘要
5. 本轮刻意未做：
   - 没有重做不可用项折叠头最终样式
   - 没有替换 `ExpansionTile`
   - 没有提前进入 `IA-06`
6. 已补 focused test，明确校验：
   - 项目智能体组 overlay 中，可选和不可选项现在都使用 `AgentGroupOptionCard`
   - 可选项点击仍会触发组切换动作
   - 不可选项展示为禁用卡片，但不会触发切换
   - 既有 `conversation_sidebar` 链路在本轮重构后仍然通过
7. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/agent_group_option_card.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_agent_group_picker.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart`
   - `apps/novel_agent_app/test/project_agent_group_overlay_test.dart`
   - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
8. 已验证：
   - `dart format lib/features/workbench/presentation/widgets/agent_group_option_card.dart lib/features/workbench/presentation/widgets/opening_agent_group_picker.dart lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart test/project_agent_group_overlay_test.dart`
   - `flutter analyze lib/features/workbench/presentation/widgets/agent_group_option_card.dart lib/features/workbench/presentation/widgets/opening_agent_group_picker.dart lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart lib/features/workbench/presentation/widgets/project_agent_group_overlay.dart test/project_agent_group_overlay_test.dart test/conversation_sidebar_test.dart`
   - `flutter test test/project_agent_group_overlay_test.dart test/conversation_sidebar_test.dart`

---

## 5.6 Session IA-06：不可用项折叠头与禁用区高级化

### 本轮目标

把现在丑的折叠块彻底重做。

### 必须完成

1. 重构：
   - `opening_unsupported_group_panel.dart`
   - `project_agent_group_overlay.dart`
2. 折叠头规则：
   - 信息密度高但不粗暴
   - 展开箭头、数量、摘要放在一个统一头部
3. 展开区规则：
   - 展开后显示禁用卡片列表
   - 不是纯文本
4. 禁止继续使用默认 `ExpansionTile` 的廉价视觉

### 本轮不要做

- 不改左栏一级入口结构
- 不改三栏骨架

### 本轮重点拆耦

- 折叠头组件
- 禁用卡片区
- 浮层装配

### 完成判定

- 不可用项看起来是正式信息层，不是调试折叠块

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-06 执行。只做不可用项折叠块高级化：重构 opening_unsupported_group_panel.dart 和 project_agent_group_overlay.dart，替换默认 ExpansionTile 视觉，把不可用项展开区改成正式禁用卡片列表。不要改三栏骨架，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已重构 `OpeningUnsupportedGroupPanel`
   - 由 `StatelessWidget + ExpansionTile` 改为显式展开状态的正式 disclosure 面板
   - 保留 `opening_unsupported_groups` 交互 key，避免上层链路与测试漂移
2. 已完成折叠头高级化：
   - 统一头部内整合告警图标、标题、数量 chip、摘要文案与展开箭头
   - 不再使用默认 `ExpansionTile` 的系统样式
3. 已完成展开区收口：
   - 展开后继续使用统一的 `AgentGroupOptionCard` 禁用卡片列表
   - 不可用项仍保留原有 `opening_unsupported_group_<groupId>` key
4. 已轻量整理 `ProjectAgentGroupOverlay` 装配层：
   - 将 supported / unsupported group 的 view data 映射从 widget 树内联逻辑中抽离为局部变量
   - 降低浮层 build 过程中的结构噪音
5. 已补 focused test，明确校验：
   - overlay 不再出现 `ExpansionTile`
   - 不可用组默认折叠隐藏
   - 展开后才显示禁用卡片
   - 不可用卡片仍不可触发组切换
6. 本轮涉及文件：
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart`
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_agent_group_overlay.dart`
   - `apps/novel_agent_app/test/project_agent_group_overlay_test.dart`
7. 已验证：
   - `dart format lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart lib/features/workbench/presentation/widgets/project_agent_group_overlay.dart test/project_agent_group_overlay_test.dart`
   - `flutter analyze lib/features/workbench/presentation/widgets/opening_unsupported_group_panel.dart lib/features/workbench/presentation/widgets/project_agent_group_overlay.dart test/project_agent_group_overlay_test.dart test/conversation_sidebar_test.dart`
   - `flutter test test/project_agent_group_overlay_test.dart test/conversation_sidebar_test.dart`

---

## 5.7 Session IA-07：聚焦回归测试与截图核验

### 本轮目标

最后做自动化兜底和视觉截图，防止“局部顺眼了，别处又裂开”。

### 必须完成

1. 更新或新增 focused test，至少覆盖：
   - 输入区结构
   - 深度思考控件状态色
   - 三栏无缝分割线
   - 智能体一级入口
   - 可选/不可选同构卡片
   - 折叠禁用区
2. 生成视觉核验截图，至少包括：
   - 输入区空态
   - 输入区生成态（停止按钮）
   - 三栏桌面态
   - 智能体面板折叠态
   - 智能体面板展开态

### 本轮不要做

- 不顺手加新功能
- 不顺手改业务合同

### 本轮重点拆耦

- 回归测试
- 截图产物
- 文档闭环

### 完成判定

- 这条链有稳定自动化兜底
- 视觉结果可复查

### 直接可用提示词

```text
按 docs/workbench-input-agent-polish-session-order-2026-05-29.md 的 Session IA-07 执行。只做聚焦回归测试与截图核验：补输入区、三栏无缝、智能体一级入口、统一卡片与折叠禁用区的 focused test，并生成对应截图产物。不加新功能，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增 `IA-07` 视觉回归测试壳：
   - `apps/novel_agent_app/test/workbench_ia07_visual_regression_test.dart`
2. 已生成并校验以下截图产物：
   - `artifacts/workbench_ia07_screenshots/ia07_input_empty_state.png`
   - `artifacts/workbench_ia07_screenshots/ia07_input_generating_stop.png`
   - `artifacts/workbench_ia07_screenshots/ia07_workbench_desktop_three_pane.png`
   - `artifacts/workbench_ia07_screenshots/ia07_agent_panel_collapsed.png`
   - `artifacts/workbench_ia07_screenshots/ia07_agent_panel_expanded.png`
3. 本轮截图覆盖了文档要求的关键视觉状态：
   - 输入区空态
   - 输入区生成态 / 停止按钮态
   - 三栏桌面态
   - 智能体面板折叠态
   - 智能体面板展开态
4. 本轮回归链同时兜住了这条链的关键约束：
   - 输入区结构
   - 深度思考控件状态色
   - 三栏无缝分割线
   - 智能体一级入口
   - 可选 / 不可选同构卡片
   - 折叠禁用区
5. 本轮涉及文件：
   - `apps/novel_agent_app/test/workbench_ia07_visual_regression_test.dart`
6. 已验证：
   - `dart format test/workbench_ia07_visual_regression_test.dart`
   - `flutter analyze test/workbench_ia07_visual_regression_test.dart`
   - `flutter test test/workbench_ia07_visual_regression_test.dart --update-goldens`
   - `flutter test test/conversation_input_dock_test.dart test/workbench_page_desktop_layout_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_agent_panel_test.dart test/project_agent_group_overlay_test.dart test/conversation_sidebar_test.dart test/workbench_ia07_visual_regression_test.dart`

---

## 6. 建议推进方式

建议后续统一用下面这段话推进：

```text
根据目前的进度和文档：docs/workbench-input-agent-polish-session-order-2026-05-29.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意解耦合、单一职责、不要让单文件过重，优先新增小组件与 focused test。开始吧。
```

---

## 7. 最后一句定义

这条链最终不是为了“把几个控件换个位置”，而是为了：

**把工作台最后一批明显不顺眼的交互和层级问题，收口成符合人类审美、符合桌面工具直觉、也方便后续 CLI 抽象的正式界面。**
