# 变更日志

`novel-control-station` 的重要变更都会记录在这个文件中。

## 0.2.4 - 2026-03-25

### 新增

- 段落控制现已正式进入主技能流程，默认启用 `web-serial-natural`，并允许项目级或章节级切换到 `long-paragraph`。
- 长篇项目目录现已把 `chapters/` 与 `control-cards/` 作为标准真值层的一部分，要求按章落盘正文与章节控制卡。
- marathon runner 现已在提示词层强制要求“直接写回项目文件”，并支持 `FileWriteBlocked` 显式停止信号。

### 变更

- `assets/codex-continue-novel.ps1` 现已默认使用 UTF-8 控制台、UTF-8 BOM 日志初始化和最高权限启动参数，减少 Windows 下中文乱码与权限不足导致的续写失败。
- runner 现已在每轮执行前后比对项目文件快照；如果会话只在标准输出返回内容、没有真正写盘，会直接停止而不是误判为成功。
- `README.md` 与 `RELEASE_NOTES.md` 现已同步记录段落模式、标准章节目录和 marathon 写回保护逻辑。

## 0.2.3 - 2026-03-25

### 变更

- `SKILL.md` 现已把 style balance、internalized strengths、support style boundary、style intensity、pseudo-style drift 正式接入 startup 访谈、章节读取和 style module loading 主流程。
- `references/quality-and-writeback-checks.md` 现已允许 bridge / recovery / quiet chapters 通过“加重压力、重排位置、深化代价”达标，而不是强迫每章都做高烈度外部推进。
- `references/chapter-control-card.md` 现已把章节最低标准从僵硬推进改为“常态推进 + 安静章节的合法低烈度路径”。

## 0.2.2 - 2026-03-24

### 新增

- `references/style-modules/index.md` 现已加入平衡型风格强化总提示，把热门连载、长销类型和高口碑小说反复验证过的共通强项内化为统一风格驱动。
- 七个风格模块 `core.md` 现已新增 `内化优势`、`风格强化提示`、`本章优先兑现`、`常见伪风格` 四层提示，用于直接驱动章节写作而非只提供原则说明。
- `references/chapter-control-card.md` 现已新增 style intensity、active style drivers、style payoff 和 pseudo-style drift 记录位。

### 变更

- `references/document-templates.md` 现已把 style balance、internalized strengths、support style boundary、chapter-level intensity、pseudo-style drift 纳入 `09-style-guide.md`。
- `references/interview-and-handoff-flow.md` 现已要求在访谈阶段确定风格平衡目标、要吸收的成熟优点，以及要避免的伪风格滑坡。
- `README.md` 现已同步说明风格模块从“风格路由”升级为“风格路由 + 风格强化”。

## 0.2.1 - 2026-03-24

### 新增

- 真实性修订新增“去分析腔 / 去过度专业术语”控制，默认清理普通读者难以越过、且没有剧情收益的专业词、行业黑话和概念化表达。
- `references/authenticity-and-de-ai-pass.md` 现已补充中文前后对照示例，并细化 AI 套话、假深刻、工整句式、空结论和专业术语的处理动作。

### 变更

- `SKILL.md` 现已把危险 AI 词壳、术语容忍度和必须保留的专业 / 时代 / 设定词，纳入 startup 访谈、章节真实性修订和 post-pass recheck。
- `references/style-modules/literary/language-health.md` 现已明确文学性不等于理论词密度、专业词堆叠或评论腔。
- `references/document-templates.md` 现已明确 `09-style-guide.md` 中 language taboos、authenticity guardrails、voice preservation notes 的词汇控制职责。
- `README.md` 现已同步说明修订层新增的去分析腔与去过度专业化能力。

## 0.2.0 - 2026-03-21

### 新增

- 项目级章节标题控制，包括命名体系锁定、章节控制卡中的标题候选，以及成稿后的题章贴合度复核。
- marathon 启动交接流程，包括 `assets/codex-continue-novel.ps1` 模板和项目根目录 runner 生成。
- 章节标题、质量/回写复核、读者留存失败模式、marathon 启动交接等补充控制参考文档。
- 扩展后的内部风格模块参考集，覆盖幽默、悬念、推理、爱情、恐怖、奇幻和文学风格。

### 变更

- `README.md` 现已记录章节标题流程、内部风格模块调度，以及 marathon runner 启动说明。
- `SKILL.md` 现已将章节标题、章节回写和 marathon handoff 纳入一等工作流阶段。
- `references/document-templates.md` 现已记录章节标题设置，以及激活主风格的兑现预期。
- 内部风格模块已从简短路由说明改写为可操作的创作参考文档，补齐了子类型覆盖、修订检查和更柔性的自适应约束。

### 移除

- 发布树中的 `tests/` 目录及其测试脚本。
- 发布树中的 `evals/` 评测目录及场景文件。
- 本次开发阶段生成的 `docs/plans/` 实施计划草稿。

## 0.1.0 - 2026-03-19

首次公开发布。

### 新增

- 面向中文长篇小说规划、创作、修补和续写的单入口控制工作流。
- 以标准项目文件、动态状态更新和审计日志为核心的文档驱动小说架构。
- 先完整大纲、后正文的工作流，包括访谈、对齐、人物档案和逐章推进。
- 面向主线、支线、关系线、伏笔线和世界规则连续性的多线结构控制。
- 内建图式召回层，用于复杂项目的图结构检索，但不替代规范项目文件。
- 章节控制卡、遗忘元素监测、线热度检查和防漂移连续性保护。
- 面向悬念、幽默、爱情、文学、历史等题材参考的风格调度设计。
- 以保留中文质感、人物声音和叙事身份为目标的真实性与去 AI 修订流程。
- 可逐章持续推进，直到按既定大纲自然收束的 marathon 创作模式。

### 打包

- 面向公开使用者的 `README.md`，采用产品式定位说明。
- 基于 MIT 的 `LICENSE`。
- 用于发布概览和使用提示的 `RELEASE_NOTES.md`。
