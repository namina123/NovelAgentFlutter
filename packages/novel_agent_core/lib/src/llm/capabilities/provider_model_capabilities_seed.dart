const String providerModelCapabilitiesSeed = r'''
{
  "version": 1,
  "defaults": {
    "capabilities": {
      "supports_streaming": true,
      "supports_tools": true,
      "supports_tool_choice": false,
      "supports_image_generation": false,
      "supports_file_attachments": false,
      "supports_image_attachments": false,
      "supports_attachment_urls_only": false,
      "supports_multi_attachments": false
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
          "description": "推理模型的思考强度。具体可用取值由模型层或中转层决定，NOVEL Agent 只负责按模型语义透传。"
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
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": true,
        "supports_file_attachments": true,
        "supports_image_attachments": true,
        "supports_attachment_urls_only": false,
        "supports_multi_attachments": true
      },
      "parameter_definitions": [
        {
          "key": "tool_choice",
          "type": "json",
          "description": "Anthropic 的工具选择参数，支持 auto / any / tool / none 等形式；应与 tools 一起按模型能力透传。",
          "exclusive_group": "tool_choice_mode"
        },
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
          "description": "DeepSeek 深度思考强度。实际取值由具体模型版本决定，可能与通用 low/medium/high 词表不同。",
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
          "description": "部分模型接受的思考强度字段；应与模型的思考参数格式配套使用，取值由模型或中转层决定。"
        }
      ]
    },
    {
      "id": "tencent_hunyuan",
      "label": "腾讯混元",
      "match": {
        "any": [
          {"base_url_contains": ["hunyuan.cloud.tencent.com", "api.hunyuan.cloud.tencent.com"]},
          {"credential_name_contains": ["hunyuan", "腾讯混元", "腾讯云混元"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "baidu_qianfan",
      "label": "百度千帆 / 文心",
      "match": {
        "any": [
          {"base_url_contains": ["qianfan.baidubce.com", "baidu.com"]},
          {"credential_name_contains": ["qianfan", "百度千帆", "文心", "ernie"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "dashscope_coding",
      "label": "Qwen Coding / DashScope Coding",
      "match": {
        "any": [
          {"base_url_contains": ["coding.dashscope.aliyuncs.com"]},
          {"credential_name_contains": ["qwen code", "qwen coding", "coding plan"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "minimax",
      "label": "MiniMax",
      "match": {
        "any": [
          {"base_url_contains": ["api.minimaxi.com", "api.minimax.chat"]},
          {"credential_name_contains": ["minimax", "abab", "海螺", "m2"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "baichuan",
      "label": "百川 / Baichuan",
      "match": {
        "any": [
          {"base_url_contains": ["api.baichuan-ai.com"]},
          {"credential_name_contains": ["baichuan", "百川"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "excluded_parameters": ["tool_choice"]
    },
    {
      "id": "doubao",
      "label": "Doubao / 火山方舟",
      "match": {
        "any": [
          {"base_url_contains": ["ark.cn-beijing.volces.com", "volces.com/api/v3", "ark"]},
          {"credential_name_contains": ["doubao", "火山方舟", "ark", "volcengine"]}
        ]
      },
      "capabilities": {
        "supports_streaming": true,
        "supports_tools": true,
        "supports_tool_choice": false
      },
      "parameter_definitions": [
        {
          "key": "reasoning_effort",
          "type": "string",
          "description": "火山方舟部分模型会接受思考强度映射；如服务商实现不同，应由具体模型覆盖。"
        }
      ],
      "excluded_parameters": ["tool_choice"]
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
          "description": "DeepSeek V4 Flash 的思考强度字段，由智能体层映射，具体词表取决于服务商版本。"
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
