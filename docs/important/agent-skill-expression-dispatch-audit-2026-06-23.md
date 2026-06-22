# 智能体 / 技能 / 表达限制 调度链审计与修复（2026-06-23）

针对 session 目标「考察所有相关智能体、智能体组、技能、技能组、表达限制等部分，参考设计，修复问题、不可用、逻辑错漏、提示词无法调度正确等」，对 core/adapters 的相关子系统做了一轮深度审计与修复。

分支：`fix/agent-skill-expression-dispatch-2026-06-23`（相对 `main` 22 个文件）。

## 已修复（含回归测试）

### 1. 技能 ID snake_case / kebab-case 不匹配（头号调度 bug）`3bbcf72`
- 内置技能包经 SKILL.md 解析得到 **kebab-case** id（`generate-outline`），但智能体文档（`default_generalist/AGENT.md`）、内置技能组目录、技能路由策略历史上全部用 **snake_case** 引用（`generate_outline`）。两端逐字比较、无归一化 → 5/7 内置技能在生产路径被判 `unavailableSkill` 静默过滤，`load_agent_skill` 也匹配不到包。
- 新增 `SkillIdNormalizer`，在所有技能 id 比较/查找边界（`ProjectAgentSkillToolExecutor`、`SkillLoadoutConflictPolicyService`、`AgentSkillSummaryService`）统一归一到 canonical kebab。归一化只发生在比较环节，不改写持久化或回显的原始 id，旧 snake_case 数据与现有测试不受影响。

### 2. 表达限制注入策略死分支 + force 优先级 `f6d25bd`
- `_modeFromExecutionPolicy` 在 brief 判定之前没有先判 force，导致 force+brief 被降级成 briefOnly，与「force = 用户可见最强约束 → 强注入」的设计相悖；第二分支里的 `|| none` 永不可达（死代码）。重排判定顺序使 force 权威。

### 3. 派生单成员组判别 flag 拼写漂移 `b0a68d8`
- 「派生自单智能体」标记位在三处用三种拼写（adapter `derived_from_single_agent` / controller `derived_from_agent_binding` / candidate resolver `derived_from_project_agent_binding`），而 `AgentGroupDelegationCapabilityService.childAgentIds` 的委派短路只认第一种。当 controller 派生组从 summary.members 产生多成员时，合成单成员组可能被错误允许委派。现统一识别三种拼写。

### 4. de_ai 风险信号截断与扫描器不一致 `2839114`
- `ExpressionConstraintContextSectionService` 把 risk_signals 截断到 8，但 `ExpressionConstraintSurfaceRiskScanService` 用全部信号扫描正文。内置 de_ai 有 11 条信号，模型从不知道第 9-11 条（`总而言之`/`值得一提的`/`这一刻改变了一切`）却会因它们被判定违反。risk_signals 是短词、不占预算，现不截断，与扫描器对齐。

### 5. creative_rule_stack.isEmpty 回归保护 `2839114`
- isEmpty 的 6 字段修复此前无测试保护。新增 `creative_rule_stack_test.dart` 覆盖 binding-only / style-binding-only / profile-only 等历史回归点。

### 6. constraint_type 闭集分类器统一（消除 "accepted but never applied"）`20c112f`
- `constraint_type` 是自由字符串，bridge 用严格前缀匹配（`expression_constraint`/`expression_constraint.*`），`NarrativePermissionPolicyService` 用宽松子串 `contains('expression')`。agent 误发 `'expression'`（漏 `_constraint`）会被权限策略判为高风险需确认、却在 bridge 静默丢弃。新增 `ConstraintTypeClassifier` 单一真相源，bridge 与 permission policy 同源判定；schema 补 description 引导规范取值。

## 经实证核实为「非 bug」（仅加回归保护）`8501840`

### C3：内置协作智能体采样参数被归一化器丢弃 —— 不成立
- 审计断言「builtin collaborator 的 temperature/top_p/top_k 放顶层会被归一化器丢弃」。实际 `AgentPackageMetadataProfileService.extractExtensions` 会把顶层 temperature/top_p/top_k 拉进 extensions，normalizer 经 extensionSampling 保留它们（回退分支也是顶层归一化值）。`editor_in_chief` 0.7/0.9、`writer` 0.95/0.97 全部原样保留。新增 `agent_profile_normalizer_service_test.dart` 锁定。

## 调研后判定为「设计缺口」延后（未强行改动最热路径）

### C1/C2：系统提示硬编码「综合创作智能体」压制选中智能体身份
- 经深挖：`AgentProfileCatalogService.fallbackDefaultAgent()` 的 system_prompt 只是个最小桩（不是 AGENT.md 那段丰富角色原则），且 `builtinProfilesFromJson` 是死代码（无 JSON asset）。**丰富的 AGENT.md persona 根本未被加载进运行时 catalog**——这是「内置 agent 包未接入运行时 catalog」的设计缺口（同 RAG wiring 那类），不是可在本次安全收口的独立 bug。
- 对当前单智能体基线（primary 恒为 default_generalist），硬编码身份行正确匹配，不构成调度错误。强行改最热路径的 prompt 内容而无法用真实模型验证会违反「如实报告结果」原则。**延后**：随多成员主智能体落地时，一并接入 builtin agent 包加载与 persona 注入。

## 明确延后（更大设计任务，不在本次范围）

- **表达限制 binding 按 scope 过滤（审计 B）**：bridge 的 `projectExpressionConstraintBindings` 未对 legacy 绑定按 targetAgentIds/targetModeIds/targetStageIds 过滤（仅 narrative 提案派生者经 `_matchesRuntime`）。真正修复点在 bridge/resolver 的 scope 过滤总闸，需设计决策，非 surface scan 一处可独立收口。
- **内置技能组引用的幽灵技能**（`project_context_research`/`artifact_routing`/`revision_workflow`/`interactive_decision_design`/`task_workflow_planning`/`memory_maintenance`/`skill_blueprint_design`）：被多个内置组引用但无对应 SKILL.md 包，静默被 availableSet 过滤。属内容缺口，需补技能包或裁剪组定义，不能凭空 fabricate。
- **技能能力词汇表不一致**：`SkillCapabilityCatalogService` 只认 7 个能力，而 SKILL.md 声明的是另一套（`file_read` 等），导致校验恒报「未识别 capability」。需统一词汇表。
- **`_matchesAgent` 松散子串匹配**（`project_prompt_contract.dart:401-414`）：拼接 id+name+role+system_prompt 后 `contains(token)` 会误分类 agent，影响 domainToolGuidance/informationToolGuidance 注入。需收紧为精确字段匹配。

## 验证

- core 全套 **968/968** 通过（新增 18 个回归测试，零回归）。
- adapters 全套 452 通过 / 2 失败，2 个失败均为 RAG 测试 teardown 的 Windows temp 目录文件锁（errno 32），与本轮改动无关（本分支 22 个文件零 RAG 相关），是先存环境 flake。
- `flutter analyze` 改动文件零 issue（37 个 warning 全在未触碰的先存文件）。
