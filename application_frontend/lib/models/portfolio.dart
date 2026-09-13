/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### PAPER TRADE MODELS ###############*/
/*##################################################*/


/*########## PAPER PORTFOLIO ##########*/

class PaperPortfolio { // class to hold paper cash + SOL holdings

  const PaperPortfolio({
    required this.cashUsd,
    required this.solHeld,
    required this.avgBuyPrice,
    required this.startingUsd,
  }); // construct portfolio snapshot

  final double cashUsd; // available paper USD
  final double solHeld; // SOL units held
  final double avgBuyPrice; // average entry price
  final double startingUsd; // starting paper balance

  double marketValue(double solPrice) { // function to compute cash + SOL mark-to-market value

    return 0; // skeleton

  }

  double unrealizedPnl(double solPrice) { // function to compute unrealized P&L vs average buy

    return 0; // skeleton

  }

}


/*########## PAPER TRADE ##########*/

class PaperTrade { // class to hold one paper buy/sell row for history / receipt

  const PaperTrade({
    required this.id,
    required this.side,
    required this.usdAmount,
    required this.solAmount,
    required this.price,
    required this.timestamp,
    this.forecastCorrect,
  }); // construct trade row

  final String id; // trade / receipt id
  final String side; // buy | sell
  final double usdAmount; // USD notional
  final double solAmount; // SOL filled
  final double price; // fill price
  final DateTime timestamp; // fill time
  final bool? forecastCorrect; // optional accuracy badge

}
