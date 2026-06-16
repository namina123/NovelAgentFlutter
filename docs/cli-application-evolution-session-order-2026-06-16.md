# NovelAgentFlutter CLI 应用完善任务顺序文档

最后更新：2026-06-16

主线代号：`CLIX`（CLI Evolution / Productization）

关联主要分析文档：

- `docs/important/cli-application-evolution-analysis-2026-06-16.md`

关联历史任务顺序文档：

- `docs/context-token-budget-and-compaction-session-order-2026-06-14.md`
- `docs/system-unification-and-book-deconstruction-session-order-2026-06-15.md`
- `docs/continuous-task-control-and-reference-substrate-session-order-2026-06-08.md`
- `docs/full-module-sweep-collaboration-session-order-2026-06-09.md`

关联项目约束：

- `agent.md`
- `docs/architecture.md`
- `docs/cli-release-boundary-2026-06-05.md`
- `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`
- `local/cleanup_backups/2026-06-04T11-31-43/untracked_files/docs/task-order-document-generation-prompt-template.md`

关联代码锚点：

- `apps/novel_agent_cli/bin/`
- `apps/novel_agent_cli/lib/bootstrap/`
- `apps/novel_agent_cli/lib/commands/`
- `apps/novel_agent_cli/lib/output/`
- `apps/novel_agent_cli/test/`
- `packages/novel_agent_core/lib/src/session/`
- `packages/novel_agent_core/lib/src/workflow/`
- `packages/novel_agent_core/lib/src/tools/`
- `packages/novel_agent_core/lib/src/agents/`
- `packages/novel_agent_core/lib/src/settings/`
- `packages/novel_agent_adapters/lib/src/workflow/`
- `packages/novel_agent_adapters/lib/src/runtime/`
- `packages/novel_agent_adapters/lib/src/storage/`

---

## 1. 这份文档解决什么

这份文档要解决的不是“顺手给 CLI 再加几个命令”，而是把当前已经能跑但仍偏 operator shell 的 `apps/novel_agent_cli`，收口成一套真正可持续演化的正式桌面 CLI 应用。

当前 CLI 的真实问题不是没有命令，而是：

```text
底层能力已经不少，
但主路径、会话路径、审批路径、输出协议、自动化路径、诊断路径还没有收束成产品形态。
```

本主线完成后，CLI 应达到：

1. `session` 不再是迁移占位符，而是正式交互主入口。
2. `workflow` 不再只是底层调度操作面，而是同时拥有：
   - 面向用户的稳定命令层
   - 面向排障与维护的 debug/operator 层
3. 审批不再只通过 `workflow pending-research` 特例暴露，而是有统一 `approval` 命令族。
4. CLI 具备专业壳层应有的输出协议：
   - `--json`
   - `--quiet`
   - `--verbose`
   - `--debug`
   - `--no-color`
   - 稳定退出码
5. CLI 能显式支撑：
   - 交互式会话
   - 非交互批处理
   - stdin / pipe
   - headless / CI
6. CLI 内部代码不再继续堆大文件，而是拆成：
   - shared command infrastructure
   - subcommands
   - renderers
   - parsing
   - interactive shell / repl
7. CLI 继续严格遵守：
   - `CLI -> core`
   - `bootstrap -> adapters`
   - 不成为第二业务中心

---

## 2. 与旧文档的关系

### 2.1 这不是另起一套 CLI

本文件不是推翻当前 `novel_agent_cli`，而是在当前基础上演化。

保留的既有事实：

1. `CliBootstrap` 仍是唯一 composition root。
2. `workflow / project / review / asset / template` 的现有命令入口继续保留。
3. CLI 继续复用：
   - `ProjectWorkflowRuntimeService`
   - `ProjectReferenceExtractionRuntimeService`
   - `ProjectPendingResearchActionService`
   - 现有 settings / repository / runtime / projection 合同

### 2.2 它继承哪些旧判断

下列判断继续有效：

1. CLI 是壳层，不是第二个业务核心。
2. `session` 当前确实未接通，不能假装它已经完成。
3. `workflow` 已经有一批真实能力，但暴露方式偏 operator。
4. probe / summary / renderer 必须消费 production 同源合同，不得重建业务事实。
5. CLI 不负责修 provider payload，不负责补 runtime 缺口，不负责自己判断 workflow 该怎么推进。

### 2.3 它替代哪些局部结论

以下文档仍保留历史价值，但后续 CLI 主线以本文件顺序为准：

- `docs/cli-release-boundary-2026-06-05.md`
- `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`

### 2.4 这份文档不处理什么

1. 不在本主线里做完整 TUI 产品化。
2. 不在本主线里重做 GUI 会话壳。
3. 不在本主线里扩写新的业务规则中心。
4. 不在本主线里把 CLI 做成 GUI 的文本镜像。
5. 不为了 CLI 方便而回写 core / adapters 的业务真相。

---

## 3. 已有实现去重审计

## 3.1 已有稳定基础，不重做

以下能力已经存在，应优先复用：

1. `CliBootstrap` 的 adapter / repository / command 组装。
2. `WorkflowCommand` 对共享 runtime 的接线。
3. `ProjectCommand / ReviewCommand / AssetCommand / TemplateCommand` 的轻量壳层结构。
4. `TerminalPrinter` 的基础 stdout/stderr 分流。
5. `WorkflowOutputSummaryService` 的共享合同消费能力。
6. `ProjectWorkflowRuntimeService`、`ProjectReferenceExtractionRuntimeService` 等共享运行时。
7. 上下文压缩、session、approval、tool permission、long task supervisor 等既有 core / adapters 基础。

## 3.2 已有但仍是半成品

这些地方最容易“看起来能用，实际上还不是正式 CLI”：

1. `session` 只是提示，不是真会话入口。
2. `workflow` 的命令面已经很大，但还没有产品层 / debug 层分界。
3. `pending-research` 只是审批特例，不是统一审批系统。
4. 输出主要面向人读，不够脚本友好。
5. 参数解析分散在各命令文件内部。
6. `workflow_command.dart`、`workflow_output_summary_service.dart`、`project_command.dart`、`asset_command.dart` 已明显发胖。
7. 命令测试重点仍集中在 workflow，其他命令族缺少足够回归保护。

