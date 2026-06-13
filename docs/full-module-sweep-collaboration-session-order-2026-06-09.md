# NovelAgentFlutter 全模块巡检、协作防双实现与逐块收口任务顺序文档

最后更新：2026-06-09

主线代号：`FMSC`（Full Module Sweep / Collaboration）

关联主分析文档：

- `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`
- `agent.md`

关联历史任务顺序文档：

- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`

关联代码锚点：

- `packages/novel_agent_core/lib/src/`
- `packages/novel_agent_adapters/lib/src/`
- `apps/novel_agent_app/lib/`
- `apps/novel_agent_cli/lib/`
- `apps/novel_agent_app/test/`
- `apps/novel_agent_app/tool/`

---

## 1. 这份文档解决什么

这份文档解决的不是某一条专题实现，而是当前项目已经进入的一个更危险阶段：

```text
功能已经很多，主线已经很多，分析也已经很多，
但越是这样，越容易出现“看起来都在推进，实际上同一逻辑长出两套实现”
以及“很多模块做到了七八成，却没人系统地把残留问题抹干净”。
```

因此，本文件要把接下来的工作压成一条可执行主线：

1. 先做一次覆盖全项目的模块审计。
2. 把问题按稳定能力块归类，而不是按文件名或表层报错归类。
3. 给每个块明确唯一主实现出口、唯一主负责入口、共享合同边界。
4. 一次只收口一个块，把残留问题真正抹除，而不是继续补旁路。
5. 最后再做跨块联调、真实探针、GUI / CLI 最小消费与发布前验收。

它要达到的终态不是“文档更全”，而是：

1. 现有模块都能被清楚说明是否真正完成。
2. 残留问题都能被定位到正确能力块。
3. 不再允许 probe、fallback、viewmodel、旧链路偷偷长成第二实现。
4. 后续协作时，不会再变成“我动你的，你动我的，最后同步出两份逻辑”。

---

## 2. 与旧文档的关系

### 2.1 这不是平行新主线

本文件不允许再新造：

1. 第二套长任务控制面。
2. 第二套参考提取真相链。
3. 第二套 GUI 消费语义。
4. 第二套 probe 判定逻辑。
5. 第二套“临时更方便”的兼容业务中心。

正确做法是：

1. 复用已经形成基础的主链。
2. 先做全模块去重审计。
3. 只补那些还没真正闭环的共享缺口。
4. 明确谁是主链，谁只是兼容层、投影层、验证层。

### 2.2 它吸收哪些旧主线

1. `CTRS` 主线提供了连续任务控制面、参考提取、参考基底的收口方向。
2. `LTSR` 主线提供了长任务、监督层、审核闭环、恢复链的主线基础。
3. 发布收口和 GUI 主线提供了真实用户入口、viewmodel、工作台与资产面的消费事实。
4. 这些主线各自都有完成内容，但现在缺的是一份站在全局上做去重、分块、按块收口的总顺序。

### 2.3 本文件不处理什么

1. 不在这份文档里重新设计题材逻辑。
2. 不把快穿、死亡回归、哈利波特、历史穿越等测试输入写进 core。
3. 不把 TUI 和完整 CLI 产品化当作本轮最前优先。
4. 不为了“先跑通”接受新的旁路实现。

---

## 3. 已有实现去重审计

### 3.1 已有稳定基础，不重做

以下方向已有正式基础，本主线默认复用：

1. 长任务 `watchdog / supervisor / heartbeat / registry` 骨架。
2. 写作执行、continuity、review、repair、delivery 等基础合同与 runtime bridge。
3. `SqliteReferenceEvidenceSubstrate` 与参考提取执行期 substrate。
4. `ProjectInformation`、activation report、information projection、context activation 基础。
5. 智能体组 / 技能组 / 工具暴露相关框架。
6. GUI 的工作台、长任务站、项目资产区、设置入口基本骨架。
7. 现有的 focused tests、mock probes、real probes 与若干回归脚本。

### 3.2 已有但仍是半闭环

下面这些最容易制造“伪完成感”：

1. 有 runtime，但不代表每条真实入口都吃的是同一 runtime truth。
2. 有 review / repair 结构，不代表所有坏交付都进入正式调度。
3. 有参考提取 substrate，不代表挂载出口、投影出口、GUI 消费口都已统一。
4. 有表达限制与信息纪律，不代表所有执行路径都已真正受控。
5. 有 GUI 功能入口，不代表它们显示的是主链真相，而不是拼出来的表层状态。
6. 有 probe，不代表 probe 没在复制主链判断。

### 3.3 真正还缺的层

这条主线真正要补的是：

1. 全模块审计台账与重复实现风险台账。
2. 各能力块的主实现出口确认。
3. 各块残留问题的分类、定位与消除顺序。
4. 各块 focused validation 与真实入口验证的对应关系。
5. 跨块联动时的“共享合同优先”执行纪律。

---

## 4. 本轮冻结的架构边界

1. 一切收口都必须以稳定能力块为单位，不以“哪个文件顺手”作为切分依据。
2. 同一能力块同一时间只能存在一个正式主实现出口。
3. 同一能力块同一阶段只能有一个主负责会话或主负责智能体。
4. 如果问题跨越多个块，先抽共享合同，再串行落地。
5. `probe / fallback / bridge / compat / viewmodel / widget helper` 都不得成为新的业务中心。
6. GUI / CLI 只能消费稳定合同，不承担补底层缺口的职责。
7. 如果某块仍是混块状态，先拆清再修，不继续往里堆补丁。
8. 任何接近或超过约 600 行且承载多种职责的文件，都要作为拆分候选审计。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. 项目形成一份真实可维护的模块台账。
2. 每个稳定能力块都能清楚说明：
   - 目标职责
   - 事实源
   - 主实现出口
   - 主要消费者
   - 验证入口
3. 所有高风险残留问题都被收口到正确块，而不是散落在外围层。
4. 已发现的双实现风险要么被删除，要么被降级为兼容层并附带移除计划。
5. GUI / CLI / probe / release 面消费的是稳定合同，而不是临时推断。
6. 后续协作可以按块接力，而不会重复补同一逻辑。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `18` 个 session。

顺序理由：

1. `FMSC-01` 到 `FMSC-03` 先建立审计台账、重复实现风险台账和共享边界，不急着大改代码。
2. `FMSC-04` 到 `FMSC-10` 逐块收口核心能力块，优先处理真正影响主链可用性的部分。
3. `FMSC-11` 到 `FMSC-14` 再收口外层消费块，避免 UI / probe 继续吞业务判断。
4. `FMSC-15` 到 `FMSC-17` 做跨块回归、真实入口 probe、发布面验收。
5. `FMSC-18` 最后收口文档、记录与协作交接纪律。

这样做的核心不是平均分配工作量，而是：

```text
先让项目“知道自己有哪些块、哪些真相、哪些风险”，
再逐块修，
最后才让表层消费和发布验收跟上。
```

---

## 7. 全局执行规则

所有 session 均必须遵守：

1. 先读本文档、主分析文档、`agent.md` 和当前 session 必读文件。
2. 只做当前 session，不开启下一任务。
3. 不允许为了省事在 `viewmodel / probe / fallback / tool script` 里补第二套逻辑。
4. 优先修主实现出口，再处理消费者。
5. 如果发现共享缺口，必须先抽合同。
6. 所有本轮修复都要附带 focused verification；必要时再开真实 probe。
7. 不把题材测试、一次性脚本、临时兼容层写入核心长期路径。
8. 不机械拆文件，但必须主动避免新产生的混块文件。

---

## 8. Sessions

## FMSC-01 全模块审计台账骨架

- 本轮目标：
  - 建立全项目模块审计台账模板与首轮填充规则。
- 层级归属：
  - Documentation / Audit
- 必读文件：
  - 本文档
  - `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
  - `agent.md`
