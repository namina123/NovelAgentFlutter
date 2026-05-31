# NovelAgentFlutter 工作台剩余问题实施顺序文档

最后更新：2026-05-29

关联文档：

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

---

## 0.17 Session WR-17 完成记录

- 已完成 `Session WR-17：总联调、探针、截图与打包前回归`
- 本轮只做闭环验证与产物回填，没有继续开新功能线。
- 本轮新增 / 收口内容：
  - 新增 `apps/novel_agent_app/test/workbench_wr17_probe_test.dart`
    - 验证打开已有项目
    - 验证当前项目切换智能体组后，主智能体派生显示同步更新
    - 验证 reasoning toggle 按模型能力动态出现
    - 验证附件公开入口仍未显示
    - 验证 stop 可真实取消，且取消后有正式 notice 与 retry 入口
    - 验证长任务项目只暴露唯一启动动作 `opening.launch_long_task`
  - 新增 `apps/novel_agent_app/test/workbench_wr17_regression_test.dart`
    - 回归生成中公开 stop 按钮显示
    - 回归不支持 reasoning 的模型不显示 toggle
    - 产出 WR-17 截图基线
- 本轮还顺手修正了 WR-17 截图测试的验证方式：
  - 去掉 widget test 里的真实异步文件 I/O
  - 改为 Flutter golden 路径直写到仓库 `artifacts/wr17_screenshots`
  - 避免测试被 fake async 文件操作卡住
- 本轮产物：
  - 探针报告：`artifacts/workbench_wr17_probe_report.json`
  - 截图：
    - `artifacts/wr17_screenshots/wr17_long_task_opening.png`
    - `artifacts/wr17_screenshots/wr17_generating_stop.png`
- 本轮验证结果：
  - `flutter analyze lib test`（`apps/novel_agent_app`）
  - `flutter test test/workbench_wr17_probe_test.dart -r expanded`
  - `flutter test test/workbench_wr17_regression_test.dart --update-goldens -r expanded`
  - `flutter test test/workbench_wr17_regression_test.dart -r expanded`
  - 全部通过
- 本轮确认结论：
  - 当前项目切组后，主智能体显示已按组优先合同正确投影
  - reasoning toggle 已变为真正的模型能力驱动显示
  - stop 已落到正式运行句柄，取消后状态与提示一致
  - 长任务开局入口已收束为单一明确动作
  - 附件链路仍保留在内部能力层，但没有对用户公开入口
- 当前这条线已经达到打包前回归要求，可继续进入后续真正的新任务；`WR-17` 本身已完成。

---

## 0.16 Session WR-16 完成记录

- 已完成 `Session WR-16：全局边框 / 分栏减噪回归`
- 本轮没有改业务边界，只处理桌面工作台里的视觉壳层重复：
  - 收掉一层全局总边框
  - 收掉每栏内部的二次内框
  - 把部分“卡片里的卡片”改回轻量段落或弱底色块
- 本轮主要收口点：
  - `WorkbenchDesktopSurface`
    - 去掉总外框
    - 顶部覆层压薄，避免再像一整块调试框架
  - `WorkbenchPaneShell`
    - 去掉每栏统一的内层 framed card
    - 只保留必要的左右分栏边界和底色
  - `ResourcePanelSection` / `ResourceTreeCard`
    - 资源区 section 默认不再强制自带边框
    - 文件树从“外层 section + 内层树卡”收成单层目录块
  - `ConversationEmptyStatePanel` / `WorkflowGuideCard` / `OpeningSessionPanel`
    - 去掉会话区内部这些大块提示卡的额外边框
    - 保留信息，不再重复造盒子
  - `ConversationPrimaryAgentBar`
    - 从边框卡片改成轻量底色摘要区
  - `DocumentWorkspaceHeaderPanel` / `DocumentTabStrip`
    - 文档头部从完整边框盒改成轻 header
    - 非激活标签不再全部描边，只给激活项保留明确状态
  - `WorkbenchActivityRail`
    - 收窄宽度
    - 未选中项不再统一描边，只保留选中态强调
- 本轮刻意保留的较重结构：
  - `DocumentWorkspaceCanvasFrame`
    - 仍保留正式内容画布边界，因为它承担文稿主体、状态和编辑区的唯一对象边界
  - `ConversationComposerPanel`
    - 仍保留输入坞主表面，因为状态摘要、模型条和发送区需要稳定合并成一个正式操作区
- 本轮没有做：
  - 没有改布局合同
  - 没有继续裁撤功能入口
  - 没有重做配色系统
  - 没有进入下一轮 CLI 对齐或业务重构
- 本轮验证结果：
  - `flutter analyze lib test`（`apps/novel_agent_app`）
  - `flutter test test/widget_test.dart test/conversation_guide_view_data_service_test.dart test/conversation_empty_state_action_projection_service_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-17`

---

## 0.15 Session WR-15 完成记录

- 已完成 `Session WR-15：长任务启动动作收口`
- 本轮把长任务项目在会话区的默认入口收束成一个 app 层唯一动作：
  - 新增 `LongTaskStartActionPolicyService`
  - 长任务项目不再在空态 / grounded guide 中直接暴露多组长任务动作
  - 当前默认统一显示 `opening.launch_long_task`
- 这次没有改 core opening 编排真相源，而是在 app 层做了薄投影：
  - `ConversationGuideViewDataService` 现在会为长任务项目优先注入唯一启动动作
  - `ConversationOpeningGuideViewDataService` 的长任务 guide 也改为只渲染这个唯一动作
  - 普通项目仍走原有 opening / session goal 链路，不被长任务入口污染
- 本轮同时把“唯一动作”接回现有 opening 链路，而没有重新发明一套状态机：
  - `WorkbenchConversationController` 新增 `opening.launch_long_task`
  - 点击后会读取当前 `openingProjection`
  - 再路由到已有的：
    - `opening.choose_long_task_mode`
    - `opening.open_mode_guidance`
    - `opening.continue_mode_guidance`
    - `opening.start_long_task_run`
- 这让主工作台层面稳定满足：
  - 长任务相关项目存在唯一明确启动动作
  - 非长任务项目不显示该入口
  - 后续缺口继续沿用既有 opening / mode guidance 链路补齐
  - 没有引入新页面
- 本轮没有做：
  - 没有重做全部模式引导文案
  - 没有删除 mode guidance 内部现有阶段动作
  - 没有改 stop / 运行控制链路
- 本轮补了 focused test：
  - `apps/novel_agent_app/test/long_task_start_action_policy_service_test.dart`
  - 更新 `apps/novel_agent_app/test/conversation_guide_view_data_service_test.dart`
  - 并回归：
    - `apps/novel_agent_app/test/conversation_empty_state_action_projection_service_test.dart`
    - `apps/novel_agent_app/test/project_opening_session_projection_service_test.dart`
- 本轮验证结果：
  - `flutter analyze lib test`（`apps/novel_agent_app`）
  - `flutter test test/conversation_guide_view_data_service_test.dart test/conversation_empty_state_action_projection_service_test.dart test/long_task_start_action_policy_service_test.dart test/project_opening_session_projection_service_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-16`
  - 处理全局边框 / 分栏减噪回归

---

## 0.14 Session WR-14 完成记录

- 已完成 `Session WR-14：附件 adapter 能力桥接`
- 本轮把附件 typed contract 继续向 adapter 能力层推进，但仍保持非公开能力：
  - 新增 `ChatRequestCapability`
  - `ChatRequest` 现在正式携带附件能力画像，而不再只带附件列表
  - `GenerateDraftUseCase` 已把 `modelProfile` 中的附件能力投影进 typed request
