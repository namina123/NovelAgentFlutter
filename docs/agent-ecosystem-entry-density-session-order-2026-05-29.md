# NovelAgentFlutter 智能体生态入口、右侧减重与表达限制可发现性任务顺序文档

最后更新：2026-05-29

关联文档：

- `docs/workbench-agent-entry-skill-probe-session-order-2026-05-29.md`
- `docs/workbench-input-agent-polish-session-order-2026-05-29.md`
- `docs/workbench-sidebars-relayout-session-order-2026-05-29.md`
- `docs/expression-constraint-session-order.md`

---

## 1. 这份文档解决什么

最新一轮截图和你的反馈，集中暴露了智能体生态与相关入口的 6 类问题：

1. `智能体生态` 仍然不是左侧竖直栏 `工作` 区域的正式入口
2. `长任务` 在左侧竖直栏已经有入口，但工作台文件区上方仍残留“当前项目长任务摘要 / 入口”语义，重复而且抢空间
3. `项目技能装载` 右侧详情区过重：
   - 大块说明
   - 大块诊断
   - 大量说明式标签
   - 一堆高占地按钮
   - 重要信息反而不清晰
4. `恢复已保存 / 记为历史快照` 语义不清，且与底部历史列表、`另存为技能组` 的关系没有被产品化说明
5. “表达限制 / 真实性复核 / 非技能类约束”虽然已有底层链路，但入口与命名对用户不够可发现，用户依然找不到；而其中 `de_ai` 只是首个内置实现，不应被误写成整个系统的固定产品名
6. 整个生态页和右侧详情区普遍存在“说明文案代替结构设计”的问题，右栏经常被无效说明占掉小半屏

这些问题不能继续作为零散 UI patch 处理，因为它们已经同时涉及：

- 主导航目录
- 工作台左栏职责边界
- 智能体生态页的浏览 / 编辑职责
- 技能装载详情的语义重构
- 表达限制子域的入口设计

所以这里单独开一条新顺序文档。

---

## 2. 为什么这一轮只出顺序文档

这轮不适合直接开做，原因不是“实现不了”，而是如果不先冻结职责，接下来很容易再次做出：

1. 一个能力多个入口
2. 一个右栏承担浏览、解释、编辑、恢复、诊断、导入好几种职责
3. 一个“表达限制”链路既像技能，又不像技能，最后用户还是找不到；再叠加 `de_ai` 被误读成系统全称，语义会更乱
4. 长任务入口明明已经全局化，却在工作台里继续留第二个弱入口

这批问题必须先明确：

- 哪些是一级入口
- 哪些是项目级入口
- 哪些是当前智能体级入口
- 哪些信息应该直接显示
- 哪些信息应该折叠、弱化、延迟显示

因此，这一轮只产出任务顺序文档，不直接改业务代码。

---

## 3. 实现去重审计

在开启这条链之前，先把“已经有链路 / 已经部分实现 / 仍未完成”的边界写死，避免后续 session 再重复造轮子。

### 3.1 已经实现，但位置或呈现不对

1. `智能体生态`
   - 已经有独立 destination、壳层跳转和页面
   - 现在缺的是“进入左侧竖直栏正式导航”，不是缺页面本身
2. `长任务`
   - 已经有左侧竖直栏正式入口
   - 现在缺的是“移除工作台侧栏里残留的当前项目长任务摘要 / 次级入口”
3. `表达限制`
   - 当前智能体侧已经有 `表达限制` 入口
   - 项目资产页已经有 `表达限制` tab
   - 表达限制编辑页与当前智能体上下文桥接链已经存在
   - 现在缺的是可发现性、命名层级和说明密度，不是缺底层链路
4. `项目技能装载`
   - 顶部主操作、历史快照、另存为技能组、诊断面板、不可用技能 issue 投影都已经存在
   - 现在缺的是主次职责收束、视觉减重和语义澄清，不是缺这些动作本身

### 3.2 已经部分实现，但仍需收口

