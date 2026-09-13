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

import 'package:flutter/material.dart'; // import ChangeNotifier + ThemeMode





/*##################################################*/
/*############### THEME STORE ######################*/
/*##################################################*/


/*########## THEME STORE ##########*/

class ThemeStore extends ChangeNotifier { // class to own app-wide light / dark ThemeMode

  ThemeMode _mode = ThemeMode.dark; // default to dark until user toggles

  ThemeMode get mode => _mode; // current ThemeMode for MaterialApp

  bool get isDark => _mode == ThemeMode.dark; // True when dark mode selected

  /*########## SET DARK MODE ##########*/

  void setDarkMode(bool enabled) { // function to flip between dark and light from Settings

    final next = enabled ? ThemeMode.dark : ThemeMode.light; // map switch → mode
    if (next == _mode) { // unchanged
      return; // skip notify
    }
    _mode = next; // apply
    notifyListeners(); // rebuild MaterialApp

  }

}
