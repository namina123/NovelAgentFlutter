const String providerInterfaceTemplateSeed = r'''
{
  "version": 1,
  "templates": [
    {
      "id": "deepseek_openai",
      "provider_id": "deepseek",
      "label": "DeepSeek",
      "aliases": ["deepseek", "深度求索", "deepseek openai"],
      "protocol": "openai_compatible",
      "default_base_url": "https://api.deepseek.com",
      "base_url_hints": ["api.deepseek.com", "deepseek"],
      "route_family": "chat_completions",
      "notes": "DeepSeek 官方 OpenAI 兼容入口。"
    },
    {
      "id": "deepseek_anthropic",
      "provider_id": "deepseek",
      "label": "DeepSeek · Anthropic",
      "aliases": ["deepseek anthropic", "deepseek claude"],
      "protocol": "anthropic_compatible",
      "default_base_url": "https://api.deepseek.com/anthropic",
      "base_url_hints": ["api.deepseek.com/anthropic"],
      "route_family": "messages",
      "notes": "DeepSeek 官方 Anthropic 兼容入口。"
    },
    {
      "id": "siliconflow_openai",
      "provider_id": "siliconflow",
      "label": "硅基流动",
      "aliases": ["siliconflow", "silicon flow", "硅基", "硅基流动"],
      "protocol": "openai_compatible",
      "default_base_url": "https://api.siliconflow.cn/v1",
      "base_url_hints": ["api.siliconflow.cn", "siliconflow", "siliconcloud"],
      "route_family": "chat_completions",
      "notes": "多模型聚合平台，具体能力应以模型 offering 为准。"
    },
    {
      "id": "openai_api",
      "provider_id": "openai",
      "label": "OpenAI",
      "aliases": ["openai", "chatgpt", "gpt"],
      "protocol": "openai_compatible",
      "default_base_url": "https://api.openai.com/v1",
      "base_url_hints": ["api.openai.com"],
      "route_family": "responses_and_chat",
      "notes": "OpenAI 官方接口；具体 endpoint family 仍应由模型/运行配置决定。"
    },
    {
      "id": "anthropic_api",
      "provider_id": "anthropic",
      "label": "Anthropic",
      "aliases": ["anthropic", "claude"],
      "protocol": "anthropic_compatible",
      "default_base_url": "https://api.anthropic.com/v1",
      "base_url_hints": ["api.anthropic.com", "anthropic.com", "claude"],
      "route_family": "messages",
      "notes": "Anthropic 官方 Messages API。"
    },
    {
      "id": "glm_openai",
      "provider_id": "glm",
      "label": "Z.AI / GLM",
      "aliases": ["glm", "bigmodel", "z.ai", "智谱", "glm openai"],
      "protocol": "openai_compatible",
      "default_base_url": "https://open.bigmodel.cn/api/paas/v4",
      "base_url_hints": ["open.bigmodel.cn/api/paas/v4"],
      "route_family": "chat_completions",
      "notes": "GLM 官方 OpenAI 兼容入口。"
    },
    {
      "id": "glm_anthropic",
      "provider_id": "glm",
      "label": "Z.AI / GLM · Anthropic",
      "aliases": ["glm anthropic", "bigmodel anthropic", "z.ai anthropic"],
      "protocol": "anthropic_compatible",
      "default_base_url": "https://open.bigmodel.cn/api/anthropic",
      "base_url_hints": ["open.bigmodel.cn/api/anthropic"],
      "route_family": "messages",
      "notes": "GLM 官方 Anthropic 兼容入口。"
    },
    {
      "id": "moonshot_openai",
      "provider_id": "moonshot",
      "label": "Kimi / Moonshot",
      "aliases": ["moonshot", "kimi", "moonshot ai", "kimi openai"],
      "protocol": "openai_compatible",
      "default_base_url": "https://api.moonshot.cn/v1",
      "base_url_hints": ["api.moonshot.cn"],
      "route_family": "chat_completions",
      "notes": "Moonshot/Kimi 官方接口。"
    },
    {
      "id": "mimo_openai",
      "provider_id": "mimo",
      "label": "MiMo / Xiaomi",
      "aliases": ["mimo", "xiaomi mimo", "mimo openai", "小米"],
      "protocol": "openai_compatible",
      "default_base_url": "https://api.xiaomimimo.com/v1",
      "base_url_hints": ["api.xiaomimimo.com/v1"],
      "route_family": "chat_completions",
      "notes": "MiMo 官方 OpenAI 兼容入口。"
    },
    {
      "id": "mimo_anthropic",
      "provider_id": "mimo",
      "label": "MiMo / Xiaomi · Anthropic",
      "aliases": ["mimo anthropic", "xiaomi mimo anthropic"],
      "protocol": "anthropic_compatible",
      "default_base_url": "https://api.xiaomimimo.com/anthropic",
      "base_url_hints": ["api.xiaomimimo.com/anthropic"],
      "route_family": "messages",
      "notes": "MiMo 官方 Anthropic 兼容入口。"
    },
    {
      "id": "doubao_openai",
      "provider_id": "doubao",
      "label": "Doubao / 火山方舟",
      "aliases": ["doubao", "火山方舟", "doubao openai", "ark"],
      "protocol": "openai_compatible",
      "default_base_url": "https://ark.cn-beijing.volces.com/api/v3",
      "base_url_hints": ["volces.com/api/v3", "ark"],
      "route_family": "chat_and_responses",
      "notes": "火山方舟 OpenAI 风格接入；具体 Chat/Responses 能力需按模型 offering 判断。"
    },
    {
      "id": "dashscope_openai_cn",
      "provider_id": "dashscope",
      "label": "百炼 / DashScope",
      "aliases": ["dashscope", "百炼", "model studio", "bailian"],
      "protocol": "openai_compatible",
      "default_base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1",
      "base_url_hints": ["dashscope.aliyuncs.com/compatible-mode/v1"],
      "route_family": "chat_completions",
      "notes": "百炼中国内地 OpenAI 兼容入口。"
    },
    {
      "id": "dashscope_openai_us",
      "provider_id": "dashscope",
      "label": "百炼 / DashScope · US",
      "aliases": ["dashscope us", "bailian us"],
      "protocol": "openai_compatible",
      "default_base_url": "https://dashscope-us.aliyuncs.com/compatible-mode/v1",
      "base_url_hints": ["dashscope-us.aliyuncs.com/compatible-mode/v1"],
      "route_family": "chat_completions",
      "notes": "百炼美国区 OpenAI 兼容入口。"
    },
    {
      "id": "dashscope_openai_sg",
      "provider_id": "dashscope",
      "label": "百炼 / DashScope · SG",
      "aliases": ["dashscope sg", "bailian sg"],
      "protocol": "openai_compatible",
      "default_base_url": "https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
      "base_url_hints": ["dashscope-intl.aliyuncs.com/compatible-mode/v1"],
      "route_family": "chat_completions",
      "notes": "百炼新加坡区 OpenAI 兼容入口。"
    },
    {
      "id": "dashscope_anthropic",
      "provider_id": "dashscope",
      "label": "百炼 / DashScope · Anthropic",
      "aliases": ["dashscope anthropic", "bailian anthropic"],
      "protocol": "anthropic_compatible",
      "default_base_url": "",
      "base_url_hints": ["apps/anthropic"],
      "route_family": "messages",
      "notes": "百炼 Anthropic 兼容能力入口；具体地址通常受套餐/应用形态影响。"
    },
    {
      "id": "nvidia_openai",
      "provider_id": "nvidia",
      "label": "NVIDIA API Catalog",
      "aliases": ["nvidia", "nim", "nvidia api catalog"],
      "protocol": "openai_compatible",
      "default_base_url": "https://integrate.api.nvidia.com/v1",
      "base_url_hints": ["integrate.api.nvidia.com"],
      "route_family": "chat_completions",
      "notes": "NVIDIA 聚合式模型托管入口。"
    },
    {
      "id": "opencode_zen",
      "provider_id": "opencode_zen",
      "label": "OpenCode Zen",
      "aliases": ["opencode zen", "zen"],
      "protocol": "openai_compatible",
      "default_base_url": "https://opencode.ai/zen",
      "base_url_hints": ["opencode.ai/zen"],
      "route_family": "mixed",
      "notes": "OpenCode Zen 是多协议路由壳层，具体模型可能走 OpenAI、Anthropic 或 Google 风格路径。"
    },
    {
      "id": "opencode_go",
      "provider_id": "opencode_go",
      "label": "OpenCode Go",
      "aliases": ["opencode go", "go"],
      "protocol": "openai_compatible",
      "default_base_url": "https://opencode.ai/zen/go/v1",
      "base_url_hints": ["opencode.ai/zen/go/v1"],
      "route_family": "mixed",
      "notes": "OpenCode Go 是多协议路由壳层，具体模型会分流到 messages/chat/models 等不同 endpoint。"
    }
  ]
}
''';
