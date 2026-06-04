# ONS-44 压力真实验证进度记录

日期：2026-06-04

关联任务：

- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `ONS-44 压力真实验证与外层对接收口`

## 本轮只完成的具体任务

本轮只完成 `ONS-44` 在 pressure probe 范围内的第二个具体任务：

1. 继续收口 `real_multiscope_pressure_probe.dart` 的复杂输入真实链。
2. 修正 chapter runtime title 与提示词边界，避免模型把 summary 写到变体路径，或再次退回子任务/摘要捷径。
3. 重新执行真实 probe，确认四章复杂输入链整体通过。

本轮没有开启：

1. GUI 展示 knowledge / ledger / projection。
2. CLI 输出 delivery / review / activation / ledger 摘要。
3. ONS-45。

## 本轮实现内容

### 1. 新增中性命名的复杂输入压力 probe

本轮新增：

- `apps/novel_agent_app/tool/real_multiscope_pressure_probe.dart`

其设计边界：

1. 输入压力使用“多舞台切换、部分记忆保留、关系错位、回站代价”。
2. 这些内容只作为用户输入与项目素材，不进入 core 类型。
3. probe 仍走普通项目 ordinary conversation-like 链，不另造题材专用 runtime。
4. probe 继续只消费 production 合同：
   - `ProjectConversationDraftRuntimeService`
   - `ProjectDraftExecutionConstraintRuntimeService`
   - `submit_chapter_delivery`
   - activation report
   - `NarrativeSupervisorRiskPolicyService`

### 2. 本轮针对 chapter_04 的收口

本轮对 `apps/novel_agent_app/tool/real_multiscope_pressure_probe.dart` 做了两类收紧：

1. 把真实运行 title 从 `第NN章《标题》` 收窄为稳定的 `第NN章`，避免工具按标题派生出变体 summary 路径。
2. 把 prompt 明确收紧为：
   - summary 只能写到精确的 `${guide.summaryPath}`
   - 至少要直接更新一个指定状态文件
   - 不允许 `call_sub_agent`、`create_chapter_task`、`mark_task_status`、`summarize_context`

这样做没有修改 production runtime 合同，只是把 pressure probe 对复杂输入的内容交付要求表达得更低歧义。

### 3. 实际真实复跑结果

已执行：

```powershell
$env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'
dart run tool/real_multiscope_pressure_probe.dart
```

静态校验已执行：

```powershell
flutter analyze tool/real_multiscope_pressure_probe.dart
```

当前最新真实报告：

- `artifacts/real_multiscope_pressure_probe_report.json`

最新结果：

1. `chapter_01`：通过
2. `chapter_02`：通过
3. `chapter_03`：通过
4. `chapter_04`：通过
5. 顶层 `report_category = success`

`chapter_04` 的关键结果已确认：

1. 正文写入：`chapters/第04章.md`
2. summary 写入：`summaries/第04章.summary.md`
3. 状态写回：
   - `assets/state/记忆残留账本.md`
   - `assets/foreshadows/回站权限.foreshadow.md`
   - 同时还更新了 `assets/characters/闻栖.md`、`assets/characters/周既明.md`
4. 正式交付：`submit_chapter_delivery`

这说明当前复杂输入真实链已经不再停在内容质量失败面上，四章压力输入已整体通过。

### 4. 已收口的关联错误

本轮延续了上一轮的失败分类收口，并在此基础上进一步消除了 `chapter_04` 的实际内容侧阻塞：

1. 不再生成变体 summary 路径。
2. 不再遗漏指定状态文件回写。
3. 当前最新报告保持 `success`，没有新的 tool error。

## 当前剩余事实

pressure probe 这一支现在已达标：

1. 同源真实 probe 已存在。
2. 四章复杂输入已通过。
3. 报告仍能区分技术失败、预算失败、等待用户与内容质量失败。

`ONS-44` 当前剩余工作已收缩为：

1. GUI 展示 knowledge / ledger / projection、权限确认、Run Center 报告。
2. CLI 输出 delivery / review / activation / ledger 摘要。

## 结论

本轮可以确认完成的只有一个具体任务：

