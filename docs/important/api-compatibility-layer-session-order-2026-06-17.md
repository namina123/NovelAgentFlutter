# API 兼容层重构与 Gemini 接入任务顺序文档（2026-06-17）

最后更新：2026-06-17

关联主分析文档：

- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`

相关旧分析与基线文档：

- `docs/provider-compatibility-baseline.md`
- `docs/builtin-model-registry-analysis-2026-05-30.md`
- `docs/writing-model-registry-research-2026-05-30.md`
- `agent.md`

---

## 1. 这份文档解决什么

这份文档解决的是：

把当前项目已经“能跑但协议合同未收口”的 API 兼容层，拆成一条可以连续推进的、适合 `gpt-5.4-mini` 执行的实施主线。

它要覆盖的不是单点修 bug，而是完整收口以下问题：

1. `OpenAI-compatible` 与 `Anthropic-compatible` 当前虽然可运行，但仍有明显硬编码耦合。
2. `api_mode` 已泄漏到 UI 和设置层，但还不是真正的运行合同。
3. `route_family` 已存在于模板层，但还不是运行时第一公民。
4. gateway 仍是“大文件 + 多职责混合”的结构，不利于继续加 `Responses` 和 `Gemini`。
5. UI 暴露规则还没有真正做到“只显示当前协议 + 路由 + 模型能力允许的项”。
6. Gemini 目前只存在于模型事实层，不存在真正的可运行链路。
7. provider / base URL / 协议 / 路由 / 模型能力之间，缺少统一连接合同与验证层。

换句话说，这不是“给 Gemini 加个 gateway 文件”那么简单，而是：

先把协议合同系统收正，再让 `Responses` 与 `Gemini` 作为按新合同接入的第一批真实落地对象。

---

## 2. 与旧文档的关系

### 2.1 与 `provider-compatibility-baseline.md` 的关系

旧文档已经明确了几个长期正确的原则：

1. 调度层大体可共用。
2. 协议层 / 流式层 / 工具消息层不能共用。
3. `Responses API` 不能继续伪装成 Chat。
4. `Gemini OpenAI compatibility` 只能视为“部分 OpenAI 兼容”。

这份新顺序文档不推翻这些原则，而是把它们真正落成实现顺序。

### 2.2 与 `builtin-model-registry-analysis-2026-05-30.md` / `writing-model-registry-research-2026-05-30.md` 的关系

旧文档已经把模型事实、provider offering、reasoning 参数策略分层的重要性讲清楚了。

这份顺序文档吸收其中最关键的结论：

1. 模型事实层和 provider offering 层必须分开。
2. 不同 provider route 不能共享同一套 thinking / effort 假设。
3. UI 应优先给用户选模板、选 offering，而不是让用户硬记模型 id 与协议细节。

但本轮主线不会把“整个模型注册表大改造”一次性吞完。

本轮只做与 API 兼容层直接相关、且会影响运行正确性的那一部分：

1. protocol / route / provider connection 合同
2. offering 级 route / capability 绑定
3. 与这些合同直接相关的元数据投影和 UI 过滤

### 2.3 与 `agent.md` 的关系

本轮必须严格遵守 `agent.md` 里已经冻结的几个项目级硬约束：

1. 多协议兼容边界必须成立。
2. `Responses API` 必须单独适配。
3. `Anthropic` 必须单独处理 messages 与 tool blocks。
4. `Gemini native` 必须独立 adapter。
5. UI、CLI 只能消费稳定合同，不能反向补底层缺口。
6. 不能把 fallback、probe、bridge 变成新的业务中心。
7. 单文件超过 400 行要复核，超过 700 行必须拆。

---

## 3. 已有实现去重审计

## 3.1 已经有且方向正确的部分

这些不应推倒重来，只应作为本轮基础：

1. `ProviderProtocolService`
   - 已把协议枚举集中化。

2. `provider_interface_template_seed.dart`
   - 已开始表达 provider 模板、base URL、`route_family` 等信息。

3. `ProviderRuntimeProfileService`
   - 已有“把 provider + model + capability 归一化成运行态”的主入口。

4. `ProviderModelMetadataService`
   - 已经承担一部分“UI 应该显示什么”的投影职责。

5. `ProviderRequestOptionsService`
   - 已经承担“把运行态翻译为请求参数”的职责雏形。

6. `OpenAiLlmGateway`
   - 现有 Chat Completions 主链可运行。

7. `AnthropicLlmGateway`
   - 现有 Messages 主链可运行。

8. `builtin_writing_model_catalog_seed.dart`
   - 已开始积累跨厂商模型事实，Gemini 事实也已存在。

## 3.2 已有但只是半成品的部分

这些是本轮重点，不应继续假装已经完成：

1. `api_mode`
   - 已存储
   - 已显示
   - 但未驱动实际 route 选择

2. `route_family`
   - 已写入 template
   - 但未参与 runtime route resolution

3. `provider detail / model settings UI`
   - 已能显示部分能力
   - 但尚未按“协议 + 路由 + offering 能力”严格过滤

4. `Gemini`
   - 已有模型事实
   - 但没有协议枚举、template、gateway、payload mapper、adapter 分支

5. `AdapterBundle.createGateway()`
   - 能工作
   - 但仍是硬编码分叉点

## 3.3 明确不能继续延长寿命的旧形态

以下形态本轮应开始收口，不允许继续作为长期正式设计：

1. `OpenAiLlmGateway` 同时负责：
   - endpoint path
   - payload building
   - SSE 解析
   - tool call 聚合
   - transport retry

2. `AnthropicLlmGateway` 同时负责：
   - payload 映射
   - stream 解析
   - tool block 映射
   - 回退策略

3. `api_mode` 以“UI 下拉字段”形式先暴露、后实现。

4. `route_family` 只当说明字段，不当运行合同。

5. 以 `provider_id` 或 `kind` 单独决定高级参数显隐。

---

## 4. 本轮冻结的架构边界

为了避免 mini 在实现时边做边漂，本轮先冻结边界。

### 4.1 `core` 必须负责

1. `ProtocolKind`
2. `RequestRouteFamily`
3. `ProviderConnectionContract`
4. `GatewayRouteResolution`
5. `CapabilityExposureView`
6. `api_mode -> route_family` 的正式运行合同
7. provider template / offering / runtime profile 的归一化与解析

### 4.2 `adapters` 必须负责

1. HTTP transport
2. protocol adapter
3. payload mapper
4. stream parser / stream adapter
5. route resolver 的具体协议拼接
6. gateway registry / factory

### 4.3 `app` 必须负责

1. 只消费 `CapabilityExposureView`
2. 只消费 `ProviderConnectionValidationResult`
3. 根据正式合同决定是否显示 API 模式、tool_choice、thinking 相关项

### 4.4 本轮不允许的演化方式

1. 不允许继续把新协议分支直接堆进旧 gateway 大文件。
2. 不允许先把 Gemini UI 打开，再慢慢补后端。
3. 不允许让 widget 自己猜当前 provider 是否支持 Responses。
4. 不允许为真实链路缺口新增 probe 私有判定。
5. 不允许把“连接校验”做成只在某个页面里弹提示的散逻辑。

---

## 5. 目标终态

本轮全部 session 完成后，目标终态应当是：

1. `OpenAI-compatible` 不再自动等于 `chat/completions only`。
2. `api_mode` 成为真实 route contract，而不是保存字段。
3. `Responses API` 有独立可运行链路，或在未支持处被严格隐藏。
4. `Anthropic` 的 payload / stream / tool block 语义从大 gateway 中拆出。
5. gateway 选择不再由 `AdapterBundle` 硬编码 if/else 控制。
6. provider / base URL / protocol / route family 之间存在统一连接合同与验证层。
7. UI 只显示当前 route contract 真正支持的高级项。
8. Gemini OpenAI-compatible 能按新合同接入。
9. Gemini native 能按独立 adapter 接入。
10. contract test、protocol test、UI 暴露 test、真实 provider probe 都消费 production 同源合同。

---

## 6. Session 数量与顺序设计理由

本轮共设计 `16` 个 session。

这样拆分的理由是：

1. 先把合同建正，再拆 runtime，再做 UI，再接 Gemini。
2. 把“Responses 真链路”放在 Gemini 之前，因为它是现有半接入字段的最主要收口点。
3. 把 provider connection validation 放在 UI 前，这样 UI 不需要自己兜错。
4. 把 `Gemini OpenAI-compatible` 和 `Gemini native` 分成两个 session，避免混成一坨。
5. 把 probe / regression 放在最后，让测试消费最终合同，而不是反过来设计业务中心。

顺序总原则：

1. core contract
2. adapter decouple
3. route truth
4. connection validation
5. UI exposure
6. Gemini rollout
7. regression / probes / docs

---

## 7. Session 列表总览

1. `APC-01` 协议与路由合同建模
2. `APC-02` provider connection contract 与 template 归一化
3. `APC-03` capability exposure 与 `api_mode` 真合同化
4. `APC-04` OpenAI Chat 链拆层
5. `APC-05` OpenAI Responses 真链路接入
6. `APC-06` Anthropic protocol adapter 拆层
7. `APC-07` gateway registry / factory resolver 替换 bundle 硬编码
8. `APC-08` runtime profile 与 offering / route 绑定收口
9. `APC-09` provider connection validation 接线
10. `APC-10` GUI 设置页与高级参数显隐重构
11. `APC-11` CLI / diagnostics / shared projection 最小接线
12. `APC-12` Gemini OpenAI-compatible 接入
13. `APC-13` Gemini native 接入
14. `APC-14` protocol contract test 与 stream test 矩阵
15. `APC-15` 真实 provider probe / regression 收口
16. `APC-16` 文档、迁移说明、遗留双轨清理

---

## 8. Session 详情

## Session APC-01：协议与路由合同建模

### 本轮目标

在 `core` 中建立真正的协议与路由合同，让后续所有实现不再依赖字符串散落判断。

### 层级归属

- Core / domain

### 必读文件

- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`
- `docs/provider-compatibility-baseline.md`
- `packages/novel_agent_core/lib/src/llm/profile/provider_protocol_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart`
- `agent.md`

