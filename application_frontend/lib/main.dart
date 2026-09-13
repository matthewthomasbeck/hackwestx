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
      title: AppConfig.appName, // window / task title
      debugShowCheckedModeBanner: false, // hide debug banner for demos
      theme: AppTheme.light, // purple / blue / green light theme
      darkTheme: AppTheme.dark, // night-mode trading theme
      themeMode: ThemeMode.system, // follow OS until settings toggle is wired
      initialRoute: AppRoutes.loading, // start on loading / splash
      routes: AppRoutes.routes, // named route → page map
    ); // root MaterialApp

  }

}
