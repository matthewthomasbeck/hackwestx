# Solana Soothsayer

**Forecast SOL. Paper-trade with confidence.**

Solana Soothsayer is a Flutter trading companion that forecasts Solana (SOL) daily closes with a deep-learning time-series model, stores market history in a timeseries database, and lets you paper-trade against those forecasts without risking real money.

---

## Inspiration

Crypto prices move fast and intuition alone is a bad trading strategy. I wanted a single app that answers two questions at once: where might SOL go next, and what would I do with that signal if I could practice without losing my net worth? HackWesTX's sponsor tracks (Auth0, Tiger Data, Solana, UI/UX) lined up with that idea: secure identity, efficient timeseries storage, Solana market context, and a mobile experience that feels like a real trading product.

---

## What it does

1. **Sign in** with Auth0 Universal Login.
2. **Pull SOL market history**, store it in Tiger Data, and refresh when the calendar day advances.
3. **Run a GPU-backed BiGRU + attention model** to forecast the next several daily closes.
4. **Chart real prices vs. predictions** on home (1W / 1M / 3M / YTD / Max), with a dedicated forecast detail view.
5. **Paper-buy SOL** from a sandbox ledger ($10,000 starting balance), then track portfolio value, P&L, and trade history.

Onboarding sums it up: AI forecasts SOL, you paper-trade with fake money, and you track results over time.

---

## How I built it: three systems working together

This is not one monolith. It is **three separate systems** that only talk over authenticated JSON APIs.

### 1. application_frontend (Flutter)

The mobile client for iOS and Android. It handles Auth0 login, charts, forecast detail, paper buys, portfolio, and trade history. It never talks to the GPU machine directly. It only calls the application backend and polls market status (`empty`, `predictions_pending`, or `ready`) until forecasts land.

### 2. application_backend (Flask on AWS EC2)

The orchestrator in the middle. It verifies user JWTs from Auth0, pulls SOL-USD history with yfinance, reads and writes Tiger Data hypertables, decides whether the day is stale enough to refresh, and owns the pipeline that kicks off prediction jobs. When forecasts finish, it accepts a callback, stores the results, and serves a market bundle the Flutter app can render.

### 3. predictor_backend (custom ML prediction API)

I designed and built my own ML prediction API from scratch instead of plugging into a third-party forecasting SaaS. It is a Flask + PyTorch service that runs on my desktop GPU, joined to EC2 over Tailscale so inference stays on a private mesh with no home-network port forwarding.

That API defines its own request and response contract: accept timeseries JSON, queue async inference, run a BiGRU + temporal attention model, and POST forecasts back to the application backend callback. Auth0 machine-to-machine tokens gate every call so random clients cannot hit the GPU. The model, training/inference workers, auth, and callback flow are all custom code I wrote for this project.

### How the three systems hand off

1. Flutter signs the user in and asks EC2 for `/market`.
2. EC2 checks Tiger for the latest OHLCV date. If stale, it fetches SOL-USD, upserts into Tiger, and immediately returns a `predictions_pending` snapshot so the app stays usable.
3. EC2 then calls my prediction API with an Auth0 M2M token and a callback URL.
4. The predictor trains/infers on GPU and POSTs results to `/callback/solana` on EC2.
5. EC2 writes forecasts into Tiger and serves a `ready` bundle.
6. Flutter redraws real prices (solid) vs. predicted closes (dashed) and unlocks the paper-trade flow.

Each piece can fail or restart on its own. The frontend stays thin, the EC2 backend owns data and orchestration, and the predictor stays a specialized ML service. That separation is the core of the architecture.

---

## How I followed the tracks

### MLH Auth0 track
- **User auth:** Flutter uses Auth0 Universal Login (PKCE) so every session is a real identity, not a fake local login.
- **Service auth:** The application backend obtains Auth0 M2M tokens to call my prediction API, so the GPU endpoint is not public.
- Dual audiences separate user traffic (`hackwestx.user.auth`) from predictor traffic (`predictor.soothsayer.hackwestx`).

