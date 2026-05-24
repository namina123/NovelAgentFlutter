from __future__ import annotations

import json
import re
import sqlite3
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from cc_switch_parser_utils import (
    decode_bool,
    decode_identifier,
    decode_js_string,
    decode_number,
    decode_string_list,
    extract_balanced_after_marker,
    extract_object_literals,
    parse_function_call,
    properties_to_map,
)


CLAUDE_PROTOCOL_BY_API_FORMAT = {
    "anthropic": "anthropic_compatible",
    "openai_chat": "openai_compatible",
    "openai_responses": "openai_compatible",
    "gemini_native": "gemini_native",
}

CLAUDE_DESKTOP_PROTOCOL_BY_API_FORMAT = {
    "anthropic": "anthropic_compatible",
    "openai_chat": "openai_compatible",
    "openai_responses": "openai_compatible",
    "gemini_native": "gemini_native",
}

OPENCLAW_PROTOCOL_BY_API = {
    "openai-completions": "openai_compatible",
    "openai-responses": "openai_compatible",
    "anthropic-messages": "anthropic_compatible",
    "google-generative-ai": "gemini_native",
    "bedrock-converse-stream": "bedrock_native",
}

HERMES_PROTOCOL_BY_API_MODE = {
    "chat_completions": "openai_compatible",
    "anthropic_messages": "anthropic_compatible",
    "codex_responses": "openai_compatible",
    "bedrock_converse": "bedrock_native",
}

OPENCODE_PROTOCOL_BY_NPM = {
    "@ai-sdk/openai": "openai_compatible",
    "@ai-sdk/openai-compatible": "openai_compatible",
    "@ai-sdk/anthropic": "anthropic_compatible",
    "@ai-sdk/amazon-bedrock": "bedrock_native",
    "@ai-sdk/google": "gemini_native",
}

VENDOR_NAME_ZH_OVERRIDES = {
    "claude official": "Claude 官方",
    "openai official": "OpenAI 官方",
    "google official": "Google 官方",
    "google official gemini api": "Google 官方",
    "gemini native": "Gemini 原生",
    "azure openai": "微软 Azure OpenAI",
    "deepseek": "深度求索",
    "moonshot": "月之暗面",
    "kimi": "Kimi",
    "dashscope": "阿里云百炼",
    "alibaba cloud": "阿里云百炼",
    "byteplus": "BytePlus",
    "newapi": "NewAPI",
    "custom gateway": "自定义网关",
}

CLAUDE_DESKTOP_ROLE_ROUTE_IDS = {
    "sonnet": "claude-sonnet-4-6",
    "opus": "claude-opus-4-7",
    "haiku": "claude-haiku-4-5",
}

SOURCE_FILES = (
    ("claude", "src/config/claudeProviderPresets.ts"),
    ("gemini", "src/config/geminiProviderPresets.ts"),
    ("codex", "src/config/codexProviderPresets.ts"),
    ("openclaw", "src/config/openclawProviderPresets.ts"),
    ("universal", "src/config/universalProviderPresets.ts"),
)


@dataclass
class PresetModelRecord:
    app_id: str
    model_role: str
    model_id: str
    display_name: str | None = None
    context_window: int | None = None
    input_cost: float | None = None
    output_cost: float | None = None
    reasoning_effort: str | None = None
    sort_order: int = 0


@dataclass
class PresetAppRecord:
    app_id: str
    enabled: bool


@dataclass
class PresetRecord:
    app_family: str
    source_file: str
    display_name: str
    vendor_name_zh: str
    name_key: str | None
    category: str | None
    provider_type: str | None
    protocol_id: str | None
    api_format: str | None
    base_url: str | None
    base_url_mode: str
    base_url_template_default: str | None
    models_url: str | None
    website_url: str | None
    api_key_url: str | None
    icon: str | None
    icon_color: str | None
    is_official: bool
    is_partner: bool
    requires_oauth: bool
    hidden: bool
    is_custom_template: bool
    partner_promotion_key: str | None
    notes: str | None = None
    endpoint_candidates: list[str] = field(default_factory=list)
    apps: list[PresetAppRecord] = field(default_factory=list)
    models: list[PresetModelRecord] = field(default_factory=list)


def normalize_slug(text: str) -> str:
    # 中文注释: 目录内部仍需要稳定主键，但它只作为数据库键使用，不会暴露给最终用户。
    slug = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return slug or "preset"


def allocate_unique_keys(presets: list[PresetRecord]) -> dict[int, str]:
    # 中文注释: 同名预设按 _2、_3 后缀扩展，和你前面要求的命名冲突策略保持一致。
    usage: dict[str, int] = defaultdict(int)
    keys: dict[int, str] = {}
    for index, preset in enumerate(presets):
        base_key = normalize_slug(f"{preset.app_family}_{preset.display_name}")
        usage[base_key] += 1
        keys[index] = base_key if usage[base_key] == 1 else f"{base_key}_{usage[base_key]}"
    return keys


