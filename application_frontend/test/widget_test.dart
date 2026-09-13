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

import 'package:flutter_test/flutter_test.dart'; // import Flutter widget tester

/*##### import local modules #####*/

import 'package:soothsayer/main.dart'; // import SoothsayerApp root





/*##################################################*/
/*############### WIDGET TESTS #####################*/
/*##################################################*/


/*########## SMOKE TEST ##########*/

void main() { // function to run frontend scaffolding smoke tests

  testWidgets('app boots', (WidgetTester tester) async { // smoke: app mounts

    await tester.pumpWidget(const SoothsayerApp()); // mount app
    // skeleton

  });

}