### 必须完成

1. 新增正式合同：
   - `ProtocolKind`
   - `RequestRouteFamily`
   - `GatewayRouteResolution`
   - `ApiModeRouteMapping`
2. 明确 `chat`、`responses`、`messages`、`generate_content`、`embeddings` 等 route family 的标准表达。
3. 明确 `api_mode` 不再是任意字符串，而是 route family 的 UI 投影。
4. 给现有 `ProviderProtocolService` 接上新合同，而不是继续返回松散 map。
5. 补 focused unit tests，确保 route family 解析、默认值和枚举稳定。

### 本轮不要做

1. 不接 UI。
2. 不改 gateway。
3. 不加 Gemini。
4. 不补 provider catalog。

### 验收标准

1. `core` 中已经存在正式协议 / 路由合同类型。
2. `api_mode` 与 route family 的关系可被单测验证。
3. 后续 session 可以直接消费这些合同，而无需继续靠字符串常量。

### 直接可用提示词

```text
执行 Session APC-01，只做 API 兼容层的协议与路由合同建模。

必读：
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/provider-compatibility-baseline.md
- packages/novel_agent_core/lib/src/llm/profile/provider_protocol_service.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart
- agent.md

本轮只做：
1. 在 core 中建立 ProtocolKind、RequestRouteFamily、GatewayRouteResolution、ApiModeRouteMapping 等正式合同。
2. 让 api_mode 不再只是松散字符串，而是 route family 的稳定投影。
3. 补 focused unit tests。

本轮不要做：
- 不动 UI
- 不动 adapters gateway
- 不加 Gemini
- 不开启下一任务

要求：
- 单一职责
- 避免把合同继续写成散 map
- 不新增大文件巨石
- 测试覆盖 route family 映射与默认行为
```

