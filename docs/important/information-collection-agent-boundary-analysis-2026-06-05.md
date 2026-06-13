# 信息收集决策边界与智能体约束分析

日期：2026-06-05

关联文档：

- `agent.md`
- `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
- `docs/project-information-substrate-session-order-2026-06-05.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`

关联实现锚点：

- `packages/novel_agent_core/lib/src/information/information_collection_request.dart`
- `packages/novel_agent_core/lib/src/information/information_collection_policy_service.dart`
- `packages/novel_agent_core/lib/src/information/information_source_quality_service.dart`
- `packages/novel_agent_core/lib/src/tools/domain/request_external_research_handler.dart`
- `packages/novel_agent_core/lib/src/workflow/writing_execution_constraint_bridge_service.dart`
- `packages/novel_agent_core/lib/src/workflow/chapter_length_profile.dart`
- `packages/novel_agent_core/lib/src/creative/expression_constraint_profile.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_research_gateway_service.dart`
- `packages/novel_agent_adapters/lib/src/tools/project_information_import_collection_service.dart`

---

## 1. 本文解决什么

这几轮讨论集中在一个核心问题：

```text
信息收集到底应当是平台限制、智能体原文、人设提示，还是普通工具能力？
```

最终结论是：

```text
信息收集不是项目类型固定流程，也不是某个智能体人设里的可选习惯。
它应当是平台级证据纪律 + 工具使用准则 + 智能体专业风格三层协作。
```

原因很简单：用户可以下载智能体、AI 可以生成智能体、项目也可以切换智能体组。如果“什么时候该收集信息、什么时候不能假装知道”只写在某个智能体原文里，新智能体很容易漏掉，系统也无法保证所有项目类型行为一致。

---

## 2. 前几轮讨论的关键结论

### 2.1 信息收集应覆盖所有项目类型

信息收集不是长任务专属，也不是拆书专属。

它适用于：

1. 一般小说项目。
2. 长篇/长任务项目。
3. 拆书项目。
4. 拆书续写项目。
5. 解书、总结、小说解说、评书式转述等分析类项目。
6. 未来同人、穿书、跨作品引用、资料型创作等项目。

区别只在于“是否需要”和“需要什么来源”，不在于项目类型。

### 2.2 不是所有项目都需要信息收集

不能把信息收集做成项目创建后的固定流程。

完全原创、设定明确、用户已经给足资料、没有现实事实依赖的项目，可以不收集或只保留用户输入。

例如：

1. 用户要写完全架空的幻想小说，所有规则都由用户设定。
2. 用户只想写一段原创情绪流短篇。
3. 当前章节只推进角色互动，不依赖外部客观资料。

这时强行联网或导入资料会增加噪音、拖慢流程、破坏创作手感。

### 2.3 但不能假装已经知道

反过来，只要智能体开始依赖外部客观信息，就不能靠猜测写很久才回头补查。

典型触发点：

1. 历史制度、年代、地名、科学、医学、法律、技术等客观事实。
2. 神话、宗教、旧典、星象、八卦、民俗、古籍、真实文化系统。
3. 现实作品、同人边界、穿书、跨作品引用。
4. 拆书时发现原作明显借用了外部资料体系，例如角色称号、名字、组织结构、仪式、神话隐喻。
5. 长任务中某个设定会持续影响后续几十章或更多章节。

这种情况下，正确行为是先判断信息缺口，再选择：

1. 项目已有资料足够：读取/导入并提取。
2. 需要外部客观资料：请求联网研究。
3. 只是创作灵感而非事实：标为设计元素或 AI 推断，不冒充事实。
4. 不确定是否值得研究：保留 uncertainty 或请求用户确认。

### 2.4 拆书项目也需要“合适的收集”

拆书不是只抽原文。

如果原书内部有明显外部参照，例如：

1. 人物名字冠以神话体系。
2. 称号来自旧典、宗教、民俗或历史制度。
3. 世界设定参考古籍、星象、八卦、北欧神话、佛道体系等。
4. 章节结构暗合某种外部文本、仪式或叙事传统。

那么拆书智能体应当能提出研究请求或导入资料请求，让这些信息成为可追踪 research note / design element / knowledge card。

但如果原作是纯内部原创设定，则优先从原文证据中抽取，不应乱联网寻找不存在的外部解释。

---

## 3. 最终判断：这部分应当如何分层

### 3.1 平台级限制：必须有

平台级限制负责最低证据纪律，所有智能体都必须遵守。

它应表达：

1. 不能把未验证的外部事实伪装成已验证事实。
2. 不能在依赖客观信息时长期凭空编写。
3. 不能把 research note、knowledge card、design element 混成普通 Markdown。
4. 不得把题材示例写死成程序分支。
5. 不得让模型自声明的 `user_granted_network_access` 取代宿主权限。

这层不决定具体文风，也不决定某章写得快慢，只约束“证据和权限边界”。

### 3.2 工具使用准则：必须有

工具准则负责告诉所有智能体：

1. 什么时候用 `request_external_research`。
2. 什么时候用导入收集。
3. 什么时候提交 `submit_research_note`。
4. 什么时候提升为 `propose_knowledge_card`。
5. 什么时候只是作品巧思，应提交 `propose_design_element`。
6. 什么时候只需 `link_information_evidence`。

这层应进入统一 prompt contract / tool guidance，而不是散落在某个智能体原文里。

### 3.3 智能体原文：可以增强，但不能承担底线

智能体原文可以写：

1. 研究型智能体更敏感于来源和引用。
2. 拆书智能体更敏感于原作巧思和符号系统。
3. 审稿智能体更敏感于事实缺口和证据不足。
4. 写作智能体更重视创作节奏，避免过度研究。

但这些只是风格和专业偏好。

不能把底线规则只放在智能体原文里。否则新下载智能体、AI 生成智能体、用户自定义智能体可能完全不知道信息收集纪律。

---

## 4. 与现有限制/约束层的关系

用户这次迷茫的根源是合理的：项目里已经存在一些“限制/约束”实现，例如去 AI、表达限制、字数策略、章节交付 gate。信息收集看起来也像一种“限制”，但它不能简单塞进表达限制或字数限制那条链。

更准确的分层应当是：

```text
用户可见规则资产
  -> 表达限制、去 AI、自定义写法规则、项目级规则绑定

