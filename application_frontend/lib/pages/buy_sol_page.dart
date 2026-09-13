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

import '../config.dart'; // import paper starting USD default
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import market store for last close
import '../theme/app_theme.dart'; // import direction colors





/*##################################################*/
/*############### BUY SOL PAGE #####################*/
/*##################################################*/


/*########## BUY SOL PAGE ##########*/

class BuySolPage extends StatefulWidget { // class for amount input + estimated SOL preview

  const BuySolPage({super.key}); // default const constructor

  @override
  State<BuySolPage> createState() => _BuySolPageState(); // create state

}


/*########## BUY SOL PAGE STATE ##########*/

class _BuySolPageState extends State<BuySolPage> { // class to track spend amount text field

  final _amountController = TextEditingController(); // USD amount input
  final double _cashUsd = AppConfig.paperStartingUsd; // stub available cash (wire from portfolio API)

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to dispose amount controller

    _amountController.dispose(); // free controller
    super.dispose(); // Flutter dispose

  }

  /*########## ESTIMATED SOL ##########*/

  double? _estimatedSol(double solPrice) { // function to preview SOL received at live price

    final usd = double.tryParse(_amountController.text); // parse field
    if (usd == null || usd <= 0 || solPrice <= 0) { // invalid / unknown price
      return null; // no preview
    }
    return usd / solPrice; // estimated fill size

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build buy SOL form

    return ListenableBuilder(
      listenable: marketStore, // price updates from /market
      builder: (context, _) {
        final solPrice = marketStore.lastClose ?? 0; // latest close
        final estimated = _estimatedSol(solPrice); // live preview
        final preds = marketStore.market?.predictions ?? const []; // forecasts
        final bullish = preds.isNotEmpty &&
            solPrice > 0 &&
            preds.first.predictedClose > solPrice; // Day-1 above spot

        return Scaffold(
          appBar: AppBar(title: const Text('Buy SOL')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Available: \$${_cashUsd.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ), // paper USD balance
                const SizedBox(height: 8),
                Text(
                  solPrice > 0
                      ? 'Spot: \$${solPrice.toStringAsFixed(2)}'
                      : 'Spot: — (load market data first)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ), // live price from /market
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount to spend (USD)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}), // refresh preview
                ), // spend amount
                const SizedBox(height: 16),
                Text(
                  estimated == null
                      ? 'Estimated SOL: —'
                      : 'Estimated SOL: ${estimated.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ), // live SOL preview
                const SizedBox(height: 8),
                Text(
                  bullish
                      ? 'Based on latest forecast — model is bullish on Day 1.'
                      : 'Based on latest forecast when model is bullish.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bullish
                            ? AppColors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ), // forecast-aware hint
                const Spacer(),
                FilledButton(
                  onPressed: solPrice <= 0
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(AppRoutes.tradeConfirm);
                        },
                  child: const Text('Review Buy'),
                ), // go to confirm / receipt
              ],
            ),
          ),
        ); // buy scaffold
      },
    );

  }

}
