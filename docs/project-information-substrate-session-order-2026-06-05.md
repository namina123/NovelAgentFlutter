# NovelAgentFlutter 共享叙事信息基座任务顺序文档

最后更新：2026-06-05

主线代号：`PIS`（Project Information Substrate）

关联分析文档：

- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `docs/writing-continuity-foundation-session-order-2026-05-31.md`
- `docs/book-deconstruction-continuation-analysis-2026-05-31.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/continuity/narrative_state/`
- `packages/novel_agent_core/lib/src/tools/domain/`
- `packages/novel_agent_core/lib/src/assets/`
- `packages/novel_agent_core/lib/src/context/`
- `packages/novel_agent_core/lib/src/runtime/project_context_file_selection_service.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/storage/`
- `packages/novel_agent_adapters/lib/src/tools/project_gateway_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_bridge_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_core/lib/src/deconstruction/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_cli/`

---

## 1. 这份文档解决什么

这份文档把“共享叙事信息策略”拆成可执行任务。目标不是再做一个题材系统，而是补齐所有写作链路共享的信息基座：

1. 普通小说、长任务、拆书、拆书续写、解书都能共享知识、设计元素、研究笔记、来源证据和引用作品边界。
2. 拆书中发现的写作巧思、符号系统、命名规则、结构设计，不再只散在 Markdown 或提示词里，而能成为可保存、可引用、可激活、可确认的结构化事实。
3. 联网搜索不再只是 `request_gateway_tool` 的一次性结果，而是通过研究合同、来源、摘要、可用事实、权限策略进入项目。
4. 长任务 checkpoint 不只看章节是否落盘，还能看到信息层是否缺证据、冲突、需要研究或需要用户确认。
5. GUI / CLI 最后只消费稳定合同，不替 core/adapters 解释 payload，也不兜底底层事实源缺口。

---

## 2. 关于“巧思 / 设计”的定位

这里必须明确：**巧思 / 设计不是只靠智能体提示词改善就够了。**

提示词可以做到：

1. 引导智能体在拆书、写作、审稿时主动寻找巧思。
2. 提醒智能体把巧思用工具提交。
3. 降低漏报概率。

但提示词不能稳定做到：

1. 防止下一轮遗忘。
2. 保留来源证据。
3. 区分用户设定、原文事实、AI 推断、外部研究。
4. 让上下文激活器知道何时注入。
5. 让用户确认某个设计是否成为长期规则。
6. 让长任务 supervisor 判断缺资料、冲突或高风险引用。

所以本主线把“巧思 / 设计”设为一等信息对象：

```text
DesignElementCard
```

它用于表达：

1. 符号系统。
2. 命名规律。
3. 神话 / 星象 / 八卦等文化映射。
4. 章节结构暗线。
5. 伏笔设计方法。
6. 特殊文体、叙事手法、重复意象。
7. 原作里可被续写继承或变奏的“小巧思”。

结论：

```text
提示词负责发现和提交。
结构化信息层负责保存、证据、权限、激活和复用。
```

---

## 3. 与旧文档的关系

### 3.1 ONS 是底座，不推翻

`ONS-01` 到 `ONS-44` 已完成：

1. 开放 claims / profiles / ledger / semantic review。
2. 领域 toolcall。
3. 章节交付状态机。
4. constraint binding。
5. context activation。
6. 普通项目与长任务真实短验。
7. GUI / CLI 最小消费。

本主线不重做这些，而是在 ONS 上新增信息基座。

### 3.2 写作连续性文档是旧层级，不再题材化扩张

`writing-continuity-foundation-session-order-2026-05-31.md` 已经证明：

1. 普通项目和拆书要共用 continuity。
2. 快穿、死亡回归、多世界只是压力例子。
3. 拆书只是一条高密度输入方向。

本主线继续这一结论，但把“知识 / 巧思 / 研究 / 来源作品”上升为共享信息层。

### 3.3 MuMu 只吸收思想

继续只吸收：

1. 后台任务可观察。
2. 章节上下文分层。
3. 角色 / 世界 / 记忆 / 伏笔作为工程资料。
4. 拆书导入后继续服务写作。

不复制 GPL 代码、字段、文案和实现。

### 3.4 MuMu 可吸收点到本主线的映射

这里补一个显式映射，防止后续任务把“参考 MuMu”误解为复制实现，或把它只当成提示词优化。

1. 后台任务表 / 状态 / 进度 / 错误 / 重试：
   - 已由长任务 supervisor / control plane 主线承接。
   - 本主线不重做后台任务表，只在 PIS-23 提供信息层 checkpoint signal，让 supervisor 能看到 pending research、high-risk reference、design conflict、required info omitted 等结构化风险。

2. 章节上下文服务 / 最近章节 / 上章结尾 / 记忆相关度：
   - 继续复用 `ContextActivationReport` 和现有 activation planner。
   - 本主线在 PIS-20 增加 information activation bridge，把 knowledge / design / research / reference 作为可解释的上下文候选，支持 selected / omitted / truncated / priority。

3. 记忆 / 伏笔 / 角色 / 组织分层：
   - 已有 `CharacterProfile`、`WorldRuleSet`、`ForeshadowRecord`、`RelationshipRecord`、`NarrativeProfile` 等不重做。
   - 本主线补 `ProjectKnowledgeCard` 与 `DesignElementCard`，用于承接那些不适合硬塞进角色表或伏笔表的开放资料，例如符号系统、命名暗线、组织隐喻、结构巧思、文化映射。

4. 拆书导入继续服务写作：
   - PIS-24 专门做 Deconstruction information bridge。
   - 拆书抽取出的原文事实、来源证据、巧思、符号系统、引用作品边界进入 analysis namespace，再经用户确认或策略提升后服务续写，不直接污染写作主 ledger。

5. 外部资料与研究：
   - MuMu 的普通上下文层级不足以表达联网研究、来源、许可证、置信度和可用事实。
   - PIS-06 / PIS-19 引入 `ResearchNote` 和 gateway research bridge，让联网结果先成为可审计研究笔记，再按权限提升为知识或设计提案。

6. 巧思 / 设计：
   - 不能只靠提示词改善。
   - PIS-05 把它定义为 `DesignElementCard`，PIS-11 到 PIS-13 让智能体能通过工具提交，PIS-20 让它进入上下文激活，PIS-24 让拆书能抽取并保留证据。

---

## 4. 已有实现去重审计

### 4.1 已有，不重做

1. ONS 合同：
   - `NarrativeStateClaim`
   - `NarrativeProfile`
   - `NarrativeSemanticReview`
   - `NarrativeConstraintBindingProposal`
   - `ContextActivationReport`

2. 领域工具框架：
   - `DomainToolRequest`
   - `DomainToolOutcome`
   - `NarrativeDomainToolCatalog`
   - `ProjectNarrativeDomainToolExecutor`

3. 章节交付：
   - `submit_chapter_delivery`
   - `ChapterDeliveryStateMachine`

4. 现有资产：
   - `CharacterProfile`
   - `WorldRuleSet`
   - `TimelineRecord`
   - `ForeshadowRecord`
   - `RelationshipRecord`
   - `StyleProfile`
   - `SharedNarrativeAssetReference`

5. 外部能力底座：
   - `request_gateway_tool`
   - `ProjectGatewayToolExecutor`
   - `search_internet`
   - `fetch_url_content`

### 4.2 已有但只是半成品

1. `knowledge/`
   - 现在只是可读目录和低优先级上下文候选。
   - 还不是结构化事实源。

2. `ProjectContextActivationService`
   - 已能激活项目文件、profiles、claims、constraints。
   - 未来不能继续无限扩张，应拆出 information bridge。

3. 拆书 continuity hints / mechanic hints
   - 已能桥接进 analysis namespace。
   - 命名仍偏旧，未来应迁移到中性 design / pattern / continuity hint。

4. gateway search
   - 已能搜索。
   - 还不能把结果变成研究笔记、引用证据和项目知识。

### 4.3 真正要补的层

1. Core information contracts。
2. Core information lifecycle / risk / permission。
3. Information domain tools。
4. Adapters repository / projection / gateway research bridge。
5. Runtime activation bridge。
6. Deconstruction bridge for design elements。
7. Ordinary / long task information delta and checkpoint signals。
8. Mock and gated real probe。
9. GUI / CLI final consumption。

---

## 5. 本轮冻结的架构边界

1. 不把北欧神话、星象、八卦、快穿、死亡回归、同人写成 core 枚举。
2. 不让 `knowledge/` 成为唯一事实源。
3. 不让联网搜索结果只停在聊天里。
4. 不让 core 直接联网。
5. 不让 GUI / CLI 解释开放 payload。
6. 不让 `ProjectWorkflowRuntimeService` 继续吸收新算法。
7. 不让 `ProjectContextActivationService` 变成新的万能上下文中心。
8. 不让智能体无确认地修改长期规则、引用作品边界或高风险外部资料。
9. 不实现完整同人系统，只预留 reference work 与 usage policy。
10. 不复制 MuMu GPL 代码。
11. 不让 probe 形成第二套业务判断。

---

## 6. 目标终态

结构化事实源：

```text
.novel_agent/information/knowledge_cards/*.json
.novel_agent/information/design_elements/*.json
.novel_agent/information/research_notes/*.json
.novel_agent/information/reference_works/*.json
.novel_agent/information/links/*.jsonl
.novel_agent/information/events/*.jsonl
```

可读投影：

```text
knowledge/项目知识摘要.md
knowledge/设计元素摘要.md
research/资料研究摘要.md
references/引用作品边界.md
```

运行时能力：

1. 写作智能体能提交知识卡和设计元素提案。
2. 拆书智能体能把原作巧思、符号系统、来源片段桥到信息层。
3. 研究智能体能请求外部研究并提交研究笔记。
4. 上下文激活能说明本轮注入了哪些知识 / 设计 / 研究资料，为什么注入，哪些被预算裁掉。
5. 长任务 supervisor 能消费信息风险信号，但不读正文做文学判断。
6. GUI / CLI 能查看投影、待确认记录、粗粒度摘要。

---

## 7. Session 数量与顺序设计理由

本主线拆成 `30` 个 session。

理由：

1. 前 8 轮先做 core 合同，不碰 adapters 和 UI。
2. 第 9 到 14 轮做工具、权限和 mock，先验证智能体工具调用可靠性。
3. 第 15 到 20 轮做 adapters、投影、gateway research 和 activation bridge。
4. 第 21 到 24 轮接普通项目、长任务、拆书、解书。
5. 第 25 到 27 轮做 regression / probe。
6. 第 28 到 30 轮才做 CLI / GUI / 文档收口。