def resolve_vendor_name_zh(display_name: str) -> str:
    lowered = display_name.lower().strip()
    if lowered in VENDOR_NAME_ZH_OVERRIDES:
        return VENDOR_NAME_ZH_OVERRIDES[lowered]
    return display_name


def decode_ts_stringish(raw_value: str | None) -> str | None:
    if raw_value is None:
        return None
    stripped = raw_value.strip()
    type_assertion_match = re.match(r"^(.*?)(?:\s+as\s+[A-Za-z0-9_.<>]+)\s*$", stripped)
    normalized = type_assertion_match.group(1).strip() if type_assertion_match else stripped
    if not normalized:
        return None
    if normalized.startswith(("'", '"', "`")):
        return decode_js_string(normalized)
    return normalized


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def resolve_repo_commit(repo_path: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
            capture_output=True,
            check=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return result.stdout.strip() or None


def parse_object(raw_value: str) -> dict[str, str]:
    return properties_to_map(raw_value) if raw_value.startswith("{") and raw_value.endswith("}") else {}


def extract_route_role(route_id: str) -> str:
    lowered = route_id.lower()
    if "sonnet" in lowered:
        return "sonnet"
    if "opus" in lowered:
        return "opus"
    if "haiku" in lowered:
        return "haiku"
    return "route"


def resolve_claude_desktop_route_entries(raw_value: str) -> list[dict[str, Any]]:
    stripped = raw_value.strip()
    if stripped.startswith("["):
        entries: list[dict[str, Any]] = []
        for route_object in extract_object_literals(stripped):
            route_props = properties_to_map(route_object)
            entries.append(
                {
                    "routeId": decode_js_string(route_props["routeId"]),
                    "upstreamModel": decode_js_string(route_props["upstreamModel"]),
                    "labelOverride": decode_js_string(route_props["labelOverride"]) if route_props.get("labelOverride") else None,
                    "supports1m": decode_bool(route_props.get("supports1m", "false")),
                }
            )
        return entries

    function_call = parse_function_call(stripped)
    if not function_call:
        return []

    callee, args = function_call
    supports1m = False
    if args and args[-1] in {"true", "false"}:
        supports1m = decode_bool(args[-1], False)
        args = args[:-1]

    if callee == "passthroughRoutes":
        return [
            {
                "routeId": route_id,
                "upstreamModel": route_id,
                "labelOverride": None,
                "supports1m": supports1m,
            }
            for route_id in CLAUDE_DESKTOP_ROLE_ROUTE_IDS.values()
        ]

    if callee in {"mappedRoutes", "brandedRoutes"} and len(args) >= 3:
        upstreams = [parse_call_string_argument(arg) for arg in args[:3]]
        roles = ("sonnet", "opus", "haiku")
        entries = []
        seen_upstream: set[str] = set()
        for role, upstream in zip(roles, upstreams, strict=False):
            if callee == "brandedRoutes" and upstream in seen_upstream:
                continue
            seen_upstream.add(upstream)
            entries.append(
                {
                    "routeId": CLAUDE_DESKTOP_ROLE_ROUTE_IDS[role],
                    "upstreamModel": upstream,
                    "labelOverride": upstream if callee == "brandedRoutes" else None,
                    "supports1m": supports1m,
                }
            )
        return entries

    return []


def parse_base_url_fields(raw_value: str | None) -> tuple[str | None, str, str | None]:
    if not raw_value:
        return None, "empty", None
    stripped = raw_value.strip()
    if not stripped:
        return None, "empty", None
    if stripped.startswith('"') or stripped.startswith("'") or stripped.startswith("`"):
        decoded = decode_js_string(stripped)
        return (decoded or None), ("fixed" if decoded else "empty"), None
    if stripped.startswith("{"):
        object_props = parse_object(stripped)
        default_value = object_props.get("defaultValue") or object_props.get("placeholder")
        decoded_default = decode_js_string(default_value) if default_value else None
        return decoded_default, "template", decoded_default
    return decode_identifier(stripped), "expression", None


def parse_config_literal_settings(config_text: str) -> dict[str, str]:
    settings: dict[str, str] = {}
    for line in config_text.splitlines():
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        settings[key.strip()] = value.strip()
    return settings


def clean_config_string(raw_value: str) -> str | None:
    stripped = raw_value.strip()
    if stripped.startswith("`") and stripped.endswith("`"):
        return decode_js_string(stripped)
    return None


def parse_call_string_argument(raw_arg: str) -> str:
    stripped = raw_arg.strip()
    if stripped.startswith(("'", '"', "`")):
        return decode_js_string(stripped)
    return decode_identifier(stripped)


def strip_prefixed_model_id(model_ref: str) -> str:
    return model_ref.split("/", 1)[1] if "/" in model_ref else model_ref


def append_unique_endpoint(target: list[str], endpoint: str | None) -> None:
    if endpoint and endpoint not in target:
        target.append(endpoint)


def extract_claude_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/claudeProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const providerPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        env_props = parse_object(parse_object(props.get("settingsConfig", "{}")).get("env", "{}"))
        api_format = decode_js_string(props["apiFormat"]) if props.get("apiFormat") else "anthropic"
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(env_props.get("ANTHROPIC_BASE_URL"))
        models_url = decode_js_string(props["modelsUrl"]) if props.get("modelsUrl") else None
        endpoint_candidates = decode_string_list(props["endpointCandidates"]) if props.get("endpointCandidates") else []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="claude",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=decode_js_string(props["providerType"]) if props.get("providerType") else None,
            protocol_id=CLAUDE_PROTOCOL_BY_API_FORMAT.get(api_format, "anthropic_compatible"),
            api_format=api_format,
            base_url=base_url,
            base_url_mode=base_url_mode,
            base_url_template_default=base_url_template_default,
            models_url=models_url,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=decode_bool(props.get("requiresOAuth", "false")),
            hidden=decode_bool(props.get("hidden", "false")),
            is_custom_template=False,
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="claude", enabled=True)],
        )

        role_pairs = (
            ("primary", env_props.get("ANTHROPIC_MODEL")),
            ("haiku", env_props.get("ANTHROPIC_DEFAULT_HAIKU_MODEL")),
            ("sonnet", env_props.get("ANTHROPIC_DEFAULT_SONNET_MODEL")),
            ("opus", env_props.get("ANTHROPIC_DEFAULT_OPUS_MODEL")),
        )
        for sort_order, (role, raw_model) in enumerate(role_pairs, start=1):
            if not raw_model:
                continue
            preset.models.append(
                PresetModelRecord(
                    app_id="claude",
                    model_role=role,
                    model_id=decode_js_string(raw_model),
                    sort_order=sort_order,
                )
            )
        presets.append(preset)
    return presets


