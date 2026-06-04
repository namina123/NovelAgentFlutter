# NovelAgentFlutter 开放叙事状态与受控 Toolcall Runtime 任务顺序文档

最后更新：2026-06-05

关联分析文档：

- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/long-task-chapter-delivery-recovery-final-gap-analysis-2026-06-03.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/long-task-supervisor-control-plane-analysis-2026-06-03.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/stability-assurance-gap-analysis-2026-06-02.md`
- `docs/writing-continuity-foundation-session-order-2026-05-31.md`
- `agent.md`

关联历史会话：

- `C:\Users\PC\.codex\sessions\2026\05\23\rollout-2026-05-23T14-55-20-019e539d-f16c-7e82-be13-d582b514aa5c.jsonl`

关联代码锚点：

- `packages/novel_agent_core/lib/src/continuity/`
- `packages/novel_agent_core/lib/src/runtime/`
- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/deconstruction/`
- `packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `apps/novel_agent_app/lib/features/task_center/`
- `apps/novel_agent_app/lib/features/book_deconstruction/`
- `apps/novel_agent_cli/`
- `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`

---

## 1. 这份文档解决什么

这份文档把 `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md` 的最终设计，拆成可执行、可验收、单会话可完成的实现顺序。

本主线命名为 `ONS`：Open Narrative State。

它要解决的不是“快穿探针”或“死亡回归探针”本身，而是把这些压力场景暴露的问题收束成正式架构：

1. 章节交付必须是领域动作，不应长期依赖一组脆弱的 `write_project_file` 组合。
2. 程序只管合同、结构、恢复、权限和调度，不做文学语义关键词裁判。
3. 智能体可以通过受控领域 toolcall 提交章节、claims、profile proposal、semantic review、constraint binding。
4. 普通项目、长任务、拆书、解书、解释分析必须共享同一套叙事状态底座。
5. 未知小说流派、未知变化机制、未知项目规则必须能保留、评审、演化，而不是被 core 静默丢弃或逼成固定枚举。
6. Markdown 是用户和智能体可读投影，不是唯一事实源。
7. GUI / CLI 最后接入，只消费稳定合同，不承担底层补洞。
8. 项目级解释器必须把未知变化转成项目内可理解事实，而不是继续逼 core 预置题材。
9. 用户编辑 Markdown 投影后，必须能回到结构化 proposal / draft，而不是让 Markdown 直接成为运行时真相。

完成本文全部 session 后，系统应当具备：

1. `submit_chapter_delivery` 等领域工具正式接入写作 runtime。
2. `NarrativeStateClaim`、`NarrativeProfile`、`NarrativeStateLedger`、`SemanticReview`、`ConstraintBinding` 等核心合同可持久化、可审计、可投影。
3. writer / reviewer / recovery / profile architect 的工具调用边界清晰。
4. supervisor 消费 delivery / claim / review 的结构化结论，而不是读正文猜语义。
5. 普通小说、普通长任务、拆书续写、解书分析都能通过同一套工具和账本交互。
6. 快穿、死亡回归、多世界、回档等只作为未来压力输入，不作为 core 分支。
7. `analysis namespace`、`source` 与可信度差异能在同一账本体系中被保留和提升。

---

## 2. 与旧文档的关系

### 2.1 最终分析优先

实现时以 `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md` 第十四、十五、十六章为准：

1. 第十四章：开放叙事状态承接架构。
2. 第十五章：开放 Toolcall 架构，用受控领域工具替代运行时脚本。
3. 第十六章：从 MuMu 与其他小说 Agent 中吸收产品与架构思想。

第十三章已经被文档标记为过渡稿，只能作为 profile architect 的提示素材，不能作为 core 实现目标。

### 2.2 旧稳定性文档保留，但降级为底座成果

不推翻：

1. `LSCP-*` 的 supervisor 控制面。
2. `CDR-*` 的章节交付与恢复问题分析。
3. `RPR-*` 的真实探针修复、字数、表达限制、去 AI 经验。
4. `WCF-*` 的 continuity 基础。
5. `BDRC-*` 的拆书续写补实链。

但旧文档中题材化、特殊机制化、探针驱动的实现描述，要在本主线中被中性化：

1. `special_mechanic` 相关实现只能作为 legacy bridge / 压力探针标签 / 迁移输入。
2. 程序化判断“这是不是快穿”“这是不是死亡回归”不再作为 core gate。
3. 旧探针只保留验收价值，不允许形成 production 之外的第二套业务判断。

### 2.3 MuMu 只吸收思想，不吸收实现

可吸收：

1. 后台任务必须有稳定 ID、状态、进度、错误、取消、重试、更新时间。
2. 用户回来后能看到任务现场。
3. 长流程需要低歧义的恢复和接管入口。

不可吸收：

1. 不复制 GPL 代码、字段、文案、类结构。
2. 不把本项目压平成一个粗粒度后台任务表。
3. 不用 MuMu 替代我们的章节交付、tool evidence、claims、semantic review、supervisor 组合。

### 2.4 历史会话约束纳入本轮执行

从本地历史会话和 `agent.md` 中继续执行这些长期约束：

1. core / adapters / app / CLI 分层不能乱。
2. 不让单一文件过大，`ProjectWorkflowRuntimeService` 只能薄接线。
3. 修 bug 优先修合同断裂，不堆隐式副作用。
4. 新合同成立后要尽快收口调用点，不能长期双轨。
5. 真实 probe 不硬编码密钥、模型、用户路径，不把一次性探针当正式产品能力。
6. 一切修改都要向“普通项目和长任务共享稳定性底座”偏靠。

---

## 3. 已有实现去重审计

### 3.1 已有，不重做

1. continuity 基础：
   - `ContinuationScope`
   - `ContinuationScopeOverlay`
   - `ContinuityFrame`
   - `ContinuityMechanicProfile`
   - `ProjectContinuityBundle`
   - `ContinuityRuntimeResolverService`

2. 章节和长任务基础：
   - `chapter_atomic_*`
   - `chapter_length_*`
   - `long_task_*`
   - `LongTaskSupervisor`
   - `LongTaskRunEventWindow`
   - `LongTaskRecoveryPlan`
   - `LongTaskRunCenterContractService`

3. 约束和交付经验：
   - 字数目标窗口、环绕策略、审核容忍。
   - 表达限制和去 AI 评估。
   - draft narrative output gate。
   - task artifact gate。

4. 工具和 evidence 基础：
   - `write_project_file`
   - `ToolRoundContext`
   - tool round evidence 相关测试。
   - `draft_generation_tool_call_reliability_test.dart`

5. 拆书基础：
   - extraction / apply / foundation build / derived project 相关链路。

### 3.2 已有但只是半成品

1. `special_mechanic_*`
   - 已证明方向过窄。
   - 后续只作为迁移桥，不继续扩展。

2. `write_project_file` 写章节
   - 可保留为底层文件工具。
   - 不能继续永久承担“完成一章”的领域语义。

3. 章节交付恢复
   - 已有 gate 和 failure classifier。
   - 还缺以 `submit_chapter_delivery` 为中心的领域状态机。

4. continuity sidecar
   - 已有 scope/frame 底座。
   - 还缺开放 claim、章节状态提交包、ledger、review。

5. supervisor
   - 已有控制面。
   - 还缺消费 claim/review/delivery disposition 的风险策略桥。

6. 上下文注入
   - 已有 context file selection 和 continuity projection。
   - 还缺可解释的 context activation contract。

### 3.3 真正要补的层

1. Core domain：
   - 开放 claims、profile、ledger、semantic review、constraint binding、context activation、domain tool outcome。

2. Core validation：
   - JSON codec、未知 payload 保留、引用校验、profile 最小要求、权限风险策略。

3. Core tools：
   - 领域工具 schema、工具结果、工具路由合同。

4. Adapters：
   - `.novel_agent/continuity/*`、`.novel_agent/constraints/*`、`.novel_agent/reviews/*` 的文件/JSONL 存储。
   - Markdown 投影。
   - domain tool executor。

5. Workflow / runtime：
   - writer / reviewer / recovery / architect 的任务边界。
   - `ProjectWorkflowRuntimeService` 只做薄编排。

6. Supervisor：
   - 消费 delivery outcome、claim disposition、semantic review finding、permission result。

7. Probe / regression：
   - 先 mock 工具可靠性，再真实 provider。
   - 压力题材只作为输入，不成为 core 判断逻辑。

8. GUI / CLI：
   - 最后对接知识账本、权限确认、运行报告和投影查看。

---

## 4. 本轮冻结的架构边界

1. 不引入运行时 Dart eval 或用户脚本作为核心开放能力。
2. 不把快穿、死亡回归、多世界、聊天群、主神空间、回档等写进 core 分支。
3. 不把示例题材变成 tool 参数枚举。
4. 不让程序用关键词判断文学语义。
5. 不让 `write_project_file` 永久承担章节交付领域动作。
6. 不让 Markdown 成为唯一事实源。
7. 不让 reviewer 直接推进任务。
8. 不让 supervisor 读正文做文学判断。
9. 不让 GUI / CLI 解释 claim payload 或兜底底层设计。
10. 不让 probe、fallback、bridge 成为新的业务中心。
11. 不让 `ProjectWorkflowRuntimeService` 继续吸收 profile / claim / risk policy 算法。
12. 不让未知 claim namespace / payload 静默丢弃。
13. 不让智能体无权限修改项目长期规则。
14. 不复制 GPL MuMu 代码或文案。
15. 不在仓库根目录或正式脚本中硬编码真实 API key、模型、个人路径。

---

## 5. 目标终态

### 5.1 事实源终态

结构化事实源：

```text
.novel_agent/continuity/narrative_profiles/*.json
.novel_agent/continuity/claims/*.jsonl
.novel_agent/continuity/ledger/*.jsonl
.novel_agent/constraints/bindings/*.json
.novel_agent/reviews/semantic/*.json
```

用户和智能体可读投影：

```text
continuity/叙事状态规则.md
continuity/最近状态变化.md
constraints/项目约束摘要.md
reviews/语义复核摘要.md
```

规则：

1. JSON / JSONL 是程序事实源。
2. MD 是投影。
3. 用户编辑 MD 后必须转为 proposal 或结构化更新。
4. 未知 payload 必须保留。
5. 来自拆书、解书、解释分析的事实可以先进入独立 namespace，再被提升为续写事实。

### 5.2 工具终态

至少具备下面这些受控领域工具：

1. `submit_chapter_delivery`
2. `submit_narrative_state_claims`
3. `propose_narrative_profile_update`
4. `submit_semantic_review`
5. `propose_constraint_binding`
6. `request_profile_clarification`

`write_project_file` 继续存在，但定位为底层文件工具。

### 5.3 智能体权责终态

1. writer：
   - 负责正文和本章状态提交。
   - 不偷偷改项目长期规则。

2. reviewer：
   - 负责语义复核和 findings。
   - 不拥有调度权。

3. recovery：
   - 只修一个明确失败目标。
   - 不同时继续写下一章。

4. profile architect：
   - 提出 profile / constraint proposal。
   - 不直接覆盖已接受规则。

5. supervisor：
   - 非 LLM 控制面。
   - 只消费结构化结果和风险策略。

### 5.4 产品终态

1. 普通小说项目默认简单可用。
2. 高级连续性、约束、账本、审稿信息可查看、可解释、可接管。
3. 长任务稳定性不依赖某个题材。
4. 拆书和解书能产出 claims / profile proposals / semantic findings。
5. 压力探针可以跑复杂输入，但报告必须区分技术失败、等待用户、预算失败、内容质量失败。

---

## 6. Session 数量与顺序设计理由

本轮切成 `44` 个 session。

这样安排的原因：

1. 先 core 合同，再 adapters，再 runtime，再 supervisor，再 probe，最后 GUI / CLI。
2. 章节交付、claims、profile、semantic review、constraint、context activation 分开落地，避免单文件和单服务过重。
3. 每个 session 都能在一次会话内完成，主要逻辑量约 2000 行以内。
4. 如果某个 session 开始时发现上轮半成品或关联错误，必须先修上轮，不开启本轮。
5. 所有 session 合起来覆盖最终设计，不把缺口留给 UI 或探针兜底。

---

## 7. 全局执行规则

每个 session 都必须遵守：

1. 先读本文档、最终分析文档、`agent.md`。
2. 只完成当前 session，不开启下一任务。
3. 遇到上轮未完成或关联错误，先修那个错误。
4. 优先复用已有 service / contract / repository / runtime hook。
5. 单文件超过 400 行要复核职责，超过 700 行必须拆分。
6. core 不 import adapters / Flutter。
7. adapters 不成为业务规则中心。
8. GUI / CLI 不直接拼业务规则。
9. 每轮补 focused test / contract test，除非明确是文档轮。
10. 真实 provider 探针必须显式开闸，不能默认消耗额度。
11. 不提交真实 key，不恢复根目录 `test_api.txt`。

---

## 8. Session 顺序

### ONS-01 现状审计与 legacy 降级图

本轮目标：建立实现前的可执行审计清单，明确哪些文件保留、迁移、冻结、废弃。

层级归属：Documentation / Architecture audit。

必读文件：

- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- `agent.md`
- `packages/novel_agent_core/lib/src/continuity/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/workflow/`

必须完成：

1. 新增 `docs/open-narrative-state-implementation-audit-2026-06-04.md`。
2. 列出已有 continuity、chapter delivery、supervisor、tool evidence、special_mechanic、deconstruction 相关文件。
3. 标记 `keep / extend / migrate / freeze / deprecate`。
4. 明确 `special_mechanic_*` 只作为 legacy bridge，不继续扩展。
5. 给出本主线每个阶段要碰的核心文件和禁止碰的边界。

本轮不要做：

1. 不写 core 代码。
2. 不重命名文件。
3. 不跑真实探针。

验收标准：

1. 审计文档覆盖所有关键目录。
2. 与本文档取舍一致。
3. 无实现改动。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-01，只做现状审计与 legacy 降级图。必须读取最终分析文档和 agent.md，新增实现审计文档，明确 keep / extend / migrate / freeze / deprecate。不要写 core 代码，不要重命名文件，不要开启 ONS-02。注意解耦合、单一职责、不要让 special_mechanic 继续主导架构。
```

### ONS-02 Core 命名空间和导出骨架

本轮目标：建立开放叙事状态的 core 文件组织，不放业务算法。

层级归属：Core / domain scaffolding。

必读文件：

- `packages/novel_agent_core/lib/novel_agent_core.dart`
- `packages/novel_agent_core/lib/src/continuity/`
- `docs/open-narrative-state-implementation-audit-2026-06-04.md`

必须完成：

1. 新建中性目录或文件组，例如 `src/continuity/narrative_state/`、`src/continuity/context_activation/`、`src/tools/domain/`。
2. 只放轻量 barrel、基础 typedef、命名说明。
3. 更新 core 导出。
4. 增加最小编译测试，确认新目录可 import。

本轮不要做：

1. 不实现 claims / profile 具体字段。
2. 不动 adapters。
3. 不接 runtime。

验收标准：

1. `dart analyze packages/novel_agent_core` 通过。
2. 无题材命名进入新 core 目录。
3. 单文件保持轻量。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-02，只做 core 命名空间和导出骨架。先读取 ONS-01 审计结果；新建中性目录，不实现业务算法，不碰 adapters/runtime/UI，不开启下一任务。补最小 import/compile 测试，运行 core analyze。注意文件体量和职责拆分。
```

### ONS-03 Narrative 引用与 Evidence 基础合同

本轮目标：先定义跨 claims、sidecar、review、context activation 共用的引用与证据模型。

层级归属：Core / domain contract。

必读文件：

- `packages/novel_agent_core/lib/src/continuity/continuity_asset_reference.dart`
- `packages/novel_agent_core/lib/src/runtime/tool_round_evidence.dart`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`

必须完成：

1. 新增 `NarrativeRef`、`NarrativeEvidenceRef`、`NarrativeSourceRef`、`NarrativeTextSpanRef` 等小模型。
2. 支持 source：writer、reviewer、deconstruction、explainer、user、system、recovery。
3. 支持引用项目资产、章节、segment、tool round、外部导入片段。
4. 编写 codec 与 focused tests。

本轮不要做：

1. 不写 claim 模型。
2. 不做持久化。
3. 不读取正文做语义判断。

验收标准：

1. 引用模型可序列化。
2. unknown source 可保留为字符串。
3. tests 覆盖未知类型不丢失。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-03，只做 Narrative 引用与 Evidence 基础合同。不要实现 claim/profile/review，不做 adapters 持久化，不开启下一任务。必须补 codec focused test，验证未知 source/ref 类型保留。保持 core 纯 Dart、小文件、无题材硬编码。
```

### ONS-04 NarrativeStateClaim 开放模型

本轮目标：实现开放叙事状态声明模型，确保未知 namespace / payload 不丢失。

层级归属：Core / domain contract。

必读文件：

- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`
- ONS-03 新增引用模型

必须完成：

1. 新增 `NarrativeStateClaim`。
2. 字段至少覆盖 `claim_id`、`claim_namespace`、`claim_label`、`claim_payload`、`affected_refs`、`context_refs`、`evidence_refs`、`source`、`confidence`、`uncertainty`、`schema_version`。
3. payload 使用开放 JSON，不写题材枚举。
4. 增加 codec、copy、validation basics。
5. 测试未知 namespace、嵌套 payload、空 claims。

本轮不要做：

1. 不做 ledger reducer。
2. 不做 profile 解释。
3. 不做智能体工具。

验收标准：

1. unknown payload 原样 round-trip。
2. claim 不依赖快穿/死亡回归等题材字段。
3. core tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-04，只实现 NarrativeStateClaim 开放模型和测试。payload 必须开放 JSON，未知 namespace 必须保留。不要做 ledger/profile/tool/adapters，不开启下一任务。补 focused codec/validation tests，保持 core 小文件。
```

### ONS-05 NarrativeProfile 与 Profile Proposal 合同

本轮目标：定义项目级解释器与更新提案合同，让智能体能提出但不能直接覆盖长期规则。

层级归属：Core / domain contract。

必读文件：

- `packages/novel_agent_core/lib/src/continuity/project_continuity_bundle.dart`
- `packages/novel_agent_core/lib/src/continuity/continuity_mechanic_profile.dart`
- ONS-04 claim 模型

必须完成：

1. 新增 `NarrativeProfile`、`NarrativeProfilePatch`、`NarrativeProfileProposal`。
2. 支持 profile 生命周期状态：draft、proposed、accepted、active、deprecated、superseded、rejected。
3. profile patch 必须开放，不写题材枚举。
4. 支持 `requires_user_confirmation`、reason、confidence、source。
5. 添加 codec tests。

本轮不要做：

1. 不做 proposal reducer。
2. 不做 UI。
3. 不迁移旧 `ContinuityMechanicProfile`。

验收标准：

1. profile proposal 不能表示“直接覆盖已接受规则”的隐式动作。
2. 旧 continuity profile 可在未来映射到 profile extension。
3. tests 覆盖 unknown profile extension round-trip。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-05，只做 NarrativeProfile 与 Profile Proposal 合同。profile patch 必须开放，不能写题材枚举。不要实现 reducer、UI 或迁移，不开启下一任务。补 codec/round-trip tests，保持 core 纯净。
```

### ONS-06 NarrativeStateLedger 与 Disposition 合同

本轮目标：定义 claims 进入项目事实账本后的状态、来源、覆盖、废弃和审计字段。

层级归属：Core / domain contract。

必读文件：

- ONS-04 `NarrativeStateClaim`
- ONS-05 `NarrativeProfileProposal`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`

必须完成：

1. 新增 `NarrativeLedgerEntry`、`NarrativeClaimDisposition`、`NarrativeLedgerEvent`。
2. 支持 observed、proposed、accepted、questioned、rejected、superseded。
3. 支持 source 与 evidence refs。
4. 支持 replacement / supersedes 引用。
5. 添加 codec tests。

本轮不要做：

1. 不写 reducer。
2. 不接存储。
3. 不接 reviewer。

验收标准：

1. 账本合同能表达拆书抽取、写作声明、解书推断、用户声明的不同来源。
2. 不因 source 不同而覆盖同一事实。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-06，只做 NarrativeStateLedger 与 Disposition 合同。要支持 observed/proposed/accepted/questioned/rejected/superseded 和 source/evidence。不要写 reducer、存储、reviewer 接线，不开启下一任务。补 codec tests。
```

### ONS-07 Chapter Narrative Submission 合同

本轮目标：把章节 sidecar 升级为章节状态提交包，支持章内 segment 和 transition。

层级归属：Core / domain contract。

必读文件：

- ONS-03 引用模型
- ONS-04 claims
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_*`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_*`

必须完成：

1. 新增 `ChapterNarrativeSubmission`。
2. 新增 `NarrativeSegment`、`NarrativeTransition`。
3. 支持 segment 章内顺序、可选 text span、scope/frame refs、claim refs。
4. transition kind 使用开放字符串。
5. 支持 final state summary 和 constraint coverage。
6. 添加 tests 覆盖章内多个 transition、空 claims、未知 transition kind。

本轮不要做：

1. 不接 submit tool。
2. 不写正文扫描判断转折。
3. 不迁移旧 special mechanics。

验收标准：

1. 一章内 0..N segment / transition 可表达。
2. 不要求 transition 出现在章首或章尾。
3. no genre hardcode。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-07，只做 ChapterNarrativeSubmission、NarrativeSegment、NarrativeTransition 合同和测试。transition kind 必须开放，不能写快穿/死亡回归分支。不要接工具、不要扫描正文判断语义、不开启下一任务。
```

### ONS-08 Semantic Review 合同

本轮目标：定义 reviewer agent 提交的结构化复核报告，不让 reviewer 拥有调度权。

层级归属：Core / domain contract。

必读文件：

- ONS-03 引用模型
- ONS-04 claims
- ONS-06 ledger
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_*`

必须完成：

1. 新增 `NarrativeSemanticReview`、`SemanticReviewFinding`。
2. 支持 severity：info、low、medium、high、blocking。
3. 支持 accepted/questioned/suggested claims。
4. 支持 recommended disposition：accept、accept_with_note、repair、checkpoint_user、manual_attention。
5. 明确 reviewer output 只是建议。
6. 添加 tests。

本轮不要做：

1. 不做 supervisor 决策。
2. 不做关键词评估。
3. 不接 LLM。

验收标准：

1. finding 必须能引用 evidence 或说明无法定位。
2. reviewer 不直接改变 ledger accepted 状态。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-08，只做 Semantic Review 合同。reviewer 只能提交 findings/recommendation，不拥有调度权。不要接 supervisor、不要做关键词评估、不要开启下一任务。补 codec 和边界测试。
```

### ONS-09 Constraint Binding Proposal 合同

本轮目标：把字数、表达限制、去 AI、风格、叙事规则等统一为可绑定约束提案，保留用户可见语义。

层级归属：Core / domain contract。

必读文件：

- `agent.md` 中写作稳定性与执行约束部分
- `packages/novel_agent_core/lib/src/workflow/chapter_length_*`
- `packages/novel_agent_core/lib/src/workflow/expression_constraint_*`
- ONS-05 profile proposal

必须完成：

1. 新增 `NarrativeConstraintBindingProposal`、`ConstraintBindingScope`、`ConstraintBindingPolicy`。
2. 支持 applies_to：writing、review、repair、deconstruction、explanation。
3. 支持 hard_execution_policy 与 soft_review_policy。
4. 支持权限字段：auto_accept、requires_user_confirmation、forbidden_auto_apply。
5. 添加 tests 覆盖字数、表达限制、未知约束类型。

本轮不要做：

1. 不替换现有字数/表达限制链。
2. 不做 UI 高级设置。
3. 不实现权限策略。

验收标准：

1. 字数目标可以作为策略字段表达，但不消灭用户熟悉的目标字数。
2. 表达限制可新增、可绑定、可区分内置/项目级。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-09，只做 Constraint Binding Proposal 合同。要覆盖字数、表达限制、去 AI、未知约束，保留用户可见语义。不要替换现有运行链，不做 UI，不开启下一任务。补 focused tests。
```

### ONS-10 Context Activation 合同

本轮目标：定义每轮模型调用到底注入了什么、为什么注入、预算裁掉什么。

层级归属：Core / domain contract。

必读文件：

- `packages/novel_agent_core/lib/src/runtime/project_context_file_selection_service.dart`
- `packages/novel_agent_core/lib/src/workflow/long_task_continuity_context_projection_service.dart`
- ONS-03 引用模型

必须完成：

1. 新增 `ContextActivationPlan`、`ContextActivationItem`、`ContextActivationReport`。
2. 支持 activation reason：keyword、ref、claim、profile_policy、task_type、manual_pin、semantic_retrieval。
3. 支持 budget、selected、omitted、truncated。
4. 添加 tests。

本轮不要做：

1. 不实现检索算法。
2. 不接 prompt builder。
3. 不接 GUI。

验收标准：

1. 可解释本轮注入内容和裁剪原因。
2. 不依赖某个题材。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-10，只做 Context Activation 合同。要能表达注入原因、预算、裁剪、遗漏。不要实现检索算法，不接 prompt/UI，不开启下一任务。补 focused tests。
```

### ONS-11 Domain Tool Outcome 通用合同

本轮目标：建立领域工具调用的统一结果、权限、错误和审计合同。

层级归属：Core / tools contract。

必读文件：

- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/runtime/tool_execution_service.dart`
- ONS-03 到 ONS-10 合同

必须完成：

1. 新增 `DomainToolRequest`、`DomainToolOutcome`、`DomainToolPermissionDecision`、`DomainToolError`。
2. 支持 accepted、proposed、rejected、needs_user_confirmation、invalid_payload、execution_failed。
3. 支持关联 tool round evidence。
4. 添加 tests。

本轮不要做：

1. 不定义具体工具 schema。
2. 不接 dispatcher。
3. 不动 adapters。

验收标准：

1. 工具失败、权限等待、结构错误可区分。
2. outcome 可被 supervisor 和 runtime 消费。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-11，只做 Domain Tool Outcome 通用合同。必须区分 accepted/proposed/rejected/needs_user_confirmation/invalid_payload/execution_failed。不要定义具体工具 schema，不接 dispatcher，不开启下一任务。补 contract tests。
```

### ONS-12 开放 JSON Codec 与结构校验服务

本轮目标：为开放 payload 建立统一 codec、版本、未知字段保留和基础结构校验。

层级归属：Core / validation。

必读文件：

- `packages/novel_agent_core/lib/src/common/json_types.dart`
- ONS-04 到 ONS-11 合同

必须完成：

1. 新增小型开放 JSON codec/validator 服务。
2. 支持 schema_version。
3. 支持 unknown fields preservation。
4. 支持 required field 轻校验。
5. 将 ONS-04 到 ONS-11 的重复校验收口到共享服务。
6. 补 tests。

本轮不要做：

1. 不引入 JSON schema 第三方重依赖，除非项目已有。
2. 不做文学语义校验。
3. 不接存储。

验收标准：

1. 未知字段 round-trip。
2. required 缺失能返回结构错误。
3. 不把开放 payload 归一化丢字段。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-12，只做开放 JSON Codec 与结构校验服务。未知字段必须保留，required 缺失返回结构错误。不要做语义校验，不接存储，不开启下一任务。补 focused tests，并复用已有 common json 类型。
```

### ONS-13 Claims / Profile / Submission 结构校验器

本轮目标：实现 claims、profile proposal、chapter submission 的结构校验，不判断文学真伪。

层级归属：Core / validation。

必读文件：

- ONS-04 `NarrativeStateClaim`
- ONS-05 `NarrativeProfileProposal`
- ONS-07 `ChapterNarrativeSubmission`
- ONS-12 codec/validator

必须完成：

1. 新增 `NarrativeClaimValidator`。
2. 新增 `NarrativeProfileProposalValidator`。
3. 新增 `ChapterNarrativeSubmissionValidator`。
4. 校验 JSON、引用基本格式、segment 顺序、transition 引用 segment、profile 最小要求。
5. 添加 tests。

本轮不要做：

1. 不判断转折是否精彩。
2. 不扫关键词。
3. 不做 ledger reducer。

验收标准：

1. bad structure 可被明确报告。
2. 文学语义不进入 validator。
3. tests 覆盖无 segment、多 segment、未知 transition kind。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-13，只做 claims/profile/submission 结构校验器。程序只校验结构，不判断文学真伪，不扫关键词，不开启下一任务。补 validator focused tests，保持服务小而分离。
```

### ONS-14 权限与风险策略 Core 服务

本轮目标：实现工具提案的权限分级和自动接受边界。

层级归属：Core / policy。

必读文件：

- ONS-09 constraint binding
- ONS-11 domain tool outcome
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md` 15.5

必须完成：

1. 新增 `NarrativePermissionPolicyService`。
2. 处理自动接受、自动提案、用户确认、禁止自动执行。
3. 覆盖 profile 更新、constraint binding、claim submission、semantic review。
4. 添加 tests。

本轮不要做：

1. 不接 UI 确认。
2. 不做存储。
3. 不允许用户脚本执行。

验收标准：

1. 高风险 profile/constraint 更新必须需要用户确认。
2. 本章局部 low-risk claim 可以自动接受或进入 proposed。
3. tests 覆盖禁止自动执行。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-14，只做权限与风险策略 core 服务。必须区分自动接受、自动提案、用户确认、禁止自动执行。不要接 UI/存储，不开启下一任务。补 policy tests，禁止引入运行时脚本能力。
```

### ONS-15 Profile Proposal Reducer 与项目级解释器

本轮目标：实现 profile proposal 的纯 core 生命周期流转，并补上项目级解释器服务，让未知变化能被项目自己解释。

层级归属：Core / domain service。

必读文件：

- ONS-05 profile 合同
- ONS-14 权限策略
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md`

必须完成：

1. 新增 `NarrativeProfileProposalService`。
2. 支持 propose、accept、reject、supersede、deprecate。
3. 生成审计事件。
4. 处理冲突 proposal。
5. 新增 `NarrativeProfileInterpreterService` 或等价纯 core 服务。
6. 解释器要能根据 active profile 解释：
   - claim namespace 的项目内语义
   - 最小字段要求
   - 风险提升或降级建议
   - unknown payload 的最小保留解释
7. 添加 tests。

本轮不要做：

1. 不做文件写入。
2. 不做 UI。
3. 不迁移旧 mechanic profile。
4. 不做题材关键词判断。

验收标准：

1. 智能体不能绕过 proposal 直接变 active。
2. supersede 有清晰引用。
3. 解释器不依赖快穿/死亡回归等题材枚举。
4. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-15，只做 Profile Proposal Reducer 与项目级解释器。智能体 proposal 不能直接变 active，解释器必须基于项目 profile 而不是题材枚举来理解未知变化。不要接存储/UI/旧迁移，不开启下一任务。补 reducer 和 interpreter tests。
```

### ONS-16 Claim Ledger Reducer

本轮目标：实现 claims 进入 ledger 后的纯 core 归并、置疑、接受、废弃、替换。

层级归属：Core / domain service。

必读文件：

- ONS-04 claim
- ONS-06 ledger
- ONS-08 semantic review
- ONS-14 权限策略

必须完成：

1. 新增 `NarrativeStateLedgerService`。
2. 支持 submit、accept、question、reject、supersede。
3. 支持 review finding 建议但不自动替代策略。
4. 添加 tests。

本轮不要做：

1. 不做持久化。
2. 不做全文检索。
3. 不让 reviewer 拥有最终调度权。

验收标准：

1. 不同 source 的 claim 可并存。
2. review 只能产生建议，最终 disposition 由 service/policy 决定。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-16，只做 Claim Ledger Reducer。要支持多 source claim、accept/question/reject/supersede。reviewer 只能建议，不拥有调度权。不要做存储/检索，不开启下一任务。补 reducer tests。
```

### ONS-17 Evidence Resolver 结构校验

本轮目标：实现 evidence refs 的结构级解析和文本 span 粗校验，为后续 review 与 submission 提供事实边界。

层级归属：Core / validation。

必读文件：

- ONS-03 引用模型
- ONS-07 submission
- `packages/novel_agent_core/lib/src/workflow/chapter_length_measurement_service.dart`

必须完成：

1. 新增 `NarrativeEvidenceResolverService`。
2. 支持根据给定的内存文本和 refs 验证 span 范围。
3. 支持 missing / unresolved / out_of_range / ambiguous。
4. 不读取文件系统。
5. 添加 tests。

本轮不要做：

1. 不判断文本语义。
2. 不做 adapters 文件读取。
3. 不做检索。

验收标准：

1. span 不合法能报告。
2. 未提供正文时返回 unresolved，不抛错。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-17，只做 Evidence Resolver 结构校验。只验证 refs/span 是否可解析，不判断语义，不读文件系统，不开启下一任务。补 focused tests。
```

### ONS-18 Context Activation Planner

本轮目标：实现纯 core 的上下文激活规划器，输入候选资产和预算，输出可解释计划。

层级归属：Core / context planning。

必读文件：

- ONS-10 Context Activation 合同
- ONS-03 引用模型
- `packages/novel_agent_core/lib/src/runtime/project_context_file_selection_service.dart`

必须完成：

1. 新增 `ContextActivationPlannerService`。
2. 支持候选 item、权重、预算、pin、required。
3. 输出 selected/omitted/truncated 与原因。
4. 添加 tests。

本轮不要做：

1. 不接真实检索。
2. 不读项目文件。
3. 不接 prompt builder。

验收标准：

1. 预算不足时报告被裁剪项。
2. required item 处理有明确策略。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-18，只做 Context Activation Planner。输入候选和预算，输出可解释 selected/omitted/truncated。不要接真实检索/文件/prompt，不开启下一任务。补 budget tests。
```

### ONS-19 Chapter Delivery State Machine 对齐

本轮目标：把现有章节交付 gate 与未来 `submit_chapter_delivery` 的 outcome 对齐到统一状态机。

层级归属：Core / workflow contract。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/chapter_delivery_*`
- `packages/novel_agent_core/lib/src/workflow/draft_narrative_output_gate_service.dart`
- ONS-07 submission
- ONS-11 outcome

必须完成：

1. 新增或演化 `ChapterDeliveryStateMachine`。
2. 覆盖 delivered、delivered_needs_repair、missing_output_recoverable、invalid_output_rewrite_required、path_mismatch_recoverable、waiting_user_choice、manual_attention_required、hard_failure。
3. 映射现有 artifact gate / narrative output gate。
4. 添加 tests。

本轮不要做：

1. 不接 adapters 写文件。
2. 不接 supervisor。
3. 不跑真实探针。

验收标准：

1. 空正文、标题-only、路径漂移、submission 缺失能区分。
2. submission 不完整不直接否定正文交付。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-19，只做 Chapter Delivery State Machine 对齐。要把现有 gate 和未来 submit_chapter_delivery outcome 统一。不要接 adapters/supervisor/真实探针，不开启下一任务。补状态机 tests。
```

### ONS-20 领域工具 Schema 定义

本轮目标：定义六个领域工具的 schema、参数模型和解析错误，不执行工具。

层级归属：Core / tool schema。

必读文件：

- ONS-04 到 ONS-11 合同
- `packages/novel_agent_core/lib/src/tools/`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md` 15.3

必须完成：

1. 新增 `NarrativeDomainToolCatalog`。
2. 定义 `submit_chapter_delivery`、`submit_narrative_state_claims`、`propose_narrative_profile_update`、`submit_semantic_review`、`propose_constraint_binding`、`request_profile_clarification`。
3. 支持 schema 输出给 provider tool calling。
4. 添加解析 tests。

本轮不要做：

1. 不执行工具。
2. 不接 provider。
3. 不写 adapters。

验收标准：

1. schema 不含题材枚举。
2. 参数解析保留未知 payload。
3. malformed payload 返回结构错误。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-20，只做六个领域工具 schema 和参数解析。不要执行工具，不接 provider/adapters，不开启下一任务。schema 不能写题材枚举，必须保留未知 payload，补 parser tests。
```

### ONS-21 Tool Dispatcher Core Contract

本轮目标：建立领域工具 dispatcher 的 core port，不绑定本地文件系统。

层级归属：Core / tool runtime contract。

必读文件：

- ONS-11 outcome
- ONS-20 tool schema
- `packages/novel_agent_core/lib/src/runtime/tool_execution_service.dart`

必须完成：

1. 新增 `NarrativeDomainToolDispatcher` port。
2. 新增 handler interfaces。
3. 支持 tool capability 声明。
4. 支持 permission decision 返回。
5. 添加 mock tests。

本轮不要做：

1. 不实现本地存储。
2. 不接 `ProjectToolDispatcher`。
3. 不接 LLM。

验收标准：

1. core 只定义接口和纯结果。
2. mock dispatcher 能返回 accepted / needs_user_confirmation / invalid_payload。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-21，只做 Tool Dispatcher Core Contract。core 只定义 port/handler/outcome，不实现本地文件系统，不接 ProjectToolDispatcher，不开启下一任务。补 mock tests。
```

### ONS-22 `submit_chapter_delivery` Core Handler 合同

本轮目标：定义章节交付领域工具的 handler 输入输出和状态机交互，不写文件。

层级归属：Core / tool handler contract。

必读文件：

- ONS-07 submission
- ONS-19 delivery state machine
- ONS-20 schema
- ONS-21 dispatcher

必须完成：

1. 新增 `SubmitChapterDeliveryHandler` port/contract。
2. 输入包括 chapter path、content、submission、constraint coverage。
3. 输出包括 delivery outcome、正文交付状态、sidecar 状态、evidence。
4. 空正文、title-only、submission invalid 必须可区分。
5. 添加 tests。

本轮不要做：

1. 不写文件。
2. 不接 postprocess。
3. 不替换 `write_project_file`。

验收标准：

1. 缺正文优先判交付失败。
2. submission 缺失可触发补做而不否定正文。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-22，只做 submit_chapter_delivery core handler 合同。不要写文件，不替换 write_project_file，不开启下一任务。必须区分空正文、title-only、submission invalid，并补 tests。
```

### ONS-23 Claims / Profile / Review / Constraint Handler 合同

本轮目标：定义其余四类提交/提案工具的 handler 合同。

层级归属：Core / tool handler contract。

必读文件：

- ONS-04 claim
- ONS-05 profile proposal
- ONS-08 semantic review
- ONS-09 constraint binding
- ONS-14 permission policy
- ONS-21 dispatcher

必须完成：

1. 新增 claims handler contract。
2. 新增 profile proposal handler contract。
3. 新增 semantic review handler contract。
4. 新增 constraint binding handler contract。
5. 每个 handler 都返回 `DomainToolOutcome`。
6. 添加 tests。

本轮不要做：

1. 不做持久化。
2. 不接 UI 确认。
3. 不做 workflow 调度。

验收标准：

1. 高风险 profile/constraint handler 可返回 needs_user_confirmation。
2. review handler 不直接推进任务。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-23，只做 claims/profile/review/constraint handler 合同。所有 handler 返回 DomainToolOutcome，高风险返回 needs_user_confirmation。不要持久化、不要接 UI/workflow，不开启下一任务。补 tests。
```

### ONS-24 Clarification Tool 合同

本轮目标：让智能体在关键信息不足时通过结构化工具请求最小用户确认。

层级归属：Core / tool handler contract。

必读文件：

- ONS-20 tool schema
- ONS-21 dispatcher
- ONS-14 permission policy

必须完成：

1. 新增 `ProfileClarificationRequest`。
2. 支持 question、options、freeform_allowed、reason、blocking。
3. handler 返回 waiting user outcome。
4. 添加 tests。

本轮不要做：

1. 不接 GUI 弹窗。
2. 不做复杂表单。
3. 不允许智能体把普通偏好变成大型问卷。

验收标准：

1. 问题小而具体。
2. blocking 与 non-blocking 可区分。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-24，只做 request_profile_clarification 合同。问题必须小而具体，返回 waiting user outcome。不要接 GUI，不做大型表单，不开启下一任务。补 tests。
```

### ONS-25 Mock 智能体工具调用可靠性矩阵

本轮目标：在不消耗真实 provider 的情况下验证 writer/reviewer/recovery/architect 是否能用领域工具完成目标。

层级归属：Core / regression。

必读文件：

- `packages/novel_agent_core/test/draft_generation_tool_call_reliability_test.dart`
- ONS-20 到 ONS-24 工具合同

必须完成：

1. 新增 mock toolcall reliability tests。
2. 覆盖 writer 提交章节。
3. 覆盖 reviewer 提交 semantic review。
4. 覆盖 recovery 修复缺正文。
5. 覆盖 architect 提交 profile proposal 和 clarification。
6. 验证只用 `write_project_file` 的旧组合仍被标为结构不可靠。

本轮不要做：

1. 不跑真实 API。
2. 不写 adapters。
3. 不为了测试写题材分支。

验收标准：

1. mock tests 能证明领域工具比低层文件组合更稳定。
2. 不依赖具体 provider。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-25，只做 mock 智能体工具调用可靠性矩阵。覆盖 writer/reviewer/recovery/architect，不跑真实 API，不写 adapters，不开启下一任务。必须证明 write_project_file-only 旧组合结构上不可靠，补 tests。
```

### ONS-26 结构化事实源 Repository Ports

本轮目标：定义 profiles、claims、ledger、reviews、bindings 的 repository ports。

层级归属：Core / repository ports。

必读文件：

- ONS-04 到 ONS-09 合同
- `packages/novel_agent_core/lib/src/project/`

必须完成：

1. 新增 `NarrativeProfileRepository` port。
2. 新增 `NarrativeClaimRepository` port。
3. 新增 `NarrativeLedgerRepository` port。
4. 新增 `SemanticReviewRepository` port。
5. 新增 `ConstraintBindingRepository` port。
6. 添加 fake repository tests。

本轮不要做：

1. 不实现文件系统。
2. 不决定 SQLite schema。
3. 不接 app。

验收标准：

1. ports 只依赖 core 模型。
2. 支持 append/read/list。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-26，只做结构化事实源 repository ports。不要实现文件系统/SQLite，不接 app，不开启下一任务。ports 只依赖 core 模型，补 fake repository tests。
```

### ONS-27 本地 JSON / JSONL Repository 实现

本轮目标：在 adapters 实现 `.novel_agent/continuity` 等结构化事实源的本地文件存储。

层级归属：Adapters / persistence。

必读文件：

- ONS-26 repository ports
- `packages/novel_agent_adapters/lib/src/storage/`
- `packages/novel_agent_core/lib/src/project/project_workspace_paths.dart`

必须完成：

1. 实现 profiles JSON repository。
2. 实现 claims JSONL repository。
3. 实现 ledger JSONL repository。
4. 实现 reviews JSON repository。
5. 实现 constraint bindings JSON repository。
6. 路径使用 `.novel_agent/`。
7. 添加 adapter tests。

本轮不要做：

1. 不做 GUI。
2. 不做 Markdown 投影。
3. 不改变项目主存储策略。

验收标准：

1. 文件路径不散落到根目录。
2. unknown payload round-trip。
3. adapter tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-27，只做 adapters 本地 JSON/JSONL repository 实现。路径必须在 `.novel_agent/`，未知 payload 必须保留。不要做 GUI/MD 投影/主存储策略变更，不开启下一任务。补 adapter tests。
```

### ONS-28 Markdown 投影与 Proposal 回流桥

本轮目标：把结构化事实源投影为用户和智能体可读 Markdown，并建立从编辑后的投影回到结构化 proposal 的桥。

层级归属：Core + Adapters / projection。

必读文件：

- ONS-27 repositories
- `packages/novel_agent_core/lib/src/workflow/*markdown*`
- `docs/continuity-execution-contract-architecture-evolution-2026-06-04.md` 15.6

必须完成：

1. core 新增投影模型和 renderer。
2. adapters 新增投影写入服务。
3. 输出 `continuity/叙事状态规则.md`、`continuity/最近状态变化.md`、`constraints/项目约束摘要.md`、`reviews/语义复核摘要.md`。
4. 新增从编辑后的 Markdown 生成 proposal draft 的 bridge contract。
5. 回流结果必须进入 proposal / claim draft，而不是直接覆盖结构化事实源。
6. 明确 MD 是投影，不是唯一事实源。
7. 添加 tests。

本轮不要做：

1. 不做 GUI 编辑器。
2. 不把 MD 当运行时真相。
3. 不允许 Markdown 编辑直接跳过 proposal 流程覆盖 JSON/JSONL。

验收标准：

1. 投影可读、稳定、可重复生成。
2. 删除投影不影响 JSON/JSONL 事实源。
3. 编辑后的 Markdown 可以生成结构化 proposal draft。
4. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-28，只做 Markdown 投影与 Proposal 回流桥。MD 仍然只是投影，编辑后的内容只能回到 proposal draft，不能直接覆盖运行时事实源。不要做 GUI 编辑器，不让 Markdown 变真相，不开启下一任务。补 renderer/bridge tests。
```

### ONS-29 Adapter Domain Tool Executors

本轮目标：实现领域工具在本地项目中的实际执行，包括写正文、写 submission、写 claims/review/proposals。

层级归属：Adapters / tools。

必读文件：

- ONS-21 到 ONS-24 handler contracts
- ONS-27 repositories
- ONS-28 projection
- `packages/novel_agent_adapters/lib/src/tools/project_file_write_tool_executor.dart`

必须完成：

1. 实现 `submit_chapter_delivery` adapter executor。
2. 实现 claims/profile/review/constraint/clarification executor。
3. `submit_chapter_delivery` 内部可调用底层文件写入，但对外返回领域 outcome。
4. 写入正文和结构化 submission 保持原子性策略或可恢复策略。
5. 添加 adapter tests。

本轮不要做：

1. 不接 provider prompt。
2. 不接 GUI。
3. 不让 executor 吸收语义判断。

验收标准：

1. 正文路径、submission、evidence 都能落盘。
2. 空 content 不被静默修成成功。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-29，只做 Adapter Domain Tool Executors。submit_chapter_delivery 可内部复用文件写入，但对外必须返回领域 outcome。不要接 prompt/GUI，不做语义判断，不开启下一任务。补 adapter tests，覆盖空 content。
```

### ONS-30 Project Tool Dispatcher 接线

本轮目标：把新领域工具接入现有项目工具 dispatcher，并保留底层文件工具。

层级归属：Adapters / runtime bridge。

必读文件：

- ONS-29 executors
- `packages/novel_agent_adapters/lib/src/tools/project_tool_dispatcher.dart`
- `packages/novel_agent_core/lib/src/runtime/tool_execution_service.dart`

必须完成：

1. 注册六个领域工具。
2. 保留 `write_project_file`。
3. 工具能力声明区分 low-level 和 domain-level。
4. tool result transcript 与 evidence 分清。
5. 添加 integration tests。

本轮不要做：

1. 不改 prompt builder。
2. 不移除旧文件工具。
3. 不跑真实 provider。

验收标准：

1. dispatcher 能路由领域工具。
2. 低层工具和领域工具不混淆 outcome。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-30，只做 Project Tool Dispatcher 接线。注册六个领域工具，保留 write_project_file，分清 low-level/domain-level 和 transcript/evidence。不要改 prompt，不跑真实 provider，不开启下一任务。补 integration tests。
```

### ONS-31 Context Activation Adapter Bridge

本轮目标：把项目资产、continuity、claims、profile、constraints 转成 context activation 候选，并生成 explain report。

层级归属：Adapters / context bridge。

必读文件：

- ONS-18 planner
- ONS-27 repositories
- `packages/novel_agent_core/lib/src/runtime/project_context_file_selection_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_continuity_runtime_payload_service.dart`

必须完成：

1. 实现 `ProjectContextActivationService`。
2. 读取项目资产和结构化事实源，产出 activation candidates。
3. 调用 core planner。
4. 输出 activation report。
5. 添加 tests。

本轮不要做：

1. 不接 prompt builder。
2. 不做复杂语义检索。
3. 不做 GUI。

验收标准：

1. 能解释本轮注入了哪些 claims/profile/constraints。
2. 预算裁剪可见。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-31，只做 Context Activation Adapter Bridge。读取项目资产和结构化事实源，输出 activation report。不要接 prompt，不做复杂语义检索/GUI，不开启下一任务。补 tests。
```

### ONS-32 Prompt Builder 引导领域工具

本轮目标：让写作、审稿、修复、profile architect prompt 明确使用领域工具，而不是依赖散文或低层文件工具组合。

层级归属：Workflow / prompt contract。

必读文件：

- ONS-20 tool schema
- ONS-30 dispatcher
- ONS-31 context activation
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_prompt_builder_service.dart`
- `packages/novel_agent_core/lib/src/workflow/draft_narrative_missing_output_repair_prompt_builder_service.dart`

必须完成：

1. 更新 writer prompt，要求 `submit_chapter_delivery`。
2. 更新 reviewer prompt，要求 `submit_semantic_review`。
3. 更新 recovery prompt，目标单一。
4. 新增 profile architect prompt contract。
5. 明确示例不是范本，未知变化保留。
6. 添加 prompt contract tests。

本轮不要做：

1. 不跑真实 API。
2. 不把题材写进 prompt builder 分支。
3. 不接 GUI。

验收标准：

1. prompt 中没有把快穿/死亡回归当固定类型。
2. 写作任务明确章节交付工具。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-32，只做 prompt builder 引导领域工具。writer 用 submit_chapter_delivery，reviewer 用 submit_semantic_review，recovery 目标单一，示例不是范本。不要跑真实 API，不写题材分支，不开启下一任务。补 prompt contract tests。
```

### ONS-33 Workflow Runtime 薄接线

本轮目标：把 `ProjectWorkflowRuntimeService` 接到领域工具和 activation report，但不继续扩张为业务中心。

层级归属：Adapters / workflow runtime bridge。

必读文件：

- ONS-29 executors
- ONS-31 context activation
- ONS-32 prompt contracts
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`

必须完成：

1. 抽出小服务，避免继续膨胀 runtime 主文件。
2. 章节生成使用 domain tool schema。
3. 记录 activation report。
4. delivery outcome 回写 workflow execution。
5. 添加 focused integration tests。

本轮不要做：

1. 不实现 supervisor 策略。
2. 不做 GUI。
3. 不跑真实探针。

验收标准：

1. runtime 主文件没有继续大幅膨胀。
2. 旧低层写文件路径仍兼容，但新章节交付优先领域工具。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-33，只做 Workflow Runtime 薄接线。优先抽小服务，不让 ProjectWorkflowRuntimeService 继续膨胀；章节生成接 domain tool schema 和 activation report。不要做 supervisor/GUI/真实探针，不开启下一任务。补 focused integration tests。
```

### ONS-34 Reviewer 与 Recovery Workflow 接线

本轮目标：把 semantic review 和 recovery 变成正式 workflow 子任务，不抢写作交付工具。

层级归属：Workflow / runtime。

必读文件：

- ONS-08 semantic review
- ONS-19 delivery state machine
- ONS-32 prompt contracts
- `packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_review_task_factory_service.dart`
- `packages/novel_agent_adapters/lib/src/workflow/project_draft_postprocess_service.dart`

必须完成：

1. 正文存在后才触发 semantic review。
2. 缺正文优先 recovery，不进入内容质量 review。
3. recovery 只修当前失败目标。
4. review finding 写入 repository。
5. 添加 tests。

本轮不要做：

1. 不让 reviewer 直接推进任务。
2. 不读正文做程序关键词判断。
3. 不跑真实 API。

验收标准：

1. 正文未交付时不启动语义审稿。
2. review/recovery 权责清晰。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-34，只做 Reviewer 与 Recovery Workflow 接线。正文存在后才 review，缺正文优先 recovery；recovery 只修当前失败目标。不要让 reviewer 推进任务，不做关键词判断，不开启下一任务。补 tests。
```

### ONS-35 Supervisor 风险策略消费

本轮目标：让 supervisor 消费 delivery outcome、claim disposition、semantic review finding 和 permission state。

层级归属：Runtime / supervisor。

必读文件：

- ONS-14 permission policy
- ONS-19 delivery state machine
- ONS-08 semantic review
- `packages/novel_agent_core/lib/src/runtime/long_task_supervisor_*`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_supervisor_adapter.dart`

必须完成：

1. 新增 `NarrativeSupervisorRiskPolicyService` 或等价小服务。
2. delivery failure 触发 recover/manual attention。
3. review blocking finding 触发 repair/checkpoint_user/manual_attention。
4. permission waiting 区分真正等待用户。
5. 添加 tests。

本轮不要做：

1. 不让 supervisor 读正文。
2. 不让 supervisor 判断题材语义。
3. 不做 GUI。

验收标准：

1. waiting_user 不再被缺正文滥用。
2. review finding 和技术失败可区分。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-35，只做 Supervisor 风险策略消费。supervisor 只消费 delivery/review/permission/ledger 结构化结果，不读正文、不判断题材语义。不要做 GUI，不开启下一任务。补 tests，重点区分 waiting_user 和缺正文。
```

### ONS-36 旧 Special Mechanic 迁移桥

本轮目标：把旧 special mechanic 状态降级迁移为开放 profile / claims / legacy namespace。

层级归属：Core + Adapters / migration。

必读文件：

- `packages/novel_agent_core/lib/src/workflow/special_mechanic_*`
- `packages/novel_agent_core/lib/src/continuity/mechanic_runtime_*`
- ONS-04 claims
- ONS-05 profile
- ONS-27 repositories

必须完成：

1. 新增 legacy importer。
2. 把旧 special mechanic 状态映射到 `legacy.special_mechanic.*` namespace。
3. 标注 deprecated，不继续扩展旧服务。
4. 更新测试，确保旧数据可读。
5. 文档说明压力探针仍可使用旧标签作为输入。

本轮不要做：

1. 不删除旧文件。
2. 不改真实探针目标。
3. 不把旧特殊机制逻辑复制进新 core。

验收标准：

1. 旧状态能迁移为 claims/profile extension。
2. 新代码不新增题材 hardcode。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-36，只做旧 Special Mechanic 迁移桥。旧状态映射到 legacy.special_mechanic.* namespace，标注 deprecated。不要删除旧文件，不改探针目标，不复制旧逻辑进新 core，不开启下一任务。补兼容 tests。
```

### ONS-37 拆书与解书 Claim 输入桥

本轮目标：让拆书和解书分析能通过同一套 claims/profile proposal/semantic finding 进入事实源。

层级归属：Core + App application / deconstruction and explanation bridge。

必读文件：

- `packages/novel_agent_core/lib/src/deconstruction/`
- `apps/novel_agent_app/lib/features/book_deconstruction/application/`
- ONS-04 claim
- ONS-05 profile proposal
- ONS-08 semantic review
- ONS-27 repositories

必须完成：

1. 拆书 foundation build 输出 claims。
2. 拆书 analyzer 可提出 profile proposal。
3. 解书/解释分析预留 source：explainer_interpreted。
4. explainer / analyzer 输出默认可进入 `analysis namespace`，与写作主 ledger 隔离。
5. 通过用户确认或策略提升，把 `analysis namespace` 中的事实提升为续写事实。
6. 派生续写项目继承 accepted/proposed 状态。
7. 添加 tests。

本轮不要做：

1. 不重做拆书 UI。
2. 不让拆书拥有独立 runtime。
3. 不把解书写死为写作子流程。

验收标准：

1. 拆书、解书、写作使用同一 claim 模型。
2. source 区分清楚。
3. `analysis namespace` 与写作主 ledger 的提升路径清楚。
4. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-37，只做拆书与解书 Claim 输入桥。拆书/解书输出 claims/profile proposals/semantic findings，source 区分清楚，`analysis namespace` 与提升路径必须明确。不要重做 UI，不造拆书独立 runtime，不开启下一任务。补 tests。
```

### ONS-38 约束桥迁移到 Binding

本轮目标：让现有字数、表达限制、去 AI 运行链能读取 constraint binding，同时保持旧用户配置可用。

层级归属：Workflow / execution constraints。

必读文件：

- ONS-09 constraint binding
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge*`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_*`
- `packages/novel_agent_core/lib/src/workflow/expression_constraint_*`
- `packages/novel_agent_adapters/lib/src/workflow/project_draft_execution_constraint_runtime_service.dart`

必须完成：

1. 新增 binding 到现有约束运行时的 adapter。
2. 旧目标字数仍可直接配置。
3. 表达限制仍支持用户新增、项目级固化。
4. 运行时报告绑定来源。
5. 添加 tests 覆盖普通项目与长任务。

本轮不要做：

1. 不废弃现有 UI 设置。
2. 不把约束做成长任务私有。
3. 不引入复杂权限 UI。

验收标准：

1. 普通任务和长任务共用 binding 桥。
2. 字数硬限制、环绕策略、审核容忍语义保留。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-38，只做约束桥迁移到 Constraint Binding。旧目标字数和表达限制设置必须继续可用，普通任务和长任务共享。不要废弃 UI 设置，不做长任务私有，不开启下一任务。补普通项目与长任务 tests。
```

### ONS-39 普通项目分散式生成接线

本轮目标：保证普通小说项目在用户分散生成、查看、调整后继续生成时，也使用章节交付和约束合同。

层级归属：Workflow / general project。

必读文件：

- ONS-33 runtime bridge
- ONS-38 constraint bridge
- `packages/novel_agent_core/lib/src/workflow/chapter_atomic_*`
- `apps/novel_agent_app/lib/features/workbench/`

必须完成：

1. 普通章节生成使用 `submit_chapter_delivery`。
2. 分散式单章生成记录 delivery outcome。
3. 用户中途修改配置后，下一章读取最新 binding/profile。
4. 添加 tests。

本轮不要做：

1. 不改大 UI。
2. 不只修长任务。
3. 不跑真实 API。

验收标准：

1. 普通项目不绕过表达限制、字数、章节交付 gate。
2. 分散式生成不会丢 context activation report。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-39，只做普通项目分散式生成接线。普通章节生成必须使用 submit_chapter_delivery、约束 binding、activation report。不要改大 UI，不只修长任务，不跑真实 API，不开启下一任务。补 tests。
```

### ONS-40 长任务章节队列接线

本轮目标：让普通长任务章节队列使用同一套 domain delivery、claims、constraints、supervisor 风险策略。

层级归属：Workflow / long task。

必读文件：

- ONS-33 runtime bridge
- ONS-35 supervisor policy
- ONS-38 constraint bridge
- `packages/novel_agent_core/lib/src/workflow/long_task_*`
- `packages/novel_agent_adapters/lib/src/workflow/project_workflow_supervisor_adapter.dart`

必须完成：

1. 长任务每章 delivery outcome 入运行记录。
2. 自动恢复读取 delivery state machine。
3. 长任务上下文注入 activation report。
4. 不预先固定 1..200 章所有任务。
5. 添加 tests。

本轮不要做：

1. 不跑复杂题材真实探针。
2. 不固定章节段落长度。
3. 不写题材逻辑。

验收标准：

1. 长任务按内容推进和调度，不靠探针预造固定任务。
2. delivery failure 能进入恢复。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-40，只做长任务章节队列接线。每章使用 domain delivery/claims/constraints/supervisor policy，不预先固定 1..200 章任务，不写题材逻辑，不跑复杂真实探针，不开启下一任务。补 tests。
```

### ONS-41 Mock 回归总包

本轮目标：汇总普通项目、长任务、拆书、解书、review、recovery 的 mock contract tests，作为真实探针前置门槛。

层级归属：Regression / mock。

必读文件：

- ONS-25 tests
- ONS-39 tests
- ONS-40 tests
- `packages/novel_agent_core/test/`
- `packages/novel_agent_adapters/test/`

必须完成：

1. 建立一个稳定的 mock regression suite。
2. 覆盖 writer success、writer no tool、empty content、title-only、submission invalid、review blocking、permission waiting、recovery success。
3. 加入 README 或测试说明。
4. 运行 core/adapters relevant tests。

本轮不要做：

1. 不跑真实 provider。
2. 不写新业务逻辑。
3. 不改 GUI。

验收标准：

1. 真实探针前可以先跑 mock suite。
2. 失败类型可读。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-41，只做 Mock 回归总包。覆盖 writer/reviewer/recovery/permission/delivery 关键失败形态，不跑真实 provider，不写新业务逻辑，不开启下一任务。运行相关 core/adapters tests。
```

### ONS-42 真实 Probe 框架同源化

本轮目标：整理真实 probe，使其只消费 production 合同，不私造恢复和评分逻辑。

层级归属：Probe / regression。

必读文件：

- `agent.md` 10.1 探针规则
- `apps/novel_agent_app/tool/probe_support.dart`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- `apps/novel_agent_app/tool/real_special_mechanics_parallel_long_task_probe.dart`
- ONS-41 mock suite

必须完成：

1. probe 使用本地配置 `local/probe_api.txt` 或环境变量。
2. 真实 probe 必须显式 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
3. 报告区分技术失败、等待用户、预算失败、内容质量失败。
4. 不在 probe 内实现 production 没有的 retry / repair。
5. 添加 probe support tests。

本轮不要做：

1. 不跑真实 API。
2. 不新增一次性 probe 脚本。
3. 不硬编码模型和 key。

验收标准：

1. probe 共享 production delivery/review/supervisor 合同。
2. 无密钥泄露风险。
3. tests 通过。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-42，只做真实 Probe 框架同源化。probe 只能消费 production 合同，不私造 retry/repair；必须显式开闸和本地配置。不要跑真实 API，不新增一次性脚本，不开启下一任务。补 probe support tests。
```

### ONS-43 短真实验证：普通项目与普通长任务

本轮目标：在真实 provider 下先验证普通项目和普通长任务，不碰复杂压力题材。

当前状态：已完成（2026-06-04）；历史阻塞与收口记录见 `docs/ons-43-real-validation-blocker-2026-06-04.md`。

层级归属：Probe / real provider validation。

必读文件：

- ONS-42 probe 框架
- `local/probe_api.txt`
- `apps/novel_agent_app/tool/real_general_novel_probe.dart`
- 长任务普通 probe 入口

必须完成：

1. 显式确认真实 probe 开闸。
2. 跑普通小说项目 10 章左右，模拟分散式用户使用。
3. 跑普通长任务短链。
4. 验证 delivery、字数、表达限制、去 AI、activation report、review/recovery。
5. 保留产物和报告。

本轮不要做：

1. 不跑快穿/死亡回归压力探针。
2. 不改生产代码，除非发现明确阻塞且先记录。
3. 不删除产物。

验收标准：

1. 普通项目和普通长任务技术链通过。
2. 报告能读出约束是否生效。
3. 失败时生成下一轮修复文档，不盲目继续大跑。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-43，只做短真实验证：普通项目和普通长任务。必须显式开闸真实 probe，保留产物和报告。不要跑快穿/死亡回归压力探针，不删除产物，不开启下一任务。若失败，先记录阻塞事实，不盲目大跑。
```

### ONS-44 压力真实验证与外层对接收口

本轮目标：在普通链通过后，做复杂输入压力验证，并完成 GUI / CLI 最后消费。

层级归属：Probe + GUI + CLI + Documentation。

必读文件：

- ONS-43 报告
- ONS-42 probe 框架
- `apps/novel_agent_app/lib/features/task_center/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_cli/`

必须完成：

1. 只在 ONS-43 通过后运行压力探针。
2. 压力输入可以包含快穿、死亡回归、多世界等，但只作为用户输入，不作为 core 类型。
3. 不人为固定每段章节数。
4. GUI 展示 knowledge/ledger/projection、权限确认、Run Center 报告。
5. CLI 输出 delivery/review/activation/ledger 摘要。
6. 更新最终文档和完成记录。

本轮不要做：

1. 不在 core 新增题材分支。
2. 不用 GUI/CLI 兜底底层缺口。
3. 不删除真实产物。

验收标准：

1. 压力探针报告区分技术失败与内容质量问题。
2. GUI / CLI 只消费稳定合同。
3. 文档记录最终通过情况和剩余风险。

直接可用提示词：

```text
根据 `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 开启 ONS-44。只有 ONS-43 已通过时，才运行复杂输入压力验证；快穿/死亡回归/多世界只能作为用户输入，不写入 core 类型。同步完成 GUI/CLI 最后消费和最终文档。不要用 GUI/CLI 兜底底层缺口，不删除真实产物，不开启下一任务。
```

---

## 9. 总启动提示词

```text
根据目前的进度和文档：`docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md` 继续下一步。每次只确认完成一个具体任务；如果上个会话末尾卡在具体任务的一半未完成或者出现关联性错误，就先修好这些，不开启下一轮任务。如果已经确认可以开启下一轮任务，就直接开始当前 session。必须读取对应 session 的目标、层级、必读文件、必须完成、本轮不要做、验收标准和直接提示词。实现时遵守解耦合、单一职责、core/adapters/app/CLI 分层、避免单文件过重、focused test/contract test、probe 同源合同、真实 key 不入仓库等约束。完成后更新本文档的完成记录占位，只记录当前 session 的结果，不顺手推进下一 session。
```

---

## 10. 完成记录占位

- ONS-01：已完成（2026-06-04，本轮新增 `docs/open-narrative-state-implementation-audit-2026-06-04.md`，完成现状审计、legacy 降级图与后续阶段边界冻结）
- ONS-02：已完成（2026-06-04，本轮新增 `src/continuity/narrative_state/`、`src/continuity/context_activation/`、`src/tools/domain/` 轻量骨架与顶层导出，并补 `open_narrative_state_namespace_smoke_test.dart`，`dart analyze` 通过）
- ONS-03：已完成（2026-06-04，本轮新增 `NarrativeSourceRef`、`NarrativeRef`、`NarrativeTextSpanRef`、`NarrativeEvidenceRef` 与缺失锚点 `runtime/tool_round_evidence.dart`，补 `narrative_reference_contracts_test.dart`，未知 source/ref 类型 round-trip 与 core analyze 通过）
- ONS-04：已完成（2026-06-04，本轮新增 `NarrativeStateClaim`、列表 codec 与基础校验码，补 `narrative_state_claim_contracts_test.dart`，未知 namespace、嵌套 payload、空 claims round-trip 与 core analyze 通过）
- ONS-05：已完成（2026-06-04，本轮新增 `NarrativeProfile`、`NarrativeProfilePatch`、`NarrativeProfileProposal` 及生命周期/校验/codec 合同，补 `narrative_profile_contracts_test.dart`，unknown profile extension round-trip、提案状态边界与 core analyze 通过）
- ONS-06：已完成（2026-06-04，本轮新增 `NarrativeStateLedger`、`NarrativeLedgerEntry`、`NarrativeLedgerEvent`、`NarrativeClaimDisposition` 及 codec/校验合同，补 `narrative_state_ledger_contracts_test.dart`，不同 source 并存、supersedes/replacement 引用与 core analyze 通过）
- ONS-07：已完成（2026-06-04，本轮新增 `ChapterNarrativeSubmission`、`NarrativeSegment`、`NarrativeTransition` 及 codec/校验合同，补 `chapter_narrative_submission_contracts_test.dart`，多 transition、空 claims、未知 transition kind 与 core analyze 通过）
- ONS-08：已完成（2026-06-04，本轮新增 `NarrativeSemanticReview`、`SemanticReviewFinding`、严重级别/建议 disposition/codec/校验合同，补 `narrative_semantic_review_contracts_test.dart`，覆盖 reviewer 建议不直接改 ledger、evidence 缺失显式申明、未知 source/disposition round-trip，并已通过相关 core tests 与 `dart analyze`）
- ONS-09：已完成（2026-06-04，本轮新增 `NarrativeConstraintBindingProposal`、`ConstraintBindingScope`、`ConstraintBindingPolicy` 及 applies_to 常量/codec/校验合同，补 `narrative_constraint_binding_contracts_test.dart`，覆盖目标字数、表达限制内置/项目级区分、未知约束类型 round-trip 与权限位冲突校验，并已通过相关 core tests 与 `dart analyze`）
- ONS-10：已完成（2026-06-04，本轮新增 `ContextActivationPlan`、`ContextActivationItem`、`ContextActivationReport` 及 reason/codec/校验合同，补 `context_activation_contracts_test.dart`，覆盖 activation reason、预算、selected/omitted/truncated、开放 reason code 与基础状态冲突校验，并已通过相关 core tests 与 `dart analyze`）
- ONS-11：已完成（2026-06-04，本轮新增 `DomainToolRequest`、`DomainToolOutcome`、`DomainToolPermissionDecision`、`DomainToolError` 及状态/权限/codec/校验合同，补 `domain_tool_outcome_contracts_test.dart`，覆盖 accepted/proposed/rejected/needs_user_confirmation/invalid_payload/execution_failed 区分与 `ToolRoundEvidence` 审计关联，并已通过相关 core tests 与 `dart analyze`）
- ONS-12：已完成（2026-06-04，本轮新增开放 JSON codec/结构校验共享服务，补 `open_json_contract_services_test.dart`，并将 ONS-04 到 ONS-11 的重复 `schema_version`/required/confidence/基础结构校验收口到共享服务；同时补齐 claim 顶层未知字段 round-trip，相关 core tests 与 `dart analyze` 已通过）
- ONS-13：已完成（2026-06-04，本轮新增 `NarrativeClaimValidator`、`NarrativeProfileProposalValidator`、`ChapterNarrativeSubmissionValidator`，补 `narrative_contract_validators_test.dart`，覆盖 claim 引用结构、profile proposal 最小 patch 内容、无 segment/多 segment/未知 transition kind、segment 顺序与 transition 引用 segment 校验，并已通过相关 core tests 与 `dart analyze`）
- ONS-14：已完成（2026-06-04，本轮新增 `NarrativePermissionPolicyService`，统一处理自动接受、自动提案、用户确认与禁止自动执行，并可直接投影为 `DomainToolOutcome`；补 `narrative_permission_policy_service_test.dart`，覆盖 profile/constraint 高风险确认、本章局部 low-risk claim 自动接受、semantic review 提案化与脚本型 payload 禁止自动执行，相关 core tests 与 `dart analyze` 已通过）
- ONS-15：已完成（2026-06-04，本轮新增 `NarrativeProfileProposalService`、`NarrativeProfileInterpreterService`、`NarrativeProfileAuditEvent` 与 `NarrativeProfileInterpretation`，补齐 propose/accept/reject/supersede/deprecate 的纯 core 生命周期、冲突 proposal supersede、accepted profile 物化与项目级解释输出；补 `narrative_profile_services_test.dart`，覆盖 proposal 不直达 active、清晰 supersede 引用、风险/最小字段/unknown payload 解释，并已通过相关 core tests 与 `dart analyze`）
- ONS-16：已完成（2026-06-04，本轮新增 `NarrativeStateLedgerService`，补齐 submit/accept/question/reject/supersede 的纯 core ledger reducer，并新增 `NarrativeStateLedgerReviewRecommendation` 让 semantic review 只输出建议而不直接改写 disposition；补 `narrative_state_ledger_service_test.dart`，覆盖多 source claim 并存、显式状态流转、replacement/supersede 引用与 review recommendation 不直接 mutate ledger，并已通过相关 core tests 与 `dart analyze`）
- ONS-17：已完成（2026-06-04，本轮新增 `NarrativeEvidenceResolverService`、`NarrativeEvidenceResolution`、`NarrativeEvidenceTextSnapshot` 与 resolution status 常量，只做内存文本快照上的 refs/span 结构级解析与粗校验，支持 `resolved` / `missing` / `unresolved` / `out_of_range` / `ambiguous`，不读取文件系统、不判断语义；补 `narrative_evidence_resolver_service_test.dart`，覆盖合法 span、缺正文 unresolved、缺 text_span missing、多候选 ambiguous 与越界 out_of_range，并已通过相关 core tests 与 `dart analyze`）
- ONS-18：已完成（2026-06-04，本轮新增 `ContextActivationPlannerService`，基于现有 `ContextActivationPlan/Item/Report` 做纯 core 的候选排序与预算规划，支持 `weight`、`pinned`、`required`，并输出可解释的 `selected/omitted/truncated` 与对应原因；补 `context_activation_planner_service_test.dart`，覆盖 required/pinned 优先级、预算耗尽后的 omitted/truncated 以及 required 项在零预算下的明确处理策略，并已通过相关 core tests 与 `dart analyze`）
- ONS-19：已完成（2026-06-04，本轮新增 `ChapterDeliveryStateMachine`、`ChapterDeliveryStateRequest`、`ChapterDeliveryStateResult` 与状态常量，统一把章节正文、路径、submission 与现有 chapter gate disposition 映射到 `delivered` / `delivered_needs_repair` / `missing_output_recoverable` / `invalid_output_rewrite_required` / `path_mismatch_recoverable` / `waiting_user_choice` / `manual_attention_required` / `hard_failure`；补 `chapter_delivery_state_machine_test.dart`，覆盖空正文、title-only、路径漂移、submission 缺失/无效、waiting_user_choice、manual_attention_required 与 hard failure，并已通过相关 core tests 与 `dart analyze`）
- ONS-20：已完成（2026-06-04，本轮新增 `NarrativeDomainToolCatalog`、六个领域工具名/定义/schema 与结构化 parse issue/result 合同，统一输出 OpenAI function schema，并把 `submit_chapter_delivery`、`submit_narrative_state_claims`、`propose_narrative_profile_update`、`submit_semantic_review`、`propose_constraint_binding`、`request_profile_clarification` 的参数解析收口到纯 core parser；保留未知顶层/嵌套 payload，`submit_chapter_delivery` 对无效 submission 仅记录 `submission_validation_errors` 供后续状态机处理，补 `narrative_domain_tool_catalog_test.dart`，并已通过相关 focused tests 与 `dart analyze`）
- ONS-21：已完成（2026-06-04，本轮新增 `NarrativeDomainToolDispatcher`、`NarrativeDomainToolHandler`、`NarrativeDomainToolCapability` 与 `NarrativeDomainToolDispatchService` 纯 core 合同，建立领域工具 capability 声明、handler 接口、基于现有 `NarrativePermissionPolicyService` 的分发入口与 accepted / needs_user_confirmation / invalid_payload / execution_failed 结构化结果收口；不接本地文件系统、不接 `ProjectToolDispatcher`、不接 LLM，补 `narrative_domain_tool_dispatch_service_test.dart` mock tests，并已通过相关 focused tests 与 `dart analyze`）
- ONS-22：已完成（2026-06-04，本轮新增 `SubmitChapterDeliveryHandler` 与 `SubmitChapterDeliveryResult` 纯 core 合同，把 `submit_chapter_delivery` 的 `chapter_path`、`chapter_content`、`submission`、`constraint_coverage` 接入 `ChapterDeliveryStateMachine`，统一输出 `delivery_state`、`chapter_body_state`、`sidecar_state`、结构化 evidence 与状态机结果；显式区分空正文、title-only、submission invalid，且在正文未成功交付时将 sidecar 标记为 `blocked_by_chapter_failure`；同时补齐 `NarrativePermissionPolicyService` 对 `submit_chapter_delivery` 的权限策略，避免 dispatcher 将正常章节交付误降为 `proposed`，新增 `submit_chapter_delivery_handler_test.dart` 并通过相关 focused tests 与 `dart analyze`）
- ONS-23：已完成（2026-06-04，本轮新增 `SubmitNarrativeStateClaimsHandler`、`ProposeNarrativeProfileUpdateHandler`、`SubmitSemanticReviewHandler`、`ProposeConstraintBindingHandler` 四个纯 core handler 合同，统一把 claims / profile proposal / semantic review / constraint binding 的结构化输入收口为 `DomainToolOutcome`；其中高风险 profile/constraint 可返回 `needs_user_confirmation`，semantic review 明确只产出结构化建议而不推进 workflow，claims handler 保留开放 payload 与 evidence 汇总；补 `narrative_domain_tool_handler_contracts_test.dart`，并已通过相关 focused tests、dispatcher 回归与 `dart analyze`）
- ONS-24：已完成（2026-06-04，本轮新增 `ProfileClarificationRequest`、`ProfileClarificationOption`、相关校验码与 `RequestProfileClarificationHandler` 纯 core 合同，支持 `question`、`options`、`freeform_allowed`、`reason`、`blocking`，并统一返回 `needs_user_confirmation` 的 waiting-user 结果；显式区分 blocking / non-blocking，限制澄清问题保持小而具体，超大选项集会按 invalid payload 拒绝；同时补齐 `NarrativePermissionPolicyService` 对 `request_profile_clarification` 的最小衔接，使 dispatcher 可放行到 handler 再收口等待用户结果，新增 `request_profile_clarification_handler_test.dart` 并通过相关 focused tests、dispatcher 回归与 `dart analyze`）
- ONS-25：已完成（2026-06-04，本轮在 `draft_generation_tool_call_reliability_test.dart` 新增 mock 领域工具可靠性矩阵，覆盖 writer 使用 `submit_chapter_delivery`、reviewer 使用 `submit_semantic_review`、recovery 区分缺正文与修复后交付、architect 组合 `propose_narrative_profile_update` 与 `request_profile_clarification`；同时保留并对照 `write_project_file` only / 正文与 sidecar 分裂写入 / 重复只读空转等旧链路结构性不可靠场景，证明领域工具 parse + dispatch 闭环在 mock 下更稳定，不依赖具体 provider、未接入 adapters，并已通过相关 regression tests 与 `dart analyze`）
- ONS-26：已完成（2026-06-04，本轮新增 `NarrativeProfileRepository`、`NarrativeClaimRepository`、`NarrativeLedgerRepository`、`SemanticReviewRepository`、`ConstraintBindingRepository` 五个纯 core repository ports，统一提供结构化事实源的 append/read/list 合同并只依赖 core models；补 `narrative_repository_ports_test.dart` 内存 fake repository tests，覆盖 profiles / claims / ledger / reviews / bindings 的最小端口语义，并已通过相关 focused tests 与 `dart analyze`）
- ONS-27：已完成（2026-06-04，本轮在 adapters 新增 `OpenNarrativeStatePathService`，把 profiles / claims / ledgers / reviews / bindings 全部收口到 `.novel_agent/continuity/`；实现 `LocalNarrativeProfileRepository`、`LocalNarrativeClaimRepository`、`LocalNarrativeLedgerRepository`、`LocalSemanticReviewRepository`、`LocalConstraintBindingRepository`，其中 profiles / reviews / bindings 使用 JSON，claims 使用追加式 JSONL，ledger 使用 `entries.jsonl + events.jsonl`，并补 index/JSONL 支撑避免依赖隐藏目录扫描；新增 `local_narrative_state_repositories_test.dart` 覆盖隐藏路径落盘与 unknown payload round-trip，并已通过相关 adapter tests 与 `dart analyze`）
- ONS-28：已完成（2026-06-04，本轮在 core 新增 `NarrativeStateProjectionSource`、`NarrativeStateProjectionDocument`、`NarrativeStateProjectionDraftBundle`、`NarrativeStateMarkdownProjectionService` 与 `NarrativeStateMarkdownBridgeService`，把 profiles / claims / ledgers / bindings / semantic reviews 投影为稳定 Markdown，并在文末保留结构化 draft code block 作为唯一回流入口；在 adapters 新增 `OpenNarrativeStateProjectionWriterService`，输出 `continuity/叙事状态规则.md`、`continuity/最近状态变化.md`、`constraints/项目约束摘要.md`、`reviews/语义复核摘要.md`。回流桥只生成 profile proposal draft / claim draft / binding draft / semantic review draft，不直接覆盖 JSON/JSONL 事实源；补 core renderer/bridge tests 与 adapter writer tests，并已通过相关 focused tests 与 `dart analyze`）
- ONS-29：已完成（2026-06-04，本轮新增 `ProjectNarrativeDomainToolExecutor`，在 adapters 内部复用 ONS-21 到 ONS-24 的 core handler/dispatch 合同，实际落地 `submit_chapter_delivery`、claims、profile proposal、semantic review、constraint binding、profile clarification` 的本地执行；其中章节交付会写正文与隐藏 submission/delivery 记录，claims/review/binding 会写入 `.novel_agent/continuity/*` 事实源并刷新 ONS-28 Markdown 投影，profile proposal 与 clarification 会写入隐藏待处理记录；补 `project_narrative_domain_tool_executor_test.dart` 覆盖成功交付、空 content 不静默成功、claims/review/proposal/binding/clarification 落盘，并通过 adapter tests 与 `dart analyze` 后收口）
- ONS-30：已完成（2026-06-04，本轮将六个领域工具正式接入 `ProjectToolDispatcher`，通过 `NarrativeDomainToolCatalog.parseRequest` + `ProjectNarrativeDomainToolExecutor` 建立 dispatcher 级路由，同时保留 `write_project_file` 等 low-level 文件工具；dispatcher 结果新增 `tool_layer` / `tool_capability` / `interaction_type=domain_tool` / `domain_outcome` / `tool_result_summary`，显式区分 low-level 与 domain-level，并让 transcript 只消费摘要而不是混入 raw evidence。同步把六个领域工具注册进 `BuiltinToolCatalog` 与 `ToolSchemaBuilderService`，补 `project_tool_dispatcher_domain_tools_test.dart` 与 `tool_schema_builder_service_test.dart`，验证领域工具暴露、dispatcher 路由、等待用户确认结果和 low-level/domain-level 不混淆；相关 adapter/core focused tests 与两侧 `dart analyze` 已通过）
- ONS-31：已完成（2026-06-04，本轮在 adapters 新增 `ProjectContextActivationService`，读取项目文本资产与 `.novel_agent/continuity/` 下的 profiles / claims / constraint bindings，统一映射为 `ContextActivationItem` 候选后交给 core `ContextActivationPlannerService` 做预算规划；桥接层会为 project files、profiles、claims、constraints 生成可追溯 `activation_text`、`selected_text`、`trimmed_chars`、`explanation`，并在 report metadata 中显式输出 `selected_context_sections` / `omitted_context_sections` / `truncated_context_sections` 与 candidate source 统计，让本轮注入与省略内容可解释、预算裁剪可见。同步新增 `project_context_activation_service_test.dart`，覆盖结构化事实源转候选、selected/omitted/truncated explain report 与 visible budget trimming；相关 adapter/core focused tests 与两侧 `dart analyze` 已通过）
- ONS-32：已完成（2026-06-04，本轮把领域工具收口规则集中到 `ProjectPromptContract.domainToolGuidance()`，并接入 `DraftPromptBuilderService`，让 writer 明确以 `submit_chapter_delivery` 作为正式章节交付、reviewer 明确以 `submit_semantic_review` 作为正式语义审稿、recovery 明确本轮目标单一且修复后仍以正式交付收口、profile architect 明确通过 `propose_narrative_profile_update` 提案并在关键歧义时使用 `request_profile_clarification` 停下等待；同时在 long-task transaction / task prompt / postprocess prompt / task factory 的提示合同中补齐对应领域工具契约，并统一强调“示例只用于说明调用形态，不是题材范本”“未知变化和未来扩展字段要保留”。文档要求提到的 `draft_narrative_missing_output_repair_prompt_builder_service.dart` 当前仓库不存在，因此 recovery 收口实际映射到通用 draft prompt 与 `LongTaskPostprocessPromptRenderer`。同步新增 `prompt_builder_domain_tool_contracts_test.dart`，并已通过 `dart test test/prompt_builder_domain_tool_contracts_test.dart`、`dart test test/long_task_runtime_services_test.dart`、`dart test test/draft_generation_use_case_test.dart`、`dart analyze .`）
- ONS-33：已完成（2026-06-04，本轮在 adapters 新增 `ProjectWorkflowRuntimeBridgeService`，把 `ProjectWorkflowRuntimeService` 需要的 workflow runtime 薄接线从主文件中抽出：一是基于 `ProjectContextActivationService` 为任务构建 activation report，并把 report 持久化到 `tracking/chapter_atomic/*.activation_report.json`，同时把 activation summary 作为 `session_context` 接入章节原子 execution 与后续 `GenerateDraftUseCase`；二是按 task type 生成 workflow 侧优先工具序，把 `submit_chapter_delivery` / `submit_semantic_review` / `propose_narrative_profile_update` / `request_profile_clarification` 等领域工具 schema 以 runtime override 的方式前置暴露给模型，同时继续保留 `write_project_file` 等 low-level 兼容路径；三是在模型执行后从 `executed_tools` 中回收 `submit_chapter_delivery` 的 `domain_outcome`，把 `chapter_delivery_state`、`chapter_delivery_path`、结构化 delivery 摘要与补回后的 `output_paths` 回写到 workflow execution，即便本轮 `writtenPaths` 仍为空也能正确识别正式章节交付。同步给 `GenerateDraftUseCase.execute()` 增加可选 `exposedToolIds` 覆盖入口，避免把 runtime 的工具顺序/过滤逻辑硬塞回主服务；新增 `project_workflow_runtime_service_test.dart` focused tests，覆盖 runtime 暴露 chapter delivery schema、保存 activation report、execution 回写 delivery outcome，以及模型仍选择 `write_project_file` 时旧低层写入链路继续兼容；并已通过 `dart test test/project_workflow_runtime_service_test.dart`（`packages/novel_agent_adapters`）、`dart test test/draft_generation_use_case_test.dart`（`packages/novel_agent_core`）、`dart analyze packages/novel_agent_core packages/novel_agent_adapters`）
- ONS-34：已完成（2026-06-04，本轮在 adapters 新增 `ProjectWorkflowReviewRuntimeService`，把 reviewer / recovery 的 workflow 接线从 `ProjectWorkflowRuntimeService` 中抽出：一是在 `chapter_gate_review` 执行前基于 `ChapterDeliveryStateMachine` 预检来源章节正文，只有正文已形成可交付 body 时才进入 semantic review；若正文缺失或交付无效，则跳过本次 review、创建或复用只修当前目标的 recovery `revision` 任务，并把下游依赖从 review 任务改接到 recovery，确保 reviewer 不直接推进 workflow。二是在正常 review 运行后，把 `submit_semantic_review` 的结构化结果持久化到隐藏 `SemanticReviewRepository`，同时镜像到既有 `reviews/*.md` / `reviews/*.json` 路径，维持 chapter gate / report 旧链路兼容，并把 semantic review ids / report paths 回写 execution。同步把该服务接入 `ProjectWorkflowRuntimeService`，新增 `project_workflow_review_runtime_service_test.dart` focused tests，并扩展 `project_workflow_runtime_service_test.dart` 覆盖“正文缺失时不发起 reviewer LLM 请求、直接创建 recovery 并重连依赖”；相关 `dart test test/project_workflow_review_runtime_service_test.dart`、`dart test test/project_workflow_runtime_service_test.dart`、`dart test test/project_long_task_chapter_gate_service_test.dart`（`packages/novel_agent_adapters`）与 `dart analyze packages/novel_agent_adapters packages/novel_agent_core` 已通过。文档中提到的 `project_draft_postprocess_service.dart` 当前仓库不存在，因此本轮实际落点映射到现行 runtime / review 服务。）
- ONS-35：已完成（2026-06-04，本轮在 core 新增 `NarrativeSupervisorRiskPolicyService`，把 supervisor 需要消费的结构化风险统一收口为 `delivery`、`review`、`permission`、`overall` 四组信号：基于 `chapter_delivery_state` 区分 `repair` / `checkpoint_user` / `manual_attention`，基于 `submit_semantic_review` 的 `recommended_disposition`、blocking/high findings 与 questioned claim 计数补出 review 风险，基于领域工具 `needs_user_confirmation` / `permission_decision` 明确“真正等待用户确认”的权限等待场景。随后把该策略接入 `LongTaskCheckpointReviewService`，让 checkpoint review 持久化 `narrative_supervisor_risk`；并更新 `LongTaskCheckpointSeverityService` 与 `LongTaskCheckpointDispositionService` 优先消费这组结构化信号，使 delivery recovery、semantic review blocking finding、permission waiting 和普通技术失败不再混成同一种粗粒度 waiting/failure。同步增强 `LongTaskChapterGateDispositionService`，让 mirrored semantic review report 的 `metadata.recommended_disposition` 也能直接触发 `repair` / `checkpoint_user` / `manual_attention`；并修正 `LongTaskChapterGatePolicyService.statusAfterReviewOutcome()`，只有真实 `blocked_wait_user` 落 `waiting_user`，`manual_attention` 改落 `failed`，避免继续滥用 waiting_user。补充 `narrative_supervisor_risk_policy_service_test.dart`，并扩展 `long_task_checkpoint_review_service_test.dart`、`long_task_checkpoint_disposition_service_test.dart`、`long_task_chapter_gate_disposition_service_test.dart`、`long_task_chapter_gate_policy_service_test.dart`；相关 `dart test test/narrative_supervisor_risk_policy_service_test.dart`、`dart test test/long_task_checkpoint_review_service_test.dart`、`dart test test/long_task_checkpoint_disposition_service_test.dart`、`dart test test/long_task_chapter_gate_disposition_service_test.dart`、`dart test test/long_task_chapter_gate_policy_service_test.dart`（`packages/novel_agent_core`）、`dart test test/project_long_task_chapter_gate_service_test.dart`、`dart test test/project_long_task_checkpoint_action_service_test.dart`（`packages/novel_agent_adapters`）与 `dart analyze packages/novel_agent_core packages/novel_agent_adapters` 已通过。文档中提到的 `project_workflow_supervisor_adapter.dart` 当前仓库不存在，因此本轮实际落点映射到现行 checkpoint review / gate policy / runtime supervisor 合同层。）
- ONS-36：已完成（2026-06-04，本轮没有去恢复任何 `special_mechanic_*` / `mechanic_runtime_*` 旧业务分支，而是把当前仍可读取的 legacy continuity/mechanic 文件正式降级为迁移输入：在 core 新增 `LegacyContinuityMechanicImporterService`，只把 `ProjectContinuityBundle` 与可选 `ProjectContinuityInputProfile` 映射成一个生命周期为 `deprecated` 的 `legacy.special_mechanic.profile`，并补出 `legacy.special_mechanic.bundle`、`coverage`、`input_profile`、`mechanic_profile`、`frame`、`scope_overlay` 等开放 claim namespace，所有导入结果都带 `deprecated_bridge_only` 标记，同时保留“旧标签仍可作为压力探针输入”的说明，但不复制任何题材判断逻辑进新 core。随后在 adapters 新增 `ProjectLegacyContinuityMechanicMigrationService`，从旧 `tracking/continuity/bundle.json` 与 `.novel_agent/settings/project_continuity_input.json` 读取 legacy 状态，幂等写入隐藏 narrative profile / claims repository，并在发生变更时刷新 ONS-28 Markdown 投影；旧 continuity 文件保持只读兼容，不删除、不改路径、不改真实 probe 目标。同步新增 `legacy_continuity_mechanic_importer_service_test.dart` 与 `project_legacy_continuity_mechanic_migration_service_test.dart`，覆盖 legacy bundle 到 `legacy.special_mechanic.*` namespace 的映射、deprecated profile extension、隐藏仓库落盘与重复迁移幂等；相关 `dart test test/legacy_continuity_mechanic_importer_service_test.dart`（`packages/novel_agent_core`）、`dart test test/project_legacy_continuity_mechanic_migration_service_test.dart`（`packages/novel_agent_adapters`）与 `dart analyze packages/novel_agent_core packages/novel_agent_adapters` 已通过。由于 ONS-01 审计已确认当前主树里没有活跃的 `special_mechanic_*` / `mechanic_runtime_*` 文件，本轮“deprecated”落点实际体现为 importer/migration 代码与导入 profile metadata 的 bridge-only 标注，而不是给不存在的旧文件补注解。）
- ONS-37：已完成（2026-06-04，本轮在 core 新增 `BookDeconstructionNarrativeBridgeService`、`BookDeconstructionNarrativePromotionService`、`BookDeconstructionDerivedProjectNarrativeInheritanceService` 与配套 artifact/inheritance 合同，把拆书 foundation build 输出统一桥接为 `NarrativeStateClaim`、`NarrativeProfileProposal`、`NarrativeSemanticReview`：直接抽取结果进入 `analysis.deconstruction.*`，解释性 continuity/profile/review 进入 `analysis.explainer.*`，并预留 `source=explainer_interpreted`；所有 analysis 态 claim/review/proposal 都显式携带 promotion target 与 `user_confirmation_or_policy` 提升路径，promotion 服务会生成保留原 analysis 副本的 promoted artifacts，派生续写项目则通过 `inherited_narrative_artifacts` 继承 accepted/proposed 状态。应用层新增 `BookDeconstructionNarrativePersistenceService`，把当前拆书预览确认流与自动导入拆书流的 bridge 产物写入 `.novel_agent/continuity/claims/*.jsonl`、`profile_proposals/*.json`、`reviews/*.json` 并刷新 Markdown projection，同时 `BookDeconstructionDraftBuildResult` 现已携带 narrative artifacts，但未重做拆书 UI、未引入拆书独立 runtime。新增 `book_deconstruction_narrative_bridge_service_test.dart`，并更新 app 侧 draft builder / controller / import execution focused tests；已通过 `dart analyze packages/novel_agent_core`、`dart test test/book_deconstruction_narrative_bridge_service_test.dart test/legacy_continuity_mechanic_importer_service_test.dart test/book_deconstruction_followup_menu_builder_service_test.dart`、`flutter test test/book_deconstruction_draft_builder_service_test.dart test/book_deconstruction_controller_test.dart test/project_import_execution_service_test.dart`、`flutter test test/workbench_conversation_controller_agent_selection_test.dart test/workbench_workspace_controller_snapshot_test.dart`，以及对本轮变更文件的 `dart analyze`。）
- ONS-38：已完成（2026-06-04，本轮在 core 新增 `WritingExecutionConstraintBridgeService` / `WritingExecutionConstraintBridgeResult`，把 `NarrativeConstraintBindingProposal` 桥接为现有章节字数元数据与表达限制 runtime；在 adapters 新增 `ProjectDraftExecutionConstraintRuntimeService`，统一读取旧的表达限制 profile/binding 设置与 `.novel_agent/continuity/bindings/*.json`，输出共享 runtime report，并同时接入普通会话生成入口与 `ProjectWorkflowRuntimeService` 长任务执行链。长任务准备阶段现已把 binding 派生的 `chapter_length_profile`、表达限制 profiles/bindings 与来源报告写入 execution，有效保留旧 UI/设置链并避免把约束做成长任务私有；`ProjectLongTaskPostprocessResultService` 也会优先读取 execution 中的有效 task 做字数评估。新增 `writing_execution_constraint_bridge_service_test.dart`、`project_draft_execution_constraint_runtime_service_test.dart`，并补强 `project_workflow_runtime_service_test.dart` 与 `workbench_conversation_controller_agent_selection_test.dart`，相关 focused tests 与 analyze 已通过）
- ONS-39：已完成（2026-06-04，本轮在 adapters 新增 `ProjectConversationDraftRuntimeService`，把普通项目分散式章节生成所需的 runtime 薄接线从 UI/controller 中抽出：发送前会基于 `ProjectWorkflowRuntimeBridgeService` + `ProjectContextActivationService` 为普通会话构建 activation report、把 activation summary 注入普通会话 `session_context`，并把 `submit_chapter_delivery` 前置到 ordinary chapter turn 的 exposed tools；发送后则会把 activation report 持久化到 `tracking/conversation_draft/*.activation_report.json`，同时优先回收模型真实调用的 `submit_chapter_delivery` outcome，若模型本轮仍只走 `write_project_file` 写出 `chapters/*`，则由该薄服务补做一次受控 `submit_chapter_delivery` 收口并记录隐藏 delivery 结果，保证普通项目不会绕过章节交付 gate，也不会丢失 activation report。应用层 `WorkbenchConversationController` 现已接入该服务，让普通会话在用户分散生成、查看、调整后继续生成时，仍共享 ONS-38 的最新 constraint binding/profile 读取链，并能在 domain delivery 只有 `changed_paths`、没有 `writtenPaths` 时正确回填章节输出路径供资源刷新和正文打开。同步更新 `ToolStrategyPromptBuilder`，把普通正式章节写作提示从“自动 `write_project_file` 保存”提升为“优先 `submit_chapter_delivery` 正式交付”，并新增 `project_conversation_draft_runtime_service_test.dart`、扩展 `workbench_conversation_controller_agent_selection_test.dart` 与 `draft_generation_use_case_test.dart`，覆盖普通会话 activation report 注入、`submit_chapter_delivery` 工具优先级、low-level 章节写入补交为 domain delivery，以及普通章节写作 prompt 合同不再默认为 `write_project_file` 收口；已通过 `dart test test/project_conversation_draft_runtime_service_test.dart`（`packages/novel_agent_adapters`）、`dart test test/draft_generation_use_case_test.dart`（`packages/novel_agent_core`）、`flutter test test/workbench_conversation_controller_agent_selection_test.dart`（`apps/novel_agent_app`）、`dart analyze lib/src/tools/tool_strategy_prompt_builder.dart test/draft_generation_use_case_test.dart`、`dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart lib/novel_agent_adapters.dart test/project_conversation_draft_runtime_service_test.dart`、`flutter analyze lib/app/bootstrap/app_bootstrap.dart lib/app/state/app_shell_controller.dart lib/features/workbench/application/controllers/workbench_conversation_controller.dart test/widget_test.dart test/workbench_conversation_controller_agent_selection_test.dart`）
- ONS-40：已完成（2026-06-04，本轮在 adapters 新增 `ProjectLongTaskChapterQueueRuntimeService`，把 `seed_to_full_novel` 的章节队列从“开局预造完整 1..N 章任务”改为“只物化 planning + 总纲检查点 + 样章 + 样章检查点首窗”，并在 `ProjectWorkflowRuntimeService.createLongTaskWorkflow()` / `nextWorkflowTask()` 接入按需续队列：当当前已物化窗口全部收口后，会基于既有 `LongTaskRevisionPlanService` + `LongTaskRevisionApplyService` 动态追加下一批章节与 checkpoint；`checkpoint_interval = 0` 时则按章逐个长出，不再提前固定整条长篇任务链。同步把 `runWorkflowTaskOnce()` 的 activation report / chapter delivery 结果显式回传到 queue/long-run 记录链，扩展 `_appendQueueStep`、`LongTaskRunStepRecorderService`、`LongTaskRunMarkdownRenderer` 持久化 `activation_report_path`、`activation_report_summary`、`chapter_delivery_state`、`chapter_delivery_path`；并让 `TaskQueueStopPolicyService`、`LongTaskRecoveryService`、`LongTaskFinishDispositionService` 优先读取 delivery state machine 信号，对 `missing_output_recoverable` / `delivered_needs_repair` / `waiting_user_choice` / `manual_attention_required` 等状态给出 repair、等待确认或人工介入的恢复/暂停决策，而不再只靠“无输出”或通用 failed_task 粗判。新增/扩展 `project_workflow_runtime_service_test.dart`、`task_queue_services_test.dart`、`long_task_runtime_services_test.dart`，覆盖 seed_to_full 首窗物化、checkpoint 确认后续窗追加、`checkpoint_interval = 0` 的逐章续队列，以及 long task run step 真正记录 activation/delivery 摘要；已通过 `dart test test/project_workflow_runtime_service_test.dart`（`packages/novel_agent_adapters`）、`dart test test/long_task_runtime_services_test.dart test/task_queue_services_test.dart`（`packages/novel_agent_core`）、`dart analyze lib/src/workflow/project_long_task_chapter_queue_runtime_service.dart lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`（`packages/novel_agent_adapters`）、`dart analyze lib/src/workflow/long_task_run_step_recorder_service.dart lib/src/workflow/long_task_run_markdown_renderer.dart lib/src/workflow/task_queue_stop_policy_service.dart lib/src/workflow/long_task_recovery_service.dart lib/src/workflow/long_task_finish_disposition_service.dart test/task_queue_services_test.dart test/long_task_runtime_services_test.dart`（`packages/novel_agent_core`））
- ONS-41：已完成（2026-06-04，本轮未引入真实 provider、未改 GUI、也没有补新业务逻辑，而是把现有 mock/fake/temp-dir focused tests 收成一个稳定可执行的回归总包：新增 `tools/run_open_narrative_mock_regression_suite.ps1`，统一顺序执行 core 的 `draft_generation_use_case_test.dart`、`submit_chapter_delivery_handler_test.dart`、`chapter_delivery_state_machine_test.dart`、`narrative_supervisor_risk_policy_service_test.dart`、`draft_generation_tool_call_reliability_test.dart`，以及 adapters 的 `project_conversation_draft_runtime_service_test.dart`、`project_narrative_domain_tool_executor_test.dart`、`project_workflow_review_runtime_service_test.dart`、`project_workflow_runtime_service_test.dart`；同时新增 `docs/open-narrative-mock-regression-suite-2026-06-04.md` 作为测试说明，把 `writer success`、`writer no tool`、`empty content`、`title-only`、`submission invalid`、`review blocking`、`permission waiting`、`recovery success` 八类必覆盖场景逐项映射到现有测试名，并补充 ordinary project / long task runtime wiring 的定位方法。该 suite 全部基于 fake gateway、mock tool outcome、本地临时目录和 in-memory 合同，不依赖真实 API，可作为 ONS-42 真实 probe 前的前置门槛；已通过 `powershell -ExecutionPolicy Bypass -File tools/run_open_narrative_mock_regression_suite.ps1` 实跑验证。）
- ONS-42：已完成（2026-06-04，本轮只做真实 probe 框架同源化，没有跑真实 API、没有新增一次性 probe 脚本，也没有补私有 retry/repair 业务逻辑：在 `apps/novel_agent_app/tool/probe_support.dart` 增加了统一的 `loadProbeApiConfig(...)` 包装和 `ProbeReportCategories` / `classifyDraftProbeReportCategory(...)`，把 app 侧真实 probe 的配置读取、显式开闸与失败分类统一收口；同时移除了 `runDraftProbeCase(...)` 中原先探针层自己的传输重试，让真实 probe 只消费 production 结果，不再在 probe 里补一套私有恢复策略。配置层继续复用 `tools/probe_config_support.dart`，真实探针统一要求 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，并从 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 读取接口配置。同步把 `real_option_probe.dart`、`real_openai_compat_probe.dart`、`real_long_task_probe.dart`、`real_long_task_20_chapter_probe.dart`、`gateway_connect_probe.dart` 收口到共享配置/分类入口，其中 `real_openai_compat_probe` 与长任务 probe 报告现已显式区分 `technical_failure`、`waiting_user`、`budget_failure`、`content_quality_failure`、`success`。新增 `apps/novel_agent_app/test/probe_support_test.dart`，覆盖显式开闸、本地配置 override 优先级、以及失败分类规则；已通过 `flutter test test/probe_support_test.dart`（`apps/novel_agent_app`）、`flutter analyze tool/probe_support.dart tool/real_option_probe.dart tool/real_openai_compat_probe.dart tool/real_long_task_probe.dart tool/real_long_task_20_chapter_probe.dart tool/gateway_connect_probe.dart test/probe_support_test.dart`（`apps/novel_agent_app`）、`dart analyze tools/probe_config_support.dart`。当时文档中提到的 `real_general_novel_probe.dart` / `real_special_mechanics_parallel_long_task_probe.dart` 在主树不存在，因此该轮实际落点映射到现存的普通真实 probe 与长任务 probe 入口，而不是为缺失文件再新造脚本；其中 `real_general_novel_probe.dart` 已在后续 ONS-43 阻塞收口中补回主树。）
- ONS-43：已完成（2026-06-04，先前本轮已显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`，并实际运行 `dart run tool/real_long_task_probe.dart` 与 `dart run tool/real_workflow_loop_probe.dart <历史普通小说工作区>`；同时仅修正了 `apps/novel_agent_app/tool/real_long_task_probe.dart` 的探针推进逻辑，使其不再假定样章后已直接生成第02章 task，而改为按当前 runtime 的 checkpoint/checkpoint_review/postprocess/waiting_user 合同推进，且 `flutter analyze tool/real_long_task_probe.dart` 已通过。后续已补回 `apps/novel_agent_app/tool/real_general_novel_probe.dart` 并通过 `flutter analyze tool/real_general_novel_probe.dart`，随后实际运行 `dart run tool/real_general_novel_probe.dart` 完成普通项目现时复跑，生成 `artifacts/real_general_novel_probe_report.json`：其中第01-03章通过且 `delivery_outcome = accept`，第04章最初在 ordinary conversation 链上触发 `submit_chapter_delivery：领域工具参数不合法`。为此，先在 adapters 的 `ProjectConversationDraftRuntimeService` 增补了 ordinary conversation 对 invalid `submit_chapter_delivery` 尝试的 salvage recovery，并通过 `dart test test/project_conversation_draft_runtime_service_test.dart` 与 `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart` 验证；随后用 `dart run tool/real_general_novel_probe.dart --chapter-count=4` 做定向真实复验，旧的 invalid payload 现象已不再出现，但第04章新的失败模式变成只做 `set_agent_tasks` / `call_sub_agent` 与只读操作，没有写出 `chapters/第04章.md`、没有 summary、也没有正式 `submit_chapter_delivery`。本轮再进一步补上 ordinary conversation 的章节完成硬边界：`chapter` / `revision` 任务如果最终没有章节输出、也没有正式 delivery，只剩计划/委派/读取类工具，就直接判为明确失败；同样通过 `dart test test/project_conversation_draft_runtime_service_test.dart` 与 `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart` 验证。随后再次执行 `dart run tool/real_general_novel_probe.dart --chapter-count=4`，新的最早阻塞一度前移到 `chapter_01`：正文已落盘，但 delivery 只到 `delivered_needs_repair`、`sidecar_state = missing`，同时仍保留 `submit_chapter_delivery：领域工具参数不合法` 的工具错误摘要。针对这个更早的 ordinary conversation 收口点，本轮继续补上“accepted-but-missing-sidecar 时继续 synthetic submission 补交”的逻辑，并让 `real_general_novel_probe` 在最终 delivery 已恢复到 `delivered + accepted` 时，不再把已修复的旧 tool error 痕迹当作 blocking failure；已通过 `dart test test/project_conversation_draft_runtime_service_test.dart`、`dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`、`flutter analyze tool/real_general_novel_probe.dart`。随后再次执行 `dart run tool/real_general_novel_probe.dart --chapter-count=4`，最新报告已 `PASS`，并确认第01-04章全部 `delivery_outcome = accept`、`tool_error_summary = ""`，说明普通项目侧最近连续暴露的 invalid submit、plan-only / sub-agent-only 无交付、以及 salvage 后 sidecar 缺失三类问题，在当前定向 4 章真实链上都已不再复现。之后又在修复后的分支上重新执行 full 10 章 ordinary 真实复跑：`dart run tool/real_general_novel_probe.dart`。一次 full rerun 先把新的最早失败点后移到第09章，暴露出 formal chapter 里 `call_sub_agent` 仍然可见会导致 plan-only / sub-agent-only 无正式交付。为此，又在 `ProjectConversationDraftRuntimeService` 中把 ordinary `chapter` / `revision` 会话里的 `set_agent_tasks` 与 `call_sub_agent` 从 exposed tools 中移除，并扩展测试断言 formal chapter `prepareDraftRun()` 的 `exposedToolIds` 不再包含这两个工具；已通过 `dart test test/project_conversation_draft_runtime_service_test.dart` 与 `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`。随后再次执行 full 10 章 ordinary 真实复跑，最新报告已 `PASS`，并确认 `chapter_01` ~ `chapter_10` 全部 `delivery_outcome = accept`、`tool_error_summary = ""`。因此普通项目侧在 `ONS-43` 范围内要求的“10 章左右 ordinary 真实短验”现已达标。之后又继续处理普通长任务样章后的续窗口阻塞：在 `ProjectLongTaskChapterQueueRuntimeService` 中放宽 seed-to-full 续队列条件，使 `planning` / `sample chapter` 即便仍停留在 `waiting_user`，只要其后继显式 `checkpoint` 已 `succeeded`，就视为该窗口已被 checkpoint 成功覆盖并允许继续物化下一窗口；同步新增 focused test `nextWorkflowTask still materializes next seed window when source tasks remain waiting_user but succeeded checkpoints already cover them`，并通过 `dart test test/project_workflow_runtime_service_test.dart` 与 `dart analyze lib/src/workflow/project_long_task_chapter_queue_runtime_service.dart test/project_workflow_runtime_service_test.dart`。随后再次执行 `dart run tool/real_long_task_probe.dart`，确认样章确认后已经能够续出 `第02章` 任务。最后再针对普通长任务 formal chapter completion 漏口做了一次收口：在 `ProjectWorkflowRuntimeService` 中新增 long-task formal chapter 边界，使 `chapter` / `revision` 任务在没有真实章节文件、也没有正式章节交付时，不能再被直接记成 `succeeded`；若本轮只是 `present_user_options` 触发真实用户选择，则任务落为 `waiting_user`；若本轮只有读取/加载/计划等非交付工具且没有正文/交付，则任务直接落为 `failed`。同步新增 focused tests `runWorkflowTaskOnce keeps formal workflow chapter at waiting_user when model asks user to choose instead of delivering chapter body` 与 `runWorkflowTaskOnce fails formal workflow chapter when no chapter body or delivery is produced`，并通过 `dart test test/project_workflow_runtime_service_test.dart` 与 `dart analyze lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`。随后再次执行 `dart run tool/real_long_task_probe.dart`，最新真实报告已 `PASS`，并确认工作区真实形成 `chapters/第01章.md` 与 `chapters/第02章.md`，其中 `chapter_02.status_after_step = succeeded`、`chapter_02.output_paths = ["chapters/第02章.md"]`、`submit_chapter_delivery = 1`，说明“普通长任务正式章节任务缺少正文输出/正式交付时仍可能被错误放行”这一最新阻塞也已被收口。因此 `ONS-43` 现已整体完成，下一轮可以开启 `ONS-44`；完整历史阻塞与收口记录见 `docs/ons-43-real-validation-blocker-2026-06-04.md`）
- ONS-44：已完成（2026-06-05，已连续完成八个独立子任务：1）新增 `apps/novel_agent_app/tool/real_multiscope_pressure_probe.dart` 并收口技术/内容失败分类；2）继续在同一 probe 上收紧 runtime title 与提示词边界，避免变体 summary 路径和遗漏状态回写，并再次实际运行 `dart run tool/real_multiscope_pressure_probe.dart`，确认 `chapter_01` ~ `chapter_04` 全部通过、`report_category = success`；3）按“CLI 先接上就行”的标准，把现有 `workflow` 命令粗粒度接上 `activation / delivery / review / ledger` 摘要输出，落点为 `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`、`workflow_command.dart` 与 `tool/workflow_output_summary_probe.dart`，并通过 `dart analyze ...` 与 `dart run tool/workflow_output_summary_probe.dart` 验证；4）按同样的“先接上”口径，把长任务总站详情接上 `Activation / Delivery / Review` 开放叙事摘要，落点为 `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`、`project_long_task_station_detail_service.dart`、`apps/novel_agent_app/lib/features/long_task_station/...`，并通过 `dart analyze`、`dart test test/project_long_task_station_detail_service_test.dart` 与 `flutter test test/long_task_station_view_data_service_test.dart` 验证；5）继续在同一 GUI 详情链上补齐 `Continuity` 粗粒度摘要，但不做复杂知识浏览：为此在 `packages/novel_agent_core/lib/src/workflow/long_task_run_step_recorder_service.dart` 中补记 `changed_paths` / `last_changed_paths`，再由 `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart` 对 `.novel_agent/continuity/` 下的变更做去重统计，并在 `apps/novel_agent_app/lib/features/long_task_station/...` 详情面板展示 `Continuity`；6）继续把 ONS-28 已定义的开放叙事 Markdown 投影挂成 GUI 快速入口，`ProjectLongTaskStationDetailService` 只从 `changed_paths / last_changed_paths / step.changed_paths` 中识别 `continuity/叙事状态规则.md`、`continuity/最近状态变化.md`、`constraints/项目约束摘要.md`、`reviews/语义复核摘要.md`，并由长任务总站详情打开对应资源，不把 Markdown 当事实源，也不做编辑器；7）把 GUI 权限确认展示接到同一长任务总站详情链：只识别当前 run 关联的 `.novel_agent/continuity/profile_proposals/*.json` 与 `.novel_agent/continuity/clarifications/*.json`，读取 proposal reason / clarification question 作为摘要，并在详情里展示 `权限确认` 入口；8）完成最终文档收口，记录最终通过情况和剩余风险。本轮同步把 `Continuity` 总数收窄为 `ledger / claims / reviews / deliveries`，避免 profile proposal / clarification 被重复计入 continuity。相关 `dart analyze`、`dart test test/project_long_task_station_detail_service_test.dart`、`flutter analyze` 与 `flutter test test/long_task_station_view_data_service_test.dart` 已通过。当前 ONS-44 已完成 pressure validation、CLI 最小接线、GUI 总站的 `Activation / Delivery / Review / Continuity / Projection / 权限确认` 最小接线，以及最终文档收口；详见 `docs/ons-44-pressure-validation-progress-2026-06-04.md`）

> 最终状态补记（2026-06-05）：ONS-44 已完成。压力真实验证、CLI 粗粒度摘要、GUI 长任务总站 `Activation / Delivery / Review / Continuity / Projection / 权限确认` 最小消费链均已收口，最终文档已更新。剩余风险只保留为后续产品深化项：GUI/CLI 仍是稳定合同的最小消费，不承担底层语义兜底；权限确认只展示记录，不执行审批；Markdown projection 只作为可读入口，不是事实源。`ONS-01` ~ `ONS-44` 任务列表已全部完成，若后续再次收到同一自动提示，应按用户约束进入阻塞式主进程控制台命令。

---

## 11. 生成后自检

1. 已说明本文解决什么。
2. 已说明与旧文档关系。
3. 已做已有实现去重审计。
4. 已冻结架构边界。
5. 已描述目标终态。
6. 已把最终分析设计覆盖进 44 个 session，包括项目级解释器、Markdown 回流 proposal bridge、analysis namespace 提升路径。
7. 顺序为 core/domain 先行，adapters/runtime 随后，probe 和 GUI/CLI 靠后。
8. 每个 session 都包含目标、层级、必读文件、必须完成、本轮不要做、验收标准、直接可用提示词。
9. 已明确不写题材 hardcode、不引入运行时脚本、不让 MD 成为唯一事实源。
10. 已明确 probe 消费 production 同源合同。
11. 已包含总启动提示词和完成记录占位。