每轮都应控制在一次会话可完成的实现量内；若发现上一轮半成品或关联错误，先修上一轮，不开启本轮。

---

## 8. 全局执行规则

每个 session 都必须遵守：

1. 先读本文档、关联分析文档、`agent.md`。
2. 只完成当前 session，不开启下一任务。
3. core 不 import adapters / Flutter。
4. adapters 不成为业务规则中心。
5. GUI / CLI 只消费稳定合同。
6. 优先复用 ONS 模型、repository port、domain tool、activation report。
7. 单文件超过 400 行复核职责，超过 700 行必须拆分。
8. 每轮补 focused test / contract test，文档轮除外。
9. 真实 provider / 联网 probe 必须显式开闸，不默认消耗额度。
10. 不提交真实 key、一次性探针或 GPL 代码。

---

## 9. Session 顺序

### PIS-01 信息层现状审计与落点图

本轮目标：确认当前 knowledge、assets、gateway、deconstruction、activation、GUI/CLI 中的信息相关实现，明确 keep / extend / migrate / freeze。

层级归属：Documentation / Architecture audit。

必读文件：

- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `agent.md`
- `packages/novel_agent_core/lib/src/assets/`
- `packages/novel_agent_core/lib/src/continuity/narrative_state/`
- `packages/novel_agent_core/lib/src/tools/domain/`
- `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_gateway_tool_executor.dart`

必须完成：

1. 新增 `docs/project-information-substrate-implementation-audit-2026-06-05.md`。
2. 列出已有信息相关文件和职责。
3. 标记哪些复用、哪些迁移、哪些冻结。
4. 明确 `knowledge/` 只是投影/素材目录，不是事实源。
5. 明确 `ProjectWorkflowRuntimeService` 和 `ProjectContextActivationService` 不能继续吸收算法。

本轮不要做：

1. 不写 core 代码。
2. 不迁移文件。
3. 不跑真实 probe。

验收标准：

1. 审计文档覆盖 core/adapters/app/CLI/probe。
2. 明确后续每层落点。
3. 无运行时代码改动。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-01，只做信息层现状审计与落点图。必须读取分析文档和 agent.md，新增审计文档，明确 keep / extend / migrate / freeze，不写代码、不迁移文件、不跑真实 probe、不开启下一任务。注意 `knowledge/` 不是事实源，ProjectWorkflowRuntimeService / ProjectContextActivationService 不能继续膨胀。
```

### PIS-02 Core information 命名空间与基础 typedef

本轮目标：建立 `information` core 命名空间和最小导出骨架。

层级归属：Core / domain scaffolding。

必读文件：

- PIS-01 审计文档
- `packages/novel_agent_core/lib/novel_agent_core.dart`
- `packages/novel_agent_core/lib/src/continuity/narrative_state/`

必须完成：

1. 新增 `packages/novel_agent_core/lib/src/information/`。
2. 建立 barrel / typedef / validation code 基础文件。
3. 复用 `JsonMap`、`ValueReaders`、开放 JSON codec，不另造工具。
4. 更新 core 导出。
5. 增加最小 import smoke test。

本轮不要做：

1. 不实现具体 card。
2. 不接 tools/adapters。
3. 不做投影。

验收标准：

1. core analyze 通过。
2. 新目录中性命名，无题材词。
3. 文件轻量。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-02，只做 core information 命名空间与基础 typedef。复用现有 common/json/open codec，不实现具体 card，不接 tools/adapters/UI，不开启下一任务。补最小 import smoke test，运行 core analyze，保持小文件和中性命名。
```

### PIS-03 Information source、usage、activation policy 合同

本轮目标：定义信息来源、使用边界、激活策略，供 knowledge / design / research / reference work 共用。

层级归属：Core / domain contract。

必读文件：

- ONS `NarrativeSourceRef` / `NarrativeEvidenceRef`
- `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_ref.dart`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`

必须完成：

1. 新增 `InformationSourceRef` 或复用/包装 `NarrativeSourceRef` 的轻量扩展。
2. 新增 `InformationUsagePolicy`。
3. 新增 `InformationActivationPolicy`。
4. 支持 source authority、role authority、research depth、activation priority、requires confirmation。
5. 添加 codec / validation tests。

本轮不要做：

1. 不做 knowledge card。
2. 不做权限执行。
3. 不写联网逻辑。

验收标准：

1. usage policy 可表达外部作品、高风险引用、只读研究资料。
2. activation policy 可表达 required / pinned / normal / reference / background。
3. unknown policy fields round-trip。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-03，只做 Information source / usage / activation policy 合同。复用 ONS source/evidence/ref 思路，开放 payload，不能写死题材或文化类型。不做 card、权限执行、联网或 adapters，不开启下一任务。补 codec/validation tests。
```

### PIS-04 ProjectKnowledgeCard 合同

本轮目标：实现通用项目知识卡，承接世界规则、文化资料、命名规则、设定事实等可复用信息。

层级归属：Core / domain contract。

必读文件：

- PIS-03 policy 合同
- `packages/novel_agent_core/lib/src/assets/world_rule_set.dart`
- `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_state_claim.dart`

必须完成：

1. 新增 `ProjectKnowledgeCard`。
2. 字段包含 id、namespace、card_type、title、summary、content_payload、source/evidence/scope refs、activation policy、usage policy、confidence、lifecycle、metadata。
3. payload 开放。
4. 添加 codec / validator / copyWith。
5. 测试普通设定、外部研究、拆书抽取三类 source round-trip。

本轮不要做：

1. 不做 design element。
2. 不做 repository。
3. 不接 prompt。

验收标准：

1. 可表达但不写死神话、星象、八卦。
2. unknown card_type 和 payload 不丢。
3. core tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-04，只实现 ProjectKnowledgeCard core 合同。payload 必须开放，可表达世界规则、文化资料、命名规则等，但不得写死任何题材/文化枚举。不做 repository/tools/adapters/UI，不开启下一任务。补 codec/validator tests。
```

### PIS-05 DesignElementCard 合同

本轮目标：把作品巧思、结构设计、符号系统、重复意象、命名暗线正式建模。

层级归属：Core / domain contract。

必读文件：

- PIS-04 `ProjectKnowledgeCard`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `packages/novel_agent_core/lib/src/assets/foreshadow_record.dart`
- `packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_continuity_hints.dart`

必须完成：

1. 新增 `DesignElementCard`。
2. 字段包含 design_id、namespace、design_label、design_payload、source/evidence refs、scope refs、activation policy、usage policy、confidence、uncertainty、lifecycle、metadata。
3. 支持 linked knowledge cards / claims / assets。
4. 添加 codec / validator tests。
5. 测试“命名暗线”“象征系统”“结构巧思”作为开放 payload round-trip。

本轮不要做：

1. 不靠 prompt 代替模型。
2. 不写固定巧思分类表。
3. 不接拆书 bridge。

验收标准：

1. 明确巧思/设计是结构化事实，不是提示词附属。
2. unknown design payload 保留。
3. core tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-05，只实现 DesignElementCard core 合同。它用于保存作品巧思、符号系统、结构设计、命名暗线等；提示词只能引导提交，不能替代结构化保存。不得写固定分类表，不接拆书/tools/adapters，不开启下一任务。补开放 payload round-trip tests。
```

### PIS-06 ResearchNote 合同

本轮目标：定义外部研究结果如何进入项目，而不是停留在聊天或 gateway 原始结果里。

层级归属：Core / domain contract。

必读文件：

- PIS-03 policy 合同
- `packages/novel_agent_core/lib/src/tools/domain/domain_tool_outcome.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_gateway_tool_executor.dart`

必须完成：

1. 新增 `ResearchNote`。
2. 字段包含 research_id、query、source_kind、source_url_or_ref、citation、summary、usable_facts、uncertainty、license_or_usage_note、created_by、linked_cards、usage_policy、metadata。
3. 区分 facts 与 creative_suggestions。
4. 添加 codec / validator tests。

本轮不要做：

1. 不做联网。
2. 不做 gateway executor。
3. 不做知识卡提升。

验收标准：

1. 研究结果可追溯来源。
2. 可用事实与创作建议分离。
3. source/citation 缺失能给 validation warning 或 error。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-06，只实现 ResearchNote core 合同。必须区分 usable_facts 与 creative_suggestions，保留 citation/source/usage policy。不做联网、gateway、repository 或知识卡提升，不开启下一任务。补 codec/validator tests。
```

### PIS-07 ReferenceWorkRecord 合同

本轮目标：为穿书、同人、跨作品引用、拆书来源作品预留边界，不实现完整同人功能。

层级归属：Core / domain contract。

必读文件：

- PIS-03 `InformationUsagePolicy`
- PIS-06 `ResearchNote`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`

必须完成：

1. 新增 `ReferenceWorkRecord`。
2. 支持 title、creator、version、source refs、relationship_to_project、declared_usage_intent、allowed_usage_summary、risk_notes、requires_confirmation、metadata。
3. relationship 使用开放字符串，不做封闭枚举。
4. 添加 codec / validator tests。

本轮不要做：

1. 不做同人写作功能。
2. 不做版权自动判断。
3. 不做联网。

验收标准：

1. 可表达 deconstructed source、fictional in-world work、fanfic reference、crossover reference，但不锁死为枚举。
2. 高风险引用可标记需要用户确认。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-07，只实现 ReferenceWorkRecord core 合同。目标是预留穿书、同人、跨作品引用和拆书来源边界，不实现完整同人功能、不做版权自动判断、不联网、不接 UI，不开启下一任务。字段保持开放，补 codec/validator tests。
```

### PIS-08 Information link / event / lifecycle 服务

本轮目标：建立知识、设计、研究、引用作品之间的链接与生命周期事件。

层级归属：Core / domain service。

必读文件：

- PIS-04 到 PIS-07 合同
- ONS `NarrativeStateLedgerService`
- ONS `NarrativeProfileProposalService`

必须完成：

1. 新增 `InformationLink`。
2. 新增 `InformationEvent`。
3. 新增 `InformationLifecycleStatus`。
4. 新增轻量 reducer / service，支持 propose、accept、question、reject、supersede、deprecate。
5. 添加 focused tests。

本轮不要做：

1. 不做 repository。
2. 不做 UI。
3. 不做语义判断。

验收标准：

1. reviewer / user / system 的状态流转可审计。
2. links 能连接 card、design、research、reference、claim。
3. reducer 不读正文判断文学意义。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-08，只做 Information link / event / lifecycle core 服务。支持 propose/accept/question/reject/supersede/deprecate，能链接 knowledge/design/research/reference/claim。不做 repository/UI/语义判断，不开启下一任务。补 focused reducer tests。
```

