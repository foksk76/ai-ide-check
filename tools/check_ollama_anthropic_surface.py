#!/usr/bin/env python3
"""Probe Ollama's Anthropic Messages API surface and model behavior."""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


DEFAULT_BASE_URL = "http://localhost:11434"
DEFAULT_MODELS = [
    "gemma4:e4b",
    "llama3.2:latest",
    "qwen3:8b-q4_K_M",
]
TOOL = {
    "name": "get_probe_value",
    "description": "Return a fixed probe value for compatibility testing.",
    "input_schema": {
        "type": "object",
        "properties": {
            "key": {"type": "string"},
        },
        "required": ["key"],
    },
}


@dataclass
class HttpResult:
    ok: bool
    status: int | None
    payload: Any = None
    raw: str = ""
    error: str = ""


def http_json(
    base_url: str,
    path: str,
    payload: dict[str, Any] | None = None,
    *,
    stream: bool = False,
    timeout: int = 180,
) -> HttpResult:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        base_url.rstrip("/") + path,
        data=data,
        headers={
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
            "x-api-key": "ollama",
        },
        method="POST" if payload is not None else "GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", errors="replace")
            if stream:
                return HttpResult(True, response.status, raw=raw)
            parsed = json.loads(raw) if raw else None
            return HttpResult(True, response.status, parsed, raw)
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            payload_error = json.loads(raw)
        except json.JSONDecodeError:
            payload_error = raw
        return HttpResult(False, exc.code, payload_error, raw, str(exc))
    except Exception as exc:  # noqa: BLE001
        return HttpResult(False, None, error=str(exc))


def content_blocks(result: HttpResult) -> list[dict[str, Any]]:
    if not isinstance(result.payload, dict):
        return []
    content = result.payload.get("content")
    return content if isinstance(content, list) else []


def text_content(result: HttpResult) -> str:
    texts = [
        block.get("text", "")
        for block in content_blocks(result)
        if block.get("type") == "text"
    ]
    return "\n".join(texts)


def first_tool_use(result: HttpResult) -> dict[str, Any] | None:
    for block in content_blocks(result):
        if block.get("type") == "tool_use":
            return block
    return None


def probe_server(base_url: str, model: str) -> dict[str, Any]:
    count_tokens = http_json(
        base_url,
        "/v1/messages/count_tokens",
        {
            "model": model,
            "messages": [{"role": "user", "content": "Count these tokens."}],
        },
        timeout=30,
    )
    models = http_json(base_url, "/v1/models", timeout=30)
    batches = http_json(
        base_url,
        "/v1/messages/batches",
        {"requests": []},
        timeout=30,
    )
    metadata = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 32,
            "metadata": {"user_id": "surface-probe"},
            "messages": [{"role": "user", "content": "Reply with exactly METADATA_OK"}],
        },
    )
    prompt_cache = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 32,
            "system": [
                {
                    "type": "text",
                    "text": "Reply with exactly CACHE_OK.",
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            "messages": [{"role": "user", "content": "Follow the system prompt."}],
        },
    )
    tool_choice = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 128,
            "tools": [TOOL],
            "tool_choice": {"type": "none"},
            "messages": [
                {
                    "role": "user",
                    "content": "Use get_probe_value with key alpha. Do not answer from memory.",
                }
            ],
        },
    )
    return {
        "count_tokens": asdict(count_tokens),
        "models_endpoint": asdict(models),
        "batches": asdict(batches),
        "metadata_request": asdict(metadata),
        "prompt_cache_request": asdict(prompt_cache),
        "tool_choice_none_request": asdict(tool_choice),
        "tool_choice_none_respected": first_tool_use(tool_choice) is None,
    }


def probe_model(base_url: str, model: str) -> dict[str, Any]:
    basic = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 128,
            "messages": [{"role": "user", "content": "Reply with exactly BASIC_OK"}],
        },
    )
    system = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 128,
            "system": "Reply with exactly SYSTEM_OK.",
            "messages": [{"role": "user", "content": "Follow the system prompt."}],
        },
    )
    multi_turn = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 128,
            "messages": [
                {"role": "user", "content": "Remember this code: ORANGE-731."},
                {"role": "assistant", "content": "I will remember ORANGE-731."},
                {"role": "user", "content": "Reply with only the code."},
            ],
        },
    )
    stream = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 128,
            "stream": True,
            "messages": [{"role": "user", "content": "Reply with exactly STREAM_OK"}],
        },
        stream=True,
    )
    tool_first = http_json(
        base_url,
        "/v1/messages",
        {
            "model": model,
            "max_tokens": 256,
            "tools": [TOOL],
            "messages": [
                {
                    "role": "user",
                    "content": "Use get_probe_value with key alpha. Do not answer from memory.",
                }
            ],
        },
    )
    tool_block = first_tool_use(tool_first)
    tool_result: HttpResult | None = None
    if tool_block:
        tool_result = http_json(
            base_url,
            "/v1/messages",
            {
                "model": model,
                "max_tokens": 256,
                "tools": [TOOL],
                "messages": [
                    {
                        "role": "user",
                        "content": "Use get_probe_value with key alpha. Do not answer from memory.",
                    },
                    {"role": "assistant", "content": tool_first.payload["content"]},
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "tool_result",
                                "tool_use_id": tool_block["id"],
                                "content": "TOOL_RESULT_OK",
                            }
                        ],
                    },
                ],
            },
        )

    stream_raw = stream.raw
    tool_result_text = text_content(tool_result) if tool_result else ""
    tool_result_accepted = bool(tool_result and tool_result.ok and tool_result_text)
    tool_result_grounded = "TOOL_RESULT_OK" in tool_result_text
    checks = {
        "basic_text": basic.ok and "BASIC_OK" in text_content(basic),
        "system_prompt": system.ok and "SYSTEM_OK" in text_content(system),
        "multi_turn": multi_turn.ok and "ORANGE-731" in text_content(multi_turn),
        "streaming": stream.ok
        and "event: message_start" in stream_raw
        and "event: message_stop" in stream_raw,
        "structured_tool_use": tool_block is not None,
        "tool_result_accepted": tool_result_accepted,
        "tool_result_grounded": tool_result_grounded,
    }
    return {
        "model": model,
        "checks": checks,
        "practical_messages_subset": all(
            checks[key]
            for key in (
                "basic_text",
                "system_prompt",
                "multi_turn",
                "streaming",
                "structured_tool_use",
                "tool_result_accepted",
            )
        ),
        "responses": {
            "basic": asdict(basic),
            "system": asdict(system),
            "multi_turn": asdict(multi_turn),
            "stream": asdict(stream),
            "tool_first": asdict(tool_first),
            "tool_result": asdict(tool_result) if tool_result else None,
        },
    }


