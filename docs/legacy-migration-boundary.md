# 旧项目迁移边界

## 目标

本文件用于约束旧项目迁移时的去向判断，避免把 Godot 宿主逻辑、UI 拼装逻辑和共享核心重新耦合在一起。

## 核心判定原则

- 纯规则、纯数据、纯字符串拼装、纯状态归一化: 进入 `packages/novel_agent_core`
- 文件系统、HTTP、进程、持久化、宿主能力探测: 进入 `packages/novel_agent_adapters`
- 页面结构、控件状态、动画、输入焦点、IME 行为、视觉呈现: 留在 `apps/novel_agent_app`
- CLI 参数、stdout/stderr、退出码: 留在 `apps/novel_agent_cli`

## 旧项目模块去向

### 进入 core

- `src/llm/provider_profile.gd`
- `src/llm/provider_model_catalog.gd`
- `src/llm/provider_model_capabilities.gd`
- `src/skills/tool_strategy.gd`
- `src/project/project_prompt_contract.gd`
- `src/context/context_budgeter.gd`
- `src/review/revision_diff.gd`
- `src/agents/agent_catalog.gd`
- `src/workflow/task_queue_runtime.gd` 中不依赖文件写入的规则部分
- `src/workflow/task_runtime.gd` 中不依赖宿主的状态流转部分

### 进入 adapters

- `src/project/project_storage.gd`
- `src/project/project_index.gd`
- `src/llm/openai_client.gd`
- `src/memory/memory_store.gd`
- `src/customization/customization_store.gd`
- `src/customization/customization_market_store.gd`
- `src/customization/customization_package_io.gd`
- `native/toolcore/src/providers/*`
- `native/toolcore/src/context/*`
- `native/toolcore/src/records/*`
- `native/toolcore/src/customization/*`

### 留在 GUI

- `src/ui/components/*`
- `src/ui/controllers/*`
- `src/ui/conversation/*`
- `src/ui/layout/*`
- `src/ui/theme/*`
- `src/ui/tasks/task_center_presenter.gd`
- `src/ui/main_controller.gd`

### 需要拆分后再迁

- `src/workflow/workflow_runtime.gd`
- `src/agents/agent_orchestrator.gd`
- `src/customization/custom_skill_executor.gd`
- `src/review/review_pipeline.gd`

这些模块包含“规则 + 持久化 + 宿主调用 + 呈现驱动”的混合职责，迁移时必须先切开，再分别落到 `core`、`adapters`、`app`。

## 当前首批迁移范围

第一批只迁纯逻辑模块:

- provider catalog
- provider capability resolver
- provider profile normalization
- project prompt contract
- tool strategy

这样做的原因是:

- GUI 和 CLI 都会复用
- 不需要 Flutter 或 Godot 宿主
- 能先把旧项目最重要的规则层稳定下来

## 当前已完成的第二批纯逻辑迁移

- context budgeter 的预算、裁剪、预览规则
- revision diff 的预览、摘要、Markdown 渲染规则
- task runtime 的任务规范化、选择、状态迁移、执行计划规则
- task queue 的选项收敛、预检、停止策略、运行摘要渲染规则

## 当前已完成的第三批纯逻辑迁移

- context assembler 的固定片段组装、项目文件片段组装、上下文包生成规则
- session record 的模式、规范化、消息压缩、上下文渲染、历史窗口、JSONL 导出规则
- generation record 的 provider 脱敏、context pack 摘要、记录构建、路径规则
- 一个共享上下文包用例入口，供 GUI/CLI 后续直接复用

## 当前已完成的第四批纯逻辑迁移

- agent profile / group 的 JSON 解析、默认值规范化、采样参数收敛与摘要渲染规则
- multi-agent orchestration 的策略画像、委派计划、协作摘要、子智能体运行包与消息合同
- agent run loop 的工具结果压缩、工具回合状态、assistant/tool 消息协议、循环决策与响应打包规则
- prompt template 的作用域、变量提取、规范化、默认模板、内存态合并与预览规则
- review report 的类型目录、问题规范化、报告规范化、Markdown 渲染、摘要、路径策略、修复任务与提示变量规则

## 当前已完成的第五批用例层纯化迁移

- chapter atomic 的任务意图、查询提示、拟写入路径、执行包构建、步骤游标、模型结果/后处理结果推进与 Markdown 清单规则
- long task run 的模式策略、运行选项、运行记录、下一步调度、步骤审计、暂停/恢复/结束与 Markdown 摘要规则
- long task transaction / prompt shaping 的任务事务、后处理事务、提示渲染、恢复建议、失败动作与基础任务工厂规则
- 两个共享用例入口：章节原子执行包生成、长任务提示生成

## 当前已完成的第六批共用调度层迁移

- long task controller 的模式画像、循环守卫、单步后停机、结束归因规则
- unattended strategy / next batch plan / run center contract / scheduler tick plan 的共用后台调度规则
- 运行中心与后台调度的 Markdown 渲染规则

## 当前已完成的第七批计划 / 引导 / 修订迁移

- long task plan record / changed paths / Markdown 渲染规则
- 运行中 guidance 队列追加、消费与注入消息规则
- long task revision 的检查点确认、任务重试修订、动态插入检查点、动态追加章节规则
- 两个共享用例入口：长任务计划生成、长任务修订计划生成

## 当前已完成的第八批共用运行入口迁移

- long task 的计划身份推导、运行路径约定、批次限流参数规则
- revision plan 的纯内存 apply 规则，供宿主写盘前先在 core 内完成任务列表变换
- 三个共享用例入口：启动长任务运行、生成调度快照、完成单步后的 record 收尾