### MLH Tiger Data track
- SOL OHLCV and model forecasts live in Tiger Cloud / Timescale hypertables (`sol_ohlcv`, `sol_predictions`).
- The backend only re-fetches and re-predicts when the stored series is behind the current day, so Tiger is the source of truth for efficient timeseries read/write, not a throwaway SQLite cache.

### MLH Solana track
- Market context is Solana (SOL-USD) daily timeseries ingested in Python and shaped for forecasting.
- The product loop is Solana-native: forecast SOL closes, surface bullish/bearish cues, and paper-trade SOL against those signals (sandbox ledger today; Solana/Helius RPC hooks reserved for on-chain paper trading next).

### UI/UX track
- Built entirely in Flutter for iOS and Android, with gestures (swipeable onboarding, pull-to-refresh / refresh affordances, bottom navigation).
- Solana-inspired purple, cyan, and green palette, dark/light mode, glow/gradient accents, custom chart painter (solid real prices and dashed forecast line), loading pulse on the Solana mark, and dedicated empty / pending / error states so the market pipeline feels intentional instead of broken.

---

## Challenges I ran into

- **Three systems, one demo:** Keeping Auth0 (user + M2M), Tiger Cloud, EC2, Tailscale, and a custom GPU prediction API aligned under hackathon time pressure.
- **Stale vs. live data:** Deciding when to skip work vs. force a refresh so the app does not hammer yfinance or the GPU on every open.
- **Async forecasts across services:** Returning `predictions_pending` immediately from EC2, polling from Flutter, and completing the loop via callback from my prediction API without blocking the user-facing API.
- **Model choice:** Starting from an LSTM-style timeseries approach and moving to a BiGRU + temporal attention setup for better inference under my constraints.
- **Owning the ML API contract:** Designing request payloads, auth, async job handling, and callbacks myself meant debugging both ends of the wire when something broke.

---

## Accomplishments I'm proud of

- Shipping an end-to-end loop across three systems: Auth0 login, Tiger-backed market data, custom GPU forecasts, Flutter chart, and paper trade.
- Designing my own ML prediction API (auth, queue, BiGRU inference, callback) instead of outsourcing forecasts.
- Locking the predictor behind Auth0 so the GPU is not a public free-for-all.
- A polished mobile shell (loading, login, onboarding, home chart, forecast, buy, confirm, portfolio, history, settings) that matches a real trading-app flow.
- Infra that actually works across cloud and home GPU via Tailscale instead of brittle port forwards.

---

## What I learned

- Sponsor tracks work best when they are load-bearing in the architecture, not bolted on for a checkbox.
- Splitting a product into three systems (client, orchestrator, ML API) forces clean contracts and makes each layer easier to reason about.
- Designing your own prediction API teaches you the hard parts: auth between services, async jobs, callbacks, and versioning the JSON shape both sides expect.
- Timeseries databases shine when the product is time (OHLCV + rolling forecasts).
- Separating user JWTs from M2M service tokens is the difference between demo auth and something you would actually ship.
- Flutter is enough to ship a credible trading UX in a weekend if the API contract is clear (`empty` / `predictions_pending` / `ready`).

---

## What's next

- Wire Solana / Helius RPC into the paper-trading path for chain-aware sandbox fills.
- Persist onboarding completion and tighten forecast-vs-actual accuracy badges in trade history.
- Pressure-test the EC2 and predictor pipeline under concurrent refresh.
- Optional sell flow and richer portfolio analytics.

---

## Built with

- Flutter
- Auth0
- Tiger Data (Timescale / Tiger Cloud)
- AWS EC2
- Tailscale
- Flask
- PyTorch (BiGRU + attention)
- Custom ML prediction API
- yfinance (SOL-USD)
- Python / pandas / numpy
- gunicorn / PyJWT

---

## Try it

1. Sign in with Auth0 on the Flutter app.
2. Wait for market status to reach **ready** (refresh if needed).
3. Inspect the chart and 5-day forecast.
4. Paper-buy SOL and check portfolio + trade history.

*Paper trading only. No real funds at risk.*
