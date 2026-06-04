# Archived Probes

这些 probe 已从 `apps/novel_agent_app/tool/` 迁出，因为它们主要服务于历史会话验证，
当前没有正式代码链或测试链依赖，不应该继续占据正式工具入口目录。

保留原则：

- `tool/` 只保留当前仍承担真实回归、兼容验证、共享 probe 支撑的脚本。
- 历史阶段性验证脚本迁到 `archive/probes/`，需要时仍可手动运行。
- 旧文档里的原路径视为历史记录；若要重跑，请改用这里的新路径。

当前归档批次：

- `legacy_long_task_modes/`
  - 旧的 seed autopilot / full outline 模式验证脚本
- `legacy_feature_validation/`
  - 单次功能闭环验证脚本，例如 agent group opening、skill loadout