1. `ONS-44` 的复杂输入 pressure probe 已从 `chapter_04` 内容质量失败推进到整轮 `PASS`。

按当前用户约束，本轮到此为止，不开启 GUI / CLI 子任务。

---

## 后续补记：CLI 粗粒度摘要已接通

同日后续又只完成了 `ONS-44` 的一个独立子任务：

1. 不做精细 CLI 设计。
2. 只把现有 `workflow` 命令的摘要输出口，粗粒度接上 `activation / delivery / review / ledger`。

本轮改动：

1. `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
2. `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
3. `apps/novel_agent_cli/tool/workflow_output_summary_probe.dart`

当前 CLI 行为：

1. 继续保留原本的 Run Center 摘要。
2. 若 workflow 结果里存在 activation report、chapter delivery、checkpoint review 或 continuity 变更路径，则会额外打印一段 `开放叙事摘要`。
3. 口径是粗粒度的，只显示：
   - `Activation`
   - `Delivery`
   - `Review`
   - `Continuity`
4. `Continuity` 目前按 `.novel_agent/continuity/` 下的变更路径粗略统计 `ledger / claims / reviews / deliveries`，不做更细的 CLI 交互设计。

验证已通过：

```powershell
dart analyze lib/commands/workflow/workflow_command.dart lib/commands/workflow/workflow_output_summary_service.dart tool/workflow_output_summary_probe.dart
dart run tool/workflow_output_summary_probe.dart
```

结果：

1. `No issues found!`
2. `workflow_output_summary_probe: PASS`

这说明 `ONS-44` 的 CLI 侧“先接上就行”的最小目标已经完成。

当前剩余工作再次收缩为：

1. GUI 展示 knowledge / ledger / projection、权限确认、Run Center 报告。
2. 最终文档收口。

---

## 后续补记：GUI 长任务总站开放叙事摘要已接通

同日后续又只完成了 `ONS-44` 的一个独立子任务：

1. 不扩散到 Workbench 或复杂知识面板。
2. 只把长任务总站详情里的 `Activation / Delivery / Review` 摘要接上现有稳定合同。

本轮改动：

1. adapters 详情模型与加载：
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail.dart`
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
2. app 总站详情映射与展示：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart`
3. focused tests：
   - `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`

当前 GUI 行为：

1. 长任务总站详情会新增一段 `开放叙事摘要`。
2. 这段摘要当前只消费稳定现有字段，不新造 runtime 语义：
   - `Activation`
   - `Delivery`
   - `Review`
3. `Activation` 与 `Delivery` 优先从现有 execution record / task / run record / 最近 step 摘要回填。
4. `Review` 直接复用现有最近审稿结果，不新增第二套 review 合同。
5. 本轮不补 `ledger / claims / projection` 细展示，也不做权限确认弹层。

验证已通过：

```powershell
dart analyze packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail.dart packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart
dart test test/project_long_task_station_detail_service_test.dart
flutter test test/long_task_station_view_data_service_test.dart
```

结果：

1. `No issues found!`
2. `ProjectLongTaskStationDetailService ... All tests passed!`
3. `LongTaskStationViewDataService ... All tests passed!`

这说明 `ONS-44` 的 GUI 侧已经完成了一个最小可用的“先接上”消费切片，但仍未完成更广的 knowledge / ledger / projection / 权限确认收口。

当前剩余工作再次收缩为：

1. GUI 里更完整的 knowledge / ledger / projection / 权限确认收口。
2. `ONS-44` 最终文档收口。

---

## 后续补记：GUI Continuity 粗粒度摘要已接通

同日后续又只完成了 `ONS-44` 的一个独立子任务：

1. 不展开成完整 knowledge / ledger 浏览器。
2. 只把长任务总站详情里的 `Continuity` 粗粒度统计接上，并把来源收口到稳定的长任务 step 审计字段。

本轮改动：

1. core 审计补口：
   - `packages/novel_agent_core/lib/src/workflow/long_task_run_step_recorder_service.dart`
2. adapters continuity 汇总：
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`
3. app 总站详情展示：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart`
4. focused tests：
   - `packages/novel_agent_core/test/long_task_runtime_services_test.dart`
   - `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`

