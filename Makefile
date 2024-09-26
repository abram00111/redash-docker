ifneq (,$(wildcard ./.env))
    include .env
    export
endif

compose=docker-compose

up:
	docker compose up -d redis postgres clickhouse --remove-orphans
	docker compose exec -u ${POSTGRES_USER} ${POSTGRES_PASSWORD} psql ${POSTGRES_DB} --csv \
		-1tqc "SELECT table_name FROM information_schema.tables WHERE table_name = 'organizations'" 2> /dev/null \
		| grep -q "organizations" || make create_database_postgres
	COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker compose up -d --build --remove-orphans
	make .env

create_database_postgres:
	@docker compose run server create_db

.env:
	printf "REDASH_COOKIE_SECRET=`pwgen -1s 32`\nREDASH_SECRET_KEY=`pwgen -1s 32`\n" >> .env

bash:
	docker compose run --rm server bash

down-clear:
	$(compose) down -v --remove-orphans

clickhouse:
	docker exec -it clickhouse /bin/sh

generate-password:
	echo -n $(password) | sha256sum | tr -d '-'

clickhouse-restart:
	$(compose) down clickhouse
	$(compose) up -d clickhouse