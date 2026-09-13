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

  /*##### Soft multi-hue glow matching the Solana gradient #####*/

  static List<BoxShadow> solanaGlow({double strength = 1}) { // function to build soft purple/cyan/green glow

    final s = strength.clamp(0.0, 2.0); // scale blur / alpha
    return [
      BoxShadow(
        color: solanaPurple.withValues(alpha: 0.42 * s),
        blurRadius: 22 * s,
        spreadRadius: 1,
        offset: const Offset(-4, 6),
      ), // purple corner glow
      BoxShadow(
        color: solanaCyan.withValues(alpha: 0.34 * s),
        blurRadius: 20 * s,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ), // cyan mid glow
      BoxShadow(
        color: solanaGreen.withValues(alpha: 0.38 * s),
        blurRadius: 22 * s,
        spreadRadius: 1,
        offset: const Offset(4, -4),
      ), // green corner glow
    ]; // soft Solana aura

  }

  /*########## CHART LINE COLORS ##########*/

  static Color chartRealLine(Brightness brightness) { // function to pick real-series stroke by mode

    return brightness == Brightness.dark
        ? whiteDarkest // dark mode: dimmest white shade
        : blackDarkest; // light mode: dimmest / darkest black shade

  }

  static Color onSolanaGradient(Brightness brightness) { // function to pick text/icons on gradient buttons

    return brightness == Brightness.dark
        ? whiteLightest // dark mode: white
        : blackDarkest; // light mode: black

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

  /*########## SCALE TEXT STYLE ##########*/

  static TextStyle? _scaleStyle(TextStyle? style, {double factor = 2.0}) { // function to 2× one style safely

    if (style == null) { // missing style
      return null; // keep null
    }
    final size = style.fontSize; // may be null on some M3 slots
    if (size == null) { // apply() asserts when fontSize is null
      return style; // leave unscaled rather than crash
    }
    return style.copyWith(fontSize: size * factor); // double readable size

  }

  /*########## SCALE TEXT THEME ##########*/

  static TextTheme _doubledText(TextTheme base) { // function to 2× all non-null text sizes for readability

    return TextTheme(
      displayLarge: _scaleStyle(base.displayLarge),
      displayMedium: _scaleStyle(base.displayMedium),
      displaySmall: _scaleStyle(base.displaySmall),
      headlineLarge: _scaleStyle(base.headlineLarge),
      headlineMedium: _scaleStyle(base.headlineMedium),
      headlineSmall: _scaleStyle(base.headlineSmall),
      titleLarge: _scaleStyle(base.titleLarge),
      titleMedium: _scaleStyle(base.titleMedium),
      titleSmall: _scaleStyle(base.titleSmall),
      bodyLarge: _scaleStyle(base.bodyLarge),
      bodyMedium: _scaleStyle(base.bodyMedium),
      bodySmall: _scaleStyle(base.bodySmall),
      labelLarge: _scaleStyle(base.labelLarge),
      labelMedium: _scaleStyle(base.labelMedium),
      labelSmall: _scaleStyle(base.labelSmall),
    ); // safe 2× without apply() null-fontSize assert

  }

  /*########## LIGHT THEME ##########*/

  static ThemeData get light { // function to build near-white light theme

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.solanaCyan,
      onPrimary: AppColors.whiteLightest,
      secondary: AppColors.solanaGreen,
      onSecondary: AppColors.blackDarkest,
      tertiary: AppColors.solanaPurple,
      onTertiary: AppColors.whiteLightest,
      error: AppColors.red,
      onError: AppColors.whiteLightest,
      surface: AppColors.whiteLightest,
      onSurface: AppColors.blackDarkest,
      surfaceContainerHighest: AppColors.whiteDarkest,
      onSurfaceVariant: const Color(0xFF4A4A4A),
    ); // extreme-light scheme on Solana accents

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    ); // seed Material text themes

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.whiteMid, // soft near-white canvas
      textTheme: _doubledText(base.textTheme), // app-wide 2× type
      primaryTextTheme: _doubledText(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.whiteLightest,
        foregroundColor: AppColors.blackDarkest,
        elevation: 0,
        titleTextStyle: _doubledText(base.textTheme).titleLarge?.copyWith(
              color: AppColors.blackDarkest,
              fontWeight: FontWeight.w700,
            ),
      ), // flat light app bars
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.solanaCyan,
          foregroundColor: AppColors.whiteLightest,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ), // cyan CTAs instead of harsh purple
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaCyan
              : AppColors.whiteDarkest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaCyan.withValues(alpha: 0.45)
              : AppColors.whiteDarkest,
        ),
      ), // cyan active switch (settings overrides for mode toggle)
    ); // light ThemeData

  }

  /*########## DARK THEME ##########*/

  static ThemeData get dark { // function to build near-black dark theme

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.solanaCyan,
      onPrimary: AppColors.whiteLightest,
      secondary: AppColors.solanaGreen,
      onSecondary: AppColors.blackDarkest,
      tertiary: AppColors.solanaPurple,
      onTertiary: AppColors.whiteLightest,
      error: AppColors.red,
      onError: AppColors.whiteLightest,
      surface: AppColors.blackMid,
      onSurface: AppColors.whiteLightest,
      surfaceContainerHighest: AppColors.blackLightest,
      onSurfaceVariant: const Color(0xFFB0B0B0),
    ); // extreme-dark scheme on Solana accents

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
    ); // seed Material text themes

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.blackDarkest, // pure black canvas
      textTheme: _doubledText(base.textTheme), // app-wide 2× type
      primaryTextTheme: _doubledText(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blackMid,
        foregroundColor: AppColors.whiteLightest,
        elevation: 0,
        titleTextStyle: _doubledText(base.textTheme).titleLarge?.copyWith(
              color: AppColors.whiteLightest,
              fontWeight: FontWeight.w700,
            ),
      ), // flat dark app bars
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.solanaCyan,
          foregroundColor: AppColors.whiteLightest,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ), // cyan CTAs instead of harsh purple
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaCyan
              : AppColors.blackLightest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.solanaCyan.withValues(alpha: 0.55)
              : AppColors.blackLightest,
        ),
      ), // cyan active switch (settings overrides for mode toggle)
    ); // dark ThemeData

  }

}
