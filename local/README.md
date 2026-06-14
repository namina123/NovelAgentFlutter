# Local Secrets And Probe Config

这个目录只用于本机、不入库的本地配置。

可放内容包括：

- 真实接口探针配置
- 本地临时密钥
- 本地调试覆盖配置

约束：

1. 除本文件和示例文件外，其余内容默认被 `.gitignore` 忽略。
2. 不要把真实密钥写回 `test_api.txt`、源码、文档或提交记录。
3. 真实探针默认只读取 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 指定文件，不再默认回退到 `test_api.txt` 或 `temp` 设置。
4. 运行真实计费 probe 前必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。

推荐文件：

- `local/probe_api.txt`

格式：

1. 第一行：`baseUrl`
2. 第二行：`apiKey`
3. 第三行：`modelId`

推荐启动方式：

1. PowerShell：
   `$env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'`
2. 如需仓库外配置文件：
   `$env:NOVEL_AGENT_PROBE_API_FILE='D:\\path\\to\\probe_api.txt'`
