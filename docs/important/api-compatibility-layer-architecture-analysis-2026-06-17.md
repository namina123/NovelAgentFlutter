# API 兼容层架构分析（2026-06-17）

## 1. 本轮分析目标

本轮不做功能堆砌，目标是全方位审视当前项目的 API 兼容层，回答以下问题：

1. 现有 OpenAI 兼容、Anthropic 兼容链路是否真正闭环。
2. Gemini 目前处于什么状态，缺口在哪里。
3. 协议类型、请求类型、模型能力、UI 显示、运行网关之间是否存在错误耦合。
4. 如果后续新增更多兼容类型，当前架构是否会导致高成本修改。
5. 哪些能力应该按协议显示，哪些应该按模型显示，哪些应该按 provider offering 显示。

本分析覆盖 `core`、`adapters`、`app` 三层，不局限于单个文件。

## 2. 当前兼容层的实际分层

### 2.1 已存在的层次

当前链路大体分为五层：

1. 协议与目录事实层
   - `provider_protocol_service.dart`
   - `provider_interface_template_seed.dart`
   - `provider_model_catalog_seed.dart`
   - `provider_model_capabilities_seed.dart`
   - `builtin_writing_model_catalog_seed.dart`

2. 运行态归一化与能力汇总层
   - `provider_profile_normalizer_service.dart`
   - `provider_runtime_profile_service.dart`
   - `provider_model_metadata_service.dart`
   - `provider_request_options_service.dart`

3. 网关与请求构造层
   - `openai_llm_gateway.dart`
   - `anthropic_llm_gateway.dart`
   - `openai_chat_request_payload_builder.dart`

4. 组装层
   - `adapter_bundle.dart`

5. UI 暴露层
   - `provider_detail_pane.dart`
   - `model_settings_view_data_service.dart`
   - `model_settings_advanced_panel.dart`

### 2.2 已经做对的地方

当前方案里有几处基础方向是对的，应该保留：

1. 协议枚举已经集中在 `ProviderProtocolService`，没有散落在 UI 和 adapter 各处。
2. provider / model / capability / writing fact 已经拆成多份 seed，而不是一个总表。
3. runtime profile 负责把 provider + model + catalog + capability 合成运行态，这比直接让 UI 拼请求要健康得多。
4. metadata 层已经开始承担“前端该显示什么”的汇总职责，这是正确方向。
5. adapter bundle 统一决定“某种 protocol 走哪个 gateway”，入口位置是对的。

## 3. 当前链路的真实现状

### 3.1 OpenAI 兼容链路

OpenAI 兼容链路目前是闭环的，但闭环里仍有结构性问题。

现有闭环：

1. provider 选择为 `openai_compatible`
2. `AdapterBundle.createGateway()` 会落到 `OpenAiLlmGateway`
3. `OpenAiLlmGateway` 固定向 `.../chat/completions` 发请求
4. payload 由 `OpenAiChatRequestPayloadBuilder` 构建
5. streaming / tool call / SSE 聚合也已经在这条链里

问题：

1. `api_mode` 目前没有真正驱动 OpenAI 网关切换 endpoint
   - `ProviderRequestOptionsService` 会产出 `api_mode`
   - UI 高级设置也允许选择 `chat` / `responses`
   - 但 `OpenAiLlmGateway.requestChat()` 仍然固定请求 `/chat/completions`
   - 这意味着“Responses API”目前只是 UI 选项，不是实际链路能力

2. `OpenAiChatRequestPayloadBuilder` 本质是“Chat Completions payload builder”
   - 文件名已经说明这一点
   - 但整个系统把它挂在 “openai compatible protocol” 下
   - 如果后续接 Gemini OpenAI-compatible、OpenAI Responses、某些聚合商的 partial-compatible path，会产生语义错位

3. OpenAI 兼容并不等于 Chat Completions 兼容
   - 当前架构里这两个概念还没有被正式拆开

### 3.2 Anthropic 兼容链路

Anthropic 兼容链路也基本闭环：

