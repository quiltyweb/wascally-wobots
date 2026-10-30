# Override with COMPOSE=docker-compose if the Compose plugin isn't installed.
COMPOSE ?= docker compose
COMPOSE_FILE := deploy/docker-compose.yml

.PHONY: up down logs

up: deploy/.env
	mkdir -p server/build
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f nakama

deploy/.env:
	cp deploy/.env.example deploy/.env