- 必须完成：
  - 新增模块审计台账文档
  - 固定台账字段与填写标准
  - 至少列出当前稳定能力块清单
- 本轮不要做：
  - 不改业务逻辑
  - 不修具体 bug
- 验收标准：
  - 后续任何会话都能直接按台账继续填与收口
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-01` 执行。先阅读本文档、`docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md` 与 `agent.md`。只建立“全模块审计台账”骨架与填写规则，至少列出稳定能力块清单和固定字段，不改业务逻辑，不修具体 bug，不开启下一任务。保持解耦合、单一职责、避免单文件过重。

## FMSC-02 重复实现风险台账

- 本轮目标：
  - 建立并首填“重复实现风险台账”。
- 层级归属：
  - Documentation / Audit
- 必读文件：
  - `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
  - `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
  - `agent.md`
- 必须完成：
  - 固定风险类型
  - 记录当前已知风险入口
  - 标注高风险块与首要清理顺序
- 本轮不要做：
  - 不直接删旧实现
- 验收标准：
  - 能回答“哪些地方最可能长出双实现”
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-02` 执行。只做“重复实现风险台账”：固定风险类型、记录当前高风险入口、标出优先清理顺序。不直接删旧实现，不开启下一任务。保持共享合同优先，不要把分析写成泛泛清单。

## FMSC-03 主实现出口与块边界冻结

- 本轮目标：
  - 为各稳定能力块明确主实现出口、事实源、验证入口与主要消费者。
- 层级归属：
  - Documentation / Core boundary audit
- 必读文件：
  - `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
  - `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
  - `packages/novel_agent_core/lib/src/`
  - `packages/novel_agent_adapters/lib/src/`
- 必须完成：
  - 对每个块补“主实现出口 / 事实源 / 验证入口”
  - 识别需要先抽合同的共享缺口
- 本轮不要做：
  - 不大改代码
- 验收标准：
  - 后续 session 能明确知道应改哪一块、哪一个出口
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-03` 执行。只冻结块边界：为稳定能力块补全主实现出口、事实源、验证入口、主要消费者，并标出共享合同缺口。不大改代码，不开启下一任务。避免把 viewmodel、probe、fallback 误当主出口。

## FMSC-04 控制面块残留问题收口

- 本轮目标：
  - 收口连续任务控制面块的残留问题，只修主链，不补旁路。
- 层级归属：
  - Core / Adapters / Runtime
- 必读文件：
  - `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
  - `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
  - `packages/novel_agent_adapters/lib/src/runtime/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
- 必须完成：
  - 根据前序台账清除控制面块的首要残留问题
  - 补 focused tests
  - 更新两份台账
- 本轮不要做：
  - 不顺手改 GUI
- 验收标准：
  - 控制面块至少去掉一类高风险残留或双实现苗头
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-04` 执行。根据前面台账，只收口控制面块的首要残留问题：优先修主实现出口，补 focused tests，更新台账。不顺手改 GUI，不开启下一任务。发现跨块缺口先抽合同。

## FMSC-05 写作执行块残留问题收口

- 本轮目标：
  - 收口写作执行块里影响普通任务与长任务共享主链的残留问题。
- 层级归属：
  - Core / Workflow / Runtime
- 必读文件：
  - `packages/novel_agent_core/lib/src/workflow/`
  - `packages/novel_agent_core/lib/src/creative/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
- 必须完成：
  - 修一类共享执行残留
  - 确认消费者都指向主合同
  - 补 focused validation
- 本轮不要做：
  - 不引入题材特例
- 验收标准：
  - 普通任务与长任务不再各补一份近似执行语义
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-05` 执行。只收口写作执行块的共享残留：修主合同消费、消除近似双实现、补 focused validation。不引入题材特例，不开启下一任务。

## FMSC-06 审稿与修复块残留问题收口

- 本轮目标：
  - 收口 review / repair / disposition / delivery gating 相关残留。
- 层级归属：
  - Core / Review / Runtime
- 必读文件：
  - `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
  - `packages/novel_agent_core/lib/src/review/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
- 必须完成：
  - 修主链上的一类审核或修复残留
  - 补 focused tests
- 本轮不要做：
  - 不通过 probe 侧特殊判断代替正式修复
- 验收标准：
  - 审稿与修复块的主链更清晰，外围层不再自行补判断
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-06` 执行。只收口审稿与修复块：修正式 review / repair 主链的一类残留，补 focused tests，不允许用 probe 侧特殊判断代替正式修复，不开启下一任务。

## FMSC-07 连续性与状态块残留问题收口

- 本轮目标：
  - 收口 continuity / state truth / projection shadow 相关残留。
- 层级归属：
  - Core / Adapters / Persistence
- 必读文件：
  - `packages/novel_agent_core/lib/src/continuity/`
  - `packages/novel_agent_core/lib/src/information/`
  - `packages/novel_agent_adapters/lib/src/storage/`
- 必须完成：
  - 修一类状态真相模糊或 shadow logic 问题
  - 补 focused validation
- 本轮不要做：
  - 不新增临时缓存真相层
