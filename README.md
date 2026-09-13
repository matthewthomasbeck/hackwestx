APP NAME (WIP): Solana Soothsayer

THE PLAN!

login to app with auth0 -> EC2 backend (EC2B) checks creds -> EC2B grabs data from Tiger Data DB (TD) for Sol ticker ->
if new there is new data via checking date of latest and current date, update TD with latest data and call prediction service (PS) with auth0 creds ->
take timeseries JSON given by backend and predict using LSTM RNN -> return predictions to EC2B -> EC2B updates TD databse with latest predictions ->
EC2B sends latest data to Flutter Frontend (FF) and reloads the page if there was new data detected -> if market looks good (i.e. Sol predicted to increase in price), suggest to buy ->
if user wants to buy, handle Sol purchase workflow (paper purchasing, I dont want to risk my net worth lmao)

Competitive Components:

* needs to use auth0 for use login and prediciton service auth (MLH Auth0 track)
* needs to use Tiger Database to store timeseries data efficiently (MLH Tiger Data track)
* needs to use Solana timeseries data from Solana api on Python (MLH Solana track)
* needs to incorporate Solana blockchain API for paper trading (MLH Solana track)
* needs to use Flutter for iOS + Android compatibility and gestures (UI/UX track)

Application Frontend Components:
* use aesthetic trading color system (pastels + night mode ideal)
* cannot be ugly af
* must allow for ticker updates from backend
* must allow for trade placing
* must have loading screen
* must have logging screen
* must take and display JSON data from backend

Application Frontend Ideas:
* want theme to be pruple + blue + green with dark/light mode and a slight glow and gradients
* want to use simple font and icons whose colors I can ideally manipulate
* loading page with simple solana logo in the center, subtle pulsing glow animation, short status text below (e.g. "Loading market data..."), and auto-navigate to login or home once auth + first /market fetch finish
* login page with app name + one-line tagline at top, centered "Sign in with Auth0" button (purple/blue gradient), small footer note that this is paper trading only, and redirect to onboarding on first launch or home if already seen onboarding
* home page with current SOL price + % change header, main line/candle chart showing real prices (solid line) and predicted prices (dashed/green line), "last updated" timestamp, pull-to-refresh or refresh icon that hits POST /market/refresh, quick-action buttons to Forecast Detail / Portfolio / Buy SOL, and bottom nav or drawer for other pages
* buy sol page with available paper USD balance at top, amount-to-spend text field (or slider), live preview of estimated SOL received at current price, optional short note like "Based on latest forecast" if model is bullish, and a primary "Review Buy" button that goes to trade confirm
* sol forecast in detail page with next 3 predicted daily closes as cards or a small chart, model version + forecast generated time, simple up/down/neutral indicator per day, and a "Why this forecast?" blurb (e.g. "LSTM trained on recent SOL daily closes")
* paper portfolio page with starting balance vs current value summary, cash available, SOL held + average buy price, unrealized P&L in green/red, and a small sparkline or mini chart of portfolio value over time (can be stubbed at first)
* trade confirm/receipt page with order summary (USD spent, SOL bought, price used, timestamp), confirm + cancel buttons on confirm step, then success receipt view with checkmark/glow, trade ID, and buttons to view history or return home
* trade history page with scrollable list of past paper trades (newest first), each row showing date, buy/sell type, amount, price, and optional "forecast was correct?" badge once accuracy data exists
* account settings page with Auth0 profile name/email, dark/light mode toggle, paper account reset button (with confirm dialog), app version, logout button, and link back to onboarding/help
* empty/pending/error pages with reusable layouts: empty = "No market data yet" + refresh button; pending = "Generating predictions..." spinner while status is predictions_pending; error = friendly message + retry button for network/auth failures
* onboarding page with 2-3 swipeable cards explaining the app (1. AI forecasts SOL, 2. You paper-trade with fake money, 3. Track results over time), skip/next buttons, and "Get Started" that marks onboarding complete and routes to login/home

Application Backend Components:
* needs to use auth0 for login
* needs to use EC2 and not Google Cloud for Tailscale compatibility
* needs to have thread for when prediction is being made
* must take data from solana api, store timeseries data in tiger data, store predicitons data in tiger data, and if new data detected, update the actual data and prediciton data tables
* must compare predictions vs actual data for a model accuracy
* must serve the flutter fronend with JSON data
* must send data to both frontend and prediction service via JSON
* must take in JSON data from prediction service

Prediction Service Components:
* needs to use auth0 for credentials
* needs to use Tailscale to put desktop and EC2 in same network to avoid port forwarding on home network
* must use LSTM RNN (most accurate for timeseries, deeplearning goated)
* need to send data to backend in form of JSON

THINGS DONE:
1. set up AWS EC2 isntance to hold my flutter backend
2. set up Tailscale and EC2 VPN to mesh my AWS backend and my Desktop with its beefy GPU
3. set up basic tiger cloud
4. set up auth0 for user auth and predictor auth
5. set up yfinance for solana time series
6. wrote skeleton for application backend
7. wrote skeleton for predictor backend
8. completed predictor backend env
9. completed application backend env
10. completed prediction pipeline on desktop
11. completed base implementation of application backend
12. successfully started both backend systems (but yet to pressure test)
13. application backend successfully downloads latest SOL timeseries data and stores it in timeseries optimized Tiger DB
14. predictor backend successfully authenticating with auth0 so random people can't call my GPU
15. appliaction backend to predictor backend to application backend pipeline complete with complete tiger cloud and auth0 predictor integration
16. application frontend basic skeleton with all pages from notebook implemented
17. application frontend now uses auth0 for user authentication



