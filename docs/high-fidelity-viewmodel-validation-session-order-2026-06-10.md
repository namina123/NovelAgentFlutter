# 高保真 ViewModel 验收、修复与重跑任务顺序文档

最后更新：2026-06-10

主线代号：`HFVV`（High Fidelity ViewModel Validation）

关联分析文档：

- `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
- `docs/important/opening-default-constraint-followup-2026-06-09.md`
- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

核心代码锚点：

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/`
- `apps/novel_agent_app/lib/features/project_creation/`
- `apps/novel_agent_app/lib/features/long_task_station/`
- `apps/novel_agent_app/lib/features/project_assets/`
- `packages/novel_agent_core/lib/src/`
- `packages/novel_agent_adapters/lib/src/`
- `apps/novel_agent_app/tool/`
- `apps/novel_agent_app/test/`

参考输入：

- `references/files/Harry Potter.txt`
- `references/files/Harry Potter - Volume 1 Raw.txt`
- `references/files/re从零开始的异世界生活.txt`

---

## 1. 这份文档解决什么

这份文档把下一回合的测试、修复与验收拆成可执行任务。它的目标不是生成更多孤立探针，而是建立一套能从 GUI ViewModel 路径模拟真实用户的高保真验收体系。

本轮必须证明：

1. 普通项目、长任务、拆书续写、知识库、网络信息、同人写作、多智能体调度都能从新项目开始走通。
2. 测试过程中出现问题时，能定位、修复、重跑，而不是只写失败报告。
3. 测试逻辑不再跳过前置流程，不再用预设提示直接逼模型产出最终正文。
4. ViewModel 状态、模型返回、项目文件、工具事件、运行记录共同构成验收证据。

---

## 2. 与旧文档和旧探针的关系

1. `FMSC` 主线负责全模块去重与协作边界，本轮消费它的“不要长双实现”约束。
2. `CTRS` 主线负责连续任务控制面和参考基底，本轮要证明它们在真实路径可用。
3. `RRP` 主线负责发布收口，本轮是发布前高风险功能验收。
4. 旧 real probes 可复用部分基础设施，但不得继续绕过用户路径。
5. 旧 probe provider 中任何“直接写第一章”的假设，都必须被移除或降级为专项测试输入。

---

## 3. 架构边界冻结

1. 不把测试题材写入 core。
2. 不把高保真 harness 做成第二套业务 runtime。
3. 不在 probe 里复制章节交付、表达限制、知识库、长任务稳定性的主判定逻辑。
4. GUI / ViewModel 是本轮主验收入口。
5. 底层 service 只能作为取证和辅助，不作为主路径替代。
6. 每条测试线产物独立，不共用项目目录。
7. 失败修复优先修生产链路，不在探针里吞错。
8. 测试 API key、代理、私有路径不得写进公开文档和 git。

---

## 4. 并行测试线

### Lane A：普通项目信息先行再写作

- 类型：单独并行主线
- 主题建议：历史 + 科技发展，社畜穿越到明代或其他朝代，轻松向，节奏合理。
- 核心验证：
  - 是否先判断资料需求。
  - 是否收集历史、制度、时代技术、工艺可行性。
  - 是否在用户未要求跳过资料时避免直接编造正文。
  - 是否生成知识卡 / 研究记录。
  - 表达限制是否生效。

### Lane B：普通项目多智能体写作

- 类型：单独并行主线
- 主题建议：需要资料、设定、审核、正文协作的普通小说。
- 核心验证：
  - 主智能体是否调用子智能体。
  - 子智能体是否有独立上下文。
  - 子智能体结果是否影响后续输出。
  - 子智能体是否受工具权限与表达限制约束。

### Lane C：用户侧知识库生成

- 类型：单独并行主线
- 输入：用户提供小规模资料或自定义设定。
- 核心验证：
  - 用户从 GUI / ViewModel 入口生成知识库。
  - 结果结构化保存。
  - 来源身份可分发、可追踪、无本机绝对路径泄漏。

### Lane D：常规书籍导入知识库生成

- 类型：单独并行主线
- 输入：优先小规模用 `Harry Potter - Volume 1 Raw.txt`，稳定后再用 `Harry Potter.txt`。
- 核心验证：
  - 使用提取类智能体组。
  - 输出中文。
  - 角色、地点、组织、物品、时间线、魔法体系、情节因果、伏笔、风格观察可查。
  - 可回答常见和刁钻问题。

