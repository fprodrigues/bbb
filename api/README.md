# BBB Voting API

API Ruby on Rails para o sistema de votação estilo BBB.

## Dependências

- Ruby 3.0.7
- PostgreSQL
- Redis

## Setup

```bash
bundle install
bin/rails db:prepare
```

## Testes

```bash
bundle exec rspec
```

O relatório de cobertura é gerado automaticamente em `coverage/index.html` via SimpleCov.

Para rodar um arquivo específico:

```bash
bundle exec rspec spec/services/voting_service_spec.rb
```

## Endpoints principais

- `GET /health`
- `GET /metrics`
- `GET /api/participants`
- `GET /api/elections/current`
- `GET /api/elections/current/results`
- `GET /api/elections/current/hourly`
- `POST /api/votes`
- `POST /api/admin/elections`
- `POST /api/admin/elections/:id/start`
- `POST /api/admin/elections/:id/close`
- `GET /api/admin/elections/history`
