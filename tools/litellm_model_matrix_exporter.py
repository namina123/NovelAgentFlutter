from __future__ import annotations

import json
import re
import sqlite3
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class ProviderProfile:
    provider_id: str
    vendor_name_zh: str
    protocol_id: str
    default_base_url: str | None
    aliases: tuple[str, ...] = ()
    notes: str | None = None


PROVIDER_PROFILES: dict[str, ProviderProfile] = {
    "openai": ProviderProfile("openai", "OpenAI", "openai_compatible", "https://api.openai.com/v1", ("chatgpt", "gpt")),
    "azure": ProviderProfile("azure", "微软 Azure OpenAI", "openai_compatible", None, ("azure openai", "aoai"), "Azure 需要部署名与 api-version，默认 base_url 依赖租户。"),
    "anthropic": ProviderProfile("anthropic", "Anthropic", "anthropic_compatible", "https://api.anthropic.com/v1", ("claude",)),
    "deepseek": ProviderProfile("deepseek", "深度求索", "openai_compatible", "https://api.deepseek.com", ("deepseek", "深度思考")),
    "openrouter": ProviderProfile("openrouter", "OpenRouter", "openai_compatible", "https://openrouter.ai/api/v1"),
    "dashscope": ProviderProfile("dashscope", "阿里云百炼", "openai_compatible", "https://dashscope.aliyuncs.com/compatible-mode/v1", ("ali", "aliyun", "qwen")),
    "moonshot": ProviderProfile("moonshot", "月之暗面", "openai_compatible", "https://api.moonshot.cn/v1", ("kimi",)),
    "xai": ProviderProfile("xai", "xAI", "openai_compatible", "https://api.x.ai/v1", ("grok",)),
    "groq": ProviderProfile("groq", "Groq", "openai_compatible", "https://api.groq.com/openai/v1"),
    "fireworks_ai": ProviderProfile("fireworks_ai", "Fireworks AI", "openai_compatible", "https://api.fireworks.ai/inference/v1"),
    "together_ai": ProviderProfile("together_ai", "Together AI", "openai_compatible", "https://api.together.xyz/v1"),
    "mistral": ProviderProfile("mistral", "Mistral AI", "openai_compatible", "https://api.mistral.ai/v1"),
    "perplexity": ProviderProfile("perplexity", "Perplexity", "openai_compatible", "https://api.perplexity.ai"),
    "cerebras": ProviderProfile("cerebras", "Cerebras", "openai_compatible", "https://api.cerebras.ai/v1"),
    "deepinfra": ProviderProfile("deepinfra", "DeepInfra", "openai_compatible", "https://api.deepinfra.com/v1/openai"),
    "novita": ProviderProfile("novita", "Novita AI", "openai_compatible", "https://api.novita.ai/v3/openai"),
    "nebius": ProviderProfile("nebius", "Nebius AI Studio", "openai_compatible", "https://api.studio.nebius.com/v1/"),
    "nvidia_nim": ProviderProfile("nvidia_nim", "NVIDIA NIM", "openai_compatible", "https://integrate.api.nvidia.com/v1"),
    "ollama": ProviderProfile("ollama", "Ollama", "openai_compatible", "http://127.0.0.1:11434/v1", ("local",)),
    "databricks": ProviderProfile("databricks", "Databricks", "openai_compatible", None, (), "Databricks 需要具体工作区 serving endpoint。"),
    "volcengine": ProviderProfile("volcengine", "火山引擎", "openai_compatible", None, ("ark",), "不同地域与产品线的兼容入口可能不同，应由用户自行补全。"),
}

PROVIDER_PROTOCOL_OVERRIDES: dict[str, str] = {
    "anthropic": "anthropic_compatible",
    "anthropic_text": "anthropic_compatible",
    "vertex_ai-anthropic_models": "anthropic_compatible",
    "gemini": "gemini_native",
    "vertex_ai": "vertex_ai_native",
    "vertex_ai-language-models": "vertex_ai_native",
    "vertex_ai-deepseek_models": "vertex_ai_native",
    "bedrock": "bedrock_native",
    "bedrock_converse": "bedrock_native",
    "bedrock_mantle": "bedrock_native",
    "ollama": "ollama_compatible",
    "ollama_chat": "ollama_compatible",
}

PROVIDER_DEFAULT_BASE_URLS: dict[str, str] = {
    "openrouter": "https://openrouter.ai/api/v1",
    "deepseek": "https://api.deepseek.com",
    "gemini": "https://generativelanguage.googleapis.com",
    "groq": "https://api.groq.com/openai/v1",
    "xai": "https://api.x.ai/v1",
    "mistral": "https://api.mistral.ai/v1",
    "together_ai": "https://api.together.xyz/v1",
    "perplexity": "https://api.perplexity.ai",
    "cerebras": "https://api.cerebras.ai/v1",
    "deepinfra": "https://api.deepinfra.com/v1/openai",
    "novita": "https://api.novita.ai/v3/openai",
    "nebius": "https://api.studio.nebius.com/v1/",
    "nvidia_nim": "https://integrate.api.nvidia.com/v1",
    "moonshot": "https://api.moonshot.cn/v1",
    "dashscope": "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "fireworks_ai": "https://api.fireworks.ai/inference/v1",
    "ollama": "http://127.0.0.1:11434/v1",
}

PROVIDER_VENDOR_NAME_ZH_OVERRIDES: dict[str, str] = {
    "azure_ai": "微软 Azure AI",
    "baseten": "Baseten",
    "bedrock": "亚马逊 Bedrock",
    "bedrock_converse": "亚马逊 Bedrock Converse",
    "cerebras": "Cerebras",
    "cloudflare": "Cloudflare",
    "cohere": "Cohere",
    "databricks": "Databricks",
    "deepinfra": "DeepInfra",
    "deepseek": "深度求索",
    "fireworks_ai": "Fireworks AI",
    "gemini": "谷歌 Gemini",
    "github_copilot": "GitHub Copilot",
    "groq": "Groq",
    "huggingface": "Hugging Face",
    "moonshot": "月之暗面",
    "mistral": "Mistral AI",
    "nebius": "Nebius AI Studio",
    "novita": "Novita AI",
    "nvidia_nim": "NVIDIA NIM",
    "ollama": "Ollama",
    "openai": "OpenAI",
    "openrouter": "OpenRouter",
    "perplexity": "Perplexity",
    "replicate": "Replicate",
    "sambanova": "SambaNova",
    "together_ai": "Together AI",
    "vertex_ai": "谷歌 Vertex AI",
    "vertex_ai-language-models": "谷歌 Vertex AI Language Models",
    "vertex_ai-deepseek_models": "谷歌 Vertex AI DeepSeek",
    "vertex_ai-anthropic_models": "谷歌 Vertex AI Anthropic",
    "vercel_ai_gateway": "Vercel AI Gateway",
    "volcengine": "火山引擎",
    "xai": "xAI",
    "watsonx": "IBM watsonx",
    "wandb": "Weights & Biases",
}

PROVIDER_PREFIXES_TO_STRIP = {
    "openrouter/",
    "deepseek/",
    "anthropic/",
    "openai/",
    "xai/",
    "groq/",
    "fireworks_ai/",
    "together_ai/",
    "mistral/",
    "moonshot/",
    "dashscope/",
    "cerebras/",
    "deepinfra/",
    "novita/",
    "nebius/",
    "nvidia_nim/",
    "ollama/",
}

