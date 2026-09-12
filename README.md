###THE PLAN!

login to app with auth0 -> EC2 backend (EC2B) checks creds -> EC2B grabs data from Tiger Data DB (TD) for Sol ticker ->
if new there is new data via checking date of latest and current date, update TD with latest data and call prediction service (PS) with auth0 creds ->
take timeseries JSON given by backend and predict using LSTM RNN -> return predictions to EC2B -> EC2B updates TD databse with latest predictions ->
EC2B sends latest data to Flutter Frontend (FF) and reloads the page if there was new data detected -> if market looks good (i.e. Sol predicted to increase in price), suggest to buy ->
if user wants to buy, handle Sol purchase workflow (paper purchasing, I dont want to risk my net worth lmao)

###Important Components:

* needs to have thread for when prediction is being made