内部执行 gate
  -> 字数偏离、表达限制复核、正文落盘、路径正确性、失败恢复

平台证据纪律 / 信息策略
  -> 什么时候必须研究、研究来源质量、权限确认、不能假装知道
```

三者有关联，但不是同一种东西。

### 4.1 表达限制 / 去 AI 是“文本呈现约束”

表达限制和去 AI 的核心目标是影响最终文本长什么样：

1. 少用机械句式。
2. 避免常见 AI 腔。
3. 控制破折号、省略号、转折句式、解释性口吻等表达习惯。
4. 支持用户新增、编辑、删除非内置规则。
5. 支持项目级、智能体定向、阶段定向绑定。

因此它们适合继续留在：

1. `creative/ExpressionConstraintProfile`
2. `ProjectExpressionConstraintBinding`
3. `NarrativeConstraintBindingProposal`
4. `WritingExecutionConstraintBridgeService`

它们可以进入执行 gate，因为系统需要检查“有没有注入、有没有复核证据、是否明显失效”。但它们的产品语义仍然是用户可理解的表达规则资产，不能被内部 gate 抹掉。

### 4.2 字数策略是“生成规模约束 + 审核容忍策略”

字数不是单纯的最大值，也不是表达限制。

它包含两层：

1. 给智能体的生成目标：例如目标 2000 字、偏差不要太大。
2. 给系统的审核容忍：轻微偏离不返修，严重偏离进入 review/repair。

所以字数适合放在：

1. `ChapterLengthProfile`
2. `ChapterLengthProfileResolverService`
3. `WritingExecutionConstraintBridgeService`
4. 章节后置 evaluation / gate / repair 链

它与表达限制同属“写作执行约束共享层”，但不是同一种用户资产。

### 4.3 信息收集不是表达限制，而是“证据纪律”

信息收集约束的目标不是让文字更像人，也不是控制章节长度，而是控制智能体和系统如何处理事实、来源、权限和记忆：

1. 什么时候可以直接写。
2. 什么时候应先读项目资料。
3. 什么时候必须请求联网研究。
4. 什么时候只能标注为设计灵感，不能伪装成事实。
5. 什么时候需要严谨来源。
6. 什么时候需要用户确认权限。
7. 收集后的信息如何变成 research note / knowledge card / design element。

因此它应优先放在：

1. `core/src/information/`：定义信息收集合同、来源要求、抽取策略、质量判断。
2. `ProjectPromptContract.informationToolGuidance`：告诉所有智能体怎么判断、怎么调用工具。
3. `tools/domain/request_external_research_handler.dart`：接收智能体的结构化研究请求。
4. adapters/runtime：执行真实搜索、导入、权限确认、审计落盘。
5. context activation / information activation：把已验证资料重新喂给写作、拆书、总结等任务。

不应把它塞进 `ExpressionConstraintProfile.rules`，因为那会把“证据和权限纪律”伪装成“文风规则”，后续一定会乱。

### 4.4 它可以接入执行约束层，但不应被表达限制吞并

从运行期看，信息收集确实可以形成 gate：

1. 缺少必要事实来源：阻断或请求确认。
2. 客观资料来源质量不足：要求补充来源。
3. 模型声称已联网但宿主未授权：判定无效。
4. research request 已登记但未执行：提示 pending，不当作已完成研究。
5. 章节引用了未验证资料：标记为 evidence gap。

但这属于更上层的“执行纪律 / runtime policy”，不是表达限制本身。

最合理的演化方向是：未来可以建立一个中性的共享层，例如：

```text
execution discipline / runtime policy
  - length discipline
  - expression discipline
  - evidence discipline
  - delivery discipline
  - recovery discipline
