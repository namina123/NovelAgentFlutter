# 长任务稳定性、监督层与审稿修复主线交接说明

日期：2026-06-07

适用主线：

- `docs/long-task-stability-supervisor-review-session-order-2026-06-06.md`

---

## 1. 当前完成状态

1. `LTSR-01` 到 `LTSR-26` 已完成。
2. 本主线已经把长任务稳定性从“宿主各自拼文案和停点判断”收口到共享 contracts、runtime truth、probe truth 与最小 GUI/CLI 消费链。
3. 当前 GUI/CLI 仍然是稳定合同的最小消费面，不是新的业务中心。

---

## 2. 现在如何查看长任务现场

GUI：

1. `长任务总站`
   - 看跨项目运行实例、停点结论、待确认事项、最近审稿/检查点/返工结果。
2. `工作台项目面板`
   - 看当前项目的长任务摘要卡片、停点标题、诊断正文、下一步和最近明细。
3. `任务中心`
   - 看 run center 摘要、恢复现场、checkpoint/revision 上下文动作和最近长任务运行记录。

CLI：

1. `workflow` 命令的共享结果输出会自动打印：
   - `长任务现场摘要`
   - `开放叙事摘要`
2. 这些摘要只消费 `run_center_contract / stop_diagnosis / checkpoint review / information summary`，不再自己重建停点判断。

---

## 3. 现在如何做最小人工动作

GUI：

1. 长任务总站可直接：
   - `暂停`
   - `继续推进`
   - `停止`
   - 打开当前任务
   - 打开最近正文 / 审稿 / 检查点 / 返工结果
   - 对 pending research 做 `确认 / 拒绝`
2. 任务中心可直接执行：
   - checkpoint action package 里已经物化到宿主的共享动作
   - revision resolution 里已经物化到宿主的共享动作
   - `接受修复 / 回滚修复 / 暂停 / 恢复`

CLI：

```powershell
dart run bin/novel_agent_cli.dart workflow pause --project <project_root>
dart run bin/novel_agent_cli.dart workflow resume --project <project_root>
dart run bin/novel_agent_cli.dart workflow checkpoint-actions --review tracking/checkpoint_reviews/xxx.json --project <project_root>
dart run bin/novel_agent_cli.dart workflow apply-checkpoint-action --review tracking/checkpoint_reviews/xxx.json --command create_followup_review_tasks --project <project_root>
dart run bin/novel_agent_cli.dart workflow revision-resolution --task tasks/xxx.json --project <project_root>
dart run bin/novel_agent_cli.dart workflow apply-revision-resolution --task tasks/xxx.json --command accept_revision --project <project_root>
dart run bin/novel_agent_cli.dart workflow accept-revision --task tasks/xxx.json --project <project_root>
dart run bin/novel_agent_cli.dart workflow rollback-revision --task tasks/xxx.json --project <project_root>
dart run bin/novel_agent_cli.dart workflow pending-research list --project <project_root>
dart run bin/novel_agent_cli.dart workflow pending-research approve --request research_request_xxx --project <project_root>
dart run bin/novel_agent_cli.dart workflow pending-research reject --request research_request_xxx --project <project_root>
```

说明：

1. `checkpoint-actions / apply-checkpoint-action / revision-resolution / apply-revision-resolution` 都只走共享 runtime service。
2. CLI 不直读底层存储，不在命令层重写一套停点或动作判断。

---

## 4. 如何跑回归

mock 回归：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_long_task_stability_supervisor_review_mock_regression_suite.ps1
```

已存在的收口文档：

1. `docs/long-task-stability-supervisor-review-mock-regression-suite-2026-06-07.md`
2. `docs/long-task-stability-supervisor-review-real-probe-validation-2026-06-07.md`
3. `docs/long-task-stability-supervisor-review-real-probe-backfill-audit-2026-06-07.md`

真实探针约束：

1. 必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`
2. 默认配置来自 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE`
3. 产物写到 `artifacts/`
4. 没有新的明确验收目标时，不为了“顺手确认一下”扩大预算重跑长链

---

## 5. 后续维护不要回退的约束

1. `stop_diagnosis / run_center_contract / repair lane / review contract` 已经是正式 truth，GUI/CLI/probe 只能消费，不要再各写一套 reason 文案表。
2. `watchdog` 只做 heartbeat / stale / orphan runtime health；`supervisor` 只做结构结果调度，不要重新揉回一个大类。
3. checkpoint/revision/pending research 动作必须继续经由共享 runtime 或 action service，不要让 GUI/CLI 直接改底层记录。
4. 工作台、总站、任务中心可以继续扩展示层，但不要把 widget/page 重新变成业务规则中心。
5. probe 只能驱动 production chain 并读取 production truth，不要新增第二套停点判定。

---

## 6. 剩余风险与下一阶段边界

当前剩余风险主要是“覆盖范围边界”，不是本主线未完成：

1. GUI/CLI 目前是最小控制面，不是完整专家控制台。
2. 短真实 probe 已验证 `success / waiting_user`，但没有为了凑齐分类强造更大预算失败样本。
3. 未来若要扩更强的批量治理、长链真实预算压测或更丰富的 artifact 浏览，应单独开新主线，不回头重开 `LTSR-01 ~ LTSR-26`。
