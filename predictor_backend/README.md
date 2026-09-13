# Solana Soothsayer — predictor_backend

PyTorch LSTM prediction service that will:
1. Accept timeseries JSON from `application_backend` at `/api/v1/predict`
2. Authenticate via `Authorization: Bearer` (Auth0 M2M target; interim API key OK)
3. Optionally normalize SOL payloads (`helpers/solana.py`)
4. Queue LSTM train/infer workers and POST prediction JSON to a callback URL

Auth is **not** part of the JSON body — `utils/json_formatter.py` validates
`timeSeries` / `xAxis` / `yAxis` only.

## Layout

```
main.py                     # Flask + workers entrypoint (skeleton)
config.py                   # env-backed Config class
api/
  auth.py                   # Bearer verify (Auth0 M2M + interim key)
  routes.py                 # /api/v1/predict, status
  health.py                 # /health, /status
helpers/
  auth0.py                  # M2M JWT / JWKS
  solana.py                 # SOL payload normalize
models/                     # LSTM, loader, trainer
task_queue/                 # QueueManager + TaskHandler
utils/                      # dates, JSON, logging, pre/postprocess
workers/                    # GPU/CPU workers + WorkerManager
```

Function bodies are intentionally empty (`pass`) skeletons with maestro-style
section comments. Full pre-strip implementations are stashed outside this repo at:

`Projects/HackWesTX_stash/HackWesTX_predictor_backend_full_pre_strip_2026-09-12`

## Quick start (after filling implementations)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp env_template.txt .env   # fill PREDICTION_SERVICE_KEY and/or Auth0
python main.py
```
