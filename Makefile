# PostgreSQL By Building — command shortcuts
# Everything here wraps docker so you never have to remember long commands.

DB      = freelanceforge
USER    = forge
COMPOSE = docker compose
EXEC    = $(COMPOSE) exec -T db psql -U $(USER) -d $(DB)

.PHONY: help up down destroy psql logs status reset run

help:            ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	 | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up:              ## Start Postgres (waits until it is ready)
	$(COMPOSE) up -d
	@echo "Waiting for Postgres to be healthy..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' pbb_postgres)" = "healthy" ]; do sleep 1; done
	@echo "Ready. Run 'make psql' to connect."

down:            ## Stop Postgres (keeps your data)
	$(COMPOSE) down

destroy:         ## Stop Postgres AND delete all data (fresh start)
	$(COMPOSE) down -v

psql:            ## Open an interactive psql shell inside the container
	$(COMPOSE) exec db psql -U $(USER) -d $(DB)

logs:            ## Tail the database logs
	$(COMPOSE) logs -f db

status:          ## Show container status
	$(COMPOSE) ps

# Run a single .sql file, e.g:  make run FILE=modules/01-tables-and-types/build.sql
run:             ## Run a SQL file: make run FILE=path/to/file.sql
	$(EXEC) -f /repo/$(FILE)

reset:           ## Drop everything and rebuild the whole schema from db/schema.sql
	$(EXEC) -f /repo/db/reset.sql
	@echo "Database reset to a clean, fully-built state."
