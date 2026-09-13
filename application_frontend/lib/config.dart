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

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  ); // EC2 / emulator API base URL

  static const appName = 'Solana Soothsayer'; // display name
  static const appTagline = 'Forecast SOL. Paper-trade with confidence.'; // tagline
  static const packageId = 'com.hackwestx.soothsayer'; // application id
  static const paperStartingUsd = 10000.0; // paper starting cash

}