---

## Session APC-02：provider connection contract 与 template 归一化

### 本轮目标

把 provider 模板层从“说明字段集合”升级为“连接合同层”的输入来源。

### 层级归属

- Core / domain

### 必读文件

- `packages/novel_agent_core/lib/src/llm/catalog/provider_interface_template_seed.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart`
- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`
- `docs/writing-model-registry-research-2026-05-30.md`

### 必须完成

1. 新增 `ProviderConnectionContract` 及相关解析服务。
2. 把 template 中已有的：
   - `protocol`
   - `default_base_url`
   - `base_url_hints`
   - `route_family`
   收进正式归一化对象。
3. 支持一个 template 对多个 allowed route family 的表达。
4. 为后续 Gemini 预留：
   - `gemini_native`
   - `openai_compatible via google`
   两类不同 template 形态。
5. 补 focused tests，覆盖：
   - 单路由模板
   - 多路由模板
   - mixed template
   - base URL 命中与默认值

### 本轮不要做

1. 不接网关。
2. 不接 UI。
3. 不做 provider connection validation 的最终用户提示。

### 验收标准

1. template 已能解析为正式 connection contract。
2. route family 不再只是备注字符串。
3. 后续 runtime / UI / validation 都能共享这份 contract。

### 直接可用提示词

```text
执行 Session APC-02，只做 provider connection contract 与 template 归一化。

必读：
- packages/novel_agent_core/lib/src/llm/catalog/provider_interface_template_seed.dart
- packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/writing-model-registry-research-2026-05-30.md

本轮只做：
1. 建立 ProviderConnectionContract。
2. 把 template 的 protocol/base_url/route_family 等字段归一化成正式合同。
3. 支持多 route family 模板。
4. 补 focused tests。

本轮不要做：
- 不改 gateway
- 不接 UI
- 不做最终 validation 提示
- 不开启下一任务

要求：
- 模板层只负责连接合同输入，不偷做运行时业务中心
- 不把 provider catalog 和 model facts 重新混在一起
```

---

## Session APC-03：capability exposure 与 `api_mode` 真合同化

### 本轮目标

建立统一 `CapabilityExposureView`，同时让 `api_mode` 真正跟 route family、协议支持和 offering 能力绑定。

### 层级归属

- Core / domain

### 必读文件

- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart`
- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`

### 必须完成

1. 新增 `CapabilityExposureView` 或等价正式视图合同。
2. 让 `ProviderModelMetadataService` 不再自己散推断，而是消费：
   - protocol contract
   - route contract
   - provider connection contract
   - model/offering capability
3. `api_mode` 必须只在“当前 connection contract 确实有多个已实现 route family”时才可见。
4. 若当前 route family 不支持某项参数，必须在 exposure view 中显式隐藏。
5. 补 focused tests：
   - OpenAI Chat only
   - OpenAI Chat + Responses
   - Anthropic Messages only
   - Gemini native 预留场景

### 本轮不要做

1. 不动 app widget。
2. 不实现 Responses gateway。
3. 不做真实 provider probe。

### 验收标准

1. `CapabilityExposureView` 已存在且可单测。
2. `api_mode` 显示条件已从散逻辑变为正式合同。
3. UI 后续只需消费这层结果。

### 直接可用提示词

```text
执行 Session APC-03，只做 capability exposure 与 api_mode 真合同化。

必读：
- packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md

本轮只做：
1. 建立 CapabilityExposureView。
2. 让 metadata / request options 改为消费正式协议、路由、connection contract。
3. 让 api_mode 的显示条件与 route family 真绑定。
4. 补 focused tests。

本轮不要做：
- 不动 UI widget
- 不实现 Responses transport
- 不开启下一任务

