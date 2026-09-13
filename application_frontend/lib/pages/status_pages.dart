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
/*############### STATUS PAGES #####################*/
/*##################################################*/


/*########## EMPTY STATUS PAGE ##########*/

class EmptyStatusPage extends StatelessWidget { // class for empty market-data state

  const EmptyStatusPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build empty market state

    return const Scaffold(
      body: Center(child: Text('Empty')),
    ); // skeleton

  }

}


/*########## PENDING STATUS PAGE ##########*/

class PendingStatusPage extends StatelessWidget { // class for predictions_pending state

  const PendingStatusPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build pending predictions state

    return const Scaffold(
      body: Center(child: Text('Pending')),
    ); // skeleton

  }

}


/*########## ERROR STATUS PAGE ##########*/

class ErrorStatusPage extends StatelessWidget { // class for network / auth error state

  const ErrorStatusPage({
    super.key,
    this.message = 'Something went wrong talking to the backend.',
  }); // optional custom message

  final String message; // error copy

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build error / retry state

    return const Scaffold(
      body: Center(child: Text('Error')),
    ); // skeleton

  }

}
