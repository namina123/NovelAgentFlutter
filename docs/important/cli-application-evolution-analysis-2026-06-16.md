# CLI 应用演化分析 - 2026-06-16

## 1. 文档定位

这份文档只做一件事：

- 站在专业 CLI 工具设计和通用 CLI agent 产品形态的视角，
- 对照我们当前仓库里 `apps/novel_agent_cli` 的真实实现，
- 给出一份契合本项目边界的 CLI 完善方案。

它不是一份“把别人的命令照抄过来”的清单，也不是一份脱离当前代码现实的理想图。

它的目标是：

1. 让 CLI 成为真正可长期演化、可自动化、可恢复、可验收的正式应用壳层。
2. 保持 `CLI -> core`、`bootstrap -> adapters` 的边界，不把 CLI 做成第二个业务中心。
3. 为后续普通项目、长任务、资料提取、知识体系、权限审批、上下文压缩提供一致的桌面入口。
4. 保持与未来 TUI 的关系清晰：CLI 先完整，TUI 后加，不反过来。

---

## 2. 本轮实际核查结果

本轮不是只读文档判断，而是直接对当前 CLI 做了代码和运行层核查。

### 2.1 已核查文件

- `apps/novel_agent_cli/bin/novel_agent.dart`
- `apps/novel_agent_cli/lib/bootstrap/cli_bootstrap.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_command.dart`
- `apps/novel_agent_cli/lib/commands/workflow/workflow_output_summary_service.dart`
- `apps/novel_agent_cli/lib/commands/project/project_command.dart`
- `apps/novel_agent_cli/lib/commands/review/review_command.dart`
- `apps/novel_agent_cli/lib/commands/asset/asset_command.dart`
- `apps/novel_agent_cli/lib/commands/template/template_command.dart`
- `apps/novel_agent_cli/lib/commands/session/session_command.dart`
- `apps/novel_agent_cli/lib/output/terminal_printer.dart`
- `apps/novel_agent_cli/test/workflow_command_test.dart`
- `apps/novel_agent_cli/test/workflow_output_summary_service_test.dart`
- `docs/cli-release-boundary-2026-06-05.md`
- `docs/continuous-task-control-and-reference-substrate-cli-handoff-2026-06-09.md`
- `docs/architecture.md`

### 2.2 实跑结果

已验证：

- `cd apps/novel_agent_cli && dart analyze` 通过
- `cd apps/novel_agent_cli && dart test` 通过
- `cd apps/novel_agent_cli && dart run bin/novel_agent.dart help` 可运行

### 2.3 当前 CLI 真实状态

当前 CLI 不是空壳，而是已经具备一批可工作的桌面命令壳层：

- `workflow`
- `project`
- `review`
- `asset`
- `template`
- `session`（但仍是明确的迁移占位符）

其中：

- `workflow` 已经接上共享长任务运行时、资料提取运行时、待确认资料研究动作。
- `project / review / asset / template` 已经接上共享服务，可做项目读写、审稿报告、资产包、模板管理。
- `session` 目前并不是可用会话入口，只是“尚未接通”的提示。

所以必须先认清一点：

**我们当前的 CLI 更像“operator shell + runtime validator”，还不是“用户可直接长期使用的 agent CLI”。**

---

## 3. 当前实现的优点

先讲值得保留的地方，因为后面的演化必须建立在这些优点上，而不是推倒重来。

### 3.1 边界总体是对的

当前实现基本符合既有架构基线：

- `CliBootstrap` 是唯一 composition root
- 命令类主要做参数解析、项目打开、终端输出
- 共享业务规则仍然主要在 `novel_agent_core` / `novel_agent_adapters`

这是正确方向，必须保留。

### 3.2 已经接上共享运行时，而不是 CLI 自己补语义

尤其是：

- 长任务 pause / resume / checkpoint / revision-resolution
- 参考资料提取摘要
- 待处理研究请求

CLI 已经尽量复用了：

- `ProjectWorkflowRuntimeService`
- `ProjectReferenceExtractionRuntimeService`
- `WorkflowOutputSummaryService`
- `ProjectPendingResearchActionService`

