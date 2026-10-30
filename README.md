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

## Server plugin

Game logic lives in a Go plugin (`server/`) that Nakama loads from `server/build/backend.so`.

```sh
make build-server   # build server/build/backend.so with heroiclabs/nakama-pluginbuilder:3.41.0
make up             # or restart nakama if it's already running: docker compose -f deploy/docker-compose.yml restart nakama
make test           # go test ./... in server/, runs on the host
```

After a restart the logs should show `module loaded` and `Registered Go runtime RPC function invocation` with `"id":"hello"`. To try the RPC, open the console's **API Explorer**, choose `hello`, enter a user ID and send it. The reply is `{"message":"Hello, <user id>"}`.

### Versions must match exactly

The plugin has to be built with the same Go toolchain and the same dependency versions as the Nakama binary that loads it. That means:

- The `heroiclabs/nakama-pluginbuilder` tag in the `Makefile` (`NAKAMA_VERSION`) must equal the `heroiclabs/nakama` tag in `deploy/docker-compose.yml`.
- `github.com/heroiclabs/nakama-common` in `server/go.mod` must be the version that Nakama release uses. Nakama 3.41.0 uses **nakama-common v1.48.0**; check Nakama's `go.mod` for that release tag when upgrading.

If they don't match, you'll see one of these:

- **Build fails** with `go: go.mod requires go >= 1.27.1 (running go 1.26.5; GOTOOLCHAIN=local)`. The builder image is older than the dependencies in `go.mod`.
- **Nakama crashes on startup** with `fatal error: runtime: no plugin module data`, followed by a stack trace through `plugin.Open` and `server.openGoModule`. The plugin was built with a different Go toolchain from the server (seen with a plugin from the 3.40.0 builder loaded into Nakama 3.41.0). Rebuild with `make build-server`.

### Go notes

`server/go.mod` needs Go 1.27.1, because nakama-common v1.48.0 requires it. With a Go 1.26 host, `make test` downloads Go 1.27.1 on first run (`GOTOOLCHAIN=auto`, the default). The plugin build itself always runs in the builder image, so the host Go version doesn't affect it.

## Client

The Godot project is in `client/`. It uses the Mobile renderer, since mobile is the eventual target, but runs on desktop for now. It uses the official Nakama Godot addon **v3.4.0** (`nakama-3.4.0.zip` from the [nakama-godot releases](https://github.com/heroiclabs/nakama-godot/releases)), installed in `client/addons/com.heroiclabs.nakama/`. The addon has no editor plugin to enable; its `Nakama.gd` is registered as the `Nakama` autoload in `project.godot`, as the addon's README instructs.

Run it with the server up:

```sh
godot --path client          # or open client/project.godot in the editor and press Play
```

The window shows "Connecting…" and then `Hello, <user id>`, or an error if the server can't be reached. The `Net` autoload (`client/autoload/net.gd`) handles the whole flow:

1. Reads its connection settings from one `CONFIG` dictionary.
2. Creates a device ID on first launch and stores it in `user://device_id`. On macOS that's `~/Library/Application Support/Godot/app_userdata/Wascally Wobots/`.
3. Authenticates anonymously with that ID.
4. Opens the socket.
5. Calls `hello`.

The device's user appears under **Accounts** in the console.

Static type hints are required: `debug/gdscript/warnings/untyped_declaration` is set to warn. The addon is excluded from these warnings.