1. `智能体生态` 与工作台之间的跳转关系
   - 当前从工作台跳入技能装载的预选链路已存在
   - 但主导航目录没有把它提升为正式入口
2. `长任务只保留唯一入口`
   - 全局正式入口已经是左侧竖直栏
   - 但工作台左侧的 `长任务` 面板和相关 contract / test 仍然保留“当前项目摘要 + 打开总站”的旧语义
3. `不可用技能`
   - 后端解析和 issue 文案已经生成
   - 但呈现方式还是独立诊断块，没有并回最终技能列表
4. `历史快照`
   - 读、写、恢复、另存为技能组已经形成闭环
   - 但 UI 上主操作、历史恢复、资产化保存混在一起，用户很难理解三者差别
5. `de_ai`
   - 作为 builtin preset / 首个实现的链路已经存在
   - 但产品语义仍需要继续固定为“表达限制系统中的一个内置实现”，而不是整个系统名

### 3.3 这一轮真正还没做的内容

1. 把 `智能体生态` 放进左侧竖直栏 `工作` 区域
2. 清掉工作台里残留的长任务次级入口语义与旧测试预期
3. 让技能装载右栏从说明板回到紧凑详情板
4. 明确历史快照是次级能力还是退场能力
5. 让表达限制对用户真正“找得到、看得懂、不会误认成技能或 de_ai 总名”

### 3.4 文档使用规则

后续执行这份文档时，必须把任务理解成：

1. 优先复用现有 route、controller、workspace service、view-data service
2. 优先删除旧暴露、旧说明、旧测试预期，而不是重新补一套平行逻辑
3. 只有在现有链路确实缺失时，才允许新增入口或新增结构

---

## 4. 本轮先冻结的产品决策

### 4.1 智能体生态入口

冻结结论：

1. `智能体生态` 必须进入左侧竖直栏 `工作` 区域
2. 它应与 `工作台` 同级，但仍属于“工作域”而不是“系统域”
3. `智能体生态` 进入后仍然是独立页面，不回退成工作台内一个子抽屉
4. 从工作台当前智能体跳入 `技能装载` 时，仍保留预选当前智能体的桥接能力

### 4.2 长任务入口

冻结结论：

1. `长任务` 的唯一正式入口保留在左侧竖直栏
2. 工作台文件区不再承担“长任务次级入口”职责
3. 文件区上方的当前项目长任务摘要需要移除
4. 如果需要看当前项目长任务，进入 `长任务总站` 后再按当前项目过滤

### 4.3 技能装载详情语义

冻结结论：

1. `项目技能装载` 右侧详情区必须减重
2. `诊断` 不再占独立大卡片
3. 不可用技能不再单独做一块“告警面板”，而是并入最终技能列表末尾
4. `恢复已保存` 的语义固定为：
   - 回到当前项目已保存装载
   - 只影响当前草稿
   - 不等于恢复某个历史快照
5. `记为历史快照` 如果保留，必须依附于“历史快照列表”这个显式区域；不能再和主操作并列冒充一级主动作
6. `另存为技能组` 继续保留，因为它是明确的资产化动作

### 4.4 历史快照策略

冻结结论：

1. 历史快照不是主操作
2. 如果保留历史快照：
   - 用户必须先看见历史列表
   - 再从历史列表恢复某一条
   - “保存快照”应放在历史区域里，而不是顶栏主按钮
3. 如果历史快照在真实使用中没有稳定价值，则后续允许整条链退场，只保留：
   - 应用当前装载
   - 回到已保存
   - 另存为技能组

### 4.5 表达限制系统入口

冻结结论：

1. `de_ai` 不是技能装载
2. `de_ai` 也不是系统总名，它只是表达限制系统的第一个内置实现
3. 真正的上位概念应继续固定为：`表达限制`
4. 当前命名与入口可发现性不足，必须让用户能明确识别：
   - 这里就是“表达限制 / 真实性复核 / 非技能类写作约束”所在位置
5. 不新增第三套分散入口，优先强化现有表达限制链的文案、结构与可定位能力

