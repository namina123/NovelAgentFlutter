# 全链路拆书修复计划（导入 → 拆书 → 提取知识(可选) → 进入创作）

> 起因：用户给出拆书全链路的正确顺序与边界，要求"测试并修复"。本文记录现状差距与分阶段改法。
> 日期：2026-06-23。

## 用户规格（target）

顺序：**导入 → 拆书 → 提取知识(可选) → 进入创作**

1. **导入**：导入书籍原文。
2. **拆书**：只做分章 + 去噪 + 清洗，**不涉及其他**。本身是**公用**工具。可选智能体（用于更聪明的去噪）。
3. **提取知识**：**可选，可直接跳过**。若提取：**必须选择模型** → 模型喂给**内置智能体藏起来分析（不暴露）** → 分析需要**翻看文档** → 才进入后续。
4. **进入创作**：若是续写，**分好的正文要放进对应存储结构的正文区域**，续写在其后接写。

## 现状差距（spec vs code）

| spec | 现状 | 关键位置 |
|---|---|---|
| 拆书=纯分章+去噪 | "拆书"按钮一次性做 分章+全套启发式抽取(角色/世界/时间线/伏笔/关系)+叙事桥+计划 | `build_book_deconstruction_draft_use_case.dart:80-184` |
| 提取知识可选/可跳过 | 强制——`buildResult!=null` 是 confirm/create 的闸门；校验器直接报"请先生成结构化预览" | `book_deconstruction_view_data_service.dart:64-74`、`book_deconstruction_controller.dart:626` |
| 提取知识=模型+隐藏智能体+翻文档 | 两套断开的抽取：融合的启发式(无模型) + LLM `reference_extraction`(可选/隐藏，但用全局默认模型不选、把原文塞进 prompt 无 RAG 访问) | `project_reference_extraction_execution_service.dart:122-189` |
| 续写正文放正文区域 | 分好的正文落 `chapters/inherited/continuation/...`(分类 `derived_continuation_narrative`，非 `chapter`)；sqlite 下根本不进 `body_text_document`；续写优先级服务对 `NNN_title.md` 给权重 0，不作为前情读 | `followup_persistence_service.dart:98-139`、`project_structured_content_write_policy.dart:14-26` |

## 已 OK（不动）

- 导入真实可用（epub/txt，归档原文）。`reference_source_document_file_reader_service.dart`。
- 公用分章原语 `ReferenceSourceDocumentStructureService` 已被 RAG / reference_extraction / 拆书复用。
- 智能拆书 `onBookDeconstructionSmartImportRequested` ≈ 规格里的"拆书公用工具+可选智能体"：模型辅助分章+去噪、不抽取知识。但是当前它是"另一种导入入口"，不推进阶段、不落正文。
- LLM `reference_extraction` 可选 + 隐藏 + 结构化记录落盘正确（旧审计"未物化"结论已过时）。

## 分阶段改法

### Phase 1 — 拆书与抽取解耦 + 抽取可跳过 ✅ 已完成（2026-06-23）

**思路（最小侵入，保留结果模型与所有消费方）：** 给 `BuildBookDeconstructionDraftUseCase.execute()` 加 `bool extractKnowledge = false`。

- `extractKnowledge:false`（拆书，默认）：只做 分章 + 章节标题/序号 + 轻量结构（章节骨架）。跳过 storyOutlineSummary 派生、premises、全部 profile 推断、timeline/foreshadow/relationships、narrativeBridge。applicationPlan 只含章纲条目；followupMenu 照常构建（路线选择需要）。
- `extractKnowledge:true`（可选提取，Phase 3 改为 LLM）：保留现有完整启发式行为（过渡期）。

**按钮/闸门：**
- "拆书"按钮（`生成结构化预览`）→ `build(extractKnowledge:false)`（纯拆书）。
- 新增可选"提取知识"动作 → `build(extractKnowledge:true)` 或（Phase 3）LLM `reference_extraction`。
- `canConfirmSelection`/`canCreateDerivedProject`/校验器：只要拆书结果存在即可放行（资产为空也允许）→ **抽取可跳过**。

**测试：** `book_deconstruction_draft_use_case` 加 extractKnowledge:false 只产章纲、不产资产；controller/view_data 加"跳过抽取可直接 confirm/create"。既有用例（默认走 extractKnowledge 兼容）不破。

### Phase 2 — 续写正文落正文区域（D4）✅ 已完成（2026-06-23）

**落地：**
- `BookDeconstructionTargetPathService.liveChapterPath(seq,title)`：续写正文落正文区域 `chapters/第N章_<标题>.md`（document_kind='chapter'），文件名带可解析"第N章"。
- `BookDeconstructionFollowupPersistenceService.persist(writeBodyAsLiveNarrative:)` + `_persistInheritedChapters(asLiveNarrative:)`：派生项目创建传 true→正文区域；拆书项目确认保持默认 false→inherited/ 镜像（分析产物，不打扰正文层）。
- `BookDeconstructionDerivedProjectCreationService` 派生时传 `writeBodyAsLiveNarrative: true`。
- 续写优先级服务 `ProjectChapterContinuityPriorityService`：`chapters/第N章.md` 且 N==previousChapterNumber → 权重 1090（前情正文）。已加单测锁定。
- 同人路线（fanfic）按设计不继承正文，行为不变。

