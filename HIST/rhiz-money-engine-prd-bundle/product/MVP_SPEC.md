# MVP Spec

## UI pages

- `/` Landing page
- `/diagnostic` Paid ops diagnostic intake
- `/dashboard` Endpoint health and service topology
- `/reports/:id` Client report
- `/cookbook` Technical recipes
- `/trading-journal` Research journal
- `/pricing` Offers and subscription tiers

## API endpoints

```http
GET /api/health
POST /api/diagnostics/run
GET /api/diagnostics/:id
POST /api/reports/generate
GET /api/services
POST /api/trading/journal
GET /api/pricing
```

## Core objects

```ts
type ServiceEndpoint = {
  id: string
  name: string
  url: string
  kind: "ollama" | "openai" | "docker" | "lxd" | "web" | "custom"
  invariant?: string
  status: "unknown" | "ok" | "warn" | "fail"
}

type DiagnosticRun = {
  id: string
  createdAt: string
  client?: string
  endpoints: ServiceEndpoint[]
  findings: Finding[]
  recommendation: string
  quoteCHF?: number
}

type TradeJournalEntry = {
  id: string
  asset: string
  thesis: string
  riskCHF: number
  invalidation: string
  outcome?: string
  emotion?: string
}
```

## MVP behavior

- No auto-fix by default.
- All mutation actions gated.
- Diagnostics are read-only unless confirmed.
- Reports are printable.
- Trading lab is journal-only.
