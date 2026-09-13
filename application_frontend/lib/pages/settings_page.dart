/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import Auth0 profile / logout
import '../theme/app_theme.dart'; // import light/dark neutral switch colors





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

class _SettingsPageState extends State<SettingsPage> { // class for profile / theme / logout actions

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
      portfolioStore.reset(); // clear local paper cash / holdings / history
      if (!mounted) { // disposed during dialog
        return; // bail
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper account reset to \$10,000')),
      ); // confirm reset
    }

  }

  Future<void> _logout() async { // function to Auth0 logout then return to login

    await authService.logout(); // clear Auth0 + local session
    syncApiAccessToken(); // drop Bearer on ApiService
    if (!mounted) { // disposed during await
      return; // bail
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    ); // back to sign-in

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build settings list

    final profile = authService.user; // Auth0 profile snapshot
    final displayName = profile?.name ?? 'Paper Trader'; // fallback label
    final displayEmail = profile?.email ?? 'Signed in'; // fallback subtitle

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListenableBuilder(
        listenable: themeStore, // live dark/light switch
        builder: (context, _) {
          return ListView(
            children: [
              ListTile(
                title: Text(displayName), // Auth0 name
                subtitle: Text(displayEmail), // Auth0 email
                leading: const Icon(Icons.person_outline),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeModeChip(
                            label: 'Dark mode',
                            selected: themeStore.isDark,
                            useDarkColors: true, // dark neutrals on this chip
                            onTap: () => themeStore.setDarkMode(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ThemeModeChip(
                            label: 'Light mode',
                            selected: !themeStore.isDark,
                            useDarkColors: false, // light neutrals on this chip
                            onTap: () => themeStore.setDarkMode(false),
                          ),
                        ),
                      ],
                    ), // Dark / Light chips — selected state moves with theme
                  ],
                ),
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
                onTap: _logout,
              ),
            ],
          ); // settings list
        },
      ),
    ); // settings scaffold

  }

}


/*########## THEME MODE CHIP ##########*/

class _ThemeModeChip extends StatelessWidget { // class for Dark / Light appearance picker chip

  const _ThemeModeChip({
    required this.label,
    required this.selected,
    required this.useDarkColors,
    required this.onTap,
  }); // construct chip

  final String label; // Dark mode / Light mode
  final bool selected; // currently active theme
  final bool useDarkColors; // true → black neutrals, false → white neutrals
  final VoidCallback onTap; // select this mode

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build one themed mode chip

    final bg = useDarkColors ? AppColors.blackMid : AppColors.whiteMid; // chip fill
    final fg = useDarkColors ? AppColors.whiteLightest : AppColors.blackDarkest; // chip text
    final border = selected
        ? AppColors.solanaCyan
        : (useDarkColors ? AppColors.blackLightest : AppColors.whiteDarkest); // selected ring

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 2.5 : 1.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ),
      ),
    ); // dark-colored or light-colored mode chip

  }

}
