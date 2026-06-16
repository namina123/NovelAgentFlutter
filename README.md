# NovelAgentFlutter

[中文](#中文说明) | [English](#english)

## 中文说明

NovelAgentFlutter 是一个本地优先的 AI 小说工作台。它希望把小说项目、章节、资料、约束、拆书结果、信息沉淀、会话与长任务运行，收束进同一个可持续演化的创作环境里，而不是停留在“一次提示词生成一章”的工具形态。

> **当前状态：仍在开发中，未完成。**
>
> 目前仓库更适合视为持续迭代中的开源实验项目，而不是正式发布的软件产品。
> GUI 已经具备一定可测试性，CLI 仍未完全收口，长任务自主连续生成也还在稳定化过程中。

## 项目想解决什么

这个项目的目标，不是单纯把模型调用包一层界面，而是尝试把长篇创作做成真正的“项目工作流”：

- 把小说作为长期项目而不是一次性聊天；
- 让普通写作、长任务写作、拆书与后续衍生流程尽量复用同一套核心合同；
- 让约束、资料、上下文、项目资产成为稳定可积累的内容，而不是每轮都重新拼提示词；
- 为后续的 CLI、Docker、信息提取、知识沉淀等方向保留足够清晰的边界。

简而言之，这个仓库更接近“创作工程工作台”，而不是“单轮生成器”。

## 当前进展

当前大致可以确认的状态如下：

### 已经具备一定基础的部分

- Flutter GUI 主体已经存在；
- Windows 与 Android 构建链路已经能跑通；
- `core + adapters + app/cli shell` 的共享架构已经形成；
- 普通项目写作链路已经比早期稳定得多；
- 长任务运行时、监督/调控、检查点、恢复等方向已经有明确基础实现；
- 拆书与后续派生写作已经不是纯概念；
- 项目信息层、表达限制、资料资产等方向已有正式落点。

### 仍然不能过度承诺的部分

- 这不是成熟产品；
- 长任务无人值守稳定性仍然不够彻底；
- CLI 仍未完全完成；
- 信息提取与可复用知识体系还没完全收口；
- 一些高级写作模式仍处于分析、演化或部分实现状态。

## 已实现内容

### 1. GUI 应用基础

当前 GUI 已经覆盖：

- 项目创建与打开；
- 工作台壳层；
- 会话式写作入口；
- 项目资产与约束面板；
- 智能体生态配置入口；
- 长任务运行视图；
- Markdown 编辑/阅读面；
- Windows / Android 打包能力。

这一层已经能用来测试真实用户路径，但在自然性、一致性和边界体验上仍有继续打磨空间。

### 2. 共享架构

仓库已经不是“GUI 一套逻辑、CLI 再复制一套逻辑”的状态，而是显式建立了共享结构：

- `packages/novel_agent_core`
- `packages/novel_agent_adapters`
- `apps/novel_agent_app`
- `apps/novel_agent_cli`

这一点是目前仓库最重要的成果之一，因为它决定了后续迭代不会轻易退化成多套平行业务中心。

### 3. 普通写作链路

普通项目写作已经具备以下基础：

- 会话驱动的写作流程；
- 项目上下文与资产消费；
- 章节交付；
- 草稿与章节落盘；
- 章节字数与表达限制等约束的初步接入；
- 通过工具与项目文件发生正式交互。

这条链路已经接近“可以真实测试”，但离正式可发布仍有距离。

### 4. 长任务运行基础

长任务方向目前已经具备：

- 运行记录与运行身份；
- 队列 / 暂停 / 恢复 / 检查点相关合同；
- supervisor / control-plane 方向的设计与实现；
- review / repair / diagnosis 等基础方向；
- GUI / CLI 对部分运行态的消费能力；
- 一定的 probe 与回归基础设施。

这块在架构上已经比较成型，但在真实连续运行下仍是当前主要风险区。

### 5. 拆书与后续派生基础

当前仓库已经具备：

- 拆书项目流；
- follow-up route 的规划基础；
- 派生项目创建基础；
- 拆书输出的持久化与后续承接方向。

这部分已经不是概念验证，但还没有达到“复杂原作也可稳定承接”的程度。

### 6. 项目信息层

目前已开始建立共享信息层，用于承载：

- 项目资产；
- 风格与表达限制；
- 参考提取输出；
- 研究资料与可复用知识方向；
- 未来知识卡 / 结构化资料体系的基础。

它的重要性在于：系统不应该每次都依赖模型临场回忆，而应该尽可能沉淀和复用信息。

## 仍未完成或仍在演化的部分

### 长任务稳定性

这是目前最需要继续解决的问题。  
虽然运行时、监督层、调控层已经建立，但仍需要继续验证和补足：

- 多章连续推进的稳定性；
- 自动重试 / 暂停 / 恢复行为；
- 审核与约束在长链中的实际执行力；
- 运行已经开启但没有正确继续推进的边界问题。

### CLI

CLI 已经不再只是空壳，但仍未完全收口。还需要继续补：

- 更完整的命令覆盖；
- 更好的操作体验；
- 与共享运行时能力的更完整对齐；
- 自动化与诊断场景的明确化。

### TUI

尚未开始。  
目前更合理的顺序仍然是：

1. 继续稳定 GUI 与共享 core；
2. 完成 CLI 基线；
3. 再评估是否值得推进 TUI。

### Docker

Docker 支持在规划中，尤其适合长任务与提取类流程，但当前还未完成。

### 信息提取与可复用知识体系

这一块仍在持续演化，尚未完全完成：

- 从导入作品中稳定提取参考信息；
- 让结构化知识可复用到后续项目；
- 保留来源与追踪关系；
- 平衡项目级知识与可复用知识；
- 让研究型写作真正可持续工作。

### 其他高级写作模式

以下方向目前仍属于未收口状态：

- IF / 假设线 / 替代路线；
- 配角或支线视角；
- 写作风格提取与复用；
- 同人 / 衍生信息体系；
- 神话、星象、符号系统、命名体系等元素嵌入与提取；
- 解说、总结、评书等面向既有文本的工作流。

## 目前比较值得保留的设计方向

我更愿意把它们叫做“项目设计赌注”，而不是夸张地说成已经被证明的创新：

### 1. 项目即工作区

核心单位不是“一条 prompt”，而是一个有文件、资产、约束、引用、运行时状态和知识沉淀的项目。

### 2. GUI / CLI 共享核心

GUI 与 CLI 被明确约束为同一核心合同的两个壳层，而不是各自复制业务逻辑。

### 3. 约束层作为正式基础设施

项目宪法、模式引导、风格引导、表达限制这些内容，不再只是零散提示词，而是在往正式层级模型靠拢。

### 4. 长任务被当作真正的运行时问题

长任务不是“多调用几次模型”这么简单，而是要有运行身份、监督、检查点、暂停/恢复、诊断与恢复策略。

### 5. 拆书与后续写作放在同一系统中

拆书、续写、派生写作不是外围脚本，而是在逐步进入统一项目与信息模型。

### 6. 信息复用优先于重复堆上下文

目标是把有价值的信息沉淀为项目资产或未来结构化知识，而不是反复依赖长对话硬塞上下文。

## 路线图

### 近期重点

- 继续收口长任务稳定性；
- 继续修 GUI 的真实用户路径问题；
- 强化权限确认与恢复连续性；
- 强化会话连续性与上下文处理；
- 继续清理遗留开发痕迹，提升仓库与产品完成度。

### 中期重点

- 完成 CLI 基线；
- 收口参考提取与可复用知识链路；
- 强化多角色运行时的实际分工；
- 继续做拆书到派生项目的闭环；
- 让信息收集与研究调用更加可靠。

### 后续方向

- Docker 化长运行形态；
- 更强的结构化知识体系；
- 更好的导入与 ingestion 支持；
- 视情况评估 TUI；
- 扩展更多项目类型与转换路径。

## 仓库结构

```text
apps/
  novel_agent_app/       Flutter GUI 应用
  novel_agent_cli/       CLI 应用（进行中）

packages/
  novel_agent_core/      共享领域合同与工作流逻辑
  novel_agent_adapters/  存储、Provider、运行时与宿主适配

docs/                    架构、分析与正式说明文档
tools/                   仓库工具与辅助脚本
local/                   本地私有文件，默认不提交
dist/                    本地构建产物，默认不提交
```

## 构建与运行

先安装 Flutter，然后：

```powershell
cd apps/novel_agent_app
flutter pub get
flutter analyze
flutter run
```

发布构建：

```powershell
flutter build windows --release
flutter build apk --release
```

当前 Android release signing 已改为显式配置模式，需要本地环境提供签名材料。

## 安全与本地密钥

请不要提交以下内容：

- API Key；
- Provider 凭据；
- `.env` 类本地私密配置；
- 带真实凭据的 probe 配置；
- 包含隐私数据的临时实验文件。

敏感材料应保留在 `local/` 等忽略路径中。

## 文档说明

仓库里仍保留了一批分析文档，因为这个项目在较长时间内一直处于快速演化和多轮收口中。  
这意味着它更像一个正在持续打磨的开源工作现场，而不是极简、定稿、轻装的成品仓库。

## 协议

Apache License 2.0，详见 [LICENSE](LICENSE)。

## 贡献方向

当前阶段最有价值的贡献通常是这些：

- 稳定性修复；
- 运行链路验证；
- 职责边界清理；
- GUI 易用性提升；
- 信息沉淀与复用能力增强；
- 更可靠的测试；
- 持续清理开发遗留粗糙处。

## 支持项目

如果你觉得这个项目的方向对你有帮助，并且愿意支持它继续迭代，可以自愿请作者喝杯饮料。  
这不是功能承诺、商业服务或使用门槛，只是一个谨慎放在这里的自愿支持入口。

### 微信
<table>
  <tr>
    <td align="center">
      <strong>微信</strong><br />
      <img src="docs/assets/donation/wechat-pay.jpg" alt="微信收款码" width="260" />
    </td>
    <td align="center">
      <strong>支付宝</strong><br />
      <img src="docs/assets/donation/alipay-pay.jpg" alt="支付宝收款码" width="260" />
    </td>
  </tr>
</table>

---

## English

[Back to Chinese](#中文说明)

NovelAgentFlutter is a local-first AI novel workspace. Its goal is to bring projects, chapters, constraints, references, deconstruction outputs, information persistence, sessions, and long-running generation into one evolving writing environment instead of stopping at a one-prompt-one-chapter tool.

> **Status: still under development.**
>
> This repository should currently be understood as an actively evolving open-source project, not a finished product.
> The GUI is already testable to a meaningful degree, the CLI is still incomplete, and autonomous long-task generation is still being stabilized.

## What This Project Is Trying To Do

The goal here is not just to wrap model calls in a UI. The real target is a project-oriented workflow for long-form writing:

- treat a novel as a durable project rather than a disposable chat;
- let ordinary writing, long-task writing, deconstruction, and follow-up workflows reuse the same core contracts where possible;
- turn constraints, references, context, and project assets into durable inputs instead of rebuilding everything from scratch every round;
- preserve clean enough boundaries for future CLI, Docker, extraction, and knowledge-oriented workflows.

In short, this repo is closer to a writing engineering workspace than a single-turn generator.

## Current State

### Areas that already have real foundations

- the Flutter GUI shell exists;
- Windows and Android build pipelines work;
- the shared `core + adapters + app/cli shell` architecture is real;
- ordinary project writing flows are much more usable than before;
- long-task runtime, supervision/control, checkpoint, and recovery directions already have formal implementation groundwork;
- deconstruction and derived writing are no longer just ideas;
- project information, expression constraints, and asset-related directions have real landing points.

### Areas that should not be overclaimed

- this is not a polished product;
- unattended long-task stability is still not strong enough;
- the CLI is still unfinished;
- information extraction and reusable knowledge are not fully closed;
- several advanced writing modes are still in analysis, evolution, or partial implementation.

## What Is Already Implemented

### 1. GUI application foundation

The GUI currently covers:

- project creation and opening;
- a workbench shell;
- session-style writing entry;
- project asset and constraint surfaces;
- agent ecosystem configuration surfaces;
- long-task runtime views;
- Markdown editing and reading surfaces;
- Windows / Android packaging.

This is already enough for real user-flow testing, though it still needs more polish around naturalness, consistency, and edge cases.

### 2. Shared architecture

The repository is no longer split into disconnected app-specific logic. It explicitly uses:

- `packages/novel_agent_core`
- `packages/novel_agent_adapters`
- `apps/novel_agent_app`
- `apps/novel_agent_cli`

This is one of the most important achievements in the repo so far, because it helps prevent future iteration from collapsing into duplicated business centers.

### 3. Ordinary writing flow

Ordinary writing already has a meaningful baseline:

- session-driven writing flow;
- project context and asset consumption;
- chapter delivery;
- draft and chapter persistence;
- initial hookup for chapter length and expression constraints;
- formal interaction with project files through tools.

This path is close to being genuinely testable, but still not ready to be presented as a finished product.

### 4. Long-task runtime foundation

The long-task side already has:

- run records and runtime identity;
- queue / pause / resume / checkpoint-related contracts;
- supervisor / control-plane directions;
- review / repair / diagnosis groundwork;
- GUI / CLI consumption of part of runtime state;
- probe and regression infrastructure.

Architecturally this area is already fairly substantial, but it is still one of the main real-world risk zones.

### 5. Deconstruction and derived-writing groundwork

The repo already includes:

- a deconstruction project flow;
- follow-up route planning foundations;
- derived project creation groundwork;
- persistence for deconstruction outputs and follow-up continuity directions.

This is no longer only conceptual, but it is not yet at the level where complex source works can be claimed to transfer reliably.

### 6. Project information layer

A shared information substrate is already being formed for:

- project assets;
- style and expression constraints;
- reference extraction outputs;
- research materials and reusable knowledge directions;
- future knowledge-card and structured reference systems.

Its importance is simple: the system should not rely on last-minute model recall every time if information can be preserved and reused.

## What Is Still Incomplete Or Evolving

### Long-task stability

This is still the main unfinished problem.  
Even though runtime, supervision, and control layers exist, the project still needs more work on:

- stable multi-chapter continuation;
- automatic retry / pause / resume behavior;
- actual review and constraint enforcement in longer chains;
- edge cases where a run appears started but does not continue correctly.

### CLI

The CLI is no longer empty, but still unfinished. It still needs:

- broader command coverage;
- better operator ergonomics;
- more complete alignment with shared runtime capabilities;
- clearer automation and diagnostic workflows.

### TUI

Not started yet.  
The more reasonable order still seems to be:

1. keep stabilizing GUI and shared core;
2. finish the CLI baseline;
3. then evaluate whether a TUI is worth building.

### Docker

Docker support is planned, especially for long-running and extraction-heavy workflows, but it is not finished yet.

### Information extraction and reusable knowledge

This direction is still evolving and not complete:

- stable extraction from imported source works;
- reusable structured knowledge for future projects;
- retained source traceability;
- a better balance between project-local knowledge and reusable knowledge;
- stronger research-oriented writing support.

### Other advanced writing modes

These directions are still not fully closed:

- IF branches / alternate lines;
- supporting-character or side-route perspectives;
- style extraction and reuse;
- fanfiction / derivative information systems;
- mythology, astrology, symbolic systems, naming systems, and other element embedding / extraction directions;
- commentary, summary, or storyteller-style workflows for existing text.

## Design Bets Worth Keeping

I would describe these as design bets rather than exaggerated claims of proven innovation:

### 1. Project as workspace

The core unit is not a single prompt but a project with files, assets, constraints, references, runtime state, and accumulated knowledge.

### 2. Shared core across GUI and CLI

GUI and CLI are constrained to remain shells over the same core contracts, instead of growing into duplicated business logic stacks.

### 3. Constraint layer as formal infrastructure

Project constitution, mode guidance, style guidance, and expression constraints are moving toward a formal layered model instead of remaining scattered prompt fragments.

### 4. Long-task treated as a real runtime problem

Long-task generation is not just “call the model many times”. It needs runtime identity, supervision, checkpoints, pause/resume, diagnosis, and recovery strategy.

### 5. Deconstruction and follow-up writing inside one system

Deconstruction, continuation, and derived writing are gradually being brought into the same project and information model.

### 6. Information reuse over repeated context stuffing

The direction is to preserve useful information as project assets or future structured knowledge instead of repeatedly overloading the context window.

## Roadmap

### Near term

- continue stabilizing long-task behavior;
- continue fixing real GUI user-flow issues;
- strengthen approval and recovery continuity;
- strengthen session continuity and context handling;
- keep cleaning up development leftovers that hurt product and repo quality.

### Mid term

- finish the CLI baseline;
- close more of the reference extraction and reusable knowledge pipeline;
- improve real runtime role separation;
- keep closing the loop from deconstruction to derived project workflows;
- make information collection and research invocation more reliable.

### Later

- Docker-oriented long-running runtime support;
- stronger structured knowledge systems;
- better import and ingestion support;
- TUI evaluation if still worthwhile;
- broader project types and project-type conversion paths.

## Repository layout

```text
apps/
  novel_agent_app/       Flutter GUI app
  novel_agent_cli/       CLI app (in progress)

packages/
  novel_agent_core/      shared domain contracts and workflow logic
  novel_agent_adapters/  storage, provider, runtime, and host adapters

docs/                    architecture and formal analysis docs
tools/                   repository utilities and helper scripts
local/                   local private files, ignored by default
dist/                    local build outputs, ignored by default
```

## Build and run

Install Flutter first, then:

```powershell
cd apps/novel_agent_app
flutter pub get
flutter analyze
flutter run
```

Release builds:

```powershell
flutter build windows --release
flutter build apk --release
```

Android release signing now expects explicit local signing configuration.

## Security and local secrets

Please do not commit:

- API keys;
- provider credentials;
- local `.env` style secret files;
- probe configs with real credentials;
- temporary experimental files containing private data.

Sensitive material should stay under ignored local paths such as `local/`.

## About the docs

The repository still keeps a number of analysis documents because this project has gone through many rounds of rapid evolution and structured closeout work.  
That means it is still closer to an actively refined open-source workshop than a minimal polished final-form repository.

## License

Apache License 2.0. See [LICENSE](LICENSE).

## Contribution notes

The most valuable contributions at this stage are usually:

- stability fixes;
- runtime verification;
- responsibility-boundary cleanup;
- GUI usability improvements;
- stronger information persistence and reuse;
- more reliable testing;
- continued cleanup of rough development leftovers.

## Support

If you find this project direction helpful and would like to support its continued development, you can optionally buy the author a drink.  
This is not a feature promise, a service contract, or a usage requirement. It is only a cautious, voluntary support option.

### WeChat Pay
<table>
  <tr>
    <td align="center">
      <strong>WeChat Pay</strong><br />
      <img src="docs/assets/donation/wechat-pay.jpg" alt="WeChat Pay QR" width="260" />
    </td>
    <td align="center">
      <strong>Alipay</strong><br />
      <img src="docs/assets/donation/alipay-pay.jpg" alt="Alipay QR" width="260" />
    </td>
  </tr>
</table>
