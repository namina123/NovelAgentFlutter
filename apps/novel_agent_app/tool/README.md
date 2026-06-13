# Probe Tool Boundary

`apps/novel_agent_app/tool/` 里的脚本属于开发探针与回归工具，不属于正式产品入口。

## 长期保留理由

保留在正式 `tool/` 目录中的脚本，必须至少满足下面之一：

1. 被当前发布收口文档或历史 session 文档直接引用。
2. 被现有 focused test / mock probe / 回归产物依赖。
3. 提供稳定的输入输出合同，能复用共享 `probe_support.dart` 或 `tools/probe_config_support.dart`。

当前保留分组：

1. 共享底座与非计费探针：
   - `probe_support.dart`
   - `all_tools_probe.dart`
   - `mock_long_task_probe.dart`
2. 真实计费探针：
   - `gateway_connect_probe.dart`
   - `real_anthropic_compat_probe.dart`
   - `real_general_novel_probe.dart`
   - `real_long_task_20_chapter_probe.dart`
   - `real_long_task_probe.dart`
   - `real_multiscope_pressure_probe.dart`
   - `real_openai_compat_probe.dart`
   - `real_option_probe.dart`
   - `real_workflow_loop_probe.dart`

历史一次性探针应继续优先归档到 `archive/probes/`，不要再把新的一次性排障脚本直接堆进这里。

## 真实探针运行约束

1. 必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
2. 默认只从 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 读取配置。
3. 不默认回退到 `test_api.txt` 或 `temp/novel_agent_settings.json`。
4. 输出应写入 `artifacts/`，不要写回正式项目目录。
5. 不允许把真实 key、固定计费入口或个人绝对路径硬编码进脚本。

## 发布隔离结论

1. `artifacts/`、`local/`、`references/` 已由仓库忽略规则隔离，不应进入提交或打包验收范围。
2. `tool/` 中的 probe 仅用于开发与验收；`RRP-26` 打包时应继续确认它们不会作为 GUI/CLI 默认入口暴露。