def extract_gemini_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/geminiProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const geminiProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(props.get("baseURL"))
        endpoint_candidates = decode_string_list(props["endpointCandidates"]) if props.get("endpointCandidates") else []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="gemini",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=None,
            protocol_id="gemini_native",
            api_format="gemini_native",
            base_url=base_url,
            base_url_mode=base_url_mode,
            base_url_template_default=base_url_template_default,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=False,
            hidden=False,
            is_custom_template=False,
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="gemini", enabled=True)],
        )
        if props.get("model"):
            preset.models.append(
                PresetModelRecord(
                    app_id="gemini",
                    model_role="primary",
                    model_id=decode_js_string(props["model"]),
                    sort_order=1,
                )
            )
        presets.append(preset)
    return presets


def extract_claude_desktop_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/claudeDesktopProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const claudeDesktopProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        api_format = decode_js_string(props["apiFormat"]) if props.get("apiFormat") else "anthropic"
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(props.get("baseUrl"))
        endpoint_candidates = decode_string_list(props["endpointCandidates"]) if props.get("endpointCandidates") else []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="claude-desktop",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=decode_js_string(props["providerType"]) if props.get("providerType") else None,
            protocol_id=CLAUDE_DESKTOP_PROTOCOL_BY_API_FORMAT.get(api_format, "anthropic_compatible"),
            api_format=api_format,
            base_url=base_url,
            base_url_mode=base_url_mode if base_url is not None else "empty",
            base_url_template_default=base_url_template_default,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=decode_bool(props.get("requiresOAuth", "false")),
            hidden=False,
            is_custom_template=False,
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            notes=f"mode={decode_js_string(props['mode'])}" if props.get("mode") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="claude-desktop", enabled=True)],
        )

        if props.get("modelRoutes"):
            for sort_order, route_entry in enumerate(resolve_claude_desktop_route_entries(props["modelRoutes"]), start=1):
                route_id = str(route_entry["routeId"])
                upstream_model = str(route_entry["upstreamModel"])
                display_name = str(route_entry["labelOverride"] or upstream_model)
                preset.models.append(
                    PresetModelRecord(
                        app_id="claude-desktop",
                        model_role=extract_route_role(route_id),
                        model_id=upstream_model,
                        display_name=display_name,
                        sort_order=sort_order,
                    )
                )
        presets.append(preset)
    return presets


