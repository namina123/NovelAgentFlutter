# NovelAgentFlutter 写作模型整合与深度思考参数顺序文档

最后更新：2026-05-30

关联文档：

- `docs/builtin-model-registry-analysis-2026-05-30.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`
- `docs/agent-group-opening-redesign-session-order.md`
- `docs/agent-ecosystem-entry-density-session-order-2026-05-29.md`
- `agent.md`

---

## 1. 这份文档解决什么

这一轮不做“大而全模型平台”，而是先把真正影响写作工作流的模型整合链做对。

这条链只围绕 4 件事：

1. **整合截至当前时间点前的内置模型列表**
   - 不是只保留最新
   - 也不是只保留旧兼容项
   - 而是保留“当前仍有意义的写作相关模型谱系”
2. **把模型提示和用户心智对齐**
   - 用户不需要理解 provider 协议细节
   - 用户只需要知道：
     - 这个模型能不能开深度思考
     - 开了之后大概怎么工作
     - 可调哪些常用参数
3. **把内置模型参数收束成“少而准”**
   - 对写作 agent 而言，默认只重点暴露：
     - `temperature`
     - `top_p`
   - 以及最重要的：
     - `深度思考` 开关
     - `深度思考强度`
4. **让自定义模型配置既省心又全面**
   - 如果用户填的是已有模型列表中的模型
     - 默认继承官方/内置参数格式与能力
   - 如果不是
     - 允许用户走自定义高级设置完全兜底

这份文档的目标不是“模型目录学术完美”，而是：

**让写作场景下的模型选择和深度思考设置足够精细、足够好用、又不把用户拖进 provider 细节泥潭。**

但这里有一条更高优先级约束：

**这次模型整合必须整合进历史既有设计，而不是替换掉它们。**

也就是说，后续实现不能出现：

1. 模型系统做完了，但 group-first 被弱化
2. 模型系统做完了，但表达限制系统被重新吞进模型参数
3. 模型系统做完了，但工作台又长出新的“调参后台”
4. 模型系统做完了，但之前强调的低心智负担、复用性、单一职责反而消失

---

## 1.1 这条链必须继承的历史目的

结合你之前多轮需求，这条链必须继续服务以下目的，而不是重开一条平行产品线：

1. **group-first 仍然是协作主规则**
   - 当前项目默认只选择一个智能体组
   - 当前主智能体由组派生
   - 模型能力只是输入能力条件之一，不能反向把产品重心改回“单智能体 + 单模型”中心
2. **模型属于输入能力层，不属于新的产品主域**
   - 模型、深度思考、发送能力都属于输入区/设置区的能力链
   - 不能抢走智能体组、表达限制、长任务、工作台这些更高层对象的职责
3. **表达限制系统必须保持独立**
   - `de_ai` 只是首个内置实现
   - 不能因为这轮做模型整合，就把“去 AI / 自然表达 / 真实性约束”重新塞回模型参数系统
4. **默认低心智负担优先**
   - 命中已知模型时尽量自动
   - 默认只暴露少量高价值项
   - 不让用户为了写作先理解 provider 协议
5. **复用优先**
   - settings
   - workbench 输入能力投影
   - CLI
   - 后续热更新
   都应复用同一份模型事实与能力层，而不是各自维护一份

---

## 2. 本轮冻结的产品边界

### 2.1 默认只暴露少量高价值参数

对写作场景，默认正式暴露的基础参数只有：

1. `temperature`
2. `top_p`
3. `深度思考开关`
4. `深度思考强度`（仅当当前模型/offering 支持）

不在默认主界面继续扩散：

- `top_k`
- 各种 provider 私有高级参数
- 大量 JSON 参数

这些高级项如果有，统一进高级设置。

### 2.2 深度思考是核心，不支持就不给入口

规则冻结如下：

1. 当前模型 / offering 不支持深度思考：
   - 不显示深度思考按钮
2. 当前模型只支持思考，不支持关闭：
   - 不显示普通开关
   - 只显示“已启用深度思考”的只读说明，必要时显示强度
3. 当前模型支持思考且可切换：
   - 显示开关
4. 当前模型支持强度调节：
   - 再显示强度选择

