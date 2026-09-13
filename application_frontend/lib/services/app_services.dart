/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### APP SERVICES #####################*/
/*##################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import local modules #####*/

import 'api_service.dart'; // import EC2 HTTP client
import 'auth_service.dart'; // import Auth0 session owner





/*########## SHARED INSTANCES ##########*/

final AuthService authService = AuthService(); // app-wide Auth0 session
final ApiService apiService = ApiService(); // app-wide EC2 client

/*########## SYNC API TOKEN ##########*/

void syncApiAccessToken() { // function to copy Auth0 Bearer onto ApiService

  apiService.accessToken = authService.accessToken; // null when logged out

}
