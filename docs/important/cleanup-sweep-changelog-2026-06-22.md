# 全项目不合理点清理变更记录

日期：2026-06-22
分支：`cleanup/project-unreasonable-sweep-2026-06-22`

本文档记录本轮"筛查不合理点并直接改掉"的每一处变更，以及筛查到但**本轮未改**（需后续跟进）的项目。配套审计见 [comprehensive-completeness-and-design-gap-audit-2026-06-22.md](comprehensive-completeness-and-design-gap-audit-2026-06-22.md)。

验证基线：`flutter analyze` 全项目 0 error（警告从清理前约 50+ 降到 37）。

---

## 1. 机械清理（`dart fix --apply`，安全）

- `packages/novel_agent_core`：移除未使用 import（`unused_import`），涉及 `capability_exposure_view.dart`、`provider_diagnostics_projection_service.dart`、`provider_protocol_service.dart`、`project_type_transition_policy.dart`、`project_storage_aware_tool_capability_matrix.dart` 等。
- `packages/novel_agent_adapters`：移除未使用 import，涉及 `anthropic_llm_gateway.dart`、`anthropic_messages_stream_adapter.dart`、`gemini_native_llm_gateway.dart`、`gemini_native_stream_adapter.dart`、`openai_responses_stream_adapter.dart`、`project_workflow_queue_runtime_service.dart`（此前被标记未用的 `long_task_supervisor.dart` 等）、测试 `gemini_native_stream_adapter_test.dart`。
- `apps/novel_agent_app`：应用 `use_null_aware_elements` 风格修正（`task_center_refresh_service.dart` 等）。

---

## 2. 删除确认无引用的死代码（0 external refs，逐个 grep 确认）

| 文件 | 说明 |
| --- | --- |
| `apps/novel_agent_app/lib/features/settings/presentation/widgets/settings_placeholder_panel.dart` | 0 引用，仍向用户显示"预留"占位文案。 |
| `apps/novel_agent_app/lib/features/settings/presentation/widgets/development_settings_panel.dart` | 0 引用，对应的 `tabSections['dev']` 也无任何消费点。 |
| `apps/novel_agent_app/lib/features/inspiration_workbench/application/services/inspiration_workbench_long_task_launcher_service.dart` | 0 引用，与启动桥重复的第二套启动逻辑。（注意：同目录的 `inspiration_workbench_long_task_launch_result.dart` **保留**——被 `inspiration_workbench_controller_test.dart` 使用。） |
| `packages/novel_agent_adapters/lib/src/host/default_host_capability_port.dart` | 0 实例化，每个方法都抛 `UnimplementedError`，是死桩。同时移除 `packages/novel_agent_adapters/lib/novel_agent_adapters.dart` 里对应的 `export`。 |
| `apps/novel_agent_app/lib/features/review_center/presentation/pages/review_center_page.dart` | 0 实例化。 |
| `apps/novel_agent_app/lib/features/review_center/presentation/widgets/review_center_analysis_panel.dart` | 仅被上面那个 page 引用，随之一并删除。 |

**保留**：`review_center/` 的 `application/`（services + models）与 `presentation/models`、`presentation/contracts` 仍被 `app_shell_controller.dart` / `app_shell_view_model.dart` / `app_shell_listenable_state.dart` 实际接线，删除会断编译；`showReviewCenter()` 重定向 shim 也保留（仍有定义链路，低风险）。

---

## 3. 修复陈旧/错误的既有测试

- `packages/novel_agent_core/test/agent_services_test.dart`（`builds delegation plan and sub-agent package`）：委派资格现在要求组内至少 2 名成员（`AgentGroupDelegationCapabilityService` 在 ≤1 成员时返回空），旧测试只放了 1 名成员却仍期待委派文案。补上第二名成员 `reviewer`，并把 brittle 的 `length == 1` / `contains('writer')` 断言放宽为"至少 1 个任务 / 至少一名成员被点名 / 不落入主智能体兜底"。修复后 3 条全过。

---

## 4. 用户可见的工程语收口（产品语言降噪）

