# Architecture diagrams (judge-friendly)

Three systems. Flutter never talks to the GPU. EC2 owns Auth0 users, Tiger storage, and orchestration. The desktop predictor is a private ML API on Tailscale that only accepts machine tokens and returns forecasts via callback.

---

## 1. Application frontend (Flutter)

**Story:** User signs in → app asks EC2 for market data → charts it → paper-trades on device.

```mermaid
flowchart TB
  User([User]) --> Auth0[Auth0 Login]
  Auth0 -->|JWT| App[Flutter App]

  App --> Screens[Screens: Home · Forecast · Buy/Sell · Portfolio]
  App --> Market[MarketStore]
  App --> Paper[PortfolioStore<br/>local paper trades]

  Market -->|GET/POST /api/v1/market| EC2[Application Backend]
  Screens --> Market
  Screens --> Paper
```

---

## 2. Application backend (Flask on EC2)

**Story:** Orchestrator — refresh SOL into Tiger, call the GPU predictor, cache chart JSON for Flutter.

```mermaid
flowchart LR
  Flutter[Flutter] -->|JWT| API[Flask API]

  API --> Auth0[Auth0]
  API --> YF[yfinance<br/>SOL-USD]
  API --> Tiger[(Tiger Data<br/>OHLCV + forecasts)]
  API -->|M2M token| Pred[Predictor Backend]
  Pred -->|callback| API
  API -->|market JSON| Flutter
```

### Refresh loop (same service, sequential)

```mermaid
sequenceDiagram
  participant F as Flutter
  participant A as App Backend
  participant T as Tiger
  participant P as Predictor

  F->>A: POST /market/refresh
  A-->>F: 202 + predictions_pending
  A->>T: upsert SOL OHLCV
  A->>P: POST /predict
  P-->>A: POST /callback/solana
  A->>T: upsert forecasts
  F->>A: GET /market poll
  A-->>F: status ready
```

---

## 3. Predictor backend (Flask + GPU)

**Story:** Accept timeseries → queue → train BiGRU on GPU → POST forecasts back.

```mermaid
flowchart LR
  EC2[App Backend] -->|POST /api/v1/predict<br/>Auth0 M2M| API[Flask API]
  API --> Q[Task Queue]
  Q --> GPU[GPU Worker]
  GPU --> Model[BiGRU + Attention<br/>train + forecast]
  Model -->|POST callback| EC2
```
