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

import 'package:flutter/material.dart'; // import Flutter Material theming





/*##################################################*/
/*############### THEME ############################*/
/*##################################################*/


/*########## APP COLORS ##########*/

class AppColors { // class to hold purple / blue / green palette tokens

  static const purple = Color(0xFF7C4DFF); // primary purple
  static const blue = Color(0xFF2979FF); // secondary blue
  static const green = Color(0xFF00E676); // success / bullish
  static const red = Color(0xFFFF5252); // error / bearish

}


/*########## APP THEME ##########*/

class AppTheme { // class to build light / dark ThemeData for MaterialApp

  /*########## LIGHT THEME ##########*/

  static ThemeData get light { // function to build light-mode theme

    return ThemeData(); // skeleton

  }

  /*########## DARK THEME ##########*/

  static ThemeData get dark { // function to build dark-mode theme

    return ThemeData.dark(); // skeleton

  }

}
