# 写作模型注册表补充资料

最后整理时间：2026-05-30

关联文档：

- `docs/builtin-model-registry-analysis-2026-05-30.md`
- `docs/writing-model-registry-session-order-2026-05-30.md`
- `docs/provider-compatibility-baseline.md`

---

## 1. 这份资料解决什么

这份不是新的顺序文档，也不是直接改代码。

它的目的只有一个：

把你前几轮追问里最关键的那条线补成一份更硬的事实资料，避免后面继续拿“厂商名”“接口名”“协议名”混着用。

尤其是下面这几个问题，这份资料要给出明确答案：

1. 一个“厂商”是不是只能对应一种协议？不是。
2. 一个 `base_url` 是不是只能代表一种能力面？不是。
3. 模型兼容应该挂在接口上，还是挂在模型/offering 上？更应该挂在模型/offering 上。
4. 聚合/中转会不会改原厂思考参数格式？会，而且已经有明确官方文档证据。
5. 我们后续的内置模型列表，应该只做“模型名列表”吗？不够，必须同时记录 offering 级覆盖与能力差异。

这份资料会尽量继承你之前的设计目的：

- 减少手填
- 优先选择而不是裸填 id
- 写作场景默认只暴露少量高价值参数
- 深度思考按模型真实能力显示
- 聚合/中转差异不能写死在 UI
- 尽量整合而不是推倒历史设计

---

## 2. 本轮核验范围

本轮主要核验以下对象，时间点截至 2026-05-30：

### 2.1 原厂/主要模型方

- OpenAI
- Anthropic
- Google Gemini
- DeepSeek
- Z.AI / GLM
- Kimi / Moonshot
- MiniMax
- Xiaomi MiMo
- Doubao / 火山方舟

### 2.2 聚合/中转/托管

- SiliconFlow
- 阿里云百炼 / DashScope / Model Studio
- NVIDIA API Catalog / NIM

### 2.3 provider 壳层 / 路由壳层

- OpenCode Zen
- OpenCode Go

---

## 3. 先给结论

### 3.1 不能再把“接口/厂商名称”当作能力事实源

原因很直接：

1. 同一厂商可能同时提供 OpenAI 兼容和 Anthropic 兼容。
2. 同一根域名下不同路径就可能走不同协议。
3. 同一协议路径里又可能混放文本模型、多模态模型、图像模型、音频模型。
4. 同一个 canonical model 在不同 provider offering 上，深度思考开关、强度参数、返回字段都可能不同。

所以后续实现里：

- `接口` 更接近“凭证 + base url/root + 可选模板”
- `兼容路由` 更接近“某条 endpoint family / protocol family”
- `模型 offering` 才是“最终能力与参数映射”的主承载对象

### 3.2 兼容性应该主要挂在 model offering，而不是只挂在接口设置

更准确地说：

1. 接口设置可以提供“模板级约束”
2. 但最终该模型怎么发请求、能不能开深度思考、用什么参数开、是否要回传 `reasoning_content`
   应由 `model offering capability` 决定

这也是你前面那句判断的核心意思：

> 相同厂商、相同 url、不同路径，甚至同一路径下不同模型，都可能不是同一能力面。

这个判断是对的，而且已经被官方文档反复坐实。

### 3.3 “模型事实”与“offering 覆盖”必须分层

最起码要拆成：

1. `Canonical model`
   - 这个模型家族本身是谁
   - 原厂命名、家族、快照、是否支持思考、是否支持工具、默认模态、上下文等
2. `Provider offering`
   - 某 provider 如何暴露它
   - provider model id
   - 协议/路由
   - base url/path hint
   - offering 级思考参数覆盖
   - offering 级模态限制
3. `Effective capability projection`
   - 给 UI 和运行时消费的结果

---

## 4. 逐家核验后的事实整理

## 4.1 OpenAI

### 已核验事实

1. OpenAI 最新公开前沿模型页已经不是旧的 `GPT-5` 基线，而是 `GPT-5.5` 与 `GPT-5.4` 系列。
2. `GPT-5.5` 官方页显示：
   - model id: `gpt-5.5`
   - reasoning effort 支持 `none / low / medium / high / xhigh`
   - context window `1,050,000`
   - max output `128,000`
   - 同时支持 `v1/chat/completions` 与 `v1/responses`