### 4.6 右侧说明式标签

冻结结论：

1. 右栏不再默认展示成批说明式字段卡片
2. 默认右栏只保留：
   - 当前条目必要身份信息
   - 当前可执行动作
   - 当前直接可编辑内容
3. 长说明、来源路径、内部 ID、二级解释文字都应弱化、折叠或移到低优先级区域

---

## 5. 总规则

后续每个 session 必须继续遵守：

1. 每次只完成一个具体任务
2. 如果上一轮卡在半截，先收口，不开下一轮
3. 先改入口合同，再改详情区职责，再改视觉密度
4. 不把新逻辑堆回 `app_shell_controller.dart`
5. 工作台、生态页、表达限制页继续各管各的子域，不互相吸收
6. focused test 和视觉回归要跟着每条高风险改动走

---

## 6. Session 列表

---

## 6.1 Session AED-01：把智能体生态接入左侧竖直栏正式导航

### 本轮目标

先把已经存在的 `智能体生态` destination 提升为左侧竖直栏 `工作` 区域正式入口，不改详情区。

### 必读文件

- `apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart`
- `apps/novel_agent_app/lib/app/routing/app_destination.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

### 必须完成

1. 在 `工作` 分组加入 `智能体生态`
2. 保持 `工作台` 与 `智能体生态` 同级
3. 不把 `智能体生态` 误归到 `系统`
4. 保持现有 destination、页面与从工作台跳入技能装载的预选逻辑，不重复新建第二套路由
5. 补 focused test：
   - 左侧竖直栏能看见 `智能体生态`
   - 进入后命中正确 destination

### 本轮不要做

- 不重构生态页布局
- 不处理长任务摘要残留
- 不改表达限制页

### 重点拆耦

- 导航 catalog
- destination 映射
- 壳层路由切换

### 完成判定

- 用户不必再靠二级跳转才能进入智能体生态

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-01 执行。只把智能体生态接入左侧竖直栏工作区域正式导航，保持工作台与智能体生态同级，并保留现有预选当前智能体跳转链。不要重构生态页，不开启下一任务。
```

---

## 6.2 Session AED-02：移除工作台里的长任务重复入口语义

### 本轮目标

让 `长任务` 只保留左侧竖直栏入口，删除工作台侧栏里残留的“当前项目摘要 / 打开总站”重复语义。

### 必读文件

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_long_task_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`

### 必须完成

1. 工作台文件区不再显示当前项目长任务摘要入口
2. `WorkbenchResourceViewData` 与相关 side-panel contract 不再承担长任务入口语义
3. 注意：`resource_manager_panel.dart` 本身已经基本收口，这一轮重点应放在 `workbench_long_task_panel.dart`、side-panel contract、view-data mapper 与相关测试预期
4. 如仍需保留当前项目长任务统计，只能由 `长任务总站` 页面自行负责
5. 补 focused test：
   - 文件区只剩文件工具与项目目录
   - 不再出现长任务摘要入口残留

### 本轮不要做

- 不改长任务总站布局
- 不改左侧竖直栏 `长任务`
- 不顺手改资源树别的结构

### 重点拆耦

- 工作台资源面板职责
- 长任务总站职责

### 完成判定

- `长任务` 在工作台内不再有第二个弱入口

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-02 执行。只移除工作台侧栏里残留的长任务重复入口和当前项目摘要语义，让长任务唯一正式入口保留在左侧竖直栏。不要改长任务总站，不开启下一任务。
```

---

## 6.3 Session AED-03：重构技能装载详情主操作语义

### 本轮目标

在现有 `项目技能装载` 顶部动作基础上收束主次语义，不新增平行动作链。

### 必读文件

- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart`

### 必须完成

1. 主操作只保留高确定性动作：
   - `应用当前装载`
   - `回到已保存`
   - `另存为技能组`
2. `记为历史快照` 从现有主操作区移走，但不删除底层持久化链
3. `恢复已保存` 文案和行为明确为“回到当前项目已保存装载”，不要与历史恢复混淆
4. focused test 覆盖：
   - 顶部主操作只剩上述三类
   - reset 不再与历史恢复混淆

### 本轮不要做

- 不删历史快照持久化
- 不改不可用技能列表
- 不改生态页总布局

### 重点拆耦

- 顶部主操作
- 历史快照行为
- 技能组资产化动作

### 完成判定

- 顶部动作语义不再混乱

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-03 执行。只重构项目技能装载详情主操作语义：保留应用当前装载、回到已保存、另存为技能组，把历史快照从主操作区移走。不要删历史仓储，不开启下一任务。
```

---

## 6.4 Session AED-04：移除独立诊断面板并把不可用技能并入最终技能列表

### 本轮目标

让已经存在的不可用技能 issue 不再占一个大卡片，而是回归最终技能列表本身。

### 必读文件

- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/models/project_skill_loadout_view_data.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`

### 必须完成

1. 删除独立 `诊断` 卡片
2. 保留现有 issue 生成链，只调整展示：把 `当前不可用技能` 合并到最终技能列表
3. 不可用 / 禁用项在列表末尾展示
4. 用轻量视觉区分，而不是另起一整块面板
5. focused test 覆盖：
   - 诊断卡片消失
   - 不可用技能仍可见
   - 不可用项排序在后

### 本轮不要做

- 不重构历史快照区域
- 不改技能组选项区

### 重点拆耦

- issue 投影
- resolved skills 列表
- 列表排序与状态样式

### 完成判定

- 右栏不再被大块诊断面板吃掉

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-04 执行。只移除项目技能装载详情里的独立诊断面板，把不可用技能并入最终技能列表末尾显示。不要顺手改别的卡片，不开启下一任务。
```

---

## 6.5 Session AED-05：把历史快照变成显式次级区，或确认退场

### 本轮目标

解决现有“恢复已保存 / 历史快照 / 技能组保存”三者关系不明的问题，不从零新建历史能力。

### 必读文件

- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`

### 必须完成

1. 明确二选一：
   - 保留历史快照，但把它收束成独立次级区
   - 或确认历史快照退场，只留已保存装载与技能组保存
2. 如果保留：
   - 先展示历史列表
   - 每条历史记录各自恢复
   - “保存快照”放到历史区
3. 如果退场：
   - 清理 UI 暴露
   - 保证现有 loadout / save-as-group 仍闭环
4. focused test 覆盖最终选定方案

### 本轮不要做

- 不顺手改生态页其他 tab
- 不改表达限制入口

### 重点拆耦

- 当前装载保存
- 历史快照
- 技能组资产化

### 完成判定

- 用户能明确理解“恢复什么”和“保存成什么”

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-05 执行。只收口项目技能装载里的历史快照策略：要么把它收成显式次级区，要么确认退场，但必须让恢复已保存、历史恢复、另存为技能组三者语义彻底分开。不要改表达限制入口，不开启下一任务。
```

---

## 6.6 Session AED-06：压缩生态页通用详情区的说明式标签与大卡片

### 本轮目标

把生态页右栏从“说明板”改成“紧凑详情板”。

### 必读文件

- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/ecosystem_detail_panel.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
- `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/agent_ecosystem_header.dart`

### 必须完成

1. 右栏默认不再堆大块说明卡
2. `条目标识 / 条目类型 / 来源 / 路径` 改为更紧凑的信息布局
3. `自定义与导入` 区域改成低占地动作区
4. 技能 / 技能组 / 智能体 / 智能体组详情默认优先显示“当前可执行内容”，不是解释文字
5. focused test / 视觉回归覆盖：
   - 右栏高度显著收缩
   - 关键动作仍可见

### 本轮不要做

- 不动左侧导航
- 不动长任务入口

### 重点拆耦

- 通用详情 pane
- 技能装载专用详情 pane

### 完成判定

