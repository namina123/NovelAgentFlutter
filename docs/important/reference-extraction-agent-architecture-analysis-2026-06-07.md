# 参考资产提取任务族与智能体组架构总分析

日期：2026-06-07

关联文档：

- `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
- `docs/reference-evidence-substrate-implementation-handoff-2026-06-07.md`
- `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`
- `docs/important/expression-constraint-agent-review-architecture-analysis-2026-06-06.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `agent.md`

关联实现锚点：

- `packages/novel_agent_core/lib/src/reference_substrate/reference_source_document_extraction_service.dart`
- `packages/novel_agent_core/lib/src/use_cases/build_reference_package_from_source_document_use_case.dart`
- `packages/novel_agent_adapters/lib/src/storage/reference_source_document_file_ingestion_service.dart`
- `packages/novel_agent_core/lib/src/agents/project_agent_group_candidate_resolver_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_execution_service.dart`
- `packages/novel_agent_core/lib/src/agents/sub_agent_group_selection_service.dart`
- `packages/novel_agent_core/lib/src/agents/builtin_collaborator_catalog_service.dart`

---

## 1. 本文解决什么

这一轮要解决的，不是“当前抽取结果像不像知识库”这么表层的问题，而是更根上的几个架构分歧：

1. 从整本书、整套资料体系中提取可复用知识，到底是不是一个独立而沉重的任务。
2. 这类任务是否应继续由普通写作智能体组主跑。
3. 它与普通信息收集、拆书、长任务、项目级知识卡之间的边界到底在哪里。
4. 我们应如何在不破坏现有 `group-first` 和三层信息架构的前提下，把这条能力做成长期可用的正式主链。

本文的目标不是直接拆任务顺序，而是先把以下东西钉牢：

1. 我们到底在做哪一类能力。
2. 这类能力在产品、运行时、数据层、智能体层各自应该落在哪里。
3. 哪些东西必须复用现有基础，哪些地方必须新增专门结构。
4. 哪些现有实现应该降级为 bootstrap，不能再被误称为“完成提取”。

---

## 2. 先确认现状：我们现在已经有什么，还缺什么

### 2.1 已经有的好基础

当前仓库并不是白板，已经有几条重要基础：

1. **三层信息架构已成立。**
   - 应用级：`ReferenceEvidenceSubstrate`
   - 项目级挂载：`ProjectReferenceAttachmentLayer`
   - 项目级工作知识：`ProjectInformationCapabilityLayer`

2. **group-first 已成立。**
   - 用户对项目默认选择的是智能体组，不是零散单智能体。
   - 单智能体只是兼容退化形式，不应再成为主心智。

3. **子智能体隔离运行基础已存在。**
   - 有独立上下文
   - 有独立工具权限
   - 有 reviewer / child fallback 雏形

4. **source document 到 substrate 的 bootstrap 链已存在。**
   - 读取文本
   - 切片与轻量线索抽取
   - 形成初始 package snapshot
   - 写入 `ReferenceEvidenceSubstrate`

5. **长任务/监督者/运行记录这类稳定性基础已部分存在。**
   - 这意味着重任务不必靠“会话里自由聊天”硬跑。

这些基础都应该保留。

### 2.2 当前最大的缺口

真正缺的不是“再多抽点字段”，而是下面几层没有被正式立起来：

1. **没有把“参考资产提取”正式定义成一种任务族。**
2. **没有把“写作默认组”和“提取执行组”分开建模。**
3. **没有把“source bootstrap”和“智能体主导语义提取”分成两段。**
4. **没有正式的 staging / proposal / review / finalize 链。**
5. **没有回答：什么时候只是做 research，什么时候需要启动正式参考资产提取。**

这几层不立起来，后续无论怎么补 agent prompt，最后都还会摇摆。

---

## 3. 首先纠偏：当前这条链到底算什么

必须非常明确地说：

```text
当前 `reference_source_document_extraction_service.dart`
不是完整参考资产提取，
而只是原始文稿导入后的 seed extraction / bootstrap extraction。
```

它现在适合承担的职责只有：

1. 原文读取与编码容错
2. 粗粒度切片
3. 初始证据锚点生成
4. 轻量章节片段与实体线索 seed
5. 给后续智能体提供可检索、可追溯的证据底稿

它不应被继续包装成：