3. OpenAI 的模型页已经明确把“模型能力”和“可用 endpoint”并列列出，而不是只剩一种 chat surface。

### 对我们实现的含义

1. 不能再把 `GPT-5` 当作“当前最新 OpenAI 主推荐”。
2. OpenAI 系 reasoning 不能只建模成布尔值，而要支持 effort 枚举。
3. OpenAI 原厂模型的“协议兼容”不能只写成 `openai_compatible=true`，因为它同一 host 下还有不同 endpoint family。

### 资料来源

- OpenAI `GPT-5.5` 模型页：
  https://developers.openai.com/api/docs/models/gpt-5.5
- OpenAI 模型总览：
  https://developers.openai.com/api/docs/models

---

## 4.2 Anthropic

### 已核验事实

1. Anthropic 当前公开模型总览已到 `Claude Opus 4.8` 代际。
2. Anthropic 官方说明里：
   - 可通过 Models API 查询 `capabilities`
   - `effort` 在 `Claude Opus 4.8` 默认是 `high`
3. Anthropic 本身是 `Messages API` 体系，不是 OpenAI chat delta 语义。

### 对我们实现的含义

1. Anthropic 不能继续只作为“另一个模型名列表”看待，它有独立消息协议和独立思考控制语义。
2. 如果某 offering 是 Anthropic 兼容，就要记住它不是简单“名字不同的 OpenAI”。
3. Anthropic 侧 reasoning 至少要能表达：
   - 有无思考
   - 是否可调 effort
   - 返回面是否是 content-block 风格

### 资料来源

- Anthropic models overview:
  https://platform.claude.com/docs/en/about-claude/models/overview
- Anthropic 4.8 更新说明：
  https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-8

---

## 4.3 Google Gemini

### 已核验事实

1. Gemini 官方 thinking 文档明确区分：
   - Gemini 3 系列主要用 `thinkingLevel`
   - Gemini 2.5 系列主要用 `thinkingBudget`
2. 文档还明确说明：
   - Gemini 3.1 Pro 不能关闭 thinking
   - Gemini 3 Flash / Flash-Lite 不支持完全意义上的 thinking-off，但 `minimal` 接近“尽量不思考”
   - Gemini 2.5 可通过 `thinkingBudget=0` 关闭
3. Gemini API 是 stateless，涉及 thought signatures / thought summaries 的上下文处理逻辑和 OpenAI、DeepSeek 并不一样。

### 对我们实现的含义

1. `Gemini 3` 与 `Gemini 2.5` 不能共用同一个 thinking 参数模板。
2. 我们的能力层至少要支持两类 Gemini 思考控制：
   - `thinkingLevel`
   - `thinkingBudget`
3. “支持思考但不允许关闭”必须是正式枚举态，不然无法表达 Gemini 3 Pro 这类模型。

### 资料来源

- Gemini thinking：
  https://ai.google.dev/gemini-api/docs/thinking
- Gemini models：
  https://ai.google.dev/gemini-api/docs/models/gemini-v2

---

## 4.4 DeepSeek

### 已核验事实

1. DeepSeek 官方同时提供：
   - OpenAI 兼容入口
   - Anthropic 兼容入口 `https://api.deepseek.com/anthropic`
2. DeepSeek 官方 thinking 文档明确：
   - OpenAI 格式开关：`thinking: {"type":"enabled/disabled"}`
   - OpenAI 格式强度：`reasoning_effort`
   - Anthropic 格式强度：`output_config.effort`
   - thinking 默认开启
3. 文档还明确：
   - 对复杂 agent 请求，如 Claude Code、OpenCode，effort 可能自动拉到 `max`
   - tool call 场景下，后续请求必须完整回传 `reasoning_content`

### 对我们实现的含义

1. 同一个 DeepSeek 厂商，至少已经有两种正式协议面，不能只放一个 provider 条目完事。
2. `thinking 默认开启` 必须能表达成模型行为，而不是 UI 默认值猜测。
3. “tool call 后必须回传 reasoning_content”是运行时约束，不是 UI 备注，应该进入能力元数据。

