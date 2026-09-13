# Solana Soothsayer

**Forecast SOL. Paper-trade with confidence.**

Solana Soothsayer is a Flutter trading companion that forecasts Solana (SOL) daily closes with a deep-learning time-series model, stores market history in a timeseries database, and lets you paper-trade against those forecasts — without risking real money.

---

## Inspiration

Crypto prices move fast and intuition alone is a bad trading strategy. We wanted a single app that answers two questions at once: *where might SOL go next?* and *what would I do with that signal if I could practice without losing my net worth?* HackWesTX’s sponsor tracks (Auth0, Tiger Data, Solana, UI/UX) lined up perfectly with that idea: secure identity, efficient timeseries storage, Solana market context, and a mobile experience that feels like a real trading product.

---

## What it does

1. **Sign in** with Auth0 Universal Login.
2. **Pull SOL market history**, store it in Tiger Data, and refresh when the calendar day advances.
3. **Run a GPU-backed BiGRU + attention model** to forecast the next several daily closes.
4. **Chart real prices vs. predictions** on home (1W / 1M / 3M / YTD / Max), with a dedicated forecast detail view.
5. **Paper-buy SOL** from a sandbox ledger ($10,000 starting balance), then track portfolio value, P&L, and trade history.

Onboarding sums it up: AI forecasts SOL → you paper-trade with fake money → you track results over time.

---

## How we built it

Three services talk over JSON:

| Layer | Stack | Role |
|--------|--------|------|
| **application_frontend** | Flutter (iOS + Android), Auth0 Flutter SDK | Auth, charts, paper trading UI |
| **application_backend** | Flask on AWS EC2 | Auth0 JWT checks, yfinance ingest, Tiger Data, pipeline orchestration |
| **predictor_backend** | Flask + PyTorch on a Tailscale-linked GPU desktop | Auth0 M2M–gated inference, async callback with forecasts |

**Pipeline:** EC2 checks Tiger for the latest OHLCV date → if stale, fetch SOL-USD via yfinance → upsert into Tiger hypertables → push a `predictions_pending` snapshot to the app → call the predictor with an Auth0 machine-to-machine token → predictor trains/infers and POSTs back to `/callback/solana` → EC2 stores forecasts in Tiger and serves a `ready` market bundle to Flutter.

Tailscale meshes the EC2 backend with the desktop GPU so inference stays private (no home-network port forwarding). The Flutter client talks to the EC2 Elastic IP directly after install.

---

## How we followed the tracks

### MLH Auth0 track
- **User auth:** Flutter uses Auth0 Universal Login (PKCE) so every session is a real identity, not a fake local login.
- **Service auth:** The application backend obtains Auth0 M2M tokens to call the prediction service, so random clients cannot hit the GPU endpoint.
- Dual audiences separate user traffic (`hackwestx.user.auth`) from predictor traffic (`predictor.soothsayer.hackwestx`).

### MLH Tiger Data track
- SOL OHLCV and model forecasts live in **Tiger Cloud / Timescale** hypertables (`sol_ohlcv`, `sol_predictions`).
- The backend only re-fetches and re-predicts when the stored series is behind the current day, so Tiger is the source of truth for efficient timeseries read/write — not a throwaway SQLite cache.

### MLH Solana track
- Market context is **Solana (SOL-USD)** daily timeseries ingested in Python and shaped for forecasting.
- The product loop is Solana-native: forecast SOL closes, surface bullish/bearish cues, and paper-trade SOL against those signals (sandbox ledger today; Solana/Helius RPC hooks reserved for on-chain paper trading next).

### UI/UX track
- Built entirely in **Flutter** for iOS and Android, with gestures (swipeable onboarding, pull-to-refresh / refresh affordances, bottom navigation).
- Solana-inspired purple → cyan → green palette, dark/light mode, glow/gradient accents, custom chart painter (solid real prices + dashed forecast line), loading pulse on the Solana mark, and dedicated empty / pending / error states so the market pipeline feels intentional instead of broken.

---

## Challenges we ran into

- **Three moving parts, one demo:** Keeping Auth0 (user + M2M), Tiger Cloud, EC2, Tailscale, and a GPU predictor aligned under hackathon time pressure.
- **Stale vs. live data:** Deciding when to skip work vs. force a refresh so the app doesn’t hammer yfinance or the GPU on every open.
- **Async forecasts:** Returning `predictions_pending` immediately, polling from Flutter, and completing the loop via callback without blocking the API.
- **Model choice:** Starting from an LSTM-style timeseries approach and moving to a **BiGRU + temporal attention** setup for better inference under our constraints.

---

## Accomplishments that we're proud of

- End-to-end loop: Auth0 login → Tiger-backed market data → GPU forecast → Flutter chart + paper trade.
- Predictor locked behind Auth0 so the GPU isn’t a public free-for-all.
- A polished mobile shell (loading, login, onboarding, home chart, forecast, buy, confirm, portfolio, history, settings) that matches a real trading-app flow.
- Infra that actually works across cloud and home GPU via Tailscale instead of brittle port forwards.

---

## What we learned

- Sponsor tracks work best when they’re **load-bearing** in the architecture, not bolted on for a checkbox.
- Timeseries databases shine when the product *is* time (OHLCV + rolling forecasts).
- Separating user JWTs from M2M service tokens is the difference between “demo auth” and something you’d actually ship.
- Flutter is enough to ship a credible trading UX in a weekend if the API contract is clear (`empty` / `predictions_pending` / `ready`).

---

## What's next

- Wire **Solana / Helius RPC** into the paper-trading path for chain-aware sandbox fills.
- Persist onboarding completion and tighten forecast-vs-actual accuracy badges in trade history.
- Pressure-test the EC2 ↔ predictor pipeline under concurrent refresh.
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
- yfinance (SOL-USD)
- Python / pandas / numpy
- gunicorn / PyJWT

---

## Try it

1. Sign in with Auth0 on the Flutter app.
2. Wait for market status to reach **ready** (refresh if needed).
3. Inspect the chart and 5-day forecast.
4. Paper-buy SOL and check portfolio + trade history.

*Paper trading only — no real funds at risk.*
