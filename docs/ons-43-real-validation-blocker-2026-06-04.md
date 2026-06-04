# ONS-43 短真实验证阻塞记录

日期：2026-06-04

关联任务：

- `docs/open-narrative-state-toolcall-runtime-session-order-2026-06-04.md`
- `ONS-43 短真实验证：普通项目与普通长任务`

## 本轮实际执行

真实 probe 均显式设置：

```powershell
$env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'
```

本轮执行过的真实验证：

1. `dart run tool/real_long_task_probe.dart`
2. `dart run tool/real_workflow_loop_probe.dart D:\FlutterProjects\NovelAgentFlutter\artifacts\real_general_novel_probe_workspace\2026-06-03T21-38-09.121728\普通小说真实写作探针`

另外，对 `apps/novel_agent_app/tool/real_long_task_probe.dart` 做了一次仅限探针侧的修正：

1. 去掉“样章确认后必然已经出现第02章 draft task”的旧假设。
2. 改为按当前 runtime 的 `checkpoint` / `checkpoint_review` / `postprocess` / `waiting_user` 继续动作推进。
3. `flutter analyze tool/real_long_task_probe.dart` 已通过。

该修正没有改 production runtime，只修正真实探针与当前 runtime 边界不一致的问题。

同日后续又执行了一次恢复后的普通项目真实短验入口：

3. `dart run tool/real_general_novel_probe.dart`

最新普通项目真实报告：

- `artifacts/real_general_novel_probe_report.json`

在定位 `chapter_04` 的 `submit_chapter_delivery` 参数失败后，又做了一次仅针对前 4 章的修复后复验：

4. `dart run tool/real_general_novel_probe.dart --chapter-count=4`

同时对 ordinary conversation runtime 做了一个只针对该失败面的补修：

1. `ProjectConversationDraftRuntimeService` 现在允许在 `submit_chapter_delivery` 因参数不合法失败时，只要工具参数里仍保留可恢复的 `chapter_path` + 正文，就补做一次受控交付。
2. 新增 `project_conversation_draft_runtime_service_test.dart` 覆盖 invalid submit salvage。
3. 已通过：
   - `dart test test/project_conversation_draft_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`

同日后续又补了一条更严格的 ordinary conversation 章节完成合同：

1. `ProjectConversationDraftRuntimeService` 现在会把 `chapter` / `revision` 任务中“没有章节输出、也没有正式 delivery，只剩计划/委派/读取类工具”的结果直接提升为明确失败，而不再把这种回合静默当成完成。
2. 新增 `project_conversation_draft_runtime_service_test.dart` 覆盖：
   - `finalizeDraftRun rejects chapter task that only planned or delegated without formal delivery`
3. 已通过：
   - `dart test test/project_conversation_draft_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`

随后再次执行了定向真实复验：

5. `dart run tool/real_general_novel_probe.dart --chapter-count=4`

针对 `chapter_01` 的 sidecar / invalid-submit 收口，又补了一次更窄的 ordinary conversation 修复：

1. `ProjectConversationDraftRuntimeService` 现在会在已存在 `accepted` 但 `submission_accepted = false` / `sidecar_state = missing|repair_required` 的章节交付结果上继续补一次 synthetic submission，而不是只在 `delivery.isEmpty` 时才补交。
2. 新增 `project_conversation_draft_runtime_service_test.dart` 覆盖：
   - `finalizeDraftRun supplements accepted delivery that is missing submission sidecar`
3. `real_general_novel_probe.dart` 的失败判定也已收紧为：
   - 若最终 `chapterDelivery` 已恢复到 `delivery_state = delivered` 且 `sidecar_state = accepted`，则不再把早先已被修复的 tool error 痕迹当作 blocking failure。
4. 已通过：
   - `dart test test/project_conversation_draft_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`
   - `flutter analyze tool/real_general_novel_probe.dart`

随后再次执行了定向真实复验：

6. `dart run tool/real_general_novel_probe.dart --chapter-count=4`

在上述 4 章定向真实复验通过后，又按 `ONS-43` 原始要求重新执行了一次 full 10 章 ordinary 真实复跑：

7. `dart run tool/real_general_novel_probe.dart`

在定位第09章再次退化成 plan-only / sub-agent-only 后，又做了一次更窄的 ordinary conversation tool exposure 收口：