1. provider 选择为 `anthropic_compatible`
2. `AdapterBundle.createGateway()` 会落到 `AnthropicLlmGateway`
3. 固定请求 `.../messages`
4. 会自动设置 `anthropic-version`
5. 会做 Anthropic message block / tool_use / tool_result 的转换

问题：

1. Anthropic 的“消息协议转换”直接耦合在 `AnthropicLlmGateway`
   - `_requestMessages`
   - `_assistantToolUseMessage`
   - `_toolResultMessage`
   - `_contentBlocksFromMessage`
   - 这些是纯协议映射逻辑，理论上应当抽成独立 payload builder / protocol mapper

2. Anthropic 的重试与回退策略和协议转换逻辑混在同一个大网关文件
   - `retryWithoutSystem`
   - `retryWithRequiredToolChoice`
   - `retryAsNonStreaming`
   - 这让后续新增 Gemini / Responses / mixed protocol 时，很难复用“策略”，只能复制网关

3. `tool_choice`、`thinking`、`reasoning_effort` 的透传目前仍偏保守，但没有形成正式的“Anthropic 参数白名单合同”

### 3.3 Gemini 当前状态

Gemini 当前不是闭环，只存在“模型事实层”，不存在“协议链路闭环”。

已存在：

1. `builtin_writing_model_catalog_seed.dart` 有 `google:gemini-3.5`、`google:gemini-2.5-pro`
2. metadata / request options 层里已经能看到 `thinkingLevel`、`thinkingBudget` 这样的字段概念
3. 部分测试里已经以 `provider_id = google` 形式验证 metadata / request options 的投影

不存在：

1. `ProviderProtocolService` 没有 Gemini 协议枚举
2. `provider_interface_template_seed.dart` 没有 Gemini provider template
3. `provider_model_catalog_seed.dart` 没有 `google` provider 目录条目
4. `AdapterBundle.createGateway()` 没有 Gemini gateway 分支
5. adapters 没有 `gemini_llm_gateway.dart`
6. 当前也没有针对 Gemini 的 payload builder

结论：

当前 Gemini 只是“模型目录事实”，不是“可运行协议兼容类型”。

如果现在直接把 Gemini 暴露为可选协议，会产生严重错配：

1. UI 允许选
2. metadata 允许看见 Gemini 模型能力
3. 运行时却会回退到 OpenAI gateway
4. 最终请求类型错误

## 4. 当前最核心的结构问题

### 4.1 协议类型与请求类型没有正式分层

这是当前 API 兼容层最关键的问题。

系统里至少存在三种不同概念，但目前只正式建模了其中一种半：

1. 协议类型
   - OpenAI-compatible
   - Anthropic-compatible
   - 后续应有 Gemini-native / Gemini-openai-compatible 等

2. 请求类型 / endpoint family
   - `chat/completions`
   - `responses`
   - `messages`
   - `generateContent`
   - `streamGenerateContent`
   - embeddings 等

3. 模型能力
   - 是否支持 tools
   - 是否支持 tool_choice
   - 是否支持 stream
   - 是否支持图片附件
   - 是否支持思考开关
   - 是否支持某种 effort 字段

当前问题是：

1. 协议和请求类型部分耦合在 gateway 文件名与内部路径里
2. 请求类型又被 UI 中的 `api_mode` 零散暴露
3. 但 `api_mode` 没有真正形成 runtime dispatch contract

这会导致：

1. 选择兼容协议不代表请求类型正确
2. 选择请求类型不代表网关真正支持
3. UI 会显示可以选，但链路不一定能走

### 4.2 provider template 既承担“识别”又隐含“路由”

`provider_interface_template_seed.dart` 当前同时承担：

1. provider / base URL 识别
2. protocol 类型建议
3. route family 说明

问题在于 `route_family` 只是文档式字段，不是强约束合同。

例如：

1. OpenAI 模板写了 `responses_and_chat`
2. DashScope 写了 `chat_completions`
3. Anthropic 写了 `messages`

但这些 route family 目前没有成为实际 runtime dispatch 的第一公民。

结果是：

1. 模板知道自己更适合哪个 family
2. UI 可能也能显示这个信息
3. 真正发请求时仍靠 gateway 内部硬编码 path