### PIS-09 Repository ports

本轮目标：定义信息层仓储端口，为 adapters 本地存储做准备。

层级归属：Core / ports。

必读文件：

- PIS-04 到 PIS-08 合同
- ONS repository ports

必须完成：

1. 新增 `KnowledgeCardRepository`。
2. 新增 `DesignElementRepository`。
3. 新增 `ResearchNoteRepository`。
4. 新增 `ReferenceWorkRepository`。
5. 新增 `InformationLinkRepository` / event repository。
6. 补 in-memory fake tests。

本轮不要做：

1. 不写 adapters。
2. 不定义路径策略。
3. 不做 projection。

验收标准：

1. ports 只依赖 core。
2. append/read/list/update 语义清楚。
3. fake tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-09，只做 information repository ports。ports 只能在 core，覆盖 knowledge/design/research/reference/link/event 的 append/read/list/update 基础语义。不做 adapters/path/projection/UI，不开启下一任务。补 in-memory fake repository tests。
```

### PIS-10 Information risk / permission policy

本轮目标：定义信息工具和信息事实进入项目时的风险、权限、自动接受边界。

层级归属：Core / policy。

必读文件：

- `NarrativePermissionPolicyService`
- PIS-03 usage policy
- PIS-06 `ResearchNote`
- PIS-07 `ReferenceWorkRecord`

必须完成：

1. 新增 `InformationPermissionPolicyService` 或扩展可复用策略服务。
2. 区分 auto_accept、proposed、needs_user_confirmation、forbidden_auto_apply。
3. 高风险外部作品、同人/穿书引用、长期规则修改必须确认。
4. 研究笔记可自动保存为 research note，但提升为项目规则需 proposal。
5. 添加 policy tests。

本轮不要做：

1. 不接 GUI。
2. 不做联网。
3. 不改变现有 ONS 权限行为。

验收标准：

1. 默认不自动联网。
2. 高风险引用不自动进入 active。
3. tests 覆盖内置资料、用户声明、外部研究、引用作品。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-10，只做 information risk / permission policy。必须区分自动接受、提案、用户确认、禁止自动执行；高风险外部作品/同人/穿书引用必须确认。不接 GUI/联网/adapters，不开启下一任务。补 policy tests。
```

### PIS-11 Information domain tool catalog

本轮目标：在 core 领域工具目录中新增信息工具 schema 和 parser。

层级归属：Core / domain tools。

必读文件：

- `NarrativeDomainToolCatalog`
- `NarrativeDomainToolNames`
- PIS-04 到 PIS-10 合同

必须完成：

1. 新增工具名：
   - `request_external_research`
   - `submit_research_note`
   - `propose_knowledge_card`
   - `propose_design_element`
   - `link_information_evidence`
   - `propose_reference_work`
2. 定义 schema 和 parse result。
3. parse 保留 unknown payload。
4. 添加 catalog tests。

本轮不要做：

1. 不做 handler。
2. 不做 adapter executor。
3. 不接 BuiltinToolCatalog。

验收标准：

1. schema 可导出。
2. parser 能区分 invalid payload 与 unknown payload。
3. 不出现题材枚举。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-11，只做 information domain tool catalog。新增 request_external_research、submit_research_note、propose_knowledge_card、propose_design_element、link_information_evidence、propose_reference_work 的 schema/parser。不做 handler/adapters/内置工具暴露，不开启下一任务。补 catalog tests，保持开放 payload。
```

### PIS-12 Information domain tool handlers

本轮目标：实现纯 core handlers，把信息工具请求收口为 `DomainToolOutcome`。

层级归属：Core / domain tools。

必读文件：

- PIS-11 catalog
- `NarrativeDomainToolDispatchService`
- `DomainToolOutcome`
- PIS-10 permission policy

必须完成：

1. 实现 submit/propose/link 类 handler。
2. `request_external_research` 在 core 只返回受控 request outcome，不执行联网。
3. handler 输出 proposed / accepted / needs_user_confirmation / invalid_payload。
4. 添加 handler tests。

本轮不要做：

1. 不写文件。
2. 不联网。
3. 不接 ProjectToolDispatcher。

验收标准：

1. 研究请求不会在 core 执行网络。
2. design element proposal 是一等 outcome。
3. 权限状态可审计。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-12，只做 information domain tool handlers。core 不执行联网、不写文件，只返回受控 DomainToolOutcome；design element proposal 必须是一等结果。不接 adapters/dispatcher/UI，不开启下一任务。补 handler tests。
```

### PIS-13 Toolcall mock reliability tests

本轮目标：先验证智能体通过工具提交知识、设计、研究、引用边界的可行性，再接真实运行时。

层级归属：Core / regression。

必读文件：

- `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`
- PIS-11 / PIS-12 工具

必须完成：

1. 增加 mock tests：
   - writer 提交 knowledge/design delta。
   - deconstructor 提交 design element。
   - researcher 请求 research 并提交 note。
   - reviewer link evidence。
   - reference work 高风险等待用户确认。
2. 对照 raw `write_project_file` / `request_gateway_tool` 不等于信息入库。
3. 不依赖真实 provider。

本轮不要做：

1. 不跑真实 API。
2. 不改 adapters。
3. 不扩大工具暴露。

验收标准：

1. mock 工具调用可靠。
2. 巧思/设计可通过工具提交，不依赖散文提示词。
3. tests 可本地稳定运行。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-13，只做 information toolcall mock reliability tests。验证 writer/deconstructor/researcher/reviewer 能通过领域工具提交 knowledge/design/research/reference/link，不跑真实 API，不改 adapters，不开启下一任务。必须证明巧思/设计不是只靠 prompt，而是可通过工具稳定提交。
```

### PIS-14 Builtin tool catalog / schema exposure

本轮目标：把信息领域工具接入内置工具目录和 schema builder，但仍不接本地持久化。

层级归属：Core tools。

必读文件：

- `BuiltinToolCatalog`
- `ToolSchemaBuilderService`
- PIS-11 catalog
- PIS-13 tests

必须完成：

1. 注册信息工具到 builtin catalog。
2. schema builder 能导出信息工具 schema。
3. 设置合适默认可见性：研究类默认受权限/平台控制，不默认无约束联网。
4. 添加 schema tests。

本轮不要做：

1. 不接 adapters executor。
2. 不开放真实联网默认权限。
3. 不改 GUI。

验收标准：

1. 工具 schema 与 domain catalog 一致。
2. 联网研究工具默认不绕过权限。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-14，只把 information domain tools 接入 BuiltinToolCatalog / ToolSchemaBuilderService。研究类工具默认受权限和平台策略约束，不允许默认无约束联网。不接 adapters executor/UI，不开启下一任务。补 schema tests。
```

### PIS-15 Adapter path service 与本地 repositories

本轮目标：实现 `.novel_agent/information/` 本地结构化事实源。

层级归属：Adapters / persistence。

必读文件：

- PIS-09 repository ports
- ONS local repositories
- `OpenNarrativeStatePathService`

必须完成：

1. 新增 `ProjectInformationPathService`。
2. 实现 knowledge/design/research/reference/link/event 本地 repositories。
3. 使用 JSON / JSONL，保留 unknown payload。
4. 添加 adapter tests。

本轮不要做：

1. 不写 projection。
2. 不接 tool executor。
3. 不接 activation。

验收标准：

1. 路径都在 `.novel_agent/information/`。
2. hidden path 读写稳定。
3. unknown payload round-trip。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-15，只做 adapters path service 与本地 information repositories。路径必须在 `.novel_agent/information/`，JSON/JSONL 保留 unknown payload。不做 projection/tool executor/activation/UI，不开启下一任务。补 adapter repository tests。
```

### PIS-16 Markdown projection 与回流 draft bridge

本轮目标：把结构化信息事实投影到用户可读 Markdown，并允许编辑块回流为 proposal draft。

层级归属：Core + Adapters / projection。

必读文件：

- PIS-04 到 PIS-08 合同
- PIS-15 repositories
- ONS `NarrativeStateMarkdownProjectionService`

必须完成：

1. 新增 projection service：
   - `knowledge/项目知识摘要.md`
   - `knowledge/设计元素摘要.md`
   - `research/资料研究摘要.md`
   - `references/引用作品边界.md`
2. 新增 Markdown bridge，只解析结构化 draft block。
3. adapters writer 刷新投影。
4. 添加 renderer / bridge / writer tests。

本轮不要做：

1. Markdown 不成为事实源。
2. 不做 GUI 编辑器。
3. 不自动应用 draft。

验收标准：

1. 投影能读。
2. 用户编辑只能变 proposal draft。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-16，只做 information Markdown projection 与回流 draft bridge。MD 只是投影，编辑只能形成 proposal draft，不能直接覆盖事实源。不做 GUI 编辑器、不自动应用、不接 runtime，不开启下一任务。补 renderer/bridge/writer tests。
```

### PIS-17 Adapter domain tool executor

本轮目标：把信息领域工具接入 adapters 本地执行，写入 repositories 并刷新 projection。

层级归属：Adapters / domain tool executor。

必读文件：

- `ProjectNarrativeDomainToolExecutor`
- PIS-12 handlers
- PIS-15 repositories
- PIS-16 projection writer

必须完成：

1. 新增或扩展 `ProjectInformationDomainToolExecutor`。
2. 处理 submit/propose/link/reference work 工具落盘。
3. `request_external_research` 只生成受控待研究记录，不直接联网。
4. 刷新 Markdown projection。
5. 添加 adapter executor tests。

本轮不要做：

1. 不接 gateway search。
2. 不改 prompt。
3. 不接 GUI。

验收标准：

1. propose_design_element 能落盘。
2. submit_research_note 能落盘。
3. 高风险 reference work 进入待确认。
4. projection 更新。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-17，只做 adapters information domain tool executor。把 knowledge/design/research/reference/link 工具 outcome 写入本地 repositories 并刷新 projection；request_external_research 只生成受控待研究记录，不直接联网。不接 gateway/prompt/GUI，不开启下一任务。补 adapter tests。
```

### PIS-18 ProjectToolDispatcher 路由接线

本轮目标：让正式工具调用能路由到信息领域 executor。

层级归属：Adapters / tool dispatch。

必读文件：

- `ProjectToolDispatcher`
- `ProjectNarrativeDomainToolExecutor`
- PIS-17 executor
- PIS-14 schema

必须完成：

1. 把信息工具接入 dispatcher。
2. 结果包含 domain_outcome、tool_layer、tool_result_summary。
3. 区分 `request_gateway_tool` 和 `request_external_research`。
4. 添加 dispatcher tests。

本轮不要做：

1. 不接真实 gateway search。
2. 不改变普通文件工具行为。
3. 不接 GUI。

验收标准：

1. information tool 可被 dispatcher 调用。
2. search gateway 工具不等于 research note 入库。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-18，只做 ProjectToolDispatcher 对 information tools 的路由接线。必须区分 request_gateway_tool 与 request_external_research，返回 domain_outcome 和清晰摘要。不接真实 gateway search、不改低层文件工具、不接 UI，不开启下一任务。补 dispatcher tests。
```

