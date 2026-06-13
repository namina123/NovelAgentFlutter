# 全模块巡检、协作防双实现与逐块收口目标提示

适用时间：2026-06-09 之后  
用途：给新会话直接开启目标模式使用  

当前状态补充：

1. `FMSC` 主线 `01 ~ 18` 已于 `2026-06-09` 全部完成。
2. 本文档保留为历史主线启动提示与后续接手参考，不代表后续会话应再从 `FMSC-01` 重跑整轮 sweep。
3. 后续若无新的跨块架构漂移，应直接从 `docs/full-module-sweep-collaboration-session-order-2026-06-09.md` 中 `FMSC 收官后的接力提示` 接下一条正式残留，而不是再开平行 sweep。

最高优先级执行文档：

- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`

关联分析与约束：

- `docs/important/full-module-sweep-collaboration-chunking-analysis-2026-06-09.md`
- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`
- `agent.md`

---

## 1. 直接可用的总提示词

把下面整段作为目标模式提示直接使用：

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

## 2. 推荐的一句 objective

如果需要压缩成目标工具的一句 objective，推荐：

```text
以 docs/full-module-sweep-collaboration-session-order-2026-06-09.md 为最高优先级执行文档，对当前项目做一次全模块巡检与逐块收口：先建立模块审计台账、重复实现风险台账和主实现出口边界，再按稳定能力块一次只收口一个 session，持续清除残留问题并防止协作时同一逻辑长出双实现。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应算完成：

1. 只是又补了一份分析，没有建立台账。
2. 只是分目录，不是按稳定能力块分块。
3. 同一个问题在不同层各补了一份实现，但都没删。
4. 只是把旧链标成 deprecated，却没有明确主链和移除计划。
5. 只是修了显眼 bug，却没有消除双实现风险。
6. 只是跑过 probe，但 probe 还在复制 production 判断。
7. 只是 GUI 看起来顺了，但实际仍在消费拼接真相。

---

## 4. 收官后的使用方式

如果后续仍引用本文档，默认应按下面方式使用：

1. 先确认 `FMSC` 是否真的已经完成。
2. 如果已完成，不再从 `FMSC-01` 重新开启 sweep。
3. 直接回到：
   - `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`
   - `docs/full-module-sweep-module-audit-ledger-2026-06-09.md`
   - `docs/full-module-sweep-duplicate-implementation-risk-ledger-2026-06-09.md`
4. 仅围绕当前仍保留的正式残留块继续推进。
