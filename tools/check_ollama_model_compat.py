#!/usr/bin/env python3
"""Check Ollama model compatibility with Claude Code style tool use."""

from __future__ import annotations

import json
import os
import textwrap
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


DEFAULT_BASE_URLS = [
    "http://bruter",
    "http://bruter:11434",
]
PREFERRED_MODELS = [
    "qwen3.5:9b-q4_K_M",
    "qwen2.5-coder:7b-instruct-q4_K_M",
    "qwen2.5:7b-instruct-q4_K_M",
    "gemma3:12b-it-q4_K_M",
    "llama3.1:8b-instruct-q4_K_M",
]
TOOL_PROMPT = (
    "Use the Write tool to write the text 'compatibility test' to "
    "'/tmp/ollama-tool-test.txt'. Do not explain. Use the tool."
)
TEST_TOOL_V1 = {
    "name": "Write",
    "description": (
        "A test tool that writes content to a file. "
        "This is a compatibility test only. Do not execute it."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "file_path": {
                "type": "string",
                "description": "Target file path",
            },
            "content": {
                "type": "string",
                "description": "File content",
            },
        },
        "required": ["file_path", "content"],
    },
}
TEST_TOOL_NATIVE = {
    "type": "function",
    "function": {
        "name": TEST_TOOL_V1["name"],
        "description": TEST_TOOL_V1["description"],
        "parameters": TEST_TOOL_V1["input_schema"],
    },
}


@dataclass
class EndpointResult:
    ok: bool
    status: int | None
    payload: Any = None
    error: str | None = None


def http_json(
    base_url: str,
    path: str,
    payload: dict[str, Any] | None = None,
    timeout: int = 90,
) -> EndpointResult:
    url = base_url.rstrip("/") + path
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST" if payload is not None else "GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8")
            parsed = json.loads(raw) if raw else None
            return EndpointResult(ok=True, status=response.status, payload=parsed)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        parsed = try_parse_json(body)
        message = extract_error_message(parsed) or body.strip() or str(exc)
        return EndpointResult(
            ok=False,
            status=exc.code,
            payload=parsed if parsed is not None else body,
            error=message,
        )
    except Exception as exc:  # noqa: BLE001
        return EndpointResult(ok=False, status=None, error=str(exc))


def try_parse_json(text: str) -> Any | None:
    try:
        return json.loads(text)
    except Exception:  # noqa: BLE001
        return None


def extract_error_message(payload: Any) -> str | None:
    if isinstance(payload, dict):
        for key in ("error", "message", "detail"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
            if isinstance(value, dict):
                nested = extract_error_message(value)
                if nested:
                    return nested
    return None


def probe_base_url() -> tuple[str, EndpointResult]:
    env_url = os.environ.get("OLLAMA_BASE_URL")
    candidates = [env_url] if env_url else DEFAULT_BASE_URLS
    last_result: EndpointResult | None = None
    for base_url in candidates:
        if not base_url:
            continue
        result = http_json(base_url, "/api/tags", timeout=20)
        last_result = result
        if result.ok:
            return base_url, result
    raise RuntimeError(
        "Could not reach Ollama API via any base URL. "
        f"Last error: {last_result.error if last_result else 'unknown'}"
    )


def get_installed_models(tags_result: EndpointResult) -> list[dict[str, Any]]:
    models = tags_result.payload.get("models", []) if isinstance(tags_result.payload, dict) else []
    preferred = [m for m in models if m.get("name") in PREFERRED_MODELS]
    remaining = [m for m in models if m.get("name") not in PREFERRED_MODELS]
    preferred.sort(key=lambda item: PREFERRED_MODELS.index(item["name"]))
    remaining.sort(key=lambda item: item.get("name", ""))
    return preferred + remaining


def nested_get(mapping: dict[str, Any], *keys: str) -> Any:
    current: Any = mapping
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def truncate(text: str | None, limit: int = 120) -> str:
    if not text:
        return ""
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 3] + "..."


def format_size_bytes(size: int | None) -> str:
    if size is None:
        return ""
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return str(size)