- 本轮新增了独立的 adapter 附件策略层：
  - `OpenAiAttachmentBridgePolicy`
  - `OpenAiAttachmentBridgeAssessment`
  - `OpenAiAttachmentSupportMode`
- 当前 adapter 已能识别并区分这些情况：
  - `unsupported`
    - 当前 provider / model 完全不支持附件
    - 当前 provider / model 不支持多附件
  - `urlOnly`
    - 当前 provider / model 只支持 URL 附件
    - 本地文件直传会稳定失败并给出原因
    - 即使是 URL-only 且附件本身可用，也会明确提示“URL 附件桥接尚未实现”
  - `native`
    - 当前 provider / model 声明支持原生文件或图片附件
    - 但当前 OpenAI 兼容附件 payload bridge 仍未实现
    - 会稳定失败并给出明确说明，而不是退回模糊报错
- 本轮把“一刀切 UnsupportedError”升级成了 provider-aware 的稳定失败：
  - `OpenAiChatRequestPayloadBuilder` 不再只说“附件未接入”
  - 现在会基于 typed capability 先做策略评估
  - 评估通过前不会默默降级成文本，也不会偷偷改写语义
- 本轮没有做：
  - 没有开放附件按钮
  - 没有实现最终的 URL / native payload 映射
  - 没有把附件混进项目导入或正文上下文降级链路
- 本轮补了 focused test：
  - `packages/novel_agent_adapters/test/openai_attachment_bridge_policy_test.dart`
  - `packages/novel_agent_adapters/test/openai_chat_request_payload_builder_test.dart`
  - 并回归：
    - `packages/novel_agent_adapters/test/openai_llm_gateway_test.dart`
    - `packages/novel_agent_core/test/llm_gateway_legacy_bridge_test.dart`
    - `packages/novel_agent_core/test/draft_generation_use_case_test.dart`
- 本轮验证结果：
  - `dart analyze lib test`（`packages/novel_agent_core`）
  - `dart analyze lib test`（`packages/novel_agent_adapters`）
  - `flutter analyze lib tool test`
  - `dart test test/llm_gateway_legacy_bridge_test.dart test/draft_generation_use_case_test.dart`（`packages/novel_agent_core`）
  - `dart test test/openai_attachment_bridge_policy_test.dart test/openai_chat_request_payload_builder_test.dart test/openai_llm_gateway_test.dart`（`packages/novel_agent_adapters`）
  - 全部通过
- 下一轮可直接进入 `WR-15`
  - 处理长任务启动动作收口
  - 附件链路继续保持内部就绪、公开关闭

---

## 0.13 Session WR-13 完成记录

- 已完成 `Session WR-13：附件宿主与暂存内部链路`
- 本轮把“会话附件”正式从“项目导入文件”职责里拆开：
  - 新增 `ConversationAttachmentPickerService`
  - 新增 `DesktopConversationAttachmentPickerService`
  - 附件选择不再复用项目导入 picker
  - Windows / macOS / Linux 的对话框标题与语义都已切成“会话附件”
- 本轮建立了独立的附件暂存状态模型：
  - 新增 `ConversationAttachmentDraft`
  - 新增 `ConversationAttachmentViewData`
  - 新增 `ConversationAttachmentDraftService`
  - 新增 `ConversationAttachmentViewDataService`
- 当前附件暂存链路已经具备这些内部能力：
  - 根据本地路径探测附件是否存在
  - 识别基础图片 / 文件媒体种类
  - 生成 mime type / size / 失败信息
  - 按本地路径去重合并多次选择结果
  - 为后续 `ChatInputAttachment` 转换保留 ready-only bridge
- 本轮把附件暂存正式挂进了会话状态，而不是 widget 局部状态：
  - `ConversationSessionState` 新增 `attachmentDrafts`
  - `ConversationSessionStateService.stateWithAttachmentDrafts()` 统一写入
  - `stateWithUserPrompt()` 会在本轮发送时清空当前轮附件暂存
- 控制器侧已接入内部编排，但仍保持产品入口关闭：
  - `WorkbenchConversationController.onAttachmentRequested()` 现在会走真实 picker + draft staging
  - 仍会先经过内部 capability 判断
  - 当前产品公开策略未改，附件按钮继续不显示
  - 因此本轮是“内部可测试、默认不开放”，没有改任何公开会话 UI
- 本轮没有做：
  - 没有把附件发送进 provider
  - 没有开放附件按钮
  - 没有把附件链路混进项目导入流程
- 本轮补了 focused test：
  - `conversation_attachment_draft_service_test.dart`
  - `conversation_attachment_view_data_service_test.dart`
  - `conversation_session_state_service_test.dart`
  - `conversation_streaming_state_service_test.dart`
- 本轮验证结果：
  - `flutter test test/conversation_attachment_draft_service_test.dart test/conversation_attachment_view_data_service_test.dart test/conversation_session_state_service_test.dart test/conversation_streaming_state_service_test.dart`
  - `flutter analyze lib test`
  - `dart analyze lib test`（`packages/novel_agent_core`）
  - 全部通过
- 下一轮可直接进入 `WR-14`
  - 开始做附件 adapter 能力桥接
  - 继续保持公开入口关闭

---

## 0.12 Session WR-12 完成记录

- 已完成 `Session WR-12：附件 typed request 合同`
- 本轮把 LLM 请求从散装参数正式收成了 typed request 合同：
  - 新增 `ChatRequest`
  - 新增 `ChatInputAttachment`
  - 新增 `AttachmentMediaKind`
- 当前 `LlmGateway` 已改成 typed entrypoint：
  - `requestChat()` 现在接受 `ChatRequest`
  - 新增 `requestChatLegacy()` 兼容桥
  - `requestText()` 现在也通过 typed request bridge 复用同一条合同
- 本轮把历史 prompt/options 兼容逻辑从 adapter 收回到了 core：
  - `ChatRequest.fromLegacy()` 负责把旧 `options.prompt` 折叠成正式 user message
  - adapter 不再自己解释 `options.prompt`
  - 附件不再需要继续规划为塞回 `requestOptions`
- 本轮同时把 adapter payload 组装从大文件里拆出：
  - 新增 `OpenAiChatRequestPayloadBuilder`
  - `OpenAiLlmGateway` 只负责 transport / stream / retry / cancel
  - request payload 组装职责单独收口
- 当前附件位已经正式进入 core / adapter 边界，但仍保持内部未开放：
  - `ChatRequest.attachments` 已可表达输入附件
  - `OpenAiChatRequestPayloadBuilder` 当前遇到附件会稳定抛出 `UnsupportedError`
  - 这是刻意边界：本轮只立 typed contract，不提前猜测 provider 附件协议
- 本轮已迁移的调用点：
  - `GenerateDraftUseCase`
  - `SubAgentExecutionService`
  - `OpenAiLlmGateway`
  - 相关 fake gateway / probe
- 本轮补了 focused test：
  - `packages/novel_agent_core/test/llm_gateway_legacy_bridge_test.dart`
  - `packages/novel_agent_core/test/draft_generation_use_case_test.dart`
  - `packages/novel_agent_adapters/test/openai_chat_request_payload_builder_test.dart`
  - `packages/novel_agent_adapters/test/openai_llm_gateway_test.dart`
