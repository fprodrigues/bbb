# BBB Voting Challenge — Frontend

Frontend em Next.js (App Router), TypeScript e Material UI para o desafio técnico de votação estilo BBB.

## Pré-requisitos

- Node.js 20+
- npm

## Instalação

```bash
npm install
```

## Desenvolvimento

```bash
npm run dev
```

Abra [http://localhost:3000](http://localhost:3000) no navegador.

## Testes

A suíte usa Jest e React Testing Library.

```bash
# Executar todos os testes
npm test

# Modo watch
npm run test:watch

# Relatório de cobertura
npm run test:coverage
```

### Estrutura dos testes

- `src/app/page.test.tsx` — página inicial
- `src/app/votacao/page.test.tsx` — fluxo de votação pública
- `src/app/admin/page.test.tsx` — painel administrativo
- `src/lib/api.test.ts` — cliente HTTP da API
- `src/test-utils/` — helpers de render, fixtures e mocks

## Scripts disponíveis

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Servidor de desenvolvimento |
| `npm run build` | Build de produção |
| `npm run start` | Servidor de produção |
| `npm run lint` | ESLint |
| `npm test` | Testes unitários e de componentes |
| `npm run test:watch` | Testes em modo watch |
| `npm run test:coverage` | Testes com relatório de cobertura |

## Páginas

- `/` — escolha entre Admin e Votação
- `/admin` — criar, iniciar, encerrar votações e acompanhar resultados
- `/votacao` — votar no paredão ativo e ver percentuais atualizados

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `NEXT_PUBLIC_API_URL` | `http://localhost:3001` | URL base da API backend |
