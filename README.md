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
* loading page with simple solana logo in the center
* login page with
* home page with
* buy sol page with
* sol forecast in detail page with
* paper portfolio page with
* trade confirm/receipt page with
* trade history page with
* account settings page with
* empty/pending/error pages with
* onboarding page with

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