1. 风格提炼完成
2. 同人可用知识库完成
3. 可共享参考资产包已经正式完成

也就是说，当前链路的正确命名应更接近：

1. `source bootstrap`
2. `seed extraction`
3. `evidence scaffolding`

而真正的“参考资产提取”应发生在它之后。

---

## 4. 我们真正要做的能力，不是一种，而是三种

这是上一版分析不够清楚的地方，这里要重新拉开。

并不是所有“信息提取”都属于同一个重量级工作。

### 4.1 轻量研究：`research`

特点：

1. 为当前项目或当前章节补一个事实缺口
2. 结果通常先落 `ResearchNote` / `KnowledgeCard` / `DesignElementCard`
3. 目标是服务当前项目，不追求全局复用包

例子：

1. 某朝代盐政大概如何
2. 某种矿炉是否合理
3. 某神话称号的常见来源

它不是这次要专门升级的主线。

### 4.2 中量源文抽取：`source bootstrap extraction`

特点：

1. 针对单个文本或导入资料做程序化切片与 seed 线索生成
2. 目标是把原始资料转成可被后续智能体消费的证据骨架
3. 当前已基本落在这层

它是正式参考资产提取的前置段，不是终点。

### 4.3 重量级参考资产提取：`reference_extraction`

特点：

1. 面向整本书、整套体系、整类资料
2. 目标是形成可复用、可挂载、可分享、可审计的参考资产包
3. 必须有智能体主导的语义提取和审核
4. 默认是长流程、可暂停、可恢复、可回看产物的任务

例子：

1. 《哈利波特》第一卷原作体系提取
2. 一套历史朝代 + 科技发展依据的参考资产提取
3. 某神话/宗教/民俗系统的写作参考资产提取

这次真正要升级的是第三种，而不是把第二种继续变厚。

---

## 5. 用户判断的哪些是对的，哪些需要进一步修正

### 5.1 对的部分

用户这次的判断大方向是对的：

1. 从整本书提取知识库绝对不是轻量工作。
2. 它和普通写作智能体组的能力侧重确实不同。
3. 无论是在普通项目运行时临时调用，还是在未来专门的提取型入口中运行，主执行能力都不应和写作组混为一谈。

### 5.2 需要修正的部分

但还要补两个关键修正：

#### 修正一：不是“专门项目”优先，而是“专门任务族”优先

我们不该先问“是不是必须有新的项目类型”，而应先问：

```text
这是不是一个有独立执行语义、独立智能体组、独立数据流和独立审核流的任务族？
```

答案是：是。

所以正式定义应先是：

1. `reference_extraction` 是任务族
2. 它可以被不同入口触发
3. 是否有单独的项目壳或工作台，是产品层问题，不是核心定义

#### 修正二：不是“写作组完全不能碰”，而是“写作组不能当主执行器”

写作组可以参与：

1. 后续消费参考资产
2. 在没有提取组时做受控兜底
3. 在项目写作中引用已抽出的资产

但它不应默认承担：

1. 原作全量体系抽取
2. 风格证据与事实证据分类
3. 可共享 package 的主审核

换句话说，真正的边界是：

```text
写作组不是 reference_extraction 的默认主执行组。
```

这条必须写进架构，不然实现时很容易滑回去。

---

## 6. 正式架构判断：`group-first` 要保留，但要增加“任务族执行覆盖层”

这是这轮最核心的结论。

当前项目里已经有一条很清晰的长期原则：

```text
用户默认选择一个项目智能体组。
```

这条原则不该被推翻。

但如果只保留这一层，就没法优雅表达：

1. 写作用 A 组
2. 审稿用 B 组
3. 重研究用 C 组
4. 参考资产提取用 D 组

因此我们需要的不是“再回到多组并列主选择器”，而是：

```text
Project Default Agent Group
    + Task-Family Execution Override Layer
```

也就是说：

1. **项目默认智能体组**继续是用户主心智。
2. **任务族执行覆盖层**是运行时内部决策层。
3. 用户在高级设置中可以配置它，但默认不需要理解它。

### 6.1 推荐正式引入的任务族

至少包括：

1. `writing`
2. `review`
3. `research`
4. `reference_extraction`
5. `deconstruction`
6. `explainer`

其中本轮新增重点是：

1. `reference_extraction`

### 6.2 这个覆盖层解决什么问题

它解决的是：