def extract_codex_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/codexProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const codexProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        config_text: str | None = None
        if props.get("config"):
            config_literal = clean_config_string(props["config"])
            if config_literal is not None:
                config_text = config_literal
            else:
                function_call = parse_function_call(props["config"])
                if function_call and function_call[0] == "generateThirdPartyConfig" and len(function_call[1]) >= 3:
                    provider_name = parse_call_string_argument(function_call[1][0])
                    base_url = parse_call_string_argument(function_call[1][1])
                    model_name = parse_call_string_argument(function_call[1][2])
                    config_text = (
                        f'model_provider = "{provider_name}"\n'
                        f'model = "{model_name}"\n'
                        'model_reasoning_effort = "high"\n'
                        "disable_response_storage = true\n\n"
                        f"[model_providers.{provider_name}]\n"
                        f'name = "{provider_name}"\n'
                        f'base_url = "{base_url}"\n'
                        'wire_api = "responses"\n'
                        "requires_openai_auth = true"
                    )

        config_settings = parse_config_literal_settings(config_text or "")
        base_url = None
        if "base_url" in config_settings:
            base_url = decode_js_string(config_settings["base_url"])

        wire_api = decode_js_string(config_settings["wire_api"]) if "wire_api" in config_settings else "responses"
        endpoint_candidates = decode_string_list(props["endpointCandidates"]) if props.get("endpointCandidates") else []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="codex",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=None,
            protocol_id="openai_compatible",
            api_format=f"openai_{wire_api}",
            base_url=base_url,
            base_url_mode="fixed" if base_url else "empty",
            base_url_template_default=None,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=decode_bool(props.get("requiresOAuth", "false")),
            hidden=False,
            is_custom_template=decode_bool(props.get("isCustomTemplate", "false")),
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="codex", enabled=True)],
        )
        if "model" in config_settings:
            preset.models.append(
                PresetModelRecord(
                    app_id="codex",
                    model_role="primary",
                    model_id=decode_js_string(config_settings["model"]),
                    reasoning_effort=decode_js_string(config_settings["model_reasoning_effort"]) if "model_reasoning_effort" in config_settings else None,
                    sort_order=1,
                )
            )
        presets.append(preset)
    return presets


def extract_hermes_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/hermesProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const hermesProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        settings_config = parse_object(props.get("settingsConfig", "{}"))
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(settings_config.get("base_url"))
        api_mode = decode_js_string(settings_config["api_mode"]) if settings_config.get("api_mode") else "chat_completions"
        endpoint_candidates: list[str] = []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="hermes",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=None,
            protocol_id=HERMES_PROTOCOL_BY_API_MODE.get(api_mode, "openai_compatible"),
            api_format=api_mode,
            base_url=base_url,
            base_url_mode=base_url_mode,
            base_url_template_default=base_url_template_default,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=False,
            hidden=False,
            is_custom_template=decode_bool(props.get("isCustomTemplate", "false")),
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="hermes", enabled=True)],
        )

        default_model_id = None
        if props.get("suggestedDefaults"):
            suggested_defaults = parse_object(props["suggestedDefaults"])
            model_object = parse_object(suggested_defaults.get("model", "{}"))
            if model_object.get("default"):
                default_model_id = decode_js_string(model_object["default"])

        if settings_config.get("models"):
            for sort_order, model_object in enumerate(extract_object_literals(settings_config["models"]), start=1):
                model_props = properties_to_map(model_object)
                model_id = decode_js_string(model_props["id"])
                context_length = decode_number(model_props["context_length"]) if model_props.get("context_length") else None
                preset.models.append(
                    PresetModelRecord(
                        app_id="hermes",
                        model_role="default_primary" if default_model_id == model_id else "catalog",
                        model_id=model_id,
                        display_name=decode_js_string(model_props["name"]) if model_props.get("name") else None,
                        context_window=int(context_length) if context_length is not None else None,
                        sort_order=sort_order,
                    )
                )
        presets.append(preset)
    return presets


def extract_opencode_variant_catalog(repo_path: Path) -> dict[str, dict[str, dict[str, Any]]]:
    source_file = "src/config/opencodeProviderPresets.ts"
    text = read_text(repo_path / source_file)
    object_text = extract_balanced_after_marker(text, "export const OPENCODE_PRESET_MODEL_VARIANTS", "{", "}")
    result: dict[str, dict[str, dict[str, Any]]] = {}
    for npm_name, array_text in parse_object(object_text).items():
        variants: dict[str, dict[str, Any]] = {}
        if array_text.startswith("["):
            for variant_object in extract_object_literals(array_text):
                variant_props = properties_to_map(variant_object)
                model_id = decode_js_string(variant_props["id"])
                variants[model_id] = {
                    "name": decode_js_string(variant_props["name"]) if variant_props.get("name") else None,
                    "contextLimit": decode_number(variant_props["contextLimit"]) if variant_props.get("contextLimit") else None,
                    "outputLimit": decode_number(variant_props["outputLimit"]) if variant_props.get("outputLimit") else None,
                }
        result[decode_js_string(npm_name) if npm_name.startswith(("'", '"')) else npm_name] = variants
    return result


