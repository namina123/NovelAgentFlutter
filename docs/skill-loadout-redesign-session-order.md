# NovelAgentFlutter 技能装载与技能组重构会话顺序文档

最后更新：2026-05-27

---

## 0.6 Session SL-06 完成记录

- 已完成 `Session SL-06：探针、回归与文档回填`
- 本轮新增并明确：
  - `apps/novel_agent_app/tool/skill_loadout_probe.dart`
  - `packages/novel_agent_adapters/test/project_agent_skill_runtime_loadout_service_test.dart`
    - 已补“切项目后不串当前 loadout”的显式回归
- 本轮真实覆盖并确认通过的七个场景：
  - 单智能体默认技能声明
  - 只选 `skill group`
  - `skill group + extra skills`
  - `skill group + disabled skills`
  - 从历史恢复
  - 显式保存为 `skill group`
  - 切项目后不串当前 `loadout`
- 当前结论已经固定：
  - `skill / skill_group / skill_loadout` 三层语义闭环已完成
  - 当前项目 `loadout`、历史快照与显式 `save-as-group` 三条链路均已具备自动验证
  - 当前没有发现需要继续修补的联调问题，因此本轮没有额外扩业务代码主线
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart test test/agent_skill_loadout_contracts_test.dart test/agent_skill_loadout_selection_service_test.dart test/agent_skill_services_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_agent_skill_runtime_loadout_service_test.dart test/project_agent_skill_tool_executor_test.dart test/project_agent_skill_loadout_repository_test.dart test/project_agent_skill_loadout_history_repository_test.dart test/project_skill_loadout_save_as_group_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `flutter test test/project_skill_loadout_workspace_service_test.dart test/project_skill_loadout_view_data_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart analyze tool/skill_loadout_probe.dart`
    - 通过
  - `apps/novel_agent_app`
    - `dart run tool/skill_loadout_probe.dart`
    - `PASS`
- 新增报告：
  - `apps/novel_agent_app/artifacts/skill_loadout_probe_report.json`
- 后续扩展点：
  - 若后续要补更细的 `agent_group / mode / stage` 命中探针，优先继续扩 `tool/skill_loadout_probe.dart`，不要把回归规则散回多个临时脚本
  - 若后续 UI 层要加更多项目切换联调，优先补 app 侧 focused test 或 probe，不要回退成手工点点点验证

---

## 0.5 Session SL-05 完成记录

- 已完成 `Session SL-05：生态页最小 UI 与项目内装载编辑`
- app 侧当前新增并明确：
  - `ProjectSkillLoadoutWorkspaceSnapshot`
  - `ProjectSkillLoadoutWorkspaceService`
  - `ProjectSkillLoadoutViewDataService`
  - `ProjectSkillLoadoutWorkspaceViewData`
  - `ProjectSkillLoadoutDetailPanel`
- 当前行为已经固定：
  - 生态页现已新增 `技能装载` tab，并复用现有 agent browser 作为左侧选择入口
  - 右侧详情区现已支持：
    - 勾选 `skill groups`
    - 勾选 `extra skills`
    - 对 resolved skills 做 `disabled` 标记
    - 显式保存历史快照
    - 从历史快照恢复到当前 draft
    - 显式 `save as skill group`
  - `AppShellController` 现在只承担：
    - 当前项目 workspace snapshot 装载
    - loadout action 转发
    - 状态提示与生态页刷新
  - group 展开、冲突诊断、resolved skill 投影仍然留在 service / core resolver，不在 widget 内重复实现
  - `save as skill group` 完成后会主动刷新生态快照，确保新写入的 `skill_groups/` 能被同页看见
- 本轮刻意未做：
  - 生态页审美重构
  - 拖拽式编排
  - 自动历史快照策略
  - 更细的按 `agent_group / mode / stage` 维度编辑