### PIS-19 Gateway research bridge

本轮目标：把受控研究请求桥接到 gateway 搜索/抓取，但必须有权限、来源和审计。

层级归属：Adapters / gateway bridge。

必读文件：

- `ProjectGatewayToolExecutor`
- `ProjectGatewayHttpService`
- PIS-06 `ResearchNote`
- PIS-10 permission policy

必须完成：

1. 新增 `ProjectResearchGatewayService`。
2. 读取 pending research request。
3. 调用 gateway search / fetch 时保留 query、source、results summary。
4. 生成 `ResearchNote` draft 或 proposed outcome。
5. 添加 fake gateway tests。

本轮不要做：

1. 不默认开真实联网。
2. 不把搜索原文大量保存。
3. 不自动提升为 knowledge card。

验收标准：

1. fake search 能生成 research note。
2. 无权限时不联网。
3. citation / source 可追踪。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-19，只做 Gateway research bridge。通过 adapters 调用 gateway search/fetch，必须有权限、来源和审计；默认不跑真实联网，不大量保存原文，不自动提升为知识卡。不接 GUI，不开启下一任务。补 fake gateway tests。
```

### PIS-20 Information activation bridge

本轮目标：让 knowledge/design/research/reference 能进入 `ContextActivationReport`，并可解释预算裁剪。

层级归属：Adapters + Core / runtime bridge。

必读文件：

- `ContextActivationPlannerService`
- `ProjectContextActivationService`
- PIS-15 repositories
- PIS-16 projection

必须完成：

1. 新增 `ProjectInformationActivationBridgeService`。
2. 把 cards / design elements / research notes / reference works 转成 `ContextActivationItem`。
3. 支持 required / pinned / activation priority。
4. `ProjectContextActivationService` 只薄接线，不继续塞算法。
5. 添加 activation tests。

本轮不要做：

1. 不改 prompt 合同。
2. 不做语义检索。
3. 不接 GUI。

验收标准：

1. activation report 显示选中、省略、截断的信息项。
2. design element 可被注入。
3. ProjectContextActivationService 没有明显膨胀。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-20，只做 Information activation bridge。把 knowledge/design/research/reference 转成 ContextActivationItem，并保留 selected/omitted/truncated 解释。ProjectContextActivationService 只能薄接线，不吸收算法。不改 prompt/GUI，不开启下一任务。补 activation tests。
```

### PIS-21 Prompt contract for information tools

本轮目标：让 writer、deconstructor、researcher、reviewer 知道何时使用信息工具，特别是巧思/设计必须提交工具。

层级归属：Core prompts / workflow contracts。

必读文件：

- `ProjectPromptContract`
- `DraftPromptBuilderService`
- `ToolStrategyPromptBuilder`
- PIS-13 mock tests
- PIS-20 activation bridge

必须完成：

1. 增加信息工具使用指引。
2. 明确巧思/设计不能只写在正文或普通 Markdown，应通过 `propose_design_element`。
3. 明确外部资料先 research note，再 proposal。
4. 明确没有显著信息变化时不编造。
5. 添加 prompt contract tests。

本轮不要做：

1. 不改 GUI。
2. 不接真实 provider。
3. 不做题材示例泛滥。

验收标准：

1. prompt 明确区分 knowledge、design、research、reference。
2. 不把示例当范本。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-21，只做 information tools 的 prompt contract。必须明确巧思/设计要通过 propose_design_element 提交，外部资料先 research note，再 proposal；没有显著变化不要编造。不接真实 provider/GUI，不开启下一任务。补 prompt contract tests。
```

### PIS-22 Ordinary project runtime 接线

本轮目标：普通小说项目生成章节时能读取信息层、提交信息 delta，但保持低成本。

层级归属：Adapters / ordinary workflow runtime。

必读文件：

- `ProjectConversationDraftRuntimeService`
- PIS-18 dispatcher
- PIS-20 activation bridge
- PIS-21 prompt contract

必须完成：

1. ordinary draft preparation 注入 information activation report。
2. finalization 记录 information changed paths。
3. chapter / revision 工具集合包含合适信息工具，但不暴露无权限联网。
4. focused tests 覆盖普通章节提交 design/knowledge delta。

本轮不要做：

1. 不改长任务。
2. 不跑真实 API。
3. 不强制每章必须提交知识卡。

验收标准：

1. 普通项目可使用信息层。
2. 没有信息 delta 时不失败。
3. 章节交付仍以 `submit_chapter_delivery` 为主。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-22，只做 ordinary project runtime 信息层接线。普通章节生成能读取 information activation、可提交 knowledge/design delta，但不强制每章提交，不暴露无权限联网。不改长任务、不跑真实 API、不开启下一任务。补 ordinary runtime focused tests。
```

### PIS-23 Long task information checkpoint signals

本轮目标：长任务 checkpoint / supervisor 能消费信息层信号，不读正文判断语义。

层级归属：Core + Adapters / long task runtime。

必读文件：

- `NarrativeSupervisorRiskPolicyService`
- `LongTaskRecoveryService`
- `TaskQueueStopPolicyService`
- `ProjectLongTaskChapterQueueRuntimeService`
- PIS-20 activation bridge

必须完成：

1. 新增 information risk signal。
2. 长任务 step 记录 information changed paths / summary。
3. checkpoint 可看到 pending research、high-risk reference、design conflict、required info omitted。
4. supervisor 只消费结构化 signal。
5. 添加 long task focused tests。

本轮不要做：

1. 不读正文做文学判断。
2. 不写题材逻辑。
3. 不跑真实长探针。

验收标准：

1. 信息缺口能进入 checkpoint / repair / manual attention 建议。
2. delivery/review/permission 旧逻辑不被破坏。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-23，只做 long task information checkpoint signals。supervisor 只能消费结构化 information risk，不读正文、不判断题材；step 记录 information changed paths/summary。不要跑真实长探针，不开启下一任务。补 long task focused tests。
```

### PIS-24 Deconstruction information bridge

本轮目标：拆书把原作巧思、符号系统、来源证据、设计元素桥接到信息层。

层级归属：Core + App application / deconstruction bridge。

必读文件：

- `BookDeconstructionNarrativeBridgeService`
- `BookDeconstructionNarrativePersistenceService`
- `BookDeconstructionExtractionResult`
- PIS-04 / PIS-05 / PIS-06 / PIS-07

必须完成：

1. 拆书 bridge 生成 knowledge cards、design elements、research note drafts、reference work record。
2. 原文证据引用进入 evidence refs。
3. 旧 mechanic hints 可迁移为中性 design / pattern hints。
4. 保持 analysis namespace，不直接污染写作主 ledger。
5. 添加 deconstruction focused tests。

本轮不要做：

1. 不重做拆书 UI。
2. 不实现完整同人功能。
3. 不自动提升 accepted。

验收标准：

1. 原作巧思能落为 DesignElementCard。
2. 拆书来源作品边界有 ReferenceWorkRecord。
3. analysis 和 writing source 分离。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-24，只做 Deconstruction information bridge。拆书结果必须能生成 knowledge cards、design elements、reference work record，并保留原文 evidence；旧 mechanic hints 迁移为中性 design/pattern hints。不要重做 UI、不自动提升 accepted、不实现同人功能、不开启下一任务。补 deconstruction tests。
```

### PIS-25 Explainer / analysis namespace bridge

本轮目标：解书、分析、审稿类任务可以提交信息层结果，但默认隔离在 analysis namespace。

层级归属：Core + Workflow。

必读文件：

- PIS-24 deconstruction bridge
- ONS analysis namespace 文档
- `NarrativeSemanticReview`

必须完成：

1. 定义 explainer / analyzer source 到信息层的桥接规则。
2. explanation 输出可产生 knowledge/design/research proposal。
3. 用户确认后才提升为写作事实。
4. 添加 focused tests。

本轮不要做：

1. 不做 GUI。
2. 不做实际解书产品流。
3. 不把分析推断当原文事实。

验收标准：

1. analysis namespace 与 writing fact 分离。
2. promotion path 清楚。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-25，只做 Explainer / analysis namespace bridge。解书/分析可提交 knowledge/design/research proposal，但默认隔离在 analysis namespace，用户确认后才提升。不做 GUI、不做完整解书产品流、不开启下一任务。补 focused tests。
```

### PIS-26 Mock regression suite

本轮目标：把信息层核心、工具、adapters、ordinary、long task、deconstruction 的 fake tests 收成总包。

层级归属：Regression / tooling。

必读文件：

- `tools/run_open_narrative_mock_regression_suite.ps1`
- PIS-02 到 PIS-25 tests

必须完成：

1. 新增 `tools/run_project_information_substrate_mock_regression_suite.ps1`。
2. 覆盖 core contracts、domain tools、adapter repos/executors、activation、ordinary、long task、deconstruction。
3. 新增说明文档。
4. 实跑总包。

本轮不要做：

1. 不跑真实 API。
2. 不联网。
3. 不修无关测试。

验收标准：

1. suite 一键通过。
2. 说明文档列出覆盖场景。
3. 不依赖真实 provider。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-26，只做 Project Information Substrate mock regression suite。新增一键脚本和说明文档，覆盖 core/tools/adapters/activation/ordinary/long-task/deconstruction fake tests。不跑真实 API、不联网、不修无关测试、不开启下一任务。实跑 suite 并记录结果。
```

### PIS-27 Gated real probe framework

本轮目标：建立真实验证框架，但只消费 production 同源合同，不做私有判定。

层级归属：Probe / framework。

必读文件：

- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- `apps/novel_agent_app/tool/real_long_task_probe.dart`
- PIS-26 suite 文档

必须完成：

1. 新增或扩展 information probe support。
2. 报告区分 technical_failure、waiting_user、budget_failure、content_quality_failure、information_quality_failure、success。
3. 仍从 `local/probe_api.txt` 或 env 读取配置，显式开闸。
4. 不新增一次性脚本到正式主线。
5. 添加 probe support tests。

本轮不要做：

1. 不跑真实 provider，除非用户明确要求。
2. 不做私有 retry。
3. 不删除产物。

验收标准：

