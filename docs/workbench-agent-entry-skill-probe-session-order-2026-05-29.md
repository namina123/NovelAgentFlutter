# NovelAgentFlutter 工作台智能体入口、目录映射与技能探针任务顺序文档

最后更新：2026-05-29

关联文档：

- `docs/workbench-input-agent-polish-session-order-2026-05-29.md`
- `docs/skill-loadout-redesign-session-order.md`
- `docs/expression-constraint-session-order.md`
- `docs/workbench-strict-gap-audit-2026-05-29.md`

---

## 1. 这份文档解决什么

上一条 `workbench-input-agent-polish` 链已经完成，但最新一轮截图又暴露出 5 个新的、而且彼此相关的问题：

1. 左上文件工具按钮在窄宽度下仍会断成两排
2. 项目目录的中文映射仍不完整，旧目录会直接漏出原始英文名
3. 用户找不到“给某个智能体设置技能装载 / 给项目挂表达限制”的稳定入口
4. 右侧会话栏里的 `智能体` 标签仍会因为标签区过窄而断成两行
5. 当前会话智能体会去读取自己不能使用的技能，说明运行链里还有“技能可见性 / 技能装载 / 当前智能体”之间的不一致

这批问题不适合继续挂在上一条输入区美化文档下面，因为它们已经不是同一条工作流：

- 一部分是布局合同
- 一部分是资源树合同
- 一部分是工作台入口设计
- 一部分是运行链探针问题

所以这里单独开一条新顺序文档。

---

## 2. 这轮为什么只出顺序文档

这轮不适合直接硬做完，原因很清楚：

1. **入口问题不是“多加两个按钮”**
   - 需要先冻结：
     - 技能装载入口是“当前智能体级”
     - 表达限制入口是“项目级约束，但支持从当前智能体上下文进入”
     - 这两条链不能再各自躲在不同子域里让用户自己猜
2. **技能异常不能靠猜修**
   - 需要先探针确认到底是：
     - 运行时 loadout 选错了
     - `available_skills` 过滤错了
     - 当前会话智能体切换后，旧技能提示仍残留
     - 还是 app 侧桥接时把不属于当前智能体的技能又投影回去了
3. **目录中文映射也不是只改文案**
   - 需要同时补齐：
     - 新骨架目录
     - 历史遗留目录
     - 资源树展示策略

因此，这轮只产出新的任务顺序文档，不直接改业务代码。

---

## 3. 本轮先冻结的设计决策

### 3.1 文件工具条

1. 左上主文件工具在标准桌面最小左栏宽度下，必须保持**单行**
2. 默认只保留 4 个一级可见动作
3. 超出 4 个的动作必须进入溢出入口或次级入口，不能靠换行解决
4. “最小宽度合同”应以这 4 个按钮的单行占位为基线

### 3.2 目录中文映射

1. 资源树不能继续裸露旧英文目录名
2. 新目录骨架与历史遗留目录都必须有统一中文投影
3. 映射逻辑要继续收束在目录描述层和显示服务层，不把文案散落进 widget

### 3.3 智能体入口

这里冻结为一个明确产品结论：

1. 左侧 `智能体` 一级面板必须继续承担“当前智能体工作入口”
2. 这个面板内必须新增稳定可见入口：
   - `技能装载`
   - `表达限制`
3. 两个入口的职责不同：
   - `技能装载`：面向当前智能体，进入后直接定位到该智能体的技能装载编辑
   - `表达限制`：面向当前项目，但进入时应带上“当前智能体上下文”，方便用户给当前智能体绑定或调整约束
4. 这里不新造第三个中心页，优先桥接到现有：
   - `Agent Ecosystem / Project Skill Loadout`
   - `Project Assets / Expression Constraints`

### 3.4 `智能体` 标签单行

1. 右侧会话栏的 `智能体` 标签必须稳定单行
2. 修复方式应体现在选择器合同层，不在页面里继续打补丁
3. 不允许依赖“刚好某个字体宽度够了”这种脆弱行为

### 3.5 技能异常修复路径

1. 先探针，后修复
2. 探针必须同时覆盖：
   - 当前会话智能体是谁
   - 当前项目为该智能体解析到的 resolved loadout 是什么
   - `load_agent_skill` 暴露给模型的 `available_skills` 是什么
   - 模型发出的技能读取请求为什么会命中“当前智能体不可读取该技能”
3. 如果没有探针结论，不允许直接在 UI 层或字符串层糊补丁

---

## 4. 总规则

后续每个 session 必须继续遵守：