- 本轮验证结果：
  - `apps/novel_agent_app`
    - `dart analyze lib/app/state/app_shell_controller.dart lib/app/bootstrap/app_bootstrap.dart lib/features/agent_ecosystem/application/models/project_skill_loadout_workspace_snapshot.dart lib/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart lib/features/agent_ecosystem/presentation/models/project_skill_loadout_view_data.dart lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart lib/features/agent_ecosystem/presentation/pages/agent_ecosystem_page.dart test/project_skill_loadout_workspace_service_test.dart test/project_skill_loadout_view_data_service_test.dart`
    - 通过
  - `apps/novel_agent_app`
    - `flutter test test/project_skill_loadout_workspace_service_test.dart test/project_skill_loadout_view_data_service_test.dart`
    - 通过
- 后续扩展点：
  - `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart`
    - 后续若要补自动历史策略或更多 restore policy，优先继续扩这里，不要把保存时序塞回 controller
  - `apps/novel_agent_app/lib/features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart`
    - 后续若要补更细的 issue 呈现、筛选或折叠策略，继续扩 projection service，不要把来源文案拼接散到 widget
  - `apps/novel_agent_app/lib/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart`
    - 当前先保守完成结构闭环；后续视觉和交互升级放到独立 UI 会话，不要顺手把业务逻辑带回来

---

## 0.4 Session SL-04 完成记录

- 已完成 `Session SL-04：运行链接线与智能体实际消费`
- 当前新增并明确：
  - `AgentSkillLoadoutSelectionService`
  - `ProjectAgentSkillRuntimeLoadoutService`
- 当前行为已经固定：
  - `ProjectAgentSkillToolExecutor`
    - 现已优先读取当前项目的 `agent_skill_loadouts.json`
    - 若存在命中的项目级 loadout，会先走 `AgentSkillLoadoutResolverService` 收束最终技能集合
    - 若不存在命中 loadout，则自动退回 `AgentProfile.skills / skillGroups`
  - `load_agent_skill` 现在返回的 `available_skills` 已正式按 resolved loadout 过滤，不再只看静态 agent 默认声明
  - `load_agent_skill` 的结果现已附带最小运行投影：
    - `resolved_skill_ids`
    - `resolved_loadout_source`
    - `resolved_loadout_has_explicit_selection`
    - `resolved_loadout_issues`
  - 当前项目级 loadout 选择策略已先收束为保守版本：
    - 同 agent 下，优先命中 `project_type` 精确匹配
    - 其次退回 global loadout
    - 如果 loadout 依赖 `agent_group / mode / stage` 这些当前运行链尚未提供的维度，则暂不自动套用