### Lane E：网络信息知识库生成

- 类型：单独并行主线
- 主题建议：历史制度 + 科技发展依据，例如制盐、冶铁、蒸汽、高炉、农业改良等。
- 核心验证：
  - 需要联网时能请求或执行联网。
  - 客观事实要求严谨来源。
  - 网络失败不假装成功。
  - 结构化知识可复用。

### Lane F：哈利波特同人写作消费

- 类型：顺带测试，依赖 Lane D
- 题材：地球中国主角，天师老死后转生哈利波特世界，与哈利同级，在魔法世界用修仙知识发展日常、解决问题，轻松向，解决原作意难平并处理剧情偏移。
- 核心验证：
  - 消费 Harry Potter 知识库。
  - 同人信息准确。
  - 剧情偏移有因果与代价。
  - 表达限制与知识卡生效。

### Lane G：一般长任务稳定性

- 类型：单独并行主线
- 核心验证：
  - 不预排 1-200 章。
  - 由智能体自然规划。
  - 至少跑到 50 个有效章节。
  - watchdog / supervisor / recovery / task station 可用。
  - 缺正文、只读轮、工具失败、表达限制失效、字数失控能被调度层处理。

### Lane H：一般长任务多智能体调度稳定性

- 类型：单独并行主线
- 核心验证：
  - 长任务中主智能体调用资料、审核、连续性子智能体。
  - 至少跑到 50 个有效章节。
  - 子智能体失败可诊断、可恢复。
  - 多智能体不破坏章节交付。

### Lane I：多剧烈变化剧情走向

- 类型：单独并行主线
- 输入示例：快穿 / 穿书 / 多世界，但只能作为测试输入。
- 核心验证：
  - 用一般长任务处理，不在 core 写死快穿。
  - 至少跑到 50 个有效章节。
  - 世界切换、回归、状态变化、记忆、任务目标能记录。
  - 分段点允许出现在章节中部。
  - 叙事合理性与稳定性兼顾。

### Lane J：拆书续写多层级

- 类型：多个并行子线
- 输入：`references/files/re从零开始的异世界生活.txt`
- 预处理：
  - 复制到 artifacts / local 临时目录。
  - 自动检测编码并转换为 UTF-8。
  - 不修改原文件。
  - 在约 100 万字附近按章节或自然段边界分段。
- 子线：
  - J1：原文片段直接续写。
  - J2：摘要层续写。
  - J3：角色 / 世界 / 伏笔 / 时间线资料续写。
  - J4：长任务式拆书续写，至少跑到 50 个有效章节。
- 核心验证：
  - 续写延续性。
  - 人物口吻与状态不崩。
  - 新旧事实边界清楚。
  - 表达限制生效。

---

## 5. 运行台账与产物约定

本轮所有测试必须使用统一 run id 和独立 lane 目录，避免并行测试互相污染。

建议路径：

```text
artifacts/high_fidelity_viewmodel_validation/<run_id>/<lane_id>/
```

每条 lane 至少保存：

- `lane_report.json`：结构化报告，记录 ok、失败分类、项目路径、模型决策、工具事件、文件产物、修复与重跑次数。
- `step_XXX_viewmodel.json`：每一步 ViewModel 快照。
- `step_XXX_tool_events.json`：工具 pending、完成、失败、重试摘要。
- `step_XXX_model_event.json`：模型返回摘要，不包含 key。
- `project_manifest.json`：新项目、智能体组、表达限制、知识库挂载、长任务配置摘要。
- `fix_log.md`：失败修复与重跑记录。

每一步必须按真实用户循环推进：

1. 输入或确认。
2. 等待 ViewModel 状态变化。
3. 判断是否是工具执行中、模型等待用户、资料收集、大纲、写作、审核、失败或完成。
4. 根据状态动态决定下一步。
5. 保存快照和事件。

工具结果可能不是马上出现。工具执行中应作为 pending 状态记录和显示，不能把空结果当成成功，也不能把耗时工具误判成失败。

长任务验收要求：

- Lane G/H/I 以及 Lane J4 必须至少跑到 50 个有效章节。
- 有效章节不是只有标题或章号，必须有正文、落盘证据、状态记录和工具事件。
- 50 章是测试验收口径，不是产品核心硬编码；仍然不能预排 1-50 或 1-200 章清单，要让智能体自然规划推进。
- 若无法达到 50 章，必须有明确失败分类、修复重跑记录或外部阻塞证据。

并行波次依赖：