1. 每次只完成一个具体任务
2. 如果上个会话卡在半截，先收口，不开下一轮
3. 先服务合同，再装配层，再 widget
4. 不把新逻辑继续堆进大文件
5. 新增入口优先通过小型 view data / action bridge / projection service 接线
6. 技能异常必须有 focused test 或 probe 产物，不接受只靠手点截图口述

---

## 5. Session 列表

---

## 5.1 Session AESP-01：文件工具条单行合同

### 本轮目标

先把左上文件工具按钮的“单行合同”立住，不做其他功能延伸。

### 必读文件

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/file_tool_group.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/layout/workbench_pane_layout_policy.dart`

### 必须完成

1. 明确文件工具条默认只保留 4 个一级可见按钮
2. 超出 4 个的动作移入溢出入口或等价次级入口
3. 左栏最小宽度合同调整到“4 个按钮稳定单行”
4. focused test 覆盖：
   - 左栏收缩到标准最小宽度时，工具条仍为一行
   - 不会再出现两排按钮

### 本轮不要做

- 不改资源树中文映射
- 不动智能体入口
- 不提前顺手改文件导入链

### 重点拆耦

- 文件工具条组件
- 左栏最小宽度合同
- 溢出动作入口

### 完成判定

- 截图中的左上文件工具不再断成两排
- 相关行为由组件合同保证，不靠外层运气撑开

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-01 执行。只做文件工具条单行合同：重构 file_tool_group.dart 和必要的左栏宽度合同，让左上主文件工具默认只保留 4 个一级按钮并始终单行，额外动作移入溢出入口。不要改目录映射，不要动智能体入口，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已完成 `FileToolGroup` 主动作收口：
   - 一级动作固定为：
     - `新文件`
     - `导入文件`
     - `新章节`
     - `保存当前文档`
   - 原先的 `新文件夹` 已移入溢出入口 `更多文件操作`
2. 已把文件工具条从 `Wrap` 改为稳定单行 `Row`
   - 文件：`apps/novel_agent_app/lib/features/workbench/presentation/widgets/file_tool_group.dart`
3. 已新增文件工具条专用的紧凑按钮模式
   - `ToolbarIconButton` 新增 `dense` 参数
   - 仅在文件工具条中启用，避免把全局工具按钮一起压缩
   - 文件：`apps/novel_agent_app/lib/shared/widgets/toolbar_icon_button.dart`
4. 已补 focused test，明确校验：
   - 文件面板仍只保留文件工具与资源树
   - 窄宽度下文件工具条保持单行
   - 溢出按钮存在
   - `新文件夹` 通过溢出菜单仍可触发
   - 文件：`apps/novel_agent_app/test/resource_manager_panel_test.dart`
5. 本轮刻意未做：
   - 没有修改资源树中文映射
   - 没有调整左栏其他一级对象按钮
   - 没有提前进入智能体入口链路
6. 已验证：
   - `dart format lib/shared/widgets/toolbar_icon_button.dart lib/features/workbench/presentation/widgets/file_tool_group.dart test/resource_manager_panel_test.dart`
   - `flutter analyze lib/shared/widgets/toolbar_icon_button.dart lib/features/workbench/presentation/widgets/file_tool_group.dart test/resource_manager_panel_test.dart`
   - `flutter test test/resource_manager_panel_test.dart`

---

## 5.2 Session AESP-02：项目目录中文映射补齐

### 本轮目标

补齐资源树里新旧目录的中文映射，不再让历史目录裸露英文名。

### 必读文件

- `packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workspace_resource_display_service.dart`

### 必须完成

1. 补齐历史目录与现有目录的中文描述映射，至少覆盖：
   - `outline`
   - `volume_outlines`
   - `chapter_outlines`
   - `knowledge`
   - `reviews`
   - `styles`
   - `summaries`
   - `world`
2. 确保目录描述优先从统一 descriptor 来源投影
3. 对缺失映射的旧目录增加兼容合同，而不是在 widget 中散落 if-else
4. focused test 覆盖：
   - 新骨架目录
   - 历史目录
   - 混合项目目录树

### 本轮不要做

- 不调整资源树暴露范围
- 不顺手重做资源树 UI
- 不动智能体入口

### 重点拆耦

- 目录 descriptor
- 中文显示策略
- 旧目录兼容映射

### 完成判定

- 用户在资源树中不再看到一批零散的英文旧目录名
- 新旧目录中文投影规则统一

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-02 执行。只做项目目录中文映射补齐：修改 project_workspace_catalog.dart 和 workspace_resource_display_service.dart，统一补齐历史目录与现有目录的中文描述，不要改资源树暴露范围，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已为资源树显示链新增旧目录兼容 descriptor：
   - `outline/` -> `大纲`
   - `volume_outlines/` -> `卷纲`
   - `chapter_outlines/` -> `章纲`
   - `styles/` -> `风格`
   - `world/` -> `世界`
   - `knowledge/` -> `知识`
   - `summaries/` -> `摘要`
   - `reviews/` -> `审稿`
2. 已将这些兼容 descriptor 并入 `ProjectWorkspaceCatalog.resourceTreeDirectoryDescriptors`
   - 文件：`packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart`
3. 当前取舍已经固定：
   - 只补“显示用兼容目录描述”
   - 不改默认资源树可见性规则
   - 不把旧目录兼容 if-else 散回 widget
4. 已补 focused test，明确校验：
   - 旧目录会通过统一 descriptor 映射出中文名
   - 新骨架目录和旧大纲候选路径会继续同时保留
   - 文件：`apps/novel_agent_app/test/workspace_resource_display_service_test.dart`
5. 本轮刻意未做：
   - 没有调整资源树暴露范围
   - 没有重做资源树 UI
   - 没有提前进入智能体入口任务
6. 已验证：
   - `dart format packages/novel_agent_core/lib/src/project/project_workspace_catalog.dart apps/novel_agent_app/test/workspace_resource_display_service_test.dart`
   - `flutter analyze lib/features/workbench/application/services/workspace_resource_display_service.dart test/workspace_resource_display_service_test.dart`
   - `flutter test test/workspace_resource_display_service_test.dart`
   - `dart test test/agent_run_services_test.dart`

---

## 5.3 Session AESP-03：智能体面板新增稳定入口合同

### 本轮目标

先在左侧 `智能体` 一级面板里，把“技能装载 / 表达限制”作为正式入口钉住，但先只做面板合同和 view data，不接最终跳转。

### 必读文件

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_agent_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/contracts/workbench_project_panel_action_handler.dart`