- 右栏不再被说明文案占去小半屏

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-06 执行。只压缩智能体生态页右栏详情密度：去掉大块说明式标签和高占地信息卡，让默认详情回到紧凑信息与动作。不要顺手改导航，不开启下一任务。
```

---

## 6.7 Session AED-07：强化表达限制系统的可发现性

### 本轮目标

在现有表达限制入口、tab 和编辑页链路基础上，让用户能明确找到“表达限制这类不是技能的项目级约束系统”，并且知道 `de_ai` 只是其中一个内置实现。

### 必读文件

- `apps/novel_agent_app/lib/features/workbench/application/services/workbench_agent_panel_action_policy_service.dart`
- `apps/novel_agent_app/lib/features/project_assets/presentation/models/project_assets_view_data.dart`
- `apps/novel_agent_app/lib/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart`
- `packages/novel_agent_adapters/lib/src/packages/builtin_expression_constraint_profile_registration_service.dart`

### 必须完成

1. 明确把上位概念固定为 `表达限制`
2. 明确对用户传达：
   - 表达限制 = 项目级写作约束系统
   - `de_ai` 只是其中一个内置 preset / toggle
   - 后续还可以继续扩更多实现
3. 不新增分散入口，只强化现有入口命名、页内结构和可定位能力
4. 在表达限制页中让 builtin `de_ai` preset 更容易被识别，但不把它写成系统总名
5. focused test 覆盖：
   - 从当前智能体入口进入时，用户能看见“表达限制”这个上位概念
   - `de_ai` preset 在默认数据下可被识别为内置实现之一

### 本轮不要做

- 不把表达限制伪装成技能
- 不在生态页里复制一套表达限制编辑器

### 重点拆耦

- 当前智能体入口
- 项目级表达限制子域
- builtin `de_ai` preset 可发现性

### 完成判定

- 用户不再需要猜“表达限制系统在哪”，同时也不会把 `de_ai` 误解成整个系统的固定名字

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-07 执行。只强化表达限制系统的可发现性：不新造分散入口，但要让当前智能体入口、表达限制页命名和 builtin de_ai preset 都足够明确，并保持 de_ai 只是内置实现之一。不要把它伪装成技能，不开启下一任务。
```

---

## 6.8 Session AED-08：总回归、截图核验与 Windows 打包

### 本轮目标

最后做这条链的结构回归和视觉确认。

### 必须完成

1. 跑完 focused test：
   - 智能体生态左侧正式入口
   - 工作台去长任务重复入口
   - 技能装载主操作收口
   - 诊断面板移除与不可用技能并入列表
   - 历史快照最终策略
   - 表达限制系统可发现性
2. 生成关键截图，至少包括：
   - 左侧竖直栏出现 `智能体生态`
   - 工作台文件区不再出现长任务摘要
   - 技能装载右栏减重后的状态
   - 表达限制系统可发现状态
3. 如用户要求，再打包 Windows

### 本轮不要做

- 不顺手再开新入口
- 不继续扩大到其他工作台页面

### 完成判定

- 生态页与相关入口终于回到单一职责、可发现、不过重的状态

### 直接可用提示词

```text
按 docs/agent-ecosystem-entry-density-session-order-2026-05-29.md 的 Session AED-08 执行。只做这条链的总回归、截图核验与必要打包：覆盖智能体生态左侧入口、工作台去长任务重复入口、技能装载右栏减重、历史快照最终策略与表达限制系统可发现性。不要加新功能，不开启下一任务。
```

---

## 7. 建议推进方式

建议后续统一用下面这段话推进：

```text
根据目前的进度和文档：docs/agent-ecosystem-entry-density-session-order-2026-05-29.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意解耦合、单一职责、不要让单文件过重，优先从导航合同、详情区语义和 focused test 入手。开始吧。
```

---

## 8. 最后一句定义

这条链最终不是为了“把智能体生态页再补几块说明卡”，而是为了：

**把智能体生态、技能装载、表达限制和长任务入口各自放回正确位置，让入口唯一、语义明确、详情减重、用户不再靠猜。**
