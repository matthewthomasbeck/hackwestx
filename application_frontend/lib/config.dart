/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### APP CONFIGURATION ################*/
/*##################################################*/


/*########## APP CONFIG ##########*/

class AppConfig { // class to hold frontend constants and dart-define overrides

  /*##### API base URL #####*/

  /// EC2 application_backend base URL (Elastic IP). Override with:
  /// --dart-define=API_BASE_URL=http://16.58.231.227:8080
  /// Phone talks to EC2 directly — no USB/computer required after install.
  /// Android emulator → laptop localhost would be http://10.0.2.2:8080 instead.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://16.58.231.227:8080',
  ); // default to AWS Elastic IP for physical devices

  /*##### app identity #####*/

  static const appName = 'Solana Soothsayer'; // display name for MaterialApp / UI
  static const appTagline = 'Forecast SOL. Paper-trade with confidence.'; // login / onboarding line
  static const packageId = 'com.hackwestx.soothsayer'; // Android applicationId / iOS bundle id

  /*##### Auth0 (Native + PKCE) #####*/

  /// Auth0 tenant domain only (no https://). Override with:
  /// --dart-define=AUTH0_DOMAIN=your-tenant.us.auth0.com
  /// Also set android/gradle.properties auth0Domain to the same value.
  static const auth0Domain = String.fromEnvironment(
    'AUTH0_DOMAIN',
    defaultValue: '',
  );

  /// Native application Client ID (not the M2M app, not the secret).
  /// --dart-define=AUTH0_CLIENT_ID=...
  static const auth0ClientId = String.fromEnvironment(
    'AUTH0_CLIENT_ID',
    defaultValue: '',
  );

  /// API Identifier / audience EC2 validates (your Auth0 API).
  /// Set to `none` to login without an API audience (debug connection-only).
  static const auth0Audience = String.fromEnvironment(
    'AUTH0_AUDIENCE',
    defaultValue: 'https://hackwestx.user.auth',
  );

  /// Whether login should request an API access token for EC2.
  static bool get requestApiAudience { // function to gate audience on login

    final value = auth0Audience.trim(); // raw dart-define / default
    if (value.isEmpty || value.toLowerCase() == 'none') { // debug without API
      return false; // OIDC profile token only
    }
    return true; // request API JWT

  }

  /// Custom URL scheme registered in Auth0 Allowed Callback / Logout URLs.
  static const auth0Scheme = String.fromEnvironment(
    'AUTH0_SCHEME',
    defaultValue: 'soothsayer',
  );

  /*##### paper trading defaults (mirror backend env until APIs exist) #####*/

  static const paperStartingUsd = 10000.0; // starting paper cash for portfolio stubs

}
