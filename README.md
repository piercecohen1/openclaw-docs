# OpenClaw Docs Mirror

Local mirror of the OpenClaw documentation from [docs.openclaw.ai](https://docs.openclaw.ai), downloaded as raw markdown via `llms.txt` index.

## Scrape Info

| | |
|---|---|
| **Last scraped** | March 18, 2026 |
| **Total pages** | 335 |
| **Source** | [llms.txt](https://docs.openclaw.ai/llms.txt) |

## Sections

| Directory | Pages |
|-----------|-------|
| `(top-level)` | 10 |
| `cli/` | 46 |
| `providers/` | 36 |
| `gateway/` | 34 |
| `tools/` | 29 |
| `channels/` | 29 |
| `concepts/` | 28 |
| `platforms/` | 26 |
| `reference/` | 21 |
| `install/` | 21 |
| `start/` | 13 |
| `nodes/` | 9 |
| `plugins/` | 8 |
| `automation/` | 8 |
| `help/` | 7 |
| `web/` | 5 |
| `security/` | 3 |
| `diagnostics/` | 1 |
| `debug/` | 1 |

## Directory Structure

```
docs
├── automation
├── channels
├── cli
├── concepts
├── debug
├── diagnostics
├── gateway
│   └── security
├── help
├── install
├── nodes
├── platforms
│   └── mac
├── plugins
├── providers
├── reference
│   └── templates
├── security
├── start
├── tools
└── web
```

## Usage

Search with ripgrep:

```bash
rg "query" docs/
rg "query" docs/llms-full.txt   # Full-text search
```

## Updating

```bash
bash download.sh --force   # Re-fetch URL list from llms.txt
```

## How It Works

The OpenClaw docs site publishes an `llms.txt` index with direct `.md` URLs for every page. The download script fetches the index, extracts all URLs, and downloads them with 10 parallel connections. Directory structure is preserved from the URL paths.