1. 不破坏 group-first 主交互
2. 不把参考资产提取绑成独立项目系统
3. 不要求用户每次都手动换组
4. 允许内部运行时根据任务族选择不同执行组

### 6.3 一条必须钉死的规则

```text
无论 reference_extraction 是在普通项目里被临时发起，
还是未来在专门的提取型入口、工作台或项目里发起，
主执行智能体组都必须优先是提取型智能体组，
而不是项目默认写作组。
```

入口可以不同，主执行能力画像不能混。

---

## 7. 这不只是智能体组不同，更是“执行方式”不同

上一版分析里提到了不同职责位，但还少了一层更关键的事：

```text
reference_extraction 不应主要依赖“主智能体自由决定何时调用子智能体”来成立。
```

原因很简单：

1. 这类任务长
2. 这类任务重
3. 这类任务需要稳定 staging / review / finalize
4. 这类任务经常要跨多个证据切片、多个阶段

因此它更适合：

1. **程序定义确定性的工作流阶段**
2. **智能体在每个阶段承担专门语义职责**

这和我们从 `book-os`、多智能体分析、长任务监督者设计里吸收的思想是一致的：

1. command / instruction / agent 分层
2. workflow node 明确
3. 子 agent 负责具体专业动作，不负责整个系统流转

所以这条能力的正确形态不是：

```text
给主写作 agent 一个更长 prompt，
让它自己想办法调子 agent 做全书提取
```

而是：

```text
由 reference_extraction workflow 明确分阶段调度，
每个阶段使用合适的职责位与工具权限。
```

这点必须明确，否则后续实现仍会不稳定。

---

## 8. 正式推荐的执行主链

这一条建议作为后续实现的正式主线。

### Phase 0：原始资料导入与 bootstrap

程序负责：

1. 导入原始文稿/资料
2. 编码容错
3. 建立源文档记录
4. 切 chunk
5. 建 seed 索引
6. 生成最小 seed evidence

当前已基本位于这层。

### Phase 1：提取任务计划

程序 + lead 智能体协作：

1. 判断这次是轻量 research 还是正式 reference_extraction
2. 估计体量、阶段、预算、是否需要 reviewer
3. 决定是单智能体提取、双智能体、还是完整提取组

### Phase 2：证据阅读与候选提案

提取型智能体组负责：

1. 读 chunk
2. 生成候选 facts / style / motif / boundary / timeline / entity proposals
3. 明确 evidence refs
4. 标记 uncertainty

### Phase 3：审核与降级

reviewer 或 lead 自审负责：

1. 证据够不够
2. 是否脑补
3. 事实/解释/风格是否混写
4. 是否 accepted / candidate_only / needs_rework

### Phase 4：合并与去重

程序 + curator 负责：

1. 多轮候选去重
2. entry kind 归位
3. 冲突项聚合
4. 构造最终 package draft

### Phase 5：finalize 到 substrate

程序负责：

1. 形成正式 package/version/entry snapshot
2. 写入 `ReferenceEvidenceSubstrate`
3. 导出 bundle
4. 留运行记录与审计信息

### Phase 6：可选挂载与项目投影

程序负责：

1. 决定是否挂载到当前项目
2. 决定哪些内容投影到 `ProjectInformationCapabilityLayer`
3. 保持应用级与项目级分离

这一整条链比“直接从 txt 生成 package snapshot”更符合真实目标。

---

## 9. 必须新增一个“staging / proposal”层，不能直接把一切写进正式 substrate

这点是上一版没说透的关键缺口。

如果未来真正的智能体提取结果一上来就直接写入正式 `ReferenceEvidenceSubstrate`，问题会非常大：

1. 候选和正式资产混在一起
2. reviewer 只能事后补救
3. 被驳回的条目也会污染正式库
4. 不利于恢复、回滚、重新审核

因此建议正式补一层：

```text
Reference Extraction Draft / Proposal Workspace
```

它的职责是：

1. 存放候选提案
2. 存放 reviewer 结论
3. 存放 chunk-level evidence maps
4. 存放 merge 过程中的临时冲突
5. 在 finalize 前不污染正式 substrate

### 9.1 这层不应取代 substrate

它不是新的全局知识库，只是：

1. 提取任务运行工作区
2. 资产成型前的 staging area

### 9.2 finalize 后谁进正式库

只有：

1. `accepted`
2. `accepted_with_uncertainty`

