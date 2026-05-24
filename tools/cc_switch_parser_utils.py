from __future__ import annotations

import ast
from dataclasses import dataclass


@dataclass(frozen=True)
class TopLevelProperty:
    key: str
    raw_value: str


def _skip_comment(text: str, index: int) -> int:
    if text.startswith("//", index):
        newline_index = text.find("\n", index + 2)
        return len(text) if newline_index == -1 else newline_index + 1
    if text.startswith("/*", index):
        end_index = text.find("*/", index + 2)
        return len(text) if end_index == -1 else end_index + 2
    return index


def _skip_ws_comments(text: str, index: int, skip_commas: bool = False) -> int:
    cursor = index
    while cursor < len(text):
        if text[cursor].isspace() or (skip_commas and text[cursor] == ","):
            cursor += 1
            continue
        next_cursor = _skip_comment(text, cursor)
        if next_cursor != cursor:
            cursor = next_cursor
            continue
        break
    return cursor


def _scan_quoted(text: str, index: int, quote: str) -> int:
    cursor = index + 1
    while cursor < len(text):
        char = text[cursor]
        if char == "\\":
            cursor += 2
            continue
        if char == quote:
            return cursor + 1
        cursor += 1
    raise ValueError(f"Unterminated string starting at {index}")


def _scan_template(text: str, index: int) -> int:
    cursor = index + 1
    while cursor < len(text):
        char = text[cursor]
        if char == "\\":
            cursor += 2
            continue
        if char == "`":
            return cursor + 1
        cursor += 1
    raise ValueError(f"Unterminated template string starting at {index}")


def _scan_balanced(text: str, start_index: int, open_char: str, close_char: str) -> int:
    depth = 0
    cursor = start_index
    while cursor < len(text):
        char = text[cursor]
        if char in ("'", '"'):
            cursor = _scan_quoted(text, cursor, char)
            continue
        if char == "`":
            cursor = _scan_template(text, cursor)
            continue
        next_cursor = _skip_comment(text, cursor)
        if next_cursor != cursor:
            cursor = next_cursor
            continue
        if char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return cursor + 1
        cursor += 1
    raise ValueError(f"Unterminated balanced block beginning at {start_index}")


def extract_balanced_after_marker(text: str, marker: str, open_char: str, close_char: str) -> str:
    marker_index = text.find(marker)
    if marker_index == -1:
        raise ValueError(f"Marker not found: {marker}")
    search_start = marker_index
    equals_index = text.find("=", marker_index)
    statement_end = text.find(";", marker_index)
    if equals_index != -1 and (statement_end == -1 or equals_index < statement_end):
        search_start = equals_index
    open_index = text.find(open_char, search_start)
    if open_index == -1:
        raise ValueError(f"Opening delimiter not found after marker: {marker}")
    end_index = _scan_balanced(text, open_index, open_char, close_char)
    return text[open_index:end_index]


def split_top_level_array_items(array_text: str) -> list[str]:
    if not array_text.startswith("[") or not array_text.endswith("]"):
        raise ValueError("Array text must be wrapped by []")

    items: list[str] = []
    cursor = 1
    item_start = None
    brace_depth = 0
    bracket_depth = 0
    paren_depth = 0

    while cursor < len(array_text):
        cursor = _skip_ws_comments(array_text, cursor)
        if cursor >= len(array_text):
            break

        if item_start is None:
            item_start = cursor

        char = array_text[cursor]
        if char in ("'", '"'):
            cursor = _scan_quoted(array_text, cursor, char)
            continue
        if char == "`":
            cursor = _scan_template(array_text, cursor)
            continue
        next_cursor = _skip_comment(array_text, cursor)
        if next_cursor != cursor:
            cursor = next_cursor
            continue

        if char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth -= 1
        elif char == "[":
            bracket_depth += 1
        elif char == "]":
            if brace_depth == 0 and bracket_depth == 0 and paren_depth == 0:
                raw_item = array_text[item_start:cursor].strip()
                if raw_item:
                    items.append(raw_item)
                break
            bracket_depth -= 1
        elif char == "(":
            paren_depth += 1
        elif char == ")":
            paren_depth -= 1
        elif char == "," and brace_depth == 0 and bracket_depth == 0 and paren_depth == 0:
            raw_item = array_text[item_start:cursor].strip()
            if raw_item:
                items.append(raw_item)
            item_start = None
            cursor += 1
            continue
        cursor += 1
    return items