要求：
- 不把暴露逻辑重新散回 UI
- 不把 metadata 继续做成万能猜测器
```

---

## Session APC-04：OpenAI Chat 链拆层

### 本轮目标

把当前 `OpenAiLlmGateway` 从“多职责大网关”拆成可复用的协议组件。

### 层级归属

- Adapters / runtime

### 必读文件

- `packages/novel_agent_adapters/lib/src/providers/openai_llm_gateway.dart`
- `packages/novel_agent_adapters/lib/src/providers/openai_chat_request_payload_builder.dart`
- `packages/novel_agent_adapters/lib/src/providers/gateway_*`
- `agent.md`

### 必须完成

1. 抽出 OpenAI Chat 路由专用部件：
   - route resolver
   - payload mapper
   - stream parser / adapter
   - response parser
2. 保持现有 Chat Completions 主链行为不回退。
3. 让 `OpenAiLlmGateway` 自身瘦身为 transport + 组装层。
4. 补 focused tests：
   - chat payload 构造
   - chat route 选择
   - stream tool call delta 聚合

### 本轮不要做

1. 不实现 Responses。
2. 不改 UI。
3. 不接 Gemini。

### 验收标准

1. Chat Completions 主链行为保持通过。
2. 旧巨石 gateway 主要职责已拆开。
3. 后续 Responses 可复用 transport，不必继续塞进同一堆 if/else。

### 直接可用提示词

```text
执行 Session APC-04，只做 OpenAI Chat 链拆层。

必读：
- packages/novel_agent_adapters/lib/src/providers/openai_llm_gateway.dart
- packages/novel_agent_adapters/lib/src/providers/openai_chat_request_payload_builder.dart
- packages/novel_agent_adapters/lib/src/providers/gateway_*.dart
- agent.md

本轮只做：
1. 从 OpenAiLlmGateway 拆出 chat route resolver、payload mapper、stream parser、response parser。
2. 保持 Chat Completions 主链行为不回退。
3. 补 focused tests。

本轮不要做：
- 不做 Responses
- 不做 UI
- 不做 Gemini
- 不开启下一任务

要求：
- 优先小文件清职责
- 不把 transport 层和协议语义继续揉在一起
```

---

## Session APC-05：OpenAI Responses 真链路接入

### 本轮目标

把当前半接入的 `api_mode = responses` 收成真实可运行链路。

### 层级归属

- Adapters / runtime

### 必读文件

- `packages/novel_agent_adapters/lib/src/providers/openai_llm_gateway.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `docs/provider-compatibility-baseline.md`
- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`

### 必须完成

1. 新增 Responses route resolver / payload mapper / stream adapter。
2. 让 `api_mode` 真正驱动 Chat vs Responses route family。
3. 未支持 Responses 的 provider / route 必须明确隐藏或拒绝，而不是静默回退到 Chat。
4. 对 OpenAI 官方链路至少完成：
   - 非流式
   - 基本流式
   - 工具调用事件归一化
5. 补 focused tests 与至少一组 adapter integration test。

### 本轮不要做

1. 不改 app 页面。
2. 不加 Gemini。
3. 不做真实联网 probe。

### 验收标准

1. `api_mode = responses` 不再是假字段。
2. 不支持 Responses 的配置不会再被误暴露为可用。
3. OpenAI Chat 与 Responses 两条链可并存而不互相污染。

### 直接可用提示词

```text
执行 Session APC-05，只做 OpenAI Responses 真链路接入。

必读：
- packages/novel_agent_adapters/lib/src/providers/openai_llm_gateway.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart
- docs/provider-compatibility-baseline.md
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md

本轮只做：
1. 接入 Responses route/payload/stream adapter。
2. 让 api_mode 真正驱动路由。
3. 不支持 Responses 的场景必须隐藏或拒绝。
4. 补 focused tests 与集成测试。

本轮不要做：
- 不做 app UI
- 不做 Gemini
- 不做真实联网 probe
- 不开启下一任务

要求：
- Responses 不得伪装成 Chat
- 不得静默回退到 chat/completions
```

---

## Session APC-06：Anthropic protocol adapter 拆层

### 本轮目标

把 `AnthropicLlmGateway` 中的协议映射、stream 解析、回退策略拆开。

### 层级归属

- Adapters / runtime

### 必读文件

- `packages/novel_agent_adapters/lib/src/providers/anthropic_llm_gateway.dart`
- `docs/provider-compatibility-baseline.md`
- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`

### 必须完成

1. 抽出 `AnthropicMessagesPayloadMapper`。
2. 抽出 `AnthropicStreamContractAdapter`。
3. 抽出 tool_use / tool_result block mapper。
4. 把 retry / fallback policy 从协议映射逻辑中分离。
5. 补 focused tests：
   - system 与 messages 分离
   - tool_use / tool_result 映射
   - stream event 归一化

### 本轮不要做

1. 不改 UI。
2. 不加 Gemini。
3. 不做 provider 连接校验。

### 验收标准

1. Anthropic 主链仍可运行。
2. Anthropic 协议语义已从大 gateway 中抽离。
3. 未来若接其它 messages-like 协议，不需要复制整坨 gateway。

### 直接可用提示词

