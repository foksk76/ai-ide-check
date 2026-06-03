# Техническая рабочая среда: Remote Ollama + Claude Code for VS Code

## Назначение

Документ фиксирует подготовку рабочей AI-среды разработки для проекта.

Среда использует:

- удалённый сервер Ollama;
- Claude Code for VS Code;
- отдельные профили VS Code для написания кода, пользовательской документации и технической проверки документации;
- две локальные модели Ollama, подобранные для устойчивой работы на GeForce RTX 3080 10 GB.

## Целевая схема

```text
Рабочая станция VS Code
  └─ Claude Code for VS Code
       └─ Anthropic-compatible API
            └─ Remote Ollama
                 ├─ qwen2.5-coder:7b-instruct-q4_K_M
                 └─ gemma3:12b-it-q4_K_M
```

## Адрес Remote Ollama

```text
http://10.179.254.250:11434
```

## Выбранные модели

| Роль | Модель | Применение |
|---|---|---|
| Код и техническая документация разработки | `qwen2.5-coder:7b-instruct-q4_K_M` | Python, Airflow, SSH, AD collector, тесты, `AGENTS.md`, документация разработчика |
| Пользовательская документация | `gemma3:12b-it-q4_K_M` | `README.md`, `user-guide.md`, `admin-guide.md`, FAQ, troubleshooting |
| Финальная техническая проверка документации | `qwen2.5-coder:7b-instruct-q4_K_M` | Проверка команд, путей файлов, переменных окружения и ссылок на код |

## Подготовка Remote Ollama на Ubuntu

Установить или обновить Ollama стандартным способом.

Загрузить необходимые модели:

```bash
ollama pull qwen2.5-coder:7b-instruct-q4_K_M
ollama pull gemma3:12b-it-q4_K_M
ollama list
```

Открыть drop-in конфигурацию systemd:

```bash
sudo systemctl edit ollama.service
```

Добавить параметры сервиса:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:"
Environment="OLLAMA_CONTEXT_LENGTH=8192"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_KEEP_ALIVE=15m"
Environment="OLLAMA_MAX_QUEUE=16"
```

Применить изменения:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama.service
sudo systemctl status ollama.service
```

Проверить доступность Ollama с рабочей станции VS Code:

```bash
curl http://10.179.254.250:11434/api/tags
```

Проверить размещение модели и контекст на сервере Ollama:

```bash
ollama ps
```

Ожидаемое стабильное состояние:

```text
PROCESSOR    CONTEXT
100% GPU     8192
```

Если модель частично уходит в CPU/RAM, уменьшить значение:

```ini
Environment="OLLAMA_CONTEXT_LENGTH=4096"
```

## Требования к VS Code

На рабочей станции должны быть установлены:

- VS Code;
- Claude Code CLI;
- Claude Code for VS Code extension.

Создать три профиля VS Code:

```text
Claude Code - Qwen Code
Claude Code - Gemma Docs
Claude Code - Qwen Doc Check
```

После переключения профиля выполнить перезагрузку окна VS Code:

```text
Command Palette -> Developer: Reload Window
```

## Профиль VS Code: Claude Code - Qwen Code

Назначение профиля:

```text
код
тесты
рефакторинг
Airflow DAG
SSH transport
AD collector
AGENTS.md
README-dev.md
технические runbook-документы
```

Фрагмент `settings.json`:

```json
{
    "claudeCode.preferredLocation": "panel",
    "claudeCode.environmentVariables": [
        {
            "name": "ANTHROPIC_AUTH_TOKEN",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_API_KEY",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_BASE_URL",
            "value": "http://10.179.254.250:11434"
        },
        {
            "name": "ANTHROPIC_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_SONNET_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "CLAUDE_CODE_SUBAGENT_MODEL",
            "value": "qwen2.5-coder:7b-instruct-q4_K_M"
        },
        {
            "name": "API_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "BASH_DEFAULT_TIMEOUT_MS",
            "value": "300000"
        },
        {
            "name": "BASH_MAX_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "CLAUDE_CODE_MAX_OUTPUT_TOKENS",
            "value": "4096"
        }
    ]
}
```

## Профиль VS Code: Claude Code - Gemma Docs

Назначение профиля:

```text
README.md для пользователей
user-guide.md
admin-guide.md
install.md
troubleshooting.md
faq.md
простые пользовательские инструкции
описание сценариев работы
```

Фрагмент `settings.json`:

```json
{
    "claudeCode.preferredLocation": "panel",
    "claudeCode.environmentVariables": [
        {
            "name": "ANTHROPIC_AUTH_TOKEN",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_API_KEY",
            "value": "ollama"
        },
        {
            "name": "ANTHROPIC_BASE_URL",
            "value": "http://10.179.254.250:11434"
        },
        {
            "name": "ANTHROPIC_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_SONNET_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "CLAUDE_CODE_SUBAGENT_MODEL",
            "value": "gemma3:12b-it-q4_K_M"
        },
        {
            "name": "API_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "BASH_DEFAULT_TIMEOUT_MS",
            "value": "300000"
        },
        {
            "name": "BASH_MAX_TIMEOUT_MS",
            "value": "1200000"
        },
        {
            "name": "CLAUDE_CODE_MAX_OUTPUT_TOKENS",
            "value": "4096"
        }
    ]
}
```

Рекомендуемая дисциплина промта:

```text
Пиши только пользовательскую документацию.
Не меняй исходный код.
Не меняй команды, имена файлов, параметры конфигурации и переменные окружения.
Если техническая деталь неясна, пометь её как TODO для проверки Qwen.
```

## Профиль VS Code: Claude Code - Qwen Doc Check

Назначение профиля:

```text
финальная техническая проверка документации
сверка README/user-guide/admin-guide с кодом
проверка команд запуска
проверка переменных окружения
проверка путей файлов
проверка Airflow DAG / SSH / AD collector
```

Используется такая же модельная конфигурация, как в профиле `Claude Code - Qwen Code`.

Рекомендуемая дисциплина промта:

```text
Проверь документацию на соответствие фактическому репозиторию.
Не переписывай стиль.
Проверяй только техническую корректность:
- команды;
- переменные окружения;
- параметры конфигурации;
- пути файлов;
- имена модулей;
- имена Airflow DAG;
- поведение SSH transport;
- поведение AD collector;
- тесты.

Верни результат в формате:
файл -> проблема -> рекомендуемое исправление.
```

## Базовые меры безопасности

Не публиковать Ollama напрямую в недоверенные сети.

Доступ к порту `11434` должен быть ограничен firewall-ом или VPN.

Пример для UFW:

```bash
sudo ufw allow from <VS_CODE_CLIENT_IP> to any port 11434 proto tcp
sudo ufw deny 11434/tcp
sudo ufw status numbered
```

## Рекомендуемое размещение в проекте

```text
docs/stands/remote-ollama-vscode-work-environment.ru.md
```

## Рабочее правило

```text
Qwen Code profile:
  код, тесты, техническая документация разработки

Gemma Docs profile:
  пользовательская документация

Qwen Doc Check profile:
  финальная техническая проверка документации перед commit
```