1. `ProjectConversationDraftRuntimeService` 现在会把 `chapter` / `revision` 普通会话中的 `set_agent_tasks`、`call_sub_agent` 从 exposed tools 里移除，避免正式章节任务再次被计划/委派工具抢走回合。
2. `project_conversation_draft_runtime_service_test.dart` 已补充断言：ordinary chapter `prepareDraftRun()` 的 `exposedToolIds` 不再包含这两个工具。
3. 已通过：
   - `dart test test/project_conversation_draft_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_conversation_draft_runtime_service.dart test/project_conversation_draft_runtime_service_test.dart`

随后再次执行 full 10 章 ordinary 真实复跑：

8. `dart run tool/real_general_novel_probe.dart`

## 阻塞事实

### 同日后续补记：普通项目真实入口已恢复

后续已补回文档 `ONS-43` 指定的普通项目真实 probe 入口：

- `apps/novel_agent_app/tool/real_general_novel_probe.dart`

并已完成静态校验：

```powershell
flutter analyze tool/real_general_novel_probe.dart
```

结果：

- `No issues found!`

这说明“普通项目真实入口缺失”这一结构性阻塞已被收口。

第一次恢复入口后的真实复跑事实为：

1. `requested_chapter_count = 10`
2. `chapter_01`、`chapter_02`、`chapter_03` 均已通过，`delivery_outcome = accept`
3. `chapter_04` 失败，报告分类为 `technical_failure`
4. 最新顶层错误为：

```text
第04章 未通过 ordinary conversation probe 验证。
```

5. `chapter_04` 的关键失败信号为：

```text
submit_chapter_delivery：领域工具参数不合法。
```

6. `chapter_04` 本轮只有 activation report 落盘，没有形成 `chapters/第04章.md` 与正式 delivery 记录

因此普通项目侧的阻塞一度从“入口缺失”收缩为“ordinary conversation 真实写作链在第04章触发了一次 `submit_chapter_delivery` 参数级技术失败”。

但在补上上述 recovery 兜底并重新做 `--chapter-count=4` 复验后，普通项目侧的最新阻塞事实再次前移：

1. 新报告仍为 `technical_failure`
2. 新报告 `requested_chapter_count = 4`
3. 第01-03章仍通过
4. 第04章这次不再出现 `submit_chapter_delivery：领域工具参数不合法`
5. 第04章最新执行痕迹只剩：
   - `set_agent_tasks`
   - `call_sub_agent`
   - 若干 `read_project_file` / `get_project_file_info`
6. 第04章最新 `tool_error_summary = ""`
7. 第04章最新 `changed_paths` 只有：
   - `tasks/写作第04章正文.task.json`
   - `tasks/写作第04章摘要.task.json`
   - `tasks/更新角色状态与伏笔.task.json`
   - `tracking/conversation_draft/chapter_*.activation_report.json`
8. 第04章仍没有：
   - `chapters/第04章.md`
   - `summaries/第04章.summary.md`
   - 正式 `submit_chapter_delivery`

这说明本轮补修已经跨过了“invalid submit payload”这一个点；普通项目侧当前最新阻塞已改为“模型在 ordinary conversation 真实场景里把当前章节任务退化成计划/分派，没有形成正式章节交付，runtime 也没有把这种 plan-only 结果强制收口为失败恢复”。

但在补上上述“无正式交付即失败”的章节完成合同后，定向真实复验又把阻塞前移到了更早的 `chapter_01`：

1. 最新报告仍为 `technical_failure`
2. 最新报告 `requested_chapter_count = 4`
3. 本次未再跑到 `chapter_04`
4. `chapter_01` 的最新关键事实：
   - `output_paths = ["chapters/第01章.md"]`
   - `chapter_delivery.delivery_state = delivered_needs_repair`
   - `chapter_delivery.sidecar_state = missing`
   - `delivery_outcome = repair`
   - `tool_error_summary = "submit_chapter_delivery：领域工具参数不合法。"`
5. 这说明普通项目真实链目前先暴露出的更早问题是：
   - 模型先发出一次 invalid `submit_chapter_delivery`
   - ordinary conversation runtime 虽然已补做正文交付，但当前补交只形成了 `submission_missing` 的 `delivered_needs_repair`
   - probe 因 `repair` / `stoppedByToolError` 仍在第01章即失败

因此本轮新增的章节完成合同已经生效，但它还没有机会继续验证 `chapter_04` 的 plan-only 失败是否在真实链上被显式拦下，因为真实复验先被 `chapter_01` 的 sidecar / invalid-submit 组合问题挡住了。

但在补上上述 sidecar / invalid-submit 收口后，最新定向真实复验已经直接穿过了 `chapter_01` 到 `chapter_04`：

