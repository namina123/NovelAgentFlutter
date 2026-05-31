# NovelAgentFlutter 工作台剩余问题总收口分析

最后更新：2026-05-28

关联文档：

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`

---

## 1. 先纠正一个判断

之前被归到“不能实现”的两类问题：

- 会话附件上传
- 真正的停止 / 取消当前生成

并不是“不能实现”。

更准确的说法是：

**它们不是一个小 UI 会话能补完的点，而是会跨 Flutter UI、应用控制器、core 合同、adapter 网关、宿主能力边界的一整条链路改造。**

所以后续完全可以通过多轮任务链全部完成，包括这些问题在内。

这份文档的目的，就是把这些链路完整摊开，避免后面再把“大工程”误判成“做不了”。

---

## 2. 这次收口的范围

这份文档覆盖两类内容：

1. 当前工作台和协作链里，历史上已经明确提出但仍未彻底兑现的点
2. 之前被错误归为“不能实现”的两条重链：
   - 附件能力
   - 真停止 / 真取消

额外纳入一个你刚刚补充的关键约束：

- **附件是否可用，不只是平台问题，还取决于当前模型 / 当前 provider API 是否支持附件输入。**

以及当前这轮最终收束出的产品决策：

- **附件链路需要分析并保留未来接入边界，但当前阶段不开放任何用户入口。**

这会直接影响后续合同设计。

---

## 3. 总体结论

当前剩余问题，不适合继续按“见一个按钮补一个按钮”的方式推进。

更合理的结论是：

### 3.1 我们现在缺的是“正式项目化合同”

具体缺的是：

- 组优先协作合同
- 会话输入能力投影合同
- 会话请求运行句柄合同
- 模型输入能力合同
- 附件宿主能力合同
- 取消 / 停止传播合同

如果这些合同不先立住，后续每补一个 UI 点，都会把判断塞回：

- `WorkbenchConversationController`
- `ConversationSidebar`
- `ConversationInputActionRow`
- `ConversationModelStrip`

这正好违背当前项目的长期要求：

- 单一职责
- 解耦合
- 不让单文件过重
- 让 GUI / CLI 未来共用能力边界

### 3.2 所有问题都能完成，但必须分轨

建议后续按四条轨道推进，而不是混成一个“大美化任务”：

1. `协作选择轨`
2. `输入能力轨`
3. `会话请求运行轨`
4. `界面减噪与易用性轨`

其中前 3 条先于第 4 条。

---

## 4. 当前未彻底实现的问题总表

## 4.1 组优先没有真正接管主工作台

### 当前现状

- 右下角仍然是 `模型 + 智能体`
- `ConversationModelStrip` 仍直接消费 `agentLabel / agentOptions`
- `AppShellController._agentSelectorOptions()` 仍直接暴露智能体列表

相关文件：

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_conversation_view_data.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart`

### 问题本质

当前代码里，“项目智能体组”存在，但“会话主入口”仍然是单智能体。

这导致：

- 项目级组约束没有成为第一事实源
- 组和智能体在 UI 上并列打架
- 当前主智能体是派生结果还是用户直接选的，语义不清

### 后续正确方向

会话主入口应该改成：

- `模型`
- `智能体组`

当前主智能体应变成：

- 只读派生摘要
- 或组详情信息

而不是第二个主下拉。

---

## 4.2 项目级智能体组入口仍然不够稳定

### 当前现状

组选择目前主要集中在 opening / 空态补充流里：

- `ProjectOpeningSessionProjectionService`
- `ProjectOpeningAgentGroupBindingService`
- `ConversationOpeningPanelViewDataService`
- `OpeningSessionPanel`

### 问题本质

这意味着组选择更像“开局向导的一部分”，而不是“当前项目的正式协作基线”。

### 后续正确方向

项目级组入口至少要同时存在于：

1. 项目面板中的正式项目配置区
2. 会话 composer 附近的轻量当前组入口

两者分工应明确：

- 项目面板负责“配置与理解”
- 会话栏负责“当前会话快速切换”

---

## 4.3 右栏状态区仍然像调试条