## 3.3 真正缺的层

本主线真正要补的是这些层：

1. CLI shared command infrastructure
2. 统一 option / help / exit code / TTY / output contract
3. 正式 `session` 命令族
4. 统一 `approval` 命令族
5. `workflow` 的产品层 / debug 层分界
6. `config` / `doctor` 命令族
7. stdin / pipe / headless 行为模型
8. CLI 级回归矩阵与 probe 收口

---

## 4. 本轮冻结的架构边界

1. CLI 只能做参数解析、终端交互、输出投影、自动化入口，不得成为新的业务规则中心。
2. 任何长任务、提取任务、审批、上下文压缩、工具权限的真实语义，必须继续留在 `core + adapters`。
3. `workflow pending-research` 可以保留兼容过渡，但正式主入口必须迁到统一 `approval` 命令族。
4. `session` 的实现必须消费正式 session / agent / approval / compaction 合同，不能自己硬拼一套聊天状态。
5. `workflow` 的产品化必须建立在当前共享 runtime 之上，不能再造第二套调度器。
6. `project / review / asset / template` 的完善优先做 shared infra 和测试收口，不先盲目扩新功能。
7. CLI 输出协议必须优先抽成共享 shell contract，而不是每个命令自己长 `--json` 特判。
8. CLI 不负责修 provider payload、fake mount success、fake continuity success、fake approval success。
9. 单文件超过 400 行主动复核职责，超过 700 行必须拆；CLI 现有大文件必须尽早拆，不允许继续堆。
10. probe / smoke / test 只能消费 production 同源合同，不允许在 CLI 测试里重新造私有真相源。

---

## 5. 目标终态

完成本主线后，应达到以下终态：

1. CLI 有稳定的 shared command infrastructure。
2. `session` 成为正式 CLI 主入口，至少具备：
   - `start`
   - `resume`
   - `list`
   - `show`
   - `send`
   - `stats`
   - `compact`
   - `stop`
3. `approval` 成为统一审批命令族。
4. `workflow` 同时具备：
   - 用户友好命令层
   - debug/operator 子命名空间
5. 所有正式命令都支持统一输出协议与稳定退出码。
6. CLI 能适应：
   - 交互终端
   - 非交互脚本
   - stdin / pipe
   - headless CI
7. `project / review / asset / template / session / approval / config / doctor` 都有基本回归保护。
8. CLI 目录结构清楚，当前 600~1100 行的大文件被拆到合理职责块。
9. 文档、probe、help、命令命名、退出码、JSON 输出形成一致口径。

---

## 6. Session 数量与顺序设计理由

本主线拆成 `15` 个 session。

顺序设计理由：

1. `CLIX-01` 到 `CLIX-04` 先拆 shared infra 和壳层协议，不让后续新功能继续堆回巨型文件。
2. `CLIX-05` 到 `CLIX-07` 先把现有命令面收口、拆责并补 shared 测试，再开始新增大能力。
3. `CLIX-08` 到 `CLIX-10` 再做 `session`，因为它是 CLI 正式化的关键入口，但不能在旧壳上硬堆。
4. `CLIX-11` 再做 `approval`，避免 `session` 继续和 `pending-research` 私有链耦死。
5. `CLIX-12` 到 `CLIX-13` 收口 `workflow` 产品层、`config` / `doctor`、以及 stdin/headless 自动化协议。
6. `CLIX-14` 到 `CLIX-15` 最后做 probes、回归、handoff 和 release 边界收口。

这条顺序明确避免：

1. 先补 `session` 再回头重拆命令基础设施。
2. 先给每个命令各自加 `--json`、`--verbose`，最后形成十几套壳层协议。
3. 先做产品层 help 与文案，结果底层 shared infra 还没定。
4. 先把审批塞进 `workflow`，让 CLI 永远背着业务特例演化。

---

## 7. 全局执行规则

所有 session 都必须遵守：

1. 每次只完成一个 session，不开启下一任务。
2. 先读本文档、`agent.md`、当前 session 必读文件。
3. CLI 壳层只做：
   - 参数解析
   - 终端交互
   - 输出协议
   - shared runtime / use case 委派
4. 任何发现缺失的业务合同，优先补到 `core / adapters`，不要在 CLI 壳层打补丁。
5. 优先拆大文件、拆 shared infra、拆 renderer / parser / context loader，不继续堆单文件。
6. 每轮都补 focused tests；涉及多命令共享协议时，补 shared tests。
7. probe、smoke、help 与 JSON 输出必须消费 production 同源结果。
8. 不为了 CLI 方便而更改 GUI 事实源、workflow 真相、approval 真相。

---

## 8. Sessions

## CLIX-01 CLI 壳层基线审计与 shared infra 冻结

- 本轮目标：
  - 冻结 CLI 壳层的 shared infrastructure 边界、命令族职责和后续拆分方向。
- 层级归属：
  - `Documentation / CLI shared boundary audit`
- 必读文件：
  - `docs/important/cli-application-evolution-analysis-2026-06-16.md`
  - `agent.md`
  - `docs/architecture.md`
  - `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart`
  - `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
  - `apps/novel_agent_cli/lib/commands/project/project_command.dart`
  - `apps/novel_agent_cli/lib/commands/asset/asset_command.dart`
- 必须完成：
  1. 明确 CLI 的顶层命令族与职责边界：
     - `session`
     - `workflow`
     - `project`
     - `review`
     - `asset`
     - `template`
     - `approval`
     - `config`
     - `doctor`
  2. 冻结 shared infra 模块草图：
     - command context
     - option parsing
     - output / exit codes
     - TTY / mode detection
     - project/settings/provider loading
  3. 在文档完成记录中写清当前大文件风险与拆分顺序。
- 本轮不要做：
  1. 不改代码行为。
  2. 不开始实现 `session`。
  3. 不引入新命令。
- 验收标准：
  1. 后续每个 session 都能明确知道自己落在哪个 shared module 或命令族里。
  2. 有文档级完成记录，避免 `mini` 后面自由发挥出第二套路由。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-01`。只做 CLI 壳层基线审计与 shared infra 冻结，明确顶层命令族、shared infrastructure 模块、当前大文件拆分顺序。不要改行为、不要实现 session、不要开启下一任务。保持解耦合、单一职责，避免把结论散落进多个命令文件。

