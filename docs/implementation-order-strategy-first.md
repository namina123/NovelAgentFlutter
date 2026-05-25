# 策略优先实施顺序

## 前提

本顺序建立在下面两件事已经成立的前提上：

1. `docs/mumuainovel-absorption-analysis.md` 的全部建议吸收项已进入预设计体系
2. `agent.md` 已正式确立“策略模式优先”

当前这两个前提都已经满足。

## 实施原则

顺序不是按“哪个页面最显眼”排，
而是按“哪个共享层先稳定，后续返工最少”排。

也就是说：

1. 先策略骨架
2. 再共享资产
3. 再共享运行层
4. 再宿主实现
5. 最后 UI 细化

## Phase 1：策略骨架

目标：

先把“不同项目、不同模式、不同工作流”三层正式立起来。

### 1.1 新建 core 策略子域

- `project_strategy`
- `mode_strategy`
- `workflow_strategy`
- `strategy_catalog_service`

### 1.2 抽出第一批共用合同

- `mode_definition`
- `mode_stage_definition`
- `workflow_profile`
- `autonomy_policy`
- `checkpoint_policy`

### 1.3 让现有长篇开局入口切到策略层

- 当前长任务模式选择不再只是一组按钮
- 它要返回稳定的 `mode_strategy`

## Phase 2：共享资产层

目标：

把所有后续模式都会复用的高价值对象先做稳定。

### 2.1 风格资产

- `style_profile`
- `style_guardrails`
- `style_examples`
- `style_override_merge_service`

### 2.2 实体身份层

- `entity_identity`
- `entity_alias`
- `entity_reference`
- `entity_reference_resolver_service`

重点：

- 角色 / 组织不与名字绑定

### 2.3 世界规则与设定资产

- `world_rule_set`
- `setting_glossary`
- `forbidden_assumptions`
- `progression_schema`

### 2.4 伏笔资产

- `foreshadow_record`
- `foreshadow_status_transition_service`
- `foreshadow_reference_link_service`

## Phase 3：模式引导状态机

目标：

把“灵感托管式长篇”的真正引导逻辑变成共享 core 规则。

### 3.1 引导状态

- `mode_guidance_state`
- `stage_completion_record`
- `mode_memory_snapshot`

### 3.2 引导推进服务

- `mode_guidance_transition_service`
- `mode_guidance_gap_detector_service`
- `mode_guidance_question_service`

### 3.3 接入现有选项 / 自由输入链

- 继续复用 `present_user_options`
- 继续允许自由输入
- 由状态机决定何时优先出选项

## Phase 4：上下文与注入层

目标：

让资产能被不同工作流稳定消费，而不是靠手拼 prompt。

### 4.1 上下文选择

- `mode_context_selector_service`
- `style_context_section_service`
- `character_context_section_service`
- `foreshadow_context_section_service`

### 4.2 风格注入

- `style_prompt_section_service`
- `style_consistency_brief_service`

### 4.3 参数策略

- 章节字数限制
- 自动推进边界
- 模式默认检查点密度

## Phase 5：第一种模式的计划生成

目标：

把引导结果转成长任务队列。

### 5.1 引导结果到计划输入

- `seed_to_plan_input_mapper`
- `autonomy_policy_to_plan_rule_mapper`

### 5.2 生成长任务骨架

- 世界观收束
- 核心角色收束
- 风格定稿
- 全书主线规划
- 分卷规划
- 第一卷细化
- 第一批章纲
- 正文起写前检查

### 5.3 接到现有 long task runtime

- 复用现有 `workflow/` 调度层
- 不另造第二套调度器

## Phase 6：宿主实现层

目标：

让共享模型真正能落盘、导入导出、可恢复。

### 6.1 SQLite / 项目文件设计

- 风格
- 实体卡
- 伏笔
- 模式状态
- 世界规则

优先结构化，避免大 JSON blob。

### 6.2 导入导出

- 项目包
- 风格包
- 卡片包
- 模板包

### 6.3 模板与工坊

- 本地模板包索引
- 模板包导入导出

## Phase 7：分析闭环

目标：

把 MuMu 值得吸收的“分析 -> 建议 -> 执行 -> 回看”闭环接起来。

### 7.1 章节分析与图谱

- 章节关系图
- 角色关系图
- 伏笔回收关系

### 7.2 一键重写

- 分析结果对象
- 局部重写计划
- 重写动作入口

### 7.3 风格漂移检查

- `style_drift_detection_service`
- `style_review_task_factory_service`

## Phase 8：平行策略接入

目标：

让第一种模式不成为孤岛。

### 8.1 一般小说项目接入共享资产层

- 风格
- 实体卡
- 伏笔
- 模板

### 8.2 其他长任务模式接入相同骨架

- 全书共拟式
- 分卷检查点式
- 章纲监督式
- 旧稿抢救重构式

### 8.3 拆书策略接入

- 把拆书输出的资产接入相同资产层

## Phase 9：UI 深化

目标：

最后再把体验做细，不在 UI 上抢跑。

### 9.1 模式引导页

- 阶段引导
- 选项分支
- 已确认摘要

### 9.2 风格中心

- 风格编辑
- 风格样例
- 风格漂移视图

### 9.3 实体中心

- 角色 / 组织
- 别名 / 改名历史
- 关系浏览

### 9.4 伏笔中心与图谱页

- 状态
- 时间线
- 图谱过滤

## 当前最先要做的第一批文件

如果下一步立刻开工，建议先落这些 core 空壳：

1. `packages/novel_agent_core/lib/src/strategy/project_strategy.dart`
2. `packages/novel_agent_core/lib/src/strategy/mode_strategy.dart`
3. `packages/novel_agent_core/lib/src/strategy/workflow_strategy.dart`
4. `packages/novel_agent_core/lib/src/modes/mode_definition.dart`
5. `packages/novel_agent_core/lib/src/modes/mode_guidance_state.dart`
6. `packages/novel_agent_core/lib/src/assets/style_profile.dart`
7. `packages/novel_agent_core/lib/src/assets/world_rule_set.dart`
8. `packages/novel_agent_core/lib/src/entity/entity_identity.dart`
9. `packages/novel_agent_core/lib/src/assets/foreshadow_record.dart`
10. `packages/novel_agent_core/lib/src/assets/autonomy_policy.dart`

## 结束判断

当下面三件事成立时，可以认为“策略优先架构”真正开始进入实现阶段：

1. 三层策略合同已存在
2. 第一批共享资产合同已存在
3. 第一种模式的引导状态机已脱离 UI 成为 core 规则