- Wave 0：HFVV-01 到 HFVV-03，准备 harness、台账、语料和安全检查。
- Wave 1：HFVV-04 启动 Lane A/B/C/D/E；任一 lane 失败都可立即修复并重跑，不等其他 lane。
- Wave 2：HFVV-06 启动 Lane F/G/H/I；Lane F 依赖 Lane D 的 Harry Potter 知识库可用。
- Wave 3：HFVV-08 启动 Lane J1-J4；依赖 HFVV-03 的 Re:Zero 预处理产物。
- Wave 4：HFVV-10 到 HFVV-11，做横切回归和发布前判定。

---

## 6. Sessions

## HFVV-01 基线审计与高保真测试计划冻结

- 本轮目标：
  - 阅读分析文档与历史任务文档，确认本轮验收范围、并行线、失败分类、产物目录和预算策略。
- 层级归属：
  - Documentation / Validation planning
- 必读文件：
  - `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
  - 本文档
  - `docs/important/opening-default-constraint-followup-2026-06-09.md`
  - `agent.md`
- 必须完成：
  - 新增或更新本轮 run plan / validation ledger。
  - 明确每条 lane 的 workspace、report、rerun 规则。
  - 核查测试 API、代理、语料文件存在性，但不打印或提交 key。
- 本轮不要做：
  - 不开始长时间真实测试。
  - 不修业务代码。
- 验收标准：
  - 目标模式能按 ledger 启动每条独立测试线。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-01` 执行。只做基线审计与高保真测试计划冻结：读分析文档、确认并行 lanes、失败分类、产物目录、API/代理/语料存在性，不打印或提交 key，不开始长时间真实测试，不修业务代码，不开启下一任务。

## HFVV-02 ViewModel Harness 合同与最小自检

- 本轮目标：
  - 建立或修正高保真 ViewModel 测试 harness。
- 层级归属：
  - App / Probe infrastructure
- 必读文件：
  - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
  - `apps/novel_agent_app/lib/features/workbench/`
  - `apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart`
  - `apps/novel_agent_app/test/`
- 必须完成：
  - harness 必须从新项目创建开始。
  - 通过 controller / action handler 发送用户输入。
  - 从 ViewModel 读取会话条目、当前执行、资源树、状态条、长任务站。
  - 每一步保存 viewmodel snapshot 和模型/工具事件摘要。
  - 明确 pending 工具、完成工具、失败工具、用户确认点的 ViewModel 识别方式。
  - 补一个不调用真实 provider 的 smoke test。
- 本轮不要做：
  - 不直接调用底层 runtime 伪造主路径。
  - 不跑全量真实探针。
- 验收标准：
  - 可以用 fake provider 跑通“新项目 -> 输入背景 -> ViewModel 决策下一步”的最小链。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-02` 执行。只建立或修正高保真 ViewModel harness：新项目起步、controller/action handler 输入、读取 ViewModel 状态、保存 step snapshot，识别 pending/完成/失败工具和用户确认点，并补 fake provider smoke test。不直接绕到底层 runtime，不跑全量真实探针，不开启下一任务。

## HFVV-03 语料预处理与知识库前置资源

- 本轮目标：
  - 准备 Harry Potter 与 Re:Zero 测试输入，建立安全的 artifacts 复制和编码转换流程。
- 层级归属：
  - Probe / Data preparation
- 必读文件：
  - `references/files/Harry Potter.txt`
  - `references/files/Harry Potter - Volume 1 Raw.txt`
  - `references/files/re从零开始的异世界生活.txt`
  - `packages/novel_agent_core/lib/src/reference_extraction/`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/`
- 必须完成：
  - 复制输入到 artifacts / local 临时目录。
  - Re:Zero 编码检测与 UTF-8 转换。
  - 在约 100 万字附近找章节 / 自然段边界。
  - 输出 source asset manifest，不泄漏不必要绝对路径。
  - 补最小测试或脚本报告。
- 本轮不要做：
  - 不修改 references 原文件。
  - 不开始提取全书。