- 本轮刻意未做：
  - 历史恢复 UI
  - save-as-group UI
  - 让更多工具或 app 页面消费 loadout projection
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/agents/agent_skill_loadout_selection_service.dart lib/src/agents/agent_skill_summary_service.dart test/agent_skill_loadout_selection_service_test.dart test/agent_skill_services_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/agent_skill_loadout_selection_service_test.dart test/agent_skill_services_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart analyze lib/novel_agent_adapters.dart lib/src/tools/project_agent_skill_runtime_loadout_service.dart lib/src/tools/project_agent_skill_tool_executor.dart lib/src/tools/project_tool_dispatcher.dart lib/src/bootstrap/adapter_bundle.dart test/project_agent_skill_runtime_loadout_service_test.dart test/project_agent_skill_tool_executor_test.dart test/project_agent_skill_loadout_repository_test.dart test/project_agent_skill_loadout_history_repository_test.dart test/project_skill_loadout_save_as_group_service_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_agent_skill_runtime_loadout_service_test.dart test/project_agent_skill_tool_executor_test.dart test/project_agent_skill_loadout_repository_test.dart test/project_agent_skill_loadout_history_repository_test.dart test/project_skill_loadout_save_as_group_service_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_selection_service.dart`
    - 后续若 app/runtime 真能提供 `agent_group / mode / stage` 上下文，可继续扩更细的命中策略，不要把这类选择逻辑塞回 executor
  - `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_runtime_loadout_service.dart`
    - 后续若别的工具、CLI 或 UI 也要消费项目级 loadout，优先复用这里，不要各自重复读 repository

---

## 0.3 Session SL-03 完成记录

- 已完成 `Session SL-03：项目级持久化、历史快照与 preset 保存骨架`
- adapters 已新增并明确：
  - `ProjectAgentSkillLoadoutRepository`
  - `ProjectAgentSkillLoadoutDocumentCodecService`
  - `ProjectAgentSkillLoadoutPathService`
  - `ProjectAgentSkillLoadoutHistoryRepository`
  - `ProjectAgentSkillLoadoutHistoryDocumentCodecService`
  - `ProjectAgentSkillLoadoutHistoryPathService`
  - `ProjectSkillLoadoutSaveAsGroupService`
- 当前行为已经固定：
  - 当前项目实际装载固定写入：
    - `.novel_agent/settings/agent_skill_loadouts.json`
  - 历史快照固定写入：
    - `.novel_agent/history/agent_skill_loadouts/`
    - 并通过 index 文档维护条目列表
  - 显式另存为技能组固定写入：
    - `skill_groups/<group_id>/skill_group.json`
  - 三条路径已正式分离：
    - 当前装载不是历史快照
    - 历史快照不会自动资产化
    - 只有显式 save-as-group 才生成 skill group 资产
- 本轮刻意未做：
  - UI 编辑器
  - 运行链接线
  - 自动历史记录策略
- 本轮验证结果：
  - `packages/novel_agent_adapters`
    - `dart analyze lib/src/storage/project_agent_skill_loadout_document_codec_service.dart lib/src/storage/project_agent_skill_loadout_history_document_codec_service.dart lib/src/storage/project_agent_skill_loadout_history_path_service.dart lib/src/storage/project_agent_skill_loadout_history_repository.dart lib/src/storage/project_agent_skill_loadout_path_service.dart lib/src/storage/project_agent_skill_loadout_repository.dart lib/src/storage/project_skill_loadout_save_as_group_service.dart test/project_agent_skill_loadout_repository_test.dart test/project_agent_skill_loadout_history_repository_test.dart test/project_skill_loadout_save_as_group_service_test.dart`
    - 通过
  - `packages/novel_agent_adapters`
    - `dart test test/project_agent_skill_loadout_repository_test.dart test/project_agent_skill_loadout_history_repository_test.dart test/project_skill_loadout_save_as_group_service_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_adapters/lib/src/storage/project_agent_skill_loadout_repository.dart`
    - 后续 `SL-04` 可继续接运行态解析，但不要把 resolver 规则写回 repository
  - `packages/novel_agent_adapters/lib/src/storage/project_skill_loadout_save_as_group_service.dart`
    - 后续 UI 若要接“另存为技能组”，优先桥接这里，不要让页面自己拼 skill_group 文档

---

## 0.2 Session SL-02 完成记录

- 已完成 `Session SL-02：装载解析与冲突策略`
- core 已新增并明确：
  - `AgentSkillLoadoutResolverService`
  - `SkillLoadoutExpansionService`
  - `SkillLoadoutConflictPolicyService`
  - `SkillLoadoutExpansion`
  - `SkillLoadoutConflictResult`
  - `ResolvedAgentSkillLoadoutEntry`
  - `ResolvedAgentSkillLoadoutEntrySource`
  - `ResolvedAgentSkillLoadoutEntrySourceKind`
  - `AgentSkillLoadoutIssue`
  - `AgentSkillLoadoutIssueCode`
- 当前行为已经固定：
  - skill loadout 的正式解析顺序已收束为：
    - profile 默认 direct skills
    - profile 默认 skill groups
    - loadout 选中的 skill groups
    - loadout 追加的 extra skills
    - loadout disabled skills 最后裁剪
  - `ResolvedAgentSkillLoadoutBuilderService` 不再提前把 profile 默认声明和 loadout 显式选择预混成一份列表，避免丢失来源信息
  - `ResolvedAgentSkillLoadout` 现在已能稳定输出：
    - `entries`
    - `finalSkillIds`
    - `issues`
  - `AgentSkillScopeService` 已退回兼容 facade：
    - 旧调用入口仍保留
    - 实际展开、去重、builtin tool 过滤、可加载 skill 交集与 disabled 裁剪已下沉到新 resolver 链
- 本轮诊断结果已明确支持：
  - `missingSkillGroup`
  - `unavailableSkill`
  - `builtinToolFiltered`
  - `disabledSkillMissingTarget`
- 本轮刻意未做：
  - 项目级持久化
  - 历史快照
  - save-as-group
  - app / UI 接线
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/agents/agent_skill_loadout_issue.dart lib/src/agents/agent_skill_loadout_issue_code.dart lib/src/agents/agent_skill_loadout_resolver_service.dart lib/src/agents/agent_skill_scope_service.dart lib/src/agents/resolved_agent_skill_loadout.dart lib/src/agents/resolved_agent_skill_loadout_builder_service.dart lib/src/agents/resolved_agent_skill_loadout_entry.dart lib/src/agents/resolved_agent_skill_loadout_entry_source.dart lib/src/agents/resolved_agent_skill_loadout_entry_source_kind.dart lib/src/agents/skill_loadout_expansion.dart lib/src/agents/skill_loadout_expansion_service.dart lib/src/agents/skill_loadout_conflict_result.dart lib/src/agents/skill_loadout_conflict_policy_service.dart test/agent_skill_loadout_contracts_test.dart test/agent_skill_services_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/agent_skill_loadout_contracts_test.dart test/agent_skill_services_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_resolver_service.dart`
    - 后续 `SL-04` 可继续接项目级 loadout 与真实运行链，不要把运行细节写回 facade
  - `packages/novel_agent_core/lib/src/agents/skill_loadout_conflict_policy_service.dart`
    - 后续若要补更细的冲突优先级或诊断细化，可继续扩这里，不要回改 expansion service