这类结果才应该进入正式 package snapshot。

`candidate_only`、`needs_rework`、`insufficient_evidence`
更适合保留在 staging / run artifact 中，不直接变成正式共享资产。

---

## 10. 参考资产提取智能体组，到底该怎么设计

这里仍然要坚持“通用职责位”，不能题材化。

### 10.1 职责位而非题材位

推荐的通用职责位仍然成立：

1. `reference_extraction_lead`
2. `evidence_reader`
3. `structure_analyst`
4. `style_analyst`
5. `evidence_reviewer`
6. `package_curator`

但这次要补上更细的判断：

### 10.2 这些职责位不是固定人数配置

系统应支持：

1. 单智能体提取兜底
2. `lead + reviewer` 的最小稳态
3. 完整多职责位提取组

### 10.3 每个职责位的权限画像必须不同

这次不能只停在“system prompt 不同”。

至少要区分：

1. 是否允许正式交付
2. 是否允许直接写项目资产
3. 是否允许做外部 research
4. 是否允许发起子委派
5. 是否允许 finalize package

例如：

1. `evidence_reader` 不应拥有 finalize 权
2. `style_analyst` 不应拥有正式项目写回权
3. `evidence_reviewer` 不应拥有无审计的改写权
4. `package_curator` 可以有 finalize 建议权，但真正持久化仍应由程序执行

### 10.4 模型侧重也应允许不同

这类组很可能需要：

1. `structure_analyst` 偏推理
2. `style_analyst` 偏文学分析
3. `reviewer` 偏苛刻审查
4. `lead` 偏统筹

这和我们之前关于“子智能体可拥有不同模型设置”的方向完全一致。

---

## 11. 这类能力与当前项目默认组的关系，应如何呈现给用户

这是产品层最容易长歪的地方。

### 11.1 默认心智仍然不应让用户面对一堆组

普通用户默认不应在主面板看到：

1. 写作组
2. 审稿组
3. 提取组
4. 研究组
5. 解说组

这样会把用户变成调度员。

### 11.2 正确心智

更合适的产品心智应是：

1. 用户选项目默认协作组
2. 系统内部按任务族调用更合适的执行组
3. 高级用户可在生态/高级设置里配置 task-family override

### 11.3 高级设置可以开放什么

允许用户配置：

1. 当前项目 `reference_extraction` 默认用哪个组
2. 缺省时是否允许单智能体兜底
3. 是否强制启用 reviewer
4. 产物默认是否自动挂载到当前项目

但这些都不应跑到写作主面板上。

---

## 12. “专门提取型项目”到底要不要

更准确的判断应该是：

```text
可以有专门入口，甚至未来可以有专门工作台，
但底层核心不应依赖专门项目类型才成立。
```

### 12.1 为什么产品层仍然值得有专门入口

因为正式参考资产提取往往需要：

1. 长时间运行
2. 分阶段查看产物
3. 读 bundle / projection
4. 查看 reviewer 结论
5. 控制是否挂载到项目

这很适合一个专门运行中心或专门工作台。

### 12.2 为什么核心层不应先绑定“新项目类型”

因为同一能力会被：

1. 普通写作项目调用
2. 拆书项目调用
3. 解说项目调用
4. 同人准备流程调用
5. 全局资料建设流程调用

如果先绑定项目类型，核心层很快就会裂成平行链。

所以正确顺序应是：

1. 先有共享 `reference_extraction` 任务族
2. 再决定产品层是否加“提取工作台/提取型项目壳”

---

## 13. 与已有多智能体架构的衔接，不应怎么做

### 13.1 不应继续把逻辑堆进 `SubAgentExecutionService`

`SubAgentExecutionService` 是子执行基础设施，不应演化成：

1. 提取计划器
2. 审核 orchestrator
3. package merge 中心
4. substrate writer

### 13.2 不应继续把逻辑堆进 `ReferenceSourceDocumentExtractionService`

这个类应保留为 bootstrap extraction 服务，不应继续膨胀。

### 13.3 不应继续把逻辑堆进某个新的大 runtime service

不要只是从：

1. `ProjectWorkflowRuntimeService`

换成：

2. `ReferenceExtractionRuntimeService`

然后继续把计划、分发、审核、合并、持久化全塞进一个 700 行文件里。

真正需要的是按职责拆层，不是换个文件名继续堆。

---