MODEL_COST_JSON_NAMES = (
    "model_prices_and_context_window.json",
    "litellm/model_prices_and_context_window_backup.json",
)

PUBLIC_OFFICIAL_MODEL_SUPPLEMENTS: tuple[dict[str, Any], ...] = (
    {
        "provider_id": "deepseek",
        "model_id": "deepseek-v4-flash",
        "source_kind": "official_docs_seed",
        "source": "https://api-docs.deepseek.com/quick_start/pricing",
        "source_notes": "DeepSeek 官方文档已公开列出该模型，但当前 LiteLLM model_cost 目录未收录。",
        "model_info": {
            "mode": "chat",
            "max_tokens": 384000,
            "max_input_tokens": 1000000,
            "max_output_tokens": 384000,
            "supports_function_calling": True,
            "supports_parallel_function_calling": False,
            "supports_tool_choice": False,
            "supports_response_schema": True,
            "supports_reasoning": True,
            "supports_prompt_caching": False,
            "supports_native_streaming": True,
            "supports_vision": False,
            "supports_audio_input": False,
            "supports_web_search": False,
        },
    },
    {
        "provider_id": "deepseek",
        "model_id": "deepseek-v4-pro",
        "source_kind": "official_docs_seed",
        "source": "https://api-docs.deepseek.com/quick_start/pricing",
        "source_notes": "DeepSeek 官方文档已公开列出该模型，但当前 LiteLLM model_cost 目录未收录。",
        "model_info": {
            "mode": "chat",
            "max_tokens": 384000,
            "max_input_tokens": 1000000,
            "max_output_tokens": 384000,
            "supports_function_calling": True,
            "supports_parallel_function_calling": False,
            "supports_tool_choice": False,
            "supports_response_schema": True,
            "supports_reasoning": True,
            "supports_prompt_caching": False,
            "supports_native_streaming": True,
            "supports_vision": False,
            "supports_audio_input": False,
            "supports_web_search": False,
        },
    },
)

OPENAI_FAMILY_BASE_PARAMS: tuple[str, ...] = (
    "frequency_penalty",
    "logit_bias",
    "logprobs",
    "top_logprobs",
    "max_tokens",
    "max_completion_tokens",
    "modalities",
    "prediction",
    "n",
    "presence_penalty",
    "seed",
    "stop",
    "stream",
    "stream_options",
    "temperature",
    "top_p",
    "tools",
    "tool_choice",
    "function_call",
    "functions",
    "max_retries",
    "extra_headers",
    "parallel_tool_calls",
    "audio",
    "web_search_options",
    "service_tier",
    "safety_identifier",
    "prompt_cache_key",
    "prompt_cache_retention",
    "store",
    "response_format",
    "user",
)

ANTHROPIC_FAMILY_BASE_PARAMS: tuple[str, ...] = (
    "stream",
    "stop",
    "temperature",
    "top_p",
    "max_tokens",
    "max_completion_tokens",
    "tools",
    "tool_choice",
    "extra_headers",
    "parallel_tool_calls",
    "response_format",
    "user",
    "web_search_options",
    "speed",
    "context_management",
    "cache_control",
)

GEMINI_FAMILY_BASE_PARAMS: tuple[str, ...] = (
    "temperature",
    "top_p",
    "top_k",
    "max_tokens",
    "max_completion_tokens",
    "stream",
    "tools",
    "tool_choice",
    "functions",
    "response_format",
    "n",
    "stop",
    "logprobs",
    "frequency_penalty",
    "presence_penalty",
    "modalities",
    "parallel_tool_calls",
    "web_search_options",
    "service_tier",
)


def resolve_litellm_repo_path(repo_root: Path, explicit_repo_path: str | None) -> Path | None:
    # 中文注释: 如果用户没显式传路径，这里自动拾取 temp 下刚拉下来的上游仓库，方便反复重跑。
    if explicit_repo_path:
        candidate = Path(explicit_repo_path)
        if not candidate.is_absolute():
            candidate = (repo_root / candidate).resolve()
        return candidate if candidate.exists() else None
    default_candidate = repo_root / "temp" / "litellm-upstream"
    return default_candidate if default_candidate.exists() else None


def read_litellm_repo_version(litellm_repo_path: Path | None) -> str:
    # 中文注释: 从上游仓库直接读 pyproject 版本号，比依赖当前 Python 环境里的包版本更可信。
    if litellm_repo_path is None:
        try:
            from importlib.metadata import version

            return version("litellm")
        except Exception:
            return "unknown"
    pyproject_path = litellm_repo_path / "pyproject.toml"
    if not pyproject_path.exists():
        return "unknown"
    content = pyproject_path.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r'(?m)^version\s*=\s*"([^"]+)"', content)
    return match.group(1) if match else "unknown"