---

## 0.1 Session SL-01 完成记录

- 已完成 `Session SL-01：SkillLoadout 核心合同`
- core 已新增并明确：
  - `AgentSkillLoadout`
  - `AgentSkillLoadoutSource`
  - `AgentSkillLoadoutScope`
  - `ResolvedAgentSkillLoadout`
  - `ResolvedAgentSkillLoadoutBuilderService`
- 当前行为已经固定：
  - `AgentProfile.skills / skillGroups` 继续保留为静态默认声明
  - `AgentSkillLoadout` 正式承担“当前项目 / 当前智能体的实际技能装载”语义
  - `ResolvedAgentSkillLoadoutBuilderService` 当前只负责：
    - 把 profile 默认声明与显式 loadout 折成稳定合同
    - 保留 `disabled_skill_ids`
    - 保留 group / extra skill 的独立表达
  - 本轮刻意未做：
    - skill group 展开
    - disabled skill 实际裁剪
    - 缺失 skill / group 诊断
    - 项目级持久化与 UI
- 本轮验证结果：
  - `packages/novel_agent_core`
    - `dart analyze lib/novel_agent_core.dart lib/src/agents/agent_skill_loadout.dart lib/src/agents/agent_skill_loadout_scope.dart lib/src/agents/agent_skill_loadout_source.dart lib/src/agents/resolved_agent_skill_loadout.dart lib/src/agents/resolved_agent_skill_loadout_builder_service.dart test/agent_skill_loadout_contracts_test.dart test/agent_skill_services_test.dart`
    - 通过
  - `packages/novel_agent_core`
    - `dart test test/agent_skill_loadout_contracts_test.dart test/agent_skill_services_test.dart`
    - 通过
- 后续扩展点：
  - `packages/novel_agent_core/lib/src/agents/resolved_agent_skill_loadout_builder_service.dart`
    - 后续 `SL-02` 可继续在此基础上接入 group 展开与 final skill set 解析，但不要把冲突策略也塞进同一个文件
  - `packages/novel_agent_core/lib/src/agents/agent_skill_loadout_scope.dart`
    - 后续若要补 agent group / mode / stage 级专属装载规则，可继续扩这里，不要回改 `AgentProfile`