```text
执行 Session APC-06，只做 Anthropic protocol adapter 拆层。

必读：
- packages/novel_agent_adapters/lib/src/providers/anthropic_llm_gateway.dart
- docs/provider-compatibility-baseline.md
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md

本轮只做：
1. 拆出 Anthropic messages payload mapper。
2. 拆出 stream contract adapter。
3. 拆出 tool block 映射。
4. 分离 retry/fallback policy。
5. 补 focused tests。

本轮不要做：
- 不做 UI
- 不做 Gemini
- 不开启下一任务

要求：
- 协议映射与失败恢复要解耦
- 不再让 gateway 继续巨石化
```

---

## Session APC-07：gateway registry / factory resolver 替换 bundle 硬编码

### 本轮目标

去掉 `AdapterBundle.createGateway()` 的硬编码分叉，让新增协议类型不再改 composition root 条件分支。

### 层级归属

- Adapters / bootstrap

### 必读文件

- `packages/novel_agent_adapters/lib/src/bootstrap/adapter_bundle.dart`
- APC-04 / APC-05 / APC-06 的新部件
- `agent.md`

### 必须完成

1. 新增 `GatewayProtocolRegistry` 或等价对象。
2. 新增 `GatewayFactoryResolver`。
3. 新增 `ProviderRequestRouteResolver` 或等价运行入口。
4. 让 `AdapterBundle` 只装配，不再自己 if/else 决定网关。
5. 补 focused integration tests，验证：
   - OpenAI chat
   - OpenAI responses
   - Anthropic messages

### 本轮不要做

1. 不改 UI。
2. 不直接接 Gemini route。

### 验收标准

1. 新增协议类型时主要是注册，而不是改 bundle 分支。
2. 现有三条主链都仍可通过测试。

### 直接可用提示词

```text
执行 Session APC-07，只做 gateway registry / factory resolver 改造。

必读：
- packages/novel_agent_adapters/lib/src/bootstrap/adapter_bundle.dart
- 本主线前面已完成的 OpenAI/Anthropic adapter 拆层结果
- agent.md

本轮只做：
1. 引入 gateway registry / factory resolver / route resolver。
2. 让 AdapterBundle 只做装配。
3. 补 focused integration tests。

本轮不要做：
- 不做 UI
- 不直接接 Gemini
- 不开启下一任务

要求：
- 组合根只装配，不决策
- 不再新增新的协议 if/else 分叉点
```

---

## Session APC-08：runtime profile 与 offering / route 绑定收口

### 本轮目标

把 runtime profile 层真正收成“provider offering + connection contract + route contract + model capability”的统一归一化入口。

### 层级归属

- Core / domain

### 必读文件

- `packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart`
- `packages/novel_agent_core/lib/src/llm/catalog/builtin_writing_model_catalog_seed.dart`

### 必须完成

1. runtime profile 中明确记录：
   - resolved protocol kind
   - resolved route families
   - resolved selected route family
   - resolved provider connection contract id
   - matched offering / canonical model
2. provider / model / offering / route 的归一化逻辑集中化。
3. `ProviderRequestOptionsService` 改为消费统一 runtime route 结果，而不是靠字段拼凑。
4. 补 focused tests，覆盖：
   - OpenAI provider with chat+responses
   - Anthropic provider with messages
   - mixed template with single selected route

### 本轮不要做

1. 不接 widget。
2. 不做真实联网。

### 验收标准

1. runtime profile 已能稳定表达“当前到底要走哪条路”。
2. request options 不再单独猜 route。

### 直接可用提示词

```text
执行 Session APC-08，只做 runtime profile 与 offering/route 绑定收口。

必读：
- packages/novel_agent_core/lib/src/llm/profile/provider_runtime_profile_service.dart
- packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart
- packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart
- packages/novel_agent_core/lib/src/llm/catalog/builtin_writing_model_catalog_seed.dart

本轮只做：
1. 让 runtime profile 正式记录 resolved protocol / route / connection contract / offering。
2. 让 request options 消费统一 route 结果。
3. 补 focused tests。

本轮不要做：
- 不做 widget
- 不做真实联网
- 不开启下一任务

要求：
- offering / route / protocol 边界清楚
- 不把运行时决定再散回 metadata 或 UI
```

---

## Session APC-09：provider connection validation 接线

### 本轮目标

建立 provider / base URL / protocol / route family 的统一校验层。

### 层级归属

- Core / domain
- App / shared projection

### 必读文件

- APC-02 的 connection contract
- APC-08 的 runtime profile 结果
- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`

### 必须完成

1. 新增 `ProviderConnectionValidationResult` 或等价合同。
2. 校验三步：
   - template 匹配
   - protocol 一致性
   - route family 一致性
3. 支持输出：
   - error
   - warning
   - hide option
   - fallback not allowed
4. 把 validation 结果接到 shared view-data service，而不是 widget 手写判断。
5. 补 focused tests。

### 本轮不要做

1. 不大改页面布局。
2. 不接 Gemini runtime。

### 验收标准

1. 用户切到不支持的协议 / route 组合时，会被统一 validation 拦住。
2. UI 和 CLI 后续都能复用同一结果。

### 直接可用提示词

```text
执行 Session APC-09，只做 provider connection validation 接线。

必读：
- 本主线已有的 connection contract / runtime profile 结果
- apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart

本轮只做：
1. 建立 ProviderConnectionValidationResult。
2. 实现 template/protocol/route 三步校验。
3. 把结果接到 shared view-data service。
4. 补 focused tests。

