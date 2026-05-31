# NovelAgentFlutter 工作台严格缺口审计

最后更新：2026-05-29

关联文档：

- `docs/workbench-remaining-session-order-2026-05-28.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

---

## 1. 先纠正结论

`WR-17` 的完成，只能说明：

- 这一轮“回归验证任务”完成了
- 相关测试、探针、截图链跑通了

**不能说明产品目标已经完成。**

从当前界面截图和代码现状看，工作台离以下目标仍有明显距离：

- 简洁、正式、低噪音
- 真正组优先
- AI 主引导，GUI 少入口
- 不向用户暴露内部目录和内部术语
- 为 CLI 收口，而不是继续堆 GUI 分支

这份文档的目的，就是把“任务文档完成”和“产品目标完成”彻底分开。

---

## 2. 这次审计怎么做

本次审计同时看三类事实源：

1. 当前用户截图里直接可见的问题
2. 用户此前明确提出、但当前界面仍未兑现的产品约束
3. 当前代码结构里仍在继续强化旧设计的链路

重点不是“还能不能修”，而是：

- **现在到底还没实现什么**
- **这些问题是表面问题，还是结构还在反向强化**

---

## 3. 已确认做对的部分

这些不是本轮主要问题，不应该被误报成“完全没做”：

1. `模型 + 智能体组` 已替代旧的 `模型 + 单智能体` 主选择器
   - `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart`
2. reasoning toggle 已进入会话输入能力链，并按能力显隐
   - `conversation_input_capability_service.dart`
   - `conversation_primary_agent_bar.dart`
3. stop 取消链已有正式运行句柄与测试覆盖
   - `conversation_request_runtime_service_test.dart`
   - `workbench_wr17_probe_test.dart`
4. 附件公开入口当前保持关闭
   - 这点和当前产品决策一致
5. 顶层全局导航已收窄到
   - `打开项目`
   - `工作台`
   - `长任务`
   - `设置`
   - 文件：`app_shell_navigation_catalog.dart`

也就是说，问题不是“完全没动”，而是：

**一些关键合同已经变了，但最终用户体验和结构收口没有跟上。**

---

## 4. 当前未完成项总判断

## 4.1 结论

当前工作台**没有完成最终收口**。

而且不是“只差一点视觉 polish”，而是至少还存在 7 类未完成问题：

1. 工作台仍然像编辑器 / 调试壳，不像面向用户的写作工作台
2. 文件树仍直接暴露大量内部或高级目录
3. 会话区仍在承担“说明书 + 入口菜单”职责
4. 组优先合同只做到了部分投影，没有完成最终产品化
5. 中间栏仍保留明显的开发态结构
6. 代码里仍保留大量旧页面 / 旧中心 / 旧工作台链路
7. 视觉语言仍未真正吸收到你要的那种克制风格

---

## 5. 截图里直接可见的未实现项

## 5.1 左栏仍然是“导航套导航”

截图里左侧出现了两层结构：

1. 全局导航：`打开项目 / 工作台 / 长任务 / 设置`
2. 工作台内部活动栏：`文件 / 项目 / 长任务`

对应代码：

- `apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_activity_rail.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_side_panel_host.dart`

问题不在“有三个 tab”本身，而在：

- 用户先进入了“工作台”
- 然后还要再理解工作台内部的第二层导航系统

这仍然是典型的“入口套入口”。

### 判定

这不符合你要的“易用、简洁、CLI 可收口”。

当前左栏虽然比早期少了很多页，但**仍然没有变成一个真正单义的对象面板**。

---

## 5.2 文件树仍暴露大量不该直接给用户看的目录

截图里直接能看到这些目录：

- `智能体配置`
- `智能体组配置`
- `技能配置`
- `技能组配置`
- `提示词模板`
- `执行追踪`
- `生成记录`
- `inspiration`
- `drafts`
- `characters`

这不是偶发数据问题，而是当前目录目录合同本身就在这样做。

直接原因：

- `packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart`

这里的：

- `advancedWorkspaceDirs`
- `resourceTreeDirectoryDescriptors`

明确把以下目录并入了资源树：

- `agents/`
- `agent_groups/`
- `skills/`
- `skill_groups/`
- `prompts/`
- `tracking/`
- `runs/`

### 判定

这和你的要求正面冲突：

- 内部链路可以保留
- 但不能作为用户主资源树的一部分直接暴露

这不是“样式问题”，而是**资源树合同错了**。

---

## 5.3 中间栏仍然是明显的编辑器壳

截图中的中间栏仍然保留了这些开发态 / 编辑器态结构：

- `正文工作区`
- `文稿编辑 / 渲染预览 / 结构视图`
- `源码 / 渲染 / 结构`
- 保存 / 审稿 / 结构按钮
- `结果面板`

对应代码：

- `document_toolbar_bar.dart`
- `document_workspace_display_mode_bar.dart`
- `workbench_primary_canvas_host.dart`
- `workbench_canvas_workspace_shell.dart`
- `workbench_auxiliary_panel_host.dart`

这里的根问题不是某个按钮大不大，而是：

- 当前正文区仍以“编辑器功能分屏”作为主心智
- 不是以“我正在写作 / 阅读 / 继续当前项目任务”作为主心智

### 判定

这和你前面多次说的完全一致：

- 中间栏更像调试用
- 很占空间
- 不够像真正面向用户的主工作区

这个判断从代码上也成立，因为当前仍明确保留了：

- 显示模式条
- 辅助结果面板
- 结构视图切换
- 审稿快捷入口

---

## 5.4 右侧会话栏仍然像“说明书 + 入口盒子”

截图里右栏在一个很小的区域里同时塞进了：

- opening 说明
- 不可用项原因
- 智能开局按钮
- 导入文资按钮
- 上下文资源
- 工具概览
- 运行状态
- 模型
- 智能体组
- 主智能体
- 深度思考
- 输入说明
- 发送区

对应代码：

- `conversation_sidebar.dart`
- `conversation_empty_state_panel.dart`
- `workflow_guide_card.dart`
- `opening_session_panel.dart`
- `primary_action_list.dart`
- `conversation_composer_panel.dart`

### 判定

这和你要的：

- “只留第一句提示”
- “后续全程由 AI 引导用户完成信息”
- “尽量少硬编码按钮”

明显不一致。

现在它依然是：

- 一大块说明文字
- 一大块项目级组说明
- 一大块空态按钮

也就是说，**AI 主引导没有真正接管开局体验**。

---

## 5.5 顶部副标题仍会泄露内部标识

截图里 `会话` 下面显示的是：

- `default-generalist`

而不是一个稳定的对用户友好的主智能体名称。

相关代码：

- `conversation_panel_header.dart`
- `conversation_group_selector_view_data_service.dart`
- `app_shell_controller.dart`

其中：

- `ConversationPanelHeader` 直接把 `primaryAgentLabel` 作为副标题
- `ConversationGroupSelectorViewDataService._primaryAgentDescription()` 会在角色为空时回退到 `agentId`
- `AppShellController._fallbackPrimaryAgentLabel()` 虽然优先回退显示名，但某些投影未就绪时仍可能漏出内部 ID

### 判定

这说明“组优先”虽然已经有合同，但**展示层的最后一道去内部化没有做完**。

用户看到内部 `agentId`，就是未完成。

---

## 5.6 项目面板仍然是“配置入口中心”

截图里左侧项目区不只是项目摘要，还包含了多组动作和跳转语义。

对应代码：

- `workbench_project_panel.dart`

当前仍直接提供：

- `项目信息`
- `刷新项目`
- `项目协作配置`
- `智能体生态`
- `项目资产与表达限制`
- `提示模板`

### 判定

这里仍然保留了“多个中心入口折叠进项目面板”的思路，而不是：

- 当前项目是什么
- 当前项目接下来做什么
- 少量真正必要的项目配置

尤其是：

- `智能体生态`
- `提示模板`

这两个仍然过于像系统级中心，而不是当前项目必须面对的日常动作。

---

## 6. 用户明确要求但仍未兑现的约束

## 6.1 “灵感没有必要”并没有彻底兑现

你之前已经明确说过：

- 灵感界面没有必要
- 灵感应该更多由 AI 引导和文件记录承担

但当前代码里，灵感链路并没有真正退出系统，只是从顶层导航里消失了。

仍然存在的链路包括：

- `features/inspiration_workbench/...`
- `InspirationWorkbenchController`
- `app_shell_controller.dart` 中的初始化和持有

### 判定

这说明灵感功能不是“已清退”，而是“暂时藏起来了”。

这会继续反向强化：

- 数据结构
- 控制器依赖
- 页面心智

---

## 6.2 “只靠 AI 引导，而不是一套逻辑很多复杂入口”没有兑现

目前仍然存在这些硬编码会话入口：

- `智能开局`
- `导入文资`
- opening 面板中的智能体组说明与选择
- 空态动作列表

相关代码：

- `conversation_empty_state_panel.dart`
- `workflow_guide_card.dart`
- `opening_session_panel.dart`
- `conversation_guide_view_data_service.dart`
- `conversation_opening_guide_view_data_service.dart`

### 判定

当前产品仍把“系统告诉用户下一步点哪里”当成主体验，
而不是“AI 基于当前项目状态继续引导”。

---

## 6.3 “默认只有单一主智能体，用户主要选择智能体组”只做了一半

这部分的中层合同已经有明显推进：

- 会话选择器已经是 `模型 + 智能体组`
- 主智能体已经变成只读摘要

但产品层仍没有完全收口：

1. 顶部副标题仍强调主智能体
2. 项目面板同时重复展示 `智能体组 + 主智能体`
3. `智能体生态` 仍是一个强入口
4. opening / 会话 / 项目配置 三处都在讨论组问题

### 判定

这说明“组优先”进入了合同层，但**没有完成产品层的单一事实源体验**。

---

## 6.4 “CLI 铺路”没有完成

你明确说过：

- GUI 要为 CLI 铺路
- CLI 不可能承受这么多分支

但当前 GUI 仍保留了很多 CLI 不会对应的复杂 UI 分叉：

- 左栏二级导航壳
- 中间栏显示模式壳
- 结果面板壳
- 空态多按钮壳
- opening 面板壳

核心文件：

- `workbench_navigation_sidebar.dart`
- `workbench_canvas_workspace_shell.dart`
- `workbench_auxiliary_panel_host.dart`
- `conversation_sidebar.dart`

### 判定

现在的 GUI 仍然不是“CLI 能映射出来的几个稳定对象”。

它还是很多面板壳和解释壳拼起来的。

---

## 7. 代码结构里仍在继续强化旧设计的地方

## 7.1 旧中心虽然不在导航里，但还在 App Shell 长期存活

`AppDestination` 现在确实只剩 4 个。

但 `app_shell_controller.dart` 和 `app_shell_listenable_state.dart` 里仍长期持有这些系统：

- `AgentEcosystem`
- `TaskCenter`
- `ReviewCenter`
- `PromptTemplates`
- `ProjectAssets`
- `BookDeconstruction`
- `InspirationWorkbench`

这意味着：

- 即使导航收窄了
- app 层的产品骨架仍然是旧时代的大系统拼盘

### 判定

这会导致每次简化 UI 时，都还要跟旧中心模型相互兼容。

也就是说，**顶层信息架构虽然看起来简化了，底层产品骨架其实还没简化。**

---

## 7.2 资源树合同和项目面板合同彼此打架

一边：

- `ResourceManagerPanel` 注释里说“只保留文件动作与资源树”

另一边：

- `ProjectWorkspaceCatalog.resourceTreeDirectoryDescriptors`
  仍把大量高级目录送进资源树

结果就是：

- UI 看起来像想做简洁文件区
- 底层目录合同却还在不断把高级概念塞进来

### 判定

这是典型的“上层想简化，下层合同没改”。

---

## 7.3 会话区已经解耦，但职责仍然太多

`ConversationSidebar` 的实现已经比以前干净很多，但它现在仍同时承担：

- 会话头部
- 空态
- 开局组选择补充
- 时间线
- 子智能体详情切换
- pending 输入预览
- composer
- 工具状态展开

### 判定

从代码可维护性角度，这不算灾难；
但从产品职责角度，它仍然是一个“会话总装面板”。

所以问题不只是“组件是不是大文件”，而是：

**产品职责还没有彻底收束。**

---

## 8. 这轮严格审计后的最终判断

## 8.1 不能再说“都完成了”

准确说法应该是：

- `WR-17` 回归任务已完成
- 若只问“那条 session 文档最后一轮是否完成”，答案是完成
- 若问“你要的工作台产品目标是否完成”，答案是否定的

## 8.2 当前最关键的未完成点不是某一个 bug

而是这三个总问题仍然同时存在：

1. **内部结构仍暴露给用户**
2. **AI 引导没有真正取代硬编码入口**
3. **工作台仍然保持编辑器 / 调试台心智**

## 8.3 后续不能继续沿用现有 `workbench-remaining-session-order` 当作“已收口总纲”

原因很简单：

- 那份文档收的是一条任务链
- 不是这轮截图暴露出来的真实产品缺口

后续应该基于本审计重新拆任务。

---

## 9. 建议的后续任务轨道

这里只定轨道，不在本轮细拆 session：

1. `资源树合同收口轨`
   - 先把用户可见目录、内部目录、高级目录重新分层
2. `工作台对象模型收口轨`
   - 左栏、中栏、右栏分别只保留单一对象职责
3. `AI 引导替代硬编码入口轨`
   - 会话空态、opening 面板、项目开局按钮重做
4. `组优先产品化轨`
   - 彻底去内部 ID、去多处重复组说明、去组相关重复入口
5. `CLI 对齐轨`
   - 移除无法映射到 CLI 的重壳层与调试态面板

---

## 10. 这份文档的用途

后续如果要继续做：

- 不应再从“上轮文档已经做完，所以继续下一轮”出发
- 应该从这份严格缺口审计出发，重建任务顺序文档

因为当前最需要的不是继续补一两个点，
而是**承认产品目标还没完成，并按真实缺口重新排队。**