- 本轮验证结果：
  - `dart analyze lib test`（`packages/novel_agent_core`）
  - `dart analyze lib test`（`packages/novel_agent_adapters`）
  - `flutter analyze lib tool test`
  - `dart test test/draft_generation_use_case_test.dart test/llm_gateway_legacy_bridge_test.dart`（`packages/novel_agent_core`）
  - `dart test test/openai_llm_gateway_test.dart test/openai_chat_request_payload_builder_test.dart`（`packages/novel_agent_adapters`）
  - 全部通过
- 下一轮可直接进入 `WR-13`
  - 建立附件宿主与暂存内部链路
  - 继续保持默认不开放任何公开附件入口

---

## 0.11 Session WR-11 完成记录

- 已完成 `Session WR-11：停止能力接回工作台 UI`
- 本轮把已经具备的取消链路正式投影回了工作台输入区与时间线：
  - 工作台输入能力事实源已开放 `productExposesStopAction`
  - 生成态输入区现在会正式显示 `停止`
  - 点击 stop 会调用真实取消链路，而不是继续显示占位提示
- 本轮还补了停止过程中的即时状态映射：
  - 用户点击 stop 后，`generationStatus` 会先变成“正在停止当前生成...”
  - `toolCoreStatus` 会提示“正在等待当前流式步骤结束。”
  - 后续再由正式 cancelled result 收口最终状态
- 取消后的时间线 / 重试行为也已经按合同表达：
  - `cancelledByUser + partialContentAccepted = true`
    - 保留助手已生成内容
    - 追加 `本轮已停止` 的 runtime notice
    - 不额外弹失败式重试横幅
  - `cancelledByUser + partialContentAccepted = false`
    - 追加 `本轮已停止` 的 runtime notice
    - 生成 `重试这次已停止请求` 入口
    - 不使用失败态红色文案
- 本轮同时把 retry label 从固定失败文案改成了 request 自带标签：
  - 失败仍显示 `重试上次失败请求`
  - 停止可显示 `重试这次已停止请求`
- 状态摘要区现在也能正确消费取消后的状态文案：
  - 不再把 cancelled 混进 failed
  - 生成结束后 runtime summary 会显示停止态摘要，而不是仍显示“生成中”
- 本轮补了 focused test：
  - `conversation_input_capability_service_test.dart`
  - `conversation_input_dock_test.dart`
  - `conversation_session_state_service_test.dart`
  - `conversation_status_summary_view_data_service_test.dart`
- 本轮验证结果：
  - `flutter test test/conversation_input_dock_test.dart test/conversation_input_capability_service_test.dart test/conversation_session_state_service_test.dart test/conversation_status_summary_view_data_service_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-12`
  - 开始把附件链路收成 typed request 合同
  - 但仍不开放任何公开附件 UI

---

## 0.10 Session WR-10 完成记录

- 已完成 `Session WR-10：gateway 合作式中断接线`
- 本轮把 cooperative cancellation 从 core 合同继续接到了 gateway / adapter transport：
  - `LlmGateway.requestChat()` 新增了 `DraftGenerationCancellationToken`
  - `GenerateDraftUseCase` 已把 core cancellation token 继续传给 gateway
  - `WorkbenchConversationController` 现有 app token -> core token -> gateway token 链已经打通
- `OpenAiLlmGateway` 现在会在 transport 层响应取消：
  - 新增 `OpenAiGatewayCancellationScope`
  - 取消时会主动关闭当前 `HttpClient`
  - 流式读取会尽快停止，不再继续向后消费后续 chunk
  - 取消时不会再补发 completed stream update
- 本轮还顺手修正了一个真实 transport 判定缺口：
  - 流式响应如果在没收到 `[DONE]` 前就断开，现在会被视为“流式传输中断”
  - 该错误已纳入 transport retry 判定
  - 因此首轮断流、次轮成功的兼容网关场景现在能稳定重试
- 当前边界仍然刻意收在合作式 transport stop：
  - 不改 stop UI
  - 不扩工具执行强制杀掉逻辑
  - 不动附件适配
- 本轮补了 focused test：
  - `packages/novel_agent_adapters/test/openai_llm_gateway_test.dart`
    - 覆盖流式断流重试
    - 覆盖 cancellation token 提前截断流式读取
- 本轮验证结果：
  - `dart test test/openai_llm_gateway_test.dart`
  - `dart analyze lib test`（`packages/novel_agent_adapters`）
  - `dart analyze lib test`（`packages/novel_agent_core`）
  - `flutter analyze lib tool test`
  - `flutter test test/conversation_request_cancellation_token_test.dart test/conversation_request_runtime_service_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-11`
  - 把真实停止能力接回工作台 UI action
  - 正确投影 cancelled 状态到时间线与状态文案

---

## 0.9 Session WR-09 完成记录

- 已完成 `Session WR-09：core 取消合同与结果状态扩展`
- 本轮把 cooperative cancellation 正式下沉到了 core：
  - 新增 `DraftGenerationCancellationToken`
  - 新增 `DraftGenerationStopPhase`
  - `GenerateDraftUseCase.execute()` 已支持取消令牌
- `DraftGenerationProgress` 与 `DraftGenerationResult` 现在都能正式表达：
  - `cancelledByUser`
  - `stopPhase`
  - `partialContentAccepted`
- 本轮保持了“取消不是失败”的分流：
  - 取消返回正式 `DraftGenerationResult`
  - 失败仍然抛异常
  - app runtime 句柄现在也能落到 `cancelled` 状态，而不是误记为 `succeeded`
- 当前取消仍然是合作式，不是 gateway 真中断：
  - 在上下文准备、技能预加载、llm 回合、工具执行、结果收尾阶段都会检查取消令牌
  - 流式内容若已部分收到，会尽量作为 partial result 保留
  - 还没有中断底层 HTTP / stream 读取
- app 侧已完成最小接线：
  - `WorkbenchConversationController` 会把 app request token 桥接到 core cancellation token
  - 取消后的生成状态文案已与普通成功分开
  - 取消结果不会继续触发自动补保存
- 本轮补了 focused test：
  - `packages/novel_agent_core/test/draft_generation_use_case_test.dart`
  - `apps/novel_agent_app/test/conversation_request_runtime_service_test.dart`
- 本轮验证结果：
  - `dart test test/draft_generation_use_case_test.dart`
  - `dart analyze lib test`
  - `flutter test test/conversation_request_cancellation_token_test.dart test/conversation_request_runtime_service_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-10`
  - 把 cooperative cancellation 从 core 合同继续接到 gateway / adapter 传输层
  - 开始让停止请求真正影响流式读取过程

---

## 0.8 Session WR-08 完成记录

- 已完成 `Session WR-08：会话请求运行合同与句柄`
- 本轮把“当前轮生成请求”从 controller 里的裸异步流程收成了正式运行合同：
  - 新增 `ConversationRequestCancellationToken`
  - 新增 `ConversationRequestHandle`
  - 新增 `ConversationRequestRuntimeService`
- 当前请求现在拥有正式句柄与生命周期状态：
  - `running`
  - `cancellationRequested`
  - `succeeded`
  - `failed`
- `WorkbenchConversationController` 不再自己直接管理 progress coalescer 与 completer：
  - 请求启动改由 runtime service 托管
  - controller 只保留发送前准备、progress 投影、成功回写、失败回写
  - stop 请求正式挂到了当前活动 handle 上
