# BBB Voting API

API Ruby on Rails (API-only) para sistema de votação estilo BBB.

## Requisitos

- Ruby 3.0.7
- PostgreSQL
- Redis (apenas em desenvolvimento/produção; os testes usam um fake em memória)

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

## Testes

```bash
# Rodar toda a suíte
bundle exec rspec

# Rodar um arquivo específico
bundle exec rspec spec/services/voting_service_spec.rb

# Cobertura (SimpleCov)
bundle exec rspec
# Relatório HTML em coverage/index.html
```

A suíte usa:

- **RSpec** para models, services e request specs
- **FactoryBot** para dados de teste
- **SimpleCov** para relatório de cobertura em `coverage/`
- **FakeRedis** em memória (sem dependência de Redis real nos testes)
- **Transactional fixtures** do Rails para isolamento do banco

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Health check |
| GET | `/metrics` | Métricas Prometheus |
| GET | `/api/participants` | Participantes ativos |
| GET | `/api/elections/current` | Eleição atual (draft/running) |
| GET | `/api/elections/current/results` | Resultado parcial |
| GET | `/api/elections/current/hourly` | Votos por hora |
| POST | `/api/votes` | Registrar voto |
| POST | `/api/admin/elections` | Criar eleição |
| POST | `/api/admin/elections/:id/start` | Iniciar votação |
| POST | `/api/admin/elections/:id/close` | Encerrar votação |
| GET | `/api/admin/elections/history` | Histórico de eleições |