1. 最新报告为 `success`
2. 最新报告 `requested_chapter_count = 4`
3. `chapter_01` ~ `chapter_04` 均为 `ok = true`
4. 四章的 `delivery_outcome` 均为 `accept`
5. 四章的 `tool_error_summary` 均为空
6. `chapter_04` 已形成：
   - `chapters/第04章.md`
   - `summaries/第04章.summary.md`
   - `world/第二层频道.md`

这说明普通项目侧最近连续暴露的三类问题，在当前定向 4 章真实链上都已不再复现：

1. `submit_chapter_delivery` invalid payload
2. plan-only / sub-agent-only 无正式章节交付
3. salvage 后 sidecar 缺失导致 `delivered_needs_repair`

但 full 10 章 ordinary 真实复跑的最新结果仍未整轮通过，新的普通项目阻塞点已经后移到第09章：

1. 最新 full rerun 报告为 `technical_failure`
2. `requested_chapter_count = 10`
3. 顶层错误为：

```text
Bad state: 普通会话正式章节任务未形成正式交付：本轮只执行了计划/委派/读取类工具（load_agent_skill、read_project_file、get_project_file_info、call_sub_agent），没有写出章节正文，也没有 submit_chapter_delivery。
```

4. `chapter_01` ~ `chapter_08` 均为 `ok = true`
5. `chapter_01` ~ `chapter_08` 的 `delivery_outcome` 均为 `accept`
6. 工作区中已形成：
   - `chapters/第01章.md` ~ `chapters/第08章.md`
   - 第09章对应 activation report
   - 第09章相关 task 文件，如 `产出第09章剧情结构方案.task.json`
7. 但工作区中仍没有：
   - `chapters/第09章.md`
   - `summaries/第09章.summary.md`
8. 这说明修复后的 ordinary conversation 链已经能稳定穿过前 8 章，而第09章再次落回“只做计划/委派/读取类工具、不形成正式交付”的失败模式，只是现在它被 runtime 明确拦下了，不再静默混过去。

但在移除 formal chapter ordinary conversation 的 `set_agent_tasks` / `call_sub_agent` 暴露后，最新 full 10 章 ordinary 真实复跑已经整体通过：

1. 最新报告为 `success`
2. `requested_chapter_count = 10`
3. `chapter_01` ~ `chapter_10` 均为 `ok = true`
4. 十章的 `delivery_outcome` 均为 `accept`
5. 十章的 `tool_error_summary` 均为空

这说明普通项目侧在 `ONS-43` 范围内要求的“10 章左右 ordinary 真实短验”现在已经重新达标。

### 1. 普通长任务短链仍未穿过样章边界

本轮两次运行 `real_long_task_probe.dart`：

1. 第一次失败原因为探针仍按旧模型直接查找第02章任务。
2. 修正探针推进逻辑后再次运行，仍失败。

第二次失败的最新报告：

- `apps/novel_agent_app/artifacts/real_long_task_probe_report.json`

关键事实：

1. `createLongTaskWorkflow()` 只初始物化了 4 个任务：
   - planning
   - checkpoint_outline
   - sample chapter
   - checkpoint_001
2. 样章确认后，探针未观测到新的 `第02章` draft task 被续出。
3. 最新错误为：

```text
Bad state: 样章确认后未能推进出第02章任务。
```

因此当前阻塞已经从“探针假设过旧”收缩为“真实 runtime / 续窗口推进结果没有满足 ONS-43 所需的普通长任务短链继续条件”。

## 当前可确认的有效证据

虽然 ONS-43 本轮未通过，但已有以下有效事实：

1. 真实 probe 开闸机制正常，需要显式 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
2. 共享本地 probe 配置读取正常，`local/probe_api.txt` 可被当前探针链使用。
3. 历史普通项目真实报告 `artifacts/real_general_novel_probe_report.json` 仍可读出：
   - chapter delivery 生效
   - chapter length constraint 生效
   - expression constraint / de-AI 检查生效
   - delivery recovery / review 结构化结果已落盘
4. 本轮长任务真实探针失败已被保留为结构化报告，没有盲目继续扩跑压力输入。
5. 普通项目真实 probe 入口现已回到主树，并通过 `flutter analyze` 结构验证。
6. 普通项目真实短验已重新复跑，并生成新的现时报告：
   - `artifacts/real_general_novel_probe_report.json`
   - 前 3 章通过，第 4 章卡在 `submit_chapter_delivery` 参数不合法