## CLIX-02 shared command context / loader / exit code 基础设施

- 本轮目标：
  - 在 CLI 壳层建立统一的 shared command infrastructure 基础骨架。
- 层级归属：
  - `CLI / shared infrastructure`
- 必读文件：
  - `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart`
  - `apps/novel_agent_cli/lib/commands/project/project_command.dart`
  - `apps/novel_agent_cli/lib/commands/review/review_command.dart`
  - `apps/novel_agent_cli/lib/commands/asset/asset_command.dart`
  - `apps/novel_agent_cli/lib/commands/template/template_command.dart`
- 必须完成：
  1. 新建 shared infra 基础对象，例如：
     - `CliCommandContext`
     - `CliProjectContextLoader`
     - `CliSettingsContextLoader`
     - `CliExitCodes`
  2. 把重复的：
     - 打开 settings
     - 打开默认项目
     - provider 存在性检查
     - 基础失败 exit code
     收束到 shared 层。
  3. 给 shared infra 补 focused tests。
- 本轮不要做：
  1. 不做 `--json`。
  2. 不做 `session`。
  3. 不重写 workflow 子命令。
- 验收标准：
  1. 至少两类以上现有命令开始复用 shared loader / exit code。
  2. 没有把 adapter/new repository 直接散落到命令类里。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-02`。只建立 shared command context / loader / exit code 基础设施，并让现有命令开始复用。不要实现 JSON 输出、不要实现 session、不要重写 workflow 命令面，不开启下一任务。注意解耦合，不把 shared infra 写成新的万能大门面。

## CLIX-03 统一 option parsing / help contract / mode detection

- 本轮目标：
  - 收口 CLI 参数解析、帮助文本和交互模式检测的正式合同。
- 层级归属：
  - `CLI / shared infrastructure`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
  - `apps/novel_agent_cli/lib/commands/project/project_command.dart`
  - `apps/novel_agent_cli/lib/output/terminal_printer.dart`
- 必须完成：
  1. 引入统一 option parsing 层：
     - 可用 `package:args`
     - 或自建轻量 parser
     - 但必须全 CLI 共用
  2. 冻结帮助合同：
     - root help
     - command help
     - subcommand help
     - 参数错误提示格式
  3. 新增 TTY / interactive mode 检测服务，为后续 `session`、stdin、headless 做准备。
  4. 补 focused tests：
     - help
     - missing arg
     - unknown arg
     - no TTY / interactive flag 基础行为
- 本轮不要做：
  1. 不做产品文案大改。
  2. 不做真正 REPL。
  3. 不加新命令族。
- 验收标准：
  1. CLI 不再每个命令自己扫 `--flag`。
  2. `help` 和基础 parse 错误行为有统一输出与退出码。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-03`。只统一 option parsing、help contract、TTY / mode detection，给后续 session/headless 做基础。不要做 REPL、不要大改文案、不要加新命令族，不开启下一任务。保持单一职责，避免把 parse/help 逻辑回流进各命令类。

## CLIX-04 输出协议与日志级别基础设施

- 本轮目标：
  - 建立统一输出协议，而不是让各命令各自补 `--json`。
- 层级归属：
  - `CLI / output infrastructure`
- 必读文件：
  - `apps/novel_agent_cli/lib/output/terminal_printer.dart`
  - `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
  - `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`
- 必须完成：
  1. 新增输出协议基础设施，例如：
     - `CliOutputMode`
     - `CliJsonOutputWriter`
     - `CliLogLevel`
     - `CliProgressReporter`
  2. 冻结正式 flags：
     - `--json`
     - `--quiet`
     - `--verbose`
     - `--debug`
     - `--no-color`
  3. 统一 stdout/stderr 规则。
  4. 给 shared output 层补 focused tests。
- 本轮不要做：
  1. 不把所有命令都一次性改完。
  2. 不重构 workflow 业务摘要逻辑。
  3. 不做 session。
- 验收标准：
  1. 输出协议层独立存在，可被后续各命令复用。
  2. 至少有最小 smoke test 证明 JSON / text 两套模式可切换。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-04`。只建立统一输出协议与日志级别基础设施：`--json / --quiet / --verbose / --debug / --no-color`，以及 stdout/stderr 规则。不要一次性改完所有命令、不要实现 session、不启动下一任务。注意让协议层可复用，不要写成 workflow 私有输出逻辑。

## CLIX-05 workflow summary/renderer 拆责

- 本轮目标：
  - 把 `workflow_output_summary_service.dart` 从单一巨型摘要文件拆成可维护的 renderer / text service 组合。
- 层级归属：
  - `CLI / renderer`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
  - `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`
- 必须完成：
  1. 按职责拆分至少这些部件：
     - `RunCenterSummaryRenderer`
     - `NarrativeRuntimeSummaryRenderer`
     - `ReferenceExtractionSummaryRenderer`
     - `ExpressionConstraintSummaryRenderer`
     - `StopDiagnosisTextService`
  2. 保持现有 CLI 摘要口径与测试通过。
  3. 新增 focused tests 覆盖拆分后的关键 text mapping。
- 本轮不要做：
  1. 不新增命令功能。
  2. 不重写 workflow 行为。
  3. 不补 session。