### 资料来源

- DeepSeek API 首页：
  https://api-docs.deepseek.com/
- DeepSeek Thinking Mode：
  https://api-docs.deepseek.com/guides/thinking_mode
- DeepSeek Anthropic API：
  https://api-docs.deepseek.com/guides/anthropic_api

---

## 4.5 Z.AI / GLM

### 已核验事实

1. 智谱开放平台首页已明确把 `GLM-5.1` 作为当前旗舰之一。
2. 智谱公开的 coding/campaign 页面已明确给出：
   - OpenAI 协议 base url：`https://open.bigmodel.cn/api/paas/v4`
   - Anthropic 协议 base url：`https://open.bigmodel.cn/api/anthropic`
   - Coding Plan 场景下还存在 `https://open.bigmodel.cn/api/coding/paas/v4`
3. 这说明同一厂商下已经明确分出：
   - 通用 API 路由
   - Anthropic 兼容路由
   - coding plan 专用路由

### 对我们实现的含义

1. GLM 不能只建模成“一个厂商、一个 base url”。
2. 我们至少要支持“同 provider 不同 route template”的内置模板。
3. `Coding Plan` 这种路径级变体不能塞回 canonical model；它更像 interface template 或 offering route variant。

### 资料来源

- 智谱开放平台首页：
  https://open.bigmodel.cn/
- GLM Coding 页面：
  https://open.bigmodel.cn/glm-coding
- claw plan 团队页中的协议地址说明：
  https://open.bigmodel.cn/claw-plan-team

---

## 4.6 Kimi / Moonshot

### 已核验事实

1. Kimi 开放平台首页显示：
   - `kimi-k2.6` 是当前最新最智能模型之一
   - `kimi-k2.5` 支持“思考与非思考模式”
2. Kimi 文档中：
   - base url 为 `https://api.moonshot.cn/v1`
   - `kimi-k2.5` 可通过 `thinking: {"type":"disabled"}` 关闭思考
   - tool calling + thinking 模式下，必须保留 `reasoning_content`
3. Kimi 模型总览还列出了：
   - `kimi-k2-thinking`
   - `kimi-k2-thinking-turbo`
   - `moonshot-v1-*`
   - 并给出下线/升级提示

### 对我们实现的含义

1. Kimi 这里至少存在：
   - 支持 thinking 开关的 hybrid 模型
   - thinking-only 的显式 thinking 模型
   - 旧的 `moonshot-v1` 非同一代条目
2. 因此 Kimi 不应只收一条 “Kimi 最新模型”，而应收一个可演进谱系。
3. `reasoning_content` 回传要求和 DeepSeek、MiMo 一样，适合抽成统一运行时能力位。

### 资料来源

- Kimi 开放平台首页：
  https://platform.moonshot.cn/
- Kimi 模型总览：
  https://platform.moonshot.cn/docs/introduction
- Kimi K2.5 文档：
  https://platform.kimi.com/docs/guide/kimi-k2-5-quickstart
- Kimi thinking 发布文：
  https://platform.moonshot.cn/blog/posts/kimi-thinking

---

## 4.7 MiniMax

### 已核验事实

1. MiniMax 官方文档当前主线模型为：
   - `MiniMax-M2.7`
   - `MiniMax-M2.7-highspeed`
   - `MiniMax-M2.5`
2. 文档中明确写到：
   - `MiniMax-M2.7` 在编程、工具调用、搜索等场景表现突出
   - `MiniMax-M2.7` 是 agentic model
   - 存在 `Tool Use & Interleaved Thinking`

### 对我们实现的含义

1. MiniMax 至少不能被压扁成“普通 OpenAI chat 兼容模型”。
2. 它需要具备：
   - tool-use 强能力
   - interleaved thinking 语义标记
3. 这类模型未来即使先走 OpenAI surface，也应保留更细粒度能力元数据。

### 资料来源

- MiniMax models：
  https://platform.minimax.io/docs/guides/models-intro
- MiniMax text generation：
  https://platform.minimax.io/docs/guides/text-generation
