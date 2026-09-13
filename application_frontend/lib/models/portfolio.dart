/*##################################################*/
/*############### PAPER TRADE MODELS ###############*/
/*##################################################*/


/*########## PAPER PORTFOLIO ##########*/

class PaperPortfolio { // class to hold paper cash + SOL holdings (stub until trade APIs exist)

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

    return cashUsd + (solHeld * solPrice); // total portfolio USD

  }

  double unrealizedPnl(double solPrice) { // function to compute unrealized P&L vs average buy

    if (solHeld <= 0) { // no position
      return 0; // flat
    }
    return (solPrice - avgBuyPrice) * solHeld; // mark vs cost basis

  }

}


/*########## PAPER TRADE ##########*/

class PaperTrade { // class to hold one paper buy/sell row for history / receipt screens

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
  final bool? forecastCorrect; // optional accuracy badge once backend supports it

}


/*########## PAPER ORDER ARGS ##########*/

class PaperOrderArgs { // class to pass review-order fields Buy/Sell → Confirm

  const PaperOrderArgs({
    required this.side,
    required this.usdAmount,
    required this.solAmount,
    required this.price,
  }); // construct pending paper order

  final String side; // buy | sell
  final double usdAmount; // USD notional
  final double solAmount; // SOL size
  final double price; // spot used for estimate / fill

  bool get isBuy => side == 'buy'; // buy flow
  bool get isSell => side == 'sell'; // sell flow

}
