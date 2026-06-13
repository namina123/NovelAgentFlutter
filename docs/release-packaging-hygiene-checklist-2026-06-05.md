# Release Packaging Hygiene Checklist

更新时间：2026-06-05

适用 session：`RRP-25`

## 1. Probe 入口边界

1. `apps/novel_agent_app/tool/README.md` 已明确：`tool/` 下脚本属于开发探针，不属于正式产品入口。
2. 保留在 `tool/` 的脚本分为：
   - 共享底座 / 非计费探针：`probe_support.dart`、`all_tools_probe.dart`、`mock_long_task_probe.dart`
   - 真实计费探针：`gateway_connect_probe.dart`、`real_anthropic_compat_probe.dart`、`real_general_novel_probe.dart`、`real_long_task_20_chapter_probe.dart`、`real_long_task_probe.dart`、`real_multiscope_pressure_probe.dart`、`real_openai_compat_probe.dart`、`real_option_probe.dart`、`real_workflow_loop_probe.dart`
3. 历史一次性探针继续放在 `apps/novel_agent_app/archive/probes/`，后续不要把新的单次排障脚本直接塞回正式 `tool/`。

## 2. 真实 API 配置与显式开闸

1. 真实 probe 必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
2. 默认配置源只允许：
   - `local/probe_api.txt`
   - `NOVEL_AGENT_PROBE_API_FILE` 指向的本地文件
3. `test_api.txt` 与 `temp/novel_agent_settings.json` 不再作为默认真实 probe 配置源；如确需兼容，只能在脚本里显式开启 fallback。
4. `local/README.md` 已同步说明上述规则。

## 3. 仓库与打包隔离面

当前已确认由 `.gitignore` 隔离：

1. `artifacts/`
2. `local/*`
3. `test_api.txt`
4. `references/MuMuAINovel-main/`
5. `references/assets/`
6. `references/files/`
7. `.env`、`.env.*`、`.envrc`

发布前仍需保持的约束：

1. 不把 `artifacts/`、`local/`、`references/` 当成发布资源目录。
2. 不把 probe report、截图、zip 临时产物、人工备份带入安装包。
3. 不把仓库外真实配置通过脚本默认复制进构建目录。

## 4. 密钥扫描

仓库级自检命令：

```text
dart tools/repository_secret_scan.dart
```

说明：

1. 扫描器只检查可能进入提交面的源码 / 文档 / 脚本。
2. `local/`、`artifacts/`、`references/`、生成目录与常见二进制产物会被排除。

## 5. 打包脚本现状

1. 当前仓库没有独立的发布打包脚本或 release orchestrator。
2. `RRP-26` 应直接基于 Flutter/Gradle/Windows 构建入口做冒烟，并继续核对安装包内容不含：
   - `local/`
   - `artifacts/`
   - `test_api.txt`
   - 参考项目目录
   - probe 临时报告与截图产物
