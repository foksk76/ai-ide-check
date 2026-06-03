# ai-ide-check

Проект для проверки локальных моделей в связке с Claude Code и Ollama.

Главная цель сейчас: выбрать практичную локальную модель для задач с кодом и
подготовить отдельный безопасный трек для обучения реверс-инжинирингу с
помощью ИИ.

## Текущий контур

| Часть | Роль |
|---|---|
| Windows 11 + Radeon RX 6800 | Основной стенд локального LLM-инференса: Ollama, Claude Code CLI, Claude Code for VS Code. |
| Proxmox VE 9.2 без GPU | Изолированная лаборатория для статического анализа, VM/LXC, воспроизведения гипотез и артефактов. |
| Cloud LLM | Ручная эскалация сложных случаев, когда локальной модели не хватает. |

Рабочее правило простое: Windows думает, Proxmox проверяет.

## Где начинать

| Нужно | Файл |
|---|---|
| Понять структуру документации | [docs/README.md](docs/README.md) |
| Узнать текущий план | [docs/plans/current-roadmap.md](docs/plans/current-roadmap.md) |
| Посмотреть отложенные модели | [docs/plans/model-retry-backlog.md](docs/plans/model-retry-backlog.md) |
| Проверить контракт стенда | [docs/contracts/vscode-ollama-agent-contract.md](docs/contracts/vscode-ollama-agent-contract.md) |
| Разобраться с reverse-engineering треком | [docs/specs/reverse-engineering-model-evaluation-idea.md](docs/specs/reverse-engineering-model-evaluation-idea.md) |
| Посмотреть роли Windows/Proxmox | [docs/specs/reverse-engineering-model-system-roles.md](docs/specs/reverse-engineering-model-system-roles.md) |

## Автоматические проверки

Основные скрипты лежат в [tools/](tools/README.md).

Windows headless-проверка Claude Code + Ollama:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_claude_ollama_headless.ps1 `
  -StandId win11-local-rx6800 `
  -Models gpt-oss:20b-ctx32k `
  -Stages handshake,tool,agent `
  -RequireFullGpu
```

Coder fixture benchmark:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run_coder_fixture_bench.ps1 `
  -StandId win11-local-rx6800 `
  -Models gpt-oss:20b-ctx32k,ministral-3:8b-ctx32k,gemma4:e4b-ctx128k `
  -RequireFullGpu
```

Результаты автоматических прогонов пишутся в `.artifacts/`. Этот каталог
намеренно не хранится в Git.

## Модели

Текущий основной кандидат:

```text
gpt-oss:20b-ctx32k
```

Ограниченный сравнительный кандидат:

```text
ministral-3:8b-ctx32k
```

Профили Ollama находятся в [tools/modelfiles/](tools/modelfiles/README.md).
Модели, которые не прошли текущий стенд, но могут быть полезны на другой
конфигурации, записаны в [model-retry-backlog.md](docs/plans/model-retry-backlog.md).

## Отчеты и статьи

Отчеты для человека, статьи и графики — это отдельная ручная публикационная
функция, а не часть обязательного автоматического прогона.

Они живут в [docs/reports/](docs/reports/README.md). Скрипты для подготовки
публикационных материалов:

| Скрипт | Назначение |
|---|---|
| `tools/generate_readme_charts.ps1` | Собрать PNG-графики для статьи или отчета. |
| `tools/export_readme_report.py` | Экспортировать подготовленный Markdown-отчет в PDF. |

Идея такая: сначала собираем проверяемые артефакты и runbook-записи, потом
человек вручную решает, что достойно стать отчетом. Автоматика меряет, человек
рассказывает.

## Данные и артефакты

| Место | Что хранится |
|---|---|
| `.artifacts/` | Сырые локальные прогоны, транскрипты, временные worktree. Не в Git. |
| `docs/runbooks/runs/` | Краткие датированные записи проверок. |
| `docs/reports/` | Человеческие отчеты, PDF, компактные сводки. |
| `docs/archive/` | Исторические документы, которые больше не являются текущим планом. |

## Следующий шаг

Смотреть [current-roadmap.md](docs/plans/current-roadmap.md). На текущий момент
следующий рабочий шаг — reliability pass для `gpt-oss:20b-ctx32k`,
`ministral-3:8b-ctx32k` и `gemma4:e4b-ctx128k`, плюс подготовка первого
статического reverse-engineering fixture без доступа к динамическому стенду.
