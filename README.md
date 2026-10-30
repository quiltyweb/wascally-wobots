# Wascally Wobots

A game of robots moving and mashing.

## Project skeleton

The current goal is the simplest working skeleton of the stack: a Godot (GDScript) client and a Nakama (Go) server, both running locally. The skeleton is done when the client on your desktop connects to the local server, authenticates, calls a `hello` RPC and shows the server's reply on screen. See [features/01-project-skeleton.md](features/01-project-skeleton.md) for the full handover.

```
Godot client  ──HTTP / WebSocket──▶  Nakama (+ Go plugin)  ──▶  PostgreSQL
```

## Repository layout

```
wascally-wobots/
├── Makefile        # build-server, up, down, logs, test
├── deploy/         # docker compose + nakama config (local only)
├── server/         # Go plugin for Nakama
└── client/         # Godot project root
```

## Tooling

| Tool           | Version                     | Notes                                                       |
| -------------- | --------------------------- | ----------------------------------------------------------- |
| Docker         | Engine 29.5.2, Compose 5.6.1 | Any Docker runtime works; on macOS colima is used here.     |
| Go             | 1.26.4                      | Host toolchain, only for `make test`; see Go notes below.   |
| Godot          | 4.7.2 stable (standard)     | Not the .NET build.                                         |

On macOS with Homebrew:

```sh
brew install colima docker docker-compose go
brew install --cask godot
colima start
docker compose version
```

If `docker compose` reports an unknown command, Docker can't find the Compose plugin. Add this to `~/.docker/config.json`:

```json
{ "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"] }
```

## Running the server locally

The server is pinned to **Nakama 3.41.0** (`heroiclabs/nakama:3.41.0`) with PostgreSQL 16. Local development only; hosting is undecided.

```sh
make up      # start postgres + nakama in the background (creates deploy/.env on first run)
make logs    # follow the nakama logs; look for "Startup done"
make down    # stop everything (the database volume is kept)
```

Use `make up COMPOSE=docker-compose` if you have the standalone Compose binary rather than the plugin.

| What           | Where                                                          |
| -------------- | -------------------------------------------------------------- |
| Client API     | `http://localhost:7350` (HTTP and WebSocket)                   |
| Console        | `http://localhost:7351`, user `admin`, password `wobots-local-console` |
| Server key     | `local-server-key`                                             |
| Postgres pass  | `deploy/.env` (copied from `deploy/.env.example`)              |

Nakama runs `nakama migrate up` on every start before launching. The "insecure default parameter value" warnings in the logs are expected for local development.