- MiniMax interleaved thinking：
  https://platform.minimax.io/docs/guides/text-m2-function-call

---

## 4.8 Xiaomi MiMo

### 已核验事实

1. Xiaomi MiMo 官方开发平台明确同时支持：
   - OpenAI API format
   - Anthropic API format
2. 官方示例给出：
   - OpenAI base url：`https://api.xiaomimimo.com/v1`
   - Anthropic base url：`https://api.xiaomimimo.com/anthropic`
3. MiMo thinking/tool 文档明确：
   - thinking 模式多轮 tool call 时，要回传 `reasoning_content`
   - 否则会 400
4. MiMo 参数文档明确：
   - `mimo-v2.5-pro`、`mimo-v2.5` 在 thinking mode 下不支持自定义 `temperature`
   - 即使传了也会被强制覆盖为推荐默认值 `1.0`
5. 2026-05-30 这一时点，MiMo 官方文档还给出一个非常具体的迁移信息：
   - `MiMo-V2-Pro / Omni` 将在 2026-06-30 完全弃用
   - 2026-06-01 起先自动路由到 `V2.5`

### 对我们实现的含义

1. MiMo 是很典型的“同厂商多协议面”案例。
2. 不能只表达“支持思考”，还要表达：
   - thinking 模式下 `temperature` 无效
   - tool 历史必须保留 reasoning_content
3. `deprecated` 与 `auto-route-to-newer-series` 应考虑进入 registry 备注或 lifecycle 字段。

### 资料来源

- MiMo docs 首页：
  https://platform.xiaomimimo.com/docs/en-US/welcome
- MiMo first API call：
  https://platform.xiaomimimo.com/docs/en-US/quick-start/first-api-call
- MiMo model hyperparameters：
  https://platform.xiaomimimo.com/docs/en-US/quick-start/model-hyperparameters
- MiMo OpenAI API：
  https://platform.xiaomimimo.com/docs/en-US/api/chat/openai-api
- MiMo Anthropic API：
  https://platform.xiaomimimo.com/docs/en-US/api/chat/anthropic-api
- MiMo reasoning_content 回传说明：
  https://platform.xiaomimimo.com/docs/en-US/usage-guide/passing-back-reasoning_content

---

## 4.9 Doubao / 火山方舟

### 已核验事实

1. 火山方舟官方已明确把：
   - Chat API
   - Responses API
   - 深度思考
   作为正式并行能力面来提供。
2. 官方深度思考资料明确：
   - `thinking.type` 支持 `enabled / disabled / auto`
   - `reasoning_effort` / `reasoning.effort` 用于调节思考长度
   - `doubao-seed-1-8-251228` 支持 `enabled（默认）/ disabled`
3. 官方模型页与深度思考页都说明：
   - Doubao 1.8 已支持 Chat API、Batch API、Responses API
   - 工具调用与深度思考可以组合

### 对我们实现的含义

1. Doubao 不能简单当“OpenAI 兼容模型 id 列表”处理。
2. 它已经有明显的 Responses-first 方向，而且 thinking 控制在 Responses API 上更正式。
3. 所以后续 registry 里应能表达：
   - provider supports chat + responses
   - offering 对这两个 surface 的支持程度
   - thought control 风格

### 资料来源

- 火山方舟产品页：
  https://www.volcengine.com/docs/82379
- 豆包 1.8 模型页：
  https://www.volcengine.com/docs/82379/2123228
- 火山方舟深度思考：
  https://www.volcengine.com/docs/82379/1956279
- 火山方舟另一条深度思考/Chat API 资料页：
  https://www.volcengine.com/docs/82379/1449737

---

## 4.10 SiliconFlow

### 已核验事实

1. SiliconFlow 官方明确把自己描述为一站式模型 API 平台，覆盖语言、语音、图像、视频等多种模型能力。
2. 它的 chat completions 文档中明确存在：
   - `enable_thinking`
   - `thinking_budget`
   - `temperature`
   - `top_p`
3. 文档还明确写出：
   - 不是所有模型都支持 `enable_thinking`
   - `thinking_budget` 适用于大多数 reasoning models
4. 它同时有图片、视频、多模态等单独能力页。

