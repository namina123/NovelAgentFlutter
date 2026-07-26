# 小说创作全流程用户视角审计

最后更新：2026-07-24

审计口径：从**真实用户**（中文中长篇小说写作者）要完成的事出发，对照当前代码入口与执行边界，不信任历史文档里的“已完成”。

关联：

- `PRODUCT.md`（目标：可持续推进的本地优先创作工作台）
- `docs/important/comprehensive-completeness-and-design-gap-audit-2026-06-22.md`（约一个月前的完成度审计）
- `memory/ux-honesty-pass-2026-06-24.md`、`memory/deconstruction-chain-architecture.md`

---

## 1. 用户侧产品地图（当前）

### 1.1 主导航

| 分组 | 入口 | 用户语义 |
| --- | --- | --- |
| 项目 | 作品库 | 打开/新建/导入作品 |
| 创作 | 创作台 / 资料库 / 拆书分析（随项目类型切换主工作区） | 写作协作、资料、拆书 |
| 创作 | 智能体生态 | 智能体/技能/装载 |
| 运行 | 长任务 | 全局长任务运行总站 |
| 系统 | 设置 | 模型、接口、权限、上下文等 |

次级/隐藏目的地：`taskCenter`（任务中心，不在主导航常驻）、`projectAssets`（资料页，类型相关）、`review_center`/`inspiration_workbench`/`prompt_templates` 旧入口已折返。

### 1.2 项目类型（创建可选）

| id | 用户名 | 主工作区倾向 |
| --- | --- | --- |
| `novel` | 普通小说 | 创作台 |
| `long_novel` | 长篇长任务 | 创作台 + 需选运行基线 |
| `knowledge_base` | 资料知识库 | 资料库为主 |
| `book_deconstruction` | 拆书承接 | 拆书分析为主 |
| `short_collection` | 短篇/文集 | **enabled: false，不展示** |

创建阶段固定包含：项目类型 →（知识库分支/拆书后续）→ **存储策略（始终）** →（长篇）运行基线。

### 1.3 四条主路径

```
路径 A  从零写小说
  设置 provider/model → 作品库新建「普通小说」→ 创作台开局会话 → 写章/改设定 → 资料整理

路径 B  拆书后续写
  新建「拆书承接」或打开拆书项目 → 导入源文 → 纯拆书(分章) → 可选「提取知识」→ 确认/创建派生写作项目 → 创作台续写

路径 C  资料知识库
  新建「资料知识库」→ 导入/提取语料 → 挂载检索 →（可选）供其他项目引用

路径 D  长篇无人值守
  新建「长篇长任务」选基线 → 开局补齐 → 启动长任务队列 → 长任务总站监控/暂停/恢复 → 审稿闸门（仅部分基线）
```

---

## 2. 分阶段 happy path 与问题

### 阶段 0 — 首次配置（设置）

**用户目标**：配好模型，确认能连上，再开始写。

| 状态 | 说明 |
| --- | --- |
| 已改善 | 「测试连接」会先本地校验再真联网 `ProviderConnectionProbeService.probe`（不再假绿勾） |
| 已改善 | `embedding_model_id` 可在模型设置里写（RAG 向量化） |
| 问题 | 设置页仍有工程味文案（token、fallback 工具 JSON、执行链等） |
| 问题 | 权限/工具策略对普通作者认知负担高，且与「先能写起来」无关 |

**证据**：

- [provider_connection_probe_service.dart](../../apps/novel_agent_app/lib/features/settings/application/services/provider_connection_probe_service.dart)
- [app_shell_controller.dart](../../apps/novel_agent_app/lib/app/state/app_shell_controller.dart) `onProviderConnectionTestRequested` / `_applyProviderConnectionProbe`
- [context_settings_panel.dart](../../apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart)「为模型回复保留的额度（token）」
- [tool_strategy_settings_panel.dart](../../apps/novel_agent_app/lib/features/settings/presentation/widgets/tool_strategy_settings_panel.dart)「允许 fallback 工具 JSON」
- [permissions_settings_panel.dart](../../apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart)「真正进入执行链」

