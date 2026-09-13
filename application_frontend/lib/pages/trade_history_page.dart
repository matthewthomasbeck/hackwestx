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





/*##################################################*/
/*############### TRADE HISTORY PAGE ###############*/
/*##################################################*/


/*########## TRADE HISTORY PAGE ##########*/

class TradeHistoryPage extends StatelessWidget { // class for scrollable past paper trades list

  const TradeHistoryPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build trade history list

    // TODO: load PaperTrade list from backend / local ledger (newest first)
    final stubTrades = <Map<String, String>>[]; // empty until paper API exists

    return Scaffold(
      appBar: AppBar(title: const Text('Trade History')),
      body: stubTrades.isEmpty
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
              itemCount: stubTrades.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trade = stubTrades[index];
                return ListTile(
                  title: Text('${trade['side']} · ${trade['amount']}'),
                  subtitle: Text(trade['date'] ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(trade['price'] ?? ''),
                      // TODO: optional "forecast was correct?" badge when accuracy API exists
                    ],
                  ),
                ); // one history row
              },
            ),
    ); // history scaffold

  }

}
