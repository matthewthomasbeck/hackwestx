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

  /// EC2 application_backend base URL. Override with:
  /// --dart-define=API_BASE_URL=https://your-ec2:8080
  /// Android emulator loopback to host is 10.0.2.2; a physical phone needs
  /// your computer's LAN IP or the public EC2 host instead.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  ); // default to Android emulator → host machine

  /*##### app identity #####*/

  static const appName = 'Solana Soothsayer'; // display name for MaterialApp / UI
  static const appTagline = 'Forecast SOL. Paper-trade with confidence.'; // login / onboarding line
  static const packageId = 'com.hackwestx.soothsayer'; // suggested Android/iOS application id

  /*##### paper trading defaults (mirror backend env until APIs exist) #####*/

  static const paperStartingUsd = 10000.0; // starting paper cash for portfolio stubs

}