### 当前现状

当前由三块组成：

- `ContextStatusBadge`
- `ConversationRuntimeStatusStrip`
- `ToolVisibilityToggle`

相关文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_status_group.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/context_status_badge.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_runtime_status_strip.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/tool_visibility_toggle.dart`

### 问题本质

这些组件当前是“分块展示状态”，不是“汇总当前协作摘要”。

### 后续正确方向

先做单行 / chip 化摘要投影服务，再做 UI。

不要先改视觉，再把状态判断继续写进 widget。

---

## 4.4 左栏项目面板仍然带旧式小图标工具条

### 当前现状

- `WorkbenchProjectPanel` 内仍挂着 `ProjectActionGroup`

相关文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_project_panel.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/project_action_group.dart`

### 问题本质

左栏已经是对象面板，却又叠了一层编辑器式小工具栏，语义重复。

### 后续正确方向

把项目动作改成语义化列表或少量主动作入口。

不要再保留“主导航 + 子工具条”的混搭层级。

---

## 4.5 深度思考能力只在设置里存在，未投影到工作台输入区

### 当前现状

模型层其实已经有 reasoning / thinking 能力链：

- `ModelExecutionProfileService`
- `ProviderModelMetadataService`
- `ModelSettingsViewDataService`
- `model_settings_panel.dart`

但会话输入区完全没有消费这套能力。

相关文件：

- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_input_capability_service.dart`

### 问题本质

模型能力已经存在，输入区能力合同却没有。

### 后续正确方向

需要把“当前模型 + 当前主智能体 + 当前项目组”的联合结果，投影成会话输入能力。

不能继续把 reasoning 只当设置页参数。

---

## 4.6 长任务开局已部分收缩，但“唯一清晰启动动作”仍不够稳定

### 当前现状

长任务相关能力已经有：

- opening projection
- guide action
- `opening.start_long_task_run`

但主工作台中的入口仍然过度依赖空态 / opening 条件。

### 问题本质

真正的目标应该是：

- 一个明确的“启动长任务”动作
- 后续缺口交给 AI 引导

而不是继续在不同状态出现不同的半向导。

---

## 4.7 视觉减噪还没收干净

### 当前现状

很多地方仍然存在：

- 双层 panel
- 过多 section 边框
- 同一对象被分成多个视觉盒子

### 问题本质

这已经不是纯配色问题，而是：

**对象边界和视觉边界没有对齐。**

### 后续正确方向

先完成合同和对象收束，再做视觉减噪回归。

否则会在错误结构上继续抛光。

---

## 5. 重点一：附件能力为什么是大链路，而不是一个按钮

## 5.0 当前产品决策

附件当前不作为公开能力开放。

也就是说，后续即使补链路，也应先做到：

- 合同完整
- 宿主边界明确
- provider 能力元数据齐备

但：

- 不在主工作台显示附件按钮
- 不在会话空态提供附件入口
- 不为了“以后可能要用”而提前暴露半成品交互

这条决策只影响“是否开放入口”，**不影响链路分析和未来扩展边界的设计**。

## 5.1 当前实际情况

现有代码里：

- `ConversationActionHandler` 已有 `onAttachmentRequested()`
- `ConversationInputActionRow` 已有附件按钮位
- `ConversationInputCapabilityState` 已有 `showAttachmentEntry`
- `ConversationInputCapabilityService` 现在固定返回 `false`
- `WorkbenchConversationController.onAttachmentRequested()` 只是占位提示

相关文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/contracts/conversation_action_handler.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/models/conversation_input_capability_state.dart`
- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_input_capability_service.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

所以：

**UI 壳已经预留，但从“用户选文件”到“模型真的收到附件”，中间链路基本还没建。**

---

## 5.2 附件能力至少涉及六层

### 第一层：宿主侧文件选择

当前项目已经有桌面端文件选择器先例：

- `DesktopProjectImportFilePickerService`

但这服务服务于“导入项目文件”，不是“会话附件”。

相关文件：

- `apps/novel_agent_app/lib/features/workbench/application/services/desktop_project_import_file_picker_service.dart`

