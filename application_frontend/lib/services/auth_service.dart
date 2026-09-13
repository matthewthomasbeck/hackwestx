/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### AUTH SERVICE #####################*/
/*##################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'dart:convert'; // import JWT payload decode helpers

/*##### import third-party libraries #####*/

import 'package:auth0_flutter/auth0_flutter.dart'; // import Auth0 Universal Login SDK
import 'package:flutter/foundation.dart'; // import debugPrint for auth diagnostics

/*##### import local modules #####*/

import '../config.dart'; // import Auth0 domain / client / audience / scheme





/*########## AUTH USER ##########*/

class AuthUser { // class to hold minimal logged-in user fields for settings / headers

  const AuthUser({
    required this.sub,
    this.email,
    this.name,
  }); // construct from Auth0 claims

  final String sub; // Auth0 subject
  final String? email; // optional email claim
  final String? name; // optional name / nickname claim

}


/*########## AUTH SERVICE ##########*/

class AuthService { // class to run Auth0 Universal Login and hold the session

  AuthUser? _user; // in-memory session user
  String? _accessToken; // in-memory Bearer token for ApiService
  Auth0? _auth0; // lazy Auth0 client

  AuthUser? get user => _user; // current user or null
  String? get accessToken => _accessToken; // current token or null
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty; // session check

  /*########## CLIENT ##########*/

  Auth0 _client() { // function to build / cache Auth0 from dart-define config

    final existing = _auth0; // cached client
    if (existing != null) { // already constructed
      return existing; // reuse
    }
    final domain = AppConfig.auth0Domain.trim(); // tenant host
    final clientId = AppConfig.auth0ClientId.trim(); // Native app client id
    if (domain.isEmpty || clientId.isEmpty) { // missing build-time config
      throw StateError(
        'Set AUTH0_DOMAIN and AUTH0_CLIENT_ID via --dart-define '
        '(and auth0Domain in android/local.properties for Android).',
      ); // fail with setup hint
    }
    final client = Auth0(domain, clientId); // Universal Login client
    _auth0 = client; // cache
    return client; // ready client

  }

  /*########## JWT PAYLOAD ##########*/

  Map<String, dynamic>? _jwtPayload(String token) { // function to decode JWT claims (no verify)

    final parts = token.split('.'); // header.payload.sig
    if (parts.length < 2) { // opaque / non-JWT
      return null; // cannot read aud
    }
    try {
      final normalized = base64Url.normalize(parts[1]); // pad payload segment
      final json = utf8.decode(base64Url.decode(normalized)); // claim JSON
      return jsonDecode(json) as Map<String, dynamic>; // claims map
    } catch (_) {
      return null; // malformed token
    }

  }

  /*########## AUDIENCE CHECK ##########*/

  bool _tokenMatchesApiAudience(String token) { // function to require API aud when configured

    if (!AppConfig.requestApiAudience) { // login without API audience
      return true; // any token is fine
    }
    final expected = AppConfig.auth0Audience.trim(); // https://hackwestx.user.auth
    final payload = _jwtPayload(token); // decode access token
    if (payload == null) { // opaque token cannot call our API as JWT
      return false; // force re-login with audience
    }
    final aud = payload['aud']; // string or list
    if (aud is String) { // single audience
      return aud == expected; // exact API identifier
    }
    if (aud is List) { // multi-aud token
      return aud.map((e) => e.toString()).contains(expected); // contains API
    }
    return false; // missing aud

  }

  /*########## APPLY CREDENTIALS ##########*/

  void _applyCredentials(Credentials credentials) { // function to mirror SDK creds into memory

    _accessToken = credentials.accessToken; // API Bearer for EC2
    final profile = credentials.user; // ID-token profile
    _user = AuthUser(
      sub: profile.sub,
      email: profile.email,
      name: profile.name ?? profile.nickname,
    ); // settings / UI profile

  }

  /*########## CLEAR LOCAL ##########*/

  void _clearLocal() { // function to drop in-memory session without calling Auth0

    _accessToken = null; // drop token
    _user = null; // drop profile

  }

  /*########## WEB AUTH ##########*/

