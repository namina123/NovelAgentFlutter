# 内置模型信息与能力注册表分析

最后更新：2026-05-30

## 1. 本轮目标

这轮不直接改实现，只收束下一轮要落地的“内置模型信息体系”设计。

目标不是简单给模型补几个字段，而是建立一套能长期承载以下诉求的事实源：

1. 内置模型信息尽量完整，减少用户自己查资料和手填参数。
2. 深度思考不是简单 `supports_reasoning: true/false`，而要表达：
   - 模型根本不支持思考
   - 模型只支持非思考
   - 模型只支持思考
   - 模型两种都支持，但默认开
   - 模型两种都支持，但需要参数开启
   - 模型支持思考但不允许关闭
3. “模型本身能力”与“某个厂商/聚合平台如何暴露它”必须分层。
4. 后续 UI 只读统一能力投影，避免继续靠厂商名硬编码，降低用户心力负担。

本轮分析范围在原先基础上，明确补入以下对象：

- 原厂 / 模型方：
  - DeepSeek
  - GLM / Z.AI
  - Kimi / Moonshot
  - MiMo / Xiaomi
  - MiniMax
- 聚合 / 托管 / 中转 provider：
  - SiliconFlow
  - NVIDIA NIM / API Catalog
  - 百炼 / Bailian / DashScope / Model Studio
- provider-multiplexer / 客户端壳层：
  - OpenCode
    - OpenCode Zen
    - OpenCode Go

这里特别记一笔，避免后面再混：

- 你写的 `bailing`，本轮按 **百炼 / Bailian** 归档。
- `SiliconFlow` 明确归为中转/聚合 provider，不属于模型原厂。
- `OpenCode` 不应被归为模型原厂，也不应被归为单一模型 provider；更准确地说，它是一个多 provider 配置壳层，并且其中至少存在 `Zen`、`Go` 这类不同 provider surface。

这也符合此前多轮会话里你反复强调的约束：

- 单一职责
- 解耦
- 不把协议差异写死在 UI
- 用户只看到真正可用的东西
- 设置项尽量少猜、少懂、少查

## 2. 当前实现现状

当前链路主要集中在：

- `packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/provider_catalog_service.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/provider_model_capabilities_seed.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_thinking_parameter_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart`
- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`
- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/model_editor_view_data.dart`

当前已经有的优点：

1. 已经不是完全散乱硬编码。
2. 已有 `provider catalog`、`capability seed`、`thinking_parameter_format` 三层雏形。
3. 设置页和运行态已经共用同一批核心服务。

当前的核心缺口：

1. **模型事实、厂商适配、请求参数映射混在一起。**
2. **深度思考表达能力太弱。**
3. **聚合平台模型和原厂模型没有清晰区分。**
4. **参数支持只能粗粒度地白名单/黑名单，无法表达条件能力。**
5. **无法表达“同一模型在思考/非思考两种模式下参数约束不同”。**
6. **无法表达“某模型支持思考，但只支持某几个 effort 值”。**
7. **无法表达“模型默认思考开启，但允许关闭”与“模型必须思考，不允许关闭”的差异。**
8. **无法表达厂商模型 id、官方文档 URL、模型主页、弃用时间、别名、快照等用户真正需要的信息。**

## 3. 为什么现有结构不够

### 3.1 `thinking_parameter_format` 只是“协议映射”，不是“模型事实”

例如：

- DeepSeek 官方 OpenAI 格式用 `thinking` + `reasoning_effort`
- Anthropic extended thinking 是 `thinking` content blocks + budget
- Gemini 2.5 用 `thinkingBudget`
- Gemini 3 用 `thinkingLevel`
- Qwen3 原生语义是 hybrid thinking，可硬开关，也可软切换

这些不是同一种事：

1. 模型是否能思考
2. 思考是否默认开启
3. 是否允许关闭
4. 如何在某个 API 上表达
5. 返回的思考内容长什么样
6. 工具调用后是否必须把思考内容带回

现在的 `thinking_parameter_format` 只覆盖了第 4 点的一部分。

### 3.2 `supported_parameters` / `unsupported_parameters` 无法表达条件

典型例子：

- DeepSeek 文档明确写了：思考模式下 `temperature`、`top_p` 等参数即使传了也不会生效。
- Gemini 2.5 Pro 不能关闭 thinking，但 Flash 可以通过 `thinking_budget=0` 关闭。
- OpenAI 不同 reasoning 模型对 `reasoning_effort` 可接受值不同。
- Anthropic extended thinking 有最小预算要求。

这些都不是简单的“支持/不支持”。

### 3.3 聚合平台不是模型本体

例如 SiliconFlow：

- 它托管 DeepSeek、Qwen、GLM 等大量模型。
- 它的 `/v1/models` 列表是动态的。
- 某些模型在其平台上可能有额外约束或行为差异。
- 文档还提到部分模型会出现 `Interleaved Thinking` 行为。

所以：

- `DeepSeek-V4-Flash` 这个“模型”
- `deepseek-ai/DeepSeek-V4-Flash` 这个“SiliconFlow 上的可选 offering”