#### 正确做法

不要复用“项目导入文件命令”直接冒充附件。

应新建独立宿主边界，例如：

- `ConversationAttachmentPickerService`
- `ConversationAttachmentHostPolicy`

原因：

- 项目导入文件是项目资源管理
- 会话附件是一次性输入材料

两者不是同一职责。

### 第二层：会话附件暂存状态

当前会话输入状态只有：

- 文本输入
- pending preview

没有：

- 已选附件列表
- 附件解析状态
- 附件失败状态
- 用户移除附件动作

#### 正确做法

需要新增独立的会话附件 view data / state slice，例如：

- `ConversationAttachmentDraft`
- `ConversationAttachmentViewData`
- `ConversationAttachmentComposerState`

不要把附件列表直接塞进 `TextEditingController` 附近的 widget 局部状态。

### 第三层：输入能力投影

附件是否可用，不能只看桌面端。

至少要联合判断：

1. 当前是否桌面端
2. 当前模型 / provider 是否支持附件输入
3. 当前项目类型 / 当前会话模式是否允许附件
4. 当前是否处于生成中

这也是你刚刚补充的关键点。

#### 当前缺口

目前模型能力元数据里有：

- `supports_reasoning`
- `supports_tools`
- `supports_streaming`

但没有：

- `supports_file_attachments`
- `supports_image_attachments`
- `supports_document_attachments`

相关文件：

- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/provider_model_capabilities_seed.dart`
- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`

#### 正确做法

先补模型输入模态能力合同，再让 `ConversationInputCapabilityService` 消费。

但当前阶段的 UI 策略应是：

- 内部能力可存在
- 公开入口仍默认关闭

也就是说，这里的 capability 更像“未来可开放能力”，不是“当前就要显示按钮”。

### 第四层：core 请求合同

当前 `LlmGateway.requestChat()` 只接受：

- `messages`
- `modelId`
- `tools`
- `options`
- `onStreamUpdate`

没有 typed attachment 输入位。

相关文件：

- `packages/novel_agent_core/lib/src/ports/llm_gateway.dart`

#### 问题本质

如果把附件继续硬塞进 `options` 或消息文本里，会导致：

- provider 差异失控
- 网关层协议分支散落
- 上层根本不知道自己传的是“原生附件”还是“文本降级”

#### 正确做法

引入正式请求对象，至少让附件成为 typed field，例如：

- `ChatRequest`
- `ChatInputAttachment`
- `AttachmentMediaKind`

不要长期继续用松散 `JsonMap options` 承载一切。

### 第五层：provider / gateway 适配

当前 `OpenAiLlmGateway` 负责：

- 组装 payload
- 发 SSE / JSON 请求
- 聚合 tool calls / reasoning

但没有附件协议分支。

相关文件：

- `packages/novel_agent_adapters/lib/src/providers/openai_llm_gateway.dart`

#### 问题本质

不同 provider 对附件输入的协议不一样：

- 有的支持原生文件 / 图片输入
- 有的只支持文本
- 有的支持 URL，不支持本地文件直传
- 有的支持多模态，但字段格式不同

#### 正确做法

附件支持必须作为 adapter 能力，而不是 core 里写死 OpenAI 风格。

更好的边界是：

- core 只表达“我有这些附件”
- adapter 决定：
  - 原生直传
  - URL 引用
  - 转换为文本摘要
  - 或明确不支持

### 第六层：会话记录与转录

当前会话状态里，用户输入主要是纯文本轮次。

如果附件接入后，还要解决：

- 会话里如何显示“本轮附带了哪些材料”
- 重试时是否带上同一批附件
- 历史记录如何还原
- 子智能体是否可见这些附件

这会影响：

- `ConversationSessionStateService`
- `ConversationStreamingStateService`
- transcript block projection

---

## 5.3 附件能力的设计原则

### 原则 A：附件不是项目导入

不要把“附件”偷换成“先导入项目再让模型读”。

原因：

- 用户语义不同
- 生命周期不同
- 权限边界不同
- 会话重试语义不同

