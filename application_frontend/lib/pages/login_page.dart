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

import 'package:auth0_flutter/auth0_flutter.dart'; // import Auth0 web-auth exceptions
import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../config.dart'; // import app name / tagline
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import shared Auth0 / API services
import '../theme/app_theme.dart'; // import brand color tokens





/*##################################################*/
/*############### LOGIN PAGE #######################*/
/*##################################################*/


/*########## LOGIN PAGE ##########*/

class LoginPage extends StatefulWidget { // class for Auth0 sign-in with paper-trading footer

  const LoginPage({super.key}); // default const constructor

  @override
  State<LoginPage> createState() => _LoginPageState(); // create state

}


/*########## LOGIN PAGE STATE ##########*/

class _LoginPageState extends State<LoginPage> { // class to run Auth0 login + show errors

  bool _busy = false; // disable CTA while Universal Login is open
  String? _error; // last login failure message

  /*########## SIGN IN ##########*/

  Future<void> _signIn() async { // function to Auth0 login then route to onboarding

    if (_busy) { // already in progress
      return; // ignore double taps
    }
    setState(() {
      _busy = true; // lock CTA
      _error = null; // clear prior error
    });
    try {
      await authService.login(); // Universal Login + PKCE
      syncApiAccessToken(); // attach Bearer for EC2 calls
      if (!mounted) { // left page during await
        return; // bail
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding); // post-login flow
    } on WebAuthenticationException catch (e) {
      if (!mounted) { // disposed
        return; // bail
      }
      if (e.code == 'USER_CANCELLED' || e.code == 'a0.session.user_cancelled') {
        setState(() {
          _busy = false; // unlock CTA
        });
        return; // no error banner for cancel
      }
      setState(() {
        _busy = false; // unlock CTA
        final detail = e.details.isEmpty ? '' : '\n${e.details}'; // Auth0 payload
        _error =
            '${e.code}: ${e.message}$detail\n\n'
            'If the browser shows a black soothsayer:// page, copy the full URL — '
            'it contains error_description. Also check Auth0 → Monitoring → Logs. '
            'Prefer Chrome as the default browser (DuckDuckGo breaks the redirect).';
      });
    } catch (e) {
      if (!mounted) { // disposed
        return; // bail
      }
      setState(() {
        _busy = false; // unlock CTA
        _error = e.toString(); // show setup / network error
      });
    }

  }

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
                  onPressed: _busy ? null : _signIn, // Auth0 Universal Login
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign in with Auth0'), // primary CTA
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16), // spacer
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ), // login error
              ],
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