不能再混成一个条目。

## 4. 设计原则

下一轮实现应遵守以下分层：

### 4.1 Canonical Model Facts

描述“这个模型家族/快照本身是什么”。

例如：

- 厂商名
- canonical model id
- 官方模型名
- 官方文档 URL
- 官方 API/模型页 URL
- 上下文长度
- 最大输出
- 输入/输出模态
- 是否支持工具
- 是否支持流式
- 思考模式类型
- 思考返回通道
- 弃用状态

### 4.2 Provider Offering Facts

描述“这个 provider 把哪个模型以什么 id 暴露出来”。

例如：

- provider id
- provider display name
- provider model id
- canonical model id
- provider docs url
- base url
- 是否推荐
- 是否默认显示
- 是否来自动态接口发现
- 是否存在 provider 特有约束

这里的 provider 不只包含原厂 API，也包含：

- 原厂 API：OpenAI、Anthropic、DeepSeek、Moonshot、Z.AI、MiniMax、Xiaomi MiMo
- 聚合托管：SiliconFlow、百炼、NVIDIA API Catalog
- 多 provider 壳层：未来如需导入 OpenCode 配置，也应落在 offering / mapping 层，而不是 canonical model 层；并且 `OpenCode Zen`、`OpenCode Go` 应视作两个不同的 offering surface

### 4.3 Request Parameter Strategy

描述“在这个 provider + offering 上，请求该怎么拼”。

例如：

- thinking toggle 怎么发
- effort 怎么发
- 参数 key 名
- 参数嵌套位置
- 哪些值要映射或裁剪
- 哪些模式下某些参数必须隐藏/禁用

### 4.4 Effective Capability Projection

最终给 UI、设置页、工作台输入区消费的投影结果。

UI 不应该读原始 provider 文档风格字段，只应该读归一化后的能力摘要。

## 5. 建议新增的正式领域合同

## 5.1 `CanonicalModelDescriptor`

建议字段：

- `canonical_id`
- `vendor_id`
- `vendor_label`
- `family`
- `snapshot`
- `display_name`
- `aliases`
- `official_model_page_url`
- `official_api_docs_url`
- `release_notes_url`
- `deprecation`
- `modalities`
- `context_window`
- `max_output_tokens`
- `supports_streaming`
- `supports_tools`
- `supports_tool_choice`
- `supports_structured_output`
- `supports_image_input`
- `supports_file_input`
- `supports_audio_input`
- `supports_reasoning_mode`
- `reasoning_mode_behavior`
- `reasoning_output_channel`
- `reasoning_requires_return_on_tool_followup`
- `parameter_profiles`
- `notes`

其中最关键的是：

### `reasoning_mode_behavior`

不要再用单个布尔值。

建议改成枚举：

- `unsupported`
- `non_thinking_only`
- `thinking_only`
- `hybrid_optional`
- `hybrid_default_on`
- `thinking_required_not_disableable`

### `reasoning_output_channel`

建议枚举：

- `none`
- `reasoning_content`
- `content_block_thinking`
- `hidden_internal`
- `provider_specific_event_stream`

### `reasoning_control_kind`

建议枚举：

- `none`
- `reasoning_effort_only`
- `thinking_object`
- `enable_boolean`
- `budget_tokens`
- `level_enum`
- `provider_strategy`

这会替代现在过于扁平的 `thinking_parameter_format`。

## 5.2 `ProviderModelOfferingDescriptor`

建议字段：

- `provider_id`
- `provider_label`
- `provider_kind`
- `provider_model_id`
- `canonical_model_id`
- `offering_display_name`
- `aliases`
- `base_url`
- `provider_docs_url`
- `supports_dynamic_discovery`
- `discovered_from_api`
- `recommended`
- `visible_by_default`
- `status`
- `provider_overrides`
- `notes`

其中：

### `provider_overrides`

用于覆盖 canonical facts 里不适用于该 provider offering 的部分。

例如：

- SiliconFlow 上某个模型可用 id
- 某聚合商禁用了某参数
- 某 provider 只支持 URL 图片，不支持原生文件
- 某 provider 对 thinking 有特定兼容写法

## 5.3 `ReasoningCapabilityDescriptor`

建议拆成独立对象，而不是散在 metadata 顶层：

- `availability`
- `default_enabled`
- `can_disable`
- `effort_supported`
- `allowed_efforts`
- `default_effort`
- `control_kind`
- `control_schema`
- `returned_channel`
- `must_echo_for_followup_after_tool_calls`
- `mode_specific_parameter_rules`

## 5.4 `ModelParameterDescriptor`

建议字段：

- `key`
- `label`
- `scope`
- `value_type`
- `required`
- `default_value`
- `allowed_values`
- `min`
- `max`
- `step`
- `advanced`
- `user_visible`
- `mode_conditions`
- `conflicts_with`
- `disabled_when`
- `source`
- `description`

这样才能表达：

- 这个参数是基础参数还是高级参数
- 用户要不要看见
- 什么时候该显示
- 什么时候应该自动灰掉