### 2.3 内置模型优先走官方已知格式

如果当前模型命中内置模型列表：

1. 直接使用内置模型能力定义
2. 自动继承：
   - 是否支持深度思考
   - 开关参数格式
   - 强度参数格式
   - 哪些强度值可用
   - 是否有 provider/offering override

用户无需自己填协议细节。

### 2.4 自定义模型允许完全兜底

如果用户添加的是自定义模型，且没有命中内置模型列表：

默认行为：

1. 基础模式只要求用户填：
   - provider
   - model id
   - base url / credential
2. 高级模式允许用户手动配置：
   - 是否支持深度思考
   - 深度思考开关参数
   - 深度思考强度参数
   - 是否支持强度调节
   - 各种强度分别传什么值

也就是说：

- 命中内置模型时，尽量自动
- 未命中时，给完整兜底能力

### 2.5 聚合/中转可以覆盖原厂思考参数

这条必须写成硬约束：

1. 原厂模型的 canonical thinking 策略只是默认值
2. 某个 provider offering 可以覆盖它

例如：

- 原厂 DeepSeek 可能是 `thinking`
- SiliconFlow 上某 offering 可能改成 `enable_thinking`
- 百炼上某 offering 可能又是 `enable_thinking` 或 `reasoning.effort`

所以实现必须以：

- `canonical model strategy`
- `provider offering override`

两层合并结果为准。

### 2.6 不能破坏既有 capability projection 与 group-first 规则

这轮必须继续兼容你之前已经明确做对的能力链：

1. 模型支持深度思考
2. 当前主智能体是否允许思考
3. 当前运行态是否应该显示这个入口

因此必须坚持：

- 模型事实层负责“模型 / offering 是否支持”
- group-first / 当前主智能体规则继续负责“当前会话是否允许”
- 最终仍由统一 capability projection 给 UI

不能为了模型整合，重新把显隐判断散回：

- widget if/else
- 单页本地状态
- 新的临时 view model 分支

### 2.7 不能把表达限制系统吞进模型设置

历史上已经明确：

- 表达限制是项目级约束系统
- `de_ai` 只是其中一个内置实现
- 它不是技能，也不是模型参数本身

所以这轮边界固定如下：

1. 模型整合只负责：
   - 模型能力
   - 深度思考参数
   - 少量采样参数
2. 表达限制继续独立
3. 即便未来某些模型与某些表达限制有联动，也应通过上层策略或能力联动接入，而不是把表达限制塞进模型表单

---

## 3. 本轮不做什么

为了把任务控制在可落地范围，这轮明确不做：

1. 不做完整远程热更新实现
2. 不做所有 provider 动态模型发现
3. 不做全平台所有模型模态 UI
4. 不把设置页改成“参数实验室”
5. 不把写作场景默认界面暴露成一大片高级协议参数

这轮先做：

- 数据合同
- 内置模型整合
- 思考能力接线
- 自定义模型兜底

---

## 4. 实现原则

### 4.1 先服务写作场景

这条链优先服务写作 agent，不追求一次把所有参数都变成平台型产品。

判断顺序固定为：

1. 写作时用户最常需要调什么
2. 什么能力最影响体验
3. 哪些参数可以自动化
4. 剩下的再放高级设置

### 4.2 事实层和表单层分离

必须拆开：

1. 模型事实层
2. offering 覆盖层
3. 表单投影层
4. 请求参数生成层

不能让设置页直接承担协议推断。

### 4.3 自定义模型不能反向污染内置事实层

自定义模型高级设置是兜底，不是新的事实源中心。

也就是说：

- 内置模型事实层稳定存在
- 自定义模型只是在未命中时补一层本地 override

### 4.4 先做“易更新结构”，后做“热更新实现”

这轮先把数据结构设计成易更新：

- 内置 seed 可拆分
- 条目字段可扩展
- offering override 正式存在
- 自定义 override 正式存在

这样下一轮再接热更新就不需要推翻重来。

### 4.5 复用已有链路，不另造第二套判断中心

这轮不允许新造一条平行能力判断链。

必须优先复用或重构已有：

- `ModelExecutionProfileService`
- `ProviderModelMetadataService`
- workbench 输入 capability projection
- settings view data projection