- 验收标准：
  1. 旧测试继续通过。
  2. 摘要逻辑不再挤在一个近千行文件里。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-05`。只拆 `workflow_output_summary_service.dart` 的职责，把 run center、narrative、reference extraction、expression constraint、stop diagnosis 拆成独立 renderer/text service，同时保持现有摘要口径与测试全绿。不要加新命令，不启动下一任务。

## CLIX-06 workflow command root / subcommands / parsing 拆责

- 本轮目标：
  - 把 `workflow_command.dart` 拆成 root dispatch + subcommands + parsing，而不改变既有行为。
- 层级归属：
  - `CLI / workflow shell`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
  - `apps/novel_agent_cli/test/workflow_command_test.dart`
  - `docs/cli-release-boundary-2026-06-05.md`
- 必须完成：
  1. `workflow_command.dart` 只保留 root dispatch 与最薄壳。
  2. 至少把这些类型分层：
     - draft
     - extract-reference
     - runtime queue / pause / resume
     - checkpoint / revision
     - pending-research（兼容阶段）
  3. 抽出 workflow parsing / selector / common context helper。
  4. 保持现有行为与测试通过。
- 本轮不要做：
  1. 不做产品层新命名。
  2. 不迁移到 `approval`。
  3. 不接 session。
- 验收标准：
  1. `workflow_command.dart` 体量明显下降。
  2. 现有 workflow tests 继续通过。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-06`。只拆 `workflow_command.dart` 为 root dispatch + subcommands + parsing，共享原有行为和测试口径。不要改产品命名、不迁 approval、不做 session，不开启下一任务。保持解耦合，避免把新 subcommand 再堆成一个次级巨型文件。

## CLIX-07 project / review / asset / template infra 收口与测试补齐

- 本轮目标：
  - 让非 workflow 命令族也接入 shared infra，并补最基本的回归矩阵。
- 层级归属：
  - `CLI / command convergence`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/project/project_command.dart`
  - `apps/novel_agent_cli/lib/commands/review/review_command.dart`
  - `apps/novel_agent_cli/lib/commands/asset/asset_command.dart`
  - `apps/novel_agent_cli/lib/commands/template/template_command.dart`
- 必须完成：
  1. 让这几类命令统一复用：
     - shared context loader
     - output protocol
     - exit codes
     - parse/help contract
  2. 视需要拆分 `project_command.dart`、`asset_command.dart` 的子命令职责。
  3. 补齐最小测试：
     - `project_command_test.dart`
     - `review_command_test.dart`
     - `asset_command_test.dart`
     - `template_command_test.dart`
- 本轮不要做：
  1. 不新增业务能力。
  2. 不做 session / approval。
  3. 不改 workflow 产品层命名。
- 验收标准：
  1. 非 workflow 命令族不再游离在 shared infra 之外。
  2. 至少形成最小回归保护面。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-07`。只收口 project/review/asset/template 到 shared infra，并补它们的最小回归测试。不要新增业务能力、不要做 session/approval、不启动下一任务。注意复用 shared loader/output/exit code，而不是各自长私有壳层。

## CLIX-08 session 命令所需的 core/adapters/use case 支撑

- 本轮目标：
  - 为 CLI `session` 正式入口补齐缺失的共享支撑合同与 use case，而不是在 CLI 内自己攒状态。
- 层级归属：
  - `Core / Adapters / session bridge`
- 必读文件：
  - `packages/novel_agent_core/lib/src/session/`
  - `packages/novel_agent_core/lib/src/agents/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
  - `apps/novel_agent_cli/lib/commands/session/session_command.dart`
- 必须完成：
  1. 审计并补齐 CLI session 需要的共享入口，至少覆盖：
     - list sessions
     - load session
     - send one round
     - session stats / context pressure
     - compact now
     - stop/close session
  2. 如缺失，新增最小 use case / runtime facade / repository query port。
  3. 这些入口必须复用既有 session / compaction / agent / tool / approval 合同。
  4. 补 focused tests。
- 本轮不要做：
  1. 不写 CLI REPL。
  2. 不在 CLI 命令层临时拼会话状态。
  3. 不做 approval 命令族。
- 验收标准：
  1. CLI 后续可以直接调用正式 use case / facade 启动 session 命令，而不是靠占位符。
  2. 不新增第二套会话真相源。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-08`。只补齐 CLI session 所需的 core/adapters/use case 支撑：list/load/send/stats/compact/stop，并复用既有 session/compaction/agent/tool/approval 合同。不要写 REPL、不要在 CLI 临时拼状态、不要做 approval 命令族，不开启下一任务。

## CLIX-09 session 非交互命令族

- 本轮目标：
  - 把 `session` 从占位符做成正式的非交互命令族。
- 层级归属：
  - `CLI / session shell`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/session/session_command.dart`
  - `packages/novel_agent_core/lib/src/session/`
  - `docs/important/cli-application-evolution-analysis-2026-06-16.md`
- 必须完成：
  1. 至少实现：
     - `session list`
     - `session show`
     - `session resume`
     - `session send`
     - `session stats`
     - `session compact`
     - `session stop`
  2. 与 shared output / exit code / parse contract 对齐。
  3. `session send` 必须能走正式 one-round agent 链，而不是自己写 prompt 拼装。
  4. 补 `session_command_test.dart`。
- 本轮不要做：
  1. 不做交互式 REPL。
  2. 不加 slash commands。
  3. 不把 session 做成 GUI 文本翻版。
- 验收标准：
  1. `session` 不再只打印迁移提示。
  2. 非交互命令族可用于脚本和单轮用户调用。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-09`。只实现 session 的非交互命令族：list/show/resume/send/stats/compact/stop，并补 `session_command_test.dart`。不要做 REPL、不要加 slash commands、不启动下一任务。确保 `session send` 走正式共享链，不要在 CLI 里自己拼 prompt 或上下文。

## CLIX-10 session 交互 REPL 与 slash command

- 本轮目标：
  - 给 `session` 增加最小交互循环和必要的 slash commands。
- 层级归属：
  - `CLI / session interactive shell`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/session/`
  - `apps/novel_agent_cli/lib/output/`
  - `packages/novel_agent_core/lib/src/session/`
- 必须完成：
  1. 实现 `session start` 进入交互会话循环。
  2. 最小支持 slash commands：
     - `/help`
     - `/model`
     - `/group`
     - `/approval`
     - `/compact`
     - `/stats`
     - `/exit`
  3. 交互会话必须复用 `session send` 正式执行链。
  4. 补 focused tests / smoke tests。
- 本轮不要做：
  1. 不做复杂多窗格 TUI。
  2. 不引入 GUI 式状态机。
  3. 不把工具事件流做成另一套 runtime。
- 验收标准：
  1. CLI 已具备最小真正 agent 交互入口。
  2. slash command 只做壳层控制，不承载新业务规则。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-10`。只实现 session 交互 REPL 与最小 slash commands，复用前一轮的正式 session 执行链。不要做 TUI、多窗格或新的 runtime，不开启下一任务。注意 slash commands 只是壳层动作，不要承载新的业务判断。