### 对我们实现的含义

1. SiliconFlow 不是原厂模型提供者，而是 offering 聚合层。
2. 同一 SiliconFlow provider 下，不能假定所有模型：
   - 都走同一种 thinking 参数
   - 都是纯文本
   - 都支持同样的 tool/streaming/structured output
3. 所以在我们的数据模型里，SiliconFlow 更适合承载 offering override，而不是 canonical model 本体。

### 资料来源

- SiliconFlow chat completions：
  https://docs.siliconflow.cn/en/api-reference/chat-completions/chat-completions
- SiliconFlow reasoning：
  https://docs.siliconflow.cn/en/userguide/capabilities/reasoning
- SiliconFlow 产品介绍：
  https://docs.siliconflow.cn/en/userguide/introduction

---

## 4.11 阿里云百炼 / DashScope / Model Studio

### 已核验事实

1. 百炼官方明确提供 OpenAI 兼容接口：
   - 中国内地：`https://dashscope.aliyuncs.com/compatible-mode/v1`
   - 美国：`https://dashscope-us.aliyuncs.com/compatible-mode/v1`
   - 新加坡：`https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
2. 百炼还明确存在 OpenAI / Anthropic 双协议的接入面，尤其在更多工具/套餐型方案里更加明显：
   - OpenAI: `.../compatible-mode/v1`
   - Anthropic: `.../apps/anthropic`
3. 百炼不是只代理自家 Qwen，它还提供第三方模型接入，包括 DeepSeek、MiniMax 等。

### 对我们实现的含义

1. 百炼是“平台 + 多模型 + 多协议 + 多套餐路由”的复合体，不是单厂商单协议。
2. 同样的“百炼”标签下，至少要区分：
   - 常规按量 OpenAI 兼容
   - 特定套餐 OpenAI 兼容
   - Anthropic 兼容
3. 这也再次证明：
   - `接口/厂商名称` 做成可搜索模板是对的
   - 但底层必须能承载不同 route template 与 offering 约束

### 资料来源

- 百炼 OpenAI 兼容：
  https://help.aliyun.com/zh/model-studio/compatibility-of-openai-with-dashscope
- 百炼产品介绍：
  https://help.aliyun.com/zh/model-studio/what-is-model-studio
- 百炼更多工具 / OpenAI + Anthropic：
  https://help.aliyun.com/zh/model-studio/more-tools
- 百炼上的 MiniMax：
  https://help.aliyun.com/zh/model-studio/minimax-api-by-minimax

---

## 4.12 NVIDIA API Catalog / NIM

### 已核验事实

1. NVIDIA NIM / API Catalog 是标准 API 暴露多模型的托管层。
2. LLM APIs 文档给出统一 endpoint：
   - `https://integrate.api.nvidia.com`
   - `POST /v1/chat/completions`
3. 其 catalog 下同时挂载了很多不同原厂模型：
   - MiniMax
   - Moonshot/Kimi
   - Qwen
   - OpenAI 开源权重
   - NVIDIA 自家 Nemotron
4. 这说明它本质上是统一 surface 下的多 offering 平台。

### 对我们实现的含义

1. NVIDIA 更像“聚合 offering host”，不是 canonical vendor。
2. 同一平台上不同模型之间的能力差异极大，不能套统一思考策略。
3. 如果后续加入 NVIDIA，优先作为 offering template 与 model source，而不是单一 provider 事实层。

### 资料来源

- NVIDIA NIM overview：
  https://docs.api.nvidia.com/nim/docs/introduction
- NVIDIA API quickstart：
  https://docs.api.nvidia.com/nim/docs/api-quickstart
- NVIDIA LLM APIs：
  https://docs.api.nvidia.com/nim/reference/llm-apis

---

## 4.13 OpenCode Zen / Go

### 已核验事实

1. OpenCode Zen 与 OpenCode Go 不是一回事。
2. OpenCode Zen 文档里，已经能看到明显不同的 surface：
   - Anthropic 风格 `.../v1/messages`
   - OpenAI-compatible `.../v1/chat/completions`
   - Google 模型风格 `.../v1/models/<id>`