def extract_context_length(show_payload: dict[str, Any]) -> str:
    model_info = show_payload.get("model_info") or {}
    for key in (
        "qwen2.context_length",
        "llama.context_length",
        "gemma.context_length",
        "gemma2.context_length",
        "phi3.context_length",
        "general.context_length",
    ):
        if key in model_info:
            return str(model_info[key])
    return ""


def classify_v1_tool_response(result: EndpointResult) -> dict[str, Any]:
    if not result.ok:
        message = result.error or ""
        lowered = message.lower()
        return {
            "status": f"Error: {truncate(message)}",
            "structured": False,
            "text_json": False,
            "notes": "Endpoint error" + (": " + truncate(message) if message else ""),
            "raw_text": "",
            "supports_tools": "does not support tools" not in lowered,
        }

    payload = result.payload if isinstance(result.payload, dict) else {}
    content = payload.get("content")
    raw_texts: list[str] = []
    structured = False
    if isinstance(content, list):
        for item in content:
            if not isinstance(item, dict):
                continue
            item_type = item.get("type")
            if item_type == "tool_use":
                structured = True
            if item_type == "text" and isinstance(item.get("text"), str):
                raw_texts.append(item["text"])
    elif isinstance(content, str):
        raw_texts.append(content)

    raw_text = "\n".join(raw_texts).strip()
    parsed_text = try_parse_json(raw_text) if raw_text else None
    text_json = isinstance(parsed_text, dict) and (
        ("name" in parsed_text and "arguments" in parsed_text)
        or ("tool" in parsed_text and "arguments" in parsed_text)
    )

    if structured:
        status = "Structured tool call"
        notes = "API returned tool_use content"
    elif text_json:
        status = "Text JSON imitation"
        notes = "Model printed tool call JSON as text"
    else:
        status = "No structured tool call"
        notes = truncate(raw_text or extract_error_message(payload) or "No tool_use block detected")

    return {
        "status": status,
        "structured": structured,
        "text_json": text_json,
        "notes": notes,
        "raw_text": raw_text,
        "supports_tools": True,
    }


def classify_native_tool_response(result: EndpointResult) -> str:
    if not result.ok:
        return f"Error: {truncate(result.error)}"
    payload = result.payload if isinstance(result.payload, dict) else {}
    tool_calls = nested_get(payload, "message", "tool_calls")
    if isinstance(tool_calls, list) and tool_calls:
        return "Structured tool call"
    message_content = nested_get(payload, "message", "content")
    parsed_text = try_parse_json(message_content) if isinstance(message_content, str) else None
    if isinstance(parsed_text, dict) and "arguments" in parsed_text:
        return "Text JSON imitation"
    return truncate(message_content or "No tool call detected")


def classify_basic_chat(result: EndpointResult) -> tuple[bool, str]:
    if not result.ok:
        return False, f"Error: {truncate(result.error)}"
    payload = result.payload if isinstance(result.payload, dict) else {}
    content = payload.get("content")
    if isinstance(content, list):
        texts = [item.get("text", "") for item in content if isinstance(item, dict) and item.get("type") == "text"]
        text = "\n".join(texts).strip()
    else:
        text = ""
    return True, truncate(text or "Success")


def recommend_role(
    model_name: str,
    basic_chat_ok: bool,
    structured_tool: bool,
    text_json: bool,
) -> str:
    lowered = model_name.lower()
    if structured_tool:
        return "Claude Code agent / coding"
    if not basic_chat_ok:
        return "Not recommended"
    if "coder" in lowered:
        return "Technical documentation check"
    if any(token in lowered for token in ("gemma", "llama")):
        return "User documentation only"
    if text_json:
        return "Plain chat only"
    return "Plain chat only"