### 4.3 UI 的“可选项展示”与 runtime 真正支持未彻底对齐

当前 UI 已经能根据 metadata 隐藏一些参数，这是对的；但还不彻底。

主要问题：

1. `API 模式` 在高级设置中总是出现 `chat` / `responses`
   - 这不应是全局固定选项
   - 应按 protocol + gateway family + runtime support 动态过滤

2. 协议可选项目前只有 OpenAI / Anthropic
   - 如果后续加入 Gemini，需要保证 UI 只在真正闭环后显示

3. provider detail pane 里选择厂商后，协议和 base URL 会跟随切换
   - 但没有进一步约束“该厂商在该协议下支持哪些请求类型”

4. model suggestions 主要按 provider offering 工作
   - 但没有再乘一次“当前协议/endpoint family compatibility”

这意味着未来会出现典型问题：

1. 同一个 provider 有多个 base URL
2. 不同 base URL 对应不同兼容协议
3. 不同协议下支持的工具、流式、思考字段也不同
4. 但 UI 只知道 provider，不知道 protocol-route combination 的细能力差异

### 4.4 Gemini 的存在暴露出“模型事实层先行、协议运行层滞后”的风险

当前把 Gemini 写进 writing model catalog 是合理的，因为它是模型事实。

但如果没有对应：

1. provider template
2. provider catalog entry
3. gateway
4. payload mapper
5. runtime dispatch
6. UI filtering

那么它就不应被当作“可运行 provider 兼容类型”。

这说明系统需要一个更明确的分层边界：

1. 模型事实层可以早于运行兼容层存在
2. 但 UI 与 runtime 只能暴露“运行闭环已完成”的兼容类型

## 5. 现有实现中的错误耦合点

### 5.1 `AdapterBundle.createGateway()` 是硬编码分叉点

当前代码：

1. Anthropic protocol -> `AnthropicLlmGateway`
2. 其他全部 -> `OpenAiLlmGateway`

这意味着：

1. 当前系统本质上只有两条真实协议执行链
2. 新增 Gemini 时必须改 `AdapterBundle`
3. 新增 Responses-native / Gemini-native / Azure-specialized 等时仍得继续加 if/else

这会让 `AdapterBundle` 变成未来的耦合核心。

应拆成：

1. `GatewayProtocolRegistry`
2. `GatewayFactoryResolver`
3. `ProviderRequestRouteResolver`

让 bundle 只装配，不决策。

### 5.2 `OpenAiLlmGateway` 内部把“协议”、“端点”、“流式解析”、“工具调用聚合”揉在一起

当前 `OpenAiLlmGateway` 同时承担：

1. OpenAI-compatible endpoint path 选择
2. payload building
3. SSE 聚合
4. tool call delta merge
5. JSON response parsing
6. transport retry policy

其中至少 1、2、4、5 应该能拆成协议部件。

否则一旦新增：

1. OpenAI Responses API
2. Google Gemini OpenAI-compatible variant
3. 某些聚合商的非标准 OpenAI stream shape

就会被迫继续往这个 gateway 堆分支。

### 5.3 `AnthropicLlmGateway` 也有相同问题，而且更重

它同时承载：

1. Messages payload conversion
2. tool use / tool result block mapping
3. SSE event type 聚合
4. 失败回退策略
5. XML tool tag fallback strategy

这意味着：

1. 协议转换和行为策略没有分离
2. 新兼容类型如果也需要 retry policy，只能复制代码

### 5.4 `api_mode` 已经泄漏到 UI，但没有成为协议合同

这是一个典型的“半接入字段”问题。

表现：

1. `ModelSettingsAdvancedPanel` 有 API 模式下拉
2. `ModelExecutionProfileService` 和设置存储里保留了 `api_mode`
3. request options 里也带了 `api_mode`
4. 但 gateway 并不依据 `api_mode` 切 endpoint

这是危险的，因为：

1. 用户会以为自己真的在切换请求类型
2. 实际只是保存了一个没生效的字段

结论：