## 6. 建议新增的“模式感知参数规则”

仅靠静态参数表不够，还需要规则对象。

建议增加：

### `ModeSpecificParameterRule`

字段建议：

- `when_reasoning_state`
  - `thinking_on`
  - `thinking_off`
  - `thinking_required`
- `disable_parameters`
- `ignore_parameters`
- `force_parameter_values`
- `allowed_efforts`
- `ui_warnings`

典型用途：

1. DeepSeek thinking on 时，`temperature` / `top_p` 虽可传但无效，应在 UI 投影为不可编辑或提示“此模式下无效”。
2. Gemini 2.5 Pro 应强制 `thinking` 可用但不可关闭。
3. Qwen3 非思考模式与思考模式可给出不同推荐参数预设。

## 7. 本轮联网采集到的关键事实

以下结论均以 2026-05-30 检索到的官方/一手文档为准。

## 7.1 OpenAI

来源：

- `https://platform.openai.com/docs/models`
- `https://platform.openai.com/docs/models/o4-mini`
- `https://platform.openai.com/docs/guides/reasoning`
- `https://platform.openai.com/docs/api-reference/runs/create`

关键事实：

1. OpenAI 当前模型目录已经明显分成 reasoning models 与 non-reasoning GPT models。
2. OpenAI 当前公开模型代际已包含 `GPT-5.5`，不能再以 `GPT-4.1 / o4-mini` 作为“最新 GPT 代际”的默认代表。
3. `o4-mini` 官方模型页显示：
   - context window 200,000
   - max output 100,000
   - 支持 Chat Completions / Responses / Realtime / Assistants / Batch
   - 支持 streaming / function calling / structured outputs
4. OpenAI 文档把 `reasoning_effort` 作为正式参数。
5. API 参考明确提到：
   - `gpt-5.1` 支持 `none / low / medium / high`
   - `gpt-5.1` 默认 `none`
   - `gpt-5.1` 之前的模型默认 `medium`，且不支持 `none`
   - `gpt-5-pro` 默认且仅支持 `high`
   - `xhigh` 在更新模型中可用

对我们设计的含义：

1. OpenAI 的 reasoning 不能再只建模成 `supports_reasoning=true`。
2. 必须支持“可配置值集合因模型而异”。
3. 必须支持“默认非思考”“默认思考”“只允许高强度”这类差异。
4. 模型注册表必须允许“最新代际模型条目”快速替换，不应把最新代表模型写死在 seed 注释或推荐逻辑里。

## 7.2 Anthropic

来源：

- `https://docs.anthropic.com/en/docs/about-claude/models/overview`
- `https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking`
- `https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/extended-thinking-tips`

关键事实：

1. Anthropic 当前模型总览已更新到 `Claude 4.8` 代际，不能再把 `Claude 4 / 4.1` 当成最新基线。
2. Anthropic 官方模型页显示 extended thinking 支持的模型包括：
   - Claude Opus 4.8
   - Claude Sonnet 4.8
   - Claude Opus 4.1
   - Claude Opus 4
   - Claude Sonnet 4
   - Claude Sonnet 3.7
3. Claude Haiku 3.5 / 3 不支持 extended thinking。
4. extended thinking 的 API 形状与普通 text 输出不同，返回 `thinking` content block。
5. 技术说明明确写到：
   - thinking token 最小预算为 1024
   - 大预算长请求推荐 batch / streaming
6. 文档反复强调 thinking block 不能随意改写；某些工具回合需要把 thinking block 带回。

对我们设计的含义：

1. Anthropic 的 reasoning 需要独立表达 `returned_channel=content_block_thinking`。
2. 需要表达 `minimum_budget_tokens=1024` 这类参数约束。
3. 需要表达“某些后续请求必须回传思考块”。

## 7.3 DeepSeek

来源：

- `https://api-docs.deepseek.com/guides/thinking_mode`
- `https://api-docs.deepseek.com/quick_start/pricing`
- `https://api-docs.deepseek.com/`
- `https://api-docs.deepseek.com/news/news250821`

关键事实：

1. 官方 Thinking Mode 文档说明：
   - toggle 参数：`thinking: { "type": "enabled/disabled" }`
   - effort 参数：`reasoning_effort`
   - 默认 thinking 为 `enabled`
   - `low` / `medium` 会映射为 `high`
   - `xhigh` 会映射为 `max`
2. thinking mode 下：
   - `temperature`
   - `top_p`
   - `presence_penalty`
   - `frequency_penalty`
   即使传了也不会生效。
3. thinking 内容通过 `reasoning_content` 返回。
4. 如果在工具调用回合产生了 reasoning，后续请求必须持续带回 `reasoning_content`，否则会报错。
5. Pricing/Models 页显示：
   - `deepseek-v4-flash`
   - `deepseek-v4-pro`
   - 两者都支持 thinking/non-thinking
   - 默认支持 thinking
   - context length 1M
   - max output 384K
6. 首页文档写明：
   - `deepseek-chat` 和 `deepseek-reasoner` 将于 2026-07-24 弃用
