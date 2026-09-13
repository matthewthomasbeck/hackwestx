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
import '../services/app_services.dart'; // import Auth0 session + market store
import '../theme/app_theme.dart'; // import brand color tokens





/*##################################################*/
/*############### LOADING PAGE #####################*/
/*##################################################*/


/*########## LOADING PAGE ##########*/

class LoadingPage extends StatefulWidget { // class for splash with Solana logo pulse + status text

  const LoadingPage({super.key}); // default const constructor

  @override
  State<LoadingPage> createState() => _LoadingPageState(); // create state

}


/*########## LOADING PAGE STATE ##########*/

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin { // class to drive pulse animation + bootstrap navigation

  late final AnimationController _pulse; // logo glow pulse controller
  String _status = 'Loading market data...'; // status line under logo

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to start pulse + auth / market bootstrap

    super.initState(); // Flutter init
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // subtle looping pulse

    _bootstrap(); // kick off auth + first /market resolve

  }

  /*########## BOOTSTRAP ##########*/

  Future<void> _bootstrap() async { // function to restore Auth0, fetch market, then navigate

    await Future<void>.delayed(const Duration(milliseconds: 600)); // brief splash delay
    if (!mounted) { // disposed during await
      return; // bail
    }
    setState(() {
      _status = 'Checking session...'; // update status copy
    });
    final loggedIn = await authService.restoreSession(); // Credentials Manager
    if (!mounted) { // disposed during await
      return; // bail
    }
    if (!loggedIn) { // need Universal Login
      Navigator.of(context).pushReplacementNamed(AppRoutes.login); // go login
      return; // done
    }

    syncApiAccessToken(); // attach Bearer for EC2
    setState(() {
      _status = 'Loading market data...'; // fetch copy
    });

    try {
      final payload = await marketStore.ensureData(); // GET /market (+ refresh if empty)
      if (!mounted) { // disposed during await
        return; // bail
      }
      final current = marketStore.market ?? payload; // prefer store after refresh
      if (current.isEmpty) { // still empty after refresh kickoff
        Navigator.of(context).pushReplacementNamed(AppRoutes.empty); // empty status
        return; // done
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.home); // pending or ready → home
    } catch (_) {
      if (!mounted) { // disposed
        return; // bail
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.error); // network / auth failure
    }

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to stop pulse animation

    _pulse.dispose(); // free ticker
    super.dispose(); // Flutter dispose

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build centered logo + status splash

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF1A1040),
              Color(0xFF0D1B2A),
            ],
          ), // purple / blue night gradient
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.55, end: 1.0).animate(_pulse),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.05).animate(_pulse),
                child: Icon(
                  Icons.currency_bitcoin, // placeholder until Solana asset logo is added
                  size: 88,
                  color: AppColors.purple.withValues(alpha: 0.95),
                  shadows: [
                    Shadow(
                      color: AppColors.blue.withValues(alpha: 0.65),
                      blurRadius: 24,
                    ), // slight glow
                  ],
                ), // pulsing center mark
              ),
            ),
            const SizedBox(height: 28), // spacer under logo
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ), // status under logo
          ],
        ),
      ),
    ); // splash scaffold

  }

}