def count_passes(item: dict[str, Any], key: str) -> str:
    passed = sum(1 for attempt in item["attempts"] if attempt["checks"][key])
    return f"{passed}/{len(item['attempts'])}"


def markdown_report(report: dict[str, Any]) -> str:
    server = report["server"]
    lines = [
        "# Ollama Anthropic Messages Surface Report",
        "",
        f"- Base URL: `{report['base_url']}`",
        f"- Models probed: `{len(report['models'])}`",
        f"- Attempts per model: `{report['attempts_per_model']}`",
        "",
        "## Server Surface",
        "",
        "| Probe | HTTP status | Result |",
        "|---|---:|---|",
        f"| `/v1/messages/count_tokens` | `{server['count_tokens']['status']}` | {'Available' if server['count_tokens']['ok'] else 'Not available'} |",
        f"| `/v1/models` | `{server['models_endpoint']['status']}` | {'Available' if server['models_endpoint']['ok'] else 'Not available'} |",
        f"| `/v1/messages/batches` | `{server['batches']['status']}` | {'Available' if server['batches']['ok'] else 'Not available'} |",
        f"| `metadata` request field | `{server['metadata_request']['status']}` | {'Accepted; support semantics not observable' if server['metadata_request']['ok'] else 'Rejected'} |",
        f"| `cache_control` request block | `{server['prompt_cache_request']['status']}` | {'Accepted; caching semantics not observable' if server['prompt_cache_request']['ok'] else 'Rejected'} |",
        f"| `tool_choice: none` request | `{server['tool_choice_none_request']['status']}` | {'Respected' if server['tool_choice_none_respected'] else 'Ignored: model still emitted tool_use'} |",
        "",
        "## Model Behavior",
        "",
        "| Model | Basic | System | Multi-turn | Streaming | Structured tool use | Tool result accepted | Tool result grounded | Practical subset |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for item in report["models"]:
        values = [
            item["model"],
            count_passes(item, "basic_text"),
            count_passes(item, "system_prompt"),
            count_passes(item, "multi_turn"),
            count_passes(item, "streaming"),
            count_passes(item, "structured_tool_use"),
            count_passes(item, "tool_result_accepted"),
            count_passes(item, "tool_result_grounded"),
            f"{sum(1 for attempt in item['attempts'] if attempt['practical_messages_subset'])}/{len(item['attempts'])}",
        ]
        lines.append("| " + " | ".join(f"`{value}`" for value in values) + " |")
    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "- Server-surface probes are endpoint-level facts and do not vary by model.",
            "- Model cells report successful attempts over total attempts.",
            "- Model checks measure practical behavior through Ollama's supported `/v1/messages` subset.",
            "- `Tool result accepted` means the second request completed with a text answer.",
            "- `Tool result grounded` means the answer preserved the injected `TOOL_RESULT_OK` marker.",
            "- A practical subset pass is not proof of full Anthropic API parity.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=os.environ.get("OLLAMA_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument("--models", nargs="+", default=DEFAULT_MODELS)
    parser.add_argument("--attempts", type=int, default=3)
    parser.add_argument(
        "--json-output",
        default="docs/ollama-anthropic-surface-report.json",
    )
    parser.add_argument(
        "--markdown-output",
        default="docs/ollama-anthropic-surface-report.md",
    )
    args = parser.parse_args()

    report = {
        "base_url": args.base_url,
        "server": probe_server(args.base_url, args.models[0]),
        "attempts_per_model": args.attempts,
        "models": [
            {
                "model": model,
                "attempts": [probe_model(args.base_url, model) for _ in range(args.attempts)],
            }
            for model in args.models
        ],
    }
    Path(args.json_output).write_text(
        json.dumps(report, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )
    Path(args.markdown_output).write_text(markdown_report(report), encoding="utf-8")
    print(markdown_report(report))
    print(f"JSON report: {args.json_output}")
    print(f"Markdown report: {args.markdown_output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
