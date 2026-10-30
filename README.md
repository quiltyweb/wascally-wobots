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
