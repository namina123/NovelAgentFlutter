# RAG 平行知识分支任务顺序文档

最后更新：2026-06-17

主线代号：`RPKB`（RAG Parallel Knowledge Branch）

主要分析文档：

- `docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md`
- `docs/important/rag-retrieval-contract-draft-2026-06-17.md`

相关旧文档与基线：

- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/important/api-compatibility-layer-session-order-2026-06-17.md`
- `docs/important/responsibility-boundary-refactor-session-order-2026-06-17.md`
- `docs/architecture.md`
- `agent.md`

建议代码锚点：

- `packages/novel_agent_core/lib/src/project/`
- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/llm/`
- `packages/novel_agent_adapters/lib/src/reference_extraction/`
- `packages/novel_agent_adapters/lib/src/storage/`
- `apps/novel_agent_app/lib/features/project_assets/`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_cli/`

---

## 1. 这份文档解决什么

这份文档解决的是：

**如何在不破坏现有结构化知识体系的前提下，把 RAG 作为一条平行的知识提取/参考资产提取分支，完整接进项目，并形成 GUI / CLI / Docker 可持续演化的正式底座。**

这条主线不只是做一个“RAG 导入按钮”，它要完整回答：

1. RAG 资产在系统里的正式地位是什么。
2. 它与现有 `knowledge_cards / design_elements / research_notes / reference_works` 如何并存。
3. 如何先做基础 `txt` 模式，再逐步扩展到模型辅助 `epub / folder / md`。
4. 如何抽象 Retrieval 接口，而不是把实现绑死到 Flutter 包或单一后端。
5. 如何让项目能挂载结构化知识资产与 RAG 语料资产，而不是二选一。

---

## 2. 与旧文档的关系

### 2.1 与 `rag-parallel-knowledge-branch-analysis-2026-06-17.md` 的关系

那份文档已经明确：

1. 现有知识体系必须保留。
2. RAG 应作为平行检索证据层存在。
3. GUI 首批不需要正式大面板。
4. 两种模式是可行的：
   - 基础无模型模式
   - 模型辅助模式

本顺序文档要做的，就是把这些分析落成实施顺序。

### 2.2 与 `rag-retrieval-contract-draft-2026-06-17.md` 的关系

那份文档已经给出：

1. 正式模型草案
2. 接口族草案
3. 元数据基座方向
4. 宿主消费边界

本顺序文档会以这些合同为核心顺序锚点，而不是跳过合同直接去补 GUI。

### 2.3 与现有 information 主线文档的关系

项目此前已经明确：

1. `.novel_agent/information/*` 才是事实源。
2. `knowledge/*.md` / `research/*.md` 只是投影。
3. GUI / CLI 不应成为信息真相层。

本主线严格继承这些约束，不允许引入 RAG 后反向让 `knowledge/`、聊天记录或 GUI 临时状态重新变成事实源。

### 2.4 与 `responsibility-boundary-refactor-session-order-2026-06-17.md` 的关系

RAG 主线不得重新造出新的巨型 runtime、巨型 controller、巨型 app facade。

所以这条主线必须遵守：

1. 单一职责
2. 合同先行
3. adapter 落后端
4. GUI 最后消费

---

## 3. 已有实现去重审计

## 3.1 已有且方向正确的部分

这些必须复用，不应推倒重来：

1. `information` 子域与 `.novel_agent/information/*`
2. 结构化知识提取主链
3. reference extraction runtime
4. SQLite 项目存储基座
5. 项目挂载/资产投影的既有思路

## 3.2 已有但只是半成品或可借用基础

1. 现有 reference extraction 主链
   - 可借用其提取 runtime 形状
   - 但不能直接拿来冒充 RAG ingestion
2. 现有 SQLite metadata/store 服务
   - 可借用其初始化、路径与 repository 风格
   - 但 RAG 元数据表族应单独建模
3. 现有 project assets / workbench 资产视图
   - 可借用资产卡、摘要、挂载入口
   - 但不应直接扩成大而散的 RAG 面板

## 3.3 绝对不能继续延寿的错误方向

1. 不允许让 RAG 直接写进 `knowledge/` 目录冒充正式入库。
2. 不允许把结构化知识与 RAG hit 结果混成一个万能工具。
3. 不允许让 GUI 直接管理 embedding/index/backend 真相。
4. 不允许把 Flutter 本地包直接升格为全项目唯一官方 retrieval backend。

---

## 4. 本轮冻结的架构边界

### 4.1 `core` 必须负责

1. RAG 正式模型
2. Retrieval 接口族
3. 挂载语义
4. 查询语义
5. 结构化知识层与 RAG 层的协作边界

### 4.2 `adapters` 必须负责

1. SQLite 元数据存储
2. ingestion runtime
3. provider backend 对接
4. 本地/sidecar/远端 retrieval adapter

### 4.3 `app` 必须负责

1. GUI 分支入口
2. 模式选择
3. 提取进度与摘要
4. 挂载入口

### 4.4 `cli` 必须负责

1. 最小构建命令
2. diagnostics / health check
3. 挂载与查询最小入口

### 4.5 本轮不允许的演化方式

1. 不允许先写死一个 Flutter-only backend，再事后抽接口。
2. 不允许先做完整大面板，再补底层正式合同。
3. 不允许让 RAG 把现有结构化知识体系边界冲散。
4. 不允许新增新的信息真相中心文件。

---

## 5. 目标终态

本轮全部 session 完成后，目标终态应当是：

1. 项目正式拥有一条平行的 `RAG 提取` 分支。
2. 现有结构化知识体系不回退、不降格。
3. RAG 资产以 `RagCorpusPackage` 等正式模型存在。
4. 项目可同时挂载结构化知识资产与 RAG 语料资产。
5. 智能体可通过独立工具检索 RAG 证据，而不是混用结构化知识工具。
6. GUI 有轻量提取入口、状态摘要与挂载入口，但没有早产的大面板。
7. CLI 至少具备最小构建、挂载、diagnostics 能力。
8. Retrieval backend 已被抽象成接口族，可接 Flutter 本地、CLI sidecar、Docker 远端等不同实现。
9. 基础 `txt` 模式可跑通。
10. 模型辅助模式已留下正式扩展位，而不是硬编码第二套流程。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `13` 个 session。

原因：

1. 先冻结边界，再建合同。
2. 先把结构化知识层与 RAG 层的关系钉住，再做 ingestion。
3. 先做基础 `txt` 模式，再补模型辅助模式扩展位。
4. GUI / CLI 都只在底层合同稳定后接线。

顺序总原则：

1. 架构边界与去重审计
2. core 合同与模型
3. adapters 元数据与 runtime
4. backend/provider 适配
5. project mount 与工具层
6. GUI / CLI 最小接线
7. probe / regression / handoff

---

## 7. Session 列表总览

1. `RPKB-01` 边界冻结与现有 information 主线对齐
2. `RPKB-02` RAG 正式模型与 Retrieval 合同落地
3. `RPKB-03` RAG SQLite 元数据基座与 repository 草案落地
4. `RPKB-04` 基础 txt ingestion runtime 打通
5. `RPKB-05` Retrieval mount 语义与项目挂载主线落地
6. `RPKB-06` RAG 检索工具与结构化知识工具边界收口
7. `RPKB-07` GUI 轻量提取分支与资产摘要接线
8. `RPKB-08` CLI 最小构建 / 挂载 / diagnostics 接线
9. `RPKB-09` 模型辅助标准化与分章扩展位建模
10. `RPKB-10` backend provider 插拔层与 host capability 收口
11. `RPKB-11` project activation / retrieval activation package 接线
12. `RPKB-12` probe / regression / high-fidelity 验证
13. `RPKB-13` 文档、迁移说明、残留双轨清理与交接

---

## 8. Session 详情

## Session RPKB-01：边界冻结与现有 information 主线对齐

### 本轮目标

先把 RAG 主线与现有 information 主线的关系钉死，避免后续实现再把事实层与检索层混回去。

### 层级归属

- Documentation / architecture

### 必读文件

- `docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md`
- `docs/important/rag-retrieval-contract-draft-2026-06-17.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `agent.md`

### 必须完成

1. 列出：
   - 结构化知识层事实源
   - RAG 检索证据层事实源
   - 可读投影层入口
2. 明确 RAG 不得替代哪些现有信息层对象。
3. 明确 GUI / CLI / adapter / core 的职责分界。

### 本轮不要做

1. 不写 backend 实现。
2. 不改 GUI。

### 验收标准

1. 后续 session 都能引用这份边界冻结清单。
2. 结构化知识层与 RAG 层的边界不再模糊。

### 直接可用提示词

```text
执行 Session RPKB-01，只做 RAG 平行知识分支的边界冻结与现有 information 主线对齐。

必读：
- docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md
- docs/important/rag-retrieval-contract-draft-2026-06-17.md
- docs/project-information-substrate-implementation-audit-2026-06-05.md
- docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md
- agent.md

本轮只做：
1. 冻结结构化事实层、RAG 检索证据层、可读投影层的边界。
2. 明确各层真相源与禁止越权点。
3. 形成后续实现可直接遵守的边界清单。

本轮不要做：
- 不写 backend
- 不改 GUI
- 不开启下一任务

要求：
- 先边界，后实现
- 不让 RAG 反客为主
```

---

## Session RPKB-02：RAG 正式模型与 Retrieval 合同落地

### 本轮目标

把分析文档里的模型草案与接口草案正式落到 `core`。

### 层级归属

- Core / domain contracts

### 必读文件

- `docs/important/rag-retrieval-contract-draft-2026-06-17.md`
- `docs/architecture.md`
- `agent.md`

### 必须完成

1. 正式模型落地，至少覆盖：
   - `RagCorpusPackage`
   - `RagSourceDocument`
   - `RagChunk`
   - `RagIndexHandle`
   - `RetrievalMountBinding`
   - `RetrievalQuery`
   - `RetrievalHit`
   - `RetrievalActivationPackage`
2. 正式接口族落地，至少覆盖：
   - `RagSourceNormalizer`
   - `RagSegmentationStrategy`
   - `RagChunkBuilder`
   - `EmbeddingProviderPort`
   - `RetrievalIndexPort`
   - `RetrievalSearchPort`
   - `RetrievalHealthPort`
   - `RetrievalIngestionPort`
3. 补 focused contract tests。

### 本轮不要做

1. 不接 SQLite。
2. 不接 GUI。

### 验收标准

1. `core` 中已有完整、可编译、可测试的 Retrieval 合同。
2. 后续实现可以只消费合同，不再靠文档口头约定。

### 直接可用提示词

```text
执行 Session RPKB-02，只做 RAG 正式模型与 Retrieval 合同落地。

必读：
- docs/important/rag-retrieval-contract-draft-2026-06-17.md
- docs/architecture.md
- agent.md

本轮只做：
1. 在 core 中落地 RAG 正式模型。
2. 在 core 中落地 Retrieval 接口族。
3. 补 focused contract tests。

本轮不要做：
- 不接 SQLite
- 不接 GUI
- 不开启下一任务

要求：
- 合同先行
- 单一职责
- 不为了方便把宿主细节带进 core
```

---

## Session RPKB-03：RAG SQLite 元数据基座与 repository 草案落地

### 本轮目标

在 adapters 中建立 RAG 元数据基座，但不把 SQLite 强行等同于向量索引本体。

### 层级归属

- Adapters / persistence

### 必读文件

- `RPKB-02` 结果
- 现有 SQLite storage 相关实现
- `docs/storage-dual-compatibility-design.md`

### 必须完成

1. 建立最小表族与 repository 草案，至少覆盖：
   - corpora
   - sources
   - chunks
   - mount bindings
   - index handles
   - ingestion runs
2. 让 SQLite 只承载元数据与映射，不承载“唯一向量 backend 真相”。
3. 补 focused persistence tests。

### 本轮不要做

1. 不实现真正向量搜索。
2. 不接 GUI。

### 验收标准

1. 元数据结构稳定。
2. 后续 backend 可插拔。

### 直接可用提示词

```text
执行 Session RPKB-03，只做 RAG SQLite 元数据基座与 repository 草案落地。

必读：
- RPKB-02 的合同结果
- 现有 SQLite storage 实现
- docs/storage-dual-compatibility-design.md

本轮只做：
1. 建立 RAG 元数据表族与 repository。
2. 确保 SQLite 只承载元数据与映射。
3. 补 focused persistence tests。

本轮不要做：
- 不做真正向量搜索
- 不接 GUI
- 不开启下一任务

要求：
- SQLite 是基座，不是全部
- 不让 repository 变成新的业务中心
```

---

## Session RPKB-04：基础 txt ingestion runtime 打通

### 本轮目标

打通第一条基础 `txt` 模式链路：导入、规则清洗、规则分章、chunk 构建、元数据入库、索引入口。

### 层级归属

- Adapters / runtime
- Core / shared strategy consumption

### 必读文件

- `RPKB-02`
- `RPKB-03`
- 现有 reference extraction runtime 相关实现

### 必须完成

1. 建立基础 ingestion runtime：
   - txt source normalize
   - 规则分章
   - 默认 chunk 策略
   - ingestion result
2. 支持最小 corpus build。
3. 补 focused runtime tests。

### 本轮不要做

1. 不支持 epub/folder/md。
2. 不接模型辅助。
3. 不接 GUI。

### 验收标准

1. 一份 txt 能被构建成正式 `RagCorpusPackage`。
2. 这条链不依赖模型与联网。

### 直接可用提示词

```text
执行 Session RPKB-04，只做基础 txt ingestion runtime 打通。

必读：
- RPKB-02 的合同结果
- RPKB-03 的 SQLite 基座结果
- 现有 reference extraction runtime 相关实现

本轮只做：
1. 打通 txt source normalize -> 规则分章 -> chunk build -> ingestion result。
2. 形成最小可用 RAG corpus build。
3. 补 focused runtime tests。

本轮不要做：
- 不支持 epub/folder/md
- 不接模型辅助
- 不接 GUI
- 不开启下一任务

要求：
- 先打通最小链路
- 不依赖模型
```

---

## Session RPKB-05：Retrieval mount 语义与项目挂载主线落地

### 本轮目标

让项目能正式挂载 RAG 语料资产，且与结构化知识资产并存。

### 层级归属

- Core / mount contracts
- Adapters / mount persistence

### 必读文件

- `RPKB-02`
- `RPKB-03`
- 现有 project assets / information mount 相关链路

### 必须完成

1. 正式落地 `RetrievalMountBinding` 的持久化与查询。
2. 支持项目同时挂载：
   - structured knowledge assets
   - rag corpus assets
3. 定义 mount scope / priority / usage policy 的最小集合。
4. 补 focused tests。

### 本轮不要做

1. 不做 GUI 大面板。
2. 不做复杂权限系统。

### 验收标准

1. 项目挂载语义正式成立。
2. 结构化知识与 RAG 不再被设计成二选一。

### 直接可用提示词

```text
执行 Session RPKB-05，只做 Retrieval mount 语义与项目挂载主线落地。

必读：
- RPKB-02 / RPKB-03 的结果
- 现有 project assets / information mount 相关链路

本轮只做：
1. 落地 RetrievalMountBinding 的正式持久化与查询。
2. 让项目可同时挂载结构化知识资产与 RAG 资产。
3. 补 focused tests。

本轮不要做：
- 不做 GUI 大面板
- 不做复杂权限
- 不开启下一任务

要求：
- 挂载是正式主线
- 不做成临时附件关系
```

---

## Session RPKB-06：RAG 检索工具与结构化知识工具边界收口

### 本轮目标

为智能体暴露正式独立的 RAG 检索工具，不和结构化知识工具混用。

### 层级归属

- Core / tool contracts
- Adapters / tool executor

### 必读文件

- `RPKB-02`
- 现有 tool contract / tool executor 相关实现

### 必须完成

1. 建立独立工具合同，例如：
   - `retrieve_rag_passages`
2. 保持结构化知识工具独立，例如：
   - `query_knowledge_cards`
   - `query_design_elements`
   - `query_reference_works`
3. 明确工具结果格式与引用路径。
4. 补 focused tests。

### 本轮不要做

1. 不做复杂智能体 prompt 大改。
2. 不混合返回结构化结论与 RAG hit。

### 验收标准

1. 工具语义分明。
2. 智能体不会把“证据召回”误当成“正式结论查询”。

### 直接可用提示词

```text
执行 Session RPKB-06，只做 RAG 检索工具与结构化知识工具边界收口。

必读：
- RPKB-02 的合同结果
- 现有 tool contract / executor 实现

本轮只做：
1. 建立独立 RAG 检索工具合同。
2. 保持结构化知识工具独立。
3. 补 focused tests。

本轮不要做：
- 不做大规模 prompt 大改
- 不混合返回不同语义的结果
- 不开启下一任务

要求：
- 证据召回与结构化结论必须分开
```

---

## Session RPKB-07：GUI 轻量提取分支与资产摘要接线

### 本轮目标

在 GUI 中增加 `RAG 提取` 分支，但只做轻入口、状态、摘要与挂载，不做大面板。

### 层级归属

- App / GUI

### 必读文件

- `RPKB-04`
- `RPKB-05`
- `RPKB-06`
- 现有 project assets / workbench / project creation 相关入口

### 必须完成

1. 在提取/参考资产相关入口新增：
   - 结构化知识
   - RAG 提取
   - 混合提取（若这一轮只留占位，也要合同化）
2. 基础模式首批只开放 txt。
3. 显示资产摘要卡：
   - 名称
   - 来源
   - chunk 数
   - 构建方式
   - 是否使用模型
   - 挂载状态
4. 补 widget / controller tests。

### 本轮不要做

1. 不做正式大面板。
2. 不做复杂浏览器。

### 验收标准

1. GUI 能触发基础 RAG 提取。
2. GUI 能看到资产摘要并挂载到项目。

### 直接可用提示词

```text
执行 Session RPKB-07，只做 GUI 轻量提取分支与资产摘要接线。

必读：
- RPKB-04 / RPKB-05 / RPKB-06 的结果
- 现有 project assets / workbench / project creation 相关入口

本轮只做：
1. 新增 RAG 提取轻入口。
2. 基础模式首批只开放 txt。
3. 显示最小资产摘要并支持挂载。
4. 补 widget/controller tests。

本轮不要做：
- 不做正式大面板
- 不做复杂浏览器
- 不开启下一任务

要求：
- GUI 只做消费，不重建底层语义
```

---

## Session RPKB-08：CLI 最小构建 / 挂载 / diagnostics 接线

### 本轮目标

让 CLI 具备最小 RAG 能力，不让 GUI 独占这条主线。

### 层级归属

- CLI
- Shared projection

### 必读文件

- `RPKB-04`
- `RPKB-05`
- `RPKB-06`
- `apps/novel_agent_cli/`

### 必须完成

1. 提供最小 CLI 入口：
   - build rag corpus
   - list rag corpora
   - mount rag corpus
   - retrieval diagnostics
2. 补 command tests。

### 本轮不要做

1. 不做完整交互式 CLI 子系统。
2. 不做 Docker。

### 验收标准

1. CLI 可独立完成基础 corpus build 与挂载。
2. GUI 与 CLI 消费同一套正式合同。

### 直接可用提示词

```text
执行 Session RPKB-08，只做 CLI 最小构建 / 挂载 / diagnostics 接线。

必读：
- RPKB-04 / RPKB-05 / RPKB-06 的结果
- apps/novel_agent_cli/

本轮只做：
1. 提供最小 CLI 命令族。
2. 补 command tests。

本轮不要做：
- 不做完整交互式 CLI
- 不做 Docker
- 不开启下一任务

要求：
- CLI 只消费正式合同
- 不复制 GUI 私有逻辑
```

---

## Session RPKB-09：模型辅助标准化与分章扩展位建模

### 本轮目标

在不直接吞完复杂格式支持的前提下，把模型辅助模式的正式扩展位建立好。

### 层级归属

- Core / strategy contracts
- Adapters / runtime extension

### 必读文件

- `docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md`
- `RPKB-02`
- `RPKB-04`

### 必须完成

1. 合同化：
   - 模型辅助标准化
   - 模型辅助分章
   - 干扰块剔除
   - 不确定块标记
2. 给 `md / epub / folder` 模式预留正式 source kind 与 strategy 扩展点。
3. 补 focused contract tests。

### 本轮不要做

1. 不直接完成全部复杂格式解析。
2. 不把“智能拆书”做成黑盒一步到位。

### 验收标准

1. 模型辅助模式已有正式扩展位。
2. 后续接入模型时不需要另造第二套体系。

### 直接可用提示词

```text
执行 Session RPKB-09，只做模型辅助标准化与分章扩展位建模。

必读：
- docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md
- RPKB-02 / RPKB-04 的结果

本轮只做：
1. 合同化模型辅助标准化与模型辅助分章扩展位。
2. 为 md/epub/folder 预留正式 source kind 与 strategy。
3. 补 focused tests。

本轮不要做：
- 不完成全部复杂格式解析
- 不做黑盒智能拆书
- 不开启下一任务

要求：
- 模型辅助只是前段增强，不是第二套 RAG 主线
```

---

## Session RPKB-10：backend provider 插拔层与 host capability 收口

### 本轮目标

把 Retrieval backend 的宿主差异收口为 provider 插拔层，而不是写死某个 Flutter 包。

### 层级归属

- Adapters / backend provider

### 必读文件

- `RPKB-02`
- `RPKB-03`
- `RPKB-08`
- `agent.md`

### 必须完成

1. 建立 retrieval provider registry / resolver。
2. 支持至少：
   - placeholder local provider
   - placeholder remote provider
   - health capability reporting
3. 宿主能查询当前是否支持某 provider。
4. 补 focused tests。

### 本轮不要做

1. 不把某个 Flutter 包直接定为唯一官方 backend。
2. 不做过早商用绑定。

### 验收标准

1. backend 可插拔语义成立。
2. GUI / CLI / Docker 未来都能接自己的 backend。

### 直接可用提示词

```text
执行 Session RPKB-10，只做 backend provider 插拔层与 host capability 收口。

必读：
- RPKB-02 / RPKB-03 / RPKB-08 的结果
- agent.md

本轮只做：
1. 建立 retrieval provider registry / resolver。
2. 支持最小 local/remote provider 占位与 capability reporting。
3. 补 focused tests。

本轮不要做：
- 不把某个 Flutter 包定死为唯一官方 backend
- 不做商用绑定
- 不开启下一任务

要求：
- 共享合同，不共享底层引擎
```

---

## Session RPKB-11：project activation / retrieval activation package 接线

### 本轮目标

让 RAG 命中的证据结果能通过正式 activation package 被智能体消费。

### 层级归属

- Core / activation contracts
- Adapters / activation bridge

### 必读文件

- `RPKB-02`
- `RPKB-05`
- `RPKB-06`
- 现有 project activation / context activation 相关链路

### 必须完成

1. 建立 retrieval activation bridge。
2. 让 RAG 命中结果转换为正式 `RetrievalActivationPackage`。
3. 明确引用路径、证据摘要、警告项。
4. 补 focused tests。

### 本轮不要做

1. 不直接把原始 hit 列表塞进 prompt。
2. 不把 activation 层做成 GUI 私有逻辑。

### 验收标准

1. 智能体能正式消费 RAG 证据包。
2. 证据注入有来源路径、可解释、可测试。

### 直接可用提示词

```text
执行 Session RPKB-11，只做 project activation / retrieval activation package 接线。

必读：
- RPKB-02 / RPKB-05 / RPKB-06 的结果
- 现有 project activation / context activation 相关链路

本轮只做：
1. 建立 retrieval activation bridge。
2. 让 RAG hit 转换为正式 RetrievalActivationPackage。
3. 补 focused tests。

本轮不要做：
- 不把原始 hit 列表直接塞 prompt
- 不做 GUI 私有逻辑
- 不开启下一任务

要求：
- activation 是共享层
- 引用路径与来源必须保留
```

---

## Session RPKB-12：probe / regression / high-fidelity 验证

### 本轮目标

对基础 txt 模式、挂载、检索、激活、GUI 分支做高保真验证。

### 层级归属

- Probe / regression
- App / high-fidelity validation

### 必读文件

- 本主线前 11 个 session 的结果
- 现有 real GUI / workflow / viewmodel probes

### 必须完成

1. 至少覆盖：
   - txt corpus build
   - asset summary visible
   - mount to project
   - retrieval tool returns evidence hits
   - activation package available to runtime
2. 报告区分：
   - 技术失败
   - backend 不可用
   - 宿主能力不足
   - 内容质量失败
3. probe 必须消费 production contracts。

### 本轮不要做

1. 不新增散乱一次性脚本。
2. 不在 probe 中复制第二套业务逻辑。

### 验收标准

1. 高保真验证能证明 RAG 平行分支真的跑通。
2. probe 仍只是验证层，不是真相层。

### 直接可用提示词

```text
执行 Session RPKB-12，只做 probe / regression / high-fidelity 验证。

必读：
- 本主线前 11 个 session 的结果
- 现有 real GUI / workflow / viewmodel probes

本轮只做：
1. 验证基础 txt 模式、资产摘要、挂载、检索工具、activation package。
2. 输出分类明确的验证报告。
3. 确保 probe 消费 production contracts。

本轮不要做：
- 不新增散乱一次性脚本
- 不复制第二套业务逻辑
- 不开启下一任务

要求：
- 高保真
- 报告要区分失败类型
```

---

## Session RPKB-13：文档、迁移说明、残留双轨清理与交接

### 本轮目标

收口这条主线的文档、迁移说明和残留问题清单。

### 层级归属

- Documentation / handoff

### 必读文件

- 本顺序文档
- `docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md`
- `docs/important/rag-retrieval-contract-draft-2026-06-17.md`
- `agent.md`

### 必须完成

1. 更新文档，说明：
   - RAG 在系统中的正式地位
   - 已完成的基础模式范围
   - 模型辅助模式仍处于哪一层
   - backend/provider 哪些只是扩展位
2. 清理明显双轨残留。
3. 更新完成记录与交接摘要。

### 本轮不要做

1. 不再扩新功能。
2. 不重构无关模块。

### 验收标准

1. 文档与实现对齐。
2. 后续会话能直接接力。

### 直接可用提示词

```text
执行 Session RPKB-13，只做文档、迁移说明、残留双轨清理与交接。

必读：
- docs/important/rag-parallel-knowledge-branch-session-order-2026-06-17.md
- docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md
- docs/important/rag-retrieval-contract-draft-2026-06-17.md
- agent.md

本轮只做：
1. 更新文档与交接摘要。
2. 清理明显双轨残留。
3. 记录仍未完成的合理扩展位。

本轮不要做：
- 不扩新功能
- 不重构无关模块
- 不开启下一任务

要求：
- 文档诚实
- 主链与扩展位边界明确
```

---

## 9. 总启动提示词

```text
你现在执行 `docs/important/rag-parallel-knowledge-branch-session-order-2026-06-17.md` 这份任务顺序文档。

先完整阅读：
- docs/important/rag-parallel-knowledge-branch-session-order-2026-06-17.md
- docs/important/rag-parallel-knowledge-branch-analysis-2026-06-17.md
- docs/important/rag-retrieval-contract-draft-2026-06-17.md
- docs/project-information-substrate-implementation-audit-2026-06-05.md
- docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md
- docs/architecture.md
- agent.md

执行规则：

1. 严格按 session 顺序执行，从 `RPKB-01` 开始。
2. 一次只做一个 session。
3. 每完成一个 session：
   - 自测
   - 更新完成记录
   - 再进入下一个 session
4. 不允许跳过 core 合同直接补 GUI。
5. 不允许把 RAG 做成新的事实源。
6. 不允许把某个 Flutter 包或单一 backend 直接写死为全项目正式主线。
7. 不允许让 GUI、CLI、probe 长成新的业务中心。
8. 每轮都遵守：
   - 单一职责
   - 文件不过重
   - 合同先行
   - focused test / contract test 优先
9. 如果当前 session 遇到并行脏区，先判断能否通过稳定合同继续；不能安全继续时，明确报告阻塞文件与原因，不硬改。

最终目标：

在不破坏现有结构化知识体系的前提下，正式引入一条可挂载、可检索、可多宿主扩展的 RAG 平行知识分支。

从 `RPKB-01` 开始执行。
```

---

## 10. 完成记录占位

- [ ] RPKB-01 边界冻结与现有 information 主线对齐
- [ ] RPKB-02 RAG 正式模型与 Retrieval 合同落地
- [ ] RPKB-03 RAG SQLite 元数据基座与 repository 草案落地
- [ ] RPKB-04 基础 txt ingestion runtime 打通
- [ ] RPKB-05 Retrieval mount 语义与项目挂载主线落地
- [ ] RPKB-06 RAG 检索工具与结构化知识工具边界收口
- [ ] RPKB-07 GUI 轻量提取分支与资产摘要接线
- [ ] RPKB-08 CLI 最小构建 / 挂载 / diagnostics 接线
- [ ] RPKB-09 模型辅助标准化与分章扩展位建模
- [ ] RPKB-10 backend provider 插拔层与 host capability 收口
- [ ] RPKB-11 project activation / retrieval activation package 接线
- [ ] RPKB-12 probe / regression / high-fidelity 验证
- [ ] RPKB-13 文档、迁移说明、残留双轨清理与交接

---

## 11. 最后自检结论

这份顺序文档已经完成了以下收口：

1. 没把 RAG 当成替代现有知识体系的方案，而是平行分支。
2. 没把 GUI 提前抬成正式真相层。
3. 没把 Flutter-only backend 当成唯一正式路线。
4. 先合同、再元数据基座、再基础 txt 模式、再 GUI/CLI、再扩展位。
5. 每个 session 都有明确目标、边界、不要做、验收标准和可直接执行提示词。

这份文档可以直接交给 `gpt-5.4-mini` 的目标模式连续执行。
