/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### AUTH SERVICE (STUB) ##############*/
/*##################################################*/


/*########## AUTH USER ##########*/

class AuthUser { // class to hold minimal logged-in user fields for settings / headers

  const AuthUser({
    required this.sub,
    this.email,
    this.name,
  }); // construct from Auth0 claims once wired

  final String sub; // Auth0 subject
  final String? email; // optional email claim
  final String? name; // optional name / nickname claim

}


/*########## AUTH SERVICE ##########*/

class AuthService { // class to stub Auth0 login / logout until native SDK is wired

  AuthUser? _user; // in-memory session user
  String? _accessToken; // in-memory Bearer token

  AuthUser? get user => _user; // current user or null
  String? get accessToken => _accessToken; // current token or null
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty; // session check

  /*########## LOGIN ##########*/

  Future<AuthUser> login() async { // function to perform Auth0 login (stub for scaffolding)

    // TODO: wire flutter_appauth / Auth0 Universal Login here
    _accessToken = 'stub-access-token'; // placeholder Bearer for local UI navigation
    _user = const AuthUser(
      sub: 'auth0|stub',
      email: 'trader@example.com',
      name: 'Paper Trader',
    ); // placeholder profile
    return _user!; // return stub user

  }

  /*########## LOGOUT ##########*/

  Future<void> logout() async { // function to clear local Auth0 session (stub)

    // TODO: clear Auth0 credentials / secure storage
    _accessToken = null; // drop token
    _user = null; // drop profile

  }

}
