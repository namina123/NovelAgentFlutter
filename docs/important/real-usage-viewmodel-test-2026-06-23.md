# 真实使用路径实测（viewmodel + 真实 LLM）2026-06-23

针对 session 目标「作为真实用户，从 viewmodel，配合 local/probe_api.txt 的真实 LLM，真正走每条可能的使用路径，测出问题直接修复，做全额使用测试」。

**端点**：`local/probe_api.txt` → OpenAI 兼容 `https://opencode.ai/zen/go/v1`，模型 `deepseek-v4-flash`（**推理模型**，流式先吐 `reasoning_content` 再吐 `content`）。所有真实调用走项目原生入口（`dart run tool/...`、`flutter test`），密钥由 `loadLocalProbeApiConfig` 从文件读取，不在命令行硬编码。

## 地基验证（已通过）

- `gateway_connect_probe`：chat 路径 `chat_final=OK`，`resolved_proxy=DIRECT`。项目 `OpenAiLlmGateway` 经流式正确从推理模型提取内容。`/v1/responses` 端点 404（provider 不支持 Responses API）→ 已分类 `configuration_unsupported`，app 默认走 chat 模式，无影响。
- `reasoning_toolcall_smoke_probe`（新增）：流式 + 非流式 tool calling 都正确——推理模型吐 `finish_reason=tool_calls`，gateway 归一成 `tool_calls[].name`（如 `write_project_file`）+ 正确 arguments。**结论：推理模型 + 项目 gateway 在 chat completions 流式/非流式 + 工具调用上端到端可用。** gateway 不是失败点。

## 已修复（含回归测试）

### 1. HFVV Wave1 createProject 阶段树缺口（lane C/D/E 长期 blocked_external 超时根因）

- 现象：lane C/D/E（均为 `knowledge_base` 项目类型）在创建阶段 15s 超时 `Timed out waiting for project creation next phase.`，从未进入真实流程。
- 根因：harness 的 `createProject`（`tool/hfvv_wave1_viewmodel_support.dart`）只驱动 `novel` 类型的两段流程（`projectType → storageStrategy`），**不识别也不提交** `knowledge_base` 的 `knowledgeBaseBranch` 中间阶段、也不为仅支持 sqlite 的 `knowledge_base` 收口存储策略（lane 误传 `markdown_project_store`）。产品侧阶段解析器（`ProjectCreationPhaseResolverService`）支持完整阶段树，是 **harness 落后于产品**。
- 修复：重写 `createProject` 为**按项目类型阶段树通用推进**——逐阶段提交直到 `projectPath` 落地；按 `ProjectTypeCatalogService` 把不支持的存储策略收口到首个支持项（kb→sqlite）；`knowledgeBaseBranchId` 默认 `structured_reference_library`；`runtimeBaseline` 阶段从 launcher options 解析有效 id。同一处修复同时覆盖 wave2（wave2 复用 `HfvvWave1AppShellHarness`，`long_novel` 路径更健壮）。
- 验证：新增 `test/hfvv_wave1_createproject_phase_fix_test.dart`，纯创建（不联网）验证 kb 创建完成 + novel 无回归，**两测全过**。
- 重跑确认：wave1 lane C/D/E **创建阶段全部通过**（finished 时间从 10:57/10:58 的 15s 超时变为 11:23/11:38/11:40 的正常推进），进到后续真实 LLM 阶段。

## 诊断结论（真实但非容器化可安全收口，已记录不强行修改）

### Wave1 lane B（普通·多智能体）content_quality_failure

- 现象：`sub_agent_run_count=0`，推理模型把"真实多智能体协作"**用散文叙事角色扮演**了（"现在按用户要求**模拟**多智能体协作流程…"），显式追问"请实际调用子智能体"后仍不调用。
- 排查结论：派发工具 `call_sub_agent` **确实启用并暴露**给模型——`enabledByDefault=true`（`BuiltinToolDefinition` 默认），permission 解析器对 unset 的 host permissionMode 走 `safe` fallback、`allow_sub_agents` 在 `safe` 下为 true；协作智能体也在（`BuiltinCollaboratorCatalogService` 有 editor_in_chief/writer/...）。即工具可用、目标可用，模型仍选择叙事。
- 结论：**推理模型行为**（倾向"思考"多视角而非派发工具），非可强修的容器化产品 bug。强行改 prompt 胁迫工具调用风险大、难验证。记录，不强行修改。

### Wave1 lane C/D/E（知识库·查询）blocked_external：会话水合卡在"正在恢复会话..."

- 创建修复后，C/D/E 一致卡在新点：抽取引用后 `sendPrompt(查询) → waitForConversationActivity` 超时。
- 根因：kb 项目今日 step 快照显示会话 `gen_status` 停在 **`正在恢复会话...`**（workbench 水合"会话恢复"阶段，`_restoreConversationRuntimeState` 是注入函数）。抽取（真实 LLM，耗时数十秒）完成后该状态**仍未推进** → 判定为**卡死而非慢**。
- 架构背景：kb 项目主工作区是 `projectAssets`（`_usesProjectAssetsAsPrimaryWorkspace`→true），workbench 目标被强制重定向回 projectAssets（`onAppShellDestinationRequested`）。即 kb 项目**不把 workbench 会话作为主面**，"经 workbench 会话查询知识库"可能本就不是 kb 的设计路径；而 workbench 水合对 kb 卡在会话恢复。
- 旁证：lane C 在 **6月10日** 的残留 artifacts 显示该路径曾经成功（7 条会话条目、含完整知识库回答"主角是林烬…"）——路径架构上可达，今日因 kb 水合会话恢复未完成而断。
- 结论：真实、3 lane 一致复现，但根因在注入式会话水合架构 + kb 工作区路由，**非本次能安全收口的容器化 bug**。需设计决策（kb 是否支持 workbench 会话查询；若支持，修 `_restoreConversationRuntimeState` 对 kb 的水合）。记录，不强行修改。

## 待补（后台跑完后追加）

- Wave2（长任务多章路径：lane F/G/H/I/J1-J4）实测结果。
- real_gui 探针家族（reference_extraction / chaptered_continuation / book_deconstruction_import）实测结果。