## CLIX-11 统一 approval 命令族与 pending-research 迁移

- 本轮目标：
  - 把审批从 workflow 特例提升为统一 CLI 命令族。
- 层级归属：
  - `CLI / approval shell`
- 必读文件：
  - `packages/novel_agent_core/lib/src/tools/`
  - `packages/novel_agent_adapters/lib/src/workflow/`
  - `apps/novel_agent_cli/lib/commands/workflow/`
- 必须完成：
  1. 新增 `approval` 命令族：
     - `approval list`
     - `approval show`
     - `approval approve`
     - `approval reject`
     - 如条件允许，`approval policy show`
  2. 将 `pending-research` 能力迁到统一 approval 路径，旧入口保留兼容或薄转发。
  3. 统一审批显示字段与输出合同。
  4. 补 `approval_command_test.dart`。
- 本轮不要做：
  1. 不重新发明 approval 数据结构。
  2. 不把审批逻辑塞回 workflow。
  3. 不做 GUI 审批页。
- 验收标准：
  1. CLI 有统一审批入口。
  2. `pending-research` 不再是长期唯一正式审批壳层。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-11`。只实现统一 approval 命令族，并把 pending-research 从 workflow 特例迁到 approval 主入口，旧入口仅保留兼容或薄转发。不要重造数据结构、不要把审批逻辑塞回 workflow、不启动下一任务。

## CLIX-12 workflow 产品层 / debug 层分层

- 本轮目标：
  - 把当前 `workflow` 的命令面分成用户友好层与 debug/operator 层。
- 层级归属：
  - `CLI / workflow productization`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/workflow/`
  - `docs/cli-release-boundary-2026-06-05.md`
  - `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`
- 必须完成：
  1. 设计并落地：
     - 用户层：`start / status / continue / pause / resume / inspect / logs`
     - debug 层：现有细颗粒命令迁到 `workflow debug ...`
  2. 保持底层共享 runtime 调用不变。
  3. `extract-reference` 与长任务在 CLI 视角下统一成 continuous run family。
  4. 补 workflow 命令帮助与相关测试。
- 本轮不要做：
  1. 不改 runtime 业务真相。
  2. 不做新 supervisor。
  3. 不把提取任务做成第二套命令哲学。
- 验收标准：
  1. CLI 用户看到的 workflow 主命令面比现在更稳定、更像产品。
  2. debug/operator 能力仍然可用，但不再污染主帮助界面。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-12`。只把 workflow 命令面分成用户层和 `workflow debug` 层，并让长任务与提取任务在 CLI 视角下统一成 continuous run family。不要改 runtime 真相、不要发明新 supervisor、不启动下一任务。

## CLIX-13 config / doctor 命令族

- 本轮目标：
  - 给 CLI 补齐正式配置与诊断入口。
- 层级归属：
  - `CLI / config & diagnostics`
- 必读文件：
  - `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart`
  - `packages/novel_agent_core/lib/src/settings/`
  - `packages/novel_agent_adapters/lib/src/storage/`
- 必须完成：
  1. 新增 `config` 命令族，至少覆盖：
     - `show`
     - `get`
     - `set`
     - `provider list`
  2. 新增 `doctor` 命令族，至少覆盖：
     - provider 配置检查
     - 默认项目路径检查
     - CLI 环境 / 写权限 / 基础 capability 检查
  3. 输出合同接入统一 JSON / text 模式。
  4. 补 `config_command_test.dart` 与 `doctor_command_test.dart`。
- 本轮不要做：
  1. 不做 GUI 设置。
  2. 不把 doctor 变成万能排障脚本集合。
  3. 不顺手改业务逻辑。
- 验收标准：
  1. CLI 用户可以用正式命令检查配置与环境，不用靠读代码猜。
  2. doctor 是稳定壳层，不是临时 probe。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-13`。只实现 config/doctor 命令族及其测试，让 CLI 能正式查看配置与做基础诊断。不要改 GUI 设置、不要把 doctor 变成临时脚本集合、不启动下一任务。

## CLIX-14 stdin / pipe / headless / non-interactive 收口

- 本轮目标：
  - 让 CLI 真正能服务自动化、脚本和 CI，而不只是在交互终端里能跑。
- 层级归属：
  - `CLI / automation boundary`
- 必读文件：
  - `apps/novel_agent_cli/lib/commands/session/`
  - `apps/novel_agent_cli/lib/commands/workflow/`
  - `apps/novel_agent_cli/lib/output/`
- 必须完成：
  1. 明确并落地：
     - stdin 输入
     - pipe 读取
     - `--non-interactive`
     - `--yes`
     - no-TTY fail-fast
  2. 至少让这些主路径支持 headless：
     - `session send`
     - `workflow` 主入口中最关键的非交互命令
     - `approval approve/reject`
  3. 补 non-interactive / stdin tests。
- 本轮不要做：
  1. 不做 shell completion。
  2. 不做跨平台 installer。
  3. 不改核心业务真相。