`api_mode` 要么正式升级为 runtime route contract，要么暂时从 UI 隐藏，直到闭环完成。

## 6. 关于“应该隐藏什么”的判断规则

### 6.1 不应按单一 provider 决定显示

例如同一厂商可能存在：

1. OpenAI-compatible URL
2. Anthropic-compatible URL
3. 官方原生 URL
4. 编码专用 URL

因此显示逻辑不能只问：

1. 这是哪家厂商？

而必须问：

1. 当前 protocol 是什么？
2. 当前 route family 是什么？
3. 当前 runtime capability 是什么？
4. 当前 model offering 是否覆写了能力？

### 6.2 建议的显示优先级

应按以下顺序决定 UI 是否显示某项：

1. 协议层是否支持
2. 当前 route family 是否支持
3. 当前 provider capability rule 是否支持
4. 当前 model offering / canonical model 是否覆写为不支持
5. 若仍不确定，则隐藏而不是显示

### 6.3 明确应隐藏的典型项

1. `API 模式`
   - 若当前协议没有多个已实现 route family，则隐藏

2. `tool_choice`
   - 若 runtime metadata 显示不支持，则不能在目标位置暴露

3. `top_k`
   - 必须按 metadata 决定，不能因为某些 provider 支持就全局暴露

4. `thinking_effort`
   - 只有当 reasoning profile 明确支持 effort 时才显示

5. `stream`
   - 若当前协议链路未完整实现 streaming 解析，不应允许用户切换为流式

## 7. Gemini 接入的正确演化方式

Gemini 不应直接被当作“再加一个协议枚举 + 再加一个 gateway 文件”这么简单。

应该按以下顺序演化：

1. 新增“协议类型”还是“请求族类型”先判断清楚
   - Gemini-native 不是 OpenAI-compatible
   - Gemini OpenAI-compatible 也不等于 Gemini-native

2. 先建立协议合同层
   - 新的 protocol kind
   - 新的 route family
   - 新的 payload mapper contract
   - 新的 response parser contract

3. 再新增 provider template 与 provider catalog

4. 再实现 gateway factory resolver 的新分支

5. 最后才暴露 UI

换句话说，Gemini 应该先补协议闭环，再补界面暴露，而不是反过来。

## 8. 建议的目标架构

### 8.1 从“两个大网关”改为“协议组件装配”

建议拆成以下结构：

1. `ProtocolKind`
   - `openai_compatible`
   - `anthropic_compatible`
   - `gemini_native`
   - 后续扩展

2. `RequestRouteFamily`
   - `chat_completions`
   - `responses`
   - `messages`
   - `generate_content`
   - `embeddings`

3. `GatewayProtocolAdapter`
   - 负责某种协议的 payload / response / stream contract

4. `GatewayRouteResolver`
   - 负责从 runtime profile + api_mode + provider template 决定 endpoint path

5. `GatewayFactoryResolver`
   - 负责选用哪个 protocol adapter

6. `CapabilityExposureService`
   - 负责决定 UI 该显示什么

### 8.2 UI 应依赖“暴露能力视图”，而不是直接读散落字段

当前 UI 已经在使用 metadata，这是好事，但还不够。

建议后续进一步形成：

1. `protocol_mode_options`
2. `api_mode_options`
3. `visible_advanced_fields`
4. `tool_capability_view`
5. `thinking_capability_view`

让 UI 不再自己猜：

1. responses 能不能显示
2. tool_choice 能不能显示
3. streaming 能不能切换

### 8.3 route family 必须从说明字段升级为正式合同字段

`provider_interface_template_seed.dart` 里的 `route_family` 目前偏说明性。

后续必须让它至少参与：

1. gateway route resolution
2. api_mode option generation
3. UI field filtering
4. provider connection validation

## 9. 当前阶段的结论

### 9.1 现状判断

当前系统不是“API 兼容层做坏了”，而是“已经有了正确雏形，但协议合同还没收口”。

具体来说：

1. OpenAI-compatible 与 Anthropic-compatible 已有可运行主链
2. provider / model / capability / metadata 的拆分方向是对的
3. 但协议类型、请求类型、模型能力三者尚未彻底分离