7. 针对 `submit_chapter_delivery` invalid payload 的 ordinary conversation recovery 已补上，并通过定向测试与 analyze。
8. 修复后再次对前 4 章做真实复验，旧的 invalid payload 现象不再出现，但第04章暴露出新的 plan-only / sub-agent-only 未交付阻塞。
9. ordinary conversation 章节完成合同已收紧：正式章节任务若只有计划/委派/读取类工具且没有正式交付，现在会被直接判为失败。
10. 章节完成合同收紧后再次真实复验，新的最早阻塞前移到 `chapter_01`：正文已补交，但 sidecar 仍缺失，导致 `delivered_needs_repair`。
11. 在补齐 accepted-but-missing-sidecar 的 synthetic submission 收口，并让 probe 忽略已恢复完成的旧 tool error 痕迹后，`dart run tool/real_general_novel_probe.dart --chapter-count=4` 已整体通过。
12. 在修复后的分支上重新执行 full 10 章 ordinary 真实复跑后，普通项目侧新的最早失败点后移到第09章；前 8 章均已通过。
13. 在 ordinary chapter / revision 的普通会话 exposed tools 中移除 `set_agent_tasks` / `call_sub_agent` 后，full 10 章 ordinary 真实复跑已整体通过。

### 同日后续补记：长任务正式章节完成合同已收口

在上述阻塞记录之后，又对 seed-to-full 长任务续队列条件做了一次更窄的 production runtime 修正：

1. `ProjectLongTaskChapterQueueRuntimeService` 的续队列判断不再要求“所有已物化任务都进入终态”这一过严条件。
2. 现在如果 `planning` / `sample chapter` 本体仍停留在 `waiting_user`，但其后继显式 `checkpoint` 任务已经 `succeeded`，则视为该前序窗口已被 checkpoint 成功覆盖，允许继续物化下一窗口。
3. 新增 focused test：
   - `nextWorkflowTask still materializes next seed window when source tasks remain waiting_user but succeeded checkpoints already cover them`
4. 已通过：
   - `dart test test/project_workflow_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_long_task_chapter_queue_runtime_service.dart test/project_workflow_runtime_service_test.dart`

随后再次执行真实长任务短验：

9. `dart run tool/real_long_task_probe.dart`

最新报告：

- `apps/novel_agent_app/artifacts/real_long_task_probe_report.json`

新事实：

1. 本次 `real_long_task_probe` 已 `PASS`
2. 样章确认后，`第02章` 任务已经成功被续出：
   - `chapter_02.task_path = tasks/plan_seed_to_full_novel_..._chapter_002.json`
3. 这说明“样章确认后续不出第02章任务”这一原始阻塞已经被收口

随后继续针对这一新缺口做了更窄的一轮修复：

1. 在 `ProjectWorkflowRuntimeService` 中新增 long-task formal chapter completion 边界：
   - `chapter` / `revision` 任务如果本轮没有形成真实章节文件、也没有正式章节交付，就不能再被直接落成 `succeeded`
   - 若本轮只是 `present_user_options` 触发真实用户选择，则任务落为 `waiting_user`，不再被错误记成完成
   - 若本轮只是读取/加载/计划等非交付工具且没有正文/交付，则任务直接落为 `failed`
2. 新增 focused tests：
   - `runWorkflowTaskOnce keeps formal workflow chapter at waiting_user when model asks user to choose instead of delivering chapter body`
   - `runWorkflowTaskOnce fails formal workflow chapter when no chapter body or delivery is produced`
3. 已通过：
   - `dart test test/project_workflow_runtime_service_test.dart`
   - `dart analyze lib/src/workflow/project_workflow_runtime_service.dart test/project_workflow_runtime_service_test.dart`

随后再次执行真实长任务短验：

10. `dart run tool/real_long_task_probe.dart`

最新报告继续位于：

- `apps/novel_agent_app/artifacts/real_long_task_probe_report.json`

本次关键结果：

1. 顶层报告为 `success`
2. `chapter_file_written = true`
3. `all_project_files` 中已真实形成：
   - `chapters/第01章.md`
   - `chapters/第02章.md`
4. `chapter_02` 当前结果为：
   - `ok = true`
   - `status_after_step = "succeeded"`
   - `output_paths = ["chapters/第02章.md"]`
   - `tool_summary.tool_name_counts.submit_chapter_delivery = 1`
5. 这说明“长任务正式章节没有正文输出/正式交付也会被错误放行”这一缺口，在当前真实链上已不再复现

## 结论

`ONS-43` 现已可以标记为完成，不再保持阻塞。

最终确认结果：

1. 普通项目：已通过。full 10 章 ordinary 真实复跑已整体通过。
2. 普通长任务：样章后的续队列阻塞与 formal chapter completion 漏口均已收口；最新真实短链已真实写出 `第02章` 并通过验证。

因此下一轮可以从 `ONS-44` 开始，而不再需要继续停留在 `ONS-43`。
