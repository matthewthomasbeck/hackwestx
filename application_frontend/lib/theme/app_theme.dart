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

class AppColors { // class to hold Solana pastels + extreme light/dark neutrals

  /*##### Solana pastels (gradient order: purple → cyan → green) #####*/

  static const solanaGreen = Color(0xFF79BF65); // Solana green pastel
  static const solanaCyan = Color(0xFF43779E); // Solana cyan pastel
  static const solanaPurple = Color(0xFF694B87); // Solana purple pastel

  /*##### Dark mode neutrals (3 blacks; darkest → lightest) #####*/

  static const blackDarkest = Color(0xFF000000); // pure black
  static const blackMid = Color(0xFF141414); // elevated dark surface
  static const blackLightest = Color(0xFF2E2E2E); // lightest dark shade

  /*##### Light mode neutrals (3 whites; darkest → lightest) #####*/

  static const whiteDarkest = Color(0xFFE0E0E0); // darkest light shade
  static const whiteMid = Color(0xFFF2F2F2); // elevated light surface
  static const whiteLightest = Color(0xFFFFFFFF); // pure white

  /*##### Semantic / legacy aliases #####*/

  static const purple = solanaPurple; // brand primary
  static const blue = solanaCyan; // brand secondary
  static const green = solanaGreen; // bullish / success
  static const red = Color(0xFFC62828); // bearish / error (kept readable)

  /*##### Shared Solana diagonal gradient #####*/

  static const solanaDiagonal = LinearGradient(
    begin: Alignment.bottomLeft, // purple lower-left
    end: Alignment.topRight, // green upper-right
    colors: [
      solanaPurple,
      solanaCyan,
      solanaGreen,
    ], // purple → cyan → green
  ); // used by chart bg + home nav buttons

  /*########## CHART LINE COLORS ##########*/

  static Color chartRealLine(Brightness brightness) { // function to pick real-series stroke by mode

    return brightness == Brightness.dark
        ? blackDarkest // dark mode: darkest black
        : whiteLightest; // light mode: pure white

  }

  static Color chartPredictionLine(Brightness brightness) { // function to pick forecast stroke by mode

    return brightness == Brightness.dark
        ? whiteMid // dark mode: middle light
        : blackMid; // light mode: middle dark

  }

  static Color chartPredictionDot(Brightness brightness) { // function to pick forecast marker fill by mode

    return brightness == Brightness.dark
        ? whiteLightest // dark mode: #FFFFFF
        : blackDarkest; // light mode: #000000

  }

  static Color timeframeSelectedFill(Brightness brightness) { // function to pick selected 1W..Max chip fill

    return brightness == Brightness.dark
        ? blackMid // dark mode: middle dark
        : whiteMid; // light mode: middle light

  }

  static Color timeframeSelectedForeground(Brightness brightness) { // function to pick selected chip label color

    return brightness == Brightness.dark
        ? whiteLightest // light text on dark mid
        : blackDarkest; // dark text on light mid

  }

}





/*##################################################*/
/*############### THEME DATA #######################*/
/*##################################################*/


/*########## APP THEME ##########*/

class AppTheme { // class to build light / dark ThemeData for MaterialApp

  /*########## LIGHT THEME ##########*/

  static ThemeData get light { // function to build near-white light theme

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.solanaPurple,
      onPrimary: AppColors.whiteLightest,
      secondary: AppColors.solanaCyan,
      onSecondary: AppColors.whiteLightest,
      tertiary: AppColors.solanaGreen,
      onTertiary: AppColors.blackDarkest,
      error: AppColors.red,
      onError: AppColors.whiteLightest,
      surface: AppColors.whiteLightest,
      onSurface: AppColors.blackDarkest,
      surfaceContainerHighest: AppColors.whiteDarkest,
      onSurfaceVariant: const Color(0xFF4A4A4A),
    ); // extreme-light scheme on Solana accents

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.whiteMid, // soft near-white canvas
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.whiteLightest,
        foregroundColor: AppColors.blackDarkest,
        elevation: 0,
      ), // flat light app bars
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaPurple
              : AppColors.whiteDarkest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaPurple.withValues(alpha: 0.45)
              : AppColors.whiteDarkest,
        ),
      ), // purple active switch
    ); // light ThemeData

  }

  /*########## DARK THEME ##########*/

  static ThemeData get dark { // function to build near-black dark theme

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.solanaPurple,
      onPrimary: AppColors.whiteLightest,
      secondary: AppColors.solanaCyan,
      onSecondary: AppColors.whiteLightest,
      tertiary: AppColors.solanaGreen,
      onTertiary: AppColors.blackDarkest,
      error: AppColors.red,
      onError: AppColors.whiteLightest,
      surface: AppColors.blackMid,
      onSurface: AppColors.whiteLightest,
      surfaceContainerHighest: AppColors.blackLightest,
      onSurfaceVariant: const Color(0xFFB0B0B0),
    ); // extreme-dark scheme on Solana accents

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.blackDarkest, // pure black canvas
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blackMid,
        foregroundColor: AppColors.whiteLightest,
        elevation: 0,
      ), // flat dark app bars
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaPurple
              : AppColors.blackLightest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaPurple.withValues(alpha: 0.55)
              : AppColors.blackLightest,
        ),
      ), // purple active switch
    ); // dark ThemeData

  }

}