1. framework 可运行 fake / dry path。
2. 分类清晰。
3. 不默认消耗额度。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-27，只做 gated real probe framework。probe 必须消费 production 同源合同，报告区分 technical/waiting/budget/content/information/success，不默认跑真实 provider，不做私有 retry，不删除产物，不开启下一任务。补 probe support tests。
```

### PIS-28 Short real validation

本轮目标：在 mock suite 通过后，做小预算真实验证，确认普通项目和长任务能实际提交信息层产物。

层级归属：Probe / real validation。

必读文件：

- PIS-26 suite 结果
- PIS-27 probe framework
- `local/probe_api.txt` 使用规则

必须完成：

1. 显式开闸真实 probe。
2. 普通小说生成 1 到 2 章，验证至少一个 design/knowledge proposal 或明确无信息变化。
3. 长任务短链验证 activation report 包含 information sections。
4. 保留产物和报告。
5. 若失败只记录事实，不盲跑。

本轮不要做：

1. 不跑长篇压力测试。
2. 不跑同人/穿书复杂场景。
3. 不删除产物。

验收标准：

1. report 说明工具调用、落盘、activation 是否有效。
2. 失败分类明确。
3. 真实消耗受控。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-28。只有 PIS-26 mock suite 与 PIS-27 framework 通过后，才显式开闸做小预算真实验证：普通项目 1-2 章、长任务短链，验证 information activation 与 knowledge/design proposal。不要跑长篇压力测试，不删除产物，不开启下一任务；失败只记录事实，不盲跑。
```

### PIS-29 CLI 最小摘要

本轮目标：CLI 输出 information 摘要，但不做完整交互。

层级归属：CLI / presentation shell。

必读文件：

- `apps/novel_agent_cli/lib/commands/workflow/`
- PIS-16 projection
- PIS-23 long task signals

必须完成：

1. workflow summary 增加 Information 粗摘要。
2. 显示 knowledge/design/research/reference 计数和投影路径。
3. 不解释 payload。
4. 添加 CLI probe / tests。

本轮不要做：

1. 不做 CLI 编辑器。
2. 不审批 proposal。
3. 不做业务规则。

验收标准：

1. CLI 能看到 information 摘要。
2. 只消费 adapters 稳定合同。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-29，只做 CLI Information 最小摘要。workflow 输出 knowledge/design/research/reference 计数和投影路径，不解释 payload、不审批 proposal、不做编辑器、不承载业务规则。不改 GUI，不开启下一任务。补 CLI probe/tests。
```

### PIS-30 GUI 最小消费与最终文档收口

本轮目标：GUI 最小展示 information projection、pending confirmation 和 run 摘要，并完成最终文档。

层级归属：App / GUI + Documentation。

必读文件：

- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/workbench/`
- PIS-16 projection
- PIS-23 signals
- PIS-29 CLI 摘要

必须完成：

1. 长任务总站或工作台展示 information summary。
2. 提供投影打开入口。
3. 展示 pending research / reference / knowledge / design confirmation 记录。
4. 不做审批 / 应用动作，除非已有稳定合同。
5. 更新本文档完成记录和最终风险。
6. 添加 GUI focused tests。

本轮不要做：

1. 不做完整 knowledge browser。
2. 不解释开放 payload。
3. 不用 GUI 兜底底层缺口。
4. 不开启下一主线。

验收标准：

1. GUI 只消费稳定 adapters view data。
2. 用户能看到信息层是否产生、是否待确认。
3. focused tests 通过。
4. 文档收口完整。

直接可用提示词：

```text
根据 `docs/project-information-substrate-session-order-2026-06-05.md` 开启 PIS-30，只做 GUI 最小消费与最终文档收口。GUI 展示 information summary、投影入口和 pending confirmation 记录，但不解释 payload、不审批、不应用、不兜底底层缺口。补 focused GUI tests，更新本文档完成记录和剩余风险，不开启下一主线。
```

---

## 10. 总启动提示词

```text
根据目前的进度和文档：`docs/project-information-substrate-session-order-2026-06-05.md` 继续下一步。每次只确认完成一个具体任务；如果上个会话末尾卡在具体任务的一半未完成或者出现关联性错误，就先修好这些，不开启下一轮任务。如果已经确认可以开启下一轮任务，就直接开始当前 session。必须读取对应 session 的目标、层级归属、必读文件、必须完成、本轮不要做、验收标准和直接可用提示词。实现时遵守 core/adapters/app/CLI 分层、解耦合、单一职责、避免单文件过重、focused test/contract test、probe 同源合同、真实 key 不入仓库等约束。完成后只更新本文档中当前 session 的完成记录，不顺手推进下一 session。
```

---

## 11. 完成记录占位