这意味着 CLI 有一个很好的基础：它不是胡乱打印文件树，而是真正在消费共享合同。

### 3.3 当前 CLI 已经有“专业壳层”的雏形

例如：

- stdout/stderr 分流
- 明确退出码
- 结构化结果的 summary block
- 可用于 probe / test / automation 的命令入口

这说明我们不是从零开始，而是已经有一层可继续收束的外壳。

---

## 4. 当前 CLI 的核心问题

### 4.1 它还不是一个“会话型 agent CLI”

这是当前最大的现实缺口。

现在真正可用的是：

- 单次 draft
- runtime 队列操作
- 项目与资产类命令

但一个成熟 CLI agent 通常会把“会话”作为核心入口之一，至少需要：

- 启动会话
- 继续上次会话
- 查看历史会话
- 在当前会话里切换模式、工具、模型、权限策略
- 在会话中断后恢复上下文

而我们现在的：

- `session` 只是占位提示

这意味着：

**CLI 目前还不能承接“像用户一样长期用 agent 工作”的主路径。**

### 4.2 当前命令面过于偏 operator，缺少产品化层

`workflow` 下已经有大量真实命令，但很多是直接暴露底层操作：

- `prepare`
- `run-once`
- `run-next`
- `postprocess-next`
- `complete-next`
- `apply-checkpoint-action`
- `apply-revision-resolution`

这些对于内部验证和调试非常有价值，但对普通 CLI 用户并不友好。

也就是说，我们已经有“底层可操作能力”，但还缺一层：

- 面向用户的稳定命令语义
- 面向自动化的稳定输出协议
- 面向排障的可读状态入口

### 4.3 参数解析已经开始发胖

当前几个文件体量已经很危险：

- `workflow_command.dart`: 1102 行
- `workflow_output_summary_service.dart`: 960 行
- `project_command.dart`: 666 行
- `asset_command.dart`: 601 行

这已经不是“有点长”，而是会直接影响协作、回归和后续功能插入。

问题不在数字本身，而在于职责已经开始粘连：

- 子命令分发
- 参数解析
- 项目上下文加载
- 输出整形
- 帮助文本
- 各子命令具体流程

混在同一个文件里。

如果继续在这个形态上补 `session`、审批、恢复、日志、stdin、JSON 输出，很容易把 CLI 做成第二个 `app_shell_controller.dart`。

### 4.4 缺少“专业 CLI”应有的输出协议

当前 CLI 输出基本都是人类可读文本，这很好，但还不够。

成熟 CLI 还需要明确支持：

- `--json`
- `--quiet`
- `--verbose`
- `--no-color`
- 稳定的 exit code 语义
- 机器可读字段的稳定命名

现在的 CLI 更偏“给人看”，不够“给脚本和其他系统消费”。

### 4.5 缺少 stdin / pipe / headless 友好入口

专业 CLI 往往同时支持：

- 直接参数调用
- 从文件读入
- 从 stdin 管道读入
- 非交互 headless 模式

我们现在的部分命令可用于批处理，但整体上仍缺：

- 从 stdin 接 prompt / source / patch / query
- 非交互模式下的稳定输出协议
- 显式 headless / no-prompt / fail-fast 行为

这会限制 CI、批处理、脚本链和远程自动化。

### 4.6 缺少统一的权限审批入口

我们项目现在已经有较复杂的：

- tool permission
- information permission
- pending research approval
- approval record

但 CLI 当前暴露出来的只是：

- `workflow pending-research list|approve|reject`

这意味着审批被做成了“资料研究特例”，而不是通用能力。

从 CLI 视角，这不够优雅，也不够长期可演化。

更合理的形态应当是：

- 一个统一的 `approval` 命令族
- research / tool / external access / risky write 只是不同审批类别

否则以后每出现一种待确认动作，CLI 都要再长一个特化命令。

### 4.7 缺少会话恢复、检查点、上下文压缩的用户面

我们在 core / adapters 里已经演化了大量：

- session compaction
- long task resume
- checkpoint review
- supervisor / continuous task control

但 CLI 用户面没有把这些组织成自然使用路径。

现在用户不能自然地做这些事：