def extract_opencode_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/opencodeProviderPresets.ts"
    text = read_text(repo_path / source_file)
    variant_catalog = extract_opencode_variant_catalog(repo_path)
    array_text = extract_balanced_after_marker(text, "export const opencodeProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        settings_config = parse_object(props.get("settingsConfig", "{}"))
        options = parse_object(settings_config.get("options", "{}"))
        npm_name = decode_js_string(settings_config["npm"]) if settings_config.get("npm") else ""
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(options.get("baseURL"))
        endpoint_candidates: list[str] = []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="opencode",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=None,
            protocol_id=OPENCODE_PROTOCOL_BY_NPM.get(npm_name, "openai_compatible" if not npm_name else None),
            api_format=npm_name or None,
            base_url=base_url,
            base_url_mode=base_url_mode,
            base_url_template_default=base_url_template_default,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=False,
            hidden=False,
            is_custom_template=decode_bool(props.get("isCustomTemplate", "false")),
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="opencode", enabled=True)],
        )

        model_map = parse_object(settings_config.get("models", "{}"))
        sort_order = 1
        for model_id_raw, model_value in model_map.items():
            model_id = decode_js_string(model_id_raw) if model_id_raw.startswith(("'", '"')) else model_id_raw
            model_props = parse_object(model_value)
            variant_defaults = variant_catalog.get(npm_name, {}).get(model_id, {})
            context_limit = variant_defaults.get("contextLimit")
            output_limit = variant_defaults.get("outputLimit")
            preset.models.append(
                PresetModelRecord(
                    app_id="opencode",
                    model_role="catalog",
                    model_id=model_id,
                    display_name=decode_js_string(model_props["name"]) if model_props.get("name") else variant_defaults.get("name"),
                    context_window=int(context_limit) if context_limit is not None else None,
                    sort_order=sort_order,
                )
            )
            if output_limit is not None:
                preset.models[-1].reasoning_effort = f"output_limit={int(output_limit)}"
            sort_order += 1

        presets.append(preset)
    return presets


