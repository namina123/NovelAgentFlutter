# 共享核心策略

## 结论

本项目当前采用:

- `纯 Dart core`
- `Dart CLI`
- `Flutter GUI`

并且当前 roadmap 明确不包含:

- `全量 C++ 核心`
- `CLI 专属 native 核心`
- `Flutter 直接调用 native 业务层`

## 选择理由

### 1. 当前问题不是“算不动”

旧项目的主要失败原因是:

- 边界缺失
- 状态过大
- 宿主与业务混杂

因此第一阶段最重要的是:

- 把共享业务规则稳定沉淀在纯 Dart core
- 让 GUI 与 CLI 共享这套规则

### 2. Dart 本身可以承担 CLI

桌面 CLI 是 Dart 的正常使用场景，不需要为了“命令行”这件事提前下沉到 C++。

### 3. C++ 应该服务于热点，而不是替代架构

C++ 更适合做:

- 本地索引引擎
- 大文本增量处理
- 高性能检索
- 特定 native 库封装

它不适合在项目还没稳定边界前承接整套业务演化。

## 未来演化

如果未来某个核心子系统出现明确热点，采用如下路径:

1. 在 `novel_agent_core` 保持合同不变
2. 在 `novel_agent_adapters` 增加新的 native adapter
3. 在 `native/` 下落地局部引擎
4. 由 bootstrap 选择 pure Dart 或 native 实现

## 反例

以下做法是明确不推荐的:

- 现在就把 project/session/workflow 全量搬到 C++
- 让 Flutter 页面直接调用 native 业务逻辑
- 为 CLI 单独重写一套核心状态机