- 查看最近会话
- 恢复某次会话
- 查看当前上下文压力
- 主动触发压缩
- 查看压缩后的摘要
- 在会话历史中回退

这和通用 agent CLI 的期望差距很大。

### 4.8 测试覆盖仍偏窄

当前 CLI 测试重点落在：

- `workflow_command_test.dart`
- `workflow_output_summary_service_test.dart`

这说明：

- `workflow` 的核心边界有一定保障
- 但 `project / review / asset / template / session` 的回归保护仍明显不足

如果要把 CLI 当正式应用，光 workflow 绿是不够的。

---

## 5. 专业 CLI 工具设计的基线要求

无论是不是 agent，只要是专业 CLI，通常都应该满足以下要求。

### 5.1 命令树清晰

要有稳定的：

- 顶层主语义
- 子命令层级
- 一致的 flag 风格
- 一致的帮助信息结构

用户看 `help`，应该能知道：

- 这个命令是做什么的
- 什么时候用
- 输入输出是什么
- 失败会怎样

### 5.2 同时服务两类用户

专业 CLI 一般必须同时服务：

1. 人类交互用户
2. 自动化脚本 / CI / 其他工具

这意味着它必须兼容：

- 人类可读输出
- 机器可读输出

### 5.3 输入方式不能单一

至少应支持其中多数：

- positional args
- named flags
- stdin
- file input
- environment variables
- config file

### 5.4 错误模型必须稳定

成熟 CLI 不能只靠“打印一句错了”。

它需要：

- 可预测的退出码
- 可区分的错误类别
- 面向用户的错误消息
- 面向日志 / 机器的错误字段

### 5.5 长运行任务必须可观察、可暂停、可恢复

尤其当命令可能运行数分钟到数小时，就必须提供：

- 当前阶段
- 当前动作
- 进度
- 阻塞原因
- 下一步建议
- 暂停 / 恢复 / 取消
- 最近一次有效产物位置

### 5.6 配置要有层次

专业 CLI 通常至少有：

- 内置默认
- 全局用户配置
- 工作区 / 项目配置
- 命令行覆盖
- 环境变量覆盖

并且优先级明确。

### 5.7 输出要分层

最少要能区分：

- 正常结果
- 结构化结果
- 错误
- 进度
- 调试信息

### 5.8 交互模式与非交互模式要分清

同一个命令在交互 shell 和 CI 脚本里行为不能含糊。

尤其要明确：

- 是否会弹确认
- 没有 TTY 时是否自动失败
- 是否允许默认决策
- 是否支持 `--yes` / `--non-interactive`

---

## 6. 通用 CLI agent 的能力基线

结合通用 CLI agent 的官方文档，可以提炼出一组更具体的产品基线。

### 6.1 会话与恢复

通用 agent CLI 几乎都会把“会话恢复”当成一级能力。

可参考的公开事实：

- Claude Code 官方文档明确支持启动会话、恢复会话、以及 headless 调用。
- Gemini CLI 官方文档明确提供 `/resume`、`--resume`、checkpoint / restore、session browser。
- Aider 把长期对话和 in-chat commands 作为基本交互形态。
- Codex CLI 官方文档明确区分交互模式、审批模式、sandbox、以及会话相关配置。

这说明：

**会话不是附加功能，而是 agent CLI 的主语义之一。**

### 6.2 命令内命令 / slash commands / mode switching

通用 agent CLI 往往不只有 shell 命令，还会在会话内部支持：

- slash commands
- 模式切换
- 上下文管理命令
- 模型切换
- 权限切换

这类设计的价值在于：

- 不打断当前会话
- 不需要重新起进程
- 降低用户对底层结构的认知成本

### 6.3 权限与安全模式

成熟 agent CLI 都非常强调：

- approvals
- sandbox
- network policy
- risky action confirmation

这不是锦上添花，而是 agent CLI 的基本生命线。

### 6.4 headless / pipe / automation

通用 agent CLI 不只要能“人在终端里聊天”，还要能：

- 被脚本调用
- 吃 stdin
- 输出稳定结果
- 在 CI / batch / cron 下工作

### 6.5 上下文管理与检查点

成熟 agent CLI 会显式暴露：

- clear / compact / resume / restore / rewind
- usage / stats / limits
- conversation state inspection