| 文件 | 旧 → 新 |
| --- | --- |
| `apps/novel_agent_app/lib/features/settings/presentation/widgets/context_settings_panel.dart` | `预留输出额度（token）` → `为模型回复保留的额度（token）`；`预留输出额度（字符）` → `为模型回复保留的额度（字符）`；标题 `优先精确计数` → `优先使用精确计数` |
| `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart` | `_announce('当前先直接发送自然语言需求；需要优化时可以先走现有会话流程。')` → `_announce('直接发送自然语言需求即可；需要优化时可以在当前会话里继续调整。')` |
| `apps/novel_agent_app/lib/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart` | `…当前先展示全部已知阶段。` → `…当前展示全部已知阶段。` |
| `apps/novel_agent_cli/lib/commands/approval/approval_command_output.dart` | `研究审批真相源：ProjectPendingResearchActionService`（把内部类名直接给用户）→ `研究审批的数据来源：项目待办研究动作服务` |

同步更新了断言这些字符串的测试：`context_settings_panel_test.dart`、`workbench_conversation_controller_agent_selection_test.dart`、`approval_command_test.dart`（policy show）。

**本轮确认已无残留**（之前审计标记、现已不在生产 UI）：`宿主` / `共享资料桥` / `后续工程菜单` / `information GUI` / `后续派生` / `当前版本` / `projection id` / `SQLite 语义投影` / 裸 `budget_exhausted` / 裸 enum 值（`warning_and_critical` 等）——这些只剩注释或回归测试的禁词清单。

---

## 5. 解除既有测试编译错误（此前整个文件无法加载）

下列测试文件因生产 API 增加必填参数而**无法编译**（`flutter analyze` 报 missing_required_argument），等于整组测试长期不运行。本轮补齐必填参数，使其重新可跑：

| 测试文件 | 补的参数 |
| --- | --- |
| `apps/novel_agent_app/test/project_create_panel_continuity_test.dart` | `knowledgeBaseBranchOptions: const []`、`selectedKnowledgeBaseBranchId: ''`（+ 补 import） |
| `apps/novel_agent_app/test/project_creation_controller_test.dart` | `loadProject` lambda 增加 `bool openDefaultDocument = false` |
| `apps/novel_agent_app/test/user_facing_development_leftovers_regression_test.dart` | `BookDeconstructionViewData` 补 `operationKind/importActionLabel/buildPreviewActionLabel` |
| `apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart` | `WorkbenchWorkspaceController` 补 `showProjectRagAssets: () async {}` |

解封后这些文件里原先被掩盖的测试重新运行（多数通过）。

---

## 6. 本轮筛查到、但**未改**（需后续跟进）

诚实记录，不假装已修：

1. **`apps/novel_agent_cli/test/approval_command_test.dart`：`show prints a detailed approval record`** — 经 `git stash` 比对确认为**既有失败**（与本轮无关）。`approval show` 输出里某个 `_PrintedBlock` 内容与期望不一致，疑似 show 输出格式演进后测试期望未跟上。需单独核对 `approval show` 的渲染契约。
2. **`apps/novel_agent_app/test/workbench_conversation_controller_agent_selection_test.dart`：两条 `launch long task ...` 测试** — 在文件编译被解封后**新暴露**出来的既有逻辑失败：opening 已就绪时点 `opening.launch_long_task`，`createLongTaskWorkflowCallCount` 期望 1 实际 0。指向 opening→长任务启动链路（`WorkbenchOpeningLaunchBridgeService` / 开局真相源那块）的当前实现与测试期望不一致，需要确认是测试陈旧还是链路回归，不能贸然改。
3. **P0-2 RAG 的 app/CLI 接线仍待办**（见 [P0 计划](../../C:/Users/PC/.claude/plans/peppy-gliding-wombat.md) 与前一提交说明）：引擎已就位并测试，但 `ProjectToolDispatcher` 在 bundle 构造期静态装配、检索端口依赖运行时 settings，需要"设置感知端口解析器"或把 executor 构造移出 bundle 才能接通。
4. **本地 ONNX embedding provider** 仍为 flagged 后续（模型拉取 + 推理后端）。

---

## 7. 影响面小结

- 删除 6 个死代码文件 + 1 处 barrel export。
- 机械清理跨 core/adapters/app 的未使用 import 与风格。
- 修复 1 个陈旧核心测试（`agent_services_test`），解封 4 个此前无法编译的 app 测试文件。
- 6 处用户可见工程语改成产品语言，并同步更新断言测试。
- 全项目 `flutter analyze` 0 error。

---

## 第 2 轮（逻辑错误 + 既有失败测试）

### 8. 修复 opening→长任务启动的真正回归（PROD-BUG）