如果现有实现不够，就下沉公共层；不要出现：

- 设置页自己猜一套
- 工作台自己猜一套
- CLI 再复制一套

### 4.6 这是写作系统的一部分，不是调参后台

这条链最终服务的是：

- 写作工作台
- 智能体协作
- 项目级表达限制
- 长任务与开局

所以必须避免：

1. 把设置页做成 provider 调试台
2. 把模型系统做成比工作台本体还重的中心页面
3. 让模型参数系统喧宾夺主，压过项目、智能体组、表达限制这些更高层对象

---

## 5. 需要覆盖的模型范围

这一轮的内置模型列表应以“写作相关、当前时间点前已知且仍有意义”为准，重点覆盖：

### 5.1 原厂 / 模型方

- OpenAI
- Anthropic
- Gemini
- DeepSeek
- Qwen
- GLM / Z.AI
- Kimi / Moonshot
- MiniMax
- MiMo / Xiaomi
- Doubao / 火山方舟

### 5.2 聚合 / 中转 / 托管

- SiliconFlow
- 百炼 / Bailian / DashScope / Model Studio
- NVIDIA NIM / API Catalog
- OpenCode Zen
- OpenCode Go

### 5.3 只纳入“写作相关 offering”

先不追求把所有图像、音频、embedding、GUI agent 模型全量开放到默认写作设置页。

本轮默认主列表以：

- 通用文本生成
- 长上下文写作
- 思考/非思考写作

为主。

多模态与其他模态能力先允许在数据层保留字段，但不作为主 UI 首要任务。

---

## 6. 建议正式数据合同

这轮不需要把上一份分析文档里的大合同一次全部实现，但至少要把下面几块定下来。

### 6.1 `BuiltinWritingModelDescriptor`

建议字段：

- `canonicalModelId`
- `vendorId`
- `vendorLabel`
- `family`
- `snapshot`
- `displayName`
- `aliases`
- `providerOfferings`
- `supportsTemperature`
- `supportsTopP`
- `reasoning`
- `status`
- `notes`

### 6.2 `WritingModelReasoningDescriptor`

建议字段：

- `supported`
- `modeBehavior`
  - `unsupported`
  - `thinking_only`
  - `hybrid_optional`
  - `hybrid_default_on`
  - `thinking_required_not_disableable`
- `canToggle`
- `defaultEnabled`
- `supportsEffort`
- `effortOptions`
- `defaultEffort`
- `toggleParameterStrategy`
- `effortParameterStrategy`

### 6.3 `ProviderOfferingOverride`

建议字段：

- `providerId`
- `providerLabel`
- `providerModelId`
- `baseUrlHint`
- `reasoningOverride`
- `supportedParametersOverride`
- `notes`

### 6.4 `CustomModelAdvancedReasoningSettings`

这是给用户手动兜底的关键合同。

建议字段：

- `supportsReasoning`
- `toggleParameterKind`
  - `none`
  - `boolean`
  - `object`
  - `custom_text`
- `toggleParameterKey`
- `toggleEnabledValue`
- `toggleDisabledValue`
- `supportsEffort`
- `effortParameterKey`
- `effortValues`
  - `low`
  - `medium`
  - `high`
  - `max`
  - `xhigh`
- `notes`

### 6.5 `EffectiveWritingModelSettings`

这是最终给 UI 和请求层消费的结果。

建议字段：

- `effectiveModelId`
- `effectiveDisplayName`
- `supportsTemperature`
- `supportsTopP`
- `showReasoningToggle`
- `reasoningToggleEditable`
- `reasoningEnabled`
- `showReasoningEffort`
- `reasoningEffortOptions`
- `effectiveToggleStrategy`
- `effectiveEffortStrategy`

### 6.6 与既有会话能力上下文的兼容要求

虽然本轮不一定新建一个全新 context 类型，但最终输出必须能与既有会话能力链兼容：

- 模型支持 ≠ 当前可显示
- offering 支持 ≠ 当前必须显示

至少要能与这些事实继续合并：

- 当前主智能体是否允许思考
- 当前会话是否处于发送/停止运行态
- 当前入口是公开动作还是内部能力