### 原则 B：附件显隐必须走能力合同

不能写死成：

- 桌面端就显示

必须至少是：

- `host supports picking`
- `model supports attachment modality`
- `current conversation mode allows it`

但当前产品决策进一步要求：

- 即便 capability 为 true，公开 UI 也可以继续关闭

因为“能力存在”不等于“现在就要开放入口”。

### 原则 C：不要把附件塞回 `ProjectWorkspacePort`

当前 `ProjectWorkspacePort` 只有：

- `listEntries`
- `readTextFile`
- `createDirectory`
- `writeTextFile`

相关文件：

- `packages/novel_agent_core/lib/src/ports/project_workspace_port.dart`

这说明它的职责是“项目工作区文件”。

本地附件来自项目外部任意位置时，不应强行扩成“万能文件系统 port”。

更好的做法是新增独立 port，例如：

- `ConversationAttachmentAssetPort`
- `HostAttachmentSourcePort`

### 原则 D：附件降级策略要显式

未来即便要支持“模型不原生支持附件时的降级方案”，也必须显式设计成策略：

- 隐藏按钮
- 禁用并说明原因
- 或转为文本抽取后注入上下文

不能默默替用户做“附件导入项目”的语义转换。

### 原则 E：当前阶段不开放公开入口

后续如果先补底层链路，应保持：

- UI 不显示附件按钮
- CLI 也不默认暴露对应用户命令
- 只保留内部合同与测试接缝

直到以下条件同时满足：

1. 至少一条 provider / model 链路真实可用
2. 会话状态、重试、转录语义已明确
3. 不会和“导入项目文件”语义混淆

---

## 6. 重点二：真正停止 / 取消为什么也是大链路

## 6.1 当前实际情况

现有代码里：

- `ConversationActionHandler` 有 `onStopRequested()`
- 输入区按钮位已预留
- `WorkbenchConversationController.onStopRequested()` 只是提示“真实中断链路后续接通”

相关文件：

- `apps/novel_agent_app/lib/features/workbench/presentation/contracts/conversation_action_handler.dart`
- `apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_conversation_controller.dart`

与此同时，长任务总站已经有真实 stop：

- `LongTaskStationController.onLongTaskStationStopRequested()`

相关文件：

- `apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart`

所以目前的情况不是“系统没有 stop 概念”，而是：

**长任务链有 stop，会话即时生成链没有 stop。**

---

## 6.2 会话 stop 至少涉及五层

### 第一层：UI 当前轮运行句柄

当前 `WorkbenchConversationController._sendPrompt()` 是一次长异步流程：

- 构建状态
- 调 `GenerateDraftUseCase.execute()`
- 接收流式进度
- 刷新资源
- 落盘

但控制器没有持有“当前请求句柄”。

也就是说，用户点停止时，没有一个可取消对象可操作。

### 第二层：core 取消合同

当前 `GenerateDraftUseCase.execute()` 没有：

- cancel token
- cancel handle
- cooperative cancellation check

相关文件：

- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`

#### 问题本质

即使 UI 有 stop 按钮，只要 core 用例没有取消协议，按钮也只能变成提示词。

#### 正确做法

需要正式引入取消合同，例如：

- `GenerationCancellationToken`
- `CancelableGenerationHandle`
- `GenerationStopReason`

### 第三层：网关流式中断

当前 `OpenAiLlmGateway.requestChat()` 内部：

- 自建 `HttpClient`
- 读取 SSE / JSON
- 聚合内容

但外部拿不到请求进行中的句柄，也无法主动关闭流。

#### 正确做法

要么：

- `requestChat()` 接受可观察 cancel token

要么：

- 改成返回可取消的运行句柄

关键目标是：在流式读取过程中，外部 stop 能关闭当前网络流。

### 第四层：工具轮与子智能体轮的中断

当前生成链不只是单次 LLM：

- 可能进入工具轮
- 可能进入子智能体轮
- 可能多轮往返

相关文件：

- `packages/novel_agent_core/lib/src/use_cases/generate_draft_use_case.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_execution_service.dart`
- `packages/novel_agent_core/lib/src/runtime/tool_execution_service.dart`

#### 问题本质

即使 SSE 可中断，如果当前正在执行：

- 本地工具
- 子智能体调用
- 项目文件读取 / 写入

也需要决定 stop 语义：

1. 立即终止当前网络流
2. 阻止进入下一轮
3. 对不可中断工具采用“合作式停止”

#### 正确做法

第一阶段先实现：

- 停止当前流
- 禁止后续轮继续

第二阶段再考虑：

- 工具执行中断
- 子智能体链路中断

不要把“全链路所有子步骤都立刻强杀”当作第一阶段目标。

### 第五层：结果状态与 UI 表达

停止后还要定义：

- 当前轮是否保留已生成正文
- 是否保留 reasoning
- 是否记为失败
- 是否允许重试
- 时间线里如何展示

当前 `DraftGenerationResult` 只有：

- `waitingForUserChoice`
- `reasoningContent`
- `stoppedByToolError`

没有：

- `cancelledByUser`
- `partialContentAccepted`
- `stopPhase`

相关文件：

- `packages/novel_agent_core/lib/src/runtime/draft_generation_result.dart`
- `packages/novel_agent_core/lib/src/runtime/draft_generation_progress.dart`

#### 正确做法

需要把“失败”和“用户主动停止”分开建模。

否则 stop 之后不是假装失败，就是假装成功。

---

## 6.3 停止能力的设计原则

### 原则 A：停止不是 UI 布尔值

不能只做：

- 生成时按钮变成停止

而底层仍然没有可取消对象。

### 原则 B：优先做合作式取消

先支持：

- 网络流关闭
- 下一轮不继续
- 工具轮边界检查 token

而不是一开始就追求强制杀掉一切宿主进程。

### 原则 C：失败与取消必须分开

取消不是失败。

后续状态里至少要能区分：

- completed
- failed
- cancelled
- waiting_user_choice

### 原则 D：不要把 stop 逻辑再塞进 `WorkbenchConversationController`

控制器已经很重。

停止链应尽量拆成：

- 会话请求运行服务
- 取消 token / handle
- 运行状态投影服务

---

## 7. 重点三：输入能力合同现在过于薄

## 7.1 当前现状

`ConversationInputCapabilityService.resolve()` 现在只接受：

- `isGenerating`

然后固定关掉：

- 附件
- 停止
- 工具
- 优化

相关文件：

- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_input_capability_service.dart`

### 问题本质

这让输入能力无法表达真正的联合判断。

至少应该接入：

- 当前平台
- 当前模型能力
- 当前主智能体 / 当前组能力
- 当前运行态
- 当前会话是否已有附件

### 后续正确方向

把输入能力拆成独立能力快照，例如：

- `ConversationInputCapabilityContext`
- `ConversationInputCapabilityState`
- `ConversationInputCapabilityResolver`

不要让 widget 或 controller 自己再拼条件。

其中附件位在当前阶段应区分两层：

1. `internal capability`
2. `publicly exposed action`

这样后续即使底层已经具备附件能力，也可以继续保持公开入口关闭。

---

## 8. 重点四：模型能力元数据还不够表达“会话输入模态”

## 8.1 当前现状

当前模型元能力主要覆盖：

- thinking / reasoning
- temperature / top_p / top_k
- streaming
- tools

相关文件：

- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/provider_model_capabilities_seed.dart`

### 缺口

缺少输入模态能力，例如：

- 是否支持图片输入
- 是否支持通用文件输入
- 是否支持多附件
- 是否要求 URL 而非本地文件
- 是否只支持文本抽取后的附件代理

### 后续正确方向

把“会话输入模态”正式纳入模型能力元数据。

否则：

- 附件按钮无法正确显隐
- 未来图片、PDF、文档支持都只能靠 provider 名称硬编码

---

## 9. 重点五：有些地方已经有可复用基座，后续应利用

## 9.1 桌面选择器边界已经有先例

可复用思路：

- `DesktopProjectImportFilePickerService`
- `DesktopProjectDirectoryPickerService`

意味着宿主边缘服务这条思路已经成立。

## 9.2 模型 reasoning 能力链已经存在

可复用思路：

- `ModelExecutionProfileService`
- `ProviderModelMetadataService`
- `ModelSettingsViewDataService`

意味着“模型能力 -> UI 能力投影”这条路已经有一半。

## 9.3 长任务 stop 已经存在终态语义

可复用思路：

- `LongTaskStationController`
- core 里的 stopped / cancelled 相关生命周期表达

这说明系统并不是完全没有取消语义，只是会话链没接上。

---

## 10. 不该采用的做法

后续实现时，以下做法都不够优雅，应避免。

## 10.1 不要把附件直接塞进 `requestOptions`

这样会让：

- core 不知道自己接的是什么
- adapter 只能解析动态字段
- 测试和能力判断都变差

## 10.2 不要把附件逻辑并入项目导入逻辑

“导入文件”和“会话附件”是两类动作，不应共享一个业务中心。

## 10.3 不要把 stop 做成只改按钮文案

没有运行句柄的 stop 只是表演。

## 10.4 不要继续做大控制器累加

`WorkbenchConversationController` 已经明显偏重。

新链路应优先外提成：

- capability service
- request runtime service
- attachment staging service
- view data projector

## 10.5 不要把 provider 特例写死在 Flutter widget

例如不能写成：

- 如果 provider id 是 X 就显示附件

这类判断应只存在于模型能力元数据或 adapter 能力投影中。

---

## 11. 建议的新合同边界

以下是后续较稳的拆法。

## 11.1 会话输入能力层

- `ConversationInputCapabilityContext`
- `ConversationInputCapabilityResolver`
- `ConversationAttachmentCapability`
- `ConversationReasoningCapability`

职责：

- 只回答“当前该显示什么、允许什么”

## 11.2 会话附件层

- `ConversationAttachmentDraft`
- `ConversationAttachmentPickerService`
- `ConversationAttachmentViewDataService`
- `ConversationAttachmentComposerController`

职责：

- 只管理附件选择、移除、展示、校验

## 11.3 会话请求运行层

- `ConversationRequestRuntimeService`
- `ConversationRequestHandle`
- `ConversationRequestCancellationToken`

职责：

- 只管理当前轮请求的生命周期

## 11.4 LLM 请求合同层

- `ChatRequest`
- `ChatInputAttachment`
- `ChatRequestCapability`

职责：

- 把 typed 请求传给 gateway

## 11.5 Provider 能力元数据层

- `supports_reasoning`
- `supports_tools`
- `supports_streaming`
- `supports_file_attachments`
- `supports_image_attachments`
- `supports_attachment_urls_only`

职责：

- 统一提供给设置页、输入区、CLI、未来 probe 使用

---

## 12. 依赖顺序建议

如果后续要把这批问题全部做完，建议顺序如下：

1. 先补模型输入模态能力元数据
2. 再补会话输入能力合同
3. 再补组优先会话 view data 合同
4. 再补附件暂存状态与桌面 picker
5. 再补 typed chat request / attachment 合同
6. 再补 gateway 附件适配
7. 附件链路先停在“内部可测试、默认不开放”
8. 再补会话请求运行句柄与 cancel token
9. 再补 stop UI 与取消状态表达
10. 最后做右栏压缩、左栏减噪和整体视觉回归

这个顺序的核心原因是：

- 先立能力事实源
- 再立请求运行边界
- 最后再抛光 UI

---

## 13. 最终结论

这批剩余问题，全部都能完成。

但其中最重的两条：

- 附件
- 真停止

都不是“再补一个按钮”的工作量，而是：

**需要补正式合同、补宿主边界、补 core 请求模型、补 adapter 能力、补 UI 投影的整链工程。**

这也正说明，后续不该再用“能不能实现”来划分，而该用：

- 这是单会话任务
- 还是多链路重构任务

来划分。

对当前项目来说，正确答案是：

**可以通过后续多轮任务链，把这些问题全部完成；关键不是难不难，而是要按职责边界拆开做。**