def extract_openclaw_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/openclawProviderPresets.ts"
    text = read_text(repo_path / source_file)
    array_text = extract_balanced_after_marker(text, "export const openclawProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        settings_config = parse_object(props.get("settingsConfig", "{}"))
        base_url, base_url_mode, base_url_template_default = parse_base_url_fields(settings_config.get("baseUrl"))
        protocol_raw = decode_js_string(settings_config["api"]) if settings_config.get("api") else None
        endpoint_candidates = []
        append_unique_endpoint(endpoint_candidates, base_url)

        preset = PresetRecord(
            app_family="openclaw",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=decode_js_string(props["nameKey"]) if props.get("nameKey") else None,
            category=decode_js_string(props["category"]) if props.get("category") else None,
            provider_type=None,
            protocol_id=OPENCLAW_PROTOCOL_BY_API.get(protocol_raw or "", None),
            api_format=protocol_raw,
            base_url=base_url,
            base_url_mode=base_url_mode,
            base_url_template_default=base_url_template_default,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=decode_js_string(props["apiKeyUrl"]) if props.get("apiKeyUrl") else None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=decode_bool(props.get("isOfficial", "false")),
            is_partner=decode_bool(props.get("isPartner", "false")),
            requires_oauth=False,
            hidden=False,
            is_custom_template=decode_bool(props.get("isCustomTemplate", "false")),
            partner_promotion_key=decode_js_string(props["partnerPromotionKey"]) if props.get("partnerPromotionKey") else None,
            endpoint_candidates=endpoint_candidates,
            apps=[PresetAppRecord(app_id="openclaw", enabled=True)],
        )

        model_defaults: dict[str, str] = {}
        if props.get("suggestedDefaults"):
            suggested_defaults = parse_object(props["suggestedDefaults"])
            if suggested_defaults.get("model"):
                default_model_props = parse_object(suggested_defaults["model"])
                if default_model_props.get("primary"):
                    model_defaults[strip_prefixed_model_id(decode_js_string(default_model_props["primary"]))] = "default_primary"
                if default_model_props.get("fallbacks"):
                    for fallback in decode_string_list(default_model_props["fallbacks"]):
                        model_defaults.setdefault(strip_prefixed_model_id(fallback), "default_fallback")

        model_sort = 1
        if settings_config.get("models"):
            for model_object in extract_object_literals(settings_config["models"]):
                model_props = properties_to_map(model_object)
                cost_props = parse_object(model_props.get("cost", "{}"))
                model_id = decode_js_string(model_props["id"])
                context_window_value = decode_number(model_props["contextWindow"]) if model_props.get("contextWindow") else None
                input_cost_value = decode_number(cost_props["input"]) if cost_props.get("input") else None
                output_cost_value = decode_number(cost_props["output"]) if cost_props.get("output") else None
                preset.models.append(
                    PresetModelRecord(
                        app_id="openclaw",
                        model_role=model_defaults.get(model_id, "catalog"),
                        model_id=model_id,
                        display_name=decode_js_string(model_props["name"]) if model_props.get("name") else None,
                        context_window=int(context_window_value) if context_window_value is not None else None,
                        input_cost=float(input_cost_value) if input_cost_value is not None else None,
                        output_cost=float(output_cost_value) if output_cost_value is not None else None,
                        sort_order=model_sort,
                    )
                )
                model_sort += 1
        presets.append(preset)
    return presets


def parse_universal_default_models(raw_value: str, constants: dict[str, dict[str, str]]) -> dict[str, dict[str, str]]:
    if raw_value.startswith("{"):
        outer = parse_object(raw_value)
        return {key: parse_object(value) for key, value in outer.items()}
    return constants.get(decode_identifier(raw_value), {})


def extract_universal_constants(text: str) -> dict[str, dict[str, dict[str, str]]]:
    constants: dict[str, dict[str, dict[str, str]]] = {}
    object_text = extract_balanced_after_marker(text, "const NEWAPI_DEFAULT_MODELS", "{", "}")
    constants["NEWAPI_DEFAULT_MODELS"] = {key: parse_object(value) for key, value in parse_object(object_text).items()}
    return constants


def extract_universal_presets(repo_path: Path) -> list[PresetRecord]:
    source_file = "src/config/universalProviderPresets.ts"
    text = read_text(repo_path / source_file)
    constants = extract_universal_constants(text)
    array_text = extract_balanced_after_marker(text, "export const universalProviderPresets", "[", "]")

    presets: list[PresetRecord] = []
    for object_text in extract_object_literals(array_text):
        props = properties_to_map(object_text)
        default_apps = parse_object(props.get("defaultApps", "{}"))
        default_models = parse_universal_default_models(props.get("defaultModels", "{}"), constants)

        preset = PresetRecord(
            app_family="universal",
            source_file=source_file,
            display_name=decode_js_string(props["name"]),
            vendor_name_zh=resolve_vendor_name_zh(decode_js_string(props["name"])),
            name_key=None,
            category="gateway_template",
            provider_type=decode_js_string(props["providerType"]) if props.get("providerType") else None,
            protocol_id="mixed_gateway",
            api_format="mixed_gateway",
            base_url=None,
            base_url_mode="user_input",
            base_url_template_default=None,
            models_url=None,
            website_url=decode_js_string(props["websiteUrl"]) if props.get("websiteUrl") else None,
            api_key_url=None,
            icon=decode_js_string(props["icon"]) if props.get("icon") else None,
            icon_color=decode_js_string(props["iconColor"]) if props.get("iconColor") else None,
            is_official=False,
            is_partner=False,
            requires_oauth=False,
            hidden=False,
            is_custom_template=decode_bool(props.get("isCustomTemplate", "false")),
            partner_promotion_key=None,
            notes=decode_js_string(props["description"]) if props.get("description") else None,
        )

        for app_id, raw_enabled in default_apps.items():
            preset.apps.append(PresetAppRecord(app_id=app_id, enabled=decode_bool(raw_enabled)))

        for app_id, model_object in default_models.items():
            if model_object.get("model"):
                preset.models.append(
                    PresetModelRecord(
                        app_id=app_id,
                        model_role="primary",
                        model_id=decode_js_string(model_object["model"]),
                        reasoning_effort=decode_js_string(model_object["reasoningEffort"]) if model_object.get("reasoningEffort") else None,
                        sort_order=1,
                    )
                )
            for sort_order, role_name in enumerate(("haikuModel", "sonnetModel", "opusModel"), start=2):
                if model_object.get(role_name):
                    preset.models.append(
                        PresetModelRecord(
                            app_id=app_id,
                            model_role=role_name.replace("Model", "").lower(),
                            model_id=decode_js_string(model_object[role_name]),
                            sort_order=sort_order,
                        )
                    )
        presets.append(preset)
    return presets


def extract_all_presets(repo_path: Path) -> list[PresetRecord]:
    # 中文注释: 最终只保留一套主目录方案，这里把 cc-switch 视为权威预设来源统一抽取。
    presets: list[PresetRecord] = []
    presets.extend(extract_claude_presets(repo_path))
    presets.extend(extract_claude_desktop_presets(repo_path))
    presets.extend(extract_gemini_presets(repo_path))
    presets.extend(extract_codex_presets(repo_path))
    presets.extend(extract_opencode_presets(repo_path))
    presets.extend(extract_openclaw_presets(repo_path))
    presets.extend(extract_hermes_presets(repo_path))
    presets.extend(extract_universal_presets(repo_path))
    return presets


def build_payload(repo_path: Path) -> dict[str, Any]:
    package_json = json.loads((repo_path / "package.json").read_text(encoding="utf-8"))
    presets = extract_all_presets(repo_path)
    key_map = allocate_unique_keys(presets)

    payload_presets: list[dict[str, Any]] = []
    payload_endpoints: list[dict[str, Any]] = []
    payload_apps: list[dict[str, Any]] = []
    payload_models: list[dict[str, Any]] = []

    for index, preset in enumerate(presets):
        preset_key = key_map[index]
        payload_presets.append(
            {
                "preset_key": preset_key,
                "app_family": preset.app_family,
                "source_file": preset.source_file,
                "display_name": preset.display_name,
                "vendor_name_zh": preset.vendor_name_zh,
                "name_key": preset.name_key,
                "category": preset.category,
                "provider_type": preset.provider_type,
                "protocol_id": preset.protocol_id,
                "api_format": preset.api_format,
                "base_url": preset.base_url,
                "base_url_mode": preset.base_url_mode,
                "base_url_template_default": preset.base_url_template_default,
                "models_url": preset.models_url,
                "website_url": preset.website_url,
                "api_key_url": preset.api_key_url,
                "icon": preset.icon,
                "icon_color": preset.icon_color,
                "is_official": preset.is_official,
                "is_partner": preset.is_partner,
                "requires_oauth": preset.requires_oauth,
                "hidden": preset.hidden,
                "is_custom_template": preset.is_custom_template,
                "partner_promotion_key": preset.partner_promotion_key,
                "notes": preset.notes,
            }
        )
        for order, endpoint_url in enumerate(preset.endpoint_candidates, start=1):
            payload_endpoints.append(
                {
                    "preset_key": preset_key,
                    "endpoint_url": endpoint_url,
                    "sort_order": order,
                }
            )
        for app_entry in preset.apps:
            payload_apps.append(
                {
                    "preset_key": preset_key,
                    "app_id": app_entry.app_id,
                    "enabled": app_entry.enabled,
                }
            )
        for model_entry in preset.models:
            payload_models.append(
                {
                    "preset_key": preset_key,
                    "app_id": model_entry.app_id,
                    "model_role": model_entry.model_role,
                    "model_id": model_entry.model_id,
                    "display_name": model_entry.display_name,
                    "context_window": model_entry.context_window,
                    "input_cost": model_entry.input_cost,
                    "output_cost": model_entry.output_cost,
                    "reasoning_effort": model_entry.reasoning_effort,
                    "sort_order": model_entry.sort_order,
                }
            )

    diagnostics = {
        "preset_count_by_family": dict(sorted(Counter(item["app_family"] for item in payload_presets).items())),
        "model_count_by_app": dict(sorted(Counter(item["app_id"] for item in payload_models).items())),
        "preset_count": len(payload_presets),
        "endpoint_count": len(payload_endpoints),
        "app_binding_count": len(payload_apps),
        "model_count": len(payload_models),
    }

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": {
            "library": "cc-switch",
            "library_version": package_json.get("version"),
            "repo_path": str(repo_path),
            "repo_commit": resolve_repo_commit(repo_path),
            "notes": [
                "cc-switch 作为用户端主目录来源，保留其厂商入口、协议、默认模型与端点候选。",
                "LiteLLM 后续仅作为能力补充源参与关联，不再与主目录并列竞争。",
            ],
        },
        "provider_presets": payload_presets,
        "provider_preset_endpoints": payload_endpoints,
        "provider_preset_apps": payload_apps,
        "provider_preset_models": payload_models,
        "diagnostics": diagnostics,
    }