本轮不要做：
- 不大改页面布局
- 不做 Gemini runtime
- 不开启下一任务

要求：
- validation 是共享合同，不是页面提示散逻辑
```

---

## Session APC-10：GUI 设置页与高级参数显隐重构

### 本轮目标

让设置页真正按 `CapabilityExposureView + ProviderConnectionValidationResult` 工作，不再直接读散字段猜。

### 层级归属

- App / GUI

### 必读文件

- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_advanced_panel.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/provider_detail_pane.dart`
- APC-03 / APC-09 输出合同

### 必须完成

1. `API 模式` 只在真实可切时显示。
2. `tool_choice`、`top_k`、`thinking_effort`、`stream` 等都按 exposure view 显隐。
3. 不支持的 route / protocol 组合给出自然但不啰嗦的反馈。
4. 页面不再直接持有协议判断细节。
5. 补 widget / view-model tests：
   - OpenAI chat+responses
   - Anthropic messages only
   - unsupported route hidden

### 本轮不要做

1. 不做大型 UI 视觉重设计。
2. 不实现新协议。

### 验收标准

1. 页面显示项与 runtime 真能力对齐。
2. 不再出现“能选但底层不支持”的明显假入口。

### 直接可用提示词

```text
执行 Session APC-10，只做 GUI 设置页与高级参数显隐重构。

必读：
- apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart
- apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_advanced_panel.dart
- apps/novel_agent_app/lib/features/settings/presentation/widgets/provider_detail_pane.dart
- 本主线已有的 CapabilityExposureView 与 ProviderConnectionValidationResult

本轮只做：
1. 让设置页按 exposure/validation 合同显示。
2. 收掉 API 模式等假入口。
3. 补 widget/view-model tests。

本轮不要做：
- 不做视觉大改
- 不新增协议
- 不开启下一任务

要求：
- UI 只消费稳定合同
- 不把协议判断塞回 widget
```

---

## Session APC-11：CLI / diagnostics / shared projection 最小接线

### 本轮目标

让 CLI 或共享诊断入口也能读到新的协议、route、validation、exposure 结果，避免 GUI 独占真相。

### 层级归属

- Core / shared projection
- CLI

### 必读文件

- `apps/novel_agent_cli/`
- `packages/novel_agent_core/lib/src/llm/profile/*`
- `agent.md`

### 必须完成

1. 提供最小共享 diagnostics 输出：
   - resolved protocol
   - allowed routes
   - selected route
   - validation warnings/errors
   - visible advanced fields
2. 如果 CLI 现有入口可复用，就挂进最小命令；若当前 CLI 不适合扩太多，就至少补共享 diagnostics service 与 focused tests。
3. 保证 diagnostics 不重复实现 GUI 逻辑。

### 本轮不要做

1. 不做 CLI 大规模功能扩展。
2. 不做真实 provider probe。

### 验收标准

1. 非 GUI 也能拿到同一套协议真相。
2. 不出现 GUI 一套、CLI 一套的平行判断。

### 直接可用提示词

```text
执行 Session APC-11，只做 CLI/diagnostics/shared projection 最小接线。

必读：
- apps/novel_agent_cli/
- packages/novel_agent_core/lib/src/llm/profile/
- agent.md

本轮只做：
1. 提供共享 diagnostics 输出 resolved protocol/route/validation/exposure。
2. 视当前结构决定挂最小 CLI 入口还是先补共享 service。
3. 补 focused tests。

本轮不要做：
- 不扩 CLI 大功能
- 不做真实 probe
- 不开启下一任务

要求：
- 诊断层消费 production truth
- 不再复制 GUI 私有判断
```

---

## Session APC-12：Gemini OpenAI-compatible 接入

### 本轮目标

先接 Gemini 的 OpenAI-compatible 路线，作为新合同下的第一条新增协议消费面。

### 层级归属

- Core
- Adapters
- App（最小暴露）

### 必读文件

- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`
- `docs/provider-compatibility-baseline.md`
- `docs/builtin-model-registry-analysis-2026-05-30.md`
- `packages/novel_agent_core/lib/src/llm/catalog/builtin_writing_model_catalog_seed.dart`

### 必须完成

1. 新增 Google OpenAI-compatible template / offering 入口。
2. 明确这条链是：
   - `provider_id = google`
   - `protocol = openai_compatible`
   - 但不是 `gemini_native`
3. 让已存在的 Gemini reasoning 参数事实，按 offering/route 合同正确投影到这条链。
4. 只有在 runtime 真闭环后，UI 才暴露对应可运行项。
5. 补 focused tests。

### 本轮不要做

1. 不做 Gemini native。
2. 不把所有 Gemini 特有能力都强行塞进 OpenAI-compatible。

### 验收标准

1. Gemini OpenAI-compatible 有真实闭环。
2. 不会与 Gemini native 混淆。

### 直接可用提示词

```text
执行 Session APC-12，只做 Gemini OpenAI-compatible 接入。

必读：
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/provider-compatibility-baseline.md
- docs/builtin-model-registry-analysis-2026-05-30.md
- packages/novel_agent_core/lib/src/llm/catalog/builtin_writing_model_catalog_seed.dart