### 必须完成

1. 扩展 `WorkbenchAgentPanel` 的正式信息结构
2. 新增稳定可见的两个入口：
   - `技能装载`
   - `表达限制`
3. 明确入口说明文案：
   - 技能装载是“当前智能体可用技能组合”
   - 表达限制是“当前项目约束，可按智能体定向绑定”
4. 入口是否可用、显示什么说明，必须走 view data，不让 widget 内联判断

### 本轮不要做

- 不接最终跳转实现
- 不直接修改 `Agent Ecosystem` 页面
- 不直接修改 `Project Assets` 页面

### 重点拆耦

- 智能体面板 view data
- 工作台动作合同
- 入口说明与状态字段

### 完成判定

- 左侧 `智能体` 面板中，用户已经能一眼看见这两个入口
- 它们不再隐藏在其他中心页里等待用户猜测

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-03 执行。只做智能体面板入口合同：扩展 workbench_agent_panel.dart、对应 view data 和 action handler，在左侧智能体面板新增稳定可见的“技能装载”“表达限制”入口，但先不要接最终跳转，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已为左侧 `智能体` 面板新增正式的“智能体工作入口”分区
   - 当前固定显示：
     - `技能装载`
     - `表达限制`
2. 已扩展 `WorkbenchAgentPanelViewData`
   - 新增 `agentWorkspaceActions`
   - 文件：`apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart`
3. 已新增独立策略服务：
   - `WorkbenchAgentPanelActionPolicyService`
   - 负责根据 `hasActiveProject` 产出这两个入口的标题、说明文案和 action id
   - 文件：`apps/novel_agent_app/lib/features/workbench/application/services/workbench_agent_panel_action_policy_service.dart`
4. 已把动作数据接入 `WorkbenchAgentPanelViewDataService`
   - 面板不再自己判断这两个入口显示什么
   - 文件：`apps/novel_agent_app/lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart`
5. 已完成当前阶段的最小装配：
   - `技能装载` 当前绑定到 `onAgentEcosystemRequested`
   - `表达限制` 当前绑定到 `onProjectAssetsRequested`
   - 这轮只确认入口合同与动作线存在，不声明“最终跳转预选”已完成
   - 文件：`apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_agent_panel.dart`
6. 已补 focused test，明确校验：
   - 智能体面板会显示“智能体工作入口”
   - 面板内存在“技能装载”“表达限制”
   - 点击后会分别触发现有动作链
   - 文件：`apps/novel_agent_app/test/workbench_agent_panel_test.dart`
7. 本轮刻意未做：
   - 没有进入 `AESP-04`
   - 没有实现“进入后预选当前智能体 / 进入表达限制页签并带智能体上下文”
   - 没有重做 `Agent Ecosystem` 或 `Project Assets` 子域页
