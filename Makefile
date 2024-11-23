.PHONY: up down logs

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker logs -f postgres_dev