这样后续不会把历史已经整理好的 capability projection 打碎。

---

## 7. Session 列表

这条链不需要很多 session，控制在 5 个以内。

---

## 7.1 Session WM-01：建立写作模型事实合同与首批内置列表

### 本轮目标

先把“写作模型整合”正式建模，但不改设置 UI。

### 必读文件

- `docs/builtin-model-registry-analysis-2026-05-30.md`
- `packages/novel_agent_core/lib/src/llm/catalog/provider_model_catalog_seed.dart`
- `packages/novel_agent_core/lib/src/llm/capabilities/provider_model_capabilities_seed.dart`

### 必须完成

1. 新建更聚焦写作场景的模型事实合同
2. 建立首批内置写作模型列表，覆盖：
   - OpenAI
   - Anthropic
   - Gemini
   - DeepSeek
   - Qwen
   - GLM
   - Kimi
   - MiniMax
   - MiMo
   - Doubao
3. provider/offering override 先只做结构和首批关键样例：
   - SiliconFlow
   - 百炼
   - OpenCode Go / Zen
4. 明确这层事实源后续要同时服务：
   - settings
   - workbench 输入 capability
   - CLI
   - 后续表达限制/智能体能力联动
5. 先不改旧 UI

### 本轮不要做

- 不改设置页表单
- 不改工作台输入区
- 不做热更新实现

### 完成判定

- core 中已有正式“写作模型事实层”
- 不再只能依赖旧的散 seed + thinking format 推断

### 直接可用提示词

```text
按 docs/writing-model-registry-session-order-2026-05-30.md 的 Session WM-01 执行。只建立写作模型事实合同与首批内置列表，覆盖 OpenAI、Anthropic、Gemini、DeepSeek、Qwen、GLM、Kimi、MiniMax、MiMo、Doubao，并加入 SiliconFlow、百炼、OpenCode Go/Zen 的 offering override 结构。不要改 UI，不开启下一任务。
```

---

## 7.2 Session WM-02：接通深度思考能力投影与 provider offering override

### 本轮目标

让系统真正能根据“模型 + offering”判断深度思考入口是否应该出现。

### 必读文件

- `packages/novel_agent_core/lib/src/llm/profile/provider_model_metadata_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_thinking_parameter_service.dart`
- `packages/novel_agent_core/lib/src/settings/model_execution_profile_service.dart`

### 必须完成

1. 把 `supports_reasoning` 升级为正式 reasoning capability projection
2. 让 projection 能区分：
   - 不支持
   - 仅思考
   - 可选思考
   - 默认开启
3. offering override 生效：
   - 例如原厂 DeepSeek 与 SiliconFlow/百炼不同 thinking 参数格式
4. 给 workbench / settings 提供统一的 effective capability 输出
5. 保证这条输出链仍可与 group-first / 当前主智能体能力限制合并，而不是覆盖它

### 本轮不要做

- 不做自定义模型高级表单
- 不改温度 / top_p UI

### 完成判定

- 不支持思考的模型不会再误显示思考入口
- 仅思考模型不会再显示错误的关闭开关

### 直接可用提示词

```text
按 docs/writing-model-registry-session-order-2026-05-30.md 的 Session WM-02 执行。只接通深度思考能力投影与 provider offering override，让系统能按模型+offering正确判断是否显示深度思考开关、是否允许关闭、是否支持强度。不要做自定义模型高级表单，不开启下一任务。
```

---

## 7.3 Session WM-03：收束设置页默认参数，只保留写作高价值项

### 本轮目标

把设置页默认模型参数收束成“少而准”的写作表单。

### 必读文件

- `apps/novel_agent_app/lib/features/settings/application/services/model_settings_view_data_service.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/models/model_editor_view_data.dart`
- `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_panel.dart`

### 必须完成

1. 默认设置页主区域只突出：
   - `temperature`
   - `top_p`
   - `深度思考开关`
   - `深度思考强度`
2. 只有当前模型支持时才显示对应项
3. 非主路径参数降到高级设置
4. 文案要更像写作工作流，而不是 provider 调试器
5. 不让默认设置页承担表达限制、去 AI、真实性约束等上层语义

