---
name: skill-creator-cn
description: 此技能应在需要创建、重构、验证、迭代或打包标准技能包时使用。适用于把经验流程沉淀为可分发的 SKILL.md 目录包，且不应默认绑定某个具体宿主工具。
version: 1
activation_hints:
  - 用户要创建新技能
  - 用户要把经验沉淀为技能
  - 用户要重构已有技能包
  - 用户要验证或打包技能
inputs:
  - 目标技能的用途
  - 触发该技能的真实示例
  - 可复用资源清单
outputs:
  - 标准技能目录结构
  - 带 frontmatter 的 SKILL.md
  - 可执行脚本、参考资料与素材建议
required_capabilities: []
optional_capabilities:
  - file_read
  - file_write
  - archive_zip
  - run_script
  - search_reference
safe_without_tools: true
resource_hints:
  scripts:
    - scripts/init_skill.dart
    - scripts/quick_validate.dart
    - scripts/package_skill.dart
  references:
    - references/skill-authoring-guide.md
    - references/upstream-attribution.md
  assets: []
preferred_output: 标准技能目录与 SKILL.md 草案
---

# 技能创建器（中文版）

## 概述

要把一个经验流程沉淀为技能时，先把技能看成“给另一个模型的入职说明”，而不是一段提示词。只保留可复用、非显而易见、能长期帮助执行的内容。

## 使用时机

在以下场景触发此技能：

1. 要创建新的 `skills/<id>/SKILL.md` 包。
2. 要把零散流程、领域知识或脚本沉淀为可复用技能。
3. 要把已有技能从“说明文本”重构为“标准包结构”。
4. 要验证技能结构、命名、frontmatter 与资源布局是否合格。
5. 要打包技能供迁移、分发或内置。

## 核心原则

1. 先从具体示例理解技能，再抽象结构。
2. 先设计可复用资源，再写 `SKILL.md`。
3. 保持渐进式披露：元数据始终轻，正文在触发时读，细节下沉到 `references/`、`scripts/`、`assets/`。
4. 不要把技能写成“必须拥有某个具体工具才能工作”。优先描述能力边界与降级策略，而不是写死宿主工具名。
5. 如果缺少工具能力，仍要给出流程指导、目录建议、结构草案和人工可执行步骤。
6. 避免在 `SKILL.md` 和 `references/` 重复堆相同信息。

## 工作流程

### 第一步：收集真实示例

先明确：

1. 用户会说什么触发该技能。
2. 技能最终要产出什么。
3. 哪些步骤会反复出现。
4. 哪些内容属于领域知识，哪些属于脚本或模板。

如果模式还不清楚，只追问最关键的 1 到 3 个问题。

### 第二步：规划目录结构

优先按标准目录组织：

```text
skill-name/
├── SKILL.md
├── scripts/
├── references/
└── assets/
```

不是每个技能都必须拥有全部资源目录，但目录含义要保持稳定：

1. `scripts/` 放确定性步骤、可重复脚本、格式转换、初始化器、验证器。
2. `references/` 放只在需要时才加载的详细资料、规则、模式和示例。
3. `assets/` 放最终输出要用的模板、图片、字体、示例工程等，不默认进上下文。

### 第三步：编写 frontmatter

至少包含：

1. `name`
2. `description`

建议补充：

1. `activation_hints`
2. `inputs`
3. `outputs`
4. `required_capabilities`
5. `optional_capabilities`
6. `safe_without_tools`
7. `resource_hints`
8. `preferred_output`

把 `description` 写成“此技能应在……时使用”的第三人称说明，不要写空泛广告语。

### 第四步：编写正文

正文使用中文祈使句风格：

1. 先写何时使用。
2. 再写如何判断。
3. 再写步骤。
4. 最后写资源怎么用。

不要把宿主内置工具写成硬前提。要写成：

- 有文件写能力时，落成真实目录结构。
- 没有文件写能力时，先输出完整草案和目录建议。
- 有脚本执行能力时，调用包内脚本。
- 没有脚本执行能力时，解释脚本应做什么。

### 第五步：验证与打包

优先使用包内脚本：

1. `scripts/init_skill.dart` 初始化新技能目录。
2. `scripts/quick_validate.dart` 做基础结构检查。
3. `scripts/package_skill.dart` 在验证通过后打包 zip。

如果宿主不能运行脚本，至少按脚本逻辑手动检查：

1. `SKILL.md` 是否存在。
2. frontmatter 是否存在且包含必需字段。
3. `name` 是否稳定可分发。
4. `description` 是否清晰说明触发时机。
5. 是否把大块细节错误地堆回 `SKILL.md`。

## 资源使用

### scripts/

优先在以下情况使用脚本：

1. 初始化固定目录结构。
2. 做可重复验证。
3. 做打包、整理、导出等稳定步骤。

### references/

需要详细规范、示例或流程时，再读参考资料。不要一开始把整份长文档塞进上下文。

### assets/

只有在技能最终要交付模板、样板文件、图片或示例工程时才使用。