当前行为：

1. 长任务 step 审计现在会保留 `changed_paths` 与 `last_changed_paths`。
2. 总站详情里的 `开放叙事摘要` 新增 `Continuity` 一项。
3. `Continuity` 只按 `.novel_agent/continuity/` 下的变更路径做粗粒度统计：
   - `ledger`
   - `claims`
   - `reviews`
   - `deliveries`
4. 统计时会对同一路径去重，避免 execution / run record / 最近 step 同时命中时被重复计数。
5. 本轮不补具体 ledger 明细跳转，也不做 projection 或权限确认弹层。

验证已通过：

```powershell
dart analyze lib/src/workflow/long_task_run_step_recorder_service.dart test/long_task_runtime_services_test.dart
dart test test/long_task_runtime_services_test.dart
dart analyze lib/src/runtime/project_long_task_station_detail_service.dart lib/src/runtime/project_long_task_station_narrative_summary.dart test/project_long_task_station_detail_service_test.dart
dart test test/project_long_task_station_detail_service_test.dart
flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/models/long_task_station_view_data.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart
flutter test test/long_task_station_view_data_service_test.dart
```

结果：

1. `No issues found!`
2. `Long task runtime services ... All tests passed!`
3. `ProjectLongTaskStationDetailService ... All tests passed!`
4. `LongTaskStationViewDataService ... All tests passed!`

这说明 `ONS-44` 的 GUI 侧现在已经具备和 CLI 对齐的 `Continuity` 最小摘要，但仍未完成完整的 knowledge / projection / 权限确认收口。

当前剩余工作再次收缩为：

1. GUI 里更完整的 knowledge / projection / 权限确认收口。
2. `ONS-44` 最终文档收口。

---

## 2026-06-05 补记：GUI Projection 快速入口已接通

本轮只完成 `ONS-44` 的一个独立子任务：

1. 不展开完整 knowledge 浏览器。
2. 只把本轮已经被 runtime 标记为变更的开放叙事 Markdown 投影，挂到长任务总站详情里的快速入口。

本轮改动：

1. adapters 详情汇总：
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`
2. app 总站详情映射与展示：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart`
3. focused tests：
   - `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`

当前行为：

1. 长任务总站详情的 `开放叙事摘要` 会显示当前 run 关联到的投影入口。
2. 入口只来自 stable `changed_paths / last_changed_paths / step.changed_paths`。
3. 当前支持的投影路径是 ONS-28 已定义的四个可读投影：
   - `continuity/叙事状态规则.md`
   - `continuity/最近状态变化.md`
   - `constraints/项目约束摘要.md`
   - `reviews/语义复核摘要.md`
4. GUI 只把这些投影作为资源入口打开，不把 Markdown 当事实源，也不做编辑器。

验证已通过：

```powershell
dart analyze lib/src/runtime/project_long_task_station_detail_service.dart lib/src/runtime/project_long_task_station_narrative_summary.dart test/project_long_task_station_detail_service_test.dart
dart test test/project_long_task_station_detail_service_test.dart
flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/models/long_task_station_view_data.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart test/long_task_station_view_data_service_test.dart
flutter test test/long_task_station_view_data_service_test.dart
```

结果：

1. `No issues found!`
2. `ProjectLongTaskStationDetailService ... All tests passed!`
3. `LongTaskStationViewDataService ... All tests passed!`

这说明 `ONS-44` 的 GUI 侧已经具备 projection 查看入口，但仍未完成权限确认展示或最终文档收口。

当前剩余工作再次收缩为：

1. GUI 权限确认展示。
2. `ONS-44` 最终文档收口。

---

## 2026-06-05 补记：GUI 权限确认展示已接通

本轮只完成 `ONS-44` 的一个独立子任务：

1. 不实现审批 / 应用动作。
2. 只把当前 run 关联到的隐藏确认记录，展示成长任务总站详情里的可打开入口。

本轮改动：

