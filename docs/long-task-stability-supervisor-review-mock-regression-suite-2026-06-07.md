# Long Task Stability Supervisor Review Mock Regression Suite

最后更新：2026-06-07

## 1. 目的

这套 mock regression suite 是 `LTSR-20` 的一键回归入口，用来在不触发真实 provider、不联网、不改 GUI 的前提下，围绕 production contracts 复核长任务稳定性主链没有回退。

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_long_task_stability_supervisor_review_mock_regression_suite.ps1
```

规则：

1. 只跑 `flutter test`、`dart run` 和本地 mock probe。
2. 不访问真实 API，不读取真实 key。
3. 如果失败，优先看 structured report 和 production contracts，不在 probe 层补私有业务判断。

## 2. 覆盖矩阵

### 2.1 LTSR-20 主链必需场景

1. `ordinary_project_self_review`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   - `apps/novel_agent_app/tool/mock_long_task_stability_regression_suite.dart`
   说明：
   普通项目 review 任务在没有 reviewer-like child 时，必须稳定落到共享 `reviewer_dispatch` 的主写自审回退，而不是丢失 reviewer selection contract。

2. `reviewer_dispatch`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   review 任务存在 reviewer child 时，必须显式委派到 reviewer child，并保留 `execution.reviewer_dispatch`。

3. `long_task_proactive_review`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   long-task checkpoint 必须能主动插入 follow-up review gate，并把下游依赖改挂到 review 门上。

4. `delivery_failure`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   路径或交付失败必须通过 `writing_execution_result -> long_task_stop_outcome -> stop_diagnosis` 落到正式 `delivery_failure`。

5. `repair_required`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   shared `review_contract` 必须能稳定映射到 blocking repair handoff，而不是只留 note 或 report-only artifact。

6. `waiting_user`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   真实用户确认等待必须通过正式 `waiting_user` taxonomy 暴露，而不是继续混进 generic recoverable failure。

7. `manual_attention`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   需要人工处理的停点必须与 `waiting_user` 分离，并通过 `stop_diagnosis` 输出。

8. `natural_completion`
   对应：
   - `apps/novel_agent_app/tool/long_task_stability_mock_regression_suite_support.dart`
   说明：
   正常收尾必须稳定投影为 `completed_naturally`，不能回退成弱结构 `completed` 字符串猜测。

### 2.2 既有 mock probe 回归

1. `long task shared runtime / supervisor / waiting / budget / technical failure`
   对应：
   - `apps/novel_agent_app/tool/mock_long_task_probe.dart`

2. `expression constraint / ordinary runtime / path / exclusion / waiting`
   对应：
   - `apps/novel_agent_app/tool/mock_expression_constraint_policy_probe.dart`

3. `probe-side production truth classification`
   对应：
   - `apps/novel_agent_app/test/probe_support_test.dart`

## 3. 报告怎么读

`mock_long_task_stability_regression_suite.dart` 会输出：

1. `artifacts/mock_long_task_stability_regression_suite_workspace/<timestamp>/mock_long_task_stability_regression_suite_report.json`
2. `artifacts/mock_long_task_stability_regression_suite_workspace/<timestamp>/mock_long_task_stability_regression_suite_report.md`

结构化报告至少包含：

1. `required_coverage`
2. `scenario id / layer / production_contracts`
3. `observed_category`
4. `summary`

解读顺序：

1. 先看 `all_required_coverage_passed`。
2. 再看失败 scenario 对应的 `production_contracts`。
3. 如果是 `delivery_failure / waiting_user / manual_attention / natural_completion` 偏差，优先看 `writing_execution_result / long_task_stop_outcome / stop_diagnosis`。
4. 如果是 `ordinary_project_self_review / reviewer_dispatch` 偏差，优先看 `execution.reviewer_dispatch` 和 review runtime。
5. 如果是 `long_task_proactive_review` 偏差，优先看 checkpoint review record、follow-up task materialization 和下游依赖重挂。

## 4. 与下一轮 real probe 的关系

1. 这套 suite 通过后，才应该继续 `LTSR-21` 的 gated short real probe。
2. 如果这套 suite 失败，先修 production contracts、runtime 接线或 review/repair handoff，不要在 probe 层补第二套业务真相。