def extract_object_literals(array_text: str) -> list[str]:
    return [item for item in split_top_level_array_items(array_text) if item.startswith("{")]


def parse_top_level_properties(object_text: str) -> list[TopLevelProperty]:
    if not object_text.startswith("{") or not object_text.endswith("}"):
        raise ValueError("Object text must be wrapped by {}")

    properties: list[TopLevelProperty] = []
    cursor = 1
    while cursor < len(object_text) - 1:
        cursor = _skip_ws_comments(object_text, cursor, skip_commas=True)
        if cursor >= len(object_text) - 1 or object_text[cursor] == "}":
            break

        key_start = cursor
        if object_text[cursor] in ("'", '"'):
            key_end = _scan_quoted(object_text, cursor, object_text[cursor])
            key = decode_js_string(object_text[key_start:key_end])
            cursor = key_end
        else:
            while cursor < len(object_text) and (object_text[cursor].isalnum() or object_text[cursor] in "_$-"):
                cursor += 1
            key = object_text[key_start:cursor].strip()

        cursor = _skip_ws_comments(object_text, cursor)
        if cursor >= len(object_text) or object_text[cursor] != ":":
            raise ValueError(f"Invalid object property near index {cursor}")
        cursor += 1
        cursor = _skip_ws_comments(object_text, cursor)
        value_start = cursor

        brace_depth = 0
        bracket_depth = 0
        paren_depth = 0
        while cursor < len(object_text):
            char = object_text[cursor]
            if char in ("'", '"'):
                cursor = _scan_quoted(object_text, cursor, char)
                continue
            if char == "`":
                cursor = _scan_template(object_text, cursor)
                continue
            next_cursor = _skip_comment(object_text, cursor)
            if next_cursor != cursor:
                cursor = next_cursor
                continue
            if char == "{":
                brace_depth += 1
            elif char == "}":
                if brace_depth == 0 and bracket_depth == 0 and paren_depth == 0:
                    raw_value = object_text[value_start:cursor].strip()
                    properties.append(TopLevelProperty(key=key, raw_value=raw_value))
                    return properties
                brace_depth -= 1
            elif char == "[":
                bracket_depth += 1
            elif char == "]":
                bracket_depth -= 1
            elif char == "(":
                paren_depth += 1
            elif char == ")":
                paren_depth -= 1
            elif char == "," and brace_depth == 0 and bracket_depth == 0 and paren_depth == 0:
                raw_value = object_text[value_start:cursor].strip()
                properties.append(TopLevelProperty(key=key, raw_value=raw_value))
                cursor += 1
                break
            cursor += 1
        else:
            raise ValueError("Unterminated object while parsing top-level properties")
    return properties


def properties_to_map(object_text: str) -> dict[str, str]:
    return {property_entry.key: property_entry.raw_value for property_entry in parse_top_level_properties(object_text)}


def decode_js_string(raw_value: str) -> str:
    stripped = raw_value.strip()
    if len(stripped) < 2:
        return stripped
    if stripped[0] == "`" and stripped[-1] == "`":
        return stripped[1:-1]
    if stripped[0] == '"' and stripped[-1] == '"':
        return ast.literal_eval(stripped)
    if stripped[0] == "'" and stripped[-1] == "'":
        return ast.literal_eval(stripped)
    return stripped


def decode_string_list(raw_value: str) -> list[str]:
    array_items = split_top_level_array_items(raw_value)
    return [decode_js_string(item) for item in array_items if item]


def decode_bool(raw_value: str, default: bool = False) -> bool:
    normalized = raw_value.strip()
    if normalized == "true":
        return True
    if normalized == "false":
        return False
    return default


def decode_number(raw_value: str) -> int | float | None:
    normalized = raw_value.strip()
    if not normalized:
        return None
    try:
        if "." in normalized:
            return float(normalized)
        return int(normalized)
    except ValueError:
        return None


def decode_identifier(raw_value: str) -> str:
    return raw_value.strip().rstrip(",")


def parse_function_call(raw_value: str) -> tuple[str, list[str]] | None:
    stripped = raw_value.strip()
    paren_index = stripped.find("(")
    if paren_index == -1 or not stripped.endswith(")"):
        return None
    callee = stripped[:paren_index].strip()
    args_text = stripped[paren_index + 1 : -1]
    args = split_top_level_array_items(f"[{args_text}]")
    return callee, args
