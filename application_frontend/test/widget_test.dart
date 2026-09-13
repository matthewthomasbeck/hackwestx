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
import 'package:soothsayer/pages/login_page.dart'; // import login for post-splash assert





/*##################################################*/
/*############### WIDGET TESTS #####################*/
/*##################################################*/


/*########## SMOKE TEST ##########*/

void main() { // function to run frontend scaffolding smoke tests

  testWidgets('app boots to loading then login', (WidgetTester tester) async { // smoke: splash → login

    await tester.pumpWidget(const SoothsayerApp()); // mount app
    expect(find.textContaining('Loading'), findsOneWidget); // splash status visible

    await tester.pump(const Duration(milliseconds: 1600)); // advance bootstrap timers
    await tester.pumpAndSettle(); // finish navigation animation

    expect(find.byType(LoginPage), findsOneWidget); // landed on login scaffolding
    expect(find.text('Sign in with Auth0'), findsOneWidget); // primary CTA present

  });

}