3. OpenCode Go 文档里也存在同样现象，而且更明显：
   - 一些模型走 `.../chat/completions`
   - MiniMax M2.7 / M2.5 走 `.../messages`
   - 还提供 `.../v1/models` 模型清单入口

### 对我们实现的含义

1. OpenCode 不应被误记成一个“模型厂商”。
2. OpenCode Zen / Go 更像“路由壳层 + curated offering surface”。
3. 因此它们应该归入：
   - interface template / provider surface
   - 不是 canonical model
4. 同一个 OpenCode surface 内部，不同模型甚至可以走不同协议面，这直接否定了“接口决定协议”的简单设计。

### 资料来源

- OpenCode Zen：
  https://dev.opencode.ai/docs/zen
- OpenCode Go：
  https://dev.opencode.ai/docs/go
- OpenCode docs：
  https://dev.opencode.ai/docs

---

## 5. 跨资料归纳出的正式设计结论

## 5.1 至少要分三层

建议后续实现至少保持这三层：

1. `InterfaceCredentialTemplate`
   - 给用户选接口/厂商模板
   - 管 base url、鉴权方式、常见默认值
   - 可以有 route family 提示，但不直接承载最终模型能力
2. `ModelOfferingDescriptor`
   - 这是事实主层
   - 负责 provider model id、canonical model id、协议面、模态、思考控制、tool/response 约束
3. `CapabilityProjection`
   - 给设置页、输入区、运行时消费

## 5.2 reasoning 不能再是一个布尔值

至少要能表达：

- 不支持
- 仅非思考
- 仅思考
- 可开关
- 默认开
- 不可关闭
- 支持强度
- 强度值集合
- 不同强度参数格式
- tool call 时是否必须回传 reasoning_content
- thinking 模式下哪些采样参数失效

## 5.3 provider override 是正式概念，不是补丁字段

因为现在官方资料已经足够证明：

- 原厂 DeepSeek 与 SiliconFlow 参数不同
- 同样是 Anthropic 兼容，不同厂商对 thinking 支持深浅不同
- MiMo / Kimi / DeepSeek 都对 `reasoning_content` 历史回传有硬要求
- Doubao 在 Chat/Responses 上的思考控制语义也不应被糊成一层

所以 offering override 应该是设计中心，不是附加备注。

## 5.4 UI 应该尽量“选”，不要让用户记 id

这条不是抽象偏好，而是被事实层倒逼出来的：

1. 同一模型家族在不同平台上的 `model id` 不同
2. 同一平台还会随快照迁移
3. 同一厂商存在多个协议 base url
4. 某些模型还会被自动路由或弃用

所以：

- 接口/厂商名称应该是可搜索可选模板
- 模型 id 应该优先给可搜索列表
- 命中内置条目后自动填已知信息
- 只有兜底才允许完全手填

---

## 6. 对当前仓库方向的修正建议

结合当前代码与这轮资料，后续应优先避免这几个错误：

### 6.1 不要继续把 provider catalog 当最终模型事实层

`provider catalog` 更像：

- 接口目录
- offering 索引

不是 canonical model 本体。

### 6.2 不要继续靠 provider 名推断思考参数

同样叫 DeepSeek、GLM、MiniMax，走到不同平台后就可能变形。

### 6.3 不要让模型能力判断散落在 UI

设置页与输入区应该只吃统一 projection。

### 6.4 先把“写作场景默认主参数”收束，再把高级参数下沉

默认主参数仍应以：

- `temperature`
- `top_p`
- `深度思考开关`
- `深度思考强度`

为主。

高级协议差异下沉到 offering / custom advanced override。

---

## 7. 我建议下一轮实现时优先落的事实字段

这一段不是最终合同，只是从资料里倒推出来的最小必要字段。

### 7.1 interface template 层

- `template_id`
- `display_label`
- `vendor_family`
- `base_url`
- `protocol_family_candidates`
- `auth_style`
- `supports_model_discovery`
- `notes`

### 7.2 offering 层