- 验收标准：
  - 后续 lanes 能直接消费预处理产物。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-03` 执行。只做 Harry Potter 与 Re:Zero 语料预处理：复制到 artifacts/local、检测并转换 Re:Zero 编码、在约 100 万字附近定位合理分段、输出 source manifest。不修改 references 原文件，不开始全量提取，不开启下一任务。

## HFVV-04 Wave 1 并行启动：普通信息线、多智能体线、知识生成线

- 本轮目标：
  - 启动并行 lanes A/B/C/D/E。
- 层级归属：
  - Probe / Real ViewModel validation
- 必读文件：
  - 本文档 Lane A-E
  - `apps/novel_agent_app/tool/`
  - `packages/novel_agent_adapters/lib/src/tools/`
  - `packages/novel_agent_core/lib/src/information/`
- 必须完成：
  - 每条 lane 独立 workspace 和 report。
  - 从新项目开始。
  - 通过 ViewModel 动态推进。
  - 任一 lane 失败，暂停该 lane 进入修复，不等所有 lane 完成。
- 本轮不要做：
  - 不把失败藏在总报告里。
  - 不修改 core 题材逻辑。
- 验收标准：
  - A/B/C/D/E 至少各有一次完整运行报告；失败项有明确修复入口或阻塞证据。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-04` 执行。启动 Wave 1 lanes A/B/C/D/E：普通项目信息先行、多智能体普通写作、用户侧知识库生成、书籍导入知识库生成、网络信息知识库生成。每条 lane 独立 workspace/report，从新项目和 ViewModel 路径开始，动态读取模型返回决定下一步。任一 lane 失败就定位修复并重跑该 lane，不等待其他 lane 全部结束。不把题材写进 core，不开启下一任务。

## HFVV-05 Wave 1 失败修复与重跑

- 本轮目标：
  - 对 Wave 1 所有失败进行真实修复与重跑。
- 层级归属：
  - Core / Adapters / App / Probe as needed
- 必读文件：
  - Wave 1 reports
  - 失败涉及的生产代码
- 必须完成：
  - 每个失败先分类。
  - 修生产链路，不在探针里吞错。
  - 重跑失败 lane。
  - 补 focused tests。
- 本轮不要做：
  - 不继续 Wave 2。
- 验收标准：
  - Wave 1 全部通过，或存在明确 `blocked_external` 证据。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-05` 执行。只处理 Wave 1 lanes A/B/C/D/E 的失败：分类、定位、修生产链路、补 focused tests、重跑失败 lane 和受影响相邻回归。不要继续 Wave 2，不要在探针里掩盖失败，不开启下一任务。

## HFVV-06 Wave 2 并行启动：消费与长任务线

- 本轮目标：
  - 启动 lanes F/G/H/I。
- 层级归属：
  - Probe / Real ViewModel validation / Long task
- 必读文件：
  - Lane F-I
  - Wave 1 成功报告
  - `packages/novel_agent_adapters/lib/src/runtime/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
  - `apps/novel_agent_app/lib/features/long_task_station/`
- 必须完成：
  - 哈利波特同人消费测试。
  - 一般长任务稳定性测试，至少 50 个有效章节。
  - 一般长任务多智能体调度测试，至少 50 个有效章节。
  - 多剧烈变化剧情走向测试，至少 50 个有效章节。
  - 验证耗时工具在长任务中有执行中、完成、失败、重试的动态状态。
  - 每条 lane 独立 report。
- 本轮不要做：
  - 不预排 1-200 章。
  - 不把快穿写入 core。
- 验收标准：
  - 每条 lane 有完整运行与验证报告。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-06` 执行。启动 Wave 2 lanes F/G/H/I：哈利波特同人知识消费、一般长任务稳定性、一般长任务多智能体调度、多剧烈变化剧情走向。全部从新项目和 ViewModel 路径开始。Lane G/H/I 必须至少跑到 50 个有效章节；长任务不能预排 1-50 或 1-200 章，要让智能体自然规划推进。快穿只作为测试输入，不写入 core。耗时工具必须验证执行中、完成、失败、重试的动态状态。任一 lane 失败就记录、定位、进入修复，不开启下一任务。

## HFVV-07 Wave 2 失败修复与重跑

- 本轮目标：
  - 修复 Wave 2 问题并重跑。
- 层级归属：
  - Core / Adapters / Runtime / App
- 必读文件：
  - Wave 2 reports
  - 相关失败代码
- 必须完成：
  - 长任务停止、只读轮、缺正文、表达限制、知识消费、剧情变化记录问题必须追到生产链。
  - 修复后重跑失败 lane。
  - 受影响长任务回归也要跑。
- 本轮不要做：
  - 不开始拆书续写。
- 验收标准：
  - Wave 2 通过或有明确外部阻塞。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-07` 执行。只处理 Wave 2 lanes F/G/H/I 的失败：长任务、知识消费、多智能体、剧情变化记录都必须追到生产链修复，补 focused tests，重跑失败 lane 和受影响长任务回归。不开始拆书续写，不开启下一任务。