这类能力对长任务尤其关键。

### 6.6 扩展点

通用 agent CLI 还越来越常见地支持：

- skills
- MCP / tools
- hooks
- custom commands

我们的项目本身就有：

- 智能体组
- 技能组
- 工具暴露策略
- 项目级约束

所以 CLI 不需要照搬别人，但必须给这些“可组合能力”留出稳定入口。

---

## 7. 对照当前项目后的关键结论

### 7.1 我们不缺“命令数量”，缺的是“产品层”

现在最不缺的是底层子命令。

现在真正缺的是：

- 主路径
- 恢复路径
- 审批路径
- 结构化输出路径
- 交互与非交互分层

所以后续不能再靠“继续往 workflow 里加子命令”来完善 CLI。

### 7.2 `session` 必须从占位符变成正式入口

如果不把 `session` 做起来，我们的 CLI 永远更像“运行时维护台”。

这不符合用户期望，也不符合我们项目已经具备的 agent / session / strategy / approval 基础。

### 7.3 审批必须通用化

`pending-research` 这种做法可以保留为细分视图，但不能继续作为审批体系的主入口。

CLI 应该演化出统一命令族，例如：

- `approval list`
- `approval show`
- `approval approve`
- `approval reject`
- `approval policy`

然后：

- research approval
- tool approval
- external research
- destructive write

都走同一套合同。

### 7.4 当前 `workflow` 要分层，不要再单文件扩写

`workflow_command.dart` 已经 1102 行，这不是继续“顺手加几个子命令”的状态了。

后续必须拆成：

- `workflow_command.dart`：只保留 root dispatch
- `commands/workflow/subcommands/...`
- `commands/workflow/parsing/...`
- `commands/workflow/renderers/...`
- `commands/shared/...`

否则 `session`、`approval`、`logs` 一接上，就会直接失控。

### 7.5 `workflow_output_summary_service.dart` 也到了必须分拆的时候

它当前混着：

- run center 摘要
- narrative runtime 摘要
- expression constraint 摘要
- chapter delivery 摘要
- reference extraction 摘要
- stop diagnosis 文本映射

这已经不是一个单一服务了。

更好的拆法应是：

- `run_center_summary_renderer.dart`
- `narrative_runtime_summary_renderer.dart`
- `reference_extraction_summary_renderer.dart`
- `expression_constraint_summary_renderer.dart`
- `stop_diagnosis_text_service.dart`

CLI 汇总层再组合它们。

---

## 8. 我们的 CLI 应该成为什么样

### 8.1 总体定位

我们的 CLI 不应只是“GUI 的缩水版”，也不应只是“内部 probe 的包装层”。

它更合理的定位是：

1. 正式桌面壳层
2. 自动化与批处理入口
3. 长任务 / 资料提取 / 审批 / 会话恢复的操作面
4. 未来 TUI 的基础命令后端

### 8.2 两条主路径

未来 CLI 应明确提供两条主路径。

#### 路径 A：交互式 agent 会话

用于：

- 普通创作
- 会话式引导
- 信息收集
- 动态审批
- 多智能体协作观察

主入口：

- `novel_agent session ...`

#### 路径 B：显式命令式工作流

用于：

- 长任务启动与推进
- 提取任务
- 项目导入导出
- 资产 / 模板 / 审稿 / 审批
- CI / 批处理 / 运维脚本

主入口：

- `workflow / project / review / asset / template / approval`

### 8.3 会话优先，命令保底

对普通用户而言，CLI 的第一体验应是会话。

对高级用户和自动化而言，命令族是保底和增强。

这是更符合 agent 产品心智的设计。

---

## 9. 建议的 CLI 能力结构

## 9.1 顶层命令族

建议最终收束为以下顶层：

- `session`
- `workflow`
- `project`
- `review`
- `asset`
- `template`
- `approval`
- `config`
- `doctor`

其中：

### `session`

作为主交互入口，负责：

- 启动交互式 agent 会话
- 恢复历史会话
- 查看历史
- 切换模式 / 模型 / 智能体组
- 查看上下文压力
- 手动压缩
- 会话级审批确认

### `workflow`

