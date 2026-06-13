# RRP-06 长任务 Mock Probe 说明

最后更新：2026-06-05

## 1. 目的

这条 mock probe 是 `RRP-06` 的稳定回归入口，用来在不消耗真实 provider 额度、不联网、不走 GUI 真交互的前提下，验证长任务链路已经开始通过 production 同源合同消费：

1. `writing_execution_result`
2. `LongTaskWritingExecutionSignalService`
3. `LongTaskRecoveryService`
4. `LongTaskSchedulerTickPlanService`
5. `LongTaskSupervisor`
6. `ProjectWorkflowRuntimeService`

## 2. 运行入口

推荐入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_release_readiness_long_task_mock_probe.ps1
```

也可以直接运行 Dart 脚本：

```powershell
dart run apps/novel_agent_app/tool/mock_long_task_probe.dart
```

## 3. 输入输出合同

输入：

1. 不需要真实 key。
2. 不读取 `local/probe_api.txt`。
3. 只依赖仓库内 production 代码和本地临时 artifacts 工作区。

输出：

1. `artifacts/mock_long_task_probe_workspace/<timestamp>/mock_long_task_probe_report.json`
2. `artifacts/mock_long_task_probe_workspace/<timestamp>/mock_long_task_probe_report.md`

报告至少包含：

1. scenario id
2. layer
3. report category
4. shared signal category
5. overall status
6. summary / next action

## 4. 当前覆盖场景

1. `normal_chapter_success`
   验证正常章节交付可以落成 `success`。
2. `empty_body_recoverable`
   验证空正文交付会进入共享 recoverable 分类，而不是被当成成功。
3. `title_only_quality_failure`
   验证标题-only 会进入内容质量失败分类。
4. `severe_word_count_constraint`
   验证严重字数偏离会通过共享约束合同进入内容质量失败分类。
5. `information_waiting_user`
   验证 information 等待确认会进入共享 waiting_user 分类。
6. `supervisor_budget_recovery`
   验证预算边界会进入 `budget_failed` / `resume_dispatch` 恢复路径。
7. `supervisor_shared_state_consumption`
   验证 supervisor 能消费共享写作结果并把运行实例推到人工复核状态。
8. `technical_failure_classification`
   验证 transport / failed-task 类失败会进入技术失败分类。

## 5. 使用规则

1. 这条 probe 只消费 production 同源合同，不在 probe 层复写业务判定。
2. 如果失败，优先看报告里的 `report_category`、`signal_category`、`overall_status` 和 `next_action`。
3. 如果 mock probe 已失败，不要先开真实 provider probe；先修 core/runtime 合同链路。