8. 已验证：
   - `dart format lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart lib/features/workbench/application/services/workbench_agent_panel_action_policy_service.dart lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart lib/features/workbench/presentation/widgets/workbench_agent_panel.dart test/workbench_agent_panel_test.dart`
   - `flutter analyze lib/features/workbench/presentation/models/workbench_agent_panel_view_data.dart lib/features/workbench/application/services/workbench_agent_panel_action_policy_service.dart lib/features/workbench/application/services/workbench_agent_panel_view_data_service.dart lib/features/workbench/presentation/widgets/workbench_agent_panel.dart test/workbench_agent_panel_test.dart`
   - `flutter test test/workbench_agent_panel_test.dart`
   - `flutter test test/workbench_navigation_sidebar_test.dart`

---

## 5.4 Session AESP-04：入口桥接与预选上下文

### 本轮目标

把上一步的两个入口正式桥接到已有能力页，并带上正确的预选上下文。

### 必读文件

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart`
- `apps/novel_agent_app/lib/features/project_assets/presentation/pages/project_assets_page.dart`
- `apps/novel_agent_app/lib/features/project_assets/application/controllers/project_assets_controller.dart`

### 必须完成

1. `技能装载` 入口点击后，进入对应能力页时直接定位到当前智能体
2. `表达限制` 入口点击后，进入 `表达限制` 页签，并带上当前智能体上下文
3. 这里要明确一条语义：
   - 表达限制仍是项目级 binding
   - 但用户从当前智能体入口进入时，应默认帮助他编辑与该智能体相关的 binding
4. focused test 覆盖：
   - 从工作台智能体面板进入技能装载页时，已预选当前智能体
   - 从工作台智能体面板进入表达限制页时，已进入 `表达限制` 页签并带有当前智能体上下文

### 本轮不要做

- 不重做生态页整体 UI
- 不重做项目资产页整体 UI
- 不开启新的智能体设置中心

### 重点拆耦

- 工作台到子域页的桥接动作
- 预选上下文状态
- 子域页消费预选状态的最小合同

### 完成判定

- 用户终于能从工作台直接到达“给这个智能体配技能”和“给当前项目挂定向表达限制”的地方
- 不再需要记住两个隐藏子域页的位置

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-04 执行。只做智能体面板入口桥接：把“技能装载”接到当前智能体的技能装载编辑，把“表达限制”接到项目资产的表达限制页签，并带上当前智能体上下文。不要重做子域页整体 UI，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已把 `技能装载 / 表达限制` 从“泛跳转动作”改成“当前智能体语义动作”
   - `WorkbenchProjectPanelActionHandler` 新增：
     - `onCurrentAgentSkillLoadoutRequested()`
     - `onCurrentAgentExpressionConstraintsRequested()`
   - `WorkbenchAgentPanel` 不再把这两个入口接到泛用：
     - `onAgentEcosystemRequested`
     - `onProjectAssetsRequested`
   - 而是明确接到“当前会话智能体”语义动作
2. 已在工作区控制器补齐桥接动作
   - 文件：`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
   - 新动作会直接读取当前工作台 `agentSelector.currentAgentId`
   - 若当前没有可定位智能体，会给出提示而不是静默失败