7. 2025-08 的 V3.1 发布说明中也明确了：
   - `deepseek-chat` 对应 non-thinking
   - `deepseek-reasoner` 对应 thinking
8. 这说明 DeepSeek 目录已经完成从 `chat/reasoner` 二分命名向 `v4-flash / v4-pro` 家族的迁移，注册表不应继续把 `deepseek-chat` 当主推荐条目。

对我们设计的含义：

1. DeepSeek 是 **`hybrid_default_on`** 的典型代表。
2. effort 值必须支持 provider 映射，而不是假设 UI 值和 API 值一一对应。
3. 模式切换后参数有效性会变化，必须有 `mode_specific_parameter_rules`。
4. 要正式支持模型弃用信息与别名迁移。

## 7.4 Gemini / Vertex AI

来源：

- `https://ai.google.dev/gemini-api/docs/thinking`
- `https://cloud.google.com/vertex-ai/generative-ai/docs/thinking`
- `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-flash`

关键事实：

1. 按 Google Developers Blog 在 **2026-05-19** 的官方发布口径，Gemini 最新系列已经到 **`Gemini 3.5`**。
2. 但 `Google AI for Developers / Gemini API models` 页面当前仍明显展示：
   - `Gemini 3 Pro`（preview）
   - `Gemini 3 Flash`（preview）
3. Gemini 当前公开可见的 GA 主线仍是：
   - `Gemini 2.5 Pro`
   - `Gemini 2.5 Flash`
   - `Gemini 2.5 Flash-Lite`
4. Gemini 2.5 系列使用 `thinkingBudget`。
5. Gemini 3 系列使用 `thinkingLevel`。
6. Gemini 2.5 文档明确给出：
   - `thinkingBudget = 0` 可关闭 thinking（但并非所有型号都允许）
   - `thinkingBudget = -1` 表示动态 thinking
7. 文档明确写到：
   - Gemini 2.5 Pro 不能关闭 thinking
   - Gemini 2.5 Flash / Flash-Lite 可关闭
8. Gemini 3 中：
   - `thinkingLevel`
   - `MINIMAL` 不是传统意义的完全关闭
   - 某些模型仍需要处理 thought signatures

对我们设计的含义：

1. Gemini 证明“thinking 开关”不一定是布尔值。
2. 必须支持 `budget_tokens` 与 `level_enum` 两种控制模型。
3. 必须支持“不可完全关闭，但可降到 minimal”这种状态。
4. Gemini 的版本更新较快，模型注册表需要允许“同家 provider 内多 thinking schema 并存”，不能假设某一代 schema 会覆盖全系。
5. 注册表应明确区分：
   - `latest_family_generation`
   - `latest_ga_generation`
   否则“最新模型”与“默认稳定推荐模型”会混淆。
6. Gemini 还是一个明确例子：**不同官方页面可能不同步**，所以注册表需要区分：
   - `announcement_latest_generation`
   - `api_docs_latest_generation`
   - `latest_ga_generation`
   否则会把“官宣已发布”与“API 文档已完全展开”误当成同一状态。

## 7.5 Qwen

来源：

- `https://qwen.readthedocs.io/en/v3.0/getting_started/quickstart.html`
- `https://qwen.readthedocs.io/en/stable/inference/transformers.html`

关键事实：

1. Qwen3 默认会先 thinking 再回答。
2. 官方文档提供：
   - `enable_thinking=False` 作为 hard switch
   - `/think` 和 `/no_think` 作为 soft switch
3. 文档还给出思考/非思考模式下不同推荐采样参数。

对我们设计的含义：

1. Qwen 是 **模型原生 hybrid thinking** 的典型，不应简单视为某个聚合 provider 的私有能力。
2. 需要区分“原生模型支持 hybrid thinking”和“某个 API 接口是否真的暴露该开关”。
3. 参数推荐值可按 reasoning state 分模式维护。

## 7.6 SiliconFlow

来源：

- `https://docs.siliconflow.com/quickstart/models`
- `https://docs.siliconflow.com/en/api-reference/models/get-model-list`
- `https://docs.siliconflow.com/en/userguide/guides/interleaved-thinking`
- `https://docs.siliconflow.com/en`

关键事实：

1. SiliconFlow 是动态聚合平台，不是单一模型厂商。
2. 它提供模型列表接口，可动态返回平台可见模型。
3. 平台文档展示了大量 hosted models，而不是少量稳定固定模型。
4. 文档提到部分模型存在 `Interleaved Thinking` 行为。
5. 你提醒的这个点需要正式写进设计约束里：SiliconFlow 上部分模型会把原厂 thinking 参数改写成聚合面自己的控制参数，例如某些模型使用 `enable_thinking`，而不是原厂的 `thinking` object。

对我们设计的含义：

1. 不应再把 SiliconFlow 里的模型当成和原厂静态模型同层的固定种子。
2. 需要区分：
   - curated built-in 推荐模型
   - provider 动态发现模型