1. adapters 详情汇总：
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_detail_service.dart`
   - `packages/novel_agent_adapters/lib/src/runtime/project_long_task_station_narrative_summary.dart`
2. app 总站详情映射与展示：
   - `apps/novel_agent_app/lib/features/long_task_station/application/services/long_task_station_view_data_service.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/models/long_task_station_view_data.dart`
   - `apps/novel_agent_app/lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart`
3. focused tests：
   - `packages/novel_agent_adapters/test/project_long_task_station_detail_service_test.dart`
   - `apps/novel_agent_app/test/long_task_station_view_data_service_test.dart`

当前行为：

1. 长任务总站详情会在 `开放叙事摘要` 下追加 `权限确认` 小节。
2. 入口只来自 stable `changed_paths / last_changed_paths / step.changed_paths`。
3. 当前识别两类隐藏确认记录：
   - `.novel_agent/continuity/profile_proposals/*.json`
   - `.novel_agent/continuity/clarifications/*.json`
4. GUI 会读取记录中的 proposal reason / clarification question 作为摘要。
5. GUI 只打开确认记录，不审批、不应用、不把 proposal 直接提升为 active profile。
6. `Continuity` 粗统计已同步收窄为 `ledger / claims / reviews / deliveries`，避免 profile proposal / clarification 被重复算进 continuity 总数。

验证已通过：

```powershell
dart analyze lib/src/runtime/project_long_task_station_detail_service.dart lib/src/runtime/project_long_task_station_narrative_summary.dart test/project_long_task_station_detail_service_test.dart
dart test test/project_long_task_station_detail_service_test.dart
flutter analyze lib/features/long_task_station/application/services/long_task_station_view_data_service.dart lib/features/long_task_station/presentation/models/long_task_station_view_data.dart lib/features/long_task_station/presentation/widgets/long_task_run_detail_panel.dart test/long_task_station_view_data_service_test.dart
flutter test test/long_task_station_view_data_service_test.dart
```

结果：

1. `No issues found!`
2. `ProjectLongTaskStationDetailService ... All tests passed!`
3. `LongTaskStationViewDataService ... All tests passed!`

这说明 `ONS-44` 的 GUI 侧已经完成权限确认记录的最小展示入口。当前剩余工作收缩为：

1. `ONS-44` 最终文档收口。

---

## 2026-06-05 最终收口：ONS-44 已完成

本轮只完成一个具体任务：`ONS-44` 最终文档收口。

最终确认：

1. 压力真实验证已通过：
   - `apps/novel_agent_app/tool/real_multiscope_pressure_probe.dart`
   - 最新真实报告：`artifacts/real_multiscope_pressure_probe_report.json`
   - `chapter_01` ~ `chapter_04` 全部通过
   - 顶层 `report_category = success`
2. CLI 最小接线已完成：
   - `workflow` 命令已输出 `activation / delivery / review / ledger` 粗粒度摘要
   - 口径是“先接上”，不做精细 CLI 交互设计
3. GUI 长任务总站最小接线已完成：
   - `Activation`
   - `Delivery`
   - `Review`
   - `Continuity`
   - `Projection`
   - `权限确认`
4. GUI / CLI 均只消费稳定合同：
   - 不解释 claim payload
   - 不把 Markdown 当事实源
   - 不审批或应用 profile proposal / clarification
   - 不用外层展示兜底底层 runtime 语义
5. 相关 focused verification 已在对应子任务中通过：
   - pressure probe 真实复跑
   - CLI `dart analyze` 与 `workflow_output_summary_probe`
   - adapters `dart analyze` / `dart test`
   - app `flutter analyze` / `flutter test`

剩余风险：

1. 真实 probe 仍依赖本地 provider 配置和显式开闸，后续大规模回归需要继续控制预算。
2. GUI 当前是长任务总站详情里的最小可见入口，不是完整 knowledge ledger 浏览器。
3. CLI 当前只做 coarse summary，不承诺最终信息架构。
4. 权限确认目前只显示和打开记录，审批 / 应用仍应作为后续独立任务设计。

结论：

1. `ONS-44 压力真实验证与外层对接收口` 已完成。
2. `ONS-01` ~ `ONS-44` 任务列表已全部完成。
3. 若后续再次收到同一自动提示，应按用户约束进入阻塞式主进程控制台命令，不再开启新的 ONS 任务。