```

这样能统一注入、检查、审计和恢复，但不会把所有东西都叫“表达限制”。

### 4.5 用户权限与可编辑边界

这里必须分清“用户能配置”和“用户能删除底线”。

用户应当可以配置：

1. 是否允许联网。
2. 哪些项目默认允许自动研究。
3. 信息收集严格度。
4. 是否把某个资料作为项目知识保存。
5. 非内置表达限制的增删改查。
6. 非内置信息来源模板或研究偏好的增删改查。

用户不应当能通过下载智能体或删除某条规则来取消平台底线：

1. 不能把未验证外部事实冒充已验证事实。
2. 不能让模型自声明授权覆盖宿主权限。
3. 不能把研究失败伪装成研究完成。
4. 不能把客观资料和创作灵感混成同一种证据。

换句话说：表达限制可以是用户资产；信息收集纪律有一部分可以暴露为设置，但最低证据纪律必须是平台基线。

### 4.6 对当前实现的落位建议

短期不要大拆现有执行约束层。最稳的做法是：

1. 保持字数、表达限制、去 AI 继续走 `WritingExecutionConstraintBridgeService`。
2. 保持信息收集合同继续走 `src/information/`。
3. 在写作运行结果或 activation report 中增加 evidence / information gap 信号，而不是把它伪装成 expression review。
4. 在 adapters/runtime 补权限薄桥和自动执行 pending research。
5. 等 evidence discipline 稳定后，再考虑抽一个中性的 `runtime policy` 或 `execution discipline` 总入口。

这比现在就强行统一成“大约束系统”更现实：先让边界清楚，再逐步统一执行事实层。

### 4.7 回接此前已经演化过的限制层与暴露协议

需要特别修正一点：这里不是重新发明一套限制层。项目此前已经演化过几条基线，信息收集必须接入这些基线，而不是另开一套平行概念。

#### 4.7.1 创作约束三层仍然有效，但平台底线不属于项目资产

`agent.md` 已经固定过创作约束三层：

1. `ProjectConstitution`
2. `ModeGuidance`
3. `StyleProfile / ProjectStyleBinding`

信息收集纪律不能把这三层搅乱，也不能被误做成“第四层创作约束”。

更精确的落位是：

1. 平台证据底线在三层之外：不能假装知道、不能绕过权限、不能把研究失败当成研究完成。它由宿主和工具执行层维护，不是项目可删除资产。
2. 项目可以在 `ProjectConstitution` 里追加更严格的资料要求，例如“本项目所有历史事实必须有来源”，但不能削弱平台底线。
3. 当前任务的研究目标可以投影到 `ModeGuidance`：本轮是在拆书、写章节、做总结、还是做资料补全，需要不同研究深度。
4. 信息呈现方式可以影响 `StyleProfile`：例如“引用资料时自然融入正文，不写论文腔”，但来源纪律本身不是文风。

因此，信息收集不能简单写成一段 agent prompt，也不能塞进 style profile；它应由平台基线、模式引导和工具合同共同表达。

#### 4.7.2 暴露协议必须继续区分普通、高级、诊断、内部运行时

此前发布收口分析已经确定过暴露协议：

| 层级 | 与信息收集相关的可见内容 | 不应默认可见 |
| --- | --- | --- |
| 普通用户 | 是否需要资料、需要联网确认、已采用哪些参考资料、资料是否足够 | raw JSON、tool profile id、prompt block id、execution constraint、内部 research request 字段 |
| 高级用户 | 研究偏好、来源严格度、资料引用规则、非内置资料规则、项目级覆盖 | provider 私有字段、底层 port、运行时大合同 |
| 开发/诊断用户 | research request、source audit、permission decision、gateway failure、activation 命中记录 | 不适用 |
| 内部运行时 | information contract、permission contract、tool outcome、activation evidence | UI 文案和用户心智术语 |

这意味着 GUI 里不应该出现“information execution discipline”之类的内部词。普通用户看到的应该是：

1. “需要查资料”
2. “需要联网确认”
3. “已导入资料”
4. “来源不足”
5. “建议补充权威来源”

高级设置里才暴露：

1. 资料收集严格度。
2. 来源类型偏好。
3. 项目是否允许自动联网研究。
4. 是否把收集结果保存为项目知识。
5. 非内置研究偏好或资料规则的增删改查。

这里的“严格度”只调整触发敏感度和来源要求，不代表用户可以关闭证据底线。最简单的产品解释是：可以少查、晚查、只查项目内资料，但不能把没查到的外部事实说成已经证实。

诊断视图再展示 request id、source audit、quality score、changed paths、permission decision 等细节。

#### 4.7.3 内置 / 非内置资产边界继续沿用

此前已经决定，来源不需要拆得过细。产品和权限层只区分：

1. 内置资产。
2. 非内置资产。

信息收集也应沿用这个原则。

适合成为内置资产的内容：

1. 基础来源质量规则。
2. 客观资料默认严格度。
3. 常见资料类型的抽取策略。
4. 默认 research note / knowledge card / design element 分类规则。

适合成为非内置资产的内容：

1. 用户自定义研究偏好。
2. 用户导入或下载的资料收集模板。
3. AI 生成的研究策略草案。
4. 某个项目固化下来的资料引用规则。

但 AI 生成的研究策略不能直接变成已信任资产。它应与技能、规则、profile 一样走：

```text
草稿/提案 -> 结构校验 -> 风险说明 -> 用户确认 -> 应用级安装或项目级固化 -> 运行时使用 -> 可回滚/删除
```

#### 4.7.4 应用级模板与项目级快照原则继续沿用

此前关于限制资产已有一个重要结论：

1. 应用级 profile 只是模板。
2. 项目引用后应固化或锁定到项目内。
3. 应用级删除不破坏旧项目复现。
4. 项目内 profile 可由用户或智能体以 proposal 方式继续演化。

信息收集资产也应如此。

例如，应用级有一个“历史资料严谨来源策略”。项目创建时默认不必复制它；当用户或智能体在某个项目中启用后，应保存项目级快照或版本锁定。之后即使应用级策略升级或删除，旧项目仍能复现当时的研究行为。

删除应用级资料策略时，可以提供“清理所有项目引用”的高级工具，但必须先预览影响范围，不能静默破坏项目。

#### 4.7.5 信息收集与 RuleBinding / PermissionProfile 的关系

此前的权责边界里已经有：

1. `RuleBinding`：用户可理解的规则绑定。
2. `PermissionProfile`：工具能力边界。
3. `Execution constraint`：内部执行和审计层。
4. `Prompt block`：把规则和工具说明渲染给模型。

信息收集应拆到这些位置，而不是放进一个总开关：

1. “需要严谨资料来源”“资料必须保存为项目知识”等用户可理解内容，可作为 `RuleBinding` 或未来的 `InformationRuleBinding`。
2. “能否联网”“能否导入本地资料”“能否写入项目知识库”，属于 `PermissionProfile`。
3. “本章用了未验证资料”“research request 未执行”“来源质量不足”，属于 runtime evidence gate。
4. “如何判断何时研究、如何提交 research note”，属于 prompt/tool guidance。

这也解释了用户困惑的答案：信息收集有一部分像限制，但不是单一限制。它跨越规则、权限、工具指导、运行 gate 和资料资产。强行归入任何一个现有小类都会造成未来耦合。

为了不把问题做复杂，近期实现不需要新增一整套可见“信息限制中心”。只需要把现有五个入口各归各位：

1. `src/information/` 保存信息合同和判断策略。
2. `ProjectPromptContract` 提供通用工具指导。
3. `PermissionProfile` 或现有权限设置决定能否联网/写入。
4. runtime gate 记录 evidence gap。
5. GUI 只展示“需要资料 / 已采纳资料 / 来源不足 / 需要确认”。

#### 4.7.6 最终命名建议

为了避免后续团队继续混用概念，建议采用以下口径：

1. 用户可见层叫：资料规则 / 研究偏好 / 来源要求。
2. 平台底线层叫：证据纪律。
3. 内部运行层叫：information policy / evidence discipline。
4. 不建议把它叫：表达限制。
5. 不建议把它只叫：技能。
6. 不建议把它只叫：智能体人设。

更短的结论是：

```text
信息收集不是“新的去 AI”。
它是跨 RuleBinding、PermissionProfile、PromptContract、ToolOutcome、RuntimeGate 的证据纪律。
```

---

## 5. 信息收集决策矩阵

### 5.1 必须先收集或声明缺口

这些情况不能直接凭空写：

1. 客观历史、科学、医学、法律、技术、地理等事实。
2. 真实文化、宗教、神话、民俗、古籍、制度。
3. 现实作品、同人、穿书、跨作品引用边界。
4. 会成为长期设定基础的外部资料。
5. 影响后续长篇结构的来源解释。

可接受动作：

1. `request_external_research`
2. 导入资料收集
3. `submit_research_note`
4. 标注 uncertainty
5. 请求用户补充资料

### 5.2 应当谨慎收集

这些情况需要智能体判断，不应自动化过度：

1. 原创世界观中的自造神话、自造制度。
2. 用户已明确给出的设定。
3. 当前只是局部气氛描写，不影响长期事实。
4. 只是参考某种感觉、风格或象征，不需要严格考据。

可接受动作：

1. 直接写作。
2. 标为 AI 推断或设计灵感。
3. 提交 `propose_design_element`，不冒充外部事实。

### 5.3 不应收集

这些情况通常不应触发资料收集：

1. 用户明确要求不要联网。
2. 完全原创且没有外部事实依赖。
3. 已有项目资料足够支撑本轮创作。
4. 收集会明显破坏当前创作节奏，且资料不是关键依赖。

---

## 6. 权限策略的最终判断

### 6.1 完全开放权限下应当几乎无感

用户说得对：

```text
完全开放权限基本不应让用户感觉到确认，因为工具会自动同意调用。
```

在 `all/open` 权限下：

1. 智能体请求联网研究。
2. 宿主确认当前允许联网。
3. 系统自动执行 gateway research。
4. 结果落为 research note。
5. 只在执行记录里保留审计。

用户不应被频繁打断。

### 6.2 非完全开放权限下只做轻确认

不应做重 GUI。

最小 UX 是：

1. 工具结果或任务站显示“请求联网研究：query”。
2. 用户可确认/拒绝。
3. 确认后继续执行 pending research request。
4. 拒绝后保留缺口，不假装已研究。

### 6.3 宿主权限必须覆盖模型自声明

`user_granted_network_access` 不能由模型说了算。

模型可以表达“我需要联网研究”，但真正授权来自：

1. 应用权限设置。
2. 本次用户确认。
3. 项目/会话策略。

这点必须作为后续实现约束。

---

## 7. 当前实现状态

截至本文时，已经完成的底座包括：

1. Core 信息收集合同：
   - `InformationCollectionRequest`
   - `InformationSourceRequirements`
   - `InformationExtractionPolicy`
   - `InformationCollectionPolicyService`
   - `InformationSourceQualityService`

2. `request_external_research` 已支持：
   - `collection_mode`
   - `information_domain`
   - `source_requirements`
   - `extraction_policy`

3. 权限策略已区分：
   - `import` 不需要联网授权。
   - `network / hybrid` 需要联网授权。

4. Gateway research 已增强：
   - 保留多个搜索候选。
   - 抓取多个来源。
   - 保存 source quality。
   - 对客观资料统计 rigorous source count。
   - 搜索失败会持久化审计。

5. 导入收集服务已新增：
   - 项目文件可导入为 research note。
   - 文本可导入为 research note。
   - 保留候选片段，不直接冒充事实。

6. 测试已覆盖：
   - 信息收集策略归一化。
   - 来源质量判断。
   - network/import 研究请求登记。
   - 多候选 gateway research。
   - 导入资料 research note 落盘。

---

## 8. 仍不完善的地方

### 8.1 权限设置与执行层还没彻底闭环

当前设置页已有：

1. `allow_network`
2. `allow_process`
3. `safe/custom/all`

但执行层仍需要补一个薄桥：

```text
权限设置 -> 工具执行策略 -> research gateway 是否自动执行
```

这不需要重 GUI，但需要让执行器真正吃到权限设置。

### 8.2 `user_granted_network_access` 需要改成宿主授权结果

当前字段已经存在，但长期不应让模型自己填了就等于授权。

更合理的口径：

1. 模型提出 `collection_mode=network/hybrid`。
2. 执行器根据宿主权限补充/覆盖 `user_granted_network_access`。
3. 若权限不足，结果为 `needs_user_confirmation`。

### 8.3 自动后处理还应补一层

当 `request_external_research` 被接受，且宿主权限允许联网时，系统应自动调用：

```text
ProjectResearchGatewayService.processPendingRequest(...)
```

否则开放权限下会出现“智能体请求了研究，但只是登记 pending，没有真正收集”的割裂感。

### 8.4 智能体提示还需要持续强化，但不应成为唯一保障

已经补过 prompt guidance，但后续仍应保持原则：

1. 平台级约束提供底线。
2. tool guidance 提供通用操作说明。
3. 智能体原文提供专业风格。
4. runtime/permission 执行真实授权和审计。

---

## 9. 最终架构结论

最终应形成如下链路：

```text
智能体判断是否需要资料
  -> 不需要：直接写作/拆书/总结
  -> 需要项目内资料：读取或导入收集
  -> 需要外部资料：request_external_research
       -> 宿主权限允许：自动 gateway research
       -> 宿主权限不足：轻确认
  -> 形成 research note
  -> 必要时提升为 knowledge/design/reference
  -> 后续通过 activation/report 注入写作链
