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





/*##################################################*/
/*############### LOGIN PAGE #######################*/
/*##################################################*/


/*########## LOGIN PAGE ##########*/

class LoginPage extends StatelessWidget { // class for Auth0 sign-in screen

  const LoginPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build login layout

    return const Scaffold(
      body: Center(child: Text('Login')),
    ); // skeleton

  }

}
