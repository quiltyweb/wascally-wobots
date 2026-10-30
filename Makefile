# Override with COMPOSE=docker-compose if the Compose plugin isn't installed.
COMPOSE ?= docker compose
COMPOSE_FILE := deploy/docker-compose.yml
# Must match the heroiclabs/nakama image tag in deploy/docker-compose.yml.
NAKAMA_VERSION := 3.41.0

.PHONY: build-server up down logs test

build-server:
	docker run --rm -w /builder -v $(CURDIR)/server:/builder \
		heroiclabs/nakama-pluginbuilder:$(NAKAMA_VERSION) \
		build -buildmode=plugin -trimpath -o build/backend.so .

up: deploy/.env
	mkdir -p server/build
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f nakama

deploy/.env:
	cp deploy/.env.example deploy/.env

test:
	cd server && go test ./...
