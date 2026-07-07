API_URL ?= http://localhost:3001
LOAD_TEST_RATE ?= 100
LOAD_TEST_DURATION ?= 1m
LOAD_TEST_PRE_ALLOCATED_VUS ?= 50
LOAD_TEST_MAX_VUS ?= 300
LOAD_TEST_PARTICIPANTS ?= [1,2]

up:
	docker compose up --build

up-detached:
	docker compose up --build -d

down:
	docker compose down

down-volumes:
	docker compose down -v

logs:
	docker compose logs -f

logs-api:
	docker compose logs -f api

logs-front:
	docker compose logs -f frontend

db-prepare:
	docker compose exec api bundle exec rails db:prepare

db-seed:
	docker compose exec api bundle exec rails db:seed

db-reset:
	docker compose exec api bundle exec rails db:drop db:create db:migrate db:seed

rails-console:
	docker compose exec api bundle exec rails console

bash-api:
	docker compose exec api bash

bash-front:
	docker compose exec frontend sh

test-api:
	docker compose exec api bundle exec rspec

test-front:
	docker compose exec frontend npm test

test-front-coverage:
	docker compose exec frontend npm run test:coverage

test-all: test-api test-front

prepare-load-election:
	@echo "Checking current election..."
	@CURRENT=$$(curl -s "$(API_URL)/api/elections/current"); \
	STATUS=$$(echo "$$CURRENT" | jq -r 'if . == null then "none" else .status end'); \
	ID=$$(echo "$$CURRENT" | jq -r 'if . == null then "" else .id end'); \
	if [ "$$STATUS" = "running" ]; then \
		echo "A running election already exists. Election ID: $$ID"; \
	elif [ "$$STATUS" = "draft" ]; then \
		echo "Starting existing draft election. Election ID: $$ID"; \
		curl -s -X POST "$(API_URL)/api/admin/elections/$$ID/start" | jq; \
	else \
		echo "Creating and starting a new election for load test..."; \
		CREATED=$$(curl -s -X POST "$(API_URL)/api/admin/elections" \
			-H "Content-Type: application/json" \
			-d '{"participant_ids":$(LOAD_TEST_PARTICIPANTS)}'); \
		echo "$$CREATED" | jq; \
		NEW_ID=$$(echo "$$CREATED" | jq -r '.id'); \
		curl -s -X POST "$(API_URL)/api/admin/elections/$$NEW_ID/start" | jq; \
	fi

load-test: prepare-load-election
	docker compose --profile loadtest run --rm \
		-e RATE=$(LOAD_TEST_RATE) \
		-e DURATION=$(LOAD_TEST_DURATION) \
		-e PRE_ALLOCATED_VUS=$(LOAD_TEST_PRE_ALLOCATED_VUS) \
		-e MAX_VUS=$(LOAD_TEST_MAX_VUS) \
		k6 run /scripts/vote-test.js

load-test-100:
	$(MAKE) load-test LOAD_TEST_RATE=100 LOAD_TEST_DURATION=1m LOAD_TEST_PRE_ALLOCATED_VUS=50 LOAD_TEST_MAX_VUS=300

load-test-1000:
	$(MAKE) load-test LOAD_TEST_RATE=1000 LOAD_TEST_DURATION=1m LOAD_TEST_PRE_ALLOCATED_VUS=300 LOAD_TEST_MAX_VUS=1500

prometheus:
	open http://localhost:9090

grafana:
	open http://localhost:3002

frontend:
	open http://localhost:3000

api:
	open http://localhost:3001