- 验收标准：
  1. CLI 可在无 TTY 环境下给出稳定行为。
  2. stdin / pipe 不再需要各命令私有特判。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-14`。只收口 stdin / pipe / headless / non-interactive 行为，覆盖 `session send`、关键 workflow 命令、approval approve/reject，并补相应测试。不要做 shell completion、不启动下一任务。

## CLIX-15 回归、probes、handoff 与 release 边界收口

- 本轮目标：
  - 用 production 同源命令链做最终 CLI 验收，并留交接文档。
- 层级归属：
  - `Probe / regression / Documentation`
- 必读文件：
  - 本文档
  - `docs/important/cli-application-evolution-analysis-2026-06-16.md`
  - `docs/cli-release-boundary-2026-06-05.md`
  - 前面各 session 改动涉及的测试
- 必须完成：
  1. 跑完整 CLI analyze/test。
  2. 补或更新 smoke / probe：
     - root help
     - workflow help
     - session help
     - approval help
     - session resume smoke
     - workflow pause/resume smoke
     - approval approve/reject smoke
     - extract-reference smoke
  3. 明确 release boundary：
     - 哪些命令是正式主入口
     - 哪些仍是 debug/operator
  4. 输出一份 handoff：
     - 当前 CLI 主链
     - 残留风险
     - TUI 后续接入点
- 本轮不要做：
  1. 不再扩新命令面。
  2. 不重写分析文档。
  3. 不把 probe 变业务中心。
- 验收标准：
  1. CLI 主链可以被文档、help、tests、smoke 一致证明。
  2. 有清楚的 release boundary 与下一阶段入口。
- 直接可用提示词：
  - 根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 执行 `CLIX-15`。只做最终 regression、smoke/probe、handoff 与 release boundary 收口：验证 session、workflow、approval、config/doctor、输出协议与非交互路径都能通过 production 同源主链证明。不要扩新命令、不重写分析文档、不开启下一任务。

---

## 9. 总启动提示词

```text
根据 `docs/cli-application-evolution-session-order-2026-06-16.md` 按顺序执行 CLI 应用完善主线。

严格要求：

1. 每次只完成一个 session。
2. 先读本文档、`agent.md`、当前 session 必读文件。
3. 只做当前 session 写明的内容，完成并确认后再进入下一任务。
4. 必须坚持：
   - CLI 只是壳层，不成为第二业务中心
   - 任何审批、会话、长任务、提取任务、上下文压缩、工具权限真相都留在 `core + adapters`
   - 先拆 shared infra 和大文件，再补 session/approval/productization
   - probe / smoke / summary 只消费 production 同源合同
   - 不让 `workflow pending-research` 继续成为长期审批主入口
   - 不让 `session` 再停留在占位符状态