- 验收标准：
  - 能清楚说明谁是事实源，谁只是投影
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-07` 执行。只收口连续性与状态块：修一类 state truth blur 或 shadow logic 问题，明确事实源与投影边界，补 focused validation。不新增临时真相层，不开启下一任务。

## FMSC-08 参考提取块残留问题收口

- 本轮目标：
  - 收口参考提取运行、挂载、投影链中的首要残留。
- 层级归属：
  - Core / Adapters / Reference extraction
- 必读文件：
  - `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
  - `packages/novel_agent_core/lib/src/reference_extraction/`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/`
  - `packages/novel_agent_adapters/lib/src/reference_substrate/`
- 必须完成：
  - 修一类参考提取主链残留
  - 防止 runtime / mount / projection 各自长出近似语义
  - 补 focused tests
- 本轮不要做：
  - 不把 md 投影重新拉回事实源
- 验收标准：
  - 提取主链更接近单一真相出口
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-08` 执行。只收口参考提取块：修 runtime / mount / projection 链的一类主残留，防止三处各补一份近似语义，补 focused tests。不把 md 投影拉回事实源，不开启下一任务。

## FMSC-09 信息基底与激活块残留问题收口

- 本轮目标：
  - 收口 information substrate / activation / project information 消费链残留。
- 层级归属：
  - Core / Adapters / Runtime bridge
- 必读文件：
  - `packages/novel_agent_core/lib/src/information/`
  - `packages/novel_agent_adapters/lib/src/information/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
- 必须完成：
  - 修一类信息激活或消费链残留
  - 明确引用的是哪层事实
- 本轮不要做：
  - 不在 prompt 拼接层补业务真相
- 验收标准：
  - 信息激活链消费稳定，且不依赖旁路解释
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-09` 执行。只收口信息基底与激活块：修一类 activation / substrate / consumer 残留，明确吃的是哪层事实源，不在 prompt 拼接层补真相，不开启下一任务。

## FMSC-10 智能体生态块残留问题收口

- 本轮目标：
  - 收口智能体组、技能组、工具暴露与配置消费链的首要残留。
- 层级归属：
  - Core / Adapters / App configuration
- 必读文件：
  - `packages/novel_agent_core/lib/src/tools/domain/`
  - `packages/novel_agent_core/lib/src/agents/`
  - `apps/novel_agent_app/lib/features/settings/`
- 必须完成：
  - 修一类配置消费或暴露策略残留
  - 防止项目级与默认级逻辑复制
- 本轮不要做：
  - 不重做整套设置 UI
- 验收标准：
  - 能明确默认、项目级、运行时消费的边界
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-10` 执行。只收口智能体生态块：修一类配置消费或暴露策略残留，避免默认级与项目级各长一套实现。不重做整套设置 UI，不开启下一任务。

## FMSC-11 工作台与会话 GUI 消费块收口

- 本轮目标：
  - 收口工作台、会话页、主面板的主链消费与文案残留。
- 层级归属：
  - App / GUI / ViewModel
- 必读文件：
  - `apps/novel_agent_app/lib/features/workbench/`
  - `apps/novel_agent_app/lib/features/home/`
  - `apps/novel_agent_app/lib/features/project_creation/`
- 必须完成：
  - 修一类 GUI 消费主链真相错误或误导性文案
  - 删除或下沉一类 viewmodel shadow logic
- 本轮不要做：
  - 不改核心 runtime 语义，除非前序台账明确这是共享缺口
- 验收标准：
  - GUI 更像消费层，而不是业务补丁层
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-11` 执行。只收口工作台与会话 GUI 消费块：修一类主链真相显示错误或文案误导问题，删除或下沉一类 viewmodel shadow logic。不把 GUI 变成补丁层，不开启下一任务。

## FMSC-12 长任务站与运行中心 GUI 消费块收口

- 本轮目标：
  - 收口长任务站、运行中心、状态页对控制面真相的消费。
- 层级归属：
  - App / GUI / Long task station
- 必读文件：
  - `apps/novel_agent_app/lib/features/long_task_station/`
  - `packages/novel_agent_adapters/lib/src/runtime/`
- 必须完成：
  - 修一类 stop reason / runtime truth / status projection 残留
  - 补 UI 层 focused test
- 本轮不要做：
  - 不在 GUI 里硬写 stop reason 推理
- 验收标准：
  - 长任务站只展示正式 runtime truth
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-12` 执行。只收口长任务站与运行中心 GUI 消费块：修一类状态投影或 stop reason 残留，补 UI focused test，不在 GUI 里硬写推理，不开启下一任务。

## FMSC-13 项目资产与参考消费 GUI 收口

- 本轮目标：
  - 收口项目资产、知识卡、参考资料面板的消费残留。
- 层级归属：
  - App / GUI / Assets
- 必读文件：
  - `apps/novel_agent_app/lib/features/project_assets/`
  - `packages/novel_agent_adapters/lib/src/storage/`
  - `packages/novel_agent_adapters/lib/src/reference_extraction/`
- 必须完成：
  - 修一类资产展示或来源表达残留
  - 消除一类 GUI 侧拼接真相
- 本轮不要做：
  - 不直接重做底层 substrate
- 验收标准：
  - GUI 对项目资产的消费更稳定、来源表达更合理
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-13` 执行。只收口项目资产与参考消费 GUI：修一类资产展示或来源表达残留，消除 GUI 侧拼接真相。不重做底层 substrate，不开启下一任务。

## FMSC-14 CLI / 自动化最小消费收口

- 本轮目标：
  - 让 CLI / 自动化入口只消费稳定合同，不复制业务逻辑。
- 层级归属：
  - CLI / Automation
- 必读文件：
  - `apps/novel_agent_cli/lib/`
  - `apps/novel_agent_app/tool/`
- 必须完成：
  - 修一类 CLI / 自动化重复消费或影子逻辑问题
  - 保持最小对接
- 本轮不要做：
  - 不把 CLI 产品化扩大化
- 验收标准：
  - CLI / 自动化不再是第二业务中心
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-14` 执行。只收口 CLI / 自动化最小消费链：修一类重复消费或影子逻辑问题，保持最小对接，不把 CLI 扩成第二业务中心，不开启下一任务。

## FMSC-15 probe / regression 同源化收口

- 本轮目标：
  - 收口 probe / regression，使其尽量消费 production 同源合同。
- 层级归属：
  - Probe / Regression
- 必读文件：
  - `apps/novel_agent_app/test/`
  - `apps/novel_agent_app/tool/`
  - 前序台账
- 必须完成：
  - 修一类 probe-side shadow judgment
  - 补 production-same-source 验证
- 本轮不要做：
  - 不让 probe 承担业务修复
- 验收标准：
  - probe 更像验证器，而不是第二解释器
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-15` 执行。只收口 probe / regression：修一类 probe-side shadow judgment，补 production 同源验证，不让 probe 承担业务修复，不开启下一任务。