---

## 1. 背景与当前状态

当前代码里，其实已经同时存在这三层素材：

- `skill`
- `skill_group`
- `AgentProfile.skills / AgentProfile.skillGroups`

也就是说，系统不是“完全没有技能组”，而是：

- 已经有 `skill_group` 作为静态组合定义
- 但还没有把“当前项目 / 当前智能体 / 当前阶段到底启用了什么技能组合”正式建模成独立运行对象

这会导致几个长期问题：

1. `agent.skills` 和 `agent.skill_groups` 目前更像静态声明，难以表达当前项目里的临时组合。
2. 如果把“用户这次选中的多个技能”自动升格成新 `skill_group`，会快速制造大量一次性垃圾组。
3. 如果只保留“项目里临时选中的 skill id 列表”，又很难复用、命名、迁移和推荐。
4. “可复用预设”和“当前会话 / 当前项目的实际选择”是两种不同语义，不能继续混着表达。

---

## 2. 设计结论

本轮正式采用三层表达，不走两种极端方案。

### 2.1 保留的三层

1. `Skill`
   - 原子能力
   - 最小单位
   - 必须保留

2. `SkillGroup`
   - 可复用预设
   - 有名字、描述、可选适用范围
   - 只表达“推荐组合”

3. `SkillLoadout`
   - 当前项目 / 当前智能体 / 当前阶段的实际技能装载
   - 是运行时/项目态对象，不等同于可复用资产

### 2.2 最终解析公式

建议统一为：

```text
final skill set
= group_ids 展开
+ extra_skill_ids
- disabled_skill_ids
```

### 2.3 明确禁止

禁止以下做法：

1. 每次用户多选多个技能，就自动创建一个新 `skill_group`
2. 把 `skill_group` 做成权限、工具策略、运行状态的混合体
3. 把“当前项目实际选择”直接写回 agent 静态包定义
4. 让 UI 自己展开 group、去重 skill、判定冲突

### 2.4 产品语义固定

- `skill`：原子能力
- `skill_group`：可复用预设
- `skill_loadout`：当前实际选择
- `history loadout`：历史选择快照，不是 skill group

也就是说：

- 可以从历史 loadout 恢复
- 可以明确“另存为 skill group”
- 但不能把历史记录或临时组合自动资产化

---

## 3. 总体约束

### 3.1 必须遵守 `agent.md`

尤其继续遵守：

- 先 core，后 adapters，再 app，最后 UI
- 不造新的全能 controller / manager
- composition root 只放在 bootstrap
- 单文件超过 `400` 行就复核
- 接近 `700` 行必须主动拆

### 3.2 本轮优先使用的模式

- state object
- resolver / expander
- repository
- projection service
- preset registry

### 3.3 本轮不要做的事

- 不把 skill group 变成工具权限中心
- 不做“大而全”的技能生态重写
- 不把历史记录直接做成 bundle/export 主线
- 不提前做复杂美化 UI

---

## 4. 关键批判与改良结论

### 4.1 不应只保留技能组

如果只保留 `skill_group`：

- 临时组合会污染生态
- 一次性试验也会被资产化
- 用户很难区分“当前项目正在这么用”和“我要沉淀成长期预设”

因此：

- `skill_group` 必须保留
- 但不能成为唯一入口

### 4.2 不应只保留 skill id 列表

如果只保留 `skill_ids`：

- 缺少命名和复用能力
- 很难做推荐组合、默认组合、跨项目复用
- “历史列表”最后会变成没有名字的伪技能组

因此：

- `skill_ids` 必须保留
- 但应作为 `loadout` 的一部分，而不是唯一产品对象

### 4.3 最合理的是“预设”和“当前装载”分离

正式结论：

- `skill_group` 负责复用
- `skill_loadout` 负责当前选择

这两层分离后，才适合继续做：