## HFVV-08 Wave 3 并行启动：拆书续写多层级

- 本轮目标：
  - 启动 Re:Zero 拆书续写 lanes J1-J4。
- 层级归属：
  - Book deconstruction / Reference / Long task / ViewModel validation
- 必读文件：
  - Lane J
  - `apps/novel_agent_app/lib/features/book_deconstruction/`
  - `packages/novel_agent_core/lib/src/reference_extraction/`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/`
- 必须完成：
  - J1 原文片段直接续写。
  - J2 摘要层续写。
  - J3 角色 / 世界 / 伏笔 / 时间线资料续写。
  - J4 长任务式拆书续写，至少 50 个有效章节。
  - 每条子线独立 report。
- 本轮不要做：
  - 不修改 Re:Zero 原文件。
  - 不把原作事实和新创作混成同一事实源。
- 验收标准：
  - 每条子线能说明续写依据、延续性、偏移记录和表达限制状态。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-08` 执行。启动 Wave 3 Re:Zero 拆书续写 lanes J1-J4：原文片段直接续写、摘要层续写、角色/世界/伏笔/时间线资料续写、长任务式拆书续写。J4 必须至少跑到 50 个有效章节。使用 HFVV-03 预处理产物，不修改 references 原文件。每条子线从 ViewModel 路径开始并独立 report。任一子线失败就定位修复并重跑，不开启下一任务。

## HFVV-09 Wave 3 失败修复与重跑

- 本轮目标：
  - 修复拆书续写的稳定性、延续性、信息边界问题。
- 层级归属：
  - Book deconstruction / Reference / Runtime / App
- 必读文件：
  - Wave 3 reports
  - 相关拆书续写代码
- 必须完成：
  - 修复续写断裂、信息错挂、表达限制失效、任务停止、来源边界混乱等问题。
  - 重跑失败子线。
  - 补 focused tests。
- 本轮不要做：
  - 不扩展同人系统。
- 验收标准：
  - J1-J4 通过或有明确阻塞。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-09` 执行。只处理 Wave 3 lanes J1-J4 的失败：续写断裂、信息错挂、表达限制失效、任务停止、来源边界混乱都必须修生产链并重跑失败子线。补 focused tests，不扩展同人系统，不开启下一任务。

## HFVV-10 横切验收与共享回归

- 本轮目标：
  - 汇总所有 lanes，跑共享回归，确认修复没有互相打架。
- 层级归属：
  - Validation / Regression / Documentation
- 必读文件：
  - 所有 lane reports
  - `docs/important/high-fidelity-viewmodel-validation-analysis-2026-06-10.md`
  - `agent.md`
- 必须完成：
  - 汇总表达限制、知识卡、知识库调用、多智能体、watchdog、GUI 状态、来源安全的横切结果。
  - 跑相关 focused tests / regression suites。
  - 标记仍未通过项。
- 本轮不要做：
  - 不新增大功能。
- 验收标准：
  - 有一份总体验收报告。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-10` 执行。汇总所有 lane reports，做横切验收与共享回归：表达限制、知识卡、知识库调用、多智能体、watchdog、GUI 状态、来源安全、失败分类。跑相关 focused tests/regression suites，生成总体验收报告。不新增大功能，不开启下一任务。

## HFVV-11 最终修复收口与发布前判定

- 本轮目标：
  - 处理 HFVV-10 中仍属于必须修复的问题，并给出发布前判定。
- 层级归属：
  - Cross-layer closeout
- 必读文件：
  - HFVV 总体验收报告
  - 失败台账
- 必须完成：
  - 修必须修复项。
  - 重跑相关 lanes。
  - 更新总报告。
  - 给出“可发布 / 不可发布 / 有条件可发布”判定。
- 本轮不要做：
  - 不处理可延后设计优化。
- 验收标准：
  - 本轮高保真验收闭环完成。
- 直接可用提示词：
  - 按 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 的 `HFVV-11` 执行。处理 HFVV-10 总体验收报告中仍属于必须修复的问题，修生产链、重跑相关 lanes、更新总报告，最后给出可发布/不可发布/有条件可发布判定。不处理可延后设计优化，不开启下一任务。

---

## 7. 总启动提示词

