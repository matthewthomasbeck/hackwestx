/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import 'config.dart'; // import app name / API config
import 'routes.dart'; // import named routes map
import 'services/app_services.dart'; // import themeStore / marketStore / apiService
import 'theme/app_theme.dart'; // import light / dark ThemeData





/*##################################################*/
/*############### APPLICATION ENTRY ################*/
/*##################################################*/


/*########## MAIN ##########*/

void main() { // function to boot Solana Soothsayer Flutter app

  runApp(const SoothsayerApp()); // mount root widget

}


/*########## SOOTHSAYER APP ##########*/

class SoothsayerApp extends StatefulWidget { // class to own MaterialApp theme + routes + resume reload

  const SoothsayerApp({super.key}); // default const constructor

  @override
  State<SoothsayerApp> createState() => _SoothsayerAppState(); // create state

}


/*########## SOOTHSAYER APP STATE ##########*/

class _SoothsayerAppState extends State<SoothsayerApp> with WidgetsBindingObserver { // class to revalidate market on foreground

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to listen for app lifecycle (resume)

    super.initState(); // Flutter init
    WidgetsBinding.instance.addObserver(this); // resume → re-GET /market

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to drop lifecycle observer

    WidgetsBinding.instance.removeObserver(this); // avoid leaks
    super.dispose(); // Flutter dispose

  }

  /*########## DID CHANGE APP LIFECYCLE STATE ##########*/

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { // function to reload market when app returns

    if (state != AppLifecycleState.resumed) { // only care about foreground
      return; // ignore pause/inactive/detached
    }
    // Force a fresh GET so a Tiger wipe while backgrounded cannot leave a stale chart in RAM
    final token = apiService.accessToken; // current Bearer
    if (token == null || token.isEmpty) { // not logged in yet
      return; // splash / login owns first fetch
    }
    () async { // fire-and-forget resume revalidate
      try {
        await marketStore.load(silent: true); // overwrite RAM snapshot from EC2
      } catch (_) {
        // keep last snapshot if offline; next pull-to-refresh can retry
      }
    }();

  }

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