5. 所有实现都要补 focused tests；涉及命令族时补命令测试，涉及 shared 协议时补 shared tests，涉及 smoke 时补 CLI probe 或 help/JSON 回归。
6. 遇到单文件继续膨胀时，优先拆 parser / renderer / subcommand / shared loader，不要硬堆。
7. 最终目标必须真正达成：CLI 成为一套同时支持会话、审批、长任务、提取任务、配置诊断、自动化脚本、稳定输出协议的正式桌面 CLI 应用。
```

---

## 10. 完成记录占位

- `CLIX-01`：
- `CLIX-01`: 已完成 CLI 壳层基线审计与 shared infra 冻结；确认顶层命令族应稳定收束为 `session / workflow / project / review / asset / template / approval / config / doctor`；shared infra 草图已冻结为 `command context / option parsing / output + exit codes / TTY + mode detection / project + settings + provider loading`；当前大文件拆分顺序已明确为先拆 `workflow_output_summary_service.dart`，再拆 `workflow_command.dart`，随后收口 `project_command.dart` 与 `asset_command.dart`，最后补 `session / approval / config / doctor` 的壳层与测试面。变更范围仅限文档记录，未改代码行为；下一步是 `CLIX-02` 建立 shared command context / loader / exit code 基础设施。
- `CLIX-02`: 已建立 shared command context / loader / exit code 基础设施；新增 `CliCommandContext`、`CliSettingsContextLoader`、`CliProjectContextLoader`、`CliExitCodes`，并让 `project / review / asset / template` 复用共享项目上下文加载入口，CLI bootstrap 也改为先构建共享 settings context 再注入项目 loader。已补 `apps/novel_agent_cli/test/shared/cli_context_loaders_test.dart` 覆盖 settings/project loader 与 exit code 回归；验证通过 `dart analyze` 与 `dart test`。下一步进入 `CLIX-03`，统一 option parsing / help contract / mode detection。
- `CLIX-03`: 已统一 option parsing / help contract / mode detection；新增 `CliArguments`、`CliHelpContract`、`CliModeDetectionService`，并让 `workflow / project / review / asset / template` 的 flag 读取转发到共享 parser，root help 与各命令 help 也统一走共享格式器。已补 `apps/novel_agent_cli/test/shared/cli_arguments_test.dart`、`apps/novel_agent_cli/test/shared/cli_help_contract_test.dart`、`apps/novel_agent_cli/test/shared/cli_mode_detection_service_test.dart`，并在 `workflow_command_test.dart` 增加 help / unknown subcommand / missing prompt 回归；验证通过 `dart analyze` 与 `dart test`。下一步进入 `CLIX-04`，建立统一输出协议与日志级别基础设施。
- `CLIX-04`: 已建立统一输出协议与日志级别基础设施；新增 `CliOutputMode`、`CliLogLevel`、`CliOutputSettings`、`CliJsonOutputWriter`、`CliProgressReporter`，并让 `CliBootstrap` 解析并剥离 `--json / --quiet / --verbose / --debug / --no-color` 后再分发命令，同时 `TerminalPrinter` 统一 text / JSON 的 stdout/stderr 规则。已补 `apps/novel_agent_cli/test/output/cli_output_protocol_test.dart` 覆盖全局输出 flags、text/json 模式切换、quiet 抑制与 bootstrap help smoke；验证通过 `dart analyze` 与 `dart test`。下一步进入 `CLIX-05`，拆分 `workflow_output_summary_service.dart` 的职责。
- `CLIX-05`: 已完成 `workflow_output_summary_service.dart` 拆责与收口；`WorkflowOutputSummaryService` 现在只保留稳定 façade，实际渲染与文本映射分别下沉到 `RunCenterSummaryRenderer`、`NarrativeRuntimeSummaryRenderer`、`ReferenceExtractionSummaryRenderer`、`ExpressionConstraintSummaryRenderer`、`StopDiagnosisTextService`，避免 CLI 再继续堆积近千行摘要逻辑。已补 `apps/novel_agent_cli/test/workflow_output_run_center_summary_renderer_test.dart`、`apps/novel_agent_cli/test/workflow_output_narrative_runtime_summary_renderer_test.dart`、`apps/novel_agent_cli/test/workflow_output_reference_extraction_summary_renderer_test.dart`、`apps/novel_agent_cli/test/workflow_output_expression_constraint_summary_renderer_test.dart`、`apps/novel_agent_cli/test/workflow_output_stop_diagnosis_text_service_test.dart`，并将原有 `workflow_output_summary_service_test.dart` 收成 façade 兼容回归；验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test test`。下一步进入 `CLIX-06`，继续拆 `workflow_command.dart` 的 root dispatch / subcommand / parsing。
- `CLIX-06`: 已完成 `workflow_command.dart` 的 root dispatch / subcommand / parsing 拆责；`WorkflowCommand` 现在只保留依赖注入与 `run` 薄壳，实际分发已经下沉到 `workflow_command_dispatch.dart`，通用解析与上下文加载下沉到 `workflow_command_parsing.dart`，输出投影下沉到 `workflow_command_output.dart`，而 `draft / extract-reference / pending-research / long-task / checkpoint-revision` 各自拆成独立命令 part 文件。已补 `workflow_command_checkpoint_revision.dart` 作为 checkpoint / revision 细分壳层，保证 `workflow_command_long_task.dart` 回到 400 行以内；验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test test`。下一步进入 `CLIX-07`，继续收口 `project / review / asset / template` 到 shared infra，并补最小回归面。
- `CLIX-07`: 已完成 `project / review / asset / template` 的 shared infra 收口与最小回归补齐；四类命令继续复用 shared project context loader、shared help contract 和 shared exit codes，新增命令测试覆盖 `project help / project summary`、`asset help / asset list`、`review help`、`template help`。期间只发现并修复了一处测试构造缺参：`apps/novel_agent_cli/test/project_command_test.dart` 里 `ImportCustomizationBundleUseCase` 需要显式传入 `generateCustomizationIndexesUseCase`，修正后 `dart analyze apps/novel_agent_cli` 与 `dart test test` 均已通过。残留风险：`project_command.dart` 与 `asset_command.dart` 仍偏大，但目前都已复核且未超过强制拆分阈值；下一步按顺序进入 `CLIX-08`，为 `session` 命令所需的 core/adapters/use case 支撑补缺。
- `CLIX-08`: 已完成 `session` 命令所需的 core/adapters/use case 支撑收口与壳层接通；`ProjectSessionWorkspaceService` 继续作为共享会话读写入口，`ProjectSessionShellService` 统一提供 `list / load(show) / send / stats / compact / stop`，并补齐了 `loadSession` 的正式成功合同 `ok: true`，避免 CLI/测试各自猜测返回结构。`SessionCommand` 现已正确接入 `CliProjectContext`，并保持只做壳层分发，不在 CLI 内拼会话状态；同时把 session CLI 测试调整为只验证正式合同里的 ID、标题、上下文片段与帮助文本，不再绑死会变化的自然语言摘要。已补/更新 `packages/novel_agent_adapters/test/project_session_workspace_service_test.dart`、`packages/novel_agent_adapters/test/project_session_shell_service_test.dart`、`packages/novel_agent_core/test/session_record_normalizer_service_test.dart`、`apps/novel_agent_cli/test/session_command_test.dart`；验证通过 `dart analyze apps/novel_agent_cli packages/novel_agent_adapters packages/novel_agent_core`（仅保留既有 warning）与相关 `dart test`。下一步只进入 `CLIX-09`，把 session 非交互命令族继续正式化，但本轮不再往前推进。
- `CLIX-09`: 已完成 `session` 的非交互命令族正式化；`SessionCommand` 现在明确支持 `session list / show(load) / resume / send / stats / compact / stop`，其中 `resume` 默认回到当前活跃会话，必要时也可显式指定 `--id` / `--session`，并把 stopped 的会话重新投影回该模式的初始可继续阶段。`ProjectSessionShellService` 新增 `resumeSession` 共享入口，继续复用会话工作区索引、session prompt context 和公开摘要合同，不在 CLI 内重建会话生命周期；相应命令帮助、恢复输出、共享 shell 回归与 CLI 命令回归均已补齐。已更新 `apps/novel_agent_cli/test/session_command_test.dart`、`packages/novel_agent_adapters/test/project_session_shell_service_test.dart`，并保持 `packages/novel_agent_adapters/test/project_session_workspace_service_test.dart` 与 `packages/novel_agent_core/test/session_record_normalizer_service_test.dart` 绿灯；验证通过 `dart test`，`dart analyze` 仅保留仓库原有 warnings。下一步才进入 `CLIX-10`，为 `session start` / slash command / REPL 做交互层，但本轮不再前进。
- `CLIX-10`: 已完成 `session` 交互 REPL 与最小 slash commands；`session start` 现在会先恢复当前活跃会话，再进入交互循环，并支持 `/help /model /group /approval /compact /stats /exit`，其中普通输入继续复用正式 `session send` 链，`/compact` 与 `/stats` 则继续消费共享压缩/压力合同。交互壳层被拆入 `apps/novel_agent_cli/lib/commands/session/session_interactive_shell.dart`，`SessionCommand` 只保留最薄分发与壳层装配；已补 `apps/novel_agent_cli/test/session_command_test.dart` 覆盖 start/help/resume/list 与交互输入、slash command、send 链回归，并保持 `packages/novel_agent_adapters/test/project_session_shell_service_test.dart`、`packages/novel_agent_adapters/test/project_session_workspace_service_test.dart`、`packages/novel_agent_core/test/session_record_normalizer_service_test.dart` 绿灯。验证通过 `dart analyze apps/novel_agent_cli` 与相关 `dart test`，仅保留仓库原有 warnings；下一步进入 `CLIX-11`，才把审批从 `workflow` 特例提升为统一 `approval` 命令族。
- `CLIX-11`: 已完成统一 `approval` 命令族与 `pending-research` 迁移；新增 `apps/novel_agent_cli/lib/commands/approval/`，正式提供 `approval list/show/approve/reject/policy show`，其中 `show` 直接读取共享 pending-research 记录加载合同，`policy show` 只投影当前审批壳层边界与真相源。`workflow pending-research` 已改为纯兼容薄转发，不再承载审批分发逻辑，`CliBootstrap` 也已把 `approval` 纳入正式顶层命令树。已补 `apps/novel_agent_cli/test/approval_command_test.dart`、`apps/novel_agent_cli/test/workflow_command_test.dart`、`apps/novel_agent_cli/test/output/cli_output_protocol_test.dart`、`packages/novel_agent_adapters/test/project_pending_research_action_service_test.dart`，并为共享真相源补了 `ProjectPendingResearchActionService.load` 读方法。验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test test/approval_command_test.dart test/workflow_command_test.dart test/session_command_test.dart test/output/cli_output_protocol_test.dart` 及 `packages/novel_agent_adapters/test/project_pending_research_action_service_test.dart`；下一步进入 `CLIX-12`，只做 workflow 产品层 / debug 层分层，不再回头扩审批主链。
- `CLIX-12`: 已完成 workflow 产品层 / debug 层分层；`workflow` 主入口现在只展示 `start / status / continue / pause / resume / inspect / logs / debug` 这些用户层连续运行命令，`workflow debug ...` 则承接原有细颗粒操作，`draft / extract-reference / create / list / next / preflight / chain / plan / prepare / run-once / run-next / run-queue / guidance-status / create-from-guidance / postprocess-once / postprocess-next / complete-next / checkpoint-actions / apply-checkpoint-action / revision-resolution / apply-revision-resolution / accept-revision / rollback-revision` 都下沉到调试层兼容入口。`workflow start` 通过连续运行家族的正式起点自动分流到长任务或资料提取，`status / inspect / logs` 分别收束为队列摘要、链路快照和最近运行记录，`continue` 则只推进连续运行一次；底层共享 runtime 调用保持不变。已新增 `apps/novel_agent_cli/lib/commands/workflow/workflow_command_user.dart`、`apps/novel_agent_cli/lib/commands/workflow/workflow_command_debug.dart`，并更新 `workflow_command_dispatch.dart`、`workflow_command_output.dart`、`workflow_command_test.dart`，补了 `apps/novel_agent_cli/test/workflow_command_productization_test.dart` 覆盖用户层 `start/status/continue/inspect/logs` 与 debug help；验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test test/approval_command_test.dart test/workflow_command_test.dart test/workflow_command_productization_test.dart test/session_command_test.dart test/output/cli_output_protocol_test.dart`。下一步进入 `CLIX-13`，只做 `config / doctor` 命令族与测试，不再回头扩 workflow 主链。
- `CLIX-13`: 已完成 `config / doctor` 命令族与回归收口；`config` 现在正式提供 `show / get / set / provider list`，并通过 `SettingsRepository` 进行安全投影与写回，`config show` / `provider list` 不暴露 provider API key，`config set` 只更新明确的 settings 字段；`doctor` 现在正式提供 `check` 诊断入口，覆盖 provider 配置、默认项目路径可打开性、临时写权限与基础 capability 检查，并复用共享输出协议投影 JSON/text 结果。已新增 `apps/novel_agent_cli/test/config_command_test.dart`、`apps/novel_agent_cli/test/doctor_command_test.dart`，同时补了根帮助回归以确保 `config show` / `doctor` 进入正式 help；验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test`（CLI 包内全量测试）。下一步进入 `CLIX-14`，只收口 stdin / pipe / headless / non-interactive 行为。
- `CLIX-14`: 已完成 stdin / pipe / headless / non-interactive 收口；新增共享 `CliAutomationInputService` 统一处理 `--non-interactive / --yes` 的模式判定与管道文本回落，并让 `session send`、`workflow draft`、`approval approve/reject` 复用同一条输入读取链。`session start` 现在在无 TTY 或显式非交互模式下 fail-fast，不再偷偷进入 REPL；`session send` 与 `workflow draft` 可从 pipe 读取正文/提示词，`approval approve/reject` 可从 pipe 读取备注。已补 `apps/novel_agent_cli/test/shared/cli_automation_input_service_test.dart`、`apps/novel_agent_cli/test/session_command_test.dart`、`apps/novel_agent_cli/test/approval_command_test.dart`、`apps/novel_agent_cli/test/workflow_command_test.dart`，验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test`（CLI 包内全量测试）。下一步进入 `CLIX-15`，只做最终 regression / smoke / handoff / release boundary 收口。
- `CLIX-15`: 已完成最终 regression、smoke/probe、handoff 与 release boundary 收口；新增 `apps/novel_agent_cli/test/cli_smoke_test.dart`，用 production 同源命令链证明了 root help、workflow help、session help、approval help、session resume、workflow pause/resume、approval approve/reject、以及 reference extraction 的主链合同；同步更新 `docs/cli-release-boundary-2026-06-05.md` 以反映当前正式入口与调试层边界，并新增 `docs/cli-application-evolution-handoff-2026-06-16.md` 记录当前主链、残留风险和 TUI 接入点。验证通过 `dart analyze apps/novel_agent_cli` 与 `dart test`（CLI 包内全量测试）。本主线在当前 session 收口完成，后续如需 TUI 或更深层 automation，再从共享合同继续推进。

---

## 11. 文档自检

1. 已说明这份文档解决什么。
2. 已说明与旧文档和当前 CLI 现状的关系。
3. 已做已有实现去重审计。
4. 已冻结架构边界。
5. 已给出目标终态。
6. 全部设计目标均有 session 覆盖：
   - shared infra
   - output protocol
   - session
   - approval
   - workflow product/debug layering
   - config/doctor
   - stdin/headless
   - tests/probes/handoff
7. 顺序遵守：
   - 先 shared infra / boundary
   - 再命令拆责
   - 再 session / approval
   - 再 workflow 产品层 / config / automation
   - 最后 regression / handoff
8. 每个 session 都写明：
   - 本轮目标
   - 层级归属
   - 必读文件
   - 必须完成
   - 本轮不要做
   - 验收标准
   - 直接可用提示词
9. CLI 没有被要求承担底层业务真相补洞。
10. 已明确避免继续把 CLI 堆成巨型大文件集合。
