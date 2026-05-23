const String providerModelCapabilitiesSeed = r'''
{
  "version": 1,
  "defaults": {
    "capabilities": {
      "supports_streaming": true,
      "supports_tools": true,
      "supports_tool_choice": false,
      "supports_image_generation": false
    }
  },
  "providers": [
    {
      "id": "openai",
      "label": "OpenAI / Azure OpenAI",
      "match": {
        "any": [
          {"base_url_contains": ["api.openai.com", "openai.azure.com"]},
          {"credential_name_contains": ["openai", "azure openai", "aoai"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": true
      },
      "parameter_definitions": [
        {
          "key": "parallel_tool_calls",
          "type": "boolean",
          "default": true,
          "description": "允许模型在一轮回复中并行发起多个工具调用；如服务商不兼容，应在模型自定义参数里关闭或移除。",
          "exclusive_group": "tool_parallelism"
        },
        {
          "key": "reasoning_effort",
          "type": "string",
          "allowed_values": ["low", "medium", "high"],
          "description": "推理模型的思考强度。NOVEL Agent 会优先通过模型的 thinking_parameter_format 和智能体思考设置生成该字段。"
        }
      ],
      "models": [
        {
          "id": "openai_reasoning_models",
          "match": {"model_prefixes": ["o1", "o3", "o4"]},
          "profile_defaults": {
            "thinking_parameter_format": "reasoning_effort_only"
          }
        }
      ]
    },
    {
      "id": "anthropic",
      "label": "Anthropic",
      "match": {
        "any": [
          {"kind": "anthropic_compatible"},
          {"base_url_contains": ["anthropic.com"]},
          {"model_contains": ["claude"]}
        ]
      },
      "capabilities": {
        "supports_streaming": false,
        "supports_tools": true,
        "supports_tool_choice": true
      },
      "parameter_definitions": [
        {
          "key": "thinking",
          "type": "json",
          "description": "Anthropic 风格的思考配置对象；具体结构随模型版本变化，应作为高级参数按需启用。",
          "exclusive_group": "thinking_mode",
          "conflicts_with": ["enable_thinking", "reasoning_effort"]
        }
      ]
    },
    {
      "id": "deepseek",
      "label": "DeepSeek",
      "match": {
        "any": [
          {"base_url_contains": ["api.deepseek.com", "deepseek"]},
          {"credential_name_contains": ["deepseek", "深度求索", "深度思考"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "profile_defaults": {
        "thinking_parameter_format": "deepseek_thinking_object"
      },
      "parameter_definitions": [
        {
          "key": "thinking",
          "type": "json",
          "description": "DeepSeek thinking 对象，例如 {\"type\":\"enabled\"}。由 NOVEL Agent 根据智能体思考开关自动生成，不建议手动重复填写。",
          "exclusive_group": "thinking_mode",
          "conflicts_with": ["enable_thinking"]
        },
        {
          "key": "reasoning_effort",
          "type": "string",
          "allowed_values": ["low", "medium", "high"],
          "description": "DeepSeek 深度思考强度。由智能体层的思考强度映射得到。",
          "exclusive_group": "thinking_effort"
        }
      ],
      "excluded_parameters": ["tool_choice"],
      "models": [
        {
          "id": "deepseek_v4_flash",
          "match": {"model_contains": ["deepseek-v4-flash", "deepseek-ai/deepseek-v4-flash", "deepseek-ai/DeepSeek-V4-Flash"]},
          "capabilities": {
            "supports_streaming": true,
            "supports_tools": true,
            "supports_tool_choice": false,
            "supports_response_format": true,
            "supports_parallel_tool_calls": true
          },
          "profile_defaults": {
            "thinking_parameter_format": "deepseek_thinking_object"
          },
          "parameter_definitions": [
            {
              "key": "stream_options",
              "type": "json",
              "description": "LiteLLM 参数表提示 DeepSeek V4 Flash 可接收流式选项；实际启用前仍应做服务商兼容测试。"
            },
            {
              "key": "parallel_tool_calls",
              "type": "boolean",
              "description": "LiteLLM 参数表提示 DeepSeek V4 Flash 可能支持并行工具调用；NOVEL Agent 默认不主动发送，避免聚合接口兼容问题。",
              "exclusive_group": "tool_parallelism"
            },
            {
              "key": "response_format",
              "type": "json",
              "description": "LiteLLM 参数表提示 DeepSeek V4 Flash 可接收结构化输出格式；应作为高级参数按需启用。"
            }
          ],
          "excluded_parameters": ["tool_choice"]
        },
        {
          "id": "deepseek_reasoner",
          "match": {"model_contains": ["deepseek-reasoner", "reasoner", "deepseek-r1"]},
          "capabilities": {
            "supports_tools": true,
            "supports_tool_choice": false
          },
          "profile_defaults": {
            "thinking_parameter_format": "deepseek_thinking_object"
          },
          "excluded_parameters": ["tool_choice"]
        },
        {
          "id": "deepseek_v4_family",
          "match": {"model_contains": ["deepseek-v4", "deepseek-ai/deepseek-v4"]},
          "capabilities": {
            "supports_tools": true,
            "supports_tool_choice": false
          },
          "profile_defaults": {
            "thinking_parameter_format": "deepseek_thinking_object"
          },
          "excluded_parameters": ["tool_choice"]
        }
      ]
    },
    {
      "id": "siliconflow",
      "label": "硅基流动 / SiliconFlow",
      "match": {
        "any": [
          {"base_url_contains": ["siliconflow", "siliconcloud"]},
          {"credential_name_contains": ["siliconflow", "硅基流动", "硅基"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "parameter_definitions": [
        {
          "key": "enable_thinking",
          "type": "boolean",
          "description": "部分 OpenAI-compatible 聚合接口使用布尔字段启用思考；具体是否可用取决于模型。",
          "exclusive_group": "thinking_mode",
          "conflicts_with": ["thinking"]
        },
        {
          "key": "reasoning_effort",
          "type": "string",
          "allowed_values": ["low", "medium", "high"],
          "description": "部分模型接受的思考强度字段；应与模型的思考参数格式配套使用。"
        }
      ]
    }
  ],
  "model_rules": [
    {
      "id": "deepseek_v4_flash_any_provider",
      "match": {"model_contains": ["deepseek-v4-flash", "deepseek-ai/deepseek-v4-flash", "deepseek-ai/DeepSeek-V4-Flash"]},
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false,
        "supports_response_format": true,
        "supports_parallel_tool_calls": true
      },
      "profile_defaults": {
        "thinking_parameter_format": "deepseek_thinking_object"
      },
      "parameter_definitions": [
        {
          "key": "thinking",
          "type": "json",
          "description": "DeepSeek V4 Flash 的 thinking 对象，由 NOVEL Agent 根据智能体思考开关自动生成。"
        },
        {
          "key": "reasoning_effort",
          "type": "string",
          "allowed_values": ["low", "medium", "high"],
          "description": "DeepSeek V4 Flash 的思考强度字段，由智能体层映射。"
        }
      ],
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "deepseek_reasoning_any_provider",
      "match": {"model_contains": ["deepseek-reasoner", "reasoner", "deepseek-r1"]},
      "capabilities": {
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "profile_defaults": {
        "thinking_parameter_format": "deepseek_thinking_object"
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "deepseek_v4_any_provider",
      "match": {"model_contains": ["deepseek-v4", "deepseek-ai/deepseek-v4"]},
      "capabilities": {
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "profile_defaults": {
        "thinking_parameter_format": "deepseek_thinking_object"
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "qwen_thinking_boolean",
      "match": {"model_contains": ["qwen", "qwq"]},
      "profile_defaults": {
        "thinking_parameter_format": "enable_thinking_boolean"
      },
      "parameter_definitions": [
        {
          "key": "enable_thinking",
          "type": "boolean",
          "description": "Qwen/QwQ 系模型常见的思考开关字段；是否发送由智能体思考选项决定。",
          "exclusive_group": "thinking_mode",
          "conflicts_with": ["thinking"]
        }
      ]
    }
  ]
}
''';