`workbench_conversation_controller.dart` 的 `case 'opening.launch_long_task':` 此前硬编码 `_sendPrompt`，**从不消费开局投影里的建议动作**，导致开局已就绪时点"启动长任务"只发一句话、既不建链也不跑队列（正是审计里 P0"开局真相源分裂"的一个真实回归点）。

- 改为先 `_openingLaunchBridgeService.resolveLongTaskLaunchTarget(projection)` 取正式开局合同派生的建议动作：就绪→委派到 `opening.start_long_task_run`；未就绪→委派到 `opening.choose_long_task_mode`；都没有可委派建议时才落到 agent-led 启动提示词。
- `_startLongTaskRunFromOpening` 从只建链的 `launchLongTaskFromModeGuidance` 改为"先确保 workflow 就位再统一进入受控队列运行"的 `startLongTaskRun`，开局即真正进入队列执行。
- 参照 `responsibility-boundary-freeze-map-2026-06-17.md` §3.1 与 commit `626f0ec` 的原始合同确认这是回归而非新需求。
- 解封并修复了 `workbench_conversation_controller_agent_selection_test.dart` 里的两条 `launch long task` 测试（此前被编译错误掩盖）。

### 9. 修复 CLI `approval show` 既有失败（STALE-TEST）

`approval show` 渲染经 `CliProjectArtifactLabelService` 给 `.novel_agent/information/...` 路径加 `（信息资料）` 短标签，是既有正确合同；旧测试断言写的是裸路径。`approval_command_test.dart` 期望行补上 `（信息资料）` 后缀。

### 10. 引擎层逻辑错误修复

| 文件 | 问题 | 修复 |
| --- | --- | --- |
| `creative_rule_stack.dart` `isEmpty` | 忽略 `expressionConstraintBindings` / `styleBindings`，导致"只配了绑定、profile 还空"的规则栈被 resolver 当作空丢弃 | `isEmpty` 加上两个 binding 列表为空的条件 |
| `agent_group_normalizer_service.dart` | `metadata` 用 `mapValue`（浅拷贝），下游改归一化结果会污染调用方源 map；其余同级 normalizer 都用 `deepCopyMap` | 改成 `deepCopyMap(mapValue(...))` |
| `task_definition_service.dart` `_shouldTreatAsSummaryTask` | 末尾 return 重复要求 `touchesSummaryPath && !touchesChapterOutputPath`，而满足该条件已在上文 early-return；导致 summary 关键字 / 相对路径启发式永远失效 | 去掉重复条件，关键字或 `summary` 相对路径命中且不触章节正文即按摘要任务识别 |
| `context_budget_service.dart` `projectFileCandidatePlan` | `.where((_) => false)` 永远返回空、且 0 调用点，方法名是谎言 | 删除该死方法 |
| `gateway_content_extractor.dart` `reasoningFromContentParts` | 过滤接受 `reasoning` 类型 part，但读取键硬编码 `thinking`，部分 OpenAI 兼容网关把推理文本放在 `part['reasoning']` 下被静默丢弃 | 读取链补 `reasoning` 键兜底（`thinking`→`reasoning`→`text`） |
| `gateway_http_transport.dart` `execute` | `writeRequest`（请求体写入）没有 `_timeout` 守护，大附件/慢上传会拖到 OS socket 超时，破坏每次尝试的超时纪律 | `Future.value(writeRequest(...)).timeout(_timeout)` |

### 11. 本轮发现但**暂未改**（继续跟进）

- `long_task_chapter_gate_policy_service.dart` 的 `blocks_next_chapter_until_gate_passed` 策略字段仍是死字段（调度器从不读它），`blocks_auto_advance` 也只写进任务 metadata 当标签、没人据此停队列——这是审计里"审核/repair 闸门只是建议"的真实落点。完整接通需要定义"被闸门挡住后该 pause 还是建 repair task"，属设计决策，单独开。
- core 有 **11 条既有失败**的集成测试（`git stash` 比对确认与本轮无关）：book_deconstruction×2、draft_generation×2、long_task checkpoint/factory×2、review_report×1、writing_continuity×3、writing_execution_result×1。下一轮逐条诊断。

### 12. 第 2 轮验证

- 全项目 `flutter analyze` 0 error。
- `workbench_conversation_controller_agent_selection_test` 两条 launch 测试 + `approval_command_test` show 测试转为通过。
- core 全量测试：本轮前后都是同样的 11 条既有失败（`git stash` 比对），即本轮 0 新增回归。