3. 聚合平台上的 DeepSeek/Qwen 等 offering 应通过 `canonical_model_id + provider_model_id` 建模。
4. `reasoning_control_kind` 不能只放在 canonical model 上，必须允许 offering override。
5. 同一个 canonical model 在不同中转上的思考开关字段可能不同：
   - 原厂 DeepSeek：`thinking`
   - 某些 SiliconFlow offering：`enable_thinking`
   - 某些百炼 offering：`enable_thinking` 或 `reasoning.effort`

## 7.7 GLM / Z.AI

来源：

- `https://docs.z.ai/guides/llm/glm-5.1`
- `https://docs.z.ai/guides/capabilities/thinking-mode`
- `https://docs.z.ai/guides/capabilities/thinking`
- `https://docs.z.ai/guides/overview/concept-param`
- `https://docs.z.ai/guides/develop/http/introduction`

关键事实：

1. Z.AI 当前官方开发文档已把 GLM 系列放在统一平台之下，并区分：
   - General API endpoint
   - Coding API endpoint
2. `GLM-5.1` 官方页显示：
   - context length 200K
   - maximum output 128K
3. Thinking Mode 文档明确：
   - `GLM-5.1 / GLM-5 / GLM-4.7` 默认开启 thinking
   - 可通过 `thinking: {"type":"disabled"}` 关闭
   - 支持 interleaved thinking
4. preserved thinking 文档明确：
   - 若后续请求希望保持推理链，需带回 `reasoning_content`
5. 参数概念页说明 `thinking` 适用于 `GLM-4.5` 及以上。

对我们设计的含义：

1. GLM 是 **`hybrid_default_on`** 族群。
2. 需要支持：
   - `thinking` object 开关
   - preserved / interleaved thinking 这类 follow-up 约束
3. `General API` 与 `Coding API` 是同一品牌下两个不同 offering surface，不应只保留一个 base URL。

## 7.8 Kimi / Moonshot

来源：

- `https://platform.kimi.ai/docs/models`
- `https://platform.kimi.ai/docs/api/models-overview`
- `https://platform.kimi.ai/docs/guide/use-kimi-k2-thinking-model`
- `https://platform.kimi.ai/docs/introduction`
- `https://www.kimi.com/help/kimi-api/api-overview`

关键事实：

1. Kimi 官方平台当前公开：
   - `kimi-k2.6`
   - `kimi-k2.5`
   - `moonshot-v1`
2. 官方文档明确：
   - `kimi-k2.6` 支持 thinking / non-thinking
   - 默认 thinking 开启
   - 可通过 `thinking: {"type":"disabled"}` 关闭
3. thinking 模型说明页明确：
   - `kimi-k2-thinking` 是 only-thinking 模型
   - `kimi-k2.6` 是 hybrid 且默认开启 thinking
4. 平台文档说明 Kimi 支持多模态输入与工具能力。

对我们设计的含义：

1. Kimi 需要同时支持：
   - `thinking_only`
   - `hybrid_default_on`
2. 不能把 Kimi 的“官方工具能力”直接等同为所有模型 offering 都支持。
3. Kimi 的多模态能力应落在具体 offering，而不是 provider 默认值。

## 7.9 MiniMax

来源：

- `https://platform.minimaxi.com/docs/guides/text-generation`
- `https://platform.minimaxi.com/docs/release-notes/models`
- `https://platform.minimaxi.com/docs/guides/text-m2-function-call`
- `https://platform.minimaxi.com/docs/api-reference/api-overview`
- `https://platform.minimaxi.com/docs/api-reference/models/anthropic/list-models`

关键事实：

1. MiniMax 开放平台当前文本模型包含：
   - `MiniMax-M2.7`
   - `MiniMax-M2.7-highspeed`
   - `MiniMax-M2.5`
   - `MiniMax-M2.5-highspeed`
2. 文本模型文档显示上下文窗口为 204,800。
3. 工具使用文档明确：
   - `MiniMax-M2.7` 原生支持 Interleaved Thinking
   - 面向 Agentic Model 场景
4. 平台支持模型列表接口。

对我们设计的含义：

1. MiniMax 至少要支持“部分模型具备 interleaved thinking/tool-use 强优化”。
2. `highspeed` 这类 offering 应视为 provider variant，而非独立 canonical model。
3. 应预留 provider 动态发现新 offering 的入口。

## 7.10 MiMo / Xiaomi

来源：

- `https://platform.xiaomimimo.com/docs/en-US/welcome`
- `https://mimo.mi.com/`

关键事实：

1. Xiaomi MiMo 已有官方 API Open Platform。
2. 官方文档明确：
   - thinking mode 与 agent 多轮场景下
   - 若历史中存在 tool call
   - 后续交互必须完整回传 `reasoning_content`
   - 否则会报错

对我们设计的含义：

1. MiMo 说明“必须回传 reasoning_content”是一类正式能力，不是 DeepSeek 的单独特例。
2. 这类 follow-up 约束应该提升为统一 capability 字段。

## 7.11 NVIDIA NIM / API Catalog

来源：

