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

import 'package:flutter/material.dart'; // import Flutter Material for Widget types

/*##### import local modules #####*/

import 'pages/buy_sol_page.dart'; // import buy SOL page
import 'pages/forecast_detail_page.dart'; // import forecast detail page
import 'pages/home_page.dart'; // import home page
import 'pages/loading_page.dart'; // import loading page
import 'pages/login_page.dart'; // import login page
import 'pages/onboarding_page.dart'; // import onboarding page
import 'pages/portfolio_page.dart'; // import portfolio page
import 'pages/settings_page.dart'; // import settings page
import 'pages/status_pages.dart'; // import empty / pending / error pages
import 'pages/trade_confirm_page.dart'; // import trade confirm page
import 'pages/trade_history_page.dart'; // import trade history page





/*##################################################*/
/*############### ROUTE NAMES ######################*/
/*##################################################*/


/*########## APP ROUTES ##########*/

class AppRoutes { // class to hold named route strings and MaterialApp route map

  static const loading = '/'; // loading route
  static const login = '/login'; // login route
  static const onboarding = '/onboarding'; // onboarding route
  static const home = '/home'; // home route
  static const buySol = '/buy-sol'; // buy SOL route
  static const forecastDetail = '/forecast'; // forecast route
  static const portfolio = '/portfolio'; // portfolio route
  static const tradeConfirm = '/trade-confirm'; // trade confirm route
  static const tradeHistory = '/trade-history'; // trade history route
  static const settings = '/settings'; // settings route
  static const empty = '/status/empty'; // empty status route
  static const pending = '/status/pending'; // pending status route
  static const error = '/status/error'; // error status route

  /*########## ROUTES MAP ##########*/

  static Map<String, WidgetBuilder> get routes { // function to build named route map

    return {
      loading: (_) => const LoadingPage(),
      login: (_) => const LoginPage(),
      onboarding: (_) => const OnboardingPage(),
      home: (_) => const HomePage(),
      buySol: (_) => const BuySolPage(),
      forecastDetail: (_) => const ForecastDetailPage(),
      portfolio: (_) => const PortfolioPage(),
      tradeConfirm: (_) => const TradeConfirmPage(),
      tradeHistory: (_) => const TradeHistoryPage(),
      settings: (_) => const SettingsPage(),
      empty: (_) => const EmptyStatusPage(),
      pending: (_) => const PendingStatusPage(),
      error: (_) => const ErrorStatusPage(),
    }; // skeleton route map

  }

}
