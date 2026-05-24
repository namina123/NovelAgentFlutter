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
          "context_length": 200000,
          "compression_context_length": 150000,
          "max_output_tokens": 8192,
          "thinking_parameter_format": "none",
          "supported_parameters": ["tools", "temperature", "top_p", "max_tokens"],
          "unsupported_parameters": ["top_k"]
        }
      ]
    }
  ]
}
''';