def build_markdown(base_url: str, results: list[dict[str, Any]], missing_focus: list[str]) -> str:
    lines = [
        "# Ollama Model Compatibility Report",
        "",
        f"- Checked at base URL: `{base_url}`",
        f"- Models installed on server: `{len(results)}`",
        "",
        "## Summary Table",
        "",
        "| Model | Installed | Metadata tools capability | Basic chat via /v1/messages | Tools via /v1/messages | Tool call is structured | Tool call printed as text | Claude Code compatible | Recommended role | Notes |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for row in results:
        lines.append(
            "| {model} | Yes | {metadata_tools} | {basic} | {v1_tools} | {structured} | {text_json} | {compatible} | {role} | {notes} |".format(
                model=row["model"],
                metadata_tools=row["metadata_tools"],
                basic=row["basic_chat_status"],
                v1_tools=row["v1_tools_status"],
                structured="Yes" if row["structured_tool_call"] else "No",
                text_json="Yes" if row["tool_call_printed_as_text"] else "No",
                compatible="Yes" if row["claude_code_compatible"] else "No",
                role=row["recommended_role"],
                notes=row["notes_md"],
            )
        )

    lines.extend(
        [
            "",
            "## Model Notes",
            "",
        ]
    )
    for row in results:
        lines.extend(
            [
                f"### {row['model']}",
                "",
                f"- Size: `{row['size']}`",
                f"- Quantization: `{row['quantization']}`",
                f"- Context length: `{row['context_length'] or 'n/a'}`",
                f"- Metadata capabilities: `{row['capabilities'] or 'n/a'}`",
                f"- Native `/api/chat` tools result: `{row['native_tools_status']}`",
                f"- Notes: {row['notes_bullets']}",
                "",
            ]
        )

    lines.extend(["## Focus Models Not Installed", ""])
    if missing_focus:
        for model_name in missing_focus:
            lines.append(f"- `{model_name}`")
    else:
        lines.append("- All focus models were installed.")

    compatible = [row["model"] for row in results if row["claude_code_compatible"]]
    docs_models = [
        row["model"]
        for row in results
        if row["recommended_role"] == "User documentation only"
    ]
    tech_check_models = [
        row["model"]
        for row in results
        if row["recommended_role"] == "Technical documentation check"
    ]
    avoid = [row["model"] for row in results if not row["claude_code_compatible"]]

    lines.extend(
        [
            "",
            "## Recommendations",
            "",
            "Recommended Claude Code agent model: "
            + (f"`{compatible[0]}`" if compatible else "None found"),
            "Recommended user documentation model: "
            + (f"`{docs_models[0]}`" if docs_models else "None clearly suitable"),
            "Recommended final documentation check model: "
            + (f"`{tech_check_models[0]}`" if tech_check_models else "None clearly suitable"),
            "Models to avoid in Claude Code: "
            + (", ".join(f"`{name}`" for name in avoid) if avoid else "None"),
            "",
            "## Textual Tool Call Imitations",
            "",
        ]
    )
    textual = [row for row in results if row["tool_call_printed_as_text"]]
    if textual:
        for row in textual:
            lines.append(f"- `{row['model']}` returned tool-call JSON as plain text.")
    else:
        lines.append("- No models printed tool-call JSON as plain text.")

    return "\n".join(lines) + "\n"


def print_console_table(results: list[dict[str, Any]]) -> None:
    headers = [
        "Model",
        "Basic",
        "V1 Tools",
        "Structured",
        "Text JSON",
        "Native",
        "Claude Code",
        "Role",
    ]
    rows = [
        [
            row["model"],
            "yes" if row["basic_chat_ok"] else "no",
            row["v1_tools_status"],
            "yes" if row["structured_tool_call"] else "no",
            "yes" if row["tool_call_printed_as_text"] else "no",
            row["native_tools_status"],
            "yes" if row["claude_code_compatible"] else "no",
            row["recommended_role"],
        ]
        for row in results
    ]
    widths = [len(header) for header in headers]
    for row in rows:
        for index, value in enumerate(row):
            widths[index] = min(max(widths[index], len(str(value))), 40)

    def clip(value: str, width: int) -> str:
        return value if len(value) <= width else value[: width - 3] + "..."

    header_line = " | ".join(clip(headers[i], widths[i]).ljust(widths[i]) for i in range(len(headers)))
    separator = "-+-".join("-" * widths[i] for i in range(len(headers)))
    print(header_line)
    print(separator)
    for row in rows:
        print(
            " | ".join(
                clip(str(row[i]), widths[i]).ljust(widths[i]) for i in range(len(row))
            )
        )


def main() -> int:
    base_url, tags_result = probe_base_url()
    models = get_installed_models(tags_result)
    if not models:
        raise RuntimeError("No installed models found via /api/tags")

    results: list[dict[str, Any]] = []
    for model in models:
        model_name = model.get("name", "")
        show_result = http_json(base_url, "/api/show", {"model": model_name}, timeout=60)
        show_payload = show_result.payload if isinstance(show_result.payload, dict) else {}
        details = show_payload.get("details") or model.get("details") or {}
        capabilities = show_payload.get("capabilities") or []
        metadata_tools = "Yes" if "tools" in capabilities else "No"

        basic_result = http_json(
            base_url,
            "/v1/messages",
            {
                "model": model_name,
                "max_tokens": 256,
                "messages": [{"role": "user", "content": "Reply with exactly: OK"}],
            },
            timeout=90,
        )
        basic_chat_ok, basic_chat_status = classify_basic_chat(basic_result)

        v1_tools_result = http_json(
            base_url,
            "/v1/messages",
            {
                "model": model_name,
                "max_tokens": 512,
                "tools": [TEST_TOOL_V1],
                "messages": [{"role": "user", "content": TOOL_PROMPT}],
            },
            timeout=120,
        )
        v1_tools = classify_v1_tool_response(v1_tools_result)

        native_result = http_json(
            base_url,
            "/api/chat",
            {
                "model": model_name,
                "stream": False,
                "tools": [TEST_TOOL_NATIVE],
                "messages": [{"role": "user", "content": TOOL_PROMPT}],
            },
            timeout=120,
        )
        native_tools_status = classify_native_tool_response(native_result)

        structured_tool = v1_tools["structured"]
        text_json = v1_tools["text_json"]
        compatible = structured_tool
        role = recommend_role(model_name, basic_chat_ok, structured_tool, text_json)

        notes = []
        if show_result.ok:
            notes.append(f"metadata tools={metadata_tools.lower()}")
        else:
            notes.append(f"/api/show error: {truncate(show_result.error)}")
        if native_tools_status == "Structured tool call" and not compatible:
            notes.append("native /api/chat supports tools but /v1/messages does not")
        elif "Text JSON imitation" in native_tools_status:
            notes.append("native /api/chat also prints tool JSON as text")
        elif native_tools_status.startswith("Error:"):
            notes.append(f"native tools error: {native_tools_status[7:]}")
        if text_json:
            notes.append("tool call is only text, not API-structured")
        elif v1_tools_result.ok:
            if not structured_tool:
                notes.append("no structured tool_use in /v1/messages")
        elif not structured_tool:
            notes.append(f"/v1/messages tools error: {truncate(v1_tools_result.error)}")

        result_row = {
            "model": model_name,
            "size": format_size_bytes(model.get("size")),
            "quantization": details.get("quantization_level") or "",
            "context_length": extract_context_length(show_payload),
            "capabilities": ", ".join(capabilities) if capabilities else "",
            "metadata_tools": metadata_tools,
            "basic_chat_ok": basic_chat_ok,
            "basic_chat_status": basic_chat_status,
            "v1_tools_status": v1_tools["status"],
            "structured_tool_call": structured_tool,
            "tool_call_printed_as_text": text_json,
            "claude_code_compatible": compatible,
            "native_tools_status": native_tools_status,
            "recommended_role": role,
            "notes_md": "<br>".join(notes),
            "notes_bullets": "; ".join(notes),
        }
        results.append(result_row)

    os.makedirs("docs", exist_ok=True)
    report = build_markdown(
        base_url=base_url,
        results=results,
        missing_focus=[name for name in PREFERRED_MODELS if name not in {r["model"] for r in results}],
    )
    report_path = os.path.join("docs", "ollama-model-compatibility-report.md")
    with open(report_path, "w", encoding="utf-8") as handle:
        handle.write(report)

    print(f"Base URL: {base_url}")
    print(f"Report written to: {report_path}")
    print()
    print_console_table(results)
    print()
    print(textwrap.dedent(
        """
        Recommendation snapshot:
        - Claude Code compatible: structured tool_use returned via /v1/messages
        - Incompatible: tool call missing, returned as plain text JSON, or API errored
        """
    ).strip())
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
