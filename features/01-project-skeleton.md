# Project Skeleton Handover

Oct 23, 2026 · @Craig

This doc hands over everything needed to build the simplest working skeleton: a Godot (GDScript) client and a Nakama (Go) server, both running locally. The skeleton is done when the client on your desktop connects to the local server, authenticates, calls a `hello` RPC and shows the server's reply on screen.

## Purpose and scope

The game will be real-time multiplayer with the server enforcing all rules. That is why the stack is built around an authoritative game server. None of the gameplay is in this skeleton; its only job is to prove that every layer of the stack runs and talks to the next one.

**Out of scope for the skeleton**

- All game mechanics, rules and player interactions (planned for later features).
- Matches and matchmaking (planned for later; see design decisions below).
- Deployment, hosting and mobile device builds (decisions deferred).
- Art, sound, accounts beyond anonymous device login.

## Tech stack and key decisions

| Layer             | Choice                                              | Notes                                                                                                        |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Client engine     | Godot 4 (latest stable), GDScript                   | Use static type hints everywhere; enable untyped-declaration warnings.                                       |
| Client networking | Official Nakama Godot client (`nakama-godot` addon) | Installed under `addons/`, used via the `Nakama` autoload.                                                   |
| Game server       | Nakama (pin one stable version)                     | Chosen because it supports authoritative real-time matches, which later gameplay features will need.         |
| Server language   | Go, built as a Nakama plugin (`.so`)                | Must be built with the `heroiclabs/nakama-pluginbuilder` image whose tag matches the Nakama version exactly. |
| Database          | PostgreSQL                                          | Required by Nakama for accounts and storage.                                                                 |
| Local environment | Docker Compose (Nakama + Postgres)                  | For local development only; hosting is undecided.                                                            |

```
Godot client  ──HTTP / WebSocket──▶  Nakama (+ Go plugin)  ──▶  PostgreSQL
```

**Design decisions to follow**

1. **The server owns every rule.** The client only sends inputs and draws what the server tells it. In the skeleton this just means logic lives in the Go plugin, not in GDScript. Gameplay will later run as authoritative Nakama matches (`runtime.Match`); not built yet.
2. **Keep game logic free of Nakama.** When gameplay is added, the rules go in a Go package with no Nakama imports so they can be unit tested on their own. The skeleton only needs `make test` wired up.
3. **Anonymous device login.** `authenticate_device_async` with a stored device ID; no sign-up flow.
4. **Every tunable is a constant in one file.** Create `server/config/constants.go` now so later features have one place to add them.

## Repository layout

One repository (monorepo) holds client and server, so changes to the client/server contract land in one commit on both sides.

```
wascally-wobots/
├── Makefile                  # build-server, up, down, logs, test
├── deploy/
│   ├── docker-compose.yml    # nakama + postgres (local)
│   └── nakama/local.yml      # nakama config
├── server/
│   ├── go.mod
│   ├── main.go               # InitModule: registers the hello RPC
│   ├── config/constants.go   # empty for now
│   └── rpc/hello.go          # hello RPC
└── client/                   # Godot project root
    ├── project.godot
    ├── addons/com.heroiclabs.nakama/
    ├── autoload/net.gd       # connection, session, socket
    └── scenes/main.tscn      # shows the hello reply
```

## Checklist

Work top to bottom; each phase ends with something you can run.

### Phase 0 — Repository and tooling

- [ ] Update the README with the goal of the skeleton.
- [ ] Add a `.gitignore` covering Go build output, `*.so`, Godot's `.godot/` folder and `.env`.
- [ ] Create the empty folders from the repository layout.
- [ ] Install Docker and Docker Compose; confirm `docker compose version` runs.
- [ ] Install Go; record the version in the README.
- [ ] Install the latest stable Godot 4 (standard build, not .NET); record the version.

### Phase 1 — Nakama running locally

- [ ] Choose one stable Nakama version and write it in the README.
- [ ] Write `deploy/docker-compose.yml` with a `postgres` service (named volume, password from `.env`).
- [ ] Add a `nakama` service pinned to the chosen version tag.
- [ ] Give the `nakama` service an entrypoint that runs `nakama migrate up` before starting the server.
- [ ] Expose ports 7350 (client API and socket) and 7351 (console).
- [ ] Mount `./server/build` into the container at `/nakama/data/modules`.
- [ ] Write `deploy/nakama/local.yml` with server key, console username/password and log level `DEBUG`.
- [ ] Add a health check so Nakama waits for Postgres.
- [ ] Run `docker compose up`; confirm the logs show the server started.
- [ ] Log in to the console at `http://localhost:7351`.
- [ ] Add `make up`, `make down` and `make logs` targets.

### Phase 2 — Go plugin and hello RPC

- [ ] Run `go mod init` in `server/`.
- [ ] Add `github.com/heroiclabs/nakama-common` at the version that matches your Nakama release (check Nakama's release notes).
- [ ] Write `main.go` with an `InitModule` function that logs "module loaded".
- [ ] Write a `make build-server` target that builds with the `heroiclabs/nakama-pluginbuilder` image (same tag as Nakama) using `go build -buildmode=plugin -trimpath -o build/backend.so`.
- [ ] Run `make build-server`; confirm `server/build/backend.so` exists.
- [ ] Restart Nakama; confirm "module loaded" appears in the logs.
- [ ] Deliberately mismatch a version once and note the error message in the README, so the next person recognises it.
- [ ] `rpc/hello.go`: an RPC that returns `{"message":"Hello, <user id>"}` using the caller's user ID from the context.
- [ ] Register it as `hello` in `InitModule`.
- [ ] Rebuild and restart; call `hello` from the console's API explorer and confirm the reply.
- [ ] Add `make test` running `go test ./...` in `server/` (runs on the host, no plugin build needed).

### Phase 3 — Godot client

- [ ] Create a new Godot 4 project in `client/` using the Mobile renderer (mobile is the eventual target; run on desktop for now).
- [ ] Enable the untyped-declaration warnings in Project Settings so missing type hints are flagged.
- [ ] Install the official Nakama Godot addon into `addons/com.heroiclabs.nakama/` (version compatible with your Nakama server).
- [ ] Enable the plugin; confirm the `Nakama` autoload appears.
- [ ] Add `autoload/net.gd` as an autoload named `Net`.
- [ ] `Net`: read server host, port, key and scheme from one config dictionary (local values only for now).
- [ ] `Net`: create the client with `Nakama.create_client(...)`.
- [ ] `Net`: generate a UUID on first launch and save it to `user://device_id`; reuse it afterwards.
- [ ] `Net`: authenticate with `authenticate_device_async(device_id)`; on exception, show an error and stop.
- [ ] `Net`: create the socket with `Nakama.create_socket_from(client)` and `connect_async(session)`.
- [ ] `Net`: call `rpc_async(session, "hello", "")` and emit a typed signal with the `message` from the payload.
- [ ] `scenes/main.tscn`: a `Label` that shows "Connecting…" and then the hello message (or the error).
- [ ] Run the project; confirm the hello message appears and the device's user shows up in the Nakama console.

## Definition of done

- [ ] `make up` and `make build-server` bring up a working server on a fresh machine using only the README.
- [ ] `make test` runs (no tests yet is fine).
- [ ] The Godot client on desktop authenticates, connects its socket and displays the reply from the `hello` RPC.