## 14. 关于“600+ 行文件”的正式原则

用户这次提醒得很对，但我们要把原则说准。

问题从来不是“600+ 行”这个数字本身。

真正的问题是：

1. 一个文件同时承担 planning、dispatch、review、merge、persistence、projection 多重职责
2. 一个类同时懂 prompt contract、agent selection、sqlite、runtime status、UI-friendly report
3. 为了赶进度，把原本应在不同模块的逻辑先塞一起

因此正式原则应是：

```text
行数阈值只是报警器，不是设计目标；
真正的拆分依据始终是职责边界、依赖方向、复用语义和运行合同。
```

这条原则需要进一步落实成对本次实现的具体要求：

1. 不能把 `reference_extraction` 的计划、智能体组选择、run package、review gate、merge、finalize 写进一个类。
2. 不能为了“压到 400/600 行以内”机械拆出多个 part 文件或多个空壳工具文件。
3. 必须按真实职责拆成小服务，再由 use case / workflow orchestrator 组合。

---

## 15. 推荐的正式模块拆分

这一层是给后续工作会话用的“架构模块图”，不是实现顺序文档。

### 15.1 core

建议新增或演化到：

1. `reference_extraction/intent/`
   - 研究 vs bootstrap vs formal extraction 判定
   - 提取任务意图模型

2. `reference_extraction/plan/`
   - 任务计划
   - chunk 分配
   - 阶段定义

3. `reference_extraction/agent/`
   - task-family group override resolver
   - 提取型职责位模型
   - run package builder
   - reviewer selection policy

4. `reference_extraction/proposal/`
   - candidate entry proposal
   - proposal evidence models
   - uncertainty contracts

5. `reference_extraction/review/`
   - review result
   - gate
   - downgrade / rework policy

6. `reference_extraction/package/`
   - merge
   - dedupe
   - finalize contract

7. `reference_extraction/projection/`
   - finalized package -> project layer projection policy

8. `reference_substrate/`
   - 继续专注应用级资产合同
   - 不负责提取工作流编排

### 15.2 adapters

建议补：

1. `storage/reference_extraction/`
   - staging workspace persistence
   - run artifact projection

2. `workflow/reference_extraction/`
   - runtime bridge
   - supervisor / queue 接线
   - run status read model

3. `storage/reference_substrate/`
   - 继续负责正式 package 的 sqlite 落库与 bundle 导入导出

### 15.3 app / cli

只负责：

1. 发起入口
2. 运行状态查看
3. 产物预览
4. 挂载/发布确认

不应负责：

1. 语义提取规则中心
2. 审核判断中心
3. sqlite 直接拼装

---

## 16. 最终结论

这轮最终要收住的结论如下。

### 16.1 当前实现的正确定位

当前实现不是“完整参考资产提取”，而是：

1. 原始资料导入
2. source bootstrap
3. seed extraction
4. substrate 初始落库链

它应该保留，但必须降级命名。

### 16.2 我们真正要升级的对象

真正需要升级的是：

```text
reference_extraction 任务族
```

而不是继续把 bootstrap extraction 变厚。

### 16.3 与智能体组的正式关系

参考资产提取必须优先使用提取型智能体组。

这条规则无论：

1. 在普通项目里临时调用
2. 在未来专门入口中调用
3. 在未来提取型项目壳中调用

都不应改变。

### 16.4 与现有 group-first 的关系

不推翻 group-first。

真正需要新增的是：

1. 项目默认组
2. 任务族执行覆盖层

而不是重新把用户暴露给一堆并列主组选择器。

### 16.5 与实现方式的正式关系

它不应主要依赖“主 agent 自由决定如何调所有子 agent”。

它应采用：

1. 程序定义稳定阶段
2. 智能体承担各阶段语义职责
3. staging -> review -> finalize -> substrate 的明确主链

### 16.6 关于接下来应该做什么

在交给实施会话之前，最重要的目标不是“赶紧补类”，而是先按这份分析落下面这些正式骨架：

1. 把当前链路重新定性为 bootstrap
2. 把 `reference_extraction` 正式定义为任务族
3. 补 task-family group override layer
4. 补 staging / proposal / review / finalize 主链
5. 让多智能体提取按确定性 workflow 运行，而不是继续靠自由聊天式 orchestration 顶着走

这才是优雅、稳定、可复用、不会越做越乱的路线。