---

### 阶段 1 — 作品库：打开 / 新建 / 导入

**用户目标**：找到作品或开新书。

| # | 严重度 | 问题 | 用户影响 | 证据 |
| --- | --- | --- | --- | --- |
| PL-01 | P1 | 作品库**无删除/复制/派生**动作 | 只能去文件系统删目录；误建项目无法在应用内清理 | [project_open_action_handler.dart](../../apps/novel_agent_app/lib/features/project_open/presentation/contracts/project_open_action_handler.dart) 仅 refresh/create/import/select/open |
| PL-02 | P1 | 创建向导**强制经过存储策略**（Markdown vs SQLite） | 与「低认知负担」相悖；新人被工程决策卡住 | [project_creation_phase_resolver_service.dart](../../apps/novel_agent_app/lib/features/workbench/application/services/project_creation_phase_resolver_service.dart) `phasesFor` 无条件插入 `storageStrategy` |
| PL-03 | P2（已部分修） | 冷启动空态 | `hasLoaded` 已区分加载中 vs 真无作品 | [project_open_view_data.dart](../../apps/novel_agent_app/lib/features/project_open/presentation/models/project_open_view_data.dart) |
| PL-04 | P2 | 打开反馈主要靠壳层/状态栏，作品库页动作反馈弱 | 大目录打开时用户不确定是否卡死 | 打开路径依赖壳层 announce，handler 无页面内进度 API |

---

### 阶段 2 — 创作台写作（路径 A 核心）

**用户目标**：在同一工作区里对话协作、编辑章节、管理设定。

| # | 严重度 | 问题 | 用户影响 | 证据 |
| --- | --- | --- | --- | --- |
| WB-01 | P0 | **附件链路不完整**：产品层默认不暴露附件入口；即便暴露，草稿只进 session，发送链/generate_draft **未传 attachments**；OpenAI 桥对任何非平凡附件 `isRequestSupported: false` | 用户以为能贴图/贴文件，实际要么看不到入口，要么发了就硬失败 | `productExposesAttachmentEntry: false`（[app_shell_controller.dart](../../apps/novel_agent_app/lib/app/state/app_shell_controller.dart) ~5248）；[conversation_attachment_facade.dart](../../apps/novel_agent_app/lib/features/workbench/application/controllers/conversation_attachment_facade.dart) 只写 draft；[openai_attachment_bridge_policy.dart](../../packages/novel_agent_adapters/lib/src/providers/openai_attachment_bridge_policy.dart) L57/L81「桥接尚未实现」 |
| WB-02 | P1 | **停止生成**：UI 会记录取消意图并同步 `DraftGenerationCancellationToken`，但注释仍写「真实中断留给后续」；依赖流式网关是否及时中断 | 长生成时点停止可能仍等完当前流 | [workbench_conversation_controller.dart](../../apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart) `onStopRequested` L791–811；`execute` 内 syncCancellation L1025–1031 |
| WB-03 | P1 | **「优化」按钮产品侧永久关闭**（`supportsOptimizeAction = false`），handler 仅 announce | 若某处误暴露会变成空操作；能力缺口 | [conversation_input_capability_resolver.dart](../../apps/novel_agent_app/lib/features/workbench/application/services/conversation_input_capability_resolver.dart) L26；`onOptimizeRequested` L756–758 |
| WB-04 | P1 | 开局引导仍偏**状态播报**（智能体组/还需…）而非「结论 + 下一步」 | 新用户读感像系统日志 | [conversation_opening_guide_view_data_service.dart](../../apps/novel_agent_app/lib/features/workbench/application/services/conversation_opening_guide_view_data_service.dart) L81–98 |
| WB-05 | P1 | 生成结果未正式落盘时依赖 draft fallback 暂存；关闭保护时可能**只聊不写文件** | 用户以为写进项目了，目录里没有 | `_finalize` 路径 `writtenPaths` 空 + `draftFallbackProtectionEnabled`（controller ~1908–1924） |
| WB-06 | P2 | 灵感工作台模块仍在仓库，导航已**折返创作台** | 文档/测试若仍提「灵感台」会误导；用户找不到独立灵感流 | [app_shell_destination_controller.dart](../../apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart) `showInspirationWorkbench` → `showWorkbench()` |
| WB-07 | P2 | 审稿中心退役，旧入口去长任务总站 | 想找「审稿」的用户迷路 | 同文件 `showReviewCenter` → `showLongTaskStation()` |
| WB-08 | P2 | 结构化资源/资料仍可能带内部词（投影/真相源类） | 正式产品感不足 | 历史 [product-design-ui-audit-2026-06-18.md](product-design-ui-audit-2026-06-18.md)；渲染层需持续人话化 |