def read_litellm_repo_commit(litellm_repo_path: Path | None) -> str | None:
    # 中文注释: commit 哈希落盘后，后续就能准确复现“这次导出究竟基于哪一版源码”。
    if litellm_repo_path is None:
        return None
    try:
        result = subprocess.run(
            ["git", "-C", str(litellm_repo_path), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except Exception:
        return None
    return result.stdout.strip() or None


def load_model_cost_map(litellm_repo_path: Path | None) -> dict[str, Any]:
    # 中文注释: 模型目录完全从上游仓库静态 JSON 读取，确保导出不触发任何运行时 provider 初始化。
    if litellm_repo_path is None:
        return {}
    for relative_name in MODEL_COST_JSON_NAMES:
        candidate = litellm_repo_path / relative_name
        if candidate.exists():
            payload = json.loads(candidate.read_text(encoding="utf-8"))
            if isinstance(payload, dict):
                return payload
    return {}


def prettify_provider_name(provider_id: str) -> str:
    # 中文注释: 对未人工登记的 provider，至少生成一个不那么刺眼的展示名，避免用户直接面对生硬内部 id。
    label = provider_id.replace("_", " ").replace("-", " ").strip()
    return " ".join(part.capitalize() for part in label.split()) or provider_id


def infer_protocol_id(provider_id: str) -> str:
    # 中文注释: 这里给所有 provider 一个协议家族标签，便于后续按传输模式和宿主兼容能力分组。
    if provider_id in PROVIDER_PROTOCOL_OVERRIDES:
        return PROVIDER_PROTOCOL_OVERRIDES[provider_id]
    if "anthropic" in provider_id:
        return "anthropic_compatible"
    if any(token in provider_id for token in ("openai", "router", "groq", "xai", "deepseek", "mistral", "perplexity")):
        return "openai_compatible"
    if "gemini" in provider_id:
        return "gemini_native"
    if "vertex" in provider_id:
        return "vertex_ai_native"
    if "bedrock" in provider_id:
        return "bedrock_native"
    if "ollama" in provider_id:
        return "ollama_compatible"
    return "litellm_adapter"


def get_provider_profile(provider_id: str) -> ProviderProfile:
    # 中文注释: 主表不再局限于人工白名单 provider；未知 provider 会动态生成基础档案，确保全量模型不被漏掉。
    known = PROVIDER_PROFILES.get(provider_id)
    if known is not None:
        return known
    return ProviderProfile(
        provider_id=provider_id,
        vendor_name_zh=PROVIDER_VENDOR_NAME_ZH_OVERRIDES.get(provider_id, prettify_provider_name(provider_id)),
        protocol_id=infer_protocol_id(provider_id),
        default_base_url=PROVIDER_DEFAULT_BASE_URLS.get(provider_id),
    )


def normalize_canonical_model_key(model_id: str) -> str:
    # 中文注释: 这里把不同厂商前缀剥离成可聚合的“规范模型键”，便于识别同模型的多种命名。
    normalized = model_id.strip().lower()
    for prefix in PROVIDER_PREFIXES_TO_STRIP:
        if normalized.startswith(prefix):
            normalized = normalized[len(prefix) :]
            break
    normalized = normalized.replace("deepseek-ai/", "deepseek/")
    normalized = normalized.replace("accounts/fireworks/models/", "")
    normalized = re.sub(r"/+", "/", normalized)
    return normalized


def build_provider_record(provider: ProviderProfile, model_count: int) -> dict[str, Any]:
    # 中文注释: provider 层是设置页与目录页最先消费的数据，所以这里单独整理中文名、协议和默认入口。
    return {
        "provider_id": provider.provider_id,
        "vendor_name_zh": provider.vendor_name_zh,
        "protocol_id": provider.protocol_id,
        "default_base_url": provider.default_base_url,
        "aliases": list(provider.aliases),
        "notes": provider.notes,
        "model_count": model_count,
    }


def build_capabilities(model_info: dict[str, Any]) -> dict[str, Any]:
    # 中文注释: 能力字段优先复用 LiteLLM 的模型元数据，避免导出脚本自己再发明一套判定逻辑。
    return {
        "mode": model_info.get("mode"),
        "max_tokens": model_info.get("max_tokens"),
        "max_input_tokens": model_info.get("max_input_tokens"),
        "max_output_tokens": model_info.get("max_output_tokens"),
        "supports_function_calling": bool(model_info.get("supports_function_calling")),
        "supports_parallel_function_calling": bool(model_info.get("supports_parallel_function_calling")),
        "supports_tool_choice": bool(model_info.get("supports_tool_choice")),
        "supports_response_schema": bool(model_info.get("supports_response_schema")),
        "supports_reasoning": bool(model_info.get("supports_reasoning")),
        "supports_prompt_caching": bool(model_info.get("supports_prompt_caching")),
        "supports_native_streaming": bool(model_info.get("supports_native_streaming")),
        "supports_vision": bool(model_info.get("supports_vision")),
        "supports_audio_input": bool(model_info.get("supports_audio_input")),
        "supports_web_search": bool(model_info.get("supports_web_search")),
    }


def infer_supported_params(model_id: str, provider: ProviderProfile, capabilities: dict[str, Any]) -> list[str]:
    # 中文注释: 参数列表改为纯静态推导：先按协议家族给基线，再按模型能力开关裁剪和补充，保证离线且可重复。
    protocol = provider.protocol_id
    if protocol == "anthropic_compatible":
        params = list(ANTHROPIC_FAMILY_BASE_PARAMS)
    elif protocol == "gemini_native" or ("gemini" in model_id.lower()):
        params = list(GEMINI_FAMILY_BASE_PARAMS)
    else:
        params = list(OPENAI_FAMILY_BASE_PARAMS)

    if not capabilities.get("supports_function_calling"):
        params = [
            item
            for item in params
            if item not in {"tools", "tool_choice", "function_call", "functions", "parallel_tool_calls"}
        ]
    elif not capabilities.get("supports_tool_choice"):
        params = [item for item in params if item != "tool_choice"]

    if not capabilities.get("supports_parallel_function_calling"):
        params = [item for item in params if item != "parallel_tool_calls"]

    if not capabilities.get("supports_response_schema"):
        params = [item for item in params if item != "response_format"]

    if not capabilities.get("supports_reasoning"):
        params = [item for item in params if item not in {"thinking", "reasoning_effort"}]
    else:
        for item in ("thinking", "reasoning_effort"):
            if item not in params:
                params.append(item)

    if not capabilities.get("supports_audio_input"):
        params = [item for item in params if item != "audio"]

    if not capabilities.get("supports_web_search"):
        params = [item for item in params if item != "web_search_options"]

    return sorted(dict.fromkeys(params))


def build_request_format_specs(
    parameter_name: str,
    provider: ProviderProfile,
    model_id: str,
    capabilities: dict[str, Any],
) -> list[dict[str, Any]]:
    # 中文注释: 同一个参数在 chat/responses 或不同协议下形态可能不同，所以这里返回的是“格式变体”列表。
    protocol = provider.protocol_id
    variants: list[dict[str, Any]] = []
    if protocol == "openai_compatible":
        variants.append(
            {
                "api_mode": "chat",
                "transport": "normalized_openai_param",
                "location": "top_level",
                "key": parameter_name,
            }
        )
        if parameter_name == "max_tokens":
            variants.append(
                {
                    "api_mode": "responses",
                    "transport": "openai_responses",
                    "location": "top_level",
                    "key": "max_output_tokens",
                }
            )
        elif parameter_name == "reasoning_effort":
            variants.append(
                {
                    "api_mode": "responses",
                    "transport": "openai_responses",
                    "location": "object",
                    "path": ["reasoning", "effort"],
                    "value_type": "string",
                }
            )
        elif parameter_name == "response_format":
            variants.append(
                {
                    "api_mode": "responses",
                    "transport": "openai_responses",
                    "location": "object",
                    "path": ["text", "format"],
                    "value_type": "object",
                }
            )
        elif parameter_name == "thinking":
            variants[-1]["value_type"] = "object"
            if "deepseek" in normalize_canonical_model_key(model_id):
                variants[-1]["example"] = {"type": "enabled"}
                variants[-1]["notes"] = "DeepSeek 系模型通常使用顶层 thinking 对象。"
    elif protocol == "anthropic_compatible":
        variants.append(
            {
                "api_mode": "messages",
                "transport": "anthropic_native",
                "location": "top_level",
                "key": parameter_name,
            }
        )
        if parameter_name == "thinking":
            variants[-1]["value_type"] = "object"
            variants[-1]["example"] = {"type": "enabled", "budget_tokens": 256}
    else:
        variants.append(
            {
                "api_mode": "provider_adapter",
                "transport": "litellm_normalized_openai_param",
                "location": "top_level",
                "key": parameter_name,
                "notes": "该 provider 的参数列表由 LiteLLM 适配层统一暴露，原生协议形态可能与最终网关请求不同。",
            }
        )
    if parameter_name == "tool_choice":
        variants[0]["value_type"] = "string_or_object"
    if parameter_name in {"parallel_tool_calls", "stream", "store"}:
        variants[0]["value_type"] = "boolean"
    if parameter_name in {"temperature", "top_p", "frequency_penalty", "presence_penalty"}:
        variants[0]["value_type"] = "number"
    if parameter_name in {"max_tokens", "max_completion_tokens"}:
        variants[0]["value_type"] = "integer"
    if parameter_name == "response_format" and not any(item.get("value_type") for item in variants):
        variants[0]["value_type"] = "object"
    if parameter_name == "tools":
        variants[0]["value_type"] = "array"
    if parameter_name == "thinking" and capabilities.get("supports_reasoning") is False:
        variants.append(
            {
                "api_mode": "chat",
                "transport": "advisory_only",
                "notes": "LiteLLM 参数表暴露了 thinking，但模型能力元数据未标记 reasoning；应用侧应做试探与回退。",
            }
        )
    return variants


def build_consistency_notes(supported_params: list[str], capabilities: dict[str, Any]) -> list[str]:
    # 中文注释: LiteLLM 有时会出现“参数表说支持，但布尔能力没亮”的情况，这里显式记下来给后续调度器做保守判断。
    notes: list[str] = []
    if "tool_choice" in supported_params and not capabilities.get("supports_tool_choice"):
        notes.append("supported_params 含 tool_choice，但能力布尔值未确认 supports_tool_choice。")
    if "tools" in supported_params and not capabilities.get("supports_function_calling"):
        notes.append("supported_params 含 tools，但能力布尔值未确认 supports_function_calling。")
    if "parallel_tool_calls" in supported_params and not capabilities.get("supports_parallel_function_calling"):
        notes.append("supported_params 含 parallel_tool_calls，但能力布尔值未确认 supports_parallel_function_calling。")
    if "reasoning_effort" in supported_params and not capabilities.get("supports_reasoning"):
        notes.append("supported_params 含 reasoning_effort，但能力布尔值未确认 supports_reasoning。")
    return notes


def build_applied_rule_ids(provider: ProviderProfile, canonical_model_key: str, supported_params: list[str]) -> list[str]:
    # 中文注释: 规则 id 单独挂到模型上，后续 GUI 或校验器只需要按 id 查规则，不必重新匹配字符串。
    rule_ids: list[str] = []
    if provider.protocol_id == "openai_compatible":
        rule_ids.extend(["openai_chat_transport", "openai_responses_transport"])
    if provider.protocol_id == "anthropic_compatible":
        rule_ids.append("anthropic_messages_transport")
    if provider.protocol_id not in {"openai_compatible", "anthropic_compatible"}:
        rule_ids.append("litellm_adapter_normalized_params")
    if "thinking" in supported_params and provider.protocol_id == "anthropic_compatible":
        rule_ids.append("anthropic_thinking_beta_header")
    if "deepseek" in canonical_model_key and "thinking" in supported_params:
        rule_ids.append("deepseek_thinking_tool_control_conflict")
    return sorted(dict.fromkeys(rule_ids))


def build_model_variant(
    provider: ProviderProfile,
    model_id: str,
    model_info: dict[str, Any],
    source_kind: str = "model_cost",
    source_notes: str | None = None,
) -> dict[str, Any]:
    # 中文注释: 每个 model_variant 直接对应“某个厂商下的某个可选模型”，这是设置页最实用的一层数据。
    canonical_model_key = normalize_canonical_model_key(model_id)
    capabilities = build_capabilities(model_info)
    supported_params = infer_supported_params(model_id, provider, capabilities)
    parameter_specs = [
        {
            "parameter_name": parameter_name,
            "request_formats": build_request_format_specs(parameter_name, provider, model_id, capabilities),
        }
        for parameter_name in supported_params
    ]
    return {
        "variant_key": build_variant_key(provider.provider_id, model_id),
        "provider_id": provider.provider_id,
        "vendor_name_zh": provider.vendor_name_zh,
        "protocol_id": provider.protocol_id,
        "default_base_url": provider.default_base_url,
        "model_id": model_id,
        "canonical_model_key": canonical_model_key,
        "capabilities": capabilities,
        "supported_openai_params": supported_params,
        "parameter_specs": parameter_specs,
        "consistency_notes": build_consistency_notes(supported_params, capabilities),
        "applied_rule_ids": build_applied_rule_ids(provider, canonical_model_key, supported_params),
        "source": model_info.get("source"),
        "source_kind": source_kind,
        "source_notes": source_notes,
    }


def build_variant_key(provider_id: str, model_id: str) -> str:
    # 中文注释: 变体键是 SQLite 里最稳定的连接键，避免每张表都靠整数自增 id 再做额外映射。
    return f"{provider_id}::{model_id}"


def build_global_rules() -> list[dict[str, Any]]:
    # 中文注释: 全局规则是参数互相影响的知识层，单独存放可以让核心层和 UI 共用同一套约束描述。
    return [
        {
            "rule_id": "openai_chat_transport",
            "protocol_id": "openai_compatible",
            "summary": "OpenAI Chat 模式默认把兼容参数作为顶层字段发送。",
        },
        {
            "rule_id": "openai_responses_transport",
            "protocol_id": "openai_compatible",
            "summary": "Responses API 与 Chat API 字段名不完全一致，例如 max_tokens -> max_output_tokens，reasoning_effort -> reasoning.effort，response_format -> text.format。",
        },
        {
            "rule_id": "anthropic_messages_transport",
            "protocol_id": "anthropic_compatible",
            "summary": "Anthropic Messages API 以原生 messages 协议发送，thinking 走顶层对象。",
        },
        {
            "rule_id": "anthropic_thinking_beta_header",
            "protocol_id": "anthropic_compatible",
            "summary": "Anthropic 开启 thinking 时通常需要额外 beta header；应用侧应把 header 作为条件化传输的一部分。",
        },
        {
            "rule_id": "deepseek_thinking_tool_control_conflict",
            "protocol_id": "openai_compatible",
            "summary": "DeepSeek V4/V3.1 一类模型在开启 thinking 或 reasoning 时，tool_choice 与并行工具控制存在条件化兼容风险，应用侧应默认保守发送。",
        },
        {
            "rule_id": "litellm_adapter_normalized_params",
            "protocol_id": "litellm_adapter",
            "summary": "对非 OpenAI/Anthropic 原生协议的 provider，参数表默认记录为 LiteLLM 暴露的归一化 OpenAI 参数集合。",
        },
    ]


def read_project_provider_snapshots(repo_root: Path) -> list[dict[str, Any]]:
    # 中文注释: 这里读取项目当前的 provider 配置快照，但故意不导出任何密钥，避免把临时测试信息扩散出去。
    settings_path = repo_root / "temp" / "novel_agent_settings.json"
    if not settings_path.exists():
        return []
    try:
        payload = json.loads(settings_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    snapshots: list[dict[str, Any]] = []
    for provider in payload.get("providers", []):
        if not isinstance(provider, dict):
            continue
        snapshots.append(
            {
                "id": provider.get("id"),
                "title": provider.get("title"),
                "protocol": provider.get("protocol"),
                "base_url": provider.get("base_url"),
                "model_id": provider.get("model_id"),
                "is_default": bool(provider.get("is_default")),
            }
        )
    return snapshots


def infer_provider_from_snapshot(snapshot: dict[str, Any]) -> ProviderProfile | None:
    # 中文注释: 项目快照里的 provider 往往是用户自定义 id，所以这里通过 base_url、标题和模型名做最佳努力推断。
    haystack = " ".join(
        str(snapshot.get(key) or "")
        for key in ("title", "base_url", "model_id", "protocol", "id")
    ).lower()
    if snapshot.get("protocol") == "anthropic_compatible":
        return PROVIDER_PROFILES.get("anthropic")
    scores: list[tuple[int, ProviderProfile]] = []
    for provider in PROVIDER_PROFILES.values():
        score = 0
        if provider.provider_id in haystack:
            score += 3
        for alias in provider.aliases:
            if alias.lower() in haystack:
                score += 2
        if provider.default_base_url and provider.default_base_url.lower() in haystack:
            score += 4
        if score > 0:
            scores.append((score, provider))
    if not scores:
        return PROVIDER_PROFILES.get("openai") if snapshot.get("protocol") == "openai_compatible" else None
    scores.sort(key=lambda item: item[0], reverse=True)
    return scores[0][1]


def build_probe_candidates(provider: ProviderProfile, model_id: str) -> list[str]:
    # 中文注释: 上游目录未必收录所有新模型，但 provider 适配器常常已经知道参数形态，所以这里补一层候选别名探测。
    candidates = [model_id]
    if "/" not in model_id:
        candidates.append(f"{provider.provider_id}/{model_id}")
        if provider.provider_id == "deepseek":
            candidates.append(f"deepseek/{model_id}")
        if provider.provider_id == "openrouter":
            candidates.append(f"openrouter/{model_id}")
        if provider.provider_id == "anthropic" and model_id.startswith("claude"):
            candidates.append(f"anthropic/{model_id}")
    return list(dict.fromkeys(candidates))


def probe_model_variant_from_snapshot(snapshot: dict[str, Any]) -> dict[str, Any] | None:
    # 中文注释: 纯静态导出不再用本地配置反推模型能力，避免用户端主表混入主观观测数据。
    return None


def build_public_supplement_variants() -> list[dict[str, Any]]:
    # 中文注释: 这层专门补“官方已公开、但上游目录暂时缺失”的模型，来源必须可审计，不能来自本地测试配置。
    variants: list[dict[str, Any]] = []
    for supplement in PUBLIC_OFFICIAL_MODEL_SUPPLEMENTS:
        provider = get_provider_profile(str(supplement["provider_id"]))
        variants.append(
            build_model_variant(
                provider=provider,
                model_id=str(supplement["model_id"]),
                model_info=dict(supplement["model_info"]),
                source_kind=str(supplement["source_kind"]),
                source_notes=str(supplement["source_notes"]),
            )
        )
        variants[-1]["source"] = supplement["source"]
    return variants


def collect_supported_chat_models(
    model_cost_map: dict[str, Any],
    project_provider_snapshots: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, int]]:
    # 中文注释: 主表收集上游全量 chat 模型与公共补充模型；本地观测模型另行分流，绝不混入用户端客观主表。
    variants: list[dict[str, Any]] = []
    observed_variants: list[dict[str, Any]] = []
    diagnostics: Counter[str] = Counter()
    for model_id, model_info in model_cost_map.items():
        if not isinstance(model_info, dict):
            diagnostics["skip_non_dict"] += 1
            continue
        provider_id = str(model_info.get("litellm_provider") or "").strip()
        provider = get_provider_profile(provider_id)
        if model_info.get("mode") != "chat":
            diagnostics["skip_non_chat"] += 1
            continue
        variants.append(build_model_variant(provider, str(model_id), model_info))

    existing_keys = {variant["variant_key"] for variant in variants}
    for supplement_variant in build_public_supplement_variants():
        if supplement_variant["variant_key"] in existing_keys:
            diagnostics["public_supplement_already_present"] += 1
            continue
        variants.append(supplement_variant)
        existing_keys.add(supplement_variant["variant_key"])
        diagnostics["public_supplement_added"] += 1

    observed_keys: set[str] = set()
    existing_keys = {variant["variant_key"] for variant in variants}
    for snapshot in project_provider_snapshots:
        supplemental_variant = probe_model_variant_from_snapshot(snapshot)
        if supplemental_variant is None:
            diagnostics["snapshot_probe_not_resolved"] += 1
            continue
        if supplemental_variant["variant_key"] in existing_keys:
            diagnostics["snapshot_probe_matches_catalog"] += 1
            continue
        if supplemental_variant["variant_key"] in observed_keys:
            diagnostics["snapshot_probe_duplicate_observed"] += 1
            continue
        observed_variants.append(supplemental_variant)
        observed_keys.add(supplemental_variant["variant_key"])
        diagnostics["snapshot_probe_added_to_observed"] += 1

    variants.sort(key=lambda item: (item["provider_id"], item["canonical_model_key"], item["model_id"]))
    observed_variants.sort(key=lambda item: (item["provider_id"], item["canonical_model_key"], item["model_id"]))
    return variants, observed_variants, dict(diagnostics)


def build_canonical_models(model_variants: list[dict[str, Any]]) -> list[dict[str, Any]]:
    # 中文注释: 规范模型组是“同一模型多厂商命名”的聚合视图，后面做模型选择器时会非常有用。
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for variant in model_variants:
        grouped[str(variant["canonical_model_key"])].append(variant)
    canonical_models: list[dict[str, Any]] = []
    for canonical_key, variants in sorted(grouped.items()):
        aliases = sorted({str(item["model_id"]) for item in variants})
        canonical_models.append(
            {
                "canonical_model_key": canonical_key,
                "provider_count": len({str(item["provider_id"]) for item in variants}),
                "aliases": aliases,
                "providers": [
                    {
                        "provider_id": str(item["provider_id"]),
                        "model_id": str(item["model_id"]),
                        "default_base_url": item["default_base_url"],
                    }
                    for item in variants
                ],
            }
        )
    return canonical_models


def build_parameter_catalog(model_variants: list[dict[str, Any]]) -> list[dict[str, Any]]:
    # 中文注释: 参数总表用来去重展示所有出现过的参数及其传输格式，避免 UI 逐模型重新扫描。
    merged: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for variant in model_variants:
        for spec in variant["parameter_specs"]:
            merged[str(spec["parameter_name"])].extend(spec["request_formats"])
    catalog: list[dict[str, Any]] = []
    for parameter_name, formats in sorted(merged.items()):
        normalized_formats = sorted(
            {
                json.dumps(format_item, ensure_ascii=False, sort_keys=True)
                for format_item in formats
            }
        )
        catalog.append(
            {
                "parameter_name": parameter_name,
                "request_formats": [json.loads(item) for item in normalized_formats],
            }
        )
    return catalog


def build_payload(repo_root: Path, litellm_repo_path: Path | None) -> dict[str, Any]:
    # 中文注释: 这一层负责把 repo 元信息、项目快照、模型目录和规则视图统一汇总成可落盘数据结构。
    project_provider_snapshots = read_project_provider_snapshots(repo_root)
    model_cost_map = load_model_cost_map(litellm_repo_path)
    model_variants, observed_model_variants, diagnostics = collect_supported_chat_models(
        model_cost_map=model_cost_map,
        project_provider_snapshots=project_provider_snapshots,
    )
    provider_counts = Counter(str(item["provider_id"]) for item in model_variants)
    providers = [
        build_provider_record(get_provider_profile(provider_id), model_count)
        for provider_id, model_count in sorted(provider_counts.items())
    ]
    return {
        "schema_version": 2,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": {
            "library": "litellm",
            "library_version": read_litellm_repo_version(litellm_repo_path),
            "repo_path": str(litellm_repo_path) if litellm_repo_path is not None else None,
            "repo_commit": read_litellm_repo_commit(litellm_repo_path),
            "filtered_protocols": ["all_litellm_chat_providers"],
            "notes": [
                "主表导出 LiteLLM 上游全量 chat 模型，而不是只导出 NovelAgent 当前宿主支持的 provider。",
                "参数支持列表来自 LiteLLM get_supported_openai_params。",
                "公共补充模型只允许来自可审计的官方文档种子，不允许来自本地测试配置。",
                "项目本地观测模型会单独进入 observed_model_variants，不混入用户端客观主表。",
                "条件化兼容规则额外吸收了仓库内参考测试与现有能力种子。",
            ],
        },
        "project_provider_snapshots": project_provider_snapshots,
        "providers": providers,
        "parameter_catalog": build_parameter_catalog(model_variants),
        "canonical_models": build_canonical_models(model_variants),
        "model_variants": model_variants,
        "observed_model_variants": observed_model_variants,
        "compatibility_rules": build_global_rules(),
        "diagnostics": diagnostics,
    }


def write_json_output(payload: dict[str, Any], output_path: Path) -> None:
    # 中文注释: JSON 仍然保留为人工检查与版本比较的调试产物。
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def create_sqlite_schema(connection: sqlite3.Connection) -> None:
    # 中文注释: 这次 schema 彻底去掉参数相关 JSON 列，改成维表 + 关联表，尽量只存一份重复字面量。
    connection.executescript(
        """
        PRAGMA foreign_keys = ON;

        CREATE TABLE metadata (
          key TEXT PRIMARY KEY,
          value TEXT
        );

        CREATE TABLE providers (
          provider_id TEXT PRIMARY KEY,
          vendor_name_zh TEXT NOT NULL,
          protocol_id TEXT NOT NULL,
          default_base_url TEXT,
          notes TEXT,
          model_count INTEGER NOT NULL
        );

        CREATE TABLE provider_aliases (
          provider_id TEXT NOT NULL,
          alias TEXT NOT NULL,
          PRIMARY KEY (provider_id, alias),
          FOREIGN KEY (provider_id) REFERENCES providers(provider_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE project_provider_snapshots (
          snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
          config_id TEXT,
          title TEXT,
          protocol_id TEXT,
          base_url TEXT,
          model_id TEXT,
          is_default INTEGER NOT NULL
        );

        CREATE TABLE canonical_models (
          canonical_model_key TEXT PRIMARY KEY,
          provider_count INTEGER NOT NULL
        );

        CREATE TABLE canonical_model_aliases (
          canonical_model_key TEXT NOT NULL,
          alias_model_id TEXT NOT NULL,
          PRIMARY KEY (canonical_model_key, alias_model_id),
          FOREIGN KEY (canonical_model_key) REFERENCES canonical_models(canonical_model_key) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE canonical_model_providers (
          canonical_model_key TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          model_id TEXT NOT NULL,
          default_base_url TEXT,
          PRIMARY KEY (canonical_model_key, provider_id, model_id),
          FOREIGN KEY (canonical_model_key) REFERENCES canonical_models(canonical_model_key) ON DELETE CASCADE,
          FOREIGN KEY (provider_id) REFERENCES providers(provider_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE compatibility_rules (
          rule_id TEXT PRIMARY KEY,
          protocol_id TEXT NOT NULL,
          summary TEXT NOT NULL
        );

        CREATE TABLE model_variants (
          variant_key TEXT PRIMARY KEY,
          record_scope TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          model_id TEXT NOT NULL,
          canonical_model_key TEXT NOT NULL,
          source TEXT,
          source_kind TEXT NOT NULL,
          source_notes TEXT,
          project_snapshot_model_id TEXT,
          mode TEXT,
          max_tokens INTEGER,
          max_input_tokens INTEGER,
          max_output_tokens INTEGER,
          supports_function_calling INTEGER NOT NULL,
          supports_parallel_function_calling INTEGER NOT NULL,
          supports_tool_choice INTEGER NOT NULL,
          supports_response_schema INTEGER NOT NULL,
          supports_reasoning INTEGER NOT NULL,
          supports_prompt_caching INTEGER NOT NULL,
          supports_native_streaming INTEGER NOT NULL,
          supports_vision INTEGER NOT NULL,
          supports_audio_input INTEGER NOT NULL,
          supports_web_search INTEGER NOT NULL,
          FOREIGN KEY (provider_id) REFERENCES providers(provider_id) ON DELETE CASCADE,
          FOREIGN KEY (canonical_model_key) REFERENCES canonical_models(canonical_model_key) ON DELETE CASCADE
        );

        CREATE TABLE parameters (
          parameter_id INTEGER PRIMARY KEY,
          parameter_name TEXT NOT NULL UNIQUE
        );

        CREATE TABLE request_format_templates (
          format_id INTEGER PRIMARY KEY,
          api_mode TEXT,
          transport TEXT,
          location TEXT,
          key_name TEXT,
          path_json TEXT,
          value_type TEXT,
          example_json TEXT,
          notes TEXT,
          UNIQUE(api_mode, transport, location, key_name, path_json, value_type, example_json, notes)
        );

        CREATE TABLE parameter_catalog_formats (
          parameter_id INTEGER NOT NULL,
          format_id INTEGER NOT NULL,
          PRIMARY KEY (parameter_id, format_id),
          FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id) ON DELETE CASCADE,
          FOREIGN KEY (format_id) REFERENCES request_format_templates(format_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE consistency_notes (
          note_id INTEGER PRIMARY KEY,
          note_text TEXT NOT NULL UNIQUE
        );

        CREATE TABLE variant_supported_parameters (
          variant_key TEXT NOT NULL,
          parameter_id INTEGER NOT NULL,
          PRIMARY KEY (variant_key, parameter_id),
          FOREIGN KEY (variant_key) REFERENCES model_variants(variant_key) ON DELETE CASCADE,
          FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE variant_parameter_formats (
          variant_key TEXT NOT NULL,
          parameter_id INTEGER NOT NULL,
          format_id INTEGER NOT NULL,
          PRIMARY KEY (variant_key, parameter_id, format_id),
          FOREIGN KEY (variant_key) REFERENCES model_variants(variant_key) ON DELETE CASCADE,
          FOREIGN KEY (parameter_id) REFERENCES parameters(parameter_id) ON DELETE CASCADE,
          FOREIGN KEY (format_id) REFERENCES request_format_templates(format_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE variant_consistency_notes (
          variant_key TEXT NOT NULL,
          note_id INTEGER NOT NULL,
          PRIMARY KEY (variant_key, note_id),
          FOREIGN KEY (variant_key) REFERENCES model_variants(variant_key) ON DELETE CASCADE,
          FOREIGN KEY (note_id) REFERENCES consistency_notes(note_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE variant_rules (
          variant_key TEXT NOT NULL,
          rule_id TEXT NOT NULL,
          PRIMARY KEY (variant_key, rule_id),
          FOREIGN KEY (variant_key) REFERENCES model_variants(variant_key) ON DELETE CASCADE,
          FOREIGN KEY (rule_id) REFERENCES compatibility_rules(rule_id) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE VIEW user_facing_model_variants AS
        SELECT * FROM model_variants WHERE record_scope != 'observed_local';

        CREATE VIEW observed_model_variants AS
        SELECT * FROM model_variants WHERE record_scope = 'observed_local';

        CREATE INDEX idx_model_variants_provider_id ON model_variants(provider_id);
        CREATE INDEX idx_model_variants_canonical_model_key ON model_variants(canonical_model_key);
        CREATE INDEX idx_model_variants_record_scope ON model_variants(record_scope);
        CREATE INDEX idx_variant_supported_parameters_parameter_id ON variant_supported_parameters(parameter_id);
        CREATE INDEX idx_variant_parameter_formats_parameter_id ON variant_parameter_formats(parameter_id);
        """
    )


def insert_metadata(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: metadata 只存小而稳定的键值，便于快速判断库版本与来源。
    source = payload["source"]
    rows = [
        ("schema_version", str(payload["schema_version"])),
        ("generated_at", str(payload["generated_at"])),
        ("library", str(source["library"])),
        ("library_version", str(source["library_version"])),
        ("repo_path", json.dumps(source.get("repo_path"), ensure_ascii=False)),
        ("repo_commit", json.dumps(source.get("repo_commit"), ensure_ascii=False)),
        ("filtered_protocols", json.dumps(source.get("filtered_protocols"), ensure_ascii=False)),
        ("notes", json.dumps(source.get("notes"), ensure_ascii=False)),
        ("diagnostics", json.dumps(payload.get("diagnostics"), ensure_ascii=False)),
    ]
    connection.executemany("INSERT INTO metadata(key, value) VALUES(?, ?)", rows)


def insert_provider_data(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: provider 表和 alias 表拆开后，查询列表和模糊搜索都更直接。
    for provider in payload["providers"]:
        connection.execute(
            """
            INSERT INTO providers(provider_id, vendor_name_zh, protocol_id, default_base_url, notes, model_count)
            VALUES(?, ?, ?, ?, ?, ?)
            """,
            (
                provider["provider_id"],
                provider["vendor_name_zh"],
                provider["protocol_id"],
                provider["default_base_url"],
                provider["notes"],
                provider["model_count"],
            ),
        )
        for alias in provider.get("aliases", []):
            connection.execute(
                "INSERT INTO provider_aliases(provider_id, alias) VALUES(?, ?)",
                (provider["provider_id"], alias),
            )


def insert_project_provider_snapshots(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: 项目快照放独立表，后面 GUI 想做“当前配置是否命中目录”检查会更方便。
    for snapshot in payload["project_provider_snapshots"]:
        connection.execute(
            """
            INSERT INTO project_provider_snapshots(config_id, title, protocol_id, base_url, model_id, is_default)
            VALUES(?, ?, ?, ?, ?, ?)
            """,
            (
                snapshot.get("id"),
                snapshot.get("title"),
                snapshot.get("protocol"),
                snapshot.get("base_url"),
                snapshot.get("model_id"),
                1 if snapshot.get("is_default") else 0,
            ),
        )


def insert_canonical_models(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: 规范模型相关表负责表达“同一模型在不同厂商下的别名和落点”。
    for canonical_model in payload["canonical_models"]:
        connection.execute(
            "INSERT INTO canonical_models(canonical_model_key, provider_count) VALUES(?, ?)",
            (canonical_model["canonical_model_key"], canonical_model["provider_count"]),
        )
        for alias_model_id in canonical_model["aliases"]:
            connection.execute(
                "INSERT INTO canonical_model_aliases(canonical_model_key, alias_model_id) VALUES(?, ?)",
                (canonical_model["canonical_model_key"], alias_model_id),
            )
        for provider_info in canonical_model["providers"]:
            connection.execute(
                """
                INSERT INTO canonical_model_providers(canonical_model_key, provider_id, model_id, default_base_url)
                VALUES(?, ?, ?, ?)
                """,
                (
                    canonical_model["canonical_model_key"],
                    provider_info["provider_id"],
                    provider_info["model_id"],
                    provider_info["default_base_url"],
                ),
            )


def insert_rules(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: 规则表保持扁平，方便后续把 rule_id 直接映射到界面提示或校验逻辑。
    for rule in payload["compatibility_rules"]:
        connection.execute(
            "INSERT INTO compatibility_rules(rule_id, protocol_id, summary) VALUES(?, ?, ?)",
            (rule["rule_id"], rule["protocol_id"], rule["summary"]),
        )


def normalize_json_cell(value: Any) -> str | None:
    # 中文注释: 复杂字段统一压成紧凑 JSON 字符串，保证同值在唯一索引里能稳定去重。
    if value is None:
        return None
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True)


def format_signature(format_entry: dict[str, Any]) -> tuple[Any, ...]:
    # 中文注释: 请求格式模板的唯一性完全由这一组字段决定，后面会据此做全局去重。
    return (
        format_entry.get("api_mode"),
        format_entry.get("transport"),
        format_entry.get("location"),
        format_entry.get("key"),
        normalize_json_cell(format_entry.get("path")),
        format_entry.get("value_type"),
        normalize_json_cell(format_entry.get("example")),
        format_entry.get("notes"),
    )


def build_parameter_registry(payload: dict[str, Any]) -> dict[str, int]:
    # 中文注释: 参数名非常重复，先抽成 id 维表，再让关联表引用整数主键，能明显减小重复字符串存储。
    names: set[str] = set()
    for parameter_entry in payload["parameter_catalog"]:
        names.add(str(parameter_entry["parameter_name"]))
    for variant in payload["model_variants"] + payload.get("observed_model_variants", []):
        names.update(str(name) for name in variant["supported_openai_params"])
        names.update(str(spec["parameter_name"]) for spec in variant["parameter_specs"])
    return {name: index for index, name in enumerate(sorted(names), start=1)}


def build_format_registry(payload: dict[str, Any]) -> dict[tuple[Any, ...], int]:
    # 中文注释: 格式模板也是高度重复的数据，单独维表后多个模型可以共享同一个 format_id。
    signatures: dict[tuple[Any, ...], int] = {}
    next_id = 1
    for parameter_entry in payload["parameter_catalog"]:
        for format_entry in parameter_entry["request_formats"]:
            signature = format_signature(format_entry)
            if signature not in signatures:
                signatures[signature] = next_id
                next_id += 1
    for variant in payload["model_variants"] + payload.get("observed_model_variants", []):
        for spec in variant["parameter_specs"]:
            for format_entry in spec["request_formats"]:
                signature = format_signature(format_entry)
                if signature not in signatures:
                    signatures[signature] = next_id
                    next_id += 1
    return signatures


def build_note_registry(payload: dict[str, Any]) -> dict[str, int]:
    # 中文注释: 一致性备注也有大量重复文本，抽成 note 维表后能减少每个模型重复存储整句说明。
    notes: set[str] = set()
    for variant in payload["model_variants"] + payload.get("observed_model_variants", []):
        notes.update(str(note) for note in variant["consistency_notes"])
    return {note: index for index, note in enumerate(sorted(notes), start=1)}


def insert_parameter_dimensions(connection: sqlite3.Connection, payload: dict[str, Any]) -> tuple[dict[str, int], dict[tuple[Any, ...], int], dict[str, int]]:
    # 中文注释: 参数、格式模板、备注三类维表先写入，再让后续事实表只引用 id。
    parameter_registry = build_parameter_registry(payload)
    format_registry = build_format_registry(payload)
    note_registry = build_note_registry(payload)

    for parameter_name, parameter_id in parameter_registry.items():
        connection.execute(
            "INSERT INTO parameters(parameter_id, parameter_name) VALUES(?, ?)",
            (parameter_id, parameter_name),
        )

    for signature, format_id in sorted(format_registry.items(), key=lambda item: item[1]):
        connection.execute(
            """
            INSERT INTO request_format_templates(
              format_id, api_mode, transport, location, key_name, path_json, value_type, example_json, notes
            ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (format_id, *signature),
        )

    for note_text, note_id in note_registry.items():
        connection.execute(
            "INSERT INTO consistency_notes(note_id, note_text) VALUES(?, ?)",
            (note_id, note_text),
        )

    return parameter_registry, format_registry, note_registry


def insert_parameter_catalog(connection: sqlite3.Connection, payload: dict[str, Any], parameter_registry: dict[str, int], format_registry: dict[tuple[Any, ...], int]) -> None:
    # 中文注释: 全局参数目录只保存 parameter_id 到 format_id 的映射，不再复制整段 JSON。
    for parameter_entry in payload["parameter_catalog"]:
        parameter_id = parameter_registry[str(parameter_entry["parameter_name"])]
        for format_entry in parameter_entry["request_formats"]:
            connection.execute(
                "INSERT INTO parameter_catalog_formats(parameter_id, format_id) VALUES(?, ?)",
                (parameter_id, format_registry[format_signature(format_entry)]),
            )


def determine_record_scope(variant: dict[str, Any]) -> str:
    # 中文注释: 主目录与观测数据用范围字段区分，避免复制两张结构完全一样的大表。
    if variant.get("source_kind") == "snapshot_probe":
        return "observed_local"
    if variant.get("source_kind") == "official_docs_seed":
        return "public_supplement"
    return "catalog"


def insert_model_variants_rows(
    connection: sqlite3.Connection,
    variants: list[dict[str, Any]],
    parameter_registry: dict[str, int],
    format_registry: dict[tuple[Any, ...], int],
    note_registry: dict[str, int],
) -> None:
    # 中文注释: 事实表只保留标量列，参数、格式、备注、规则全部走关联表，彻底去掉大块 JSON 存储。
    for variant in variants:
        capabilities = variant["capabilities"]
        connection.execute(
            """
            INSERT INTO model_variants(
              variant_key, record_scope, provider_id, model_id,
              canonical_model_key, source, source_kind, source_notes, project_snapshot_model_id,
              mode, max_tokens, max_input_tokens, max_output_tokens,
              supports_function_calling, supports_parallel_function_calling, supports_tool_choice,
              supports_response_schema, supports_reasoning, supports_prompt_caching,
              supports_native_streaming, supports_vision, supports_audio_input, supports_web_search
            ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                variant["variant_key"],
                determine_record_scope(variant),
                variant["provider_id"],
                variant["model_id"],
                variant["canonical_model_key"],
                variant.get("source"),
                variant.get("source_kind"),
                variant.get("source_notes"),
                variant.get("project_snapshot_model_id"),
                capabilities.get("mode"),
                capabilities.get("max_tokens"),
                capabilities.get("max_input_tokens"),
                capabilities.get("max_output_tokens"),
                1 if capabilities.get("supports_function_calling") else 0,
                1 if capabilities.get("supports_parallel_function_calling") else 0,
                1 if capabilities.get("supports_tool_choice") else 0,
                1 if capabilities.get("supports_response_schema") else 0,
                1 if capabilities.get("supports_reasoning") else 0,
                1 if capabilities.get("supports_prompt_caching") else 0,
                1 if capabilities.get("supports_native_streaming") else 0,
                1 if capabilities.get("supports_vision") else 0,
                1 if capabilities.get("supports_audio_input") else 0,
                1 if capabilities.get("supports_web_search") else 0,
            ),
        )
        for parameter_name in variant["supported_openai_params"]:
            connection.execute(
                "INSERT INTO variant_supported_parameters(variant_key, parameter_id) VALUES(?, ?)",
                (variant["variant_key"], parameter_registry[str(parameter_name)]),
            )
        for spec in variant["parameter_specs"]:
            parameter_id = parameter_registry[str(spec["parameter_name"])]
            for format_entry in spec["request_formats"]:
                connection.execute(
                    "INSERT INTO variant_parameter_formats(variant_key, parameter_id, format_id) VALUES(?, ?, ?)",
                    (
                        variant["variant_key"],
                        parameter_id,
                        format_registry[format_signature(format_entry)],
                    ),
                )
        for note_text in variant["consistency_notes"]:
            connection.execute(
                "INSERT INTO variant_consistency_notes(variant_key, note_id) VALUES(?, ?)",
                (variant["variant_key"], note_registry[str(note_text)]),
            )
        for rule_id in variant["applied_rule_ids"]:
            connection.execute(
                "INSERT INTO variant_rules(variant_key, rule_id) VALUES(?, ?)",
                (variant["variant_key"], rule_id),
            )


def insert_model_variants(connection: sqlite3.Connection, payload: dict[str, Any]) -> None:
    # 中文注释: 参数维表与事实表一起写入，保证所有引用 id 都在同一事务内完成。
    parameter_registry, format_registry, note_registry = insert_parameter_dimensions(connection, payload)
    insert_parameter_catalog(connection, payload, parameter_registry, format_registry)
    insert_model_variants_rows(connection, payload["model_variants"], parameter_registry, format_registry, note_registry)
    insert_model_variants_rows(connection, payload.get("observed_model_variants", []), parameter_registry, format_registry, note_registry)


def write_sqlite_output(payload: dict[str, Any], output_path: Path) -> None:
    # 中文注释: SQLite 是这次导出的主消费产物，后续 Flutter/Dart 可以按表精确查询而不是整库读 JSON。
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()
    connection = sqlite3.connect(output_path)
    try:
        create_sqlite_schema(connection)
        insert_metadata(connection, payload)
        insert_provider_data(connection, payload)
        insert_project_provider_snapshots(connection, payload)
        insert_canonical_models(connection, payload)
        insert_rules(connection, payload)
        insert_model_variants(connection, payload)
        connection.commit()
    finally:
        connection.close()


def export_model_matrix(
    repo_root: Path,
    litellm_repo_path: Path | None,
    write_json: bool = True,
    output_suffix: str | None = None,
) -> dict[str, Any]:
    # 中文注释: 导出主流程统一在这里，支持追加输出后缀，避免调试时被已打开的数据库文件阻塞。
    payload = build_payload(repo_root=repo_root, litellm_repo_path=litellm_repo_path)
    generated_dir = repo_root / "tools" / "generated"
    suffix = f"_{output_suffix}" if output_suffix else ""
    sqlite_path = generated_dir / f"litellm_model_matrix{suffix}.sqlite3"
    json_path = generated_dir / f"litellm_model_matrix{suffix}.json"
    write_sqlite_output(payload, sqlite_path)
    if write_json:
        write_json_output(payload, json_path)
    payload["_artifacts"] = {
        "sqlite_path": str(sqlite_path),
        "json_path": str(json_path),
    }
    return payload