作为运行时与长任务入口，负责：

- 启动一般长任务
- 启动资料提取连续任务
- 查看运行状态
- pause / resume / cancel / inspect / logs
- 操作 checkpoint / revision / repair

### `project`

负责：

- 项目摘要
- 基础文件操作
- 导入 / 导出 / 打包
- 项目类型转换
- 项目配置查看与更新

### `review`

负责：

- review 列表
- review 详情
- 创建审稿任务
- 从审稿报告生成修复任务

### `asset` / `template`

负责：

- 与项目资产、模板相关的显式管理

### `approval`

负责：

- 所有待确认动作的统一处理

### `config`

负责：

- 查看与修改 CLI / provider / 默认策略
- 用户级配置
- 工作区级配置

### `doctor`

负责：

- 环境检查
- provider 配置检查
- 默认项目路径检查
- token 计数器 / context 能力 / tool 权限可用性检查
- 目录结构和写权限检查

---

## 10. `session` 应如何设计

### 10.1 第一原则

`session` 不应是 GUI workbench 的文本翻版。

它应该是：

- 面向终端的会话壳层
- 消费共享 session / agent / tool / approval / compaction 合同
- 能在无 GUI 的情况下完整推进用户主链

### 10.2 最小可用能力

第一版正式 `session` 至少应支持：

- `session start [--project ...]`
- `session resume [--latest|--id ...]`
- `session list`
- `session show --id ...`
- `session send --message "..."`
- `session compact`
- `session stats`
- `session stop`

### 10.3 交互方式

推荐分两层：

1. 非交互命令
2. 交互 REPL

即：

- `session send --message "..."` 用于脚本和单轮触发
- `session start` 进入交互循环，用 `/` 风格命令控制会话

### 10.4 会话内命令

建议保留一组轻量 slash command，例如：

- `/help`
- `/model`
- `/group`
- `/tools`
- `/approval`
- `/compact`
- `/stats`
- `/resume`
- `/clear`
- `/exit`

注意：

这些是 CLI 壳层命令，不是重新造业务规则。

### 10.5 普通项目的信息收集必须在这里可用

由于我们项目已经明确强调：

- 除非用户明确授权，否则智能体不应擅自替用户决定关键创作信息

那么 CLI 的 `session` 必须能自然承接：

- 智能体发起澄清
- 用户逐条回答
- 项目文件落盘
- 会话继续

这会成为 CLI 与 GUI 在用户主路径上的真正对齐点。

---

## 11. `workflow` 应如何重构

### 11.1 保留底层能力，但分出“产品层”和“运维层”

当前 `workflow` 下的很多命令都是真实有效的，不应该删。

但应该分层：

#### 产品层

- `workflow start`
- `workflow status`
- `workflow continue`
- `workflow pause`
- `workflow resume`
- `workflow inspect`
- `workflow approve`
- `workflow logs`

#### 运维 / 调试层

- `workflow debug prepare`
- `workflow debug run-once`
- `workflow debug postprocess-next`
- `workflow debug apply-checkpoint-action`
- `workflow debug apply-revision-resolution`

这样可以避免用户直接暴露到底层 runtime 颗粒度。

### 11.2 长任务与提取任务都要统一成“连续运行任务”

从 CLI 视角看：

- 一般长任务
- 资料提取任务

都应该被看作 continuous run。

因此 `workflow` 的状态、暂停、恢复、日志、审批，不应该只服务写作长任务。

---

## 12. 审批体系的 CLI 设计

### 12.1 不再以具体业务特例暴露

当前的 `pending-research` 说明审批链已经开始落地，但暴露方式还偏特例化。

后续应统一成：

- `approval list`
- `approval show --id ...`
- `approval approve --id ...`
- `approval reject --id ...`
- `approval policy show`
- `approval policy set`

### 12.2 审批展示字段

每条审批至少应有：

- `approval_id`
- `kind`
- `scope`
- `request_summary`
- `risk_level`
- `requested_by`
- `created_at`
- `blocking_runtime`
- `related_project`
- `related_run`
- `related_artifact_paths`

### 12.3 审批与恢复必须联动

当某次长任务或提取任务因为审批阻塞时，CLI 必须能让用户：