- 项目级恢复
- 历史组合
- 一键套用
- 另存为预设
- 项目类型 / 智能体组 / 阶段专属默认装载

---

## 5. 推荐执行顺序总览

1. `Session SL-01`：core 的 `SkillLoadout` 合同与展开模型
2. `Session SL-02`：resolver / merge / conflict policy
3. `Session SL-03`：项目级持久化、历史快照与 preset 保存骨架
4. `Session SL-04`：运行链接线，让 agent 真正消费 loadout
5. `Session SL-05`：生态页最小 UI，支持选组、补技能、禁技能、恢复历史
6. `Session SL-06`：探针、回归、文档回填

总量控制在 6 个 session，足够分层，又不会过碎。

---

## 6. Session SL-01：SkillLoadout 核心合同

### 本轮目标

先在 core 里正式定义“当前技能装载”是什么，但不碰任何 UI 和落盘。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- 本文档
- `packages/novel_agent_core/lib/src/agents/agent_profile.dart`
- `packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart`

### 必须完成

1. 建立 core 领域对象，例如：
   - `AgentSkillLoadout`
   - `AgentSkillLoadoutSource`
   - `AgentSkillLoadoutScope`
   - `ResolvedAgentSkillLoadout`
2. 明确 loadout 至少支持：
   - `skill_group_ids`
   - `extra_skill_ids`
   - `disabled_skill_ids`
3. 明确 loadout 与静态 `AgentProfile.skills / skillGroups` 的关系：
   - profile 是默认声明
   - loadout 是当前项目/当前智能体的实际选择
4. 保证数据模型可供 GUI / CLI / adapters 共用

### 本轮不要做

- 不做 repository
- 不做 UI
- 不改实际执行链
- 不自动保存历史

### 本轮重点拆耦

- `loadout contract`
- `source/scope contract`
- `resolved loadout contract`

### 完成判定

- core 已能独立表达“当前技能装载”
- 不再需要把当前技能组合塞回 `AgentProfile`
- 不依赖文件系统或 Flutter

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-01 执行。先阅读 agent.md、本文件、packages/novel_agent_core/lib/src/agents/agent_profile.dart、packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart。先只做 core 合同：建立 AgentSkillLoadout、AgentSkillLoadoutSource、AgentSkillLoadoutScope、ResolvedAgentSkillLoadout，明确 skill_group_ids、extra_skill_ids、disabled_skill_ids 三层表达，以及它们与 AgentProfile.skills / skillGroups 的边界。不要做 UI，不要做持久化，不要改执行链。
```

---

## 7. Session SL-02：装载解析与冲突策略

### 本轮目标

把 “group 展开 + extra skill + disabled skill + 默认 profile 技能” 正式解析成最终技能集合。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- 本文档
- `packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart`
- `packages/novel_agent_core/lib/src/agents/builtin_skill_group_catalog_service.dart`

### 必须完成

1. 建立解析服务，例如：
   - `AgentSkillLoadoutResolverService`
   - `SkillLoadoutExpansionService`
   - `SkillLoadoutConflictPolicyService`
2. 正式支持：
   - skill group 展开
   - extra skill 补充
   - disabled skill 去除
   - 去重
3. 明确默认合并顺序：
   - profile 默认声明
   - loadout group
   - loadout extra
   - loadout disabled
4. 为后续 UI 提供：
   - 最终 skill ids
   - 来源说明
   - 无效引用 / 缺失 skill / 缺失 group 的结构化原因

### 本轮不要做

- 不做 repository
- 不做 app 页面
- 不做“另存为 skill group”

### 本轮重点拆耦

- `group expander`
- `merge policy`
- `diagnostic result`

### 完成判定

- core 已能稳定输出最终技能集合
- 不需要页面自己展开技能组
- 冲突和缺失能结构化返回，而不是只给字符串

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-02 执行。先阅读 agent.md、本文件、packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart、packages/novel_agent_core/lib/src/agents/builtin_skill_group_catalog_service.dart。只做 core 解析层：建立 AgentSkillLoadoutResolverService、SkillLoadoutExpansionService、SkillLoadoutConflictPolicyService，把 profile 默认技能、skill groups、extra skills、disabled skills 正式合并成最终技能集合，并输出结构化诊断结果。不要做持久化，不要做 UI。
```