```text
根据 `docs/high-fidelity-viewmodel-validation-session-order-2026-06-10.md` 启动高保真 ViewModel 验收、修复与重跑主线。

目标：

1. 从 HFVV-01 开始按顺序执行，不跳 session。
2. 本轮验收必须从新项目开始，通过 GUI ViewModel / Controller / action handler 模拟真实用户交互。
3. 不允许用旧探针捷径跳过前置流程，不允许直接预设“生成第 N 章”作为普通项目主验收。
4. 每条测试线独立 workspace、独立 report、独立修复重跑闭环。
5. 并行测试线可以同时启动，但任何一条失败都要立即分类、定位、修复并重跑该线，不等所有线全部跑完。
6. 修复必须优先落在生产链路，不能只在 probe 里吞错。
7. 题材输入不能写进 core；快穿、哈利波特、Re:Zero、历史科技都只是测试材料。
8. 工具结果可能是耗时返回，必须动态显示 pending、完成、失败、重试状态，不能把空结果当成功。
9. 长任务测试线至少跑到 50 个有效章节，但不能预排章节清单，要让智能体自然规划推进。
10. 表达限制、知识卡、知识库调用、多智能体、watchdog/supervisor、来源安全、GUI 动态状态都是横切验收点。
11. 每个 session 完成后只确认本 session，不开启下一任务，除非明确要求继续。

先执行 HFVV-01。
```

---

## 8. 完成记录占位

- `HFVV-01`：已完成（基线审计、计划冻结、run ledger、lane 模板、预算策略、API/代理/语料存在性核查已落地；run id：`2026-06-10T01-35-42`；见 `docs/high-fidelity-viewmodel-validation-ledger-2026-06-10.md` 与 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/`）
- `HFVV-02`：已完成（已新增 `AppShellController` 级高保真 ViewModel harness 与 fake-provider smoke test；验证了新项目创建、pending tool、completed/failed tool、waiting_user 投影。2026-06-13 又补上真实普通分章续写真机闭环，证明 production-same-source harness 能稳定承载普通项目正式分章续写、continuity handoff 和章节字数 gate；证据见 `apps/novel_agent_app/test/hfvv_viewmodel_harness_support.dart`、`apps/novel_agent_app/test/hfvv_viewmodel_harness_smoke_test.dart`、`apps/novel_agent_app/tool/real_gui_chaptered_continuation_probe.dart`、`apps/novel_agent_app/test/real_gui_chaptered_continuation_probe_test.dart`、`artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_02/` 与 `artifacts/high_fidelity_viewmodel_validation/2026-06-13T00-41-33-097775/lane_ordinary_chaptered_continuation/`）
- `HFVV-03`：已完成（已新增 `hfvv_prepare_source_assets.dart` 与 `reference_source_boundary_locator_service.dart`；三份语料已复制到 `artifacts/.../hfvv_03/source_assets/`，并在 `local/hfvv_source_assets/2026-06-10T01-35-42/utf8/` 写出 UTF-8 副本；`Re:Zero` 已完成编码检测与 UTF-8 转换，且约 100 万字边界已定位到 `paragraph_break @ 999987`；详见 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_03/source_asset_manifest.json` 与 `hfvv_03_report.md`）
- `HFVV-04`：已完成（2026-06-10）。Wave 1 lanes A/B/C/D/E 已从新项目和 ViewModel 路径完成真实运行；失败 lane 已在本 session 内联定位、修生产链、补 focused tests 并重跑收口，最终 `artifacts/high_fidelity_viewmodel_validation/2026-06-10T01-35-42/hfvv_04_wave1_summary.json` 为 `ok=true`。详见 `hfvv_04_acceptance_audit.md` 与各 lane `lane_report.json`。
- `HFVV-05`：已完成（2026-06-10）。本 session 对 Wave 1 最终证据做失败修复与重跑收口复核：确认 `hfvv_04_wave1_summary.json` 为 `ok=true`，且 lanes A/B/C/D/E 终态全部 `ok=true`、`report_category=success`、`failure_count=0`，无残留 `blocked_external`。由于真实生产链修复、focused tests 与失败 lane 重跑已在 HFVV-04 内联完成，HFVV-05 不再新增业务代码，只补 `hfvv_05_acceptance_audit.md`、台账与证据索引。）
- `HFVV-06`：未开始
- `HFVV-07`：未开始
- `HFVV-08`：未开始
- `HFVV-09`：未开始
- `HFVV-10`：未开始
- `HFVV-11`：未开始
