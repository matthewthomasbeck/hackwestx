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
/*############### HOME PAGE ########################*/
/*##################################################*/


/*########## HOME PAGE ##########*/

class HomePage extends StatelessWidget { // class for SOL chart home + quick actions

  const HomePage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build home chart scaffold

    return const Scaffold(
      body: Center(child: Text('Home')),
    ); // skeleton

  }

}
