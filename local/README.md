# Local Secrets And Probe Config

这个目录只用于本机、不入库的本地配置。

可放内容包括：

- 真实接口探针配置
- 本地临时密钥
- 本地调试覆盖配置

约束：

1. 除本文件和示例文件外，其余内容默认被 `.gitignore` 忽略。
2. 不要把真实密钥写回 `test_api.txt`、源码、文档或提交记录。
3. 真实探针默认应优先读取 `local/probe_api.txt`。

推荐文件：

- `local/probe_api.txt`

格式：

1. 第一行：`baseUrl`
2. 第二行：`apiKey`
3. 第三行：`modelId`
