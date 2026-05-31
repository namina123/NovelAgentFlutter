# 会话系统审计（2026-05-27）

## 结论

当前会话系统的主要卡顿，不是单点 bug，而是三类问题叠加：

1. **流式更新频率过高**  
   每个 token / 分片都可能触发一轮完整的 UI 投影与 `notifyListeners()`。

2. **状态广播边界过大**  
   右侧会话流式变化，会穿透到整个 `AppShellController -> AppShell -> WorkbenchPage` 链路。

3. **流式阶段做了太多“最终态才需要”的工作**  
   比如工具结果 JSON 细节、全文可选中文本、历史投影、引导投影等。

这意味着：即便真正变化的只是右栏最后一条流式消息，系统也会让更大范围的树跟着重建，而且在重建时还会重复做不少重活。

---

## 这轮已落地的修复

### 1. 流式进度合帧

新增：

- `apps/novel_agent_app/lib/features/workbench/application/services/conversation_progress_coalescer_service.dart`

作用：

- 把高频 `onProgress` 合并为约 66ms 一次的 UI 发射
- 完成态前强制 `flushNow()`，避免最后一段内容丢失

收益：

- 显著减少 `notifyListeners()`、会话状态替换、右栏重建次数

### 2. 流式工具投影改为轻量模式

调整：

- `ConversationToolEntryProjectionService`
- `ConversationSessionStateService`
- `ConversationStreamingStateService`

作用：

- 流式阶段仍显示工具轨迹
- 但不再为每次流式刷新都构造大段 JSON `detailBody`
- 完整工具细节只保留在最终态投影中

收益：

- 避免每个流式分片重复 `JsonEncoder.withIndent(...)`

### 3. 流式阶段只补丁会话字段

调整：

- `WorkbenchConversationController.applyStreamingConversationState(...)`

作用：

- 流式更新时不再每次都完整重算：
  - workflow guide
  - session history
  - 其他工作台字段

收益：

- 降低右栏流式更新时的投影成本

### 4. 流式正文改用快速文本渲染

调整：

- `conversation_message_entry_tile.dart`

作用：

- `assistant_streaming` 使用 `Text`
- 最终态仍保留 `SelectableText`

收益：

- 降低流式阶段文本选择层的布局与交互成本

---

## 当前仍然存在的问题

### P0：根壳层广播过粗

位置：

- `apps/novel_agent_app/lib/shared/widgets/app_shell.dart`
- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`

现状：

- `AppShell` 通过 `AnimatedBuilder(animation: controller, ...)` 监听整个 `AppShellController`
- 任何 `workbench` 变化都会让根壳层重建

风险：

- 会话流式更新会连带重建 rail / scaffold / router page 包装层
- 页面越多、壳层越重，卡顿越明显

建议：

- 把 `destination`、`theme/shell chrome`、`workbench page data` 拆成不同 listenable
- 根壳层只监听真正影响壳层结构的状态
- `WorkbenchPage` 改为监听自己的 page-level notifier

### P0：WorkbenchViewData 过于一体化

位置：

- `apps/novel_agent_app/lib/features/workbench/presentation/models/workbench_view_data.dart`

现状：

- 资源树、文档区、会话区、overlay 状态都塞在一个 view data 里

风险：

- 会话流式变化会让资源树、文档区也拿到新的父级 `viewData`
- 虽然不一定每次都 repaint，但 build 压力已经被放大

建议：

- 拆成：
  - `WorkbenchConversationViewData`
  - `WorkbenchDocumentViewData`
  - `WorkbenchResourceViewData`
  - `WorkbenchOverlayViewData`

### P1：流式状态和最终状态仍然共用大量投影路径

位置：

- `WorkbenchConversationController`
- `ConversationSessionStateService`

现状：

- 这轮已经补了一层“流式轻量 patch”
- 但底层 session 替换和 workbench mutate 仍然共享同一大链路

风险：

- 后续功能继续增多时，流式阶段容易再次偷跑进重逻辑

建议：

- 正式区分：
  - `settled conversation projection`
  - `streaming conversation projection`

### P1：时间线条目模型偏向“展示字符串”，缺少更稳定的渲染合同

位置：

- `ConversationEntryViewData`
- `ConversationToolEntryProjectionService`

现状：

- 工具细节、思考细节大量以最终字符串形式挂在 view data 上

风险：

- 早序列化、早 pretty print
- 流式和最终态难以共享缓存

建议：

- 引入更正式的 detail payload 合同，例如：
  - summary
  - lightweight preview
  - lazy full detail

### P1：会话 timeline 仍是“列表重投影”思路

位置：

- `ConversationTimeline`
- `ConversationStreamingStateService`

现状：

- 每次流式 patch 仍会重新组一份 `entries`

风险：

- 当历史会话很长、工具记录变多时，列表重建成本会继续放大

建议：

- 给 streaming appendix 建独立模型：
  - stable history entries
  - current round tool strip
  - current streaming assistant entry
  - footer blocks

### P2：会话摘要和历史投影仍可能在错误场景下被重复计算

位置：

- `applyConversationState`
- `_conversationSummary(...)`
- `historyEntries(...)`

现状：

- 这轮已绕开最热的 streaming 路径
- 但完整投影链本身仍偏重

建议：

- 增加投影缓存 / dirty flag

---

## 推荐的正式设计方向

### 一、分层

把会话系统拆成四层：

1. **Session Core**
   - 原始会话记录
   - 工具执行记录
   - 子智能体运行记录

2. **Streaming Projection Layer**
   - 高频、轻量、可丢帧合并
   - 只服务当前显示

3. **Settled Projection Layer**
   - 最终态、可展开细节、历史回放

4. **Presentation Controllers**
   - Conversation pane notifier
   - Document pane notifier
   - Resource pane notifier

### 二、状态边界

禁止以下情况继续存在：

- 会话流式 token 触发整个 shell rebuild
- 会话流式 token 触发资源树 / 文档区跟着重投影
- 会话流式 token 触发最终态细节字符串生成

### 三、设计模式建议

推荐：

- **Presenter / Projection Service**
  - 负责从 core state 生成 pane-specific view data

- **Streaming Patch Model**
  - 负责高频增量更新

- **Page-scope Listenable**
  - 每个大页面单独监听自己的状态

不推荐：

- 继续把所有页面状态堆进一个 `ChangeNotifier`
- 继续把所有 workbench 字段塞进一个大 `WorkbenchViewData`

---

## 下一步实现顺序

### Session A

目标：

- 把 `AppShell` 从“监听整个 controller”改成“只监听 destination / shell chrome”
- 给 `WorkbenchPage` 独立的 page-level listenable

### Session B

目标：

- 拆分 `WorkbenchViewData`
- 让 conversation/document/resource 三栏各自只接自己的 slice

### Session C

目标：

- 给 conversation timeline 引入 `streaming appendix model`
- 把稳定历史和流式附加区彻底分开

### Session D

目标：

- 给 tool detail / reasoning detail 引入 lazy payload
- 最终收束 detail 展示合同

---

## 本轮验证

已通过：

- `flutter test test/conversation_progress_coalescer_service_test.dart test/conversation_streaming_state_service_test.dart`
- `dart analyze lib test`

建议下轮在完成 `Session A` 后，再做一次真实 provider 流式探针，对比流式阶段 CPU 与主线程卡顿体感。