3. 已在壳层补齐真正的预选逻辑
   - 文件：`apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
   - `技能装载`：
     - 刷新生态快照时直接指定
       - `selectedTabId: 'skill-loadouts'`
       - `selectedEntryId: <当前智能体 id>`
   - `表达限制`：
     - 刷新 `ProjectAssetsController`
     - 进入 `expression_constraints` 页签
     - 记录 `entryAgentContextId`
4. 已把两个子域页重新挂回主路由，解决“看起来能跳，实际上只回工作台”的硬伤
   - 文件：
     - `apps/novel_agent_app/lib/app/routing/app_destination.dart`
     - `apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart`
     - `apps/novel_agent_app/lib/app/routing/app_router.dart`
   - 新增目的地：
     - `agentEcosystem`
     - `projectAssets`
   - 当前它们仍不是左侧主导航常驻项，但已是可真实到达的次级能力页
5. 已为表达限制子域补一个最小上下文合同
   - `ProjectAssetsSnapshot` / `ProjectAssetsViewData` 新增：
     - `entryAgentContextId`
   - `ProjectAssetsController` 新增：
     - `openExpressionConstraintsForAgent(String agentId)`
   - `ExpressionConstraintBindingEditorPanel` 在有入口智能体上下文时会显示：
     - `当前入口智能体：<agentId>`
   - 即使当前项目还没有任何表达限制 preset，空态也能保留这条上下文
6. 已补 focused test
   - `apps/novel_agent_app/test/workbench_agent_panel_test.dart`
     - 校验“技能装载 / 表达限制”触发的是当前智能体桥接动作，而不再是旧泛动作
   - `apps/novel_agent_app/test/project_assets_controller_expression_constraint_context_test.dart`
     - 校验表达限制桥接会切到 `expression_constraints` 页签并保留 `entryAgentContextId`
7. 本轮刻意未做：
   - 没有重做 `AgentEcosystemPage` 的整体 UI
   - 没有重做 `ProjectAssetsPage` 的整体 UI
   - 没有把表达限制编辑器升级为“智能体选择器”正式交互，只先建立入口上下文合同
   - 没有开启 `AESP-05`
8. 已验证：
   - `dart format` 已覆盖本轮修改文件
   - `flutter analyze`：
     - `lib/app/routing/app_destination.dart`
     - `lib/app/state/app_shell_destination_controller.dart`
     - `lib/app/routing/app_router.dart`
     - `lib/app/state/app_shell_controller.dart`
     - `lib/features/workbench/presentation/contracts/workbench_project_panel_action_handler.dart`
     - `lib/features/workbench/presentation/widgets/workbench_agent_panel.dart`
     - `lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
     - `lib/features/project_assets/application/models/project_assets_snapshot.dart`
     - `lib/features/project_assets/presentation/models/project_assets_view_data.dart`
     - `lib/features/project_assets/application/services/project_assets_view_data_service.dart`
     - `lib/features/project_assets/application/services/project_assets_expression_constraint_view_data_service.dart`
     - `lib/features/project_assets/application/controllers/project_assets_controller.dart`
     - `lib/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart`
     - `test/workbench_agent_panel_test.dart`
     - `test/workbench_workspace_controller_snapshot_test.dart`
     - `test/workbench_conversation_controller_agent_selection_test.dart`
     - `test/project_assets_controller_expression_constraint_context_test.dart`
   - `flutter test test/workbench_agent_panel_test.dart`
   - `flutter test test/workbench_workspace_controller_snapshot_test.dart`
   - `flutter test test/workbench_conversation_controller_agent_selection_test.dart`
   - `flutter test test/project_assets_controller_expression_constraint_context_test.dart`

---

## 5.5 Session AESP-05：`智能体` 标签单行合同

### 本轮目标

修正右侧会话栏里 `智能体` 标签挤成两行的问题，并把修复收束到选择器控件合同。

