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


/*########## AUTH USER ##########*/

class AuthUser { // class to hold minimal logged-in user fields

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

class AuthService { // class to handle Auth0 login / logout

  AuthUser? get user => null; // skeleton
  String? get accessToken => null; // skeleton
  bool get isLoggedIn => false; // skeleton

  /*########## LOGIN ##########*/

  Future<AuthUser> login() async { // function to perform Auth0 login

    return const AuthUser(sub: ''); // skeleton

  }

  /*########## LOGOUT ##########*/

  Future<void> logout() async { // function to clear local Auth0 session

    // skeleton

  }

}