def write_json_output(payload: dict[str, Any], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def create_sqlite_schema(connection: sqlite3.Connection) -> None:
    connection.executescript(
        """
        PRAGMA foreign_keys = ON;

        CREATE TABLE metadata (
          key TEXT PRIMARY KEY,
          value TEXT
        );

        CREATE TABLE provider_presets (
          preset_key TEXT PRIMARY KEY,
          app_family TEXT NOT NULL,
          source_file TEXT NOT NULL,
          display_name TEXT NOT NULL,
          vendor_name_zh TEXT NOT NULL,
          name_key TEXT,
          category TEXT,
          provider_type TEXT,
          protocol_id TEXT,
          api_format TEXT,
          base_url TEXT,
          base_url_mode TEXT NOT NULL,
          base_url_template_default TEXT,
          models_url TEXT,
          website_url TEXT,
          api_key_url TEXT,
          icon TEXT,
          icon_color TEXT,
          is_official INTEGER NOT NULL,
          is_partner INTEGER NOT NULL,
          requires_oauth INTEGER NOT NULL,
          hidden INTEGER NOT NULL,
          is_custom_template INTEGER NOT NULL,
          partner_promotion_key TEXT,
          notes TEXT
        );

        CREATE TABLE provider_preset_endpoint_candidates (
          preset_key TEXT NOT NULL,
          endpoint_url TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          PRIMARY KEY (preset_key, endpoint_url),
          FOREIGN KEY (preset_key) REFERENCES provider_presets(preset_key) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE provider_preset_apps (
          preset_key TEXT NOT NULL,
          app_id TEXT NOT NULL,
          enabled INTEGER NOT NULL,
          PRIMARY KEY (preset_key, app_id),
          FOREIGN KEY (preset_key) REFERENCES provider_presets(preset_key) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE TABLE provider_preset_models (
          preset_key TEXT NOT NULL,
          app_id TEXT NOT NULL,
          model_role TEXT NOT NULL,
          model_id TEXT NOT NULL,
          display_name TEXT,
          context_window INTEGER,
          input_cost REAL,
          output_cost REAL,
          reasoning_effort TEXT,
          sort_order INTEGER NOT NULL,
          PRIMARY KEY (preset_key, app_id, model_role, model_id),
          FOREIGN KEY (preset_key) REFERENCES provider_presets(preset_key) ON DELETE CASCADE
        ) WITHOUT ROWID;

        CREATE VIEW user_facing_provider_presets AS
        SELECT * FROM provider_presets WHERE hidden = 0;

        CREATE VIEW user_facing_preset_models AS
        SELECT
          pp.preset_key,
          pp.app_family,
          pp.display_name AS provider_name,
          pp.vendor_name_zh,
          pp.protocol_id,
          pp.api_format,
          pp.base_url,
          ppm.app_id,
          ppm.model_role,
          ppm.model_id,
          ppm.display_name AS model_display_name,
          ppm.context_window,
          ppm.input_cost,
          ppm.output_cost,
          ppm.reasoning_effort
        FROM provider_preset_models ppm
        JOIN provider_presets pp ON pp.preset_key = ppm.preset_key
        WHERE pp.hidden = 0;

        CREATE INDEX idx_provider_presets_app_family ON provider_presets(app_family);
        CREATE INDEX idx_provider_presets_protocol_id ON provider_presets(protocol_id);
        CREATE INDEX idx_provider_preset_models_model_id ON provider_preset_models(model_id);
        """
    )


def write_sqlite_output(payload: dict[str, Any], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    connection = sqlite3.connect(output_path)
    try:
        create_sqlite_schema(connection)
        metadata_rows = [
            ("schema_version", str(payload["schema_version"])),
            ("generated_at", payload["generated_at"]),
            ("library", payload["source"]["library"]),
            ("library_version", str(payload["source"]["library_version"])),
            ("repo_path", json.dumps(payload["source"]["repo_path"], ensure_ascii=False)),
            ("repo_commit", json.dumps(payload["source"]["repo_commit"], ensure_ascii=False)),
            ("notes", json.dumps(payload["source"]["notes"], ensure_ascii=False)),
            ("diagnostics", json.dumps(payload["diagnostics"], ensure_ascii=False)),
        ]
        connection.executemany("INSERT INTO metadata(key, value) VALUES(?, ?)", metadata_rows)

        for preset in payload["provider_presets"]:
            connection.execute(
                """
                INSERT INTO provider_presets(
                  preset_key, app_family, source_file, display_name, vendor_name_zh,
                  name_key, category, provider_type, protocol_id, api_format, base_url,
                  base_url_mode, base_url_template_default, models_url, website_url,
                  api_key_url, icon, icon_color, is_official, is_partner, requires_oauth,
                  hidden, is_custom_template, partner_promotion_key, notes
                ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    preset["preset_key"],
                    preset["app_family"],
                    preset["source_file"],
                    preset["display_name"],
                    preset["vendor_name_zh"],
                    preset["name_key"],
                    preset["category"],
                    preset["provider_type"],
                    preset["protocol_id"],
                    preset["api_format"],
                    preset["base_url"],
                    preset["base_url_mode"],
                    preset["base_url_template_default"],
                    preset["models_url"],
                    preset["website_url"],
                    preset["api_key_url"],
                    preset["icon"],
                    preset["icon_color"],
                    1 if preset["is_official"] else 0,
                    1 if preset["is_partner"] else 0,
                    1 if preset["requires_oauth"] else 0,
                    1 if preset["hidden"] else 0,
                    1 if preset["is_custom_template"] else 0,
                    preset["partner_promotion_key"],
                    preset["notes"],
                ),
            )

        for endpoint_entry in payload["provider_preset_endpoints"]:
            connection.execute(
                """
                INSERT INTO provider_preset_endpoint_candidates(preset_key, endpoint_url, sort_order)
                VALUES(?, ?, ?)
                """,
                (
                    endpoint_entry["preset_key"],
                    endpoint_entry["endpoint_url"],
                    endpoint_entry["sort_order"],
                ),
            )

        for app_entry in payload["provider_preset_apps"]:
            connection.execute(
                "INSERT INTO provider_preset_apps(preset_key, app_id, enabled) VALUES(?, ?, ?)",
                (
                    app_entry["preset_key"],
                    app_entry["app_id"],
                    1 if app_entry["enabled"] else 0,
                ),
            )

        for model_entry in payload["provider_preset_models"]:
            connection.execute(
                """
                INSERT INTO provider_preset_models(
                  preset_key, app_id, model_role, model_id, display_name, context_window,
                  input_cost, output_cost, reasoning_effort, sort_order
                ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    model_entry["preset_key"],
                    model_entry["app_id"],
                    model_entry["model_role"],
                    model_entry["model_id"],
                    model_entry["display_name"],
                    model_entry["context_window"],
                    model_entry["input_cost"],
                    model_entry["output_cost"],
                    model_entry["reasoning_effort"],
                    model_entry["sort_order"],
                ),
            )
        connection.commit()
    finally:
        connection.close()


def export_cc_switch_provider_catalog(
    repo_root: Path,
    cc_switch_repo_path: Path,
    write_json: bool = True,
    output_suffix: str | None = None,
) -> dict[str, Any]:
    payload = build_payload(cc_switch_repo_path)
    generated_dir = repo_root / "tools" / "generated"
    suffix = f"_{output_suffix}" if output_suffix else ""
    sqlite_path = generated_dir / f"cc_switch_provider_catalog{suffix}.sqlite3"
    json_path = generated_dir / f"cc_switch_provider_catalog{suffix}.json"
    write_sqlite_output(payload, sqlite_path)
    if write_json:
        write_json_output(payload, json_path)
    payload["_artifacts"] = {
        "sqlite_path": str(sqlite_path),
        "json_path": str(json_path),
    }
    return payload
