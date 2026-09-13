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

import '../config.dart'; // import app name / tagline
import '../routes.dart'; // import named route constants
import '../theme/app_theme.dart'; // import brand color tokens





/*##################################################*/
/*############### LOGIN PAGE #######################*/
/*##################################################*/


/*########## LOGIN PAGE ##########*/

class LoginPage extends StatelessWidget { // class for Auth0 sign-in with paper-trading footer

  const LoginPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build login layout

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(), // push brand toward vertical center
              Text(
                AppConfig.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ), // app name hero
              const SizedBox(height: 8), // spacer
              Text(
                AppConfig.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ), // one-line tagline
              const SizedBox(height: 40), // spacer before CTA
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.blue],
                  ), // purple → blue CTA
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: call AuthService.login() then branch onboarding vs home
                    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
                  }, // scaffolding: go to onboarding after "sign in"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Sign in with Auth0'), // primary CTA
                ),
              ),
              const Spacer(), // push footer down
              Text(
                'Paper trading only — no real SOL is purchased.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ), // disclaimer footer
            ],
          ),
        ),
      ),
    ); // login scaffold

  }

}
