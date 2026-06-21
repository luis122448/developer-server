# Open WebUI

ChatGPT-like interface for LLMs. Configured here for **external OpenAI-compatible APIs**
(DeepSeek by default) — no local model runtime (Ollama) for now.

## Port

| Port | Purpose |
| ---- | ------- |
| 8088 | Web UI  |

Access: `http://<server-IP>:8088`

## Setup

1. Create the `.env` from the template and set your DeepSeek API key:

   ```bash
   cp .env.example .env
   # edit .env -> OPENAI_API_KEY=sk-your-deepseek-key
   ```

2. Start it:

   ```bash
   docker compose up -d
   ```

3. Open `http://<server-IP>:8088`, create the first account (it becomes admin).

> All container config lives in `.env` (loaded via `env_file`). `.env` is gitignored;
> `.env.example` is the committed template with dummy values.

## Two profile templates

Pick the one that fits how you want to run it (or mix both — Open WebUI can use Ollama
**and** an external API at the same time):

| Template              | Use when                                                    |
| --------------------- | ----------------------------------------------------------- |
| `.env.example`        | External API only (DeepSeek). No local model.               |
| `.env.local.example`  | Local model via **Ollama on dev-005** (192.168.100.165). Can also keep DeepSeek. |

```bash
# external API only
cp .env.example .env

# local Ollama (dev-005) — optionally also DeepSeek
cp .env.local.example .env
```

After changing `.env`, recreate the container:

```bash
docker compose up -d --force-recreate
```

## Connecting to Ollama on dev-005

Ollama on dev-005 listens on `*:11434` (verified). Setting
`OLLAMA_BASE_URL=http://192.168.100.165:11434` makes Open WebUI list every model
present there in the model picker (`ollama list` on dev-005).

To add/remove models, run on dev-005:

```bash
ollama pull <name>
ollama list
ollama rm <name>
```

## Using DeepSeek

The compose points the OpenAI connection at `https://api.deepseek.com` (OpenAI-compatible).
Once the key is set, the DeepSeek models appear in the model picker:

- `deepseek-chat` — general chat (V3)
- `deepseek-reasoner` — reasoning model (R1)

You can also add/edit connections in the UI: **Settings → Admin → Connections**.

## Notes

- **Local models later**: to run local models, deploy Ollama and set
  `ENABLE_OLLAMA_API=true` + `OLLAMA_BASE_URL`. Not enabled now.
- Data (accounts, chats, settings) persists in the `open-webui-data` volume.
- The API key is a secret — keep it in `.env` (gitignored), never in the compose.