1. 找到阻塞项
2. 确认或拒绝
3. 继续原运行

而不是让用户手动去猜哪个 run 要 resume。

---

## 13. 输出协议设计

### 13.1 默认输出

默认仍保留人类可读块输出，这是当前 CLI 的一个优点。

### 13.2 结构化输出

所有正式命令都应支持：

- `--json`

输出规则：

- stdout 只输出 JSON
- stderr 只输出错误与警告
- 字段结构稳定

### 13.3 日志级别

建议统一支持：

- `--quiet`
- `--verbose`
- `--debug`
- `--no-color`

### 13.4 exit code

至少应收束出一套稳定映射：

- `0`: 成功
- `1`: 运行失败
- `2`: 参数或输入错误
- `3`: 找不到资源
- `4`: 审批阻塞
- `5`: 配置错误
- `6`: 网络 / provider 不可用
- `7`: 用户中止

不一定一步到位，但必须开始统一。

---

## 14. 配置层设计

当前 CLI 已经能读取 settings，但还不够产品化。

建议收束成四层：

1. 内置默认
2. 用户级 CLI 配置
3. 项目级覆盖
4. 命令行临时覆盖

并统一暴露：

- `config show`
- `config get`
- `config set`
- `config provider list`
- `config provider doctor`
- `config defaults show`

重点不是“做一个配置编辑器”，而是让 CLI 可以：

- 可检查
- 可脚本化
- 可诊断

---

## 15. 上下文压缩与 token 策略在 CLI 中的定位

CLI 不能忽略这件事，因为：

- 长任务
- 多轮会话
- 资料提取

都会直接碰到上下文边界。

CLI 至少要能做到：

- `session stats` 查看当前压力
- `session compact` 主动压缩
- `session show --context` 查看压缩摘要
- `workflow inspect` 显示当前运行是否卡在压缩或上下文边界

但这部分逻辑仍应由 core / adapters 负责，CLI 只负责：

- 触发
- 展示
- 选择策略

---

## 16. 目录与代码结构演化建议

这是实现层很重要的一点。

### 16.1 不要继续堆大文件

必须直接拆。

建议目录大致变成：

```text
apps/novel_agent_cli/lib/
  bootstrap/
  commands/
    shared/
      cli_command_context.dart
      project_context_loader.dart
      option_parsers/
      output/
      exit_codes.dart
    session/
      session_command.dart
      subcommands/
      repl/
      renderers/
    workflow/
      workflow_command.dart
      subcommands/
      renderers/
      parsing/
    project/
      project_command.dart
      subcommands/
    review/
    asset/
    template/
    approval/
    config/
    doctor/
  output/
    terminal_printer.dart
    json_output_writer.dart
    progress_reporter.dart
```

### 16.2 参数解析要独立出来

当前每个命令类都自己扫描 `--flag`，这在命令少时可以接受，但现在已经不够了。

建议：

- CLI 壳层引入统一解析层
- 可以用 `package:args`
- 也可以继续自建轻量 parser

但无论哪种，都要：

- 统一 flag 风格
- 统一 help 生成
- 统一错误提示

### 16.3 共享上下文加载器

像这些逻辑已经反复出现：

- 打开 settings
- 解析默认项目
- 打开 project
- 检查 provider

应该抽成 CLI shared service，而不是每个命令再写一次。

---

## 17. 哪些职责必须留在 core / adapters

这个边界必须写清楚，防止 CLI 完善过程中越界。

### 17.1 必须留在 core / adapters 的

- 会话合同
- 长任务状态机
- 资料提取状态机
- 审批记录与权限规则
- 上下文压缩策略
- token 计算
- provider payload 构造
- 工具暴露规则
- 智能体组调度合同
- 运行记录与检查点合同

### 17.2 可以放在 CLI 壳层的

- 参数解析
- 终端交互
- 文本 / JSON 输出
- 进度显示
- TTY 检测
- 命令帮助
- shell completion
- 非交互 fail-fast 策略

### 17.3 不该放在 CLI 壳层的

- 自己判断长任务下一步怎么推进
- 自己推断 mount / continuity / coverage 状态
- 自己重建 provider 请求逻辑
- 自己补 session compaction 语义
- 为了终端展示方便而改写业务规则