### 9.2 当前最需要修的不是加 Gemini，而是先收协议合同

如果现在直接加 Gemini，会把以下问题带着放大：

1. `api_mode` 半接入
2. gateway 路由硬编码
3. UI 选项暴露不严格
4. route family 只是说明，不是合同

### 9.3 最关键的用户侧风险

当前最大风险不是“目录里模型名字不准”，而是：

1. 用户能选到某个协议/模式
2. 但运行时请求 path 不对
3. 或者参数显示了却不该发
4. 或者 provider 的某个 URL 其实只支持另一种兼容链路

这类问题会直接导致“配置看起来正确，但真实请求失败”。

## 10. 下一阶段建议任务顺序

建议按以下顺序推进，而不是先上 Gemini：

1. 把 `api_mode` 升级为正式 route contract
2. 从 gateway 中拆出 protocol payload mapper / response parser / route resolver
3. 建立“协议支持 -> route family -> UI 暴露”的统一 capability exposure 层
4. 让 provider connection validation 真正校验 protocol + base URL + route family 的一致性
5. 完成后再接 Gemini-native
6. 最后再把 UI 中 Gemini 暴露出来

## 11. 直接结论

一句话总结当前 API 兼容层：

当前项目已经有“兼容层”的骨架，但还没有真正形成“协议合同系统”。

OpenAI 和 Anthropic 现在属于“能跑但仍有硬编码耦合”；Gemini 属于“模型事实已存在，但运行协议链路尚未接入”。下一步最正确的方向不是继续堆 provider，而是把协议类型、请求类型、模型能力、UI 暴露彻底拆开并建模，否则后续每加一种兼容类型，都会再次改到 gateway、bundle、UI、catalog 多处，成本会持续上升。

## 12. 官方协议面对照

这一节不是为了抄官方，而是为了回答一个更实际的问题：

我们当前的“兼容类型”命名，到底是在对齐哪一层事实。

### 12.1 OpenAI 官方并不等于单一接口

从官方接口面看，至少有两类与当前项目强相关的文本生成主路径：

1. Chat Completions
   - 典型路径是 `/chat/completions`
   - 输入核心是 `messages`
   - 流式返回是 delta 形态
   - 很多第三方“OpenAI 兼容”本质上兼容的是这一族

2. Responses
   - 典型路径是 `/responses`
   - 输入结构不是简单复刻 Chat Completions
   - 输出事件、工具调用、内容片段的组织方式也与 Chat Completions 不完全相同

这意味着：

1. “OpenAI-compatible” 只能表示协议风格接近 OpenAI
2. 不能自动推导“必然支持 Chat Completions 和 Responses 两者”
3. 更不能因为 UI 里有 `api_mode = responses`，就假定底层真的已经具备 Responses 语义

而我们当前实现里：

1. `ProviderRequestOptionsService` 会保留 `api_mode`
2. `ModelSettingsAdvancedPanel` 会展示 `chat / responses`
3. `OpenAiLlmGateway` 却固定打到 `/chat/completions`

所以当前与官方接口面对齐的真实状态是：

1. 项目现在真正实现的是 OpenAI 风格的 Chat Completions 主链
2. 还没有实现 OpenAI 官方 Responses 主链
3. 因而 UI 中的 Responses 目前属于“未闭环暴露”

### 12.2 Anthropic 官方的 Messages 是一整套消息协议，不只是一个 URL

Anthropic 官方主路径的关键点并不是只有 `/messages`，还包括：

1. `system` 与 `messages` 的分离
2. `tool_use` / `tool_result` 内容块协议
3. streaming 事件类型与 OpenAI SSE 形态不同
4. `anthropic-version` 等固定 header 合同

我们当前实现其实已经覆盖了其中很大一部分：

1. `AnthropicLlmGateway` 已区分 system prompt
2. 已做 tool_use / tool_result 映射
3. 已实现事件流聚合
4. 已补 `anthropic-version`

但问题也刚好暴露在这里：