---

## 8. Session SL-03：项目级持久化、历史快照与 preset 保存骨架

### 本轮目标

把当前项目的实际装载、历史组合和“明确保存为技能组”三条路径落到 adapters。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/migration-progress.md`

### 必须完成

1. 建立项目级 loadout 仓储，例如：
   - `ProjectAgentSkillLoadoutRepository`
   - `ProjectAgentSkillLoadoutCodecService`
2. 建立历史快照仓储，例如：
   - `ProjectAgentSkillLoadoutHistoryRepository`
3. 建立“显式另存为技能组”的 use case / service，例如：
   - `SaveSkillLoadoutAsGroupUseCase`
4. 明确规则：
   - 历史 loadout 不自动变 skill group
   - 只有用户显式保存时才生成新 group
   - 项目当前装载只影响当前项目

### 本轮不要做

- 不做 UI
- 不做复杂导入导出
- 不做全局云同步

### 本轮重点拆耦

- `project loadout repository`
- `history repository`
- `save-as-group use case`

### 完成判定

- 当前项目技能装载可正式落盘
- 历史快照与技能组资产化是两条不同路径
- 没有把三种职责写进一个大 repository

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-03 执行。先阅读 agent.md、本文件、docs/migration-progress.md。把项目级技能装载正式落到 adapters：建立 ProjectAgentSkillLoadoutRepository、ProjectAgentSkillLoadoutHistoryRepository，以及 SaveSkillLoadoutAsGroupUseCase。重点保证“当前装载”“历史快照”“显式保存为技能组”三条路径分离。不要做 UI，不要顺手做导入导出大改。
```

---

## 9. Session SL-04：运行链接线与智能体实际消费

### 本轮目标

让 agent 真正按项目 loadout 跑，而不是只看静态 `skills / skill_groups`。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- 本文档
- `packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_agent_skill_tool_executor.dart`

### 必须完成

1. 把项目级 loadout 接回运行链
2. 让以下路径统一消费 resolved loadout：
   - agent skills summary
   - available skill listing
   - `load_agent_skill`
   - 后续默认技能路由
3. 明确 fallback：
   - 没有项目 loadout 时，退回 `AgentProfile.skills / skillGroups`
4. 为后续 app 提供最小 projection：
   - 当前启用技能
   - 来源（group / extra / disabled）
   - 是否来自历史恢复

### 本轮不要做

- 不做大 UI
- 不做复杂编辑器
- 不做新的技能策略主线

### 本轮重点拆耦

- `runtime loadout resolver`
- `tool-facing projection`
- `fallback policy`

### 完成判定

- 智能体运行时已能真实读到项目级技能装载
- 不需要把装载逻辑塞回 UI controller
- 原有静态 agent profile 仍保留兼容路径

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-04 执行。先阅读 agent.md、本文件、packages/novel_agent_core/lib/src/agents/agent_skill_scope_service.dart、packages/novel_agent_adapters/lib/src/tools/project_agent_skill_tool_executor.dart。把项目级 skill loadout 正式接回运行链：让技能摘要、available skills、load_agent_skill 等路径优先消费 resolved loadout，并在没有项目装载时退回 AgentProfile.skills / skillGroups。不要做大 UI，不要新开技能策略主线。
```

---

## 10. Session SL-05：生态页最小 UI 与项目内装载编辑

### 本轮目标

在核心和持久化都稳定后，再给用户一个最小但正式的入口。

### 预计改动量

- 约 `1100 ~ 1900` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/frontend-evolution-session-order.md`

### 必须完成