本轮只做：
1. 接入 google 的 OpenAI-compatible template/offering/runtime 闭环。
2. 正确投影 Gemini 在这条链上的 reasoning 参数。
3. 只在闭环完成后暴露 UI。
4. 补 focused tests。

本轮不要做：
- 不做 Gemini native
- 不把所有 Gemini 特有能力硬塞进兼容层
- 不开启下一任务

要求：
- 明确区分 google openai-compatible 与 gemini native
```

---

## Session APC-13：Gemini native 接入

### 本轮目标

按独立 adapter 接入 Gemini native，验证新架构确实能承载非 OpenAI / 非 Anthropic 的第三种正式协议类型。

### 层级归属

- Core
- Adapters
- App（最小暴露）

### 必读文件

- APC-01 到 APC-12 结果
- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`
- `docs/provider-compatibility-baseline.md`

### 必须完成

1. 新增 `ProtocolKind.gemini_native`。
2. 新增 Gemini native template / connection contract / route family：
   - `generate_content`
   - `stream_generate_content`
3. 新增 Gemini native payload mapper / stream adapter。
4. 支持 Gemini native 的基础 reasoning 参数映射。
5. UI 只在 native 链闭环后展示。
6. 补 focused tests 与至少一组 adapter integration test。

### 本轮不要做

1. 不把 native 逻辑塞回 OpenAI gateway。
2. 不为了省事复用不匹配的 SSE parser。

### 验收标准

1. 项目第一次真正拥有三大协议主链：
   - OpenAI-compatible
   - Anthropic-compatible
   - Gemini-native
2. 结构上不需要再靠 bundle if/else 才能新增第四种。

### 直接可用提示词

```text
执行 Session APC-13，只做 Gemini native 接入。

必读：
- 本主线前序所有协议合同与 gateway registry 结果
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/provider-compatibility-baseline.md

本轮只做：
1. 新增 gemini_native protocol 与 route family。
2. 接入 Gemini native payload/stream/runtime 闭环。
3. 补 focused tests 与集成测试。

本轮不要做：
- 不把 native 逻辑塞回 OpenAI gateway
- 不偷用不匹配的 stream parser
- 不开启下一任务

要求：
- Gemini native 必须独立 adapter
- 不破坏前序三条已稳定主链
```

---

## Session APC-14：protocol contract test 与 stream test 矩阵

### 本轮目标

为新架构建立覆盖协议合同、route contract、payload mapper、stream parser 的系统测试矩阵。

### 层级归属

- Core tests
- Adapter tests

### 必读文件

- APC-01 到 APC-13 所有新增核心合同与 adapter
- `agent.md`

### 必须完成

1. 建立协议合同测试矩阵，至少覆盖：
   - OpenAI chat
   - OpenAI responses
   - Anthropic messages
   - Gemini openai-compatible
   - Gemini native
2. 建立 stream event 测试矩阵，至少覆盖：
   - text delta
   - reasoning delta
   - tool call delta
   - tool_use/tool_result
   - route terminal event
3. 建立 validation / exposure matrix tests。
4. 测试必须尽量消费 production contract，不得复制第二套私有逻辑。

### 本轮不要做

1. 不做真实联网。
2. 不新增业务功能。

### 验收标准

1. 协议差异被正式测试矩阵接住。
2. 后续再扩 provider 时能快速回归。

### 直接可用提示词

```text
执行 Session APC-14，只做 protocol contract test 与 stream test 矩阵。

必读：
- 本主线 APC-01 到 APC-13 的正式合同与 adapters
- agent.md

本轮只做：
1. 补协议合同、route、payload、stream、validation、exposure 的测试矩阵。
2. 测试消费 production truth。

本轮不要做：
- 不做真实联网
- 不新增功能
- 不开启下一任务

要求：
- 不复制第二套业务判断
- 测试命名与协议差异清晰
```

---

## Session APC-15：真实 provider probe / regression 收口

### 本轮目标

在 opt-in 条件下，对关键 provider 做高信号真实回归，验证新合同不是纸上正确。

### 层级归属

- Probe / regression
- Shared runtime diagnostics

### 必读文件

- `agent.md`
- 本主线 APC-01 到 APC-14 成果
- 现有真实 provider probe 入口

### 必须完成

1. 用现有共享 probe 框架，而不是新开一堆散脚本。
2. 至少覆盖：
   - OpenAI Chat
   - OpenAI Responses
   - Anthropic Messages
   - Gemini OpenAI-compatible
   - Gemini native（若本地 provider/key 可用）
3. probe 报告要明确区分：
   - 技术失败
   - 配置不支持
   - 权限/预算限制
   - 内容质量问题
4. probe 必须使用 production 的 route / exposure / validation 合同，不得旁路。

### 本轮不要做

1. 不把 probe 变成新的 runtime。
2. 不硬编码个人 key 或本地路径。

### 验收标准

1. 关键链路至少有一轮真实跑通或有明确失败分类。
2. probe 与 production 合同同源。

### 直接可用提示词

```text
执行 Session APC-15，只做真实 provider probe / regression 收口。

必读：
- agent.md
- 本主线 APC-01 到 APC-14 结果
- 现有真实 provider probe 入口

本轮只做：
1. 复用共享 probe 框架做关键 provider 回归。
2. 输出技术失败/配置不支持/预算限制/内容质量问题的分类报告。
3. 保证 probe 消费 production route/validation/exposure 合同。

本轮不要做：
- 不新增散 probe 脚本
- 不硬编码个人 key
- 不开启下一任务

要求：
- probe 不是第二套 runtime
- 报告区分失败类型
```