1. 这些协议映射逻辑没有单独成为 `AnthropicProtocolAdapter`
2. 它们被堆在 `AnthropicLlmGateway` 内部
3. 这让“Anthropic 协议合同”和“HTTP 重试/回退策略”混成一层

所以 Anthropic 这边的问题不是“没做”，而是“做进去了，但职责还没拆开”。

### 12.3 Gemini 必须拆分成两条概念链

Gemini 这块最容易出误判，因为官方本来就有两种接入面：

1. Gemini 原生接口
   - 典型族是 `generateContent` / `streamGenerateContent`
   - 请求与响应结构是 Google 自己的 schema

2. Gemini OpenAI 兼容入口
   - Google 官方也提供 OpenAI 兼容方式
   - 但这本质上是“Gemini 提供的 OpenAI-compatible route”
   - 不等于 Gemini native

这个差异非常关键。

如果不拆开，就会产生三种常见误伤：

1. 把 `google` 当成单一 provider，然后混用 native 与 compatible base URL
2. 把 Gemini native 的能力误套到 OpenAI-compatible route 上
3. 让 UI 以为“Gemini = 一个协议下拉选项”就能解决

更稳的建模应该是：

1. `ProtocolKind.gemini_native`
2. `ProtocolKind.openai_compatible`
3. `ProviderOffering(google, openai-compatible route)`
4. `ProviderOffering(google, gemini-native route)`

也就是说，Gemini 更能说明为什么“厂商”、“协议”、“路由族”必须分开。

## 13. 当前项目里的兼容概念混淆图

### 13.1 现在被混在一起的五个维度

从代码现状看，至少有五个维度尚未完全正交：

1. 厂商 identity
   - 例如 `openai`、`anthropic`、`google`、`deepseek`

2. 协议种类
   - 例如 `openai_compatible`、`anthropic_compatible`

3. 路由族
   - 例如 `chat_completions`、`responses`、`messages`、`generate_content`

4. 模型能力
   - 是否支持 tools / tool_choice / streaming / thinking / attachments

5. 参数合同
   - `reasoning_effort`
   - `thinking`
   - `enable_thinking`
   - `thinkingBudget`
   - `thinkingLevel`

现在系统里虽然这些信息“都多少有一点”，但分布不均：

1. 厂商 identity 主要在 template / catalog
2. 协议种类主要在 `ProviderProtocolService`
3. 路由族写在 template 的 `route_family` 字段里，但未进入 runtime 强合同
4. 模型能力在 metadata / capability seed / writing catalog 三处共同决定
5. 参数合同则散落在 request options、metadata、gateway、reasoning profile 中

这就是为什么当前很多地方会出现“看起来都支持，但一跑就不一定对”的情况。

### 13.2 `route_family` 目前是标签，不是合同

`provider_interface_template_seed.dart` 里已经有：

1. `chat_completions`
2. `messages`
3. `responses_and_chat`
4. `chat_and_responses`
5. `embeddings`
6. `mixed`

这说明项目其实已经意识到“同一协议下还有不同 route family”。

但因为 runtime 不真正消费这个字段，它现在的地位更像：

1. 目录说明
2. 文档备注
3. UI 参考

而不是：

1. gateway route 选择依据
2. request payload mapper 选择依据
3. UI 选项过滤依据
4. provider connection validation 依据

只要这一步不升级，后续新增多少 provider，都会重复现在的半接入问题。

## 14. 请求类型兼容的真实风险点

### 14.1 “兼容协议”不代表“兼容每一种请求族”

这是最该明确写死在设计里的原则。

例如一个 provider 可以：

1. 支持 OpenAI-compatible chat/completions
2. 不支持 OpenAI Responses
3. 支持 tools
4. 不支持 parallel_tool_calls
5. 支持 stream
6. 但 stream 返回形态又不是官方标准 SSE

如果系统只靠 `protocol = openai_compatible` 来暴露 UI 和发送请求，就会天然过度乐观。

### 14.2 请求类型与 payload builder 必须一一对应

当前最危险的地方不是字段名，而是 payload builder 的语义中心。

例如：

