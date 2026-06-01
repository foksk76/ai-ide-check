#!/usr/bin/env python3
"""Export the repository README to a self-contained PDF report."""

from __future__ import annotations

import argparse
import base64
import html
import mimetypes
import re
import shutil
import subprocess
from pathlib import Path


def inline_markup(text: str) -> str:
    escaped = html.escape(text)
    code_parts: list[str] = []

    def preserve_code(match: re.Match[str]) -> str:
        code_parts.append(f"<code>{match.group(1)}</code>")
        return f"@@CODE{len(code_parts) - 1}@@"

    escaped = re.sub(r"`([^`]+)`", preserve_code, escaped)
    escaped = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    for index, part in enumerate(code_parts):
        escaped = escaped.replace(f"@@CODE{index}@@", part)
    return escaped


def embed_image(repository: Path, alt: str, target: str) -> str:
    image_path = (repository / target).resolve()
    if not image_path.is_file():
        raise FileNotFoundError(f"README image not found: {target}")
    mime_type = mimetypes.guess_type(image_path.name)[0] or "image/png"
    payload = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return (
        '<figure><img src="data:'
        f'{mime_type};base64,{payload}" alt="{html.escape(alt)}">'
        f"<figcaption>{html.escape(alt)}</figcaption></figure>"
    )


def split_table_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def markdown_to_html(repository: Path, source: str) -> str:
    lines = source.splitlines()
    blocks: list[str] = []
    paragraph: list[str] = []
    list_kind: str | None = None
    list_items: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            blocks.append(f"<p>{inline_markup(' '.join(paragraph))}</p>")
            paragraph.clear()

    def flush_list() -> None:
        nonlocal list_kind
        if list_items and list_kind:
            items = "".join(f"<li>{inline_markup(item)}</li>" for item in list_items)
            blocks.append(f"<{list_kind}>{items}</{list_kind}>")
            list_items.clear()
            list_kind = None

    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if stripped.startswith("```"):
            flush_paragraph()
            flush_list()
            language = stripped[3:].strip()
            code_lines: list[str] = []
            index += 1
            while index < len(lines) and not lines[index].strip().startswith("```"):
                code_lines.append(lines[index])
                index += 1
            blocks.append(
                f'<pre><code class="language-{html.escape(language)}">'
                f"{html.escape(chr(10).join(code_lines))}</code></pre>"
            )
        elif not stripped:
            flush_paragraph()
            flush_list()
        elif re.match(r"^#{1,6} ", stripped):
            flush_paragraph()
            flush_list()
            level = len(stripped) - len(stripped.lstrip("#"))
            blocks.append(f"<h{level}>{inline_markup(stripped[level + 1:])}</h{level}>")
        elif match := re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", stripped):
            flush_paragraph()
            flush_list()
            blocks.append(embed_image(repository, match.group(1), match.group(2)))
        elif (
            "|" in stripped
            and index + 1 < len(lines)
            and re.match(r"^\s*\|?[\s:|-]+\|[\s:|-]+\|?\s*$", lines[index + 1])
        ):
            flush_paragraph()
            flush_list()
            headers = split_table_row(stripped)
            index += 2
            rows: list[list[str]] = []
            while index < len(lines) and "|" in lines[index] and lines[index].strip():
                rows.append(split_table_row(lines[index]))
                index += 1
            index -= 1
            head = "".join(f"<th>{inline_markup(cell)}</th>" for cell in headers)
            body = "".join(
                "<tr>" + "".join(f"<td>{inline_markup(cell)}</td>" for cell in row) + "</tr>"
                for row in rows
            )
            blocks.append(f"<table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>")
        elif match := re.match(r"^[-*] (.+)$", stripped):
            flush_paragraph()
            if list_kind not in (None, "ul"):
                flush_list()
            list_kind = "ul"
            list_items.append(match.group(1))
        elif match := re.match(r"^\d+\. (.+)$", stripped):
            flush_paragraph()
            if list_kind not in (None, "ol"):
                flush_list()
            list_kind = "ol"
            list_items.append(match.group(1))
        else:
            flush_list()
            paragraph.append(stripped)
        index += 1

    flush_paragraph()
    flush_list()
    return "\n".join(blocks)


