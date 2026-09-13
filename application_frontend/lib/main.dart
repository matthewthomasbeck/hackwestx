/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import 'config.dart'; // import app name / API config
import 'routes.dart'; // import named routes map
import 'theme/app_theme.dart'; // import light / dark ThemeData





/*##################################################*/
/*############### APPLICATION ENTRY ################*/
/*##################################################*/


/*########## MAIN ##########*/

void main() { // function to boot Solana Soothsayer Flutter app

  runApp(const SoothsayerApp()); // mount root widget

}


/*########## SOOTHSAYER APP ##########*/

class SoothsayerApp extends StatelessWidget { // class to own MaterialApp theme + routes

  const SoothsayerApp({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build MaterialApp shell

    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: AppRoutes.loading,
      routes: AppRoutes.routes,
    ); // skeleton MaterialApp

  }

}