1. 在现有生态页或项目级配置入口中提供最小编辑能力：
   - 选择 skill groups
   - 追加 extra skills
   - 禁用 selected skills
   - 从历史恢复
   - 显式“保存为技能组”
2. 默认把“保存为技能组”做成明确动作，不自动发生
3. 页面只消费 projection / view data，不自己展开 group
4. UI 先求结构正确，不求视觉终局

### 本轮不要做

- 不做完整生态中心大改版
- 不做复杂拖拽编排
- 不做大面积审美重构

### 本轮重点拆耦

- `view data service`
- `editing action service`
- `save-as-group action bridge`

### 完成判定

- 用户可在项目内正式调整智能体技能装载
- 可恢复历史组合
- 可明确另存为技能组
- 没有把 group 展开 / 冲突解析写进 widget

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-05 执行。先阅读 agent.md、本文件、docs/frontend-evolution-session-order.md。只做技能装载最小 UI：支持选择 skill groups、追加 extra skills、禁用 selected skills、从历史恢复，以及显式“保存为技能组”。不要自动创建 skill group，不要把 group 展开和冲突解析写进 widget，不追求最终视觉。
```

---

## 11. Session SL-06：探针、回归与文档回填

### 本轮目标

只做真实闭环验证和必要修补，不开新主线。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- 本文档
- `docs/migration-progress.md`

### 必须完成

1. 运行至少这些回归：
   - 单智能体默认技能声明
   - 只选 skill group
   - skill group + extra skills
   - skill group + disabled skills
   - 从历史恢复
   - 显式保存为 skill group
   - 切项目后不串当前 loadout
2. 如有必要，新增专门 probe
3. 只修探针暴露的问题
4. 回填文档

### 本轮不要做

- 不借探针重写生态页
- 不继续扩复杂 UI
- 不开 bundle/export 新主线

### 本轮重点拆耦

- probe 脚本和业务服务分离
- 问题修补保持局部

### 完成判定

- skill / skill_group / skill_loadout 三层语义都已闭环
- 当前项目技能装载不会串项目
- 文档状态与代码状态一致

### 建议提示词

```text
按 docs/skill-loadout-redesign-session-order.md 的 Session SL-06 执行。先阅读 agent.md、本文件、docs/migration-progress.md。只做技能装载总回归与必要修补：覆盖单智能体默认技能、skill group、extra skills、disabled skills、历史恢复、显式保存为技能组，以及切项目不串当前 loadout。只修探针暴露的问题，不开新主线，完成后回填文档。
```

---

## 12. 探针开启时机

建议节奏：

1. `SL-01 ~ SL-02`
   - 只跑 core unit test
2. `SL-03`
   - 跑 repository / codec test
3. `SL-04`
   - 跑运行链 smoke
4. `SL-05`
   - 跑 app/widget smoke
5. `SL-06`
   - 再跑真实 probe / 总回归

原因：

- 太早跑 probe，只会测到半成品
- 容易把临时 app bridge 误当正式设计
- 会倒逼把本该在 core 的解析逻辑提前写回 UI

---

## 13. 执行规则

后续按本文件推进时，默认继续遵守：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或者暴露强关联回归，先补完，不开启下一轮。
3. 每轮开始前至少复读：
   - `agent.md`
   - 本文件对应 session
   - 该 session 指向的相关文件
4. 每轮结束时都要说明：
   - 本轮完成了什么
   - 哪些文件是后续扩展点
   - 哪些点被明确延期
5. 即便做到 UI，也继续遵守：
   - 单一职责
   - 避免单文件过重
   - view data / controller / widget / service 分层

---

## 14. 当前推荐起点

从当前状态看，最自然的起点是：

1. `Session SL-01`
2. `Session SL-02`

原因很明确：

- 现在最重要的不是先做 UI，而是把 `skill_group` 和 `current loadout` 的语义分开
- 如果不先立住 loadout 合同，后面的 repository、运行链、生态页都会反复返工
- 当前代码已经有 `skills` 和 `skill_groups`，最适合先做“加一层 current loadout”，而不是推翻原有结构
