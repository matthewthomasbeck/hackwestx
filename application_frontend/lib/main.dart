/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import 'config.dart'; // import app name / API config
import 'routes.dart'; // import named routes map
import 'services/app_services.dart'; // import themeStore for live ThemeMode
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

    return ListenableBuilder(
      listenable: themeStore, // rebuild when Settings toggles dark/light
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName, // window / task title
          debugShowCheckedModeBanner: false, // hide debug banner for demos
          theme: AppTheme.light, // near-white Solana light theme
          darkTheme: AppTheme.dark, // near-black Solana dark theme
          themeMode: themeStore.mode, // Settings-driven ThemeMode
          initialRoute: AppRoutes.loading, // start on loading / splash
          routes: AppRoutes.routes, // named route → page map
        ); // root MaterialApp
      },
    );

  }

}