表达约束：普通会话已通过 `_resolveExecutionConstraintsFallback` / draft runtime 注入 profiles/bindings（相对 6 月「永远空数组」有改善），但强制力仍主要在提示词层，缺硬校验闸门（除长任务特定基线）。

---

### 阶段 3 — 拆书链路（路径 B）

**用户目标**：导入参考书 → 分章清洗 → 可选抽设定 → 进入续写项目。

| # | 严重度 | 问题 | 用户影响 | 证据 |
| --- | --- | --- | --- | --- |
| BD-01 | — | 纯拆书默认 `extractKnowledge: false` | **符合**设计：拆书与抽取解耦 | controller 拆书路径 L356/L742 |
| BD-02 | — | 提取知识可选、必须选模型、handler 可空时允许跳过 | 正确方向 | `onBookDeconstructionAnalysisRequested` L894–921 |
| BD-03 | P1 | 分析 handler 未注入时提示「分析尚未接入…」 | 装机/接线失败时用户不知是配置问题还是产品缺口 | controller L901–905 |
| BD-04 | P1 | 术语残留：「后续路线」等内部/半工程说法 | 跟「进入创作」心智不一致 | [book_deconstruction_followup_documents_service.dart](../../apps/novel_agent_app/lib/features/book_deconstruction/application/services/book_deconstruction_followup_documents_service.dart) |
| BD-05 | P2 | 长操作已有超时/取消（8min 代际守卫） | 已修；仍需用户理解「取消」是软取消 | UX honesty pass 记录 |
| BD-06 | P2 | 续写正文落盘：派生项目写 live chapters；拆书项目确认默认 mirror | 用户若在拆书项目里找「正文章节」可能对不上 | deconstruction-chain memory；需在 UI 说清「分析项目 vs 写作项目」 |

---

### 阶段 4 — 资料 / RAG（路径 C）

**用户目标**：材料进库，写作时能被用上。

| # | 严重度 | 问题 | 用户影响 | 证据 |
| --- | --- | --- | --- | --- |
| RAG-01 | P1（已部分修） | 向量检索**可接线**（settings-backed embedding + SqliteVectorRetrievalPort），未配 embedding 时诚实降级 lexical/lexical_fallback | 默认多数用户仍是关键词；若 UI 写「语义检索」仍误导 | [project_rag_retrieval_tool_executor.dart](../../packages/novel_agent_adapters/lib/src/tools/project_rag_retrieval_tool_executor.dart)；[adapter_bundle.dart](../../packages/novel_agent_adapters/lib/src/bootstrap/adapter_bundle.dart) searchPortResolver |
| RAG-02 | P1 | 用户必须知道填「RAG 向量化模型 ID」才启用向量 | 发现性差；留空静默关键词 | model_settings 字段（ux honesty pass） |
| RAG-03 | P2 | 结构化/混合提取历史上有占位路径 | 需确认当前 UI 是否仍露出「暂未开放」类按钮 | 2026-06-22 审计 4.6；需 UI 复核 |
| RAG-04 | P2 | 导出：目录导出存在，**ZIP 未做** | 跨设备打包不便 | [local_project_file_mutation_adapter.dart](../../packages/novel_agent_adapters/lib/src/storage/local_project_file_mutation_adapter.dart) L89 注释 |

---

### 阶段 5 — 长任务 / 多章推进（路径 D，头号卖点）

**用户目标**：启动后可持续多章跑，崩了/暂停了能真正接着写。