1. `OpenAiChatRequestPayloadBuilder`
   - 它明确是 Chat Completions payload builder

但 runtime 却把它绑定在一个更宽泛的概念下：

1. OpenAI-compatible gateway

这会带来两个问题：

1. 如果以后真接 Responses，要么继续塞 if/else，要么重写另一个 builder
2. 如果某些 provider 标称 OpenAI-compatible，但只兼容部分 route family，当前 builder 没法表达这个差异

更稳的形态应当是：

1. `ChatCompletionsPayloadMapper`
2. `ResponsesPayloadMapper`
3. `AnthropicMessagesPayloadMapper`
4. `GeminiGenerateContentPayloadMapper`

然后 gateway 只负责 transport，不再同时拥有“路由决定权”和“协议语义权”。

### 14.3 流式解析也不应继续挂在大网关里

现在两个 gateway 都把 streaming 聚合做进去了，这在只有两种协议时还能工作，但扩展会迅速变贵。

因为不同路由族的 streaming 合同可能都不同：

1. OpenAI Chat Completions SSE
2. OpenAI Responses 事件流
3. Anthropic Messages 事件流
4. Gemini 原生流式事件

它们不只是字段名不同，而是事件模型就不同。

因此更合理的是：

1. transport 层只负责字节流与 HTTP 生命周期
2. `StreamEventParser` 负责事件解码
3. `StreamResultAssembler` 负责将事件还原成统一 `LlmStreamUpdate`

否则未来只要再加 Gemini native，就会把现有 gateway 再推向一次巨型文件。

## 15. UI 暴露层的正确判断合同

### 15.1 UI 不应直接问“这个厂商支持什么”

因为同一厂商可能有多种路由入口：

1. 官方原生
2. OpenAI-compatible
3. Anthropic-compatible
4. embeddings 专用入口
5. coding 专用入口

例如当前 template 里已经存在这种现实：

1. `deepseek_openai`
2. `deepseek_anthropic`
3. `dashscope_openai_cn`
4. `dashscope_anthropic`
5. `dashscope_embeddings`
6. `dashscope_coding`

这说明“厂商”这一层过粗，无法直接驱动 UI。

### 15.2 更合理的 UI 暴露判定顺序

后续应该统一按下面顺序收口：

1. 当前 credential / provider offering 选中了哪个入口模板
2. 该模板归属哪个 `ProtocolKind`
3. 该模板支持哪些 `RequestRouteFamily`
4. 当前 model 在这条 route family 下是否支持某项能力
5. 最后才决定 UI 是否展示该选项

也就是说，UI 需要依赖的是：

1. `ResolvedProviderRouteContract`
2. `ResolvedCapabilityExposureView`

而不是散落地看：

1. 一个 `supportsTopK`
2. 一个 `api_mode`
3. 一个 `provider_id`

### 15.3 `API 模式` 的暴露条件必须收严

当前最典型的错误暴露就是 `API 模式`。

未来更合理的规则应是：

1. 如果当前 route contract 只有一个可运行族，例如 `messages`
   - 则完全隐藏 API 模式

2. 如果当前 route contract 有多个“已实现且已验证”的族
   - 才展示 API 模式

3. 如果某模型仅在部分 route family 下支持 tools / streaming / attachments
   - 切换 API 模式后，其他高级参数也应联动重算可见性

否则就会出现：

1. UI 看似在切模式
2. 但底层还在走旧链路

## 16. Provider / Base URL / 协议的三层校验模型

### 16.1 当前缺的是“连接合同校验”，不是简单字符串提示

用户担心的一类问题非常实际：

1. 某厂商不同兼容类型是不同 URL
2. 同一个 URL 支持的协议族也不一样
3. 用户虽然选了兼容模式，但请求类型可能仍不对

这说明后面必须补的是“连接合同校验层”。

建议抽成单独概念：

1. `ProviderConnectionContract`
   - provider_id
   - protocol_kind
   - allowed_route_families
   - default_base_url
   - base_url_matchers
   - auth_scheme
   - required_headers
   - stream_contract_kind

### 16.2 校验应分三步而不是一步

第一步，模板匹配：