### 必读文件

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_agent_header_strip.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/selector_field.dart`

### 必须完成

1. `SelectorField` 的标签区宽度与文本合同调整到足以单行容纳 `智能体`
2. 明确：
   - `maxLines: 1`
   - `softWrap: false`
   - 合理的标签宽度或等价紧凑布局
3. focused test 覆盖：
   - `智能体` 标签保持单行
   - 不影响 `模型` 等其他选择器

### 本轮不要做

- 不顺手重做整个右栏头部
- 不改智能体切换业务逻辑

### 重点拆耦

- 选择器通用标签合同
- 会话栏智能体选择器装配

### 完成判定

- 右上角 `智能体` 三个字稳定单行
- 不是靠某个偶然像素宽度撑开的脆弱修复

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-05 执行。只做右侧会话栏“智能体”标签单行合同：调整 selector_field.dart 和必要装配，让标签稳定单行且不影响其他选择器。不重做右栏整体布局，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已把 `SelectorField` 的标签宽度从固定魔法数改成按文本测量
   - 文件：`apps/novel_agent_app/lib/features/workbench/presentation/widgets/selector_field.dart`
   - 旧实现里标签区固定 `width: 26`
   - 现在改为：
     - 使用 `TextPainter` 按当前标签文本和样式计算单行所需宽度
     - 标签区宽度随 `label` 自适应
2. 已把选择器标签单行合同明确收束到控件本身
   - `SelectorField` 内部标签 `Text` 现在明确声明：
     - `maxLines: 1`
     - `softWrap: false`
     - `overflow: TextOverflow.visible`
   - 这样 `智能体` 不再依赖“刚好宽度够用”的脆弱运气
3. 当前修复不会影响 `模型` 选择器合同
   - 同一个 `SelectorField` 继续服务：
     - `智能体`
     - `模型`
   - 这轮不在页面里继续打补丁，也没有重做会话栏布局
4. 已补 focused test
   - 新增：
     - `apps/novel_agent_app/test/selector_field_test.dart`
   - 覆盖：
     - `智能体` 标签保持单行
     - `模型` 标签合同不受影响
5. 已补一条集成回归
   - `flutter test test/conversation_sidebar_test.dart`
   - 确认右侧会话栏现有组合链在本轮控件调整后没有被带坏
6. 本轮刻意未做：
   - 没有重做右栏整体布局
   - 没有改智能体切换业务逻辑
   - 没有提前进入 `AESP-06`
7. 已验证：
   - `dart format lib/features/workbench/presentation/widgets/selector_field.dart test/selector_field_test.dart`
   - `flutter analyze lib/features/workbench/presentation/widgets/selector_field.dart test/selector_field_test.dart`
   - `flutter test test/selector_field_test.dart`
   - `flutter test test/conversation_sidebar_test.dart`

---

## 5.6 Session AESP-06：技能异常探针与链路审计

### 本轮目标

先把“当前智能体会读取自己不能使用的技能”这件事做成可复现、可追踪、可定位的问题。

### 必读文件

- `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_runtime_loadout_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_selection_service.dart`
- `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_resolver_service.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`
- `apps/novel_agent_app/tool/skill_loadout_probe.dart`

### 必须完成

1. 复现并探针记录以下链路：
   - 当前项目
   - 当前会话智能体
   - 当前项目中该智能体命中的 loadout
   - `available_skills`
   - 触发报错时请求读取的 `skill_id`
2. 至少确认下列疑点是否成立：
   - 解析到了错误 agent 的 loadout
   - 当前 agent 切换后，旧会话的技能提示仍在污染后续轮次
   - `available_skills` 预览与真正允许读取的技能列表不一致
   - 当前项目已有保存 loadout，但 app 层局部投影和 runtime 投影不一致
3. 产出 probe 报告或 focused test，不能只有人工口述

### 本轮不要做

- 不直接改业务逻辑
- 不提前在 UI 层加遮羞补丁
- 不顺手重构整条技能系统

### 重点拆耦

- runtime resolved loadout
- tool-facing available skill projection
- app 侧当前智能体上下文

### 完成判定

- 这个问题已经从“截图异常”变成“有结论的链路问题”
- 已能说明到底是 loadout、过滤、还是切换残留造成的

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-06 执行。只做技能异常探针与链路审计：围绕 project_agent_skill_tool_executor.dart、runtime loadout service、app_shell_controller.dart 和现有 skill_loadout_probe.dart，复现并记录为什么当前智能体会去读自己不可用的技能。不要直接修逻辑，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已新增 AESP-06 专用 probe 测试
   - 文件：`apps/novel_agent_app/test/workbench_agent_skill_probe_test.dart`
   - 这轮没有直接改业务逻辑，而是把技能异常拆成 5 个可复查步骤逐条验证
2. 已证实：当前会话智能体解析链本身没有串
   - probe 步骤：`request_agent_resolution_uses_selected_agent`
   - 结论：
     - `ConversationRequestAgentResolverService` 会正确把当前会话选中的 `reviewer` 解析成实际请求智能体
   - 这说明问题不是“右栏当前智能体显示错了”
3. 已证实：runtime loadout 没有命中到错误 agent
   - probe 步骤：`runtime_loadout_selection_stays_agent_scoped`
   - 结论：
     - `ProjectAgentSkillRuntimeLoadoutService`
     - `AgentSkillLoadoutSelectionService`
     - `AgentSkillLoadoutResolverService`
     会正确为 `reviewer` 命中 `review_only_skill`
   - 这说明问题不是“loadout 选到了别的智能体”
4. 已证实：`available_skills` 预览和实际允许读取列表一致
   - probe 步骤：`executor_preview_and_enforcement_stay_consistent`
   - 结论：
     - `ProjectAgentSkillToolExecutor` 返回的 `available_skills`
     - 与后续 `load_agent_skill` 真正允许读取的技能保持一致
   - 这说明问题不是“preview 列表和 enforcement 链分叉了”
5. 已证实：主智能体工具执行链会正确注入 `_agent`
   - probe 步骤：`main_tool_execution_path_injects_agent_context`
   - 结论：
     - `ToolExecutionService` 在执行 `load_agent_skill` 时，会把当前 agent 注入到工具参数 `_agent`
     - 主执行链因此能正确读取 `review_only_skill`
   - 这说明问题不是“主会话工具链漏传当前智能体”
6. 已证实：子智能体执行链会丢失 `_agent` 上下文
   - probe 步骤：`sub_agent_execution_path_drops_agent_context`
   - 结论：
     - `SubAgentExecutionService` 当前直接调用 `ToolExecutionPort`
     - 在执行 `load_agent_skill` 时没有像 `ToolExecutionService` 那样补 `_agent`
     - 最终 `ProjectAgentSkillToolExecutor` 回退到 `fallbackDefaultAgent()`
     - 因而对 `review_only_skill` 报出：
       - `当前智能体不可读取该技能：review_only_skill`
   - 这条链已经被 probe 报告明确记录为本轮最强证据
7. 已产出 probe 报告
   - 文件：`artifacts/workbench_agent_skill_probe_report.json`
   - 当前报告已明确区分：
     - 哪些疑点已被排除
     - 哪条链最可能是真正根因
8. 本轮审计结论已冻结
   - 当前最可能根因不是：
     - 选错 agent loadout
     - app 层当前 agent 投影错误
     - `available_skills` 与 enforcement 不一致
   - 当前最可能根因是：
     - **子智能体执行链绕过了 `ToolExecutionService` 对 `load_agent_skill` 的 `_agent` 注入**
9. 本轮刻意未做：
   - 没有直接修 `SubAgentExecutionService`
   - 没有在 UI 层加遮羞补丁
   - 没有提前开启 `AESP-07`
10. 已验证：
   - `dart format test/workbench_agent_skill_probe_test.dart`
   - `flutter analyze test/workbench_agent_skill_probe_test.dart`
   - `flutter test test/workbench_agent_skill_probe_test.dart`
   - `flutter test test/workbench_agent_panel_test.dart`

---

## 5.7 Session AESP-07：基于探针结论修复技能过滤异常

### 本轮目标

在上一轮 probe 结论明确后，只修真实暴露出来的那条链。

### 必读文件

- 以上一轮 probe 结论为准
- 高概率涉及：
  - `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_tool_executor.dart`
  - `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_runtime_loadout_service.dart`
  - `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_selection_service.dart`
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

### 必须完成

1. 只修 probe 明确证实的问题
2. 保证以下合同一致：
   - 当前会话智能体可见技能
   - `available_skills`
   - `load_agent_skill` 允许读取的技能
   - app 侧当前智能体摘要
3. 补 focused test，至少覆盖：
   - 切换不同智能体后，技能可见性不串
   - 某智能体不会再读取另一个智能体的不可用技能
   - `available_skills` 与实际可读取技能一致

### 本轮不要做

- 不顺手改技能装载 UI
- 不额外扩 agent_group / mode / stage 全新策略
- 不把 probe 临时逻辑残留到生产链

### 重点拆耦

- 问题根因对应的最小修复面
- 测试与业务实现分离

### 完成判定

- 截图里的“当前智能体不可读取该技能”异常，在同类场景下不再出现
- 过滤合同在 runtime 和 app 两侧一致

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-07 执行。基于上一轮 probe 结论，只修当前智能体错误读取不可用技能的问题，保证 available_skills、load_agent_skill 和当前智能体可见技能一致。不要顺手扩技能系统，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已按 probe 结论完成最小修复面收口：
   - `SubAgentExecutionService` 不再直接把 `load_agent_skill` 原样下发
   - 新增子智能体专用执行桥接：
     - 当子智能体调用 `load_agent_skill` 时，显式补入当前子智能体 `_agent`
     - 其他工具继续走原有 `ToolExecutionPort`
   - 文件：
     - `packages/novel_agent_core/lib/src/agents/sub_agent_execution_service.dart`
2. 已补 core 侧 focused test，验证子智能体技能上下文合同：
   - 子智能体读取自己允许的技能时，会携带自身 `agent_id`
   - 子智能体尝试读取别的智能体技能时，仍会被正确拦下
   - 文件：
     - `packages/novel_agent_core/test/sub_agent_execution_service_test.dart`
3. 已把 app 侧 probe 从“复现旧 bug”翻成“验证修复后合同成立”：
   - 子智能体链现在要求：
     - `load_agent_skill` 记录到 reviewer 的 `_agent`
     - reviewer 可成功读取 `review_only_skill`
   - probe 结论也同步改写为“子智能体技能上下文已对齐”
   - 文件：
     - `apps/novel_agent_app/test/workbench_agent_skill_probe_test.dart`
4. 本轮明确没有扩散修改范围：
   - 没有重做技能装载 UI
   - 没有改 `available_skills` 生成策略
   - 没有扩 agent group / mode / stage 规则
   - 只修 probe 已证实的子智能体 `_agent` 注入缺口
5. 已验证：
   - `flutter analyze lib/src/agents/sub_agent_execution_service.dart test/sub_agent_execution_service_test.dart`
   - `flutter test test/sub_agent_execution_service_test.dart`
   - `flutter analyze test/workbench_agent_skill_probe_test.dart`
   - `flutter test test/workbench_agent_skill_probe_test.dart`

---

## 5.8 Session AESP-08：总回归、截图核验与打包

### 本轮目标

最后把这条链做成可回归、可复查、可交付。

### 必须完成

1. 跑完本链 focused test：
   - 文件工具条单行
   - 目录中文映射
   - 智能体面板入口
   - 入口预选跳转
   - `智能体` 标签单行
   - 技能异常过滤修复
2. 生成关键截图，至少包括：
   - 左栏文件工具单行态
   - 资源树中文映射态
   - 智能体面板带两个新入口
   - 右栏 `智能体` 单行选择器
3. 如用户要求，再进行 Windows 打包

### 本轮不要做

- 不顺手再加新功能
- 不借回归之名继续改设计

### 完成判定

- 这条链的每个问题都有可复查产物
- 后续不会再把“某个 session 做完”误报成“整个产品目标完成”

### 直接可用提示词

```text
按 docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md 的 Session AESP-08 执行。只做这条链的总回归、截图核验与必要打包：覆盖文件工具条单行、目录中文映射、智能体入口、入口桥接、智能体标签单行和技能异常修复。不要加新功能，不开启下一任务。
```

### 本轮完成记录（2026-05-29）

1. 已完成本链 focused test 总回归：
   - 文件工具条单行：
     - `apps/novel_agent_app/test/resource_manager_panel_test.dart`
   - 目录中文映射：
     - `apps/novel_agent_app/test/workspace_resource_display_service_test.dart`
   - 智能体面板入口：
     - `apps/novel_agent_app/test/workbench_agent_panel_test.dart`
   - 表达限制入口桥接上下文：
     - `apps/novel_agent_app/test/project_assets_controller_expression_constraint_context_test.dart`
   - `智能体` 标签单行：
     - `apps/novel_agent_app/test/selector_field_test.dart`
   - 技能过滤修复：
     - `apps/novel_agent_app/test/workbench_agent_skill_probe_test.dart`
     - `packages/novel_agent_core/test/sub_agent_execution_service_test.dart`
2. 已完成本链分析回归：
   - `flutter analyze test/resource_manager_panel_test.dart test/workspace_resource_display_service_test.dart test/workbench_agent_panel_test.dart test/project_assets_controller_expression_constraint_context_test.dart test/selector_field_test.dart test/workbench_agent_skill_probe_test.dart`
   - `flutter analyze test/sub_agent_execution_service_test.dart`
3. 已新增 `AESP-08` 专用视觉回归壳，避免继续借用其他任务链截图：
   - 文件：
     - `apps/novel_agent_app/test/workbench_aesp08_visual_regression_test.dart`
   - 这份回归只负责本链要求的 4 类视觉状态：
     - 左栏文件工具单行态
     - 资源树旧目录中文映射态
     - 智能体面板带 `技能装载 / 表达限制`
     - 右栏 `智能体` 单行选择器
4. 已生成并校验以下截图产物：
   - `artifacts/workbench_aesp08_screenshots/aesp08_resource_panel_single_row.png`
   - `artifacts/workbench_aesp08_screenshots/aesp08_resource_panel_legacy_mapping.png`
   - `artifacts/workbench_aesp08_screenshots/aesp08_agent_panel_entries.png`
   - `artifacts/workbench_aesp08_screenshots/aesp08_conversation_agent_selector.png`
5. 已验证截图链路：
   - `flutter test --update-goldens test/workbench_aesp08_visual_regression_test.dart`
   - `flutter test test/workbench_aesp08_visual_regression_test.dart`
6. 本轮没有额外改新功能：
   - 没有继续改工作台设计
   - 没有扩大技能系统重构范围
   - 没有顺手动别的任务文档链路
7. 本链最终交付状态：
   - 文件工具条单行已可回归
   - 旧目录中文映射已可回归
   - 智能体面板入口与入口桥接已可回归
   - `智能体` 标签单行已可回归
   - 子智能体技能上下文错乱问题已可回归
   - 本文档 5.1 到 5.8 已全部完成

---

## 6. 建议推进方式

建议后续统一用下面这段话推进：

```text
根据目前的进度和文档：docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意解耦合、单一职责、不要让单文件过重，优先新增小型 view data / service / focused test。开始吧。
```

---

## 7. 最后一句定义

这条链最终不是为了“再补几个按钮和文案”，而是为了：

**把工作台里与智能体使用最直接相关的几个缺口一次性收口：入口可达、目录可读、标签不裂、技能可见性不串。**