- `https://docs.api.nvidia.com/nim/docs/introduction`
- `https://docs.api.nvidia.com/nim/docs/product`
- `https://docs.api.nvidia.com/nim/reference/nvidia-nemotron-3-nano-omni-30b-a3b-reasoning`
- `https://docs.api.nvidia.com/nim/reference/nvidia-llama-3_3-nemotron-super-49b-v1_5`

关键事实：

1. NVIDIA NIM 是托管/可自托管 inference microservice/catalog，不是单一模型厂商。
2. 它承载大量第三方模型与 NVIDIA 自有模型。
3. 不同模型页会分别声明：
   - reasoning 是否默认开启
   - 如何关闭（如 `chat_template_kwargs.enable_thinking = false`）
   - reasoning budget 参数

对我们设计的含义：

1. NVIDIA 必须归为聚合托管 offering 层。
2. 需要允许 provider offering 对 reasoning control schema 做局部覆盖。

## 7.12 百炼 / Bailian / DashScope / Model Studio

来源：

- `https://help.aliyun.com/zh/model-studio/deep-thinking`
- `https://help.aliyun.com/zh/model-studio/stream`
- `https://help.aliyun.com/zh/model-studio/text-generation-model`
- `https://www.alibabacloud.com/help/zh/model-studio/models`
- `https://help.aliyun.com/zh/model-studio/token-plan-tools-and-mcp`

关键事实：

1. 百炼模型面同时承载：
   - Qwen 系列
   - DeepSeek-R1
   - GLM-5
   - kimi-k2.5
   - MiniMax-M2.5
   等多类模型 offering。
2. 官方“深度思考模型的用法”明确区分：
   - 混合思考模式
   - 仅思考模式
3. 文档直接给出了显著差异：
   - 某些 Qwen3.x 默认开启思考
   - 某些默认不开启
   - 某些仅思考，不支持 `enable_thinking`
   - `QwQ` 与 `DeepSeek-R1` 总会进行思考
4. 文档还说明：
   - 在 DashScope API 下，某些模型用 `enable_thinking`
   - 在 Responses API 下，可用 `reasoning.effort`
5. Token Plan / MCP 文档说明：
   - 部分工具能力来自模型内置工具
   - 其他模型则通过 MCP 提供

对我们设计的含义：

1. 百炼是“单 provider 承载多 canonical models、多 reasoning schema、多 tool surfaces”的典型复杂面。
2. 必须支持 **同一 provider 下，不同 offering 的 reasoning 控制方式不同**。
3. provider-level 默认值远远不够，必须下沉到 offering-level。
4. 这与 SiliconFlow 的情况一起证明：聚合/中转平台可以重写原厂 thinking 参数形态，因此请求参数策略必须是 `provider offering aware` 的。

## 7.13 OpenCode

来源：

- `https://dev.opencode.ai/docs/providers/`
- `https://dev.opencode.ai/docs/models/`
- `https://dev.opencode.ai/docs/config`

关键事实：

1. OpenCode 是可接 75+ providers 的客户端/配置壳层。
2. OpenCode 文档明确存在至少两个由 OpenCode 团队提供的 provider surface：
   - `OpenCode Zen`
   - `OpenCode Go`
3. `OpenCode Zen` 是 curated model list，由 OpenCode 团队提供、测试和验证。
4. `OpenCode Go` 是低成本订阅式 provider surface，提供一批经过筛选的 open coding models。
5. `OpenCode Go` 当前文档列出的模型包含：
   - `GLM-5`
   - `GLM-5.1`
   - `Kimi K2.5`
   - `Kimi K2.6`
   - `MiMo-V2.5`
   - `MiMo-V2.5-Pro`
   - `MiniMax M2.5`
   - `MiniMax M2.7`
   - `Qwen3.5 Plus`
   - `Qwen3.6 Plus`
   - `DeepSeek V4 Pro`
   - `DeepSeek V4 Flash`
6. `OpenCode Zen` 使用 `opencode/<model-id>` 形式的模型 id。
7. OpenCode 同时允许用户接入任何其他 provider，并支持自定义 `baseURL` 与模型映射。

对我们设计的含义：

1. OpenCode 不该进入 canonical vendor 列表。
2. `Zen` 与 `Go` 也不应被当成 canonical model vendor；它们更像 OpenCode 体系下两个不同的 provider offering surface。
3. 这进一步证明：
   - provider surface
   - model id mapping
   - curated model pool
   都必须是正式领域层，而不是补丁字段。
4. 如果未来我们要导入 OpenCode 风格配置，应通过 offering mapping 适配，而不是回改 canonical model 层。

## 8. 下一轮实现建议的数据结构

## 8.1 不要继续扩写单一 seed 文件

当前两个核心 seed：

- `provider_model_catalog_seed.dart`
- `provider_model_capabilities_seed.dart`

已经开始承担过多职责。

建议拆成至少四类：

1. `builtin_canonical_model_seed.dart`
2. `builtin_provider_offering_seed.dart`
3. `reasoning_strategy_seed.dart`
4. `provider_parameter_strategy_seed.dart`

## 8.2 建议新增的核心服务

### Core 层

