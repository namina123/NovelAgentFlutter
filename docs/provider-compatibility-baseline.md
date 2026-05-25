# 提供商兼容基线

最后更新：2026-05-25

## 目标

本项目必须兼容至少四类接口形态：

1. `OpenAI Chat Completions`
2. `OpenAI Responses API`
3. `Anthropic Messages API`
4. `Gemini` 原生 API 与 `Gemini OpenAI compatibility`

这里的关键结论是：

- `调度层` 大体可以共用
- `协议层 / 流式层 / 工具消息层` 不能共用

也就是说，真正应该共享的是“智能体如何工作”，而不是“每家接口长什么样”。

## 哪些可以共用

这些应该保持在 core 中，尽量与提供商无关：

- 会话策略
- 上下文预算与裁剪
- 长任务调度
- 阶段状态机
- 工具注册与暴露策略
- 工具执行结果的领域归一化
- 重试策略
- 错误不计入上下文的规则
- 选项等待态
- 项目级摘要 / 长期记忆策略

## 哪些必须分流

这些必须在 adapters / gateway 层按提供商分流：

- 请求体结构
- 响应体结构
- 流式事件格式
- 工具调用事件格式
- 工具结果回传格式
- 思考内容 / reasoning 内容的承载位置
- 系统提示词 / 开发者提示词的映射方式
- 是否支持 Responses API
- 是否支持 built-in tools
- 是否支持强制 tool choice

## 统一抽象原则

不要在 core 里直接问：

- “是不是 OpenAI”
- “是不是 Anthropic”
- “是不是 Gemini”

而应该问能力：

- 是否支持 `chat_completions`
- 是否支持 `responses_api`
- 是否支持 `tool_calls`
- 是否支持 `streaming_text_delta`
- 是否支持 `streaming_tool_arguments_delta`
- 是否支持 `reasoning_blocks`
- 是否支持 `forced_tool_choice`
- 是否支持 `built_in_web_search`
- 是否支持 `structured_output_strict`

也就是说，协议判断应以 `capability matrix` 为中心，而不是以厂商名硬分支。

## 当前基线

## 1. OpenAI Chat Completions

特点：

- 工具调用与 `tool_calls` 对齐
- 工具回传通过后续消息继续
- 支持 `tool_choice`
- 流式返回是 chat delta 语义

适合：

- 现有 OpenAI 兼容供应商的大多数接入
- 我们当前的主兼容层

注意：

- `function_call` 是旧式字段，应以 `tool_choice / tool_calls` 为主
- 流式工具参数拼接必须按 delta 聚合，不能把单片段当完整 JSON

## 2. OpenAI Responses API

特点：

- 是 OpenAI 当前推荐的新接口
- 响应是语义化事件流，不是 Chat delta
- 单次请求中可以出现多类 output item / tool 事件
- 工具、结构化输出、流式事件模型都与 Chat Completions 不同

结论：

- 不能把现有 Chat Completions 流式解析器硬套到 Responses API
- 必须单独做 `ResponsesGatewayAdapter`
- UI 层只能消费归一化事件，不能直接消费 Responses 原始事件名

当前项目约束：

- 在真正做完单独适配前，`Responses API` 只能作为受限能力，不得伪装成已经等价支持

## 3. Anthropic Messages API

特点：

- 工具不是独立 `tool` 角色消息，而是 `assistant` / `user` 内容块中的 `tool_use` 与 `tool_result`
- 工具结果必须紧跟工具调用返回，不能在中间插别的消息
- 流式事件是 message / content block 语义，不是 OpenAI delta 语义

结论：

- Anthropic 不能直接套 OpenAI 兼容的消息拼装逻辑
- 必须有单独的 `AnthropicMessageAdapter`
- 我们的统一工具回合状态机要允许“工具结果回到 user content blocks”这种形态

思考相关限制：

- 当使用 extended thinking + tool use 时，工具选择不能依赖强制选某个具体工具的策略
- thinking block 需要按原样带回后续请求，不能在中途私自改写

## 4. Gemini 原生 API

特点：

- 原生工具、函数调用、思考参数、结构化输出都有自己的原生语义
- Gemini 原生 API 的工具流与 OpenAI / Anthropic 都不一样

结论：

- 若后续要完整支持 Gemini 原生能力，应做独立 native adapter
- 不要因为 Gemini 同时有 OpenAI compatibility，就假设两者能力完全一致

## 5. Gemini OpenAI compatibility

特点：

- 官方文档明确提供 OpenAI 兼容入口
- 官方页面重点展示的是 `chat/completions`
- 官方文档明确写到 function calling、streaming、thinking 参数映射

但当前约束是：

- 它不应被视为“OpenAI 全接口全功能镜像”
- 至少在我们当前基线里，不能默认它已经等价支持 `Responses API`
- Gemini 特有能力不能假定能从 OpenAI compatibility 入口全部拿到

项目级结论：

- `Gemini OpenAI compatibility` 先归入 `OpenAI Chat-compatible` 这一兼容层
- 若需 Gemini 原生能力，另走 Gemini native adapter

## 工具设计约束

为了兼容不同接口层，工具系统必须遵守：

1. 工具 schema 在 core 中定义为提供商无关的中间表达
2. 各 gateway 再把 schema 翻译成各自协议
3. 工具调用结果在进入 core 前必须先归一化
4. 工具错误必须带结构化原因，不能只丢原始 provider 文本
5. 流式工具参数必须支持“分片未完成态”
6. 不得假设每家都支持：
   - 强制单工具调用
   - 多工具并发
   - 原生 built-in tools
   - 思考内容可见
   - 非流式与流式完全同形

## 调度设计约束

调度层可以共用，但必须满足：

1. 调度只依赖归一化事件
2. 调度不直接读取原始 SSE 事件名
3. 调度不直接判断厂商
4. 调度通过 capability 决定：
   - 是否允许强制工具
   - 是否启用 reasoning 展示
   - 是否可以走 Responses
   - 是否可以期待 tool argument delta

## 当前项目硬约束

从现在开始：

1. `OpenAI Chat compatible` 是默认公共执行面
2. `Responses API` 必须单独适配，不能继续伪装成 Chat
3. `Anthropic` 必须单独适配消息块与工具结果回传
4. `Gemini OpenAI compatibility` 只视为“部分 OpenAI 兼容”，不能超范围假定
5. `Gemini native` 若启用，必须独立 adapter
6. 工具与调度的共享点应在 core，协议差异应在 adapters
