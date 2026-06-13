# 连续任务控制面与参考基底总目标提示

适用时间：2026-06-08 之后  
用途：给新会话直接开启目标模式使用  
主任务顺序文档：

- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`

关联分析文档：

- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `agent.md`

---

## 1. 直接可用的总提示词

把下面整段作为目标模式提示直接使用：

```text
请以 `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md` 作为本轮唯一的主任务顺序文档，并同时严格遵守：

- `docs/important/task-liveness-and-strategy-layer-supplement-analysis-2026-06-08.md`
- `docs/important/harry-potter-reference-audit-and-watchdog-analysis-2026-06-08.md`
- `docs/important/reference-ingestion-budget-and-batch-architecture-analysis-2026-06-08.md`
- `docs/important/reference-extraction-runtime-sweep-analysis-2026-06-08.md`
- `docs/important/reference-extraction-agent-architecture-analysis-2026-06-07.md`
- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `agent.md`

你的目标不是自由发挥，而是严格按 `CTRS-01` 到文档末尾的顺序推进这条主线，每次只完成一个 session，并在完成后停在当前 session，不抢跑下一任务。

必须遵守以下总原则：

1. 这条主线解决的是“连续任务控制面 + 参考基底收口”，不是单一 bug 修补。
2. 不允许再造平行 runtime、平行 supervisor、平行挂载链、probe-side 真相链。
3. `watchdog` 不是长任务专属；它服务所有连续任务族，包括长篇写作、目标模式、参考提取、研究整编等。
4. 参考提取当前没写成 sqlite，首先是挂载出口与持久化目标问题，不是简单缺少某个 toolcall。
5. 重型提取工具默认应绑定提取/研究智能体组，并通过暴露策略受控开放；不要把整套提取工具默认铺给普通写作线程。
6. 参考提取默认保持单并发主链，不把多并行做成默认实现。
7. 连续性冲突必须保留证据并进入项目决议链，不要简单覆盖旧事实，也不要把这类语义判断塞进 `watchdog`。
8. `md` 投影应回到轻摘要与人工校对入口，不再承担结构化事实源镜像。
9. GUI / CLI 只在稳定合同完成后消费，不承担底层设计补丁职责。
10. 全程遵守解耦合、单一职责、避免单文件过重、focused tests/contract tests/regression 同步落地的工程纪律。

执行方式要求：

1. 从 `CTRS-01` 开始，按顺序推进。
2. 每轮先检查前一 session 是否真的完成；若仍有半完成、断裂、验收未过或相关错误，先在当前轮补齐这些尾项。
3. 每次只确认完成一个 session，不开启下一轮。
4. 只有在当前 session 的目标、验收标准、不要做事项都满足后，才可认定该 session 完成。
5. 任何 real probe、focused probe、mock regression 都必须消费 production 同源合同，不准另写 probe-side 业务判断。
6. 如果某轮无法安全推进，明确记录阻断点、剩余边界与原因，不得粉饰为已完成。

本轮最终成功标志不是“写了很多代码”，而是：

1. 连续任务控制面真正泛化到所有连续任务族。
2. 参考提取挂载链真正朝 sqlite-first 收口。
3. 来源身份、轻投影、工具暴露策略、预算/分批/覆盖状态、连续性冲突决议都进入稳定合同。
4. focused tests、regression、real probe 对这些主线给出真实证据。
5. GUI / CLI 至少有最小稳定消费入口，而不是继续把业务判断塞在表层。

请现在按主任务顺序文档从第一个未完成的 session 开始执行，并严格在每轮结束时只汇报当前 session 的完成情况、修改内容、验证结果和是否可进入下一 session。
```

---

## 2. 推荐的一句 objective

如果需要压缩成目标工具的一句 objective，推荐：

```text
依照 docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md 按序完成 CTRS 主线：把 watchdog/supervisor 泛化为所有连续任务族共享控制面，将参考提取从 sqlite substrate + json 挂载 + 重 md 投影的半收口状态推进到 sqlite-first、source-identity-first、projection-lightweight 的稳定主链，并通过 focused tests、regression 与真实提取/消费验证其可用性。
```

---

## 3. 不应被当作完成的假信号

以下情况都不应算完成：

1. 只是新增文档，没有真实改 runtime / persistence / projection / tool exposure 主链。
2. 只是把“watchdog 适用于提取任务”写成注释，没有正式 profile 与 runtime 接线。
3. 只是保留了 sqlite substrate，但项目挂载出口仍默认写向 `.novel_agent/information/*.json`。
4. 只是把来源显示文案换了，但主来源身份仍依赖绝对本地路径。
5. 只是给写作智能体多加几个提取 toolcall，而没有建立提取组与暴露策略。
6. 只是跑了 probe，没有把 focused tests 与 production 同源 regression 收口。
7. 只是让 GUI / CLI 多显示几行字，但底层合同仍未稳定。
