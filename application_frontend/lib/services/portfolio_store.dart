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

/*##### import third-party libraries #####*/

import 'package:flutter/foundation.dart'; // import ChangeNotifier for UI rebuilds

/*##### import local modules #####*/

import '../config.dart'; // import paper starting USD
import '../models/portfolio.dart'; // import PaperPortfolio / PaperTrade





/*##################################################*/
/*############### PORTFOLIO STORE ##################*/
/*##################################################*/


/*########## PORTFOLIO STORE ##########*/

class PortfolioStore extends ChangeNotifier { // class to hold in-app paper cash, SOL, and trade history

  double cashUsd = AppConfig.paperStartingUsd; // available paper USD
  double solHeld = 0; // SOL units held
  double avgBuyPrice = 0; // volume-weighted average buy price
  final List<PaperTrade> trades = []; // newest-first paper fills

  /*########## SNAPSHOT ##########*/

  PaperPortfolio get snapshot { // function to expose current holdings as a PaperPortfolio

    return PaperPortfolio(
      cashUsd: cashUsd,
      solHeld: solHeld,
      avgBuyPrice: avgBuyPrice,
      startingUsd: AppConfig.paperStartingUsd,
    ); // live paper snapshot

  }

  /*########## BUY ##########*/

  PaperTrade buy({required double usdAmount, required double price}) { // function to fill a paper buy at spot

    if (usdAmount <= 0 || price <= 0) { // invalid order
      throw ArgumentError('Buy requires positive USD amount and price'); // hard fail
    }
    if (usdAmount > cashUsd + 1e-9) { // overspend
      throw StateError('Insufficient paper cash'); // hard fail
    }

    final solAmount = usdAmount / price; // fill size
    final priorSol = solHeld; // holdings before fill
    final priorAvg = avgBuyPrice; // avg before fill

    cashUsd -= usdAmount; // debit cash
    solHeld += solAmount; // credit SOL
    if (priorSol <= 0) { // first buy
      avgBuyPrice = price; // entry = fill
    } else { // blend cost basis
      avgBuyPrice = ((priorAvg * priorSol) + usdAmount) / solHeld; // VWAP
    }

    final trade = PaperTrade(
      id: 'paper-${DateTime.now().millisecondsSinceEpoch}',
      side: 'buy',
      usdAmount: usdAmount,
      solAmount: solAmount,
      price: price,
      timestamp: DateTime.now(),
    ); // receipt row
    trades.insert(0, trade); // newest first
    notifyListeners(); // rebuild buy / portfolio / history
    return trade; // for confirm receipt

  }

  /*########## RESET ##########*/

  void reset() { // function to restore starting cash and clear holdings / history

    cashUsd = AppConfig.paperStartingUsd; // back to start
    solHeld = 0; // flat
    avgBuyPrice = 0; // no basis
    trades.clear(); // wipe history
    notifyListeners(); // rebuild listeners

  }

}