  WebAuthentication _webAuth(Auth0 auth0) { // function to build Android/iOS web auth (prefer Chrome)

    return auth0.webAuthentication(scheme: AppConfig.auth0Scheme.trim()); // custom scheme

  }

  /*########## RESTORE SESSION ##########*/

  Future<bool> restoreSession() async { // function to reload stored Auth0 credentials if valid

    try {
      final auth0 = _client(); // need configured client
      final hasValid = await auth0.credentialsManager.hasValidCredentials(); // secure store check
      if (!hasValid) { // nothing usable
        _clearLocal(); // ensure clean
        return false; // send to login
      }
      final credentials = await auth0.credentialsManager.credentials(); // refresh if needed
      if (!_tokenMatchesApiAudience(credentials.accessToken)) { // leftover none-audience session
        debugPrint(
          'Auth0 restored token missing API audience '
          '${AppConfig.auth0Audience}; clearing session.',
        ); // explain skip-to-home confusion
        await auth0.credentialsManager.clearCredentials(); // drop bad session
        _clearLocal(); // clear memory
        return false; // force Universal Login with audience
      }
      _applyCredentials(credentials); // hydrate memory
      return isLoggedIn; // true when token present
    } catch (_) {
      _clearLocal(); // treat misconfig / plugin errors as logged out
      return false; // splash → login
    }

  }

  /*########## LOGIN ##########*/

  Future<AuthUser> login() async { // function to open Auth0 Universal Login (PKCE)

    final auth0 = _client(); // configured Native app
    final domain = AppConfig.auth0Domain.trim(); // must match android auth0Domain
    final scheme = AppConfig.auth0Scheme.trim(); // e.g. soothsayer
    final audience =
        AppConfig.requestApiAudience ? AppConfig.auth0Audience.trim() : null;
    debugPrint(
      'Auth0 login domain=$domain scheme=$scheme audience=${audience ?? '(none)'}',
    ); // log exact audience requested
    final credentials = await _webAuth(auth0)
        .login(
          useHTTPS: true, // iOS Universal Links when available; Android uses scheme
          audience: audience, // null skips API token (connection debug)
          // Prefer Chrome — DuckDuckGo often fails custom-scheme callbacks (black screen).
          customTabsOptions: const CustomTabsOptions(
            allowedBrowsers: [
              'com.android.chrome',
              'com.chrome.beta',
              'com.chrome.dev',
            ],
          ),
          scopes: {
            'openid',
            'profile',
            'email',
            // Refresh tokens: keep when API offline access is enabled in Auth0.
            if (audience != null) 'offline_access',
          }, // OIDC (+ refresh when calling API)
          parameters: const {
            'prompt': 'login', // avoid silent SSO reuse after logout
          },
        )
        .timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw StateError(
            'Auth0 login timed out. On Android, set auth0Domain=$domain in '
            'android/local.properties (same as AUTH0_DOMAIN), stop the app, '
            'and fully re-run flutter run — hot reload will not fix redirects. '
            'Also confirm Auth0 Allowed Callback URLs include '
            '$scheme://$domain/android/${AppConfig.packageId}/callback',
          ),
        ); // browser / Custom Tab login
    if (!_tokenMatchesApiAudience(credentials.accessToken)) { // got token but wrong/missing aud
      throw StateError(
        'Login succeeded but access token aud is not ${AppConfig.auth0Audience}. '
        'Check Auth0 API Identifier and Monitoring → Logs.',
      ); // surface misconfigured API audience
    }
    _applyCredentials(credentials); // store access token + profile
    return _user!; // logged-in user

  }

  /*########## LOGOUT ##########*/

  Future<void> logout() async { // function to clear Auth0 session + local token

    try {
      final auth0 = _client(); // configured client
      await auth0.credentialsManager.clearCredentials(); // drop secure store first
      await _webAuth(auth0).logout(
        useHTTPS: true, // match login redirect style
        customTabsOptions: const CustomTabsOptions(
          allowedBrowsers: [
            'com.android.chrome',
            'com.chrome.beta',
            'com.chrome.dev',
          ],
        ),
      ); // Auth0 logout
    } catch (_) {
      // Still clear local state if Auth0 logout / config fails
    }
    _clearLocal(); // drop in-memory session

  }

}