**验证：** `book_deconstruction_target_path_service_test`（liveChapterPath）、`project_chapter_continuity_priority_service_test`（新）、`book_deconstruction_derived_project_creation_service_test`（续写正文落 chapters/，inherited 镜像为空）、core+app deconstruction 全绿。

**遗留（非阻断）：** sqlite 项目下续写正文经 `WriteProjectTextFileUseCase` 落文件系统 `chapters/`（续写上下文激活走文件系统可读到），但未写入 `body_text_document` 主事实源行——需要经 `ProjectStructuredContentBridgeService` 桥接，是更深的 app↔adapter 集成，留后续。markdown 项目（正文主事实源=文件系统）已完全正确。

### Phase 2 — 原始计划（保留供参考）

- `BookDeconstructionFollowupPersistenceService._persistInheritedChapters`：续写路线下，把分好的正文写入**正文区域**（`chapters/<NNN>_<title>.md`，sqlite 下进 `body_text_document` with `document_kind='chapter'`），而非 `chapters/inherited/...`。
- `BookDeconstructionTargetPathService.inheritedChapterPath` → 改为正文路径（或在续写模式下返回正文路径）。
- sqlite 写入：经 `ProjectStructuredContentBridgeService`（`chapter` 已在 `_sqlitePrimaryContentTypes` 允许集），不再仅文件镜像。
- 续写优先级服务：正文区 `NNN_<title>.md` 或 `第N章` 命名需能被识别为前情（`extractChapterNumber` 扩展或按序号）。
- 保留 `chapters/inherited/` 仅给同人/分析镜像（非续写）。

**测试：** derived_project_creation 续写路线 → 正文区有章节 + sqlite body_text_document 有 chapter 行；续写上下文激活能读到前情。

### Phase 3 — 提取知识 = LLM（模型选择 + 隐藏智能体 + 翻文档）（D3）✅ 已完成（2026-06-23）

**落地（在拆书向导内提供可选"提取知识"动作，复用既有 LLM reference_extraction）：**
- `BookDeconstructionController` 新增 `extractKnowledgeHandler` 回调（typedef 返回 `(ok,message)`，与 project_assets 解耦）+ `onBookDeconstructionExtractKnowledgeRequested`：已配置模型才启用，委托隐藏内置智能体读拆书产物分析；未配置/失败如实提示，且强调"可跳过直接确认进入创作"。
- `BookDeconstructionOperationKind.extractingKnowledge`、view data `canExtractKnowledge`/`extractKnowledgeActionLabel`、preview panel "提取知识（可选）"按钮（拆书后、确认前）。
- `app_shell_controller` 注入 handler → 复用 `_injectedProjectReferenceExtractionExecutionService`/`ProjectReferenceExtractionExecutionService.pickAndExecute`（读拆书结构化正文、必须已配置模型、隐藏内置智能体、结构化记录落 knowledge/design/research/reference 仓库）。
- **必须选模型**：未配置时按钮禁用 + "需要先配置模型"；已配置才启用。
- **隐藏内置智能体**：reference_extraction 本就无 agent picker + 合成兜底组（spec"藏起来不暴露"）。
- **翻文档**：source 解析走拆书结构化正文投影（`useDeconstructionProjection`），分析读取拆书产物。

**验证：** `book_deconstruction_controller_test`（+2：调用回调如实呈现 / 未配置模型拒绝且不调用回调）、全 deconstruction app 19 绿、app analyze 改动文件零 issue。

**遗留（非阻断，已记录）：** reference_extraction 现用全局默认模型（spec"必须选择模型"的理想形态是就地模型 picker）；分析把原文批量塞进 prompt 而非 RAG 检索——两者是更深 UI/检索增强，留后续。

### Phase 3 — 原始计划（保留供参考）

- 把 Phase 1 的可选"提取知识"接到 LLM `reference_extraction`（源用拆书产出的清洗正文，`useDeconstructionProjection` 路径已有）。
- **必须选模型**：在提取动作里要求一次模型选择（若全局默认缺失则就地选），对齐 spec"必须选择模型"。
- **隐藏内置智能体**：维持 reference_extraction 现有"无 agent picker + 合成兜底组"的隐藏形态，UI 不暴露 agent。
- **翻文档**：给提取 agent 接语料访问（把拆书产物入 RAG 语料并挂载，或让 agent 经检索工具读章节），替换"塞进 prompt"。

**测试：** 提取动作要求模型；隐藏 agent 不在 UI 暴露；分析能读到拆书章节内容。

## 验证

- 单测：core `build_book_deconstruction_draft_use_case`（Phase 1）、adapters followup/正文 落盘（Phase 2）、reference_extraction 模型/隐藏（Phase 3）。
- 既有基线不新红：`book_deconstruction_controller_test`、`book_deconstruction_view_data_service_test`、`book_deconstruction_confirm_workflow_service_test`、`book_deconstruction_derived_project_creation_service_test`、`book_deconstruction_re0_smoke_contract_test`、`project_content_path_policy_service_*`。
- 静态：`dart analyze` 改动文件；`flutter analyze apps/novel_agent_app`。
- 桌面编译：每阶段 `flutter build windows --debug`。

## 不在本计划（延后）

- 拆书 orchestration 完全抽成跨项目类型公用工具（原语已公用，编排解耦留后续）。
- kb 水合卡死、多智能体派发等其他 P0 遗留（见 p0-closure-2026-06-23.md）。