## FMSC-16 跨块联调与真实入口小探针

- 本轮目标：
  - 在前述若干块完成后，跑一轮小规模真实入口联调与探针。
- 层级归属：
  - Integration / Probe
- 必读文件：
  - 前序台账
  - 相关 real probe 脚本
- 必须完成：
  - 选择一组普通入口与一组连续任务入口
  - 报告真实失败属于哪一块
  - 若发现问题，只回到对应块修
- 本轮不要做：
  - 不盲目开大规模探针
- 验收标准：
  - 能把失败清楚归因到块，而不是一锅端
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-16` 执行。只做跨块联调与小规模真实入口探针：各选一组普通入口与连续任务入口，报告失败归因到哪一块；若发现问题，只回对应块修，不盲目开大规模探针，不开启下一任务。

## FMSC-17 发布面验收与残留清单更新

- 本轮目标：
  - 以“接近可发布的软件”为视角，更新残留清单与优先级。
- 层级归属：
  - Productization / Audit
- 必读文件：
  - `docs/release-readiness-productization-session-order-2026-06-05.md`
  - 前序台账
  - `apps/novel_agent_app/lib/`
- 必须完成：
  - 按产品视角更新残留
  - 标出必须修、可延后、纯优化
- 本轮不要做：
  - 不再扩展新设计
- 验收标准：
  - 项目残留清单更像真实发布清单，而不是研究 backlog
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-17` 执行。只做发布面验收与残留清单更新：从接近可发布的软件视角重排残留优先级，标出必须修、可延后、纯优化。不扩展新设计，不开启下一任务。

## FMSC-18 总收口、交接与约束回写

- 本轮目标：
  - 收口整个主线的完成记录、交接说明与项目级约束更新。
- 层级归属：
  - Documentation / Handoff
- 必读文件：
  - 本文档
  - `docs/important/full-module-sweep-collaboration-goal-prompt-2026-06-09.md`
  - `agent.md`
- 必须完成：
  - 更新完成记录
  - 更新后续接力提示
  - 若本轮沉淀出新长期规则，回写 `agent.md`
- 本轮不要做：
  - 不再开新实现块
- 验收标准：
  - 后续会话可以无歧义接手
- 直接可用提示词：
  - 按 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 的 `FMSC-18` 执行。只做总收口、交接与约束回写：更新完成记录、后续接力提示，必要时把新长期规则回写 `agent.md`。不再开新实现块，不开启下一任务。

---

## 9. 总启动提示词

下面这段可以直接作为目标模式总提示词：

```text
请以 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 作为本轮最高优先级执行文档，并同时参考：

- `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `agent.md`

你本轮的核心目标不是泛泛地“修项目”，而是：

1. 全方位检查当前已存在的模块。
2. 找出每个模块仍未收口的残留问题。
3. 按稳定能力块逐个抹除问题。
4. 更重要的是，防止协作时出现“我动你的、你动我的”，最后让同一逻辑长出两个实现。

必须始终把下面这条当成最高约束：

同一能力块同一时间只能有一个正式主实现出口和一个主负责会话；
如果问题跨块，先抽共享合同，再串行落地；
不允许在 core、adapter、viewmodel、probe、fallback 各补一份近似逻辑。

执行方式必须严格遵循 `FMSC` 顺序：

1. 先做 `FMSC-01` 到 `FMSC-03`，建立模块审计台账、重复实现风险台账和主实现出口边界。
2. 然后一次只做一个 session，不得跳做多个块。
3. 每完成一个 session，都要：
   - 更新对应台账
   - 说明本轮修的是哪个块
   - 说明主实现出口在哪里
   - 说明消除了哪些残留问题或双实现风险
4. 没完成当前 session 前，不开启下一任务。

额外纪律：

1. 不为了“先跑通”让 GUI、probe、脚本或 fallback 变成新的业务中心。
2. 不把题材测试逻辑写进 core。
3. 不把一次性探针脚本混入长期主线。
4. 所有修复都要尽量附带 focused validation；需要真实 probe 时再开。

完成标准不是“改了很多文件”，而是：

1. 项目模块已被台账化。
2. 残留问题已按块归位。
3. 至少当前 session 对应块被真正收口，而不是补了一层旁路。
4. 双实现风险被明确删除、降级或附上移除计划。
5. 后续会话接手时，不会再因为边界不清而重复补同一逻辑。

