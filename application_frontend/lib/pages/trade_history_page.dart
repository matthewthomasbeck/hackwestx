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

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../models/portfolio.dart'; // import PaperTrade
import '../services/app_services.dart'; // import portfolioStore





/*##################################################*/
/*############### TRADE HISTORY PAGE ###############*/
/*##################################################*/


/*########## TRADE HISTORY PAGE ##########*/

class TradeHistoryPage extends StatelessWidget { // class for scrollable past paper trades list

  const TradeHistoryPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build trade history list

    return ListenableBuilder(
      listenable: portfolioStore, // live paper fills
      builder: (context, _) {
        final trades = portfolioStore.trades; // newest first

        return Scaffold(
          appBar: AppBar(title: const Text('Trade History')),
          body: trades.isEmpty
              ? Center(
                  child: Text(
                    'No paper trades yet.\nBuy SOL from the home screen to populate this list.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ) // empty history state
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: trades.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    return ListTile(
                      title: Text(
                        '${_sideLabel(trade)} · ${trade.solAmount.toStringAsFixed(4)} SOL',
                      ),
                      subtitle: Text(_formatTime(trade.timestamp)),
                      trailing: Text(
                        '\$${trade.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ); // one history row
                  },
                ),
        ); // history scaffold
      },
    );

  }

  /*########## SIDE LABEL ##########*/

  String _sideLabel(PaperTrade trade) { // function to title-case buy/sell

    if (trade.side.isEmpty) { // defensive
      return 'Trade'; // fallback
    }
    return '${trade.side[0].toUpperCase()}${trade.side.substring(1)}'; // Buy / Sell

  }

  /*########## FORMAT TIME ##########*/

  String _formatTime(DateTime dt) { // function to show local trade time

    final local = dt.toLocal(); // device zone
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min'; // compact stamp

  }

}
