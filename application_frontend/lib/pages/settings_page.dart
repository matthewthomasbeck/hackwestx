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

import '../routes.dart'; // import named route constants





/*##################################################*/
/*############### SETTINGS PAGE ####################*/
/*##################################################*/


/*########## SETTINGS PAGE ##########*/

class SettingsPage extends StatefulWidget { // class for profile / theme / reset / logout

  const SettingsPage({super.key}); // default const constructor

  @override
  State<SettingsPage> createState() => _SettingsPageState(); // create state

}


/*########## SETTINGS PAGE STATE ##########*/

class _SettingsPageState extends State<SettingsPage> { // class to hold local theme toggle stub

  bool _darkMode = true; // local dark toggle until ThemeMode is app-wide

  /*########## RESET PAPER ##########*/

  Future<void> _confirmReset() async { // function to confirm paper account reset dialog

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset paper account?'),
        content: const Text(
          'This clears paper cash, holdings, and trade history back to the starting balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    ); // confirm dialog
    if (ok == true) {
      // TODO: call paper reset API / clear local ledger
    }

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build settings list

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Paper Trader'), // Auth0 name stub
            subtitle: Text('trader@example.com'), // Auth0 email stub
            leading: Icon(Icons.person_outline),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v), // TODO: lift ThemeMode to app root
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset paper account'),
            onTap: _confirmReset,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Onboarding / help'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.onboarding),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App version'),
            subtitle: Text('1.0.0+1'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              // TODO: AuthService.logout() then clear token on ApiService
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
    ); // settings scaffold

  }

}
