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
/*############### THEME COLORS #####################*/
/*##################################################*/


/*########## APP COLORS ##########*/

class AppColors { // class to hold purple / blue / green palette tokens

  static const purple = Color(0xFF7C4DFF); // primary purple accent
  static const blue = Color(0xFF2979FF); // secondary blue accent
  static const green = Color(0xFF00E676); // bullish / success green
  static const red = Color(0xFFFF5252); // bearish / error red

}





/*##################################################*/
/*############### THEME DATA #######################*/
/*##################################################*/


/*########## APP THEME ##########*/

class AppTheme { // class to build light / dark ThemeData for MaterialApp

  /*########## LIGHT THEME ##########*/

  static ThemeData get light { // function to build light-mode theme with purple/blue seed

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.light,
      secondary: AppColors.blue,
      tertiary: AppColors.green,
    ); // Material 3 scheme from brand seed

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6FF), // soft light background
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ), // flat app bars for trading aesthetic
    ); // light ThemeData

  }

  /*########## DARK THEME ##########*/

  static ThemeData get dark { // function to build dark-mode theme with purple/blue glow feel

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.dark,
      secondary: AppColors.blue,
      tertiary: AppColors.green,
    ); // Material 3 dark scheme from brand seed

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B0F1A), // night-mode background
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ), // flat app bars for trading aesthetic
    ); // dark ThemeData

  }

}