- `canonical_model_registry_service.dart`
- `provider_model_offering_registry_service.dart`
- `reasoning_capability_projection_service.dart`
- `provider_parameter_strategy_service.dart`
- `effective_model_capability_service.dart`
- `dynamic_provider_model_discovery_service.dart`（可先只定义接口）

### App 层

- `model_registry_view_data_service.dart`
- `model_display_name_resolver_service.dart`
- `model_capability_badge_service.dart`
- `model_parameter_editor_policy_service.dart`

## 8.3 建议保留的旧层，但要降权

### `ProviderThinkingParameterService`

不应继续扮演“模型 reasoning 事实源”，应下沉为：

- 只负责“把已归一化的 reasoning strategy 翻译为请求参数”

### `ProviderModelMetadataService`

不应直接自己推断太多能力，应改成：

- 聚合 canonical facts
- provider offering facts
- effective reasoning projection
- parameter schema projection

### `ProviderCatalogService`

不应再直接把 provider 与 model 混在一个静态目录里当成唯一事实源。

## 9. 对 UI / 用户体验的直接收益

如果按上面的分层做，后续 UI 可以真正做到：

1. 只显示当前 offering 真正可用的参数。
2. 深度思考开关的显隐和默认值完全能力驱动。
3. 用户看到的是：
   - 厂商名
   - 模型中文显示名/别名
   - 官方模型 id
   - 能否思考
   - 是否默认思考
   - 是否能关闭
   - 可调参数范围
4. 对于 SiliconFlow 这种聚合 provider，可以同时做到：
   - 列出平台真实可用模型
   - 又不丢失 canonical model 的友好说明
5. 后续即便继续接：
   - 去 AI 这类非技能能力装载
   - 智能体模型限制
   - 模型/智能体组合能力过滤
   也不会再回到 UI 硬编码。

## 10. 下一轮建议改动文件

## 10.1 Core 新增

- `packages/novel_agent_core/lib/src/llm/catalog/builtin_canonical_model_seed.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/builtin_provider_offering_seed.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/canonical_model_registry_service.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/provider_model_offering_registry_service.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/reasoning_capability_descriptor.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/model_parameter_descriptor.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/mode_specific_parameter_rule.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/effective_model_capability_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_parameter_strategy_service.dart`

## 10.2 Core 重构

- `packages/novel_agent_core/lib/src/llm/catalog/provider_catalog_service.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/provider_model_capabilities_seed.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_thinking_parameter_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart`
- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`

## 10.3 App 侧重构

- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/model_editor_view_data.dart`

必要时新增：

- `apps/novel_agent_app/lib/features/settings/presentation/models/model_reasoning_view_data.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/model_offering_view_data.dart`

## 10.4 测试建议

- `packages/novel_agent_core/test/provider_model_metadata_service_test.dart`
- `packages/novel_agent_core/test/provider_request_options_service_test.dart`
- `packages/novel_agent_core/test/model_execution_profile_service_test.dart`
- 新增 `canonical_model_registry_service_test.dart`
- 新增 `effective_model_capability_service_test.dart`
- 新增 `reasoning_capability_projection_test.dart`
- App 侧新增设置页投影测试

## 11. 下一轮实现顺序建议

建议分 5 个小任务，不要一轮硬做完：

1. **建立新领域合同与 seed 拆分**
   - 只建模，不改 UI
2. **接通 capability projection**
   - 让现有 metadata 从新事实源生成
3. **接通 request strategy**
   - 让请求参数生成从新 strategy 走
4. **接通设置页 view data**
   - 让设置页能展示更准确的模型信息
5. **再决定是否扩模型列表 UI**
   - 先把事实源做对，再谈展示

## 12. 本轮结论

结论很明确：

当前项目已经有“模型能力链”的雏形，但还停留在“能用”的早期阶段，离“用户最小心力负担”和“已知可获取内容最大适配”还有明显距离。

下一轮不应该继续在现有 `supports_reasoning + thinking_parameter_format + supported_parameters` 上堆字段，而应该正式升级成：

1. canonical model facts
2. provider offering facts
3. reasoning strategy
4. parameter schema
5. effective capability projection

并且要特别新增一条硬约束：

6. **reasoning 参数策略必须允许 provider offering 覆盖 canonical model 默认策略**

因为现实里已经明确存在：

- 最新模型代际变化很快，例如 GPT 已到 5.5、Claude 已到 4.8
- 同一 canonical model 经不同聚合/中转暴露时，thinking 参数可能被改写
- 中转平台可能把原厂 `thinking` object 改成 `enable_thinking`
- 另一条接入面又可能改成 `reasoning.effort` 或其他嵌套格式

只有这样，后续才有可能稳定支撑：

- OpenAI
- Anthropic
- DeepSeek
- GLM / Z.AI
- Kimi / Moonshot
- Gemini
- Qwen
- MiniMax
- MiMo / Xiaomi
- SiliconFlow 这类聚合平台
- SiliconFlow 这类中转/聚合平台
- NVIDIA NIM 这类托管平台
- 百炼这类多模型聚合平台
- OpenCode 这类 provider-multiplexer 配置来源
- OpenCode Zen / Go 这类壳层内部的独立 offering surface