- 本轮 stop 仍然是合作式取消边界，不做真实 provider 中断：
  - 已能记录取消意图
  - 已能阻止取消后的后续 progress 继续刷回 UI
  - 尚未改 core result taxonomy，也未接 gateway 真取消
- 本轮还补了 focused test：
  - `conversation_request_cancellation_token_test.dart`
  - `conversation_request_runtime_service_test.dart`
- 本轮验证结果：
  - `flutter test test/conversation_request_cancellation_token_test.dart test/conversation_request_runtime_service_test.dart`
  - `flutter analyze lib/features/workbench/application test/conversation_request_cancellation_token_test.dart test/conversation_request_runtime_service_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-09`
  - 把 cooperative cancellation 正式下沉到 core use case
  - 分离 cancelled / failed / partial result 的合同表达

---

## 0.7 Session WR-07 完成记录

- 已完成 `Session WR-07：左栏项目面板去工具条化`
- 本轮把左栏项目面板从“小图标工具条 + 多层 section 盒子”收成了真正的项目侧栏：
  - 删除了 `ProjectActionGroup`
  - 项目动作不再用小图标工具条表达
  - 外层重复 section 壳已经明显减少
- 当前项目面板现在按语义分成更稳定的四段：
  - `项目摘要`
  - `当前项目动作` / `开始项目`
  - `项目协作配置`
  - `项目资料与规则`
- 本轮保留但收口了必要动作：
  - 有项目时只保留 `项目信息`、`刷新项目`
  - 无项目时只保留 `打开项目`、`新建项目`
  - 不再在项目侧栏里长期并排展示四个同质图标动作
- 本轮同时明确了配置区边界：
  - `项目智能体组`、`智能体生态` 收到 `项目协作配置`
  - `项目资产与表达限制`、`提示模板` 留在 `项目资料与规则`
- 本轮没有做：
  - 没有重做资源树
  - 没有改右栏能力判断
  - 没有扩新项目操作
- 本轮验证结果：
  - `flutter test test/workbench_project_panel_test.dart test/workbench_navigation_sidebar_test.dart test/resource_manager_panel_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-08`
  - 开始把当前轮请求收成正式运行句柄
  - 继续把运行期细节从控制器里拆出来

## 0.6 Session WR-06 完成记录

- 已完成 `Session WR-06：右栏 group-first composer strip 重排`
- 本轮把右栏底部正式收成了更像协作区的连续 composer：
  - 状态摘要、模型/智能体组选择、主智能体只读摘要、输入区现在处于同一连续表面
  - 不再是“状态区 / 选择区 / 输入区”三块割裂 panel
- 本轮完成的 group-first 收束：
  - `ConversationModelStrip` 现在只保留真正可切换的两个入口：`模型`、`智能体组`
  - 主智能体已改成只读摘要，不再伪装成平级选择器
  - 新增 `ConversationPrimaryAgentBar` 承接主智能体说明与 reasoning toggle
- 本轮把 reasoning toggle 投影回了工作台输入区附近：
  - `ConversationActionHandler` 新增 reasoning toggle 动作合同
  - `WorkbenchConversationController` 现会把开关写回共享模型设置
  - 仍未开放附件公开入口
- 本轮保持了拆耦边界：
  - `ConversationPanelStatusGroup` 继续只吃 `WR-05` 的紧凑状态投影
  - `ConversationModelStrip` 只负责 selector strip
  - `ConversationPrimaryAgentBar` 只负责只读主智能体摘要与 reasoning toggle
  - `ConversationComposerPanel` 负责连续 composer 布局组合
- 本轮没有做：
  - 没有改左栏项目面板
  - 没有扩新业务能力
  - 没有接 stop 真中断
- 本轮验证结果：
  - `flutter test test/conversation_sidebar_test.dart test/conversation_input_dock_test.dart test/workbench_canvas_workspace_shell_test.dart test/workbench_navigation_sidebar_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-07`
  - 继续处理右栏压缩与 composer 周边剩余收口
  - 保持“先合同、后布局细化”的节奏

## 0.5 Session WR-05 完成记录

- 已完成 `Session WR-05：右栏状态摘要投影服务`
- 本轮把右栏状态区从“多个组件各自拼文案”收束成了统一投影链：
  - 新增 `ConversationStatusSummaryItemKind`
  - 新增 `ConversationStatusSummaryItemViewData`
  - 新增 `ConversationStatusSummaryViewData`
  - 新增 `ConversationStatusSummaryViewDataService`
- 当前右栏状态区已经改成 `chip 优先 + 轻量展开说明` 的结构：
  - `上下文`
  - `工具`
  - `运行`
- 本轮同时明确了状态语义职责边界：
  - `ConversationStatusSummaryViewDataService` 负责把上下文、工具显示和运行态压缩成紧凑摘要
  - `ConversationPanelStatusGroup` 只负责渲染和点击转发
  - `ConversationSidebar` 只负责把本地 `tool visibility` UI 偏好喂给投影层
- 当前已保留后续扩展余地：
  - tool chip 可展开说明
  - context / runtime 明细文案已进入 view data，可后续接更正式的明细面板
  - 没有把这些说明重新塞回 widget 内部条件判断
- 本轮没有做：
  - 没有改 composer 布局
  - 没有压缩左栏
  - 没有做更重的视觉改版
- 本轮验证结果：
  - `flutter test test/conversation_status_summary_view_data_service_test.dart test/conversation_sidebar_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-06`：
  - 继续处理会话区与输入区相关的收口任务
  - 保持“先收语义合同，再改布局”的节奏

## 0.4 Session WR-04 完成记录

- 已完成 `Session WR-04：项目级智能体组稳定入口`
- 本轮把“项目默认智能体组”的正式入口从 opening 补充入口中拆了出来，并固定到项目面板：
  - 新增 `ProjectAgentGroupPanelViewData`
  - 新增 `ProjectAgentGroupPanelViewDataService`
  - `WorkbenchWorkspaceShellViewData` 现正式携带 `projectAgentGroupPanel`
- 当前项目面板已具备稳定协作配置入口：
  - 新增 `项目协作配置` 区块
  - `项目智能体组` 动作统一进入项目级配置浮层
  - 未打开项目时会回落为“先打开项目”的明确引导
- 本轮同时明确了三层职责边界：
  - opening 面板：只负责开局阶段补充与快速切换
  - 会话栏入口：只负责轻量快速切换
  - 项目面板入口：负责当前项目的正式默认组配置
- 当前项目级配置浮层已独立建模，不再把 project-level 配置继续塞回 opening 语义：
  - 新增 `ProjectAgentGroupWorkspaceViewData`
  - 新增 `ProjectAgentGroupWorkspaceViewDataService`
  - 新增 `ProjectAgentGroupOverlay`
  - `WorkbenchWorkspaceController` 已接入请求 / 关闭 / 选择组的完整动作链
- 本轮没有做：
  - 没有压缩右栏
  - 没有改模型选择器与输入区布局
  - 没有做视觉减噪大扫除