```

这条链路的关键不是“多收集”，而是：

1. 不该收集时不要打扰创作。
2. 该收集时不能假装知道。
3. 已收集的信息必须可追踪。
4. 权限开放时自动执行，权限不足时轻确认。
5. 一般项目、长任务、拆书、解书共用同一套判断与合同。

---

## 9. IED-01 审计补充：当前断点与禁止重做项

### 9.1 `request_external_research -> pending -> gateway/import -> research note -> evidence gate -> GUI/CLI` 当前断点

1. `request_external_research` handler 已能完成 payload 归一化、`InformationCollectionRequest` 结构化和 `request_registered=true` 的受控结果返回。
   当前断点：`packages/novel_agent_core/lib/src/tools/domain/request_external_research_handler.dart` 仍直接把 `collectionRequest.userGrantedNetworkAccess` 当作权限输入，最终仍可能来自模型 payload，而不是宿主上下文覆盖结果。

2. `ProjectInformationDomainToolExecutor` 已能把 request 落到 `.novel_agent/information/research_requests/*.json`，并写入 `pending_gateway_execution` / `awaiting_user_confirmation` 等状态。
   当前断点：`packages/novel_agent_adapters/lib/src/tools/project_information_domain_tool_executor.dart` 只负责登记 pending request 和写 event，没有在持久化后自动调用 coordinator，也没有统一的确认/拒绝 action service。

3. `ProjectResearchGatewayService.processPendingRequest(...)` 与 `ProjectInformationImportCollectionService` 都已经存在，且都能生成 `ResearchNote`、source audit 与 projection。
   当前断点：
   - gateway 仍需要外部显式传入 `allowGatewayExecution=true`，没有由 settings/runtime 自动提供宿主权限决策；
   - import collection 目前是独立入口，尚未从 `request_external_research` 的 `import / hybrid` 请求稳定接线；
   - hybrid 还没有统一 coordinator 先导入再按权限决定联网部分。

4. research note、event、projection 的持久化链路已经通。
   当前断点：accepted 的 `request_external_research` 默认只停在 pending request，开放权限下不会自动进入 `research_notes/`、`research/资料研究摘要.md` 或 source audit 投影，因此“已请求研究”和“已完成研究”之间仍有断层。

5. evidence signal 已经具备部分基础。
   - `packages/novel_agent_core/lib/src/workflow/narrative_supervisor_risk_policy_service.dart` 已能从结构化工具结果里识别 pending research、high-risk reference、design conflict、required omitted。
   - `packages/novel_agent_core/lib/src/workflow/writing_execution_result_normalizer_service.dart` 已有 `informationSignal` / `WritingExecutionInformationSummary` 输入位。
   当前断点：
   - 普通写作 runtime 还没有把 information execution summary 稳定灌入同一条 shared gate；
   - “rigorous source insufficient / gateway failed / awaiting confirmation” 还没有被收口成独立、稳定、可复用的 evidence gate 合同；
   - 当前 supervisor 偏向消费现有结构化结果，但 source quality 严重不足仍主要留在 research note uncertainty 与 gateway summary 里。

6. GUI / CLI 已能做最小摘要消费。
   - long task station 能列出 information summary、projection 和 pending research record；
   - CLI workflow summary 能显示 knowledge/design/research/reference 计数与 projection 路径。
   当前断点：目前都还是“只读摘要”，没有普通用户可理解的 approve / reject 轻动作，workbench 也还没有完整的“确认联网研究 / 拒绝并保留缺口”闭环。

### 9.2 `allow_network` 当前保存位置与消费缺口

1. `apps/novel_agent_app/lib/features/settings/presentation/widgets/permissions_settings_panel.dart` 会把 `allow_network` 作为 `permissions.allow_network` 保存回设置 payload。
2. `apps/novel_agent_app/lib/app/state/app_shell_controller.dart` 通过 `onPermissionSettingsSaved(...)` 把该 payload 写回 `AppSettings.permissionSettings`。
3. `packages/novel_agent_adapters/lib/src/config/local_settings_repository.dart` 会把整段 `permissions` JSON 持久化到 `novel_agent_settings.json`，并在 `load()` 时回读到 `AppSettings.permissionSettings`。

当前断点：

1. `permissionSettings['allow_network']` 还没有桥接成纯 core 的 host permission context。
2. `ProjectInformationDomainToolExecutor`、`ProjectResearchGatewayService`、`ProjectToolDispatcher` 目前都不会直接消费这份设置。
3. 结果就是 settings 已保存，但 information tool 执行链还无法根据宿主设置稳定覆盖 `user_granted_network_access`。

### 9.3 本轮确认的“已有 / 半闭环 / 禁止重做”

#### 已有，可直接复用

1. `InformationCollectionRequest`、`InformationSourceRequirements`、`InformationExtractionPolicy`、`InformationCollectionPolicyService`。
2. `RequestExternalResearchHandler` 与 information domain tool 骨架。
3. `.novel_agent/information/*` 本地事实源、projection writer、activation bridge。
4. `ProjectResearchGatewayService`、`ProjectInformationImportCollectionService`。
5. supervisor / writing summary / long task station / CLI 的最小 information 摘要消费位。

#### 半闭环，正是 IED 主线要补的

1. 宿主权限上下文缺位，模型自声明联网授权尚未被覆盖。
2. pending research 缺少统一 approve / reject action。
3. 开放权限 accepted 后不自动执行 gateway/import。
4. source quality insufficient、gateway failed、awaiting confirmation 还没有统一 evidence gate 合同。
5. GUI / CLI 只有展示，没有轻确认动作。

#### 禁止重做或错误方向

1. 不重做 PIS 已完成的 information contracts、repositories、projection、activation。
2. 不新增全能 information control center，不把 GUI / CLI / probe 变成业务判断中心。
3. 不让 core 读取本地 settings 文件，不让模型 payload 决定最终联网授权。
4. 不把 `knowledge/`、`research/` Markdown 投影重新当作事实源。
5. 不继续把 algorithm 塞进 `ProjectWorkflowRuntimeService`、`ProjectContextActivationService` 或 widget。

## 10. 后续最小实现建议

下一步最合适的单任务不是扩 GUI，而是：

```text
补“信息收集权限执行薄桥”：
让 app/settings 的权限设置进入工具执行器；
开放权限下自动执行 accepted research request；
受限权限下返回 needs_user_confirmation；
所有结果保留审计与 changed_paths。
```

这一步完成后，信息收集会更接近真实可用状态：

1. 智能体负责判断。
2. 平台负责证据纪律。
3. 宿主负责权限。
4. 用户只在必要时确认。

---

## 11. IED-18 收口更新（2026-06-06）

### 11.1 当前实现状态已经收口到什么程度

截至 `IED-17` 完成并进入 `IED-18` 文档收口时，信息收集证据纪律主线已从“边界分析”进入“生产合同闭环可用”阶段：

1. 宿主权限已正式覆盖模型自声明。
   - `user_granted_network_access` 现在保留 raw declaration 审计语义。
   - 真正生效的联网授权来自宿主 `HostInformationPermissionContext`。
   - `allow_network`、permission mode、confirmation mode 已能从 settings 薄桥接入 tool/runtime 执行链。

2. `request_external_research` 已形成 open / safe / import / hybrid 的稳定执行闭环。
   - open 权限下可在 request 持久化后自动执行 gateway/import。
   - safe/restricted 权限下稳定进入 `awaiting_user_confirmation`。
   - approved pending request 可通过统一 action service + coordinator 恢复执行。

3. pending research 的用户动作已不再停留在隐藏 JSON。
   - adapters 已有统一 `ProjectPendingResearchActionService`。
   - GUI 已提供最小 `approve / reject` 轻动作。
   - CLI 已提供 `workflow pending-research list / approve / reject`。

4. evidence gate 已稳定进入共享写作结果、长任务 checkpoint 和摘要链路。
   - `awaiting_confirmation`、`gateway_failed`、`required_information_omitted`、`external_fact_unverified`、`rigorous_source_insufficient` 已有统一结构化落点。
   - 普通项目、长任务、拆书续写与分析 followup 共享同一套 `WritingExecutionResult` / supervisor information signal 口径。

5. GUI / CLI 现在只消费人话摘要与稳定 projection。
   - 工作台与长任务总站会显示“已执行研究 / 待确认 / 来源不足 / 资料投影”等用户可理解摘要。
   - CLI summary 与 pending-research 子命令只消费稳定 action/projection 合同，不直接暴露 raw payload。

6. 验收链已同时具备 mock regression 和 gated real probe。
   - mock regression suite 已覆盖 open auto research、restricted pending、import、hybrid、gateway failed、rigorous source insufficient、ordinary runtime、long task checkpoint。
   - real provider 小预算 probe 已验证：
     - 开放权限普通项目可观察到真实 research 行为；
     - 受限权限普通项目可稳定进入 waiting user；
     - 长任务短链 checkpoint 可见 information evidence 摘要。

### 11.2 仍然明确保留的风险与未完成项

以下内容仍不能被误写成“已经完整产品化”：

1. 当前没有完整的 knowledge browser / information center。
   - GUI 仍以最小资料摘要、projection 打开入口、待确认轻动作为主。
   - 这符合本主线边界，不等于资料产品已经完全收口。

2. real probe 的结论仍是“小预算样本成立”，不是“大规模题材全覆盖”。
   - 真实联网验证仍需显式开闸。
   - 当前 real probe 只证明关键链路和证据可见性成立，不代表所有题材、所有 provider、所有长任务长度都已稳定。

3. 来源质量与真实命中率仍需继续观察。
   - `rigorous_source_insufficient` 已有稳定 evidence gate 语义。
   - 但不同资料题材、不同 provider、不同 query 风格下的真实命中率与来源质量，后续仍可能需要单独优化 prompt / gateway / source preference。

4. projection 仍然只是 projection，不是事实源。
   - `knowledge/*.md`、`research/*.md`、`references/*.md` 依旧不能代替 `.novel_agent/information/*` 隐藏事实源。
   - 后续若做更强资料编辑体验，必须继续走结构化合同，不要回退成直接改 Markdown。

5. 轻确认已成立，但还不是批量资料治理系统。
   - 当前重点是“必要确认”和“保留缺口不假装完成”。
   - 后续若扩展批量审批、规则级治理或更强资料索引，应另开主线，不要回写到本主线文档里假装已完成。

### 11.3 当前维护口径

后续如果继续维护这条主线，默认应遵守：

1. 先复用既有 `information` 合同、permission bridge、pending action service、coordinator、evidence gate、projection service。
2. 不把新需求塞回 `ProjectWorkflowRuntimeService`、widget、probe 或 CLI 壳层里做私有判断。
3. 真实联网问题优先先看：
   - request record
   - information events
   - research note / projection changed paths
   - shared writing result / checkpoint information summary
4. 如果只是验证链路，优先跑 mock regression；只有需要确认真实 provider 行为时才显式开闸 real probe。