- PIS-01：已完成（2026-06-05，已新增 `docs/project-information-substrate-implementation-audit-2026-06-05.md`，完成 core/adapters/app/CLI/probe 的信息层现状审计与落点图，明确 `knowledge/` 只是投影/素材目录而非事实源，并冻结 `ProjectWorkflowRuntimeService` / `ProjectContextActivationService` 的继续膨胀）
- PIS-02：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增中性 `information` 命名空间骨架，包含 barrel、基础 typedef 与通用 validation codes，并更新 `novel_agent_core.dart` 顶层导出；新增 `packages/novel_agent_core/test/project_information_namespace_smoke_test.dart` 验证 package 导出与 open-json codec 复用，`packages/novel_agent_core` 下 `dart analyze` 与该 focused test 已通过）
- PIS-03：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `InformationSourceRef`、`InformationUsagePolicy`、`InformationActivationPolicy` 与配套常量目录，复用 `NarrativeSourceRef` 和 `OpenJsonContractCodecService` 实现开放 round-trip，支持 `source_authority / role_authority / research_depth / activation_priority / requires_confirmation` 等字段；新增 `packages/novel_agent_core/test/information_policy_contracts_test.dart` 覆盖 codec/validation 与 unknown policy fields round-trip，`packages/novel_agent_core` 下 `dart analyze` 与 focused tests 已通过）
- PIS-04：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `ProjectKnowledgeCard`、配套 `codec service`、`validator` 与通用生命周期常量，字段覆盖 `card_id / namespace / card_type / title / summary / content_payload / source_refs / evidence_refs / scope_refs / activation_policy / usage_policy / confidence / lifecycle_status / metadata`，并保持 `card_type` 与 payload 开放；新增 `packages/novel_agent_core/test/project_knowledge_card_contracts_test.dart`，覆盖普通设定、外部研究、拆书抽取三类 source round-trip、copyWith、列表 codec 与 validator，`packages/novel_agent_core` 下 `dart analyze` 与 focused tests 已通过）
- PIS-05：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `DesignElementCard`、`DesignElementCardCodecService`、`DesignElementCardValidator` 与 `InformationLinkedRefTypes`，字段覆盖 `design_id / design_namespace / design_label / design_payload / source_refs / evidence_refs / scope_refs / linked_refs / activation_policy / usage_policy / confidence / uncertainty / lifecycle_status / schema_version / metadata`，并保持 design payload 与 linked ref type 开放；新增 `packages/novel_agent_core/test/design_element_card_contracts_test.dart` 覆盖“命名暗线”“象征系统”“结构巧思”round-trip、copyWith、空列表 codec 与 validator，`packages/novel_agent_core` 下 `dart test test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-06：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `ResearchNote`、`ResearchNoteCodecService`、`ResearchNoteValidator`，字段覆盖 `research_id / query / source_kind / source_url_or_ref / citation / summary / usable_facts / creative_suggestions / uncertainty / license_or_usage_note / created_by / linked_cards / usage_policy / schema_version / metadata`，并明确把 `usable_facts` 与 `creative_suggestions` 分离；新增 `packages/novel_agent_core/test/research_note_contracts_test.dart` 覆盖外部研究来源追溯、gateway 引用、copyWith、空列表 codec 与 source/citation 缺失校验，`packages/novel_agent_core` 下 `dart test test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-07：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `ReferenceWorkRecord`、`ReferenceWorkRecordCodecService`、`ReferenceWorkRecordValidator`，字段覆盖 `reference_work_id / title / creator / version / source_refs / relationship_to_project / declared_usage_intent / allowed_usage_summary / risk_notes / requires_confirmation / schema_version / metadata`，并保持 `relationship_to_project` 为开放字符串，不封闭成枚举；新增 `packages/novel_agent_core/test/reference_work_record_contracts_test.dart` 覆盖 `deconstructed_source`、`fanfic_reference`、`crossover_reference` 等开放关系字符串、confirmation 风险标记、copyWith、空列表 codec 与 source ref 校验，`packages/novel_agent_core` 下 `dart test test/reference_work_record_contracts_test.dart test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-08：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `InformationLink`、`InformationEvent`、`InformationLifecycleStatus` 与 `InformationLifecycleService`，并补充 `research_note / reference_work` ref type 常量与 `questioned / rejected` 生命周期常量；轻量 reducer 支持 `propose / accept / question / reject / supersede / deprecate`，只基于结构化 ref 与状态流转做审计，不读正文做语义判断；新增 `packages/novel_agent_core/test/information_lifecycle_service_test.dart` 覆盖 knowledge/design/research/reference/claim 链接、reviewer/user/system 可审计状态流转、supersede/deprecate 清晰引用与 invalid ref 校验，`packages/novel_agent_core` 下 `dart test test/information_lifecycle_service_test.dart test/reference_work_record_contracts_test.dart test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-09：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/ports/` 新增 `KnowledgeCardRepository`、`DesignElementRepository`、`ResearchNoteRepository`、`ReferenceWorkRepository`、`InformationLinkRepository`、`InformationEventRepository` 六类 core 端口，并更新 `packages/novel_agent_core/lib/novel_agent_core.dart` 顶层导出；各端口只依赖 core 合同与 `ProjectDescriptor`，提供清晰的 `append / read / list / update` 基础语义，不引入 adapters、路径策略或 projection 假设；新增 `packages/novel_agent_core/test/information_repository_ports_test.dart`，通过 in-memory fake repositories 覆盖 knowledge/design/research/reference/link/event 的 append/read/list/update 语义与过滤行为，`packages/novel_agent_core` 下 `dart test test/information_repository_ports_test.dart test/information_lifecycle_service_test.dart test/reference_work_record_contracts_test.dart test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-10：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `InformationPermissionDispositions`、`InformationPermissionDecision` 与 `InformationPermissionPolicyService`，独立定义 information 层的 `auto_accept / proposed / needs_user_confirmation / forbidden_auto_apply` 四类策略结果，不改变现有 ONS `NarrativePermissionPolicyService` 行为；policy 已覆盖 `ProjectKnowledgeCard`、`DesignElementCard`、`ResearchNote`、`ReferenceWorkRecord` 以及外部研究请求，明确默认不自动联网、研究笔记可自动保存但提升为项目规则需 proposal、高风险外部作品/同人/穿书引用与长期规则修改必须确认；新增 `packages/novel_agent_core/test/information_permission_policy_service_test.dart` 覆盖内置资料、用户声明、外部研究、引用作品与脚本型 payload 禁止自动执行等场景，`packages/novel_agent_core` 下 `dart test test/information_permission_policy_service_test.dart test/information_repository_ports_test.dart test/information_lifecycle_service_test.dart test/reference_work_record_contracts_test.dart test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-11：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/tools/domain/` 扩展 `NarrativeDomainToolNames` 与 `NarrativeDomainToolCatalog`，新增 `request_external_research`、`submit_research_note`、`propose_knowledge_card`、`propose_design_element`、`link_information_evidence`、`propose_reference_work` 六个 information 工具名，以及对应的 OpenAI schema 与 parse 入口；parser 直接复用 PIS-04 到 PIS-10 已完成的 information 合同，区分 invalid payload 与开放 unknown payload，并保持 payload/metadata 的开放 round-trip，不引入题材枚举；更新 `packages/novel_agent_core/test/narrative_domain_tool_catalog_test.dart`，覆盖 12 个 domain tool schema、6 个 information 工具的 parse success、unknown payload 保留与 malformed payload 结构化 issue，`packages/novel_agent_core` 下 `dart test test/narrative_domain_tool_catalog_test.dart test/information_permission_policy_service_test.dart test/information_repository_ports_test.dart test/information_lifecycle_service_test.dart test/reference_work_record_contracts_test.dart test/research_note_contracts_test.dart test/design_element_card_contracts_test.dart test/project_knowledge_card_contracts_test.dart test/information_policy_contracts_test.dart test/project_information_namespace_smoke_test.dart` 与 `dart analyze` 已通过）
- PIS-12：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/tools/domain/` 新增 `RequestExternalResearchHandler`、`SubmitResearchNoteHandler`、`ProposeKnowledgeCardHandler`、`ProposeDesignElementHandler`、`LinkInformationEvidenceHandler`、`ProposeReferenceWorkHandler` 与共享 `InformationDomainToolHandlerSupport`，纯 core 收口 information 工具请求为受控 `DomainToolOutcome`，其中 `request_external_research` 只返回受控研究请求、不执行联网，`DesignElementCard` 作为一等结果通过 `design_element` outcome payload 独立暴露；handlers 复用 `InformationPermissionPolicyService` 把 information 层 `auto_accept / proposed / needs_user_confirmation / forbidden_auto_apply` 映射为 `accepted / proposed / needs_user_confirmation / invalid_payload`，并保留 upstream/information permission audit 元数据；同时为信息链路补充 `decideInformationLink` 轻量策略、更新 `packages/novel_agent_core/lib/src/tools/domain.dart` 导出，并新增 `packages/novel_agent_core/test/information_domain_tool_handler_contracts_test.dart` 覆盖六类 handler 的 accepted/proposed/needs_user_confirmation/invalid_payload 通路，`packages/novel_agent_core` 下 `dart test test/information_domain_tool_handler_contracts_test.dart test/information_permission_policy_service_test.dart` 与 `dart analyze` 已通过）
- PIS-13：已完成（2026-06-05，已新增 `packages/novel_agent_core/test/information_tool_call_reliability_test.dart`，基于 `NarrativeDomainToolCatalog` + PIS-12 handlers 建立纯 core 的 information toolcall mock reliability 覆盖，验证 writer 能稳定提交 `knowledge_card` 与 `design_element` delta、deconstructor 能提交一等 `DesignElementCard`、researcher 流程能先 `request_external_research` 再 `submit_research_note` 且不执行真实联网、reviewer 能通过 `link_information_evidence` 建立结构化证据链、高风险 `ReferenceWorkRecord` 会停在 `needs_user_confirmation`；同时显式证明原始 `write_project_file` / `request_gateway_tool` 不属于 information 入库链，不能替代结构化 information tools，从而落实“巧思/设计不是只靠 prompt，而是可通过工具稳定提交”的验收点；`packages/novel_agent_core` 下 `dart test test/information_tool_call_reliability_test.dart test/information_domain_tool_handler_contracts_test.dart test/draft_generation_tool_call_reliability_test.dart` 与 `dart analyze` 已通过）
- PIS-14：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/tools/builtin_tool_catalog.dart` 将 `request_external_research`、`submit_research_note`、`propose_knowledge_card`、`propose_design_element`、`link_information_evidence`、`propose_reference_work` 六个 information domain tools 注册进 builtin tool 目录，使其进入统一的 tool toggle / exposure / schema 暴露链；其中 `request_external_research` 明确设置为 `desktop_or_gateway_only` 且 `enabledByDefault: false`，确保研究请求默认仍受平台与权限策略约束，不形成无约束联网默认能力；同时补充 `packages/novel_agent_core/test/tool_schema_builder_service_test.dart`、`test/tool_exposure_policy_service_test.dart`、`test/tool_strategy_service_test.dart`，验证 information tool schema 与 `NarrativeDomainToolCatalog` 一致、外部研究工具在桌面可暴露但在移动端被平台策略拦截、默认工具策略不会自动开放研究请求但保留 research note 提交能力；`packages/novel_agent_core` 下 `dart test test/tool_schema_builder_service_test.dart test/tool_exposure_policy_service_test.dart test/tool_strategy_service_test.dart test/narrative_domain_tool_catalog_test.dart` 与 `dart analyze` 已通过）
- PIS-15：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/storage/` 新增 `ProjectInformationPathService`，统一把 knowledge/design/research/reference/link/event 的结构化事实源路径收口到 `.novel_agent/information/`；同时实现 `LocalKnowledgeCardRepository`、`LocalDesignElementRepository`、`LocalResearchNoteRepository`、`LocalReferenceWorkRepository` 四个 JSON 仓储与 `LocalInformationLinkRepository`、`LocalInformationEventRepository` 两个 JSONL 仓储，分别复用 `ProjectJsonDocumentService`、`OpenNarrativeStateJsonlDocumentService` 与现有 index 文档服务，保持 unknown payload / unknown top-level fields 的 round-trip，并让 JSONL 仓储通过“同 ID 最后一条记录为当前状态”的读取语义保持可审计历史；已更新 `packages/novel_agent_adapters/lib/novel_agent_adapters.dart` 导出，并新增 `packages/novel_agent_adapters/test/local_project_information_repositories_test.dart`，覆盖 hidden path、JSON/JSONL 落盘、unknown payload round-trip、update/filter 语义与 latest-record 读取行为；`packages/novel_agent_adapters` 下 `dart test test/local_project_information_repositories_test.dart test/local_narrative_state_repositories_test.dart` 与 `dart analyze` 已通过）
- PIS-16：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/information/` 新增 `InformationProjectionDocument`、`InformationProjectionSource`、`InformationProjectionDraftBundle`、`InformationMarkdownProjectionService` 与 `InformationMarkdownBridgeService`，生成 `knowledge/项目知识摘要.md`、`knowledge/设计元素摘要.md`、`research/资料研究摘要.md`、`references/引用作品边界.md` 四类 projection，并通过 frontmatter + draft block 明确“Markdown 只是投影、编辑只能回流为结构化 draft”；同时在 `packages/novel_agent_adapters/lib/src/storage/` 新增 `ProjectInformationProjectionWriterService`，基于 PIS-15 repositories 刷新四份可读投影且不改写隐藏 JSON 事实源；新增 `packages/novel_agent_core/test/information_markdown_projection_services_test.dart` 与 `packages/novel_agent_adapters/test/project_information_projection_writer_service_test.dart`，并已通过 `packages/novel_agent_core` 下 `dart test test/information_markdown_projection_services_test.dart test/narrative_state_markdown_projection_services_test.dart`、`dart analyze`，以及 `packages/novel_agent_adapters` 下 `dart test test/project_information_projection_writer_service_test.dart test/open_narrative_state_projection_writer_service_test.dart test/local_project_information_repositories_test.dart`、`dart analyze`）
- PIS-17：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/tools/` 新增 `ProjectInformationDomainToolExecutor`，独立承接 information domain tools 的 adapters 本地执行，默认注册 `request_external_research`、`submit_research_note`、`propose_knowledge_card`、`propose_design_element`、`link_information_evidence`、`propose_reference_work` 六类 handlers，并把 success / proposed / needs_user_confirmation 结果分别落入 PIS-15 的 repositories 或受控隐藏记录；同时扩展 `packages/novel_agent_adapters/lib/src/storage/project_information_path_service.dart`，新增 `.novel_agent/information/research_requests/` 路径与 index，用于保存不联网的 pending research request 记录，供后续 PIS-19 gateway bridge 读取；executor 现在会把 knowledge/design/research/reference 写入本地 JSON 仓储、把 link 与 lifecycle audit 追加到 JSONL `links/events` 日志，并通过 `ProjectInformationProjectionWriterService` 刷新四份 Markdown projection，从而保证 `propose_design_element` / `submit_research_note` 可落盘、`request_external_research` 只登记受控待研究记录、高风险 `ReferenceWorkRecord` 进入 `needs_user_confirmation` 且保留待确认审计痕迹；新增 `packages/novel_agent_adapters/test/project_information_domain_tool_executor_test.dart` 覆盖 design/research/reference/request/link 五条执行链路，并已通过 `packages/novel_agent_adapters` 下 `dart test test/project_information_domain_tool_executor_test.dart test/project_information_projection_writer_service_test.dart test/local_project_information_repositories_test.dart` 与 `dart analyze`，以及 `packages/novel_agent_core` 下 `dart test test/information_domain_tool_handler_contracts_test.dart test/information_permission_policy_service_test.dart` 与 `dart analyze`）
- PIS-18：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart` 把六个 information domain tools 正式接入 dispatcher：新增 `ProjectInformationDomainToolExecutor` 的路由实例、独立 `information` handler dispatcher、对应的 `_domainToolNames` 扩展，以及按 tool name 选择 narrative/info executor 的分发逻辑；同时补充 information tools 的默认 `source_type` 映射与 domain capability 查询，确保正式工具调用可以返回稳定的 `domain_outcome`、`tool_layer: domain`、`tool_result_summary` 与 `changed_paths`。本轮显式区分了 `request_external_research` 与 `request_gateway_tool`：前者经 domain parse + information executor 只登记受控 research request / pending confirmation 记录，后者仍停留在 project/gateway 工具层，不会自动写入 research note 或 information repositories。新增 `packages/novel_agent_adapters/test/project_tool_dispatcher_domain_tools_test.dart` 的 information 路由覆盖，验证 `propose_design_element` 能通过 dispatcher 落入 information executor、`request_external_research` 返回 domain waiting result 且不联网、`request_gateway_tool` 仍无 `domain_outcome` 且不会创建 information research 索引；并已通过 `packages/novel_agent_adapters` 下 `dart test test/project_tool_dispatcher_domain_tools_test.dart test/project_information_domain_tool_executor_test.dart` 与 `dart analyze`）
- PIS-19：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/tools/` 新增 `ProjectResearchGatewayService` 与 `ProjectResearchGatewayRunResult`，桥接 PIS-17 留下的 pending research request 到受控 gateway search/fetch 流程：服务会读取 `.novel_agent/information/research_requests/` 待处理记录，先复核 `InformationPermissionPolicyService` 权限，再在显式 `allowGatewayExecution: true` 时调用 gateway，并把 query、search result summary、短摘录与可追踪 citation/source 收口为 `ResearchNote`；同时保持默认不执行真实联网、不大量持久化原始抓取正文、不自动提升为 knowledge card，并追加 information event 审计与 projection 刷新。已新增 `packages/novel_agent_adapters/test/project_research_gateway_service_test.dart` 用 fake gateway 覆盖“允许时生成 research note”“无权限时不联网”以及“不保存大段原始 content”场景；`packages/novel_agent_adapters` 下 `dart test test/project_research_gateway_service_test.dart test/project_information_projection_writer_service_test.dart test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart` 与 `dart analyze`，以及 `packages/novel_agent_core` 下 `dart test test/information_permission_policy_service_test.dart test/information_domain_tool_handler_contracts_test.dart` 与 `dart analyze` 已通过）
- PIS-20：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/workflow/` 新增 `ProjectInformationActivationBridgeService`，把 PIS-15 的 `knowledge card / design element / research note / reference work` 结构化事实源独立桥接为 `ContextActivationItem`，并把 `activation_priority / required / pinned / preferred_budget_chars / citation/source refs` 等信息保留到 activation metadata 中；同时让 `ProjectContextActivationService` 只做薄接线，继续复用既有 `ContextActivationPlannerService` 做 selected / omitted / truncated 预算裁剪，不把 information 侧算法继续塞回主服务。完成后 `ContextActivationPlan` / `ContextActivationReport` 的 summary 与 `selected_context_sections / omitted_context_sections / truncated_context_sections` 已能解释 information items，且 `design element` 可作为一等上下文被选入。已新增 `packages/novel_agent_adapters/test/project_information_activation_bridge_service_test.dart`，并扩展 `test/project_context_activation_service_test.dart` 覆盖 knowledge/design/research/reference 的候选构建与 selected/omitted/truncated 可见性；`packages/novel_agent_adapters` 下 `dart test test/project_information_activation_bridge_service_test.dart test/project_context_activation_service_test.dart test/project_information_projection_writer_service_test.dart test/project_information_domain_tool_executor_test.dart test/project_tool_dispatcher_domain_tools_test.dart` 与 `dart analyze` 已通过）
- PIS-21：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/project/project_prompt_contract.dart` 新增共享 `informationToolGuidance`，明确区分 `knowledge / design / research / reference` 四类信息工具职责：长期事实走 `propose_knowledge_card`，作品巧思/结构设计/命名暗线/符号系统必须走 `propose_design_element`，外部资料先 `request_external_research / submit_research_note` 再决定是否提升，来源证据与引用边界分别通过 `link_information_evidence`、`propose_reference_work` 收口，并明确“没有显著信息变化时不要编造也不要强行调用信息工具”；同时已把这套 guidance 接入 `DraftPromptBuilderService` 与 `ToolStrategyPromptBuilder`，保证普通 draft prompt 与系统层工具策略 prompt 共用同一套信息工具约束，并对 `LongTaskTransactionContractService` 做最小同步，让长任务的 `writer / reviewer / planning` 事务契约也能识别 information tool 的收口方式。已扩展 `packages/novel_agent_core/test/prompt_builder_domain_tool_contracts_test.dart` 覆盖 writer / researcher / deconstructor / reviewer 以及长任务 planning/review/chapter 的信息工具约束，并更新 `test/draft_generation_use_case_test.dart` 验证系统 prompt 也包含 `propose_design_element` 与“外部资料先 research note 再 proposal”的提示；`packages/novel_agent_core` 下 `dart test test/prompt_builder_domain_tool_contracts_test.dart test/draft_generation_use_case_test.dart test/draft_generation_tool_call_reliability_test.dart` 与 `dart analyze` 已通过）
- PIS-22：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/workflow/project_conversation_draft_runtime_service.dart` 为普通 `chapter / revision` 会话显式收口安全 information tools：保留 `propose_knowledge_card`、`propose_design_element`、`submit_research_note`、`link_information_evidence`、`propose_reference_work`，并明确排除 `request_external_research`、`set_agent_tasks`、`call_sub_agent`，从而保证普通章节运行时可以低成本提交 information delta，但不暴露无权限联网研究；同时在 `finalizeDraftRun` 合并 `DraftGenerationResult.changedPaths` 与 executed tool/domain persistence 的 `changed_paths`，不再只记录 activation report 和章节交付补单结果，因此普通章节里落下的 knowledge/design/research/reference 结构化改动都会进入最终 artifacts，而没有 information delta 的章节流仍可正常完成，且 `submit_chapter_delivery` 继续作为主要章节交付路径。已扩展 `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`，覆盖普通章节 preparation 注入 information activation、chapter tool set 暴露安全 information tools 且不包含 `request_external_research`，以及普通章节同时提交 knowledge/design delta 时最终 artifacts 会保留 `.novel_agent/information/...` 与 projection 的 changed paths；`packages/novel_agent_adapters` 下 `dart test test/project_conversation_draft_runtime_service_test.dart test/project_tool_dispatcher_domain_tools_test.dart test/project_information_domain_tool_executor_test.dart` 与 `dart analyze` 已通过）
- PIS-23：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart` 为长任务 supervisor 新增独立 `information` 风险信号，结构化收口 `pending research`、`high-risk reference`、`design conflict`、`required info omitted` 与 information changed paths，并把它正式并入 overall category，使 supervisor 仍然只消费结构化 runtime/tool/activation 合同而不读正文；同时在 `packages/novel_agent_core/lib/src/workflow/long_task_checkpoint_review_service.dart`、`long_task_checkpoint_review_markdown_renderer.dart`、`long_task_run_step_recorder_service.dart`、`long_task_run_markdown_renderer.dart` 把 information signal、summary 与 changed paths 写入 checkpoint review 和长任务 step 审计，让 checkpoint / run record / markdown 能直接看到信息层缺口与变更。进一步在 `packages/novel_agent_core/lib/src/workflow/task_queue_stop_policy_service.dart`、`long_task_recovery_service.dart`、`long_task_finish_disposition_service.dart` 把 information 的 `repair / manual_attention / checkpoint_user` 映射进长任务暂停、恢复和结束说明，确保信息缺口能进入 checkpoint / repair / manual attention 建议，同时不破坏 delivery / review / permission 既有语义。已补充 `packages/novel_agent_core/test/narrative_supervisor_risk_policy_service_test.dart`、`test/long_task_checkpoint_review_service_test.dart`、`test/long_task_runtime_services_test.dart`、`test/task_queue_services_test.dart`，以及 `packages/novel_agent_adapters/test/project_long_task_checkpoint_review_service_test.dart`，覆盖 information risk 进入 checkpoint review、step record、queue stop、recovery 与 markdown 落盘的 focused 场景；`packages/novel_agent_core` 下 `dart test test/narrative_supervisor_risk_policy_service_test.dart test/long_task_checkpoint_review_service_test.dart test/long_task_runtime_services_test.dart test/task_queue_services_test.dart` 与 `dart analyze`，以及 `packages/novel_agent_adapters` 下 `dart test test/project_long_task_checkpoint_review_service_test.dart test/project_long_task_postprocess_result_service_test.dart test/project_workflow_runtime_service_test.dart` 与 `dart analyze` 已通过）
- PIS-24：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/deconstruction/` 新增 `BookDeconstructionInformationBridgeService`，并扩展 `BookDeconstructionNarrativeArtifactBundle`，让拆书 bridge 在保留原有 narrative claims/profile/review 的同时，额外桥接出 `ProjectKnowledgeCard`、`DesignElementCard`、`ResearchNote` draft 与 `ReferenceWorkRecord`：其中故事总纲/章节提要进入 `analysis.deconstruction.*` knowledge cards，世界规则/风格特征与旧 `mechanic hints` 迁移为中性的 `analysis.deconstruction.design.*` / `analysis.explainer.design.pattern_hint` design elements，并把原始来源摘要写入 `evidence_refs`；拆书来源作品边界则单独落为 `ReferenceWorkRecord`，保持 `requires_confirmation: true` 与 analysis metadata，不自动提升为 accepted。与此同时，`packages/novel_agent_core/lib/src/deconstruction/book_deconstruction_narrative_bridge_service.dart` 已改为薄组合 narrative + information bridge，`book_deconstruction_narrative_promotion_service.dart` 只保留 information artifacts 为 analysis/proposed 态而不顺带 promoted；`apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart` 也已接入 information repositories 与 projection writer，把拆书导入产生的 knowledge/design/research/reference 结构化事实源写入 `.novel_agent/information/` 并刷新 `knowledge/设计元素摘要.md`、`references/引用作品边界.md` 等投影，而不污染 writing 主 ledger。已补充 `packages/novel_agent_core/test/book_deconstruction_narrative_bridge_service_test.dart` 与 `apps/novel_agent_app/test/book_deconstruction_controller_test.dart`，覆盖“original cleverness -> DesignElementCard”“source-work boundary -> ReferenceWorkRecord”“analysis namespace separation”“mechanic hint -> neutral pattern hint”“evidence refs 落盘”与 app 侧 persistence/projection；`packages/novel_agent_core` 下 `dart test test/book_deconstruction_narrative_bridge_service_test.dart`、`dart analyze`，以及 `apps/novel_agent_app` 下 `flutter test test/book_deconstruction_controller_test.dart`、`flutter analyze` 已通过）
- PIS-25：已完成（2026-06-05，已在 `packages/novel_agent_core/lib/src/workflow/` 新增 `AnalysisInformationBridgeConstants` 与 `SemanticReviewInformationBridgeService`，定义 reviewer / explainer / explainer_interpreted 等分析型来源到 information 层的桥接规则：`NarrativeSemanticReview.suggestedClaims` 可被桥接为默认留在 `analysis.review.*` 或 `analysis.explainer.*` 下的 `ProjectKnowledgeCard` / `DesignElementCard` proposal，`SemanticReviewFinding` 则可桥接为 `ResearchNote` proposal；这些桥接产物统一使用 `analysis_interpreted` source authority、`reference_only` usage policy、`requires_confirmation: true`、`proposed` lifecycle 或等价 metadata，并显式写出 `promotion_path=user_confirmation_or_policy` 与 writing target namespace，从而保证分析推断不会直接被当成写作主事实。与此同时，`packages/novel_agent_adapters/lib/src/workflow/` 新增 `ProjectSemanticReviewInformationService`，并让 `ProjectWorkflowReviewRuntimeService.persistSemanticReviewArtifacts()` 在保存 semantic review / review report 的同时，自动把 review 中的 analysis proposals 写入 `.novel_agent/information/knowledge_cards/`、`design_elements/`、`research_notes/` 并刷新 information Markdown projections，同时通过 `attachReviewArtifacts()` 把 `analysis_information` summary 与 changed paths 回挂到 execution record，但未引入 GUI、未创建完整解书产品流、也未把解释性分析自动提升为 writing fact。已新增 `packages/novel_agent_core/test/semantic_review_information_bridge_service_test.dart` 与扩展 `packages/novel_agent_adapters/test/project_workflow_review_runtime_service_test.dart`，覆盖 explainer/reviewer source 到 `analysis.*` namespace 的桥接、knowledge/design/research proposal 生成、promotion path metadata、workflow 持久化到 information hidden store/projection 以及 execution artifact 附着；`packages/novel_agent_core` 下 `dart test test/semantic_review_information_bridge_service_test.dart`、`dart analyze`，以及 `packages/novel_agent_adapters` 下 `dart test test/project_workflow_review_runtime_service_test.dart`、`dart analyze` 已通过）
- PIS-26：已完成（2026-06-05，已新增 `tools/run_project_information_substrate_mock_regression_suite.ps1` 与 `docs/project-information-substrate-mock-regression-suite-2026-06-05.md`，把 PIS-02 到 PIS-25 的信息层 fake tests 收成一键 mock regression suite，并按 `Core information contract suite`、`Core information workflow suite`、`Adapters information storage and tool suite`、`Adapters information runtime suite` 四组覆盖 core contracts、domain tools、adapter repositories/projections/executors/dispatcher/gateway、activation、ordinary conversation runtime、long task checkpoint、semantic review runtime 与 deconstruction bridge；suite 只跑 `dart test`、不触发真实 provider、`request_external_research` 仅走 fake/pending 路径、不联网。已实跑 `powershell -ExecutionPolicy Bypass -File tools/run_project_information_substrate_mock_regression_suite.ps1`，四组全部通过，作为后续 `PIS-27` gated probe framework 的前置门槛）
- PIS-27：已完成（2026-06-05，已在 `apps/novel_agent_app/tool/probe_support.dart` 扩展 gated probe framework：`ProbeApiConfig` 现在保留配置来源 `sourceLabel`，统一提供 `buildProbeWorkspaceDirectory()` / `safeProbeTimestamp()` 以便真实 probe 默认把 workspace 保留在仓库 `artifacts/` 下而不是临时目录即删；同时新增 `ProbeReportCategories.informationQualityFailure` 与 `buildInformationProbeAssessment()`，让 probe support 可以基于 production 同源 activation report、information changed paths、information tool names 与 required-info-omitted 信号，对 information 质量做 dry/fake 分类，而不在探针层补私有 retry 或业务判断。与此同时，`apps/novel_agent_app/tool/real_general_novel_probe.dart` 与 `apps/novel_agent_app/tool/real_long_task_probe.dart` 已改为消费这套共享 support：两者都显式走 `ensureLocalRealProbeOptIn` + `loadProbeApiConfig(...)`，报告中保留 `probe_config_source` / `workspace_root`，并附带 observation-only 的 `information_probe` 汇总；长任务 probe 同时停止自动删除 workspace 产物，满足“保留产物、不默认消耗额度”的框架要求，但本轮没有实际跑真实 provider。已扩展 `apps/novel_agent_app/test/probe_support_test.dart`，覆盖 opt-in 配置来源、workspace 路径生成、waiting/budget/content/information/technical 分类，以及 information activation/artifact dry checks；`apps/novel_agent_app` 下 `flutter test test/probe_support_test.dart` 与 `flutter analyze` 已通过）
- PIS-28：已完成（2026-06-05，已按 `PIS-27` 框架显式开闸真实 probe，但只做小预算验证且不盲重跑：在 `apps/novel_agent_app` 下以进程级 `NOVEL_AGENT_ENABLE_REAL_PROBES=1` 运行 `dart run tool/real_general_novel_probe.dart --chapter-count=2` 与 `dart run tool/real_long_task_probe.dart`，两份报告分别落在 `artifacts/real_general_novel_probe_report.json`、`artifacts/real_long_task_probe_report.json`，对应 workspace 保留在 `artifacts/real_general_novel_probe_workspace/2026-06-05T09-53-06-080694/` 与 `artifacts/real_long_task_probe_workspace/2026-06-05T09-55-48-509444/`。普通项目 2 章链路 PASS，正式交付、章节/summary/character/timeline 落盘正常，但两章 `activation_report_summary` 都显示 `knowledge 0 / design 0 / research 0 / references 0`，`information_probe` 的 `information_changed_paths` 与 `information_tool_names` 为空，因此本轮普通项目真实结果应归类为“明确无信息变化”，而不是 information proposal 已触发。长任务短链 probe 也 PASS，且保留的 production activation report 文件 `tracking/chapter_atomic/plan_seed_to_full_novel_1780624549890315_chapter_001.activation_report.json` 与 `...chapter_002.activation_report.json` 的 summary 同样明确包含 `knowledge 0 / design 0 / research 0 / references 0` 计数，说明 long-task activation report 已携带 information 统计位，但本次真实样章/短链并未实际选入 information sections；对应报告里的 `information_probe` 仍为 success observation-only。由于文档明确要求“失败只记录事实，不盲跑”，本轮没有继续追加第二次真实尝试，也没有删除任何产物；结论是：PIS-28 的小预算真实验证已执行并留档，普通项目与长任务链路都可跑通，但本次真实样本尚未观察到 information proposal/activation 的非零落地，需要后续如果要继续推进真实 information 命中率时再针对性处理）
- PIS-29：已完成（2026-06-05，已在 `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart` 为 workflow CLI 摘要新增 Information 最小合同：`extractNarrativeRuntimeContract()` 现在会从稳定 runtime 输出中提炼 information 粗摘要，只消费 `changed_paths`、`checkpoint_review.review.information_summary` 与 `analysis_information` 等已有合同，不直接读取隐藏 JSON、不解释 payload；`narrativeBriefLines()` 则固定输出 `knowledge / design / research / reference` 四类计数，以及四个 projection 路径 `knowledge/项目知识摘要.md`、`knowledge/设计元素摘要.md`、`research/资料研究摘要.md`、`references/引用作品边界.md`，从而让 CLI 能快速看到本轮 information 侧是否有结构化落盘或分析提案，同时保持 presentation shell 边界，不承担 proposal 审批或业务规则。与此同时，已新增 `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`，覆盖“有 information changed paths 时显示计数和 signal”“零变更时仍显示 0 计数和 projection 路径”“仅有 `analysis_information` ids 时可回填计数”三类 focused 场景；并在 `apps/novel_agent_cli/pubspec.yaml` 补上 `test` dev dependency。`apps/novel_agent_cli` 下 `dart test` 与 `dart analyze` 已通过）
- PIS-30：已完成（2026-06-05，已在 `packages/novel_agent_adapters/lib/src/runtime/` 扩展 `ProjectLongTaskStationNarrativeSummary` 与 `ProjectLongTaskStationDetailService`，把 PIS-23 已有的 `information_summary / information_changed_paths`、PIS-16 的四个 information projection 路径，以及 `.novel_agent/information/knowledge_cards/`、`design_elements/`、`research_requests/`、`reference_works/` 下的待确认记录，统一投影为长任务总站可消费的稳定 detail contract；同时在 `apps/novel_agent_app/lib/features/long_task_station/` 为 detail view data 和详情面板新增 information summary、projection 和 pending confirmation 展示区块，只提供“打开投影/打开确认记录”入口，不做审批或应用动作。另一方面，`apps/novel_agent_app/lib/features/workbench/application/services/conversation_tool_entry_projection_service.dart` 现已能从稳定工具结果合同中提炼 `Information：knowledge/design/research/reference` 摘要、signal 与 projection 路径，让普通工作台时间线也能看到 information 变化，而不读取隐藏事实源或解释开放 payload。已补 `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`、`apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`、`apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`、`apps/novel_agent_app/test/conversation_tool_entry_projection_service_test.dart`；并通过 `packages/novel_agent_adapters` 下 `dart test test/project_long_task_station_detail_service_test.dart` 与 `dart analyze`，以及 `apps/novel_agent_app` 下 `flutter test test/long_task_station_view_data_service_test.dart test/long_task_run_detail_panel_test.dart test/conversation_tool_entry_projection_service_test.dart` 与 `flutter analyze`）