| # | 严重度 | 问题 | 用户影响 | 证据 |
| --- | --- | --- | --- | --- |
| LT-01 | **P0** | **长任务总站「恢复」只改状态** `paused→running`，**不重新进入** `runWorkflowTaskQueue` | 用户点恢复以为继续写章，实际队列不再推进；崩溃/暂停后「续跑」假象 | [long_task_supervisor.dart](../../packages/novel_agent_adapters/lib/src/runtime/long_task_supervisor.dart) `resumeRun` L98–109；[long_task_station_controller.dart](../../apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart) `onLongTaskStationResumeRequested` 只调 `resumeRun` |
| LT-02 | P0/P1 | 队列入口本身支持 `continue_long_task_run_path` / `resumeRecord`，但**总站 UI 未接到该入口** | 能力在底层、动作在表层脱节 | [project_workflow_queue_runtime_service.dart](../../packages/novel_agent_adapters/lib/src/workflow/project_workflow_queue_runtime_service.dart) L442–447、L568–632 |
| LT-03 | P1 | Watchdog **仅在队列运行期间** start，结束 finally stop；不是常驻守护 | 进程外挂死后的「陈旧 running」探测弱；总站恢复也不会靠它重启队列 | queue runtime L517–535 |
| LT-04 | P1 | 默认 `max_steps=3` 每批；unattended 可外层续批，但文案若承诺「真正无人值守无限写」会过度 | 用户对「跑一会儿就停/要续」预期错位 | queue L649–674、L806–809 |
| LT-05 | P1 | 章级审稿闸门/自动 repair **仅** `chapter_collaboration_autorun` 基线生效；其它基线一律 `auto_continue` | 多数长篇配置下审稿不挡推进、不建修复任务 | [long_task_chapter_gate_disposition_service.dart](../../packages/novel_agent_core/lib/src/workflow/long_task_chapter_gate_disposition_service.dart) L15–27；[project_long_task_chapter_gate_service.dart](../../packages/novel_agent_adapters/lib/src/workflow/project_long_task_chapter_gate_service.dart) L32–39 |
| LT-06 | P1 | 任务中心藏在长任务体系内（不常驻主导航） | 入口套入口；调参与监控分裂 | destination `showTaskCenter` 注释 + 导航 catalog 无 taskCenter |
| LT-07 | P2 | runtime_profile 工作台可 `reloadCurrentRuntimeProfile`；起长任务时是否**始终**以磁盘 profile 为准仍需与 CLI/queue 选项交叉验收 | 外部改 profile 后 GUI 动作可能漂移 | workspace controller `reloadCurrentRuntimeProfile` |

---

### 阶段 6 — 智能体生态

**用户目标**：换协作角色、装技能、导入自定义包。

| # | 严重度 | 问题 | 用户影响 |
| --- | --- | --- | --- |
| AE-01 | P1 | 「智能体组」作为主感知单位偏配置视角，不是「谁在写什么」 | 普通作者理解成本高（历史 product UI 审计） |
| AE-02 | P2 | 生态页与创作台协作设置双入口，语义易重复 | 改了一处另一处是否即时同步需用户自行验证 |
| AE-03 | P2 | 坏 JSON 源已兜底不红屏（已修） | 保留回归 |

---

### 阶段 7 — 跨路径结构问题

| # | 严重度 | 问题 | 用户影响 |
| --- | --- | --- | --- |
| X-01 | P1 | 入口折返多（灵感/审稿/模板/项目库） | 「菜单曾经有过」的能力消失，无替代说明 |
| X-02 | P1 | 巨型壳层/工作台控制器仍主导所有域通知 | 任意重操作易全局刷新、卡顿感（GF 半修复） |
| X-03 | P1 | 合同层完备 vs 执行最后一跳缺失（resume、附件、闸门范围）仍是主病灶 | 「看起来很全，用到关键处才塌」 |
| X-04 | P2 | 窄屏/移动布局弱 | Android/iOS 可用但挤 |
| X-05 | P2 | 无应用内作品 ZIP 打包/跨机迁移一等公民 | 重度项目用户迁移成本高 |

