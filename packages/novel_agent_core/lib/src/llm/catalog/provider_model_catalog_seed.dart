const String providerModelCatalogSeed = r'''
{
  "version": 1,
  "providers": [
    {
      "id": "deepseek",
      "label": "DeepSeek",
      "aliases": ["deepseek", "深度求索", "深度思考"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.deepseek.com",
      "base_url_hints": ["api.deepseek.com", "deepseek"],
      "models": [
        {
          "id": "deepseek-v4-flash",
          "label": "DeepSeek V4 Flash",
          "aliases": ["deepseek v4 flash", "deepseek-v4-flash", "v4 flash", "reasoner"],
          "type": "text",
          "supports_tools": true,
          "recommended": true,
          "context_length": 131072,
          "compression_context_length": 98304,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "deepseek_thinking_object",
          "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "response_format", "parallel_tool_calls", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["tool_choice", "top_k"],
          "notes": "实际使用时可能在服务商响应中显示为 reasoner；本项目默认不发送 tool_choice。"
        },
        {
          "id": "deepseek-v4-pro",
          "label": "DeepSeek V4 Pro",
          "aliases": ["deepseek v4 pro", "deepseek-v4-pro", "v4 pro", "deepseek-v4"],
          "type": "text",
          "supports_tools": true,
          "context_length": 131072,
          "compression_context_length": 98304,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "deepseek_thinking_object",
          "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "response_format", "parallel_tool_calls", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["tool_choice", "top_k"]
        },
        {
          "id": "deepseek-chat",
          "label": "DeepSeek Chat",
          "aliases": ["deepseek chat", "deepseek-v3"],
          "type": "text",
          "supports_tools": true,
          "context_length": 65536,
          "compression_context_length": 49152,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "response_format", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["tool_choice", "top_k"]
        }
      ]
    },
    {
      "id": "siliconflow",
      "label": "硅基流动",
      "aliases": ["siliconflow", "silicon flow", "硅基", "硅基流动"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.siliconflow.cn/v1",
      "base_url_hints": ["siliconflow", "siliconcloud", "api.siliconflow.cn"],
      "models": [
        {
          "id": "deepseek-ai/DeepSeek-V4-Flash",
          "label": "DeepSeek V4 Flash（硅基流动）",
          "aliases": ["deepseek v4 flash", "deepseek-v4-flash", "v4 flash"],
          "type": "text",
          "supports_tools": true,
          "recommended": true,
          "context_length": 131072,
          "compression_context_length": 98304,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "deepseek_thinking_object",
          "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "response_format", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["tool_choice", "top_k"]
        },
        {
          "id": "Qwen/Qwen3-32B",
          "label": "Qwen3 32B",
          "aliases": ["qwen3", "通义千问", "qwen"],
          "type": "text",
          "supports_tools": true,
          "context_length": 32768,
          "compression_context_length": 24576,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "enable_thinking_boolean",
          "supported_parameters": ["stream", "tools", "enable_thinking", "temperature", "top_p", "top_k", "max_tokens"],
          "unsupported_parameters": ["tool_choice"]
        }
      ]
    },
    {
      "id": "openai",
      "label": "OpenAI",
      "aliases": ["openai", "chatgpt", "gpt"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.openai.com/v1",
      "base_url_hints": ["api.openai.com"],
      "models": [
        {
          "id": "gpt-4.1",
          "label": "GPT-4.1",
          "aliases": ["gpt4.1", "gpt 4.1"],
          "type": "text",
          "supports_tools": true,
          "context_length": 1047576,
          "compression_context_length": 786432,
          "max_output_tokens": 32768,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "response_format", "temperature", "top_p", "max_tokens", "parallel_tool_calls"],
          "unsupported_parameters": ["top_k"]
        },
        {
          "id": "o4-mini",
          "label": "o4-mini",
          "aliases": ["o4 mini", "o4"],
          "type": "text",
          "supports_tools": true,
          "context_length": 200000,
          "compression_context_length": 150000,
          "max_output_tokens": 100000,
          "thinking_parameter_format": "reasoning_effort_only",
          "supported_parameters": ["stream", "tools", "reasoning_effort", "max_tokens", "parallel_tool_calls"],
          "unsupported_parameters": ["top_k"]
        },
        {
          "id": "gpt-image-1",
          "label": "GPT Image 1",
          "aliases": ["gpt image", "image"],
          "type": "image",
          "supports_tools": false,
          "supports_image_generation": true,
          "supported_parameters": ["size", "quality", "background", "output_format"],
          "unsupported_parameters": ["tools", "tool_choice", "temperature", "top_p", "top_k"]
        }
      ]
    },
    {
      "id": "anthropic",
      "label": "Anthropic",
      "aliases": ["anthropic", "claude"],
      "kind": "anthropic_compatible",
      "default_base_url": "https://api.anthropic.com/v1",
      "base_url_hints": ["anthropic.com", "claude"],
      "models": [
        {
          "id": "claude-3-5-sonnet-20241022",
          "label": "Claude 3.5 Sonnet",
          "aliases": ["claude sonnet", "claude-3-5-sonnet"],
          "type": "text",
          "supports_tools": true,
          "supports_streaming": true,
          "context_length": 200000,
          "compression_context_length": 150000,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "tool_choice", "temperature", "top_p", "top_k", "max_tokens"],
          "unsupported_parameters": []
        }
      ]
    },
    {
      "id": "google",
      "label": "Google / Gemini",
      "aliases": ["google", "gemini", "google gemini"],
      "kind": "openai_compatible",
      "default_base_url": "https://generativelanguage.googleapis.com/v1beta",
      "base_url_hints": [
        "generativelanguage.googleapis.com/v1beta/openai",
        "generativelanguage.googleapis.com/v1beta"
      ],
      "models": [
        {
          "id": "gemini-3.5",
          "label": "Gemini 3.5",
          "aliases": ["gemini 3.5", "gemini-3.5", "gemini 3"],
          "type": "text",
          "supports_tools": true,
          "supports_streaming": true,
          "supports_file_attachments": true,
          "supports_image_attachments": true,
          "supports_multi_attachments": true,
          "context_length": 1048576,
          "compression_context_length": 786432,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "enable_thinking_boolean",
          "supported_parameters": [
            "stream",
            "tools",
            "temperature",
            "top_p",
            "thinkingLevel",
            "max_tokens"
          ],
          "unsupported_parameters": ["top_k"]
        },
        {
          "id": "gemini-2.5-pro",
          "label": "Gemini 2.5 Pro",
          "aliases": ["gemini 2.5 pro", "gemini-2.5-pro", "gemini 2.5"],
          "type": "text",
          "supports_tools": true,
          "supports_streaming": true,
          "supports_file_attachments": true,
          "supports_image_attachments": true,
          "supports_multi_attachments": true,
          "context_length": 1048576,
          "compression_context_length": 786432,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "enable_thinking_boolean",
          "supported_parameters": [
            "stream",
            "tools",
            "temperature",
            "top_p",
            "thinkingBudget",
            "max_tokens"
          ],
          "unsupported_parameters": ["top_k"]
        }
      ]
    },
    {
      "id": "tencent_hunyuan",
      "label": "腾讯混元",
      "aliases": ["hunyuan", "腾讯混元", "腾讯云混元"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.hunyuan.cloud.tencent.com/v1",
      "base_url_hints": ["api.hunyuan.cloud.tencent.com", "hunyuan.cloud.tencent.com"],
      "models": [
        {
          "id": "hunyuan-turbo",
          "label": "Hunyuan Turbo",
          "aliases": ["hunyuan turbo", "混元 turbo"],
          "type": "text",
          "supports_tools": true,
          "context_length": 128000,
          "compression_context_length": 96000,
          "max_output_tokens": 16384,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "baidu_qianfan",
      "label": "百度千帆 / 文心",
      "aliases": ["qianfan", "百度千帆", "文心", "文心一言", "ernie"],
      "kind": "openai_compatible",
      "default_base_url": "https://qianfan.baidubce.com/v2",
      "base_url_hints": ["qianfan.baidubce.com", "qianfan.baidubce.com/v2"],
      "models": [
        {
          "id": "ernie-4.5",
          "label": "ERNIE 4.5",
          "aliases": ["ernie 4.5", "文心 4.5"],
          "type": "text",
          "supports_tools": true,
          "context_length": 128000,
          "compression_context_length": 96000,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "minimax",
      "label": "MiniMax",
      "aliases": ["minimax", "abab", "海螺", "m2", "mini max"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.minimaxi.com/v1",
      "base_url_hints": ["api.minimaxi.com", "api.minimax.chat"],
      "models": [
        {
          "id": "abab6.5",
          "label": "ABAB 6.5",
          "aliases": ["abab6.5", "abab 6.5", "abab", "abab-6.5"],
          "type": "text",
          "supports_tools": true,
          "context_length": 128000,
          "compression_context_length": 96000,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        },
        {
          "id": "m2.7",
          "label": "MiniMax M2.7",
          "aliases": ["m2.7", "m2", "minimax m2.7"],
          "type": "text",
          "supports_tools": true,
          "context_length": 1000000,
          "compression_context_length": 750000,
          "max_output_tokens": 80000,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "baichuan",
      "label": "百川 / Baichuan",
      "aliases": ["baichuan", "百川", "baichuan ai"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.baichuan-ai.com/v1",
      "base_url_hints": ["api.baichuan-ai.com"],
      "models": [
        {
          "id": "baichuan4",
          "label": "Baichuan 4",
          "aliases": ["baichuan-4", "baichuan 4", "baichuan4"],
          "type": "text",
          "supports_tools": true,
          "context_length": 131072,
          "compression_context_length": 98304,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "yi",
      "label": "零一万物 / Yi",
      "aliases": ["yi", "01ai", "零一万物", "lingyi", "yi-large"],
      "kind": "openai_compatible",
      "default_base_url": "https://api.lingyiwanwu.com/v1",
      "base_url_hints": ["api.lingyiwanwu.com", "api.01.ai"],
      "models": [
        {
          "id": "yi-large",
          "label": "Yi-Large",
          "aliases": ["yi large", "yi-large", "yi large model"],
          "type": "text",
          "supports_tools": true,
          "context_length": 128000,
          "compression_context_length": 96000,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "doubao",
      "label": "Doubao / 火山方舟",
      "aliases": ["doubao", "火山方舟", "ark", "volcengine"],
      "kind": "openai_compatible",
      "default_base_url": "https://ark.cn-beijing.volces.com/api/v3",
      "base_url_hints": ["ark.cn-beijing.volces.com", "volces.com/api/v3", "ark"],
      "models": [
        {
          "id": "doubao-seed-1.8",
          "label": "Doubao Seed 1.8",
          "aliases": ["doubao seed 1.8", "seed 1.8"],
          "type": "text",
          "supports_tools": true,
          "context_length": 256000,
          "compression_context_length": 192000,
          "max_output_tokens": 65536,
          "thinking_parameter_format": "deepseek_thinking_object",
          "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k", "tool_choice"]
        }
      ]
    },
    {
      "id": "dashscope_coding",
      "label": "Qwen Coding / DashScope Coding",
      "aliases": ["qwen code", "qwen coding", "coding plan"],
      "kind": "openai_compatible",
      "default_base_url": "https://coding.dashscope.aliyuncs.com/v1",
      "base_url_hints": ["coding.dashscope.aliyuncs.com"],
      "models": [
        {
          "id": "qwen3-coder-plus",
          "label": "Qwen3 Coder Plus",
          "aliases": ["qwen3 coder plus", "qwen coder plus"],
          "type": "text",
          "supports_tools": true,
          "context_length": 131072,
          "compression_context_length": 98304,
          "max_output_tokens": 32768,
          "thinking_parameter_format": "enable_thinking_boolean",
          "supported_parameters": ["stream", "tools", "enable_thinking", "temperature", "top_p", "top_k", "max_tokens"],
          "unsupported_parameters": ["tool_choice"]
        },
        {
          "id": "qwen3-32b",
          "label": "Qwen3 32B",
          "aliases": ["qwen3 32b", "qwen3"],
          "type": "text",
          "supports_tools": true,
          "context_length": 32768,
          "compression_context_length": 24576,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "enable_thinking_boolean",
          "supported_parameters": ["stream", "tools", "enable_thinking", "temperature", "top_p", "top_k", "max_tokens"],
          "unsupported_parameters": ["tool_choice"]
        }
      ]
    }
  ]
}
''';