## 12. 最终剩余风险

1. 当前 GUI 仍然只做最小消费：可以看 summary、打开 projection、查看待确认记录，但还没有完整 knowledge browser，也没有 approval/apply 流。
2. workbench 侧的信息展示目前落在工具时间线 detail 中，适合确认“本轮有没有 information delta”，但不是独立的信息中心。
3. PIS-28 真实 probe 已证明存在“运行成功但 information 计数全 0”的有效样本；当前 GUI 已保留这类 0 计数摘要，不会把它误解成失败，但后续若要提升真实命中率，需要另开新主线针对 prompt / workflow 行为处理。

---

## 12. 生成后自检

1. 已说明本文解决什么。
2. 已回答巧思/设计不是只靠提示词，而是结构化信息对象。
3. 已说明与 ONS、写作连续性、MuMu 参考的关系。
4. 已做已有实现去重审计。
5. 已冻结架构边界。
6. 已描述目标终态。
7. 已覆盖 core contracts、tools、permissions、repositories、projection、gateway research、activation、ordinary、long task、deconstruction、explainer、probe、CLI、GUI。
8. 顺序为 core/domain 先行，adapters/runtime 随后，probe 和 GUI/CLI 靠后。
9. 每个 session 均包含目标、层级、必读文件、必须完成、本轮不要做、验收标准和直接可用提示词。
10. 已明确不写题材 hardcode、不让 Markdown 成为事实源、不让 GUI/CLI/probe 兜底底层设计。
11. 已包含总启动提示词和完成记录占位。
