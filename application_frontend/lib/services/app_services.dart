/*##################################################*/
/*############### APP SERVICES #####################*/
/*##################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import local modules #####*/

import 'api_service.dart'; // import EC2 HTTP client
import 'auth_service.dart'; // import Auth0 session owner
import 'market_store.dart'; // import shared /market state
import 'portfolio_store.dart'; // import in-app paper ledger
import 'theme_store.dart'; // import app-wide light / dark mode





/*########## SHARED INSTANCES ##########*/

final AuthService authService = AuthService(); // app-wide Auth0 session
final ApiService apiService = ApiService(); // app-wide EC2 client
final MarketStore marketStore = MarketStore(apiService); // app-wide SOL market snapshot
final PortfolioStore portfolioStore = PortfolioStore(); // app-wide paper cash / trades
final ThemeStore themeStore = ThemeStore(); // app-wide ThemeMode owner

/*########## SYNC API TOKEN ##########*/

void syncApiAccessToken() { // function to copy Auth0 Bearer onto ApiService

  apiService.accessToken = authService.accessToken; // null when logged out

}