def find_browser() -> Path:
    candidates = [
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    ]
    for executable in candidates:
        if executable.is_file():
            return executable
    for command in ("msedge", "chrome"):
        found = shutil.which(command)
        if found:
            return Path(found)
    raise FileNotFoundError("Microsoft Edge or Google Chrome is required to export PDF.")


def build_document(body: str, report_date: str, version: str) -> str:
    return f"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<title>Локальные модели для Claude Code</title>
<style>
@page {{ size: A4; margin: 16mm 14mm 18mm; }}
body {{ color: #1e293b; font: 10.5pt Arial, sans-serif; line-height: 1.45; }}
h1 {{ color: #0f172a; font-size: 23pt; margin: 0 0 6mm; }}
h2 {{ color: #0f172a; font-size: 16pt; margin: 8mm 0 3mm; page-break-after: avoid; }}
h3 {{ color: #0f172a; font-size: 12pt; margin: 5mm 0 2mm; page-break-after: avoid; }}
p, li {{ margin: 0 0 2mm; }}
a {{ color: #0369a1; text-decoration: none; }}
code {{ background: #f1f5f9; font: 9pt Consolas, monospace; padding: 0.4mm 0.8mm; }}
pre {{ background: #0f172a; color: #e2e8f0; padding: 3mm; border-radius: 2mm;
       white-space: pre-wrap; page-break-inside: avoid; }}
pre code {{ background: transparent; color: inherit; padding: 0; }}
table {{ border-collapse: collapse; font-size: 8.5pt; margin: 3mm 0 5mm; width: 100%; }}
th, td {{ border: 0.25mm solid #cbd5e1; padding: 1.4mm; vertical-align: top; }}
th {{ background: #e2e8f0; text-align: left; }}
figure {{ margin: 4mm 0 6mm; page-break-inside: avoid; }}
figure img {{ display: block; max-width: 100%; max-height: 150mm; margin: auto; }}
figcaption {{ color: #64748b; font-size: 8pt; margin-top: 1mm; text-align: center; }}
.report-meta {{ color: #475569; font-size: 9pt; margin-bottom: 7mm; }}
</style>
</head>
<body>
<div class="report-meta">Отчёт от {html.escape(report_date)} · версия {html.escape(version)}</div>
{body}
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--date", required=True, help="Report date in YYYY-MM-DD format.")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument(
        "--output",
        default="docs/reports/{date}-local-model-evaluation-report.pdf",
        help="PDF output path relative to the repository root.",
    )
    args = parser.parse_args()

    repository = Path(__file__).resolve().parents[1]
    readme = repository / "README.md"
    output = repository / args.output.format(date=args.date)
    output.parent.mkdir(parents=True, exist_ok=True)
    work_directory = repository / ".artifacts" / "report-export"
    work_directory.mkdir(parents=True, exist_ok=True)
    html_path = work_directory / f"{args.date}-local-model-evaluation-report.html"

    body = markdown_to_html(repository, readme.read_text(encoding="utf-8"))
    html_path.write_text(build_document(body, args.date, args.version), encoding="utf-8")
    browser = find_browser()
    subprocess.run(
        [
            str(browser),
            "--headless=new",
            "--disable-gpu",
            "--no-pdf-header-footer",
            f"--print-to-pdf={output}",
            html_path.as_uri(),
        ],
        check=True,
    )
    if not output.is_file() or output.stat().st_size < 1000:
        raise RuntimeError(f"PDF export did not produce a valid file: {output}")
    print(output)


if __name__ == "__main__":
    main()
