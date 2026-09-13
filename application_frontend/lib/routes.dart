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

import 'pages/buy_sol_page.dart'; // import paper buy SOL screen
import 'pages/forecast_detail_page.dart'; // import forecast detail screen
import 'pages/home_page.dart'; // import home chart screen
import 'pages/loading_page.dart'; // import splash / loading screen
import 'pages/login_page.dart'; // import Auth0 login screen
import 'pages/onboarding_page.dart'; // import first-run onboarding screen
import 'pages/portfolio_page.dart'; // import paper portfolio screen
import 'pages/settings_page.dart'; // import account settings screen
import 'pages/status_pages.dart'; // import empty / pending / error screens
import 'pages/trade_confirm_page.dart'; // import trade confirm / receipt screen
import 'pages/trade_history_page.dart'; // import trade history screen





/*##################################################*/
/*############### ROUTE NAMES ######################*/
/*##################################################*/


/*########## APP ROUTES ##########*/

class AppRoutes { // class to hold named route strings and MaterialApp route map

  static const loading = '/'; // initial splash / loading route
  static const login = '/login'; // Auth0 login route
  static const onboarding = '/onboarding'; // first-run onboarding route
  static const home = '/home'; // main chart home route
  static const buySol = '/buy-sol'; // paper buy SOL route
  static const forecastDetail = '/forecast'; // forecast detail route
  static const portfolio = '/portfolio'; // paper portfolio route
  static const tradeConfirm = '/trade-confirm'; // trade confirm / receipt route
  static const tradeHistory = '/trade-history'; // trade history route
  static const settings = '/settings'; // account settings route
  static const empty = '/status/empty'; // empty market-data status route
  static const pending = '/status/pending'; // predictions-pending status route
  static const error = '/status/error'; // error / retry status route

  /*########## ROUTES MAP ##########*/

  static Map<String, WidgetBuilder> get routes { // function to build named route → page map

    return {
      loading: (_) => const LoadingPage(), // splash while auth + first /market resolve
      login: (_) => const LoginPage(), // Auth0 sign-in
      onboarding: (_) => const OnboardingPage(), // swipeable intro cards
      home: (_) => const HomePage(), // SOL chart + quick actions
      buySol: (_) => const BuySolPage(), // amount + review buy
      forecastDetail: (_) => const ForecastDetailPage(), // next 5 predicted closes
      portfolio: (_) => const PortfolioPage(), // cash / holdings / P&L
      tradeConfirm: (_) => const TradeConfirmPage(), // confirm then receipt
      tradeHistory: (_) => const TradeHistoryPage(), // past paper trades
      settings: (_) => const SettingsPage(), // profile / theme / logout
      empty: (_) => const EmptyStatusPage(), // no market data yet
      pending: (_) => const PendingStatusPage(), // generating predictions
      error: (_) => const ErrorStatusPage(), // friendly error + retry
    }; // MaterialApp.routes map

  }

}