同时不把 UI、设置页、请求拼装和模型事实继续耦死在一起。

## 13. 参考来源

- OpenAI Models: https://platform.openai.com/docs/models
- OpenAI GPT-5.5: https://platform.openai.com/docs/models/gpt-5.5
- OpenAI o4-mini: https://platform.openai.com/docs/models/o4-mini
- OpenAI Reasoning Guide: https://platform.openai.com/docs/guides/reasoning
- OpenAI API Reference (`reasoning_effort`): https://platform.openai.com/docs/api-reference/runs/create
- Anthropic Models Overview: https://docs.anthropic.com/en/docs/about-claude/models/overview
- Anthropic Claude 4.8: https://docs.anthropic.com/en/docs/about-claude/models/all-models#model-comparison-table
- Anthropic Extended Thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
- Anthropic Extended Thinking Tips: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/extended-thinking-tips
- DeepSeek Thinking Mode: https://api-docs.deepseek.com/guides/thinking_mode
- DeepSeek Models & Pricing: https://api-docs.deepseek.com/quick_start/pricing
- DeepSeek API Home: https://api-docs.deepseek.com/
- DeepSeek V3.1 Release: https://api-docs.deepseek.com/news/news250821
- Gemini Thinking: https://ai.google.dev/gemini-api/docs/thinking
- Gemini Models: https://ai.google.dev/gemini-api/docs/models
- Gemini 3.5 Announcement: https://developers.googleblog.com/en/introducing-gemini-35/
- Vertex AI Thinking: https://cloud.google.com/vertex-ai/generative-ai/docs/thinking
- Vertex AI Google Models: https://docs.cloud.google.com/vertex-ai/docs/generative-ai/learn/models
- Gemini 3 Flash docs: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-flash
- Qwen Quickstart: https://qwen.readthedocs.io/en/v3.0/getting_started/quickstart.html
- Qwen Transformers Inference: https://qwen.readthedocs.io/en/stable/inference/transformers.html
- SiliconFlow Model List: https://docs.siliconflow.com/quickstart/models
- SiliconFlow List Models API: https://docs.siliconflow.com/en/api-reference/models/get-model-list
- SiliconFlow Interleaved Thinking: https://docs.siliconflow.com/en/userguide/guides/interleaved-thinking
- GLM-5.1: https://docs.z.ai/guides/llm/glm-5.1
- Z.AI Thinking Mode: https://docs.z.ai/guides/capabilities/thinking-mode
- Z.AI Thinking: https://docs.z.ai/guides/capabilities/thinking
- Z.AI Parameters: https://docs.z.ai/guides/overview/concept-param
- Z.AI HTTP Introduction: https://docs.z.ai/guides/develop/http/introduction
- Kimi Models: https://platform.kimi.ai/docs/models
- Kimi Models Overview: https://platform.kimi.ai/docs/api/models-overview
- Kimi K2 Thinking Guide: https://platform.kimi.ai/docs/guide/use-kimi-k2-thinking-model
- Kimi Introduction: https://platform.kimi.ai/docs/introduction
- Kimi API Overview: https://www.kimi.com/help/kimi-api/api-overview
- MiniMax Text Generation: https://platform.minimaxi.com/docs/guides/text-generation
- MiniMax Models Release Notes: https://platform.minimaxi.com/docs/release-notes/models
- MiniMax Function Call / Thinking: https://platform.minimaxi.com/docs/guides/text-m2-function-call
- MiniMax API Overview: https://platform.minimaxi.com/docs/api-reference/api-overview
- MiniMax Models API: https://platform.minimaxi.com/docs/api-reference/models/anthropic/list-models
- Xiaomi MiMo Open Platform: https://platform.xiaomimimo.com/docs/en-US/welcome
- MiMo Home: https://mimo.mi.com/
- NVIDIA NIM Intro: https://docs.api.nvidia.com/nim/docs/introduction
- NVIDIA NIM Product: https://docs.api.nvidia.com/nim/docs/product
- NVIDIA Nemotron Reasoning: https://docs.api.nvidia.com/nim/reference/nvidia-nemotron-3-nano-omni-30b-a3b-reasoning
- NVIDIA Llama Nemotron: https://docs.api.nvidia.com/nim/reference/nvidia-llama-3_3-nemotron-super-49b-v1_5
- Bailian Deep Thinking: https://help.aliyun.com/zh/model-studio/deep-thinking
- Bailian Streaming: https://help.aliyun.com/zh/model-studio/stream
- Bailian Text Models: https://help.aliyun.com/zh/model-studio/text-generation-model
- Bailian Models Overview: https://www.alibabacloud.com/help/zh/model-studio/models
- Bailian Tool Plan / MCP: https://help.aliyun.com/zh/model-studio/token-plan-tools-and-mcp
- OpenCode Providers: https://dev.opencode.ai/docs/providers/
- OpenCode Models: https://dev.opencode.ai/docs/models/
- OpenCode Config: https://dev.opencode.ai/docs/config