- `offering_id`
- `canonical_model_id`
- `provider_id`
- `provider_label`
- `provider_model_id`
- `protocol_family`
- `endpoint_family`
- `modalities`
- `supports_tools`
- `supports_streaming`
- `supports_structured_output`
- `reasoning_behavior`
- `reasoning_toggle_strategy`
- `reasoning_effort_strategy`
- `requires_reasoning_content_on_tool_followup`
- `parameter_invalidations`
- `lifecycle`
- `docs_url`

### 7.3 projection 层

- `show_reasoning_toggle`
- `show_reasoning_effort`
- `reasoning_toggle_enabled`
- `reasoning_default_on`
- `reasoning_disable_allowed`
- `temperature_editable`
- `top_p_editable`
- `recommended_defaults`

---

## 8. 这份资料对后续任务的直接价值

如果我们下一轮开始动实现，这份资料最直接的用处有三条：

1. 能把“接口/厂商模板”和“模型/offering 能力”正式拆开。
2. 能给内置模型列表补上真实世界里最容易踩坑的思考参数差异。
3. 能把“用户可选、自动补全、少手填”的 UI 目标真正建立在事实层之上，而不是 widget 级猜测。

---

## 9. 参考链接清单

### OpenAI

- https://developers.openai.com/api/docs/models
- https://developers.openai.com/api/docs/models/gpt-5.5

### Anthropic

- https://platform.claude.com/docs/en/about-claude/models/overview
- https://platform.claude.com/docs/en/about-claude/models/whats-new-claude-4-8

### Gemini

- https://ai.google.dev/gemini-api/docs/thinking
- https://ai.google.dev/gemini-api/docs/models/gemini-v2

### DeepSeek

- https://api-docs.deepseek.com/
- https://api-docs.deepseek.com/guides/thinking_mode
- https://api-docs.deepseek.com/guides/anthropic_api

### GLM / Z.AI

- https://open.bigmodel.cn/
- https://open.bigmodel.cn/glm-coding
- https://open.bigmodel.cn/claw-plan-team

### Kimi / Moonshot

- https://platform.moonshot.cn/
- https://platform.moonshot.cn/docs/introduction
- https://platform.kimi.com/docs/guide/kimi-k2-5-quickstart
- https://platform.moonshot.cn/blog/posts/kimi-thinking

### MiniMax

- https://platform.minimax.io/docs/guides/models-intro
- https://platform.minimax.io/docs/guides/text-generation
- https://platform.minimax.io/docs/guides/text-m2-function-call

### Xiaomi MiMo

- https://platform.xiaomimimo.com/docs/en-US/welcome
- https://platform.xiaomimimo.com/docs/en-US/quick-start/first-api-call
- https://platform.xiaomimimo.com/docs/en-US/quick-start/model-hyperparameters
- https://platform.xiaomimimo.com/docs/en-US/api/chat/openai-api
- https://platform.xiaomimimo.com/docs/en-US/api/chat/anthropic-api
- https://platform.xiaomimimo.com/docs/en-US/usage-guide/passing-back-reasoning_content

### Doubao / 火山方舟

- https://www.volcengine.com/docs/82379
- https://www.volcengine.com/docs/82379/2123228
- https://www.volcengine.com/docs/82379/1956279
- https://www.volcengine.com/docs/82379/1449737

### SiliconFlow

- https://docs.siliconflow.cn/en/api-reference/chat-completions/chat-completions
- https://docs.siliconflow.cn/en/userguide/capabilities/reasoning
- https://docs.siliconflow.cn/en/userguide/introduction

### 阿里云百炼 / DashScope

- https://help.aliyun.com/zh/model-studio/compatibility-of-openai-with-dashscope
- https://help.aliyun.com/zh/model-studio/what-is-model-studio
- https://help.aliyun.com/zh/model-studio/more-tools
- https://help.aliyun.com/zh/model-studio/minimax-api-by-minimax

### NVIDIA API Catalog / NIM

- https://docs.api.nvidia.com/nim/docs/introduction
- https://docs.api.nvidia.com/nim/docs/api-quickstart
- https://docs.api.nvidia.com/nim/reference/llm-apis

### OpenCode

- https://dev.opencode.ai/docs
- https://dev.opencode.ai/docs/zen
- https://dev.opencode.ai/docs/go