---

## Session APC-16：文档、迁移说明、遗留双轨清理

### 本轮目标

把这条主线最后收口为可维护状态，清理遗留双轨与过时文档表述。

### 层级归属

- Documentation / handoff
- Repo hygiene

### 必读文件

- `docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md`
- 本顺序文档
- `docs/provider-compatibility-baseline.md`
- `agent.md`

### 必须完成

1. 更新文档，明确：
   - 哪些协议主链已完成
   - 哪些 UI 选项是真实闭环
   - Gemini OpenAI-compatible 与 native 的区别
2. 清理已被正式合同替代的旧散字段或注释。
3. 移除明显过时的“Responses 已支持”假表述。
4. 若仍有临时 bridge，文档中明确主链 / 兼容层 / 计划移除点。

### 本轮不要做

1. 不新增新功能。
2. 不再大改架构。

### 验收标准

1. 文档与实现现状一致。
2. 遗留双轨被明显收束。

### 直接可用提示词

```text
执行 Session APC-16，只做文档、迁移说明、遗留双轨清理。

必读：
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/important/api-compatibility-layer-session-order-2026-06-17.md
- docs/provider-compatibility-baseline.md
- agent.md

本轮只做：
1. 更新相关文档与迁移说明。
2. 清理已被正式合同替代的旧表述和明显双轨残留。

本轮不要做：
- 不新增功能
- 不再大改架构
- 不开启下一任务

要求：
- 文档诚实反映实现
- 明确主链与兼容层边界
```

---

## 9. 总启动提示词

下面这段提示词用于给 `gpt-5.4-mini` 的目标模式启动整条主线。

```text
你现在执行 `docs/important/api-compatibility-layer-session-order-2026-06-17.md` 这份任务顺序文档。

先完整阅读：
- docs/important/api-compatibility-layer-session-order-2026-06-17.md
- docs/important/api-compatibility-layer-architecture-analysis-2026-06-17.md
- docs/provider-compatibility-baseline.md
- docs/builtin-model-registry-analysis-2026-05-30.md
- docs/writing-model-registry-research-2026-05-30.md
- agent.md

执行规则：

1. 严格按 session 顺序执行，从 `APC-01` 开始。
2. 一次只做一个 session。
3. 每完成一个 session：
   - 先自测
   - 再更新完成记录
   - 再进入下一个 session
4. 如果发现当前 session 与其他正在进行中的改动冲突：
   - 先判断是否能在不碰脏文件的前提下继续
   - 若不能安全继续，明确报告阻塞文件与阻塞原因
   - 不要硬改并行脏区
5. 不允许跳过 core contract 直接补 UI。
6. 不允许把 fallback、probe、bridge 变成新的业务中心。
7. 不允许把新增协议继续塞回旧 gateway 巨石文件。
8. 每轮都要遵守：
   - 单一职责
   - 文件不过重
   - UI 只消费稳定合同
   - focused test / contract test 优先
9. 没完成当前 session 前，不要提前做下一任务。
10. 若某 session 已部分实现，先做去重审计，再补缺口，不要复制第二套实现。

最终目标：

让项目的 API 兼容层从“能跑的协议入口集合”，收口成“协议合同系统”，并按新合同完成：
- OpenAI Chat
- OpenAI Responses
- Anthropic Messages
- Gemini OpenAI-compatible
- Gemini native

开始执行 `APC-01`。
```

---

## 10. 完成记录占位

- [x] APC-01 协议与路由合同建模
- [x] APC-02 provider connection contract 与 template 归一化
- [x] APC-03 capability exposure 与 `api_mode` 真合同化
- [x] APC-04 OpenAI Chat 链拆层
- [x] APC-05 OpenAI Responses 真链路接入
- [x] APC-06 Anthropic protocol adapter 拆层
- [x] APC-07 gateway registry / factory resolver 替换 bundle 硬编码
- [x] APC-08 runtime profile 与 offering / route 绑定收口
- [x] APC-09 provider connection validation 接线
- [x] APC-10 GUI 设置页与高级参数显隐重构
- [x] APC-11 CLI / diagnostics / shared projection 最小接线
- [x] APC-12 Gemini OpenAI-compatible 接入
- [x] APC-13 Gemini native 接入
- [x] APC-14 protocol contract test 与 stream test 矩阵
- [x] APC-15 真实 provider probe / regression 收口
- [x] APC-16 文档、迁移说明、遗留双轨清理

---

## 11. 最后自检结论

这份顺序文档已经按本项目约束完成了以下收口：

1. 先合同、再 adapter、再 validation、再 UI、再 Gemini、再 probe。
2. 没把 GUI 提前抬成补底层的地方。
3. 没把 Gemini 直接放到最前面硬接。
4. 没把 Responses 继续作为“以后再说”的半接入字段保留。
5. 每个 session 都有：
   - 本轮目标
   - 层级归属
   - 必读文件
   - 必须完成
   - 本轮不要做
   - 验收标准
   - 可直接执行提示词

如果后续再补新的兼容类型，这份文档也可以作为同类主线的模板继续扩展，而不用重新发明顺序。
