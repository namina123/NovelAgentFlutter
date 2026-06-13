# 表达限制执行策略交接说明

日期：2026-06-06

适用范围：`ECP-18` 收口后的后续接手会话。

## 1. 当前完成状态

1. `ECP-01` 到 `ECP-18` 已完成。
2. 其中 `ECP-17` 采用了 mock fallback，不是短真实探针。
3. 当前可以继续做“显式开闸后的短真实探针验证”，但不建议直接进入更大预算长任务真实验证。

## 2. 三档策略如何配置

当前用户侧策略统一为：

1. `关闭`
   - 内部对应 `disabled`
   - 本次运行不主动注入表达限制，也不要求表达限制 review
2. `智能使用`
   - 内部对应 `adaptive`
   - 默认推荐档，会按任务类型、阶段与最近风险信号自动调节注入和处置
3. `强力约束`
   - 内部对应 `force`
   - 对用户可见文本强执行，但仍排除工具协议、路径、研究执行和纯技术轮次

GUI 入口：

- 项目资产页的表达规则/表达限制设置区域

CLI 摘要入口：

- `apps/novel_agent_cli` 的 workflow summary 输出

## 3. 报告怎么看

重点看四类信息：

1. `policy mode / injection strength / review requirement`
2. `review provided / evidence missing / risk signals / disposition`
3. `path resolution / chapter title normalization`
4. `stop reason / stop diagnosis`

常用产物位置：

1. mock 表达限制探针：
   - `artifacts/mock_expression_constraint_policy_probe_workspace/<timestamp>/`
2. mock 长任务探针：
   - `artifacts/mock_long_task_probe_workspace/<timestamp>/`
3. 真实 GUI/长任务探针最新报告：
   - `artifacts/real_gui_viewmodel_information_long_task_probe_report.json`
   - `artifacts/real_gui_viewmodel_information_long_task_probe_report.md`

本轮已确认的最新 mock 产物：

1. `artifacts/mock_long_task_probe_workspace/2026-06-06T17-35-48-344775/`
2. `artifacts/mock_expression_constraint_policy_probe_workspace/2026-06-06T17-35-58-309199/`

## 4. 如何运行验证

mock 回归：

```powershell
powershell -File tools/run_expression_constraint_policy_mock_regression_suite.ps1
```

短真实探针前置条件：

1. `local/probe_api.txt` 已配置，或设置 `NOVEL_AGENT_PROBE_API_FILE`
2. 显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`
3. 明确允许真实计费调用

短真实探针入口：

```powershell
dart run apps/novel_agent_app/tool/real_general_novel_probe.dart
dart run apps/novel_agent_app/tool/real_gui_viewmodel_information_long_task_probe.dart
```

建议顺序：

1. 先跑 ordinary project 3 到 5 章
2. 再跑 long task 10 到 20 章
3. 必要时补 `disabled / force` 小样本

## 5. 下一步建议

下一轮优先做：

1. 显式开闸后的短真实探针
2. 人工复核真实产物里的章节路径、标题、review 证据和 stop reason

暂不建议直接做：

1. 更大预算真实长跑
2. 新一轮 GUI/CLI 扩张
3. 为探针结果新增临时补丁分支