- 本轮验证结果：
  - `flutter test test/project_agent_group_panel_view_data_service_test.dart test/project_agent_group_workspace_view_data_service_test.dart test/workbench_project_panel_test.dart test/resource_manager_panel_test.dart test/workspace_command_overlay_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
  - `flutter analyze lib test`
  - 全部通过
- 下一轮可直接进入 `WR-05`：
  - 开始把右栏状态区收束成紧凑摘要投影
  - 继续避免让组件自己拼上下文 / 工具 / 运行状态语义

## 0.3 Session WR-03 完成记录
- 已完成 `Session WR-03：建立 group-first 会话选择合同`
- 本轮已把会话主入口正式从“单智能体选择”收束为“项目智能体组选择 + 主智能体只读摘要”：
  - `OpeningSessionProjection` 新增 `currentPrimaryAgentSummary`
  - `ProjectOpeningSessionProjectionService` 现会直接从当前组选出主智能体摘要
  - 新增 `ConversationGroupSelectorViewData`
  - 新增 `ConversationGroupSelectorViewDataService`
- 当前 group-first 合同已经贯通到工作台视图链路：
  - `WorkbenchViewData`
  - `WorkbenchConversationViewData`
  - `WorkbenchPaneViewDataMapperService`
  - `ConversationModelStrip`
  - `ConversationPanelHeader`
- 当前会话栏语义已调整为：
  - 模型选择
  - 智能体组选择
  - 主智能体只读摘要
- 本轮同时收口了两个关联边角：
  - opening 面板与会话栏已共用同一条 `onAgentGroupSelected` 项目默认组切换动作
  - 输入能力判断会优先读取当前组解析出的主智能体 reasoning 能力，而不是只看旧默认单智能体设置
- 当前已去掉的旧合同：
  - 会话栏第二选择器不再建模为单智能体
  - `WorkbenchWorkspaceController` 不再持有旧 `agentOptionsBuilder`
- 本轮没有做：
  - 没有压缩右栏布局
  - 没有改左栏项目面板整体布局，只做了协作基线文案语义对齐
  - 没有接 stop 链路
- 本轮验证结果：
  - `flutter analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - `flutter test test/conversation_empty_state_action_projection_service_test.dart test/conversation_group_selector_view_data_service_test.dart test/conversation_input_dock_test.dart test/conversation_sidebar_test.dart test/project_opening_session_projection_service_test.dart test/workbench_canvas_workspace_shell_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_project_panel_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-04`：
  - 把项目级智能体组入口从 opening / 空态继续扩成稳定常驻入口
  - 继续清掉剩余单智能体入口残留

## 0.2 Session WR-02 完成记录

- 已完成 `Session WR-02：建立输入能力投影合同 V2`
- 本轮已新增正式输入能力合同与投影层：
  - `ConversationInputCapabilityContext`
  - `ConversationInputPublicExposurePolicy`
  - `ConversationInputCapabilityResolver`
  - `ConversationInputCapabilityContextBuilderService`
  - `ConversationInputCapabilityService` 现已退化为轻量 facade
- 当前输入能力已不再只看 `isGenerating`：
  - 已联合接入
    - 当前平台是否支持桌面附件选择
    - 当前模型 reasoning / attachment 能力
    - 当前主智能体是否允许 reasoning
    - 当前运行态
    - 当前产品公开开关
- 当前已明确区分两层：
  - `internal capability`
  - `publicly exposed action`
- 当前收束结果：
  - reasoning toggle 已进入 capability projection
  - stop 已能作为内部能力投影，但公开入口继续关闭
  - attachment 已能作为内部能力投影，但公开入口继续关闭
  - tool options / optimize 继续通过产品公开策略保持关闭
- 本轮接线范围：
  - `AppShellController` 会在设置与智能体生态刷新后统一生成输入 capability context
  - `WorkbenchViewData -> WorkbenchConversationViewData -> ConversationSidebar` 已能稳定传递该 context
  - widget 仍只消费 `ConversationInputCapabilityState`，没有把判断塞回侧栏或按钮组件
- 本轮没有做：
  - 没有重做会话 UI 布局
  - 没有开放附件按钮
  - 没有接通真实 stop 中断链路
- 本轮验证结果：
  - `flutter test test/conversation_input_capability_service_test.dart test/conversation_input_dock_test.dart test/conversation_empty_state_action_projection_service_test.dart`
  - `flutter analyze lib/features/workbench lib/app/state/app_shell_controller.dart test/conversation_input_capability_service_test.dart test/conversation_input_dock_test.dart test/conversation_empty_state_action_projection_service_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-03`：
  - 把当前项目协作选择正式收束为 `智能体组`
  - 当前主智能体改为组解析结果
  - 让 capability context 后续从 group-first 主成员语义继续接力，而不是只看默认单智能体

## 0.1 Session WR-01 完成记录

- 已完成 `Session WR-01：补模型输入模态能力元数据`
- 本轮已把附件输入模态能力正式收进统一能力事实源：
  - `supports_file_attachments`
  - `supports_image_attachments`
  - `supports_attachment_urls_only`
  - `supports_multi_attachments`
- 已打通的传播链：
  - `ProviderCapabilityResolver` 种子默认值与 provider 规则
  - `ProviderProfileNormalizerService` 模型骨架与归一化
  - `ProviderRuntimeProfileService` 运行态组装与目录默认值回填
  - `ProviderModelMetadataService` 编辑元数据投影
  - `ModelSettingsViewDataService`
  - `ModelEditorViewData`
- 当前实现边界已明确：
  - 这些能力现在只作为内部事实源与可消费视图数据存在
  - 本轮没有开放任何附件公开入口
  - 本轮没有改工作台右栏、composer 或设置页布局
- 当前保守能力样本：
  - `Anthropic` 规则已作为正例，支持文件附件、图片附件与多附件
  - 其他 provider 若无明确规则，继续保持默认关闭
- 本轮验证结果：
  - `dart test test/provider_profile_service_test.dart test/provider_model_metadata_service_test.dart`
  - `flutter test test/model_settings_view_data_service_test.dart`
  - `dart analyze lib test`
  - `flutter analyze lib/features/settings test/model_settings_view_data_service_test.dart`
  - 全部通过
- 下一轮可直接进入 `WR-02`：
  - 基于这套能力事实源建立 `ConversationInputCapabilityContext / Resolver`
  - 区分 `internal capability` 与 `publicly exposed action`
  - 保持附件能力内部存在但公开入口继续关闭

## 1. 这份文档的定位

这是一份新的合并后执行文档。

它吸收并继续推进两条线：

1. `group-first` 协作栏重构线
2. `workbench remaining chain` 剩余链路补完线

如果后续任务安排与下面文档冲突：

- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`

则以后续实现顺序、依赖关系和边界判断为准，优先使用本文件。

这不是“只修样式”的文档，而是：

**把组优先、输入能力、停止链路、附件内部链路、界面减噪，全部拆成可持续推进的一串正式 session。**

---

## 2. 总目标

后续这条线的最终目标是：

1. 当前项目协作正式以 `智能体组` 为主入口
2. 输入区能力由正式 capability contract 投影，而不是硬编码开关
3. 深度思考能力按模型 / 当前主智能体 / 当前运行态动态出现
4. 停止当前生成成为真实能力，而不是占位按钮
5. 附件链路完成内部合同与未来边界，但当前阶段不开放任何公开入口
6. 左右两栏从“调试感和工具栏感”收束成正式协作界面
7. 所有新增逻辑都遵守：
   - 单一职责
   - 小文件
   - 分层清晰
   - 尽量让 GUI / CLI 未来共享同一能力事实源

---

## 3. 当前总策略

## 3.1 先合同，后 UI

必须先补：

- 模型输入模态能力
- group-first 会话合同
- 输入 capability 合同
- 会话请求运行与取消合同

然后再做：

- 右栏紧凑化
- 左栏减噪
- 全局视觉回归

## 3.2 附件当前不开放公开入口

这是当前正式产品决策：

- 不在会话区显示附件按钮
- 不在空态显示附件入口
- 不把附件做成用户当前可见功能

但：

- 要把内部链路分析清楚
- 要保留未来接入边界
- 要补能力合同与测试接缝

## 3.3 停止能力要先做合作式取消

本线不要求一开始就支持“强制中断所有底层动作”。

第一阶段的 stop 目标是：

1. 能中断当前流式请求
2. 能阻止继续进入下一轮
3. 能把状态正确标成 `cancelled`

---

## 4. 总执行规则

后续按本文件推进时，默认遵循：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或出现强关联回归，先补完，不开启下一轮。
3. 优先拆 service / contract / projection，不把判断继续塞回大 widget 或大 controller。
4. 单文件超过 `400` 行要复核职责；超过 `700` 行原则上先拆。
5. 先让能力事实源稳定，再做界面压缩。
6. 合适时补 focused test，不把验证长期留在手工点击。
7. 附件相关 session 即使完成，也不要顺手开放公开 UI。

---

## 5. 推荐总顺序

推荐按下面四条轨道的依赖顺序推进：

1. `模型能力轨`
2. `group-first 协作轨`
3. `输入与请求运行轨`
4. `工作台减噪轨`

更细的自然顺序是：

1. 模型能力元数据
2. 输入能力合同
3. group-first 会话 view data
4. 项目级智能体组稳定入口
5. 右栏组优先与摘要压缩
6. 左栏项目面板收口
7. 停止链路
8. 附件内部链路
9. 长任务启动动作收口
10. 全局视觉回归与联调

---

## 6. Session WR-01：补模型输入模态能力元数据

### 本轮目标

先把模型 / provider 对会话输入模态的能力表达补齐，作为后续输入 capability 的事实源。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 扩展 provider / model metadata，至少能表达：
   - `supports_reasoning`
   - `supports_file_attachments`
   - `supports_image_attachments`
   - `supports_attachment_urls_only`
   - `supports_multi_attachments`
2. 补齐 capability seed / metadata builder / editor metadata 的传播链
3. 保持这些能力不写死在 Flutter widget 里
4. 为后续输入 capability service 提供稳定读取口

### 本轮不要做

- 不改右栏 UI
- 不改 composer
- 不开放附件入口

### 本轮重点拆耦

- `provider capability seed`
- `model metadata projection`
- `UI-independent capability contract`

### 完成判定

- 模型输入模态能力已经能独立被读取
- reasoning 与 attachment 类能力都有统一事实源
- 后续 capability 投影不需要靠 provider id 硬编码

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-01 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理模型输入模态能力元数据：补 supports_file_attachments、supports_image_attachments、supports_attachment_urls_only、supports_multi_attachments 等能力，并把它们从 capability seed 传播到 metadata builder 和可消费视图数据。不要改右栏 UI，不要开放附件入口。注意能力事实源必须独立于 Flutter widget。
```

---

## 7. Session WR-02：建立输入能力投影合同 V2

### 本轮目标

把输入能力从“只看 isGenerating 的硬编码开关”升级成正式 capability projection。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`

### 必须完成

1. 新建正式输入 capability context / resolver
2. 至少让 capability 能联合判断：
   - 当前平台
   - 当前模型能力
   - 当前主智能体 / 当前组能力
   - 当前运行态
   - 当前产品开关
3. 明确区分：
   - `internal capability`
   - `publicly exposed action`
4. reasoning toggle 进入 capability 投影
5. attachment capability 即使存在，也默认不公开暴露

### 本轮不要做

- 不重做会话 UI 布局
- 不改停止真实链路
- 不开放附件按钮

### 本轮重点拆耦

- `ConversationInputCapabilityContext`
- `ConversationInputCapabilityResolver`
- `public action exposure policy`

### 完成判定

- 输入区能力不再是固定 false
- 推理、停止、附件可以分别投影
- 附件能力可内部存在但公开入口仍关闭

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-02 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md。只处理输入能力投影合同 V2：建立 ConversationInputCapabilityContext 和 Resolver，让 reasoning、stop、attachment 都走联合能力判断，并明确区分 internal capability 与 publicly exposed action。不要重做会话 UI，不要开放附件按钮。注意把判断留在服务层，不要塞回 widget。
```

---

## 8. Session WR-03：建立 group-first 会话选择合同

### 本轮目标

正式把会话主入口从 `单智能体` 切到 `智能体组`。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 梳理“当前项目默认只选一个智能体组”的读写合同
2. 当前主智能体改为组解析结果
3. 会话 view data 中补齐：
   - 当前组显示
   - 当前主智能体只读摘要
   - 是否允许切换组
4. 停止把第二主选择器继续建模为单智能体
5. 保持 opening / project binding / fallback 组兜底逻辑可回归

### 本轮不要做

- 不压缩右栏布局
- 不改左栏项目面板
- 不碰 stop 链路

### 本轮重点拆耦

- `project group -> primary agent projection`
- `conversation selector contract`
- `conversation view data projection`

### 完成判定

- 当前项目协作在语义上正式以组为主
- 主智能体成为派生结果
- 后续 UI 压缩时不再需要猜语义

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-03 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理 group-first 会话选择合同：把当前项目协作选择正式收束为智能体组，并从组解析当前主智能体的只读摘要。不要顺手压缩右栏，不要改左栏。注意拆开 group resolution、view data projection 和 selector contract。
```

---

## 9. Session WR-04：项目级智能体组稳定入口

### 本轮目标

让项目级组选择不再只依赖 opening / 空态。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`

### 必须完成

1. 在项目面板中建立正式项目级智能体组入口
2. 明确项目面板入口和会话轻量入口的分工
3. 当前项目已绑定组时，项目面板能读到稳定状态
4. 避免把“组配置”继续塞进会话空态补充说明里
5. focused test 覆盖已有项目 / opening 项目两条路径

### 本轮不要做

- 不做右栏紧凑化
- 不改模型选择器布局
- 不做视觉减噪大扫除

### 本轮重点拆耦

- `project-level group panel view data`
- `group configuration entry`
- `opening-only vs project-level responsibilities`

### 完成判定

- 不管是不是空态，当前项目都有正式组入口
- opening panel 不再承担全部组配置职责

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-04 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md。只处理项目级智能体组稳定入口：让项目面板拥有正式的组配置入口，并明确它与会话轻量入口、opening 补充入口之间的职责边界。不要顺手做右栏紧凑化或视觉减噪。注意 view data、配置入口和 existing/opening 状态判断分层。
```

---

## 10. Session WR-05：右栏状态摘要投影服务

### 本轮目标

先把右栏状态区的语义收成紧凑摘要，再谈布局。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 新建紧凑状态摘要 projection service
2. 把以下状态投影成单行 / chip 优先结构：
   - 上下文
   - 工具显示
   - 运行状态
3. 保留展开详细说明的余地，但不在本轮做重 UI
4. 让 `ConversationPanelStatusGroup` 不再自己拼业务语义

### 本轮不要做

- 不改 composer 布局
- 不改左栏
- 不改停止真实链路

### 本轮重点拆耦

- `compact status projection`
- `summary chip model`
- `detail expansion contract`

### 完成判定

- 状态语义已经不依赖三个旧组件各自解释
- 后续 UI 压缩只需替换布局，不必重写业务判断

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-05 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理右栏状态摘要投影服务：把上下文、工具显示、运行状态统一投影成紧凑摘要结构，让 ConversationPanelStatusGroup 不再自己拼业务语义。不要顺手改 composer 布局或左栏。注意 summary model 和旧 widget 适配层分离。
```