---

## 18. 测试与验收基线

CLI 如果要成为正式应用，测试面必须扩。

### 18.1 命令级回归

至少补齐：

- `project_command_test.dart`
- `review_command_test.dart`
- `asset_command_test.dart`
- `template_command_test.dart`
- `session_command_test.dart`
- `approval_command_test.dart`
- `config_command_test.dart`

### 18.2 help / parse 回归

要有：

- root help smoke test
- 子命令 help smoke test
- 非法参数退出码测试
- `--json` 输出形态测试

### 18.3 集成 smoke

建议保留真实 CLI probe，但不要把 probe 和主逻辑耦死。

至少有：

- session resume smoke
- workflow pause/resume smoke
- approval approve/reject smoke
- extract-reference smoke
- long-task inspect/logs smoke

### 18.4 非交互模式测试

必须增加：

- stdin 输入测试
- no-tty 测试
- `--yes` / `--non-interactive` 行为测试

---

## 19. 建议的实施顺序

这部分很重要，因为 CLI 不能一口气大改到失控。

### Phase 1：收边界，不加大功能面

目标：

- 拆大文件
- 建 shared command infrastructure
- 统一 exit code
- 统一输出协议

这一阶段先不追求新功能暴涨。

### Phase 2：把 `session` 从占位符做成正式入口

目标：

- session list / resume / send / stats / compact
- 最小 REPL
- 基本 slash commands

这是 CLI 从 operator shell 进化到 agent CLI 的关键阶段。

### Phase 3：把审批体系通用化

目标：

- 独立 `approval` 命令族
- research pending 迁到 approval 体系
- workflow/session 与 approval 联动

### Phase 4：把 workflow 做产品层 / 调试层分层

目标：

- 用户友好命令
- 运维调试命令下沉到 `workflow debug`
- 长任务和提取任务统一 continuous run 视角

### Phase 5：补自动化与产品化能力

目标：

- `--json`
- stdin / pipe
- config / doctor
- shell completion
- 更完整的 test matrix

---

## 20. 最终结论

当前 CLI 的判断可以很明确：

### 20.1 已经做对的部分

- 架构边界总体对
- 共享运行时接得对
- 一批命令已真实可跑
- 作为 runtime shell 已经有基础可用性

### 20.2 还没做完的核心部分

- `session` 仍未成为正式主入口
- 审批体系还未通用化
- 输出协议还不够专业
- 自动化接口还不够完整
- 大文件已经开始压垮协作性

### 20.3 下一阶段的真正目标

不是“再加几个 workflow 子命令”，而是：

**把现在这套偏 operator 的 CLI 壳，收束成一个同时支持会话、审批、长任务、提取任务、自动化脚本的正式桌面 CLI 应用。**

这才是与我们当前 core / adapters 进度相匹配的完善方向。

---

## 21. 外部参考

以下链接仅作为通用 CLI / CLI agent 能力对照，不代表我们照搬其实现：

- Claude Code CLI reference: https://code.claude.com/docs/en/cli-reference
- Claude Code commands: https://code.claude.com/docs/en/commands
- Claude Code permission modes: https://code.claude.com/docs/en/permission-modes
- Claude Code headless usage: https://code.claude.com/docs/en/headless
- Aider documentation: https://aider.chat/docs/
- Aider in-chat commands: https://aider.chat/docs/usage/commands.html
- Aider chat modes: https://aider.chat/docs/usage/modes.html
- Aider options/config: https://aider.chat/docs/config/options.html
- Gemini CLI commands: https://geminicli.com/docs/reference/commands/
- Gemini CLI session management: https://geminicli.com/docs/cli/session-management/
- Gemini CLI checkpointing: https://geminicli.com/docs/cli/checkpointing/
- Gemini CLI configuration: https://geminicli.com/docs/reference/configuration/
- OpenAI Codex CLI features: https://developers.openai.com/codex/cli/features
- OpenAI Codex CLI reference: https://developers.openai.com/codex/cli/reference
- OpenAI Codex approvals/security: https://developers.openai.com/codex/agent-approvals-security
