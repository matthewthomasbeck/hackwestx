# Solana Soothsayer — application_backend

Flask API on EC2 that will:
1. Authenticate Flutter users with Auth0
2. Pull SOL timeseries via yfinance into Tiger Cloud (`sol_ohlcv`)
3. Call `predictor_backend` over Tailscale with an Auth0 M2M token
4. Store predictions in Tiger (`sol_predictions`)
5. Serve real / real+forecast JSON to the Flutter app

## Layout

```
main.py                     # Flask entrypoint (skeleton)
api/
  health.py                 # / and /health
  market.py                 # /api/v1/market, refresh, /me, callback
helpers/
  auth0.py                  # user JWT + M2M token
  tiger_db.py               # Tiger Cloud read/write
  yfinance_solana.py        # SOL-USD fetch
  prediction_client.py      # predictor HTTP client
  frontend_delivery.py      # JSON cache / optional webhook
  pipeline.py               # date-check + update orchestration
```

Function bodies are intentionally empty (`pass`) skeletons with maestro-style
section comments. Full pre-strip implementations are stashed outside this repo at:

`Projects/_stash/HackWesTX_application_backend_full_pre_strip_2026-09-12`

## Quick start (after filling implementations)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp env_template.txt .env   # fill Tiger + Auth0 + predictor URL
python main.py
```