### 本轮不要做

- 不改自定义模型高级协议兜底
- 不开热更新

### 完成判定

- 用户默认不再看到一堆协议参数
- 写作相关主参数一眼可懂

### 直接可用提示词

```text
按 docs/writing-model-registry-session-order-2026-05-30.md 的 Session WM-03 执行。只收束设置页默认模型参数，主区域只突出 temperature、top_p、深度思考开关和深度思考强度，并按当前模型能力动态显示。不要做自定义模型高级协议兜底，不开启下一任务。
```

---

## 7.4 Session WM-04：实现自定义模型高级兜底

### 本轮目标

让未命中内置模型列表的自定义模型也能完整配置深度思考协议。

### 必读文件

- `apps/novel_agent_app/lib/features/settings/presentation/widgets/model_settings_panel.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_request_options_service.dart`
- `packages/novel_agent_core/lib/src/llm/profile/provider_thinking_parameter_service.dart`

### 必须完成

1. 自定义模型若命中内置列表：
   - 默认继承官方/内置参数格式
2. 若未命中：
   - 允许用户进入高级设置
   - 手动配置：
     - 是否支持深度思考
     - 开关参数怎么传
     - 是否支持强度
     - 各强度分别传什么值
3. 请求参数生成层读取这套自定义 override
4. 自定义 override 不能反向污染内置模型事实层，只能挂在用户配置层

### 本轮不要做

- 不做远程热更新
- 不改工作台主 UI

### 完成判定

- 未命中内置模型时，用户不再被锁死
- 已命中内置模型时，用户默认不需要自己理解协议

### 直接可用提示词

```text
按 docs/writing-model-registry-session-order-2026-05-30.md 的 Session WM-04 执行。只实现自定义模型高级兜底：命中内置模型时自动继承参数格式，未命中时允许用户手动配置是否支持深度思考、开关参数、强度参数及各强度传值。不要做热更新，不开启下一任务。
```

---

## 7.5 Session WM-05：补全测试与为热更新预留 manifest 入口

### 本轮目标

这轮先不做真正热更新，但必须把后续热更新入口留好。

### 必读文件

- `packages/novel_agent_core/test/provider_model_metadata_service_test.dart`
- `packages/novel_agent_core/test/model_execution_profile_service_test.dart`
- `packages/novel_agent_core/test/provider_request_options_service_test.dart`

### 必须完成

1. 补全：
   - 内置模型命中测试
   - offering override 测试
   - 深度思考显隐测试
   - 仅思考模型测试
   - 自定义模型高级 override 测试
2. 给目录层增加 manifest 入口结构
   - 可以先是本地接口 / 协议
   - 不必真的联网更新
3. 保证后续热更新不需要推翻本轮结构
4. 验证 settings / workbench / capability projection 仍共享同一事实源

### 本轮不要做

- 不做远程拉取
- 不做缓存策略

### 完成判定

- 结构上已经为热更新留口
- 本轮模型整合链有 focused test 兜底

### 直接可用提示词

```text
按 docs/writing-model-registry-session-order-2026-05-30.md 的 Session WM-05 执行。只补全写作模型整合链的 focused test，并为后续热更新预留 manifest 入口结构，但不实现真正远程更新。不要改工作台主 UI，不开启下一任务。
```

---

## 8. 建议推进方式

后续建议统一用下面这段话推进：

```text
根据目前的进度和文档：docs/writing-model-registry-session-order-2026-05-30.md继续下一步，每次只确认完成一个具体的任务，如果上个会话末尾卡在具体任务的一半未完成或者出现了关联性错误，那么就先把这些做好，不需要开启下一轮任务；如果已经确认可以开启下一轮任务，那么可以直接开始。注意解耦合、单一职责、优先服务写作场景，默认只暴露 temperature、top_p 与深度思考相关项，高级协议参数放到兜底设置里。开始吧。
```

---

## 9. 最后一句定义

这条链最终不是为了做一个“模型参数大全”，而是为了：

**把写作 agent 真正常用的模型选择、深度思考能力和参数协议收束成一套省心、准确、可扩展，并且不破坏既有 group-first、表达限制与工作台职责边界的正式系统。**
