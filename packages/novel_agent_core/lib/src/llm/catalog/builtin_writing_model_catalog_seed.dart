const String builtinWritingModelCatalogSeed = r'''
{
  "version": 1,
  "models": [
    {
      "canonical_model_id": "openai:gpt-5.5",
      "vendor_id": "openai",
      "vendor_label": "OpenAI",
      "family": "gpt-5.5",
      "snapshot": "latest",
      "display_name": "GPT-5.5",
      "aliases": ["gpt-5.5", "gpt55"],
      "context_length": 1050000,
      "compression_context_length": 800000,
      "max_output_tokens": 128000,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": false,
        "mode_behavior": "unsupported"
      },
      "notes": "当前写作场景下的通用 GPT 主线条目。"
    },
    {
      "canonical_model_id": "openai:o4-mini",
      "vendor_id": "openai",
      "vendor_label": "OpenAI",
      "family": "o4",
      "snapshot": "mini",
      "display_name": "o4-mini",
      "aliases": ["o4-mini", "o4 mini"],
      "context_length": 200000,
      "compression_context_length": 150000,
      "max_output_tokens": 100000,
      "supports_temperature": false,
      "supports_top_p": false,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "reasoning_effort", "max_tokens", "parallel_tool_calls"],
      "unsupported_parameters": ["temperature", "top_p", "top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "thinking_required_not_disableable",
        "can_toggle": false,
        "default_enabled": true,
        "supports_effort": true,
        "effort_options": ["low", "medium", "high"],
        "default_effort": "medium",
        "toggle_parameter_strategy": {
          "kind": "reasoning_always_on"
        },
        "effort_parameter_strategy": {
          "kind": "reasoning_effort_only",
          "key": "reasoning_effort"
        }
      }
    },
    {
      "canonical_model_id": "anthropic:claude-sonnet-4.8",
      "vendor_id": "anthropic",
      "vendor_label": "Anthropic",
      "family": "claude-sonnet",
      "snapshot": "4.8",
      "display_name": "Claude Sonnet 4.8",
      "aliases": ["claude sonnet 4.8", "claude-4.8-sonnet"],
      "context_length": 200000,
      "compression_context_length": 150000,
      "max_output_tokens": 64000,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supports_file_attachments": true,
      "supports_image_attachments": true,
      "supports_multi_attachments": true,
      "supported_parameters": ["tools", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": false,
        "supports_effort": false,
        "toggle_parameter_strategy": {
          "kind": "anthropic_thinking_object"
        }
      }
    },
    {
      "canonical_model_id": "anthropic:claude-sonnet-3.7",
      "vendor_id": "anthropic",
      "vendor_label": "Anthropic",
      "family": "claude-sonnet",
      "snapshot": "3.7",
      "display_name": "Claude Sonnet 3.7",
      "aliases": ["claude sonnet 3.7", "claude-3.7-sonnet"],
      "context_length": 200000,
      "compression_context_length": 150000,
      "max_output_tokens": 64000,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supports_file_attachments": true,
      "supports_image_attachments": true,
      "supports_multi_attachments": true,
      "supported_parameters": ["tools", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "legacy",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": false,
        "supports_effort": false,
        "toggle_parameter_strategy": {
          "kind": "anthropic_thinking_object"
        }
      }
    },
    {
      "canonical_model_id": "google:gemini-3.5",
      "vendor_id": "google",
      "vendor_label": "Google",
      "family": "gemini-3.5",
      "snapshot": "latest",
      "display_name": "Gemini 3.5",
      "aliases": ["gemini 3.5", "gemini-3.5"],
      "context_length": 1048576,
      "compression_context_length": 786432,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supports_file_attachments": true,
      "supports_image_attachments": true,
      "supports_multi_attachments": true,
      "supported_parameters": ["stream", "tools", "temperature", "top_p", "thinkingLevel", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": true,
        "effort_options": ["minimal", "low", "medium", "high"],
        "default_effort": "medium",
        "toggle_parameter_strategy": {
          "kind": "level_enum"
        },
        "effort_parameter_strategy": {
          "kind": "level_enum",
          "key": "thinkingLevel"
        }
      }
    },
    {
      "canonical_model_id": "google:gemini-2.5-pro",
      "vendor_id": "google",
      "vendor_label": "Google",
      "family": "gemini-2.5",
      "snapshot": "pro",
      "display_name": "Gemini 2.5 Pro",
      "aliases": ["gemini 2.5 pro", "gemini-2.5-pro"],
      "context_length": 1048576,
      "compression_context_length": 786432,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supports_file_attachments": true,
      "supports_image_attachments": true,
      "supports_multi_attachments": true,
      "supported_parameters": ["stream", "tools", "temperature", "top_p", "thinkingBudget", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "thinking_required_not_disableable",
        "can_toggle": false,
        "default_enabled": true,
        "supports_effort": true,
        "effort_options": ["dynamic", "budget"],
        "default_effort": "dynamic",
        "toggle_parameter_strategy": {
          "kind": "budget_tokens_not_disableable"
        },
        "effort_parameter_strategy": {
          "kind": "budget_tokens",
          "key": "thinkingBudget"
        }
      }
    },
    {
      "canonical_model_id": "deepseek:deepseek-v4-flash",
      "vendor_id": "deepseek",
      "vendor_label": "DeepSeek",
      "family": "deepseek-v4",
      "snapshot": "flash",
      "display_name": "DeepSeek V4 Flash",
      "aliases": ["deepseek-v4-flash", "deepseek v4 flash", "deepseek-ai/deepseek-v4-flash"],
      "context_length": 131072,
      "compression_context_length": 98304,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "response_format", "parallel_tool_calls", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["tool_choice", "top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_default_on",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": true,
        "effort_options": ["low", "medium", "high", "max", "xhigh"],
        "default_effort": "high",
        "toggle_parameter_strategy": {
          "kind": "thinking_object",
          "key": "thinking",
          "enabled_value": {"type": "enabled"},
          "disabled_value": {"type": "disabled"}
        },
        "effort_parameter_strategy": {
          "kind": "custom_text",
          "key": "reasoning_effort"
        }
      },
      "provider_offerings": [
        {
          "provider_id": "deepseek",
          "provider_label": "DeepSeek",
          "provider_model_id": "deepseek-v4-flash",
          "base_url_hint": "api.deepseek.com"
        },
        {
          "provider_id": "siliconflow",
          "provider_label": "硅基流动",
          "provider_model_id": "deepseek-ai/DeepSeek-V4-Flash",
          "base_url_hint": "api.siliconflow.cn",
          "reasoning_override": {
            "toggle_parameter_strategy": {
              "kind": "boolean",
              "key": "enable_thinking",
              "enabled_value": true,
              "disabled_value": false
            },
            "effort_parameter_strategy": {
              "kind": "custom_text",
              "key": "reasoning_effort"
            }
          },
          "supported_parameters_override": ["temperature", "top_p", "enable_thinking", "reasoning_effort"],
          "notes": "部分中转会把原厂 thinking object 改写为 enable_thinking。"
        },
        {
          "provider_id": "opencode_go",
          "provider_label": "OpenCode Go",
          "provider_model_id": "DeepSeek V4 Flash"
        }
      ]
    },
    {
      "canonical_model_id": "deepseek:deepseek-v4-pro",
      "vendor_id": "deepseek",
      "vendor_label": "DeepSeek",
      "family": "deepseek-v4",
      "snapshot": "pro",
      "display_name": "DeepSeek V4 Pro",
      "aliases": ["deepseek-v4-pro", "deepseek v4 pro", "deepseek-ai/deepseek-v4-pro"],
      "context_length": 131072,
      "compression_context_length": 98304,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "response_format", "parallel_tool_calls", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["tool_choice", "top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_default_on",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": true,
        "effort_options": ["low", "medium", "high", "max", "xhigh"],
        "default_effort": "high",
        "toggle_parameter_strategy": {
          "kind": "thinking_object",
          "key": "thinking",
          "enabled_value": {"type": "enabled"},
          "disabled_value": {"type": "disabled"}
        },
        "effort_parameter_strategy": {
          "kind": "custom_text",
          "key": "reasoning_effort"
        }
      },
      "provider_offerings": [
        {
          "provider_id": "deepseek",
          "provider_label": "DeepSeek",
          "provider_model_id": "deepseek-v4-pro",
          "base_url_hint": "api.deepseek.com"
        },
        {
          "provider_id": "opencode_go",
          "provider_label": "OpenCode Go",
          "provider_model_id": "DeepSeek V4 Pro"
        }
      ]
    },
    {
      "canonical_model_id": "deepseek:deepseek-chat",
      "vendor_id": "deepseek",
      "vendor_label": "DeepSeek",
      "family": "deepseek-chat",
      "snapshot": "legacy",
      "display_name": "DeepSeek Chat",
      "aliases": ["deepseek-chat", "deepseek-v3"],
      "context_length": 65536,
      "compression_context_length": 49152,
      "max_output_tokens": 8192,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "response_format", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["tool_choice", "top_k"],
      "status": "deprecated",
      "reasoning": {
        "supported": false,
        "mode_behavior": "unsupported"
      },
      "notes": "保留为历史兼容条目。"
    },
    {
      "canonical_model_id": "qwen:qwen-3.6-plus",
      "vendor_id": "qwen",
      "vendor_label": "Qwen",
      "family": "qwen-3.6",
      "snapshot": "plus",
      "display_name": "Qwen 3.6 Plus",
      "aliases": ["qwen3.6 plus", "qwen-3.6-plus"],
      "context_length": 32768,
      "compression_context_length": 24576,
      "max_output_tokens": 8192,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "enable_thinking", "temperature", "top_p", "top_k", "max_tokens"],
      "unsupported_parameters": ["tool_choice"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_default_on",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": false,
        "toggle_parameter_strategy": {
          "kind": "boolean",
          "key": "enable_thinking",
          "enabled_value": true,
          "disabled_value": false
        }
      }
    },
    {
      "canonical_model_id": "glm:glm-5.1",
      "vendor_id": "glm",
      "vendor_label": "Z.AI / GLM",
      "family": "glm-5",
      "snapshot": "5.1",
      "display_name": "GLM-5.1",
      "aliases": ["glm-5.1", "glm 5.1"],
      "context_length": 131072,
      "compression_context_length": 98304,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_default_on",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": false,
        "toggle_parameter_strategy": {
          "kind": "thinking_object",
          "key": "thinking",
          "enabled_value": {"type": "enabled"},
          "disabled_value": {"type": "disabled"}
        }
      }
    },
    {
      "canonical_model_id": "moonshot:kimi-k2.6",
      "vendor_id": "moonshot",
      "vendor_label": "Kimi / Moonshot",
      "family": "kimi-k2",
      "snapshot": "2.6",
      "display_name": "Kimi K2.6",
      "aliases": ["kimi-k2.6", "kimi k2.6"],
      "context_length": 256000,
      "compression_context_length": 192000,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_default_on",
        "can_toggle": true,
        "default_enabled": true,
        "supports_effort": false,
        "toggle_parameter_strategy": {
          "kind": "thinking_object",
          "key": "thinking",
          "enabled_value": {"type": "enabled"},
          "disabled_value": {"type": "disabled"}
        }
      }
    },
    {
      "canonical_model_id": "moonshot:kimi-k2-thinking",
      "vendor_id": "moonshot",
      "vendor_label": "Kimi / Moonshot",
      "family": "kimi-k2",
      "snapshot": "thinking",
      "display_name": "Kimi K2 Thinking",
      "aliases": ["kimi-k2-thinking", "kimi k2 thinking"],
      "context_length": 256000,
      "compression_context_length": 192000,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "thinking_only",
        "can_toggle": false,
        "default_enabled": true,
        "supports_effort": false
      }
    },
    {
      "canonical_model_id": "minimax:minimax-m2.7",
      "vendor_id": "minimax",
      "vendor_label": "MiniMax",
      "family": "minimax-m2",
      "snapshot": "2.7",
      "display_name": "MiniMax M2.7",
      "aliases": ["minimax-m2.7", "minimax m2.7"],
      "context_length": 1000000,
      "compression_context_length": 750000,
      "max_output_tokens": 80000,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": false,
        "supports_effort": false
      }
    },
    {
      "canonical_model_id": "mimo:mimo-v2.5-pro",
      "vendor_id": "mimo",
      "vendor_label": "MiMo / Xiaomi",
      "family": "mimo-v2.5",
      "snapshot": "pro",
      "display_name": "MiMo V2.5 Pro",
      "aliases": ["mimo-v2.5-pro", "mimo v2.5 pro"],
      "context_length": 256000,
      "compression_context_length": 192000,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": false,
        "supports_effort": false
      }
    },
    {
      "canonical_model_id": "doubao:doubao-seed-1.8",
      "vendor_id": "doubao",
      "vendor_label": "Doubao / 火山方舟",
      "family": "doubao-seed",
      "snapshot": "1.8",
      "display_name": "Doubao Seed 1.8",
      "aliases": ["doubao-seed-1.8", "doubao seed 1.8"],
      "context_length": 256000,
      "compression_context_length": 192000,
      "max_output_tokens": 65536,
      "supports_temperature": true,
      "supports_top_p": true,
      "supports_streaming": true,
      "supports_tools": true,
      "supported_parameters": ["stream", "tools", "thinking", "reasoning_effort", "temperature", "top_p", "max_tokens"],
      "unsupported_parameters": ["top_k"],
      "status": "active",
      "reasoning": {
        "supported": true,
        "mode_behavior": "hybrid_optional",
        "can_toggle": true,
        "default_enabled": false,
        "supports_effort": true,
        "effort_options": ["low", "medium", "high"],
        "default_effort": "low",
        "toggle_parameter_strategy": {
          "kind": "thinking_object",
          "key": "thinking",
          "enabled_value": {"type": "enabled"},
          "disabled_value": {"type": "disabled"}
        },
        "effort_parameter_strategy": {
          "kind": "custom_text",
          "key": "reasoning_effort"
        }
      }
    }
  ]
}
''';