---

## 11. Session WR-06：右栏 group-first composer strip 重排

### 本轮目标

在前面合同稳定后，正式把右栏收成更像协作区的 composer 结构。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`

### 必须完成

1. 右下角只保留：
   - 模型
   - 智能体组
2. 当前主智能体改为只读摘要
3. 状态摘要改用 WR-05 的紧凑投影
4. 输入区与选择区形成连续 composer，而不是两块割裂 panel
5. 允许 reasoning toggle 在合适位置出现
6. 不显示附件公开入口

### 本轮不要做

- 不改左栏项目面板
- 不扩新业务能力
- 不做 stop 真中断

### 本轮重点拆耦

- `group-first selector strip`
- `composer block layout`
- `read-only primary agent summary`

### 完成判定

- 右栏主选择入口变成模型 + 智能体组
- 主智能体不再作为平级主选择器
- composer 结构更连续、更省空间

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-06 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md。只处理右栏 group-first composer strip 重排：右下角只保留模型和智能体组，当前主智能体改成只读摘要，并把状态摘要与 composer 收成连续结构。不要开放附件入口，不要顺手改左栏。注意 selector strip、status summary、composer layout 分层。
```

---

## 12. Session WR-07：左栏项目面板去工具条化

### 本轮目标

把左栏项目面板从“小图标工具条 + 多层盒子”收成真正的项目侧栏。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 收掉 `ProjectActionGroup` 这种工具条式入口
2. 保留少量明确项目动作，但改为语义化入口
3. 项目面板更清晰地区分：
   - 项目摘要
   - 项目规则 / 配置
   - 智能体组 / 生态
4. 减少重复 section / 边框
5. 保持文件、项目、长任务三类对象结构不混

### 本轮不要做

- 不重做资源树
- 不改右栏能力判断
- 不扩新项目操作

### 本轮重点拆耦

- `project panel semantic sections`
- `project action list`
- `visual density cleanup`

### 完成判定

- 左栏不再像主导航旁边挂了个小工具箱
- 项目面板更像正式项目侧栏

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-07 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理左栏项目面板去工具条化：去掉 ProjectActionGroup 风格的小图标动作，保留少量语义明确的项目入口，并减少重复边框和 section 壳。不要顺手重做资源树和右栏。注意项目摘要、动作入口、配置区分层。
```

---

## 13. Session WR-08：会话请求运行合同与句柄

### 本轮目标

先把“当前轮生成”从裸异步流程收成正式运行句柄。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 为会话当前轮请求建立运行句柄合同
2. 至少引入：
   - `ConversationRequestHandle`
   - `ConversationRequestRuntimeService`
   - `ConversationRequestCancellationToken`
3. 让 `WorkbenchConversationController` 不再直接承担全部运行期细节
4. 为后续 stop 行为提供可取消对象
5. focused test 覆盖句柄生命周期

### 本轮不要做

- 不接 gateway 真取消
- 不改 stop 按钮 UI
- 不做附件链路

### 本轮重点拆耦

- `request runtime lifecycle`
- `controller vs runtime service boundary`
- `cancel token contract`

### 完成判定

- 当前轮请求已经有正式 handle
- 控制器不再只是一个长异步函数壳
- 后续 stop 可以接在明确边界上

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-08 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理会话请求运行合同与句柄：建立 ConversationRequestHandle、ConversationRequestRuntimeService 和 CancellationToken，让 WorkbenchConversationController 不再直接承担全部运行期细节。不要接 gateway 真取消，不要改 stop 按钮 UI。注意 runtime lifecycle、controller boundary 和 cancel token 分层。
```

---

## 14. Session WR-09：core 取消合同与结果状态扩展

### 本轮目标

把 stop / cancel 从“未来概念”变成 core 可表达的正式状态。

### 预计改动量

- 约 `900 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 为 `GenerateDraftUseCase` 引入 cooperative cancellation 合同
2. 扩展 progress / result，至少支持：
   - `cancelledByUser`
   - `stopPhase`
   - `partialContentAccepted` 或等价表达
3. 失败与取消语义分离
4. 保持第一阶段目标只做合作式取消
5. focused test 覆盖取消与失败分流

### 本轮不要做

- 不改 gateway HTTP 层
- 不开放 UI 停止按钮
- 不改附件能力

### 本轮重点拆耦

- `core cancellation contract`
- `generation result state taxonomy`
- `cooperative stop checks`

### 完成判定

- core 已能表达 cancelled
- stop 不再只能伪装成失败
- gateway 接线前的核心合同已稳定

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-09 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理 core 取消合同与结果状态扩展：为 GenerateDraftUseCase 引入 cooperative cancellation token，并让 DraftGenerationProgress / Result 能区分 cancelled、failed、partial content 等状态。不要改 gateway HTTP 层，不要开放 UI 停止按钮。注意 core contract 和 UI 表达分离。
```

---

## 15. Session WR-10：gateway 合作式中断接线

### 本轮目标

让 stop 真正能中断当前流式请求。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 让 `LlmGateway` 支持取消传播
2. 让 `OpenAiLlmGateway` 在流式读取中响应取消
3. 保持 adapter 负责 transport 细节，core 不直知 HTTP
4. 第一阶段至少实现：
   - 中断当前网络流
   - 停止后续轮继续
5. focused test 覆盖取消传播边界

### 本轮不要做

- 不改 stop UI
- 不扩工具执行强制杀掉逻辑
- 不做附件适配

### 本轮重点拆耦

- `gateway cancellation propagation`
- `stream abort boundary`
- `adapter-specific transport cleanup`

### 完成判定

- 停止可以传到 gateway
- 当前流式请求可被合作式中断
- 不需要在 UI 层假装 stop 已实现

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-10 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理 gateway 合作式中断接线：让 LlmGateway 支持取消传播，并让 OpenAiLlmGateway 在流式读取过程中响应取消。不要顺手改 stop UI，不要扩工具强制中断。注意 core contract、adapter transport 和 cleanup 边界分开。
```

---

## 16. Session WR-11：停止能力接回工作台 UI

### 本轮目标

把已经具备的取消链路投影回工作台输入区与时间线状态。

### 预计改动量

- 约 `800 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 生成态正式显示 stop action
2. stop action 调用真实取消链路
3. 取消后的时间线 / 状态文案正确显示
4. retry / partial content 行为按合同表达
5. 保持 stop 与 failed 明确区分

### 本轮不要做

- 不开放附件
- 不做新布局大改
- 不做工具执行强杀

### 本轮重点拆耦

- `stop action projection`
- `cancelled timeline/status projection`
- `runtime state -> UI mapping`

### 完成判定