开始时先执行当前还未完成的最早 FMSC session；
如果发现某个 earlier session 实际未完成或存在关联性错误，优先回补，不要开启下一 session。
```

---

## 10. 完成记录占位

- `FMSC-01`：已完成（2026-06-09）。已新增唯一正式模块审计台账 `docs/full-module-sweep-module-audit-ledger-2026-06-09.md`，固定 `block_id / responsibility / layer_span / key_code_anchors / existing_basis / audit_status / open_gaps / issue_types / shared_contract_dependency / primary_outlet / truth_source / main_consumers / validation_entrypoints / owner_session / handoff_ready / next_entry` 等字段与更新纪律，并首轮列出 `10` 个稳定能力块：控制面、写作执行、审稿与修复、连续性与状态、参考提取、信息基底与激活、智能体生态、宿主壳与工作台 GUI、CLI 与自动化、probe 与回归。本轮刻意未提前替 `FMSC-02` 填风险明细，也未替 `FMSC-03` 冻结主实现出口/事实源/验证入口；通过把后续会话强制收束到这一份台账，已先消除“每个会话各写一份模块清单、再在不同文档里给同一块下不同口径”的首轮双实现风险。当前最早未完成 session 顺延为 `FMSC-02`。
- `FMSC-02`：已完成（2026-06-09）。已新增唯一正式重复实现风险台账 `docs/full-module-sweep-duplicate-implementation-risk-ledger-2026-06-09.md`，固定 `consumer_shadow_projection / projection_truth_split / cross_layer_contract_fork / legacy_parallel_path / config_resolution_split / probe_side_interpreter / host_action_bypass / shared_hotspot_multi_owner` 八类风险，并首填 `10` 条当前高风险入口，覆盖控制面停点解释、参考提取挂载与信息投影双口径、信息激活链混读、写作执行与审稿修复共享语义分叉、连续性投影混读、智能体生态配置双口径、GUI view-data shadow logic、CLI/自动化旁路、probe 第二解释器与超大共享热点文件。模块审计台账中的 `duplicate_impl_risk_note` 已统一回链到对应 `risk_id`，从而把“哪些地方最可能长出双实现”和“应按哪个正式 session 串行清理”固定到同一入口。当前高风险块首轮清理顺序已按正式 `FMSC-03` 到 `FMSC-15` 会话对齐，当前最早未完成 session 顺延为 `FMSC-03`。
- `FMSC-03`：已完成（2026-06-09）。已在 `docs/full-module-sweep-module-audit-ledger-2026-06-09.md` 为 `10` 个稳定能力块补齐 `primary_outlet / truth_source / main_consumers / validation_entrypoints`，并把各块 `audit_status` 统一推进到 `bounded`、`handoff_ready` 推进到 `yes`；同时在风险台账中把当前 `10` 条高风险项统一推进到 `boundary_frozen`，明确后续代码 session 不得再把 `projection writer / summary service / view-data service / probe support / CLI summary` 误认成主链。当前已冻结的主出口包括：控制面块的 `LongTaskRunCenterContractService`、写作执行块的 `ProjectWorkflowRuntimeService`、审稿与修复块的 `ReviewRepairHandoffService`、连续性与状态块的 `NarrativeStateLedgerService`、参考提取块的 `ProjectReferenceExtractionRuntimeService`、信息基底与激活块的 `ProjectInformationActivationBridgeService`、智能体生态块的 `ContinuousTaskToolExposureRuntimeResolverService`、GUI 消费块的 `workbench_workspace_controller.dart`、CLI 消费块的 `workflow_command.dart`、probe/regression 块的 `continuous_task_control_plane_regression_suite_test.dart`。对应共享合同缺口也已明确归位，例如 `run_center_contract / stop_diagnosis`、`project-information:// locator`、`writing_execution_result / chapter_delivery contract`、`review_contract / repair_lane`、`source_asset_identity / batch coverage` 等。当前最早未完成 session 顺延为 `FMSC-04`。
- `FMSC-04`：已完成（2026-06-09）。本轮只收口 `FMSC-B01` 控制面块，未开启 `FMSC-05`。主实现出口继续保持为 `packages/novel_agent_core/lib/src/workflow/long_task_run_center_contract_service.dart`，并新增控制面共享合同出口 `packages/novel_agent_core/lib/src/workflow/continuous_task_lifecycle_stop_outcome_resolver_service.dart` 与 `packages/novel_agent_core/lib/src/workflow/continuous_task_recovery_state_factory_service.dart`。已消除的残留问题是：`LongTaskSupervisor`、`ContinuousTaskSupervisorBridgeService`、`ReferenceExtractionContinuousTaskSyncService` 先前分别维护 technical-failure recovery shell / lifecycle->stop-outcome 的近似实现，现已统一改为消费同一条 core 合同，避免 control-plane 在 `supervisor / bridge / sync` 三处再长一份 `LongTaskRecoveryState + LongTaskStopOutcome` 组装逻辑，并补上 focused validation 覆盖 `continuous_task_lifecycle_stop_outcome_resolver_service_test.dart`、`continuous_task_recovery_state_factory_service_test.dart`、`continuous_task_supervisor_bridge_service_test.dart`、`long_task_supervisor_test.dart`、`project_reference_extraction_runtime_service_test.dart`。同时修正了 recovery 路径里 `stop_outcome` metadata 容易丢失的残留问题，把 `FMSC-R01` 从“主链和消费者都可能再解释”降到“主链已统一、消费者待清理”，把 `FMSC-R10` 在控制面入口处降级为“共享合同已抽出，后续只允许按后续 session 清理 GUI / CLI / probe 消费层”。当前最早未完成 session 顺延为 `FMSC-05`。
- `FMSC-05`：已完成（2026-06-09）。本轮只收口 `FMSC-B02` 写作执行块，未开启 `FMSC-06`。主实现出口继续保持为 `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`，并新增 adapter 共享合同出口 `packages/novel_agent_adapters/lib/src/workflow/project_writing_execution_contract_service.dart`。已消除的残留问题是：`ProjectWorkflowRuntimeService` 与 `ProjectConversationDraftRuntimeService` 先前分别私有维护 `chapter_delivery -> ChapterDeliveryStateResult`、`execution_constraints -> WritingExecutionConstraintBridgeResult`、`activation_report -> ContextActivationReport` 与 `expression_constraint_projection` 的近似装配，现已统一改为消费同一条 adapter 合同，避免普通任务 runtime 与普通会话 runtime 在 `writing_execution_result` 主链前再次长出两套近似翻译逻辑，并补上 focused validation 覆盖 `project_writing_execution_contract_service_test.dart`、`project_conversation_draft_runtime_service_test.dart`、`project_workflow_runtime_service_test.dart`。同时把 `FMSC-R04` 从“边界已冻结但普通写作与会话写作仍共享热点双装配”降到“主链已统一、review / postprocess 相邻消费者待清理”，当前最早未完成 session 顺延为 `FMSC-06`。
- `FMSC-06`：已完成（2026-06-09）。本轮只收口 `FMSC-B03` 审稿与修复块，未开启 `FMSC-07`。主实现出口继续保持为 `packages/novel_agent_core/lib/src/review/review_repair_handoff_service.dart`，并新增 adapter 共享合同出口 `packages/novel_agent_adapters/lib/src/workflow/project_review_repair_task_contract_service.dart`。已消除的残留问题是：`ProjectWorkflowReviewRuntimeService` 已经产出共享 `review_contract / review_summary / review_repair_handoff`，但 `ProjectReviewReportService` 与 `ProjectLongTaskReviewRepairTaskService` 仍沿用 report-based repair task factory，各自再解释一版“审稿结果如何转成修复任务”；现已统一改为让 review JSON 持久化共享工件，并优先由同一条 adapter 合同消费 `ReviewRepairHandoffService` 产出的 `repair_request / repair_task` 语义来物化 workflow revision 任务，旧 report factory 只保留兼容兜底。focused validation 已覆盖 `project_review_repair_task_contract_service_test.dart`、`project_workflow_review_runtime_service_test.dart`、`project_long_task_review_repair_task_service_test.dart`、`project_workflow_runtime_service_test.dart`。同时把 `FMSC-R04` 从“review runtime 与 repair task service 仍各自解释 repair 语义”降到“主链已统一、GUI / CLI 等消费者待按后续 session 清理”，当前最早未完成 session 顺延为 `FMSC-07`。
- `FMSC-07`：已完成（2026-06-09）。本轮只收口 `FMSC-B04` 连续性与状态块，未开启 `FMSC-08`。主实现出口继续保持为 `packages/novel_agent_core/lib/src/continuity/narrative_state/narrative_state_ledger_service.dart`，并新增 adapter 共享合同出口 `packages/novel_agent_adapters/lib/src/workflow/project_narrative_claim_activation_contract_service.dart`。已消除的残留问题是：`ProjectContextActivationService` 先前直接把 `claims.jsonl` 的 raw narrative claim 当作可激活状态真相来消费，导致 `NarrativeStateLedgerService` 的 disposition truth 与 activation 上下文形成并行出口；现已统一改为由同一条 adapter 合同优先消费 ledger-backed claim entry，`accepted/questioned` 继续进入正式 continuity state truth，`proposed/observed` 仅保留为待裁决 submission，`rejected/superseded` 不再进入 activation 候选。focused validation 已覆盖 `project_context_activation_service_test.dart` 与 `project_workflow_runtime_bridge_service_test.dart`。同时把 `FMSC-R05` 从“activation / projection / workspace 都可能混读 continuity truth”降到“activation 主链已统一、readable projection 与 GUI / assets 消费层待按后续 session 清理”，当前最早未完成 session 顺延为 `FMSC-08`。
- `FMSC-08`：已完成（2026-06-09）。本轮只收口 `FMSC-B05` 参考提取块，未开启 `FMSC-09`。主实现出口继续保持为 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_extraction_runtime_service.dart`，并新增 adapter 共享合同出口 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome.dart` 与 `packages/novel_agent_adapters/lib/src/reference_extraction/project_reference_mount_outcome_resolver_service.dart`。已消除的残留问题是：`ProjectReferenceExtractionMountService` 先前用 `ReferenceProjectionResult? / null` 隐式承载 attach-only、projection applied 与未投影等结果，而 `ProjectReferenceExtractionRuntimeService` 又私有补了一份挂载状态解释去重新推导相同语义，导致 runtime / mount / projection 链上随时可能长出第二套 mount status 映射；现已统一改为由共享合同产出正式 `ProjectReferenceMountOutcome`，runtime 只负责判断 `published snapshot` 是否可用，mount service 返回正式结果，supervisor 与 focused tests 同源消费该结果，并新增 `snapshot_unavailable` 正式状态来承接非 publishable staging run。focused validation 已覆盖 `project_reference_extraction_mount_service_test.dart`、`project_reference_extraction_runtime_service_test.dart`、`reference_extraction_supervisor_signal_service_test.dart` 与 `reference_substrate_chain_test.dart`。同时把 `FMSC-R02` 从“主链和消费者都可能重建 mount/projection 结果解释”降到“主链已统一、projection consumer 待按 `FMSC-09 / FMSC-13` 清理”，并明确本轮没有为 `FMSC-R09` 增加任何 probe-side 判断。当前最早未完成 session 顺延为 `FMSC-09`。
- `FMSC-09`：已完成（2026-06-09）。本轮只收口 `FMSC-B06` 信息基底与激活块，未开启 `FMSC-10`。主实现出口继续保持为 `packages/novel_agent_adapters/lib/src/workflow/project_information_activation_bridge_service.dart`，并新增 core 共享合同出口 `packages/novel_agent_core/lib/src/information/information_source_of_truth_locator_service.dart`。已消除的残留问题是：信息块里原本由 `InformationMarkdownProjectionService` 与 `ProjectInformationPathService` 各自私写一套 `project-information://...` locator 规则，导致 projection metadata 与 activation bridge 对同一 sqlite-first 信息真相仍存在双口径；现已统一改为由同一条 core locator 合同生成 collection / entry truth locator，`ProjectInformationActivationBridgeService`、`ProjectContextActivationService` 与 markdown projection 只消费这组同源标识。focused validation 已覆盖 `information_source_of_truth_locator_service_test.dart`、`information_markdown_projection_services_test.dart`、`project_information_activation_bridge_service_test.dart`、`project_information_projection_writer_service_test.dart` 与 `project_context_activation_service_test.dart`。同时把 `FMSC-R02` 从“信息主链仍可能各自定义 source-of-truth locator”降到“主链 locator 已统一、projection consumer 待按 `FMSC-11 / FMSC-13 / FMSC-14` 清理”，并把 `FMSC-R03` 推进到“主链已统一、runtime / GUI / workspace consumer 待清理”。当前最早未完成 session 顺延为 `FMSC-10`。
- `FMSC-10`：已完成（2026-06-09）。本轮只收口 `FMSC-B07` 智能体生态块，未开启 `FMSC-11`。主实现出口继续保持为 `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`。已消除的残留问题是：`ProjectWorkflowRuntimeBridgeService` 先前私有维护一份基于 `task_type + ToolStrategyService.defaultSettings()` 的 workflow 默认候选工具排序，而 `SubAgentEffectiveExecutionProfileService` 在 child package / agent 未声明 `allowed_tool_ids` 时又私有回退到另一份 `defaultSettings()` 结果，导致默认级、项目级与运行时配置消费链随时可能各长一套默认候选工具解释；现已统一改为由同一条 runtime tool exposure 主链生成 `default candidate tool ids`，workflow bridge 与 sub-agent 两条消费链都只传上下文，不再各自补 fallback。focused validation 已覆盖 `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`packages/novel_agent_core/test/sub_agent_effective_execution_profile_service_test.dart`、`packages/novel_agent_core/test/sub_agent_execution_service_test.dart` 与 `packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart`。同时把 `FMSC-R06` 从“边界冻结”推进到“主链已统一、settings / loadout / binding consumer 待清理”，当前最早未完成 session 顺延为 `FMSC-11`。
- `FMSC-11`：已完成（2026-06-09）。本轮只收口 `FMSC-B08` 宿主壳与工作台 GUI 消费块，未开启 `FMSC-12`。主实现出口继续保持为 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`。已消除的残留问题是：workbench 信息区先前由 `WorkspaceInformationProjectionService` 直接读取 `activation_report.json` 里宿主再包装的 `selected_context_sections / omitted_context_sections`，在 GUI 侧私有维护一份“本轮已使用 / 未使用哪些资料”的轻量解释器；现已统一改为直接消费正式 `ContextActivationReport.items` 合同，让 workbench 只读取主链 activation truth，而不再依赖额外的 GUI projection metadata。focused validation 已覆盖 `apps/novel_agent_app/test/workspace_information_projection_service_test.dart`、`apps/novel_agent_app/test/resource_manager_panel_test.dart`、`apps/novel_agent_app/test/workbench_project_panel_test.dart` 与 `apps/novel_agent_app/test/workbench_workspace_controller_snapshot_test.dart`。同时把 `FMSC-R07` 从“边界冻结”推进到“主链已统一一类 workbench information usage 读法、其余 GUI consumer 待清理”，并把 `FMSC-R03` 进一步收紧为“activation report 主链已统一、workspace 其余 projection consumer 待清理”。当前最早未完成 session 顺延为 `FMSC-12`。
- `FMSC-12`：已完成（2026-06-09）。本轮只收口 `FMSC-B08` 宿主壳与工作台 GUI 消费块，未开启 `FMSC-13`。主实现出口继续保持为 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`。已消除的残留问题是：long task station 详情先前由 `LongTaskStationViewDataService` 基于 legacy `run.stopReason` 再生成一份 GUI 私有 `stopReasonLabel`，`LongTaskRunDetailPanel` 再把它展示为 `补充原因`，导致正式 `stopDiagnosis / blocker` 投影旁边又长出第二条 stop reason 人话出口；现已统一改为让长任务站只消费正式 `LongTaskStopDiagnosisProjectionService` 投影出来的 `stopDiagnosis` 与 blocker 真相，并删除该 GUI 侧补充解释链。focused validation 已覆盖 `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart` 与 `apps/novel_agent_app/test/long_task_run_detail_panel_test.dart`。同时把 `FMSC-R01` 从“GUI/CLI/probe 继续二次 stop reason 解释”进一步收紧到“CLI/probe 与其余 GUI consumer 待清理”，并把 `FMSC-R07` 推进到“workbench 与 long task station 两类 GUI shadow projection 已统一、task center / project assets consumer 待清理”。当前最早未完成 session 顺延为 `FMSC-13`。
- `FMSC-13`：已完成（2026-06-09）。本轮只收口 `FMSC-B08` 宿主壳与工作台 GUI 消费块，未开启 `FMSC-14`。主实现出口继续保持为 `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`。已消除的残留问题是：project assets 的 graph / inspector / sidebar 导航先前由 `ProjectAssetsController` 在 GUI 侧私拆 `referenceKey` 的 `kind:id` 文本规则，再自己决定应切到 `foreshadow / timeline / relationship` 哪个页签并选中哪条资产，这让共享 narrative asset reference identity 在 core `SharedNarrativeAssetReferenceIndex` 外又长出一条 app 侧解释器；现已统一改为让 controller 只消费正式 `SharedNarrativeAssetReferenceIndex.referenceByKey(...)` 返回的 `assetKind / assetId / referenceKey`，删除这条 GUI 侧 shared identity 解析链。focused validation 已覆盖 `apps/novel_agent_app/test/project_assets_controller_expression_constraint_context_test.dart` 与 `packages/novel_agent_core/test/shared_narrative_asset_reference_index_service_test.dart`。同时把 `FMSC-R07` 从“task center 与 project assets 都可能继续补宿主侧判断”进一步收紧到“主要剩余 task center consumer 待清理”。当前最早未完成 session 顺延为 `FMSC-14`。
- `FMSC-14`：已完成（2026-06-09）。本轮只收口 `FMSC-B09` CLI 与自动化消费块，未开启 `FMSC-15`。主实现出口继续保持为 `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`。已消除的残留问题是：CLI 的 `WorkflowOutputSummaryService.extractNarrativeRuntimeContract(...)` 先前会在命令侧基于 `stop_outcome / recovery_state / stop_reason / review_summary / information_summary` 再投影一份 narrative `stop_diagnosis`，即使正式 `run_center_contract.stop_diagnosis` 已经存在，也容易让 workflow 摘要层长成第二控制面；现已统一改为优先直接消费正式 `run_center_contract.stop_diagnosis`，只有共享合同缺位时才保留兼容兜底。focused validation 已覆盖 `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`、`apps/novel_agent_cli/test/workflow_command_test.dart` 与 `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`。同时把 `FMSC-R01` 从“CLI/probe 与其他 consumer 继续二次 stop reason 解释”进一步收紧到“主要剩余 probe 与 task center 等 consumer 待清理”，并把 `FMSC-R08` 从“边界冻结”推进到“workflow CLI 一类 control-plane bypass 已收口、其余命令/脚本 consumer 待继续清理”。当前最早未完成 session 顺延为 `FMSC-15`。
- `FMSC-15`：已完成（2026-06-09）。本轮只收口 `FMSC-B10 probe / regression` 同源化收口，未开启 `FMSC-16`。主实现出口继续保持为 `packages/novel_agent_adapters/test/continuous_task_control_plane_regression_suite_test.dart`。已消除的残留问题是：`apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart` 先前在 `delivery_failure / repair_required / waiting_user / manual_attention / natural_completion` 五个 mock stop 场景里直接调用 `LongTaskStopDiagnosisProjectionService.project(...)`，使 probe 自己又长出一条控制面停点解释链；现已统一改为先构造正式 `run_center_contract`，再只消费其中的 `stop_diagnosis`。同时把 `long_task_proactive_review` 的 probe 断言从旧的 `downstreamTask.depends_on` 细节检查切回生产同源的 `checkpoint_followup.review_task_ids + sourceTask.checkpoint_followup_task_ids` 合同，不再让 probe 盯底层重写细节。focused validation 已覆盖 `apps/novel_agent_app/test/long_task_stability_mock_regression_suite_test.dart` 与 `apps/novel_agent_app/test/probe_support_test.dart`。同时把 `FMSC-R09` 从“边界冻结”推进到“已清掉一类最直接的 mock probe interpreter、剩余 real/shared probe 入口待清理”，并把 `FMSC-R01` 进一步收紧到“主要剩余 shared probe support 与 task center 等 consumer 待清理”。当前最早未完成 session 顺延为 `FMSC-16`。
- `FMSC-16`：已完成（2026-06-09）。本轮按要求只做一组普通入口与一组连续任务入口的小规模真实探针，未开启 `FMSC-17`。连续任务入口 `apps/novel_agent_app/tool/real_long_task_probe.dart --stop-after-sample` 首次即 `PASS`，说明当前 sample checkpoint truth 没有暴露新的跨块故障；普通入口 `apps/novel_agent_app/tool/real_information_evidence_ordinary_probe.dart` 首次 `FAIL`，但失败归因不是 probe 侧，而是 earlier owning block `FMSC-B07` 的 runtime tool exposure 主链残留。主实现出口继续保持为 `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolver_service.dart`，并在共享合同 `packages/novel_agent_core/lib/src/workflow/continuous_task_tool_exposure_runtime_resolution.dart` 中补出正式 `visible_tool_ids`：此前 ordinary-project 入口只暴露 `default_allowed_tool_ids`，把 `requires_confirmation` research 工具整个藏掉，导致受限权限普通项目连正式 `request_external_research` 出口都看不见，模型只好退回 `present_user_options` 并生成 generic `ordinary_conversation_waiting_user_choice`。本轮已统一改为让 `ProjectWorkflowRuntimeBridgeService`、`ProjectConversationDraftRuntimeService`、`GenerateDraftUseCase` 与 `SubAgentEffectiveExecutionProfileService` 同源消费 `visible_tool_ids`，从而保留“可见但需宿主确认”的 research 工具出口，同时继续把重型提取工具 gated 在正式边界外。focused validation 已覆盖 `packages/novel_agent_core/test/continuous_task_tool_exposure_runtime_resolver_service_test.dart`、`packages/novel_agent_adapters/test/project_workflow_runtime_bridge_service_test.dart` 与 `packages/novel_agent_adapters/test/project_conversation_draft_runtime_service_test.dart`；修复后 `real_information_evidence_ordinary_probe.dart` 已从 `FAIL` 转为 `PASS`。本轮因此明确删除了一类“runtime resolution 保留了 requires-confirmation 语义，但 workflow / ordinary 入口各自把它过滤掉”的双实现风险，并确认 `FMSC-16` 已在回 owning block 修复后真正收口。当前最早未完成 session 顺延为 `FMSC-17`。
- `FMSC-17`：已完成（2026-06-09）。本轮严格只做 `Productization / Audit`，未开启 `FMSC-18`。本轮正式主实现出口不是新的 GUI / CLI / probe / fallback 代码入口，而是 `docs/full-module-sweep-module-audit-ledger-2026-06-09.md` 与 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中的发布面残留分级记录。已收口的残留问题是：项目当前残留已从“研究型 backlog”重排为“接近可发布的软件”视角，并明确分成三层。`必须修` 只保留两类正式发布阻断：其一是 `FMSC-B01 / FMSC-B02 / FMSC-B03` 交界上的真实 provider 长任务稳定性仍未闭环，证据来自 `docs/release-readiness-final-closeout-2026-06-05.md` 与 `docs/real-provider-regression-report-2026-06-05.md` 中的缺章、失败后继续推进与早期停滞记录；其二是 Android 分发面仍使用 `apps/novel_agent_app/android/app/build.gradle.kts` 中的示例 `applicationId = "com.example.novel_agent_app"` 与 debug signing，这阻断正式对外分发准备。`可延后` 明确归位为 CLI 迁移壳与 `session` 子命令边界、task center 作为仍保留的次级运维消费面、以及 remaining real/shared probe cleanup；`纯优化` 则归位为 DPI/真机视觉回归、OSS 中文字体资产与 CLI 文档/帮助打磨。本轮因此删除了一类“发布验收时把外围消费层、探针清理、包装缺口和真实主链阻断混成一锅并让多个会话同时开修”的协作风险，并把当前最早未完成 session 顺延为 `FMSC-18`。
- `FMSC-18`：已完成（2026-06-09）。本轮严格只做 `Documentation / Handoff`，未再开启任何新的实现块。主实现出口继续落在 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 与 `docs/important/full-module-sweep-collaboration-goal-prompt-2026-06-09.md` 两份交接文档；`agent.md` 不再额外回写，是因为本轮沉淀出的长期约束已经在 `6.11 协作就绪分块与防双实现约束`、`10.1 探针与真实接口脚本规则`、`10.2 项目整洁性维护规则` 中正式存在。已收口的残留问题是：`FMSC-01 ~ FMSC-17` 的完成记录、主出口、残留分级与后续接力口径现在都集中回到唯一正式文档，不再需要靠对话上下文猜“现在到底该接哪一块”。本轮已消除的双实现风险是：后续会话不会再把“继续做 FMSC 总巡检”和“开始修发布阻断”混成同一任务，也不会因为目标文档缺少收官提示而重新从 `FMSC-01` 或中途任意块并行重开。至此，`FMSC` 主线 `01 ~ 18` 全部完成。

---

## 11. FMSC 收官后的接力提示

`FMSC` 主线到这里已经完成，其职责是：

1. 把模块台账化。
2. 把双实现风险台账化。
3. 冻结各块主实现出口。
4. 串行清掉一批高风险残留。
5. 把剩余发布面问题明确降到可接手的后续清单。

后续会话默认**不要**再从 `FMSC-01` 重跑，除非未来出现新的跨块架构漂移，足以证明需要重新开一轮全模块 sweep。

### 11.1 默认接力顺序

1. 如果目标是兑现“稳定自主长任务写作”产品承诺，先处理 `FMSC-B01 / FMSC-B02 / FMSC-B03` 交界上的真实 provider 长任务稳定性阻断。
2. 如果目标是正式 Android 分发，再处理 `apps/novel_agent_app/android/app/build.gradle.kts` 的 `applicationId / signingConfig` 缺口。
3. `task center`、CLI 迁移壳与 remaining probe cleanup 默认继续视为后续消费者治理项，不得抢到前两类阻断之前。

### 11.2 接手时必须继续遵守

1. 同一能力块同一时间只能有一个正式主实现出口和一个主负责会话。
2. 如果问题跨块，先抽共享合同，再串行落地。
3. 不允许在 `core / adapter / viewmodel / probe / fallback` 各补一份近似逻辑。
4. 不允许为了“先跑通”让 GUI、脚本或 probe 重新变成业务中心。

### 11.3 推荐的后续提示词

```text
基于 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 已完成记录、`docs/full-module-sweep-module-audit-ledger-2026-06-09.md` 的发布面残留分级，以及 `agent.md` 的协作防双实现约束，只处理当前最高优先级的正式残留块。先确认当前最重要的是不是 `FMSC-B01 / FMSC-B02 / FMSC-B03` 的真实 provider 长任务稳定性；如果是，就只沿这些块的正式主实现出口和共享合同推进，不改 GUI、CLI、probe 消费层，不并行开启第二块。完成后更新对应台账与 focused validation 结果，并说明主出口、已消除的残留问题和仍保留的降级项。
```