---

## 3. 历史 P0 复核（相对 2026-06-22 / 06-24）

| 历史主张 | 2026-07-24 状态 | 说明 |
| --- | --- | --- |
| 长任务 resume 只翻状态不入队 | **仍 broken（总站路径）** | supervisor 未变；queue 有 continue 但总站未调 |
| Watchdog 生产从不 start | **部分修** | 队列运行期 start/stop |
| RAG 纯关键词、无 embedding | **部分修** | 有向量路径 + 诚实降级；默认仍关键词 |
| 测试连接假绿 | **已修** | 真 probe |
| 附件桥未实现 | **仍 broken** | policy 仍拒绝；产品入口默认关 |
| 停止不中断 | **部分修** | token 已挂，端到端依赖网关 |
| repair/闸门不生效 | **部分修** | 仅 autorun 基线真建 repair |
| 表达约束空数组 | **部分修** | 有 runtime resolve 注入 |
| 创建强制存储策略 | **仍在** | phasesFor 未改 |
| 作品库无删除 | **仍在** | handler 未扩 |
| 资产编辑器切换丢编辑 | **已修**（auto-save-on-switch） | 见 ux honesty pass |
| embedding_model_id 无 UI | **已修** | 模型设置字段 |
| 错误人话化 | **已修** | UserFacingErrorHumanizer |

---

## 4. 按用户伤害排序的收口清单

### 必须先堵（会直接「假跑/假能力」）

1. **长任务总站 Resume → 真正 `runWorkflowTaskQueue(continue_long_task_run_path: …)`**，pause/stop 语义与队列生命周期对齐；文案写清批次边界。
2. **附件：要么实现 OpenAI/Anthropic 桥并打通 draft→ChatRequest，要么入口永久隐藏并去掉 session 假草稿。**
3. **RAG 默认文案与设置向导**：未配 embedding 时全 UI 写「关键词检索」；配了才写「向量检索」。
4. **章闸门策略产品化**：非 autorun 基线在 UI 标明「不拦截连载」；或扩大 enforce 范围。

### 紧随其后（主路径摩擦）

5. 创建向导：普通小说默认存储策略，高级项折叠。  
6. 作品库：删除（确认）/复制/打开进度。  
7. 开局引导改写为「结论 + 下一步动作」。  
8. 停止生成端到端验收（流式中途取消、UI 状态、部分正文是否保留）。  
9. 设置页术语降噪（token/fallback/执行链）。  
10. 拆书确认页：写清「分析项目 / 写作项目 / 正文落在哪」。

### 持续清理

11. 删除或归档孤儿 feature 目录（inspiration 独立页叙事、review_center 壳、placeholder）。  
12. 入口套入口：任务中心与长任务总站信息架构合并。  
13. ZIP 导出。  
14. 窄屏 reflow。  
15. 巨石控制器拆分（工程债，间接伤体验）。

---

## 5. 一句话结论

**用户能走通「配模型 → 建项目 → 在创作台聊天协作」的主路径；拆书「分章 → 可选分析 → 进创作」方向已对齐。真正伤信任的是卖点级能力的最后一跳：长任务总站恢复不续跑、附件半成品、RAG/审稿能力默认与文案可能不一致，以及创建/作品库仍偏工程决策。**

下一阶段应优先 **堵假绿与假恢复**，而不是继续横向加入口。

---

## 6. 建议验收剧本（人工）

1. 新建普通小说 → 只配 provider → 开局写一章 → 检查 `chapters/` 或活动文档是否有正文。  
2. 长篇长任务 → 启动队列 → 总站暂停 → 恢复 → **观察是否还有新任务推进**（预期现状：否）。  
3. 拆书：导入 txt → 拆书 → 不分析确认 → 派生写作项目 → 看 chapters 是否有继承正文。  
4. 资料库：不配 embedding 入库 → 工具检索 → 应看到「关键词」而非「语义」。  
5. 附件：若 UI 无按钮为预期；若强开产品开关 → 发图应失败且人话错误。  
6. 设置测试连接：错 key / 对 key 应区分失败/成功。  
```