- 工作台 stop 变成真实能力
- 用户可见状态与底层结果一致

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-11 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理停止能力接回工作台 UI：生成态显示 stop action，调用真实取消链路，并把 cancelled 状态正确投影到时间线和状态文案。不要开放附件，不要顺手做大布局改造。注意 action projection、runtime mapping 和 timeline projection 分离。
```

---

## 17. Session WR-12：附件 typed request 合同

### 本轮目标

在不开放公开入口的前提下，把附件从松散 options 方向拉回正式 typed contract。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 为 LLM 请求建立 typed request / attachment contract
2. 至少引入：
   - `ChatRequest`
   - `ChatInputAttachment`
   - `AttachmentMediaKind`
3. 保持现有调用方可平滑迁移
4. 不把附件继续塞进 `requestOptions`
5. 不开放任何公开 UI

### 本轮不要做

- 不接宿主 picker
- 不改 composer
- 不开放附件按钮

### 本轮重点拆耦

- `typed chat request model`
- `attachment request contract`
- `legacy request bridge`

### 完成判定

- core / adapter 都有 typed attachment 位
- 后续接附件链路不需要继续污染 `JsonMap options`

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-12 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理附件 typed request 合同：引入 ChatRequest、ChatInputAttachment、AttachmentMediaKind 等正式模型，并给现有 request 调用提供平滑桥接。不要开放任何公开 UI，不要接宿主 picker。注意 typed model 和 legacy bridge 分离。
```

---

## 18. Session WR-13：附件宿主与暂存内部链路

### 本轮目标

继续补附件内部链路，但只做到“内部可测试、默认不开放”。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 新建独立附件宿主边界：
   - `ConversationAttachmentPickerService`
   - 或同职责服务
2. 新建附件暂存状态模型：
   - `ConversationAttachmentDraft`
   - `ConversationAttachmentViewData`
3. 保持和“项目导入文件”职责完全分离
4. 补 focused test
5. 保持所有入口默认关闭

### 本轮不要做

- 不开放按钮
- 不把附件塞回项目导入流程
- 不改会话 UI

### 本轮重点拆耦

- `host attachment boundary`
- `attachment staging state`
- `no-public-entry policy`

### 完成判定

- 附件内部链路已有独立宿主和暂存状态
- 但公开入口仍保持关闭

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-13 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理附件宿主与暂存内部链路：建立独立的 ConversationAttachmentPickerService 和附件暂存状态模型，并确保与项目导入文件职责完全分离。不要开放任何按钮，不要改会话 UI。注意 host boundary、staging state 和 no-public-entry policy 分层。
```

---

## 19. Session WR-14：附件 adapter 能力桥接

### 本轮目标

把附件 typed contract 至少桥接到 adapter 能力层，但继续保持非公开能力。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`

### 必须完成

1. 让 adapter 能读懂 typed attachment contract
2. 明确当前 provider 下：
   - 原生支持
   - 不支持
   - 仅 URL 支持
   - 需降级策略
3. 当前阶段至少允许：
   - 内部 capability 探测
   - 失败时稳定报错
4. 不开放用户入口

### 本轮不要做

- 不做最终附件发送 UI
- 不增加公开命令
- 不和项目导入混用

### 本轮重点拆耦

- `adapter attachment capability bridge`
- `provider-specific attachment policy`
- `internal-only readiness`

### 完成判定

- adapter 层已具备附件能力桥接基础
- 但产品层仍不公开该功能

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-14 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md。只处理附件 adapter 能力桥接：让 adapter 能读懂 typed attachment contract，并区分原生支持、URL-only、完全不支持等 provider 情况。不要开放公开入口，不要增加用户命令。注意 provider-specific policy 和 internal-only readiness 分层。
```

---

## 20. Session WR-15：长任务启动动作收口

### 本轮目标

把长任务相关项目中的“唯一清晰启动动作”收稳。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/workbench-remaining-chain-analysis-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 长任务相关项目里有唯一明确的启动动作
2. 删除或弱化过度刻板的前置按钮树
3. 保持后续缺口由 AI 引导完成
4. 非长任务相关项目不误出现该入口
5. focused probe 覆盖长任务项目与普通项目

### 本轮不要做

- 不改 stop 链路
- 不重做全部 opening 文案
- 不引入新页面

### 本轮重点拆耦

- `long-task start action policy`
- `project-type gated exposure`
- `AI-guided follow-up flow`

### 完成判定

- 长任务相关项目里有稳定单一启动入口
- 普通项目不会被长任务入口污染

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-15 执行。先阅读 agent.md、docs/workbench-remaining-chain-analysis-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理长任务启动动作收口：让长任务相关项目存在唯一明确的启动动作，后续缺口尽量交给 AI 引导完成，并确保普通项目不误显示该入口。不要引入新页面。注意 project-type exposure policy 和 AI-guided follow-up flow 分层。
```

---

## 21. Session WR-16：全局边框 / 分栏减噪回归

### 本轮目标

做一轮不改业务边界的视觉收口。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`

### 必须完成

1. 检查左中右三栏里的重复边框、嵌套 panel、section 壳
2. 去掉没有明确层级收益的视觉分栏
3. 统一表面密度和节奏
4. 不改业务边界
5. 回填仍保留较重结构的原因

### 本轮不要做

- 不开新主线
- 不再大改合同
- 不继续扩附件功能

### 本轮重点拆耦

- `surface density cleanup`
- `section nesting audit`
- `visual regression note`

### 完成判定

- 工作台整体不再像调试框拼起来
- 内容与协作重新成为视觉重心

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-16 执行。先阅读 agent.md、docs/ui-simplification-full-audit-2026-05-28.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md。只做全局边框和分栏减噪回归：清掉无明确层级收益的重复 panel、section 壳和视觉分栏，统一左中右三栏的表面密度，但不要改变业务边界。注意视觉减噪与业务逻辑完全分离。
```

---

## 22. Session WR-17：总联调、探针、截图与打包前回归

### 本轮目标

确认这条线从合同、实现到体验全部闭环。

### 预计改动量

- 约 `500 ~ 1300` 行

### 必读文档

- `agent.md`
- 本文件
- 前面各 session 的完成记录

### 必须完成

1. 回归至少这些路径：
   - 打开已有项目
   - 当前项目切换智能体组
   - 观察主智能体派生显示
   - reasoning toggle 按模型动态出现
   - 生成中 stop 可真实取消
   - 取消后状态正确显示
   - 长任务项目存在唯一明确启动动作
2. 确认附件公开入口仍未显示
3. 补 focused widget / integration / probe
4. 做一次截图核对
5. 回填文档与打包前结论

### 本轮不要做

- 不开新功能主线
- 不借回归之名重做架构

### 本轮重点拆耦

- `regression probe`
- `packaging readiness notes`
- `no-public-attachment verification`

### 完成判定

- 当前这条线已经可继续稳定打包测试
- 附件保持内部链路就绪但对用户关闭

### 建议提示词

```text
按 docs/workbench-remaining-session-order-2026-05-28.md 的 Session WR-17 执行。先阅读 agent.md、docs/workbench-remaining-session-order-2026-05-28.md 以及前面各 session 完成记录。只做总联调、探针、截图与打包前回归：验证组优先协作、动态 reasoning toggle、真实 stop 取消、长任务单一启动动作，并确认附件公开入口仍未显示。不要开新主线。
```

---

## 23. 哪些旧 session 已被吸收

以下旧线已被本文件吸收：

- `GF-01` -> `WR-03`
- `GF-02` -> `WR-02` + `WR-01`
- `GF-03` -> `WR-05` + `WR-06`
- `GF-04` -> `WR-07`
- `GF-05` -> `WR-16`
- `GF-06` -> `WR-17`

旧文档仍可保留作为历史上下文，但后续建议统一按本文件推进。

---

## 24. 最后一句话定义

这条线的最终目标不是“把几个按钮补出来”，而是：

**把 NovelAgentFlutter 的工作台收束成一个真正组优先、能力驱动、状态可信、未来还能继续演化的正式协作前端。**