1. 当前 base URL 命中了哪个 template
2. 若命中多个，是否存在歧义

第二步，协议一致性校验：

1. 用户选择的 protocol 是否与 template 允许值一致
2. 若不一致，应阻止而不是放行

第三步，路由族一致性校验：

1. 当前 `api_mode` 对应的 route family 是否在该 template 允许范围内
2. 若不在，应隐藏或报配置错误

这样做的价值是：

1. 不把错误拖到真正发请求时才暴露
2. UI、CLI、后台任务都能共享同一套校验结果

## 17. Gemini 接入时最容易踩的坑

### 17.1 不能把 Gemini 只当作“再加一个 provider”

如果只新增：

1. `provider_id = google`
2. 一个 base URL
3. 一些模型名

那只是目录层扩充，不是兼容层接入。

Gemini 真正需要区分的是：

1. Google 原生 Gemini API
2. Google 提供的 OpenAI-compatible 接口

这两条链的差异至少包括：

1. URL 族不同
2. payload 结构不同
3. streaming 事件不同
4. 参数名不同
5. tool / attachment 表达方式也可能不同

### 17.2 写作模型事实层里的 Gemini 参数不能直接当 runtime 合同

当前 `builtin_writing_model_catalog_seed.dart` 里已经有：

1. `thinkingLevel`
2. `thinkingBudget`

但这只是“模型语义事实层”的表达。

它并不自动说明：

1. 当前 gateway 知道怎样发送这些参数
2. 当前 provider route 支持这些参数
3. UI 当前显示这些参数就是安全的

所以 Gemini 很适合作为一个警示：

模型事实层可以先行，但 runtime 合同层绝不能跟着想当然。

## 18. 推荐的最终拆层方案

### 18.1 核心新合同

建议后续 API 兼容层至少引入以下核心合同对象：

1. `ProtocolKind`
   - 协议家族

2. `RequestRouteFamily`
   - 请求路径与协议族

3. `ProviderConnectionContract`
   - provider/baseUrl/auth/header/allowed routes

4. `GatewayRouteResolution`
   - runtime 当前实际命中的 endpoint family 与 URL

5. `PayloadMapper`
   - 将统一 `ChatRequest` 映射到具体协议 payload

6. `StreamContractAdapter`
   - 将具体流式事件映射回统一 `LlmStreamUpdate`

7. `CapabilityExposureView`
   - 供 GUI/CLI 用来判断显示哪些选项

### 18.2 各层职责边界

建议把当前职责这样切：

1. `core`
   - 定义协议合同、路由合同、能力暴露合同
   - 负责 provider/model/template/runtime 的归一化与解析

2. `adapters`
   - 只负责 HTTP transport 与协议适配实现
   - 不再兼任“UI 暴露逻辑解释器”

3. `app`
   - 只消费 `CapabilityExposureView`
   - 不自己推断某字段该不该显示

### 18.3 兼容层未来新增类型的正确接入顺序

以后无论是 Gemini、Azure 特化、还是别的大陆厂商新协议，顺序都应一致：

1. 先补协议合同
2. 再补 route family 合同
3. 再补 provider connection contract
4. 再补 payload mapper / stream adapter
5. 再补 capability exposure
6. 最后才在 UI 开放

这样才能保证“新增兼容类型”主要是加模块，而不是横向改一排旧文件。

## 19. 本轮最终结论

这次更完整地看下来，问题本质已经很明确了：

1. 当前项目不是没有 API 兼容层，而是兼容层还停在“能跑的协议入口集合”
2. 它还没有收成“协议合同系统”
3. OpenAI / Anthropic 现有链路能说明主干方向是对的
4. `api_mode` 半接入、`route_family` 非合同化、gateway 巨石化，是当前最需要先解的三件事
5. Gemini 不该直接硬塞进现有结构，否则只会把这些问题成倍放大

所以这一步最正确的结论仍然不是“赶紧加 Gemini”，而是：

先把协议种类、请求族、provider connection contract、能力暴露视图拆正，再让 Gemini 作为第一种按新规则接入的协议类型落地。
