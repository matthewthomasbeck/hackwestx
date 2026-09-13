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
  final double _solPrice = 0; // stub last close (wire from MarketPayload)

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to dispose amount controller

    _amountController.dispose(); // free controller
    super.dispose(); // Flutter dispose

  }

  /*########## ESTIMATED SOL ##########*/

  double? get _estimatedSol { // function to preview SOL received at stub price

    final usd = double.tryParse(_amountController.text); // parse field
    if (usd == null || usd <= 0 || _solPrice <= 0) { // invalid / unknown price
      return null; // no preview
    }
    return usd / _solPrice; // estimated fill size

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build buy SOL form

    final estimated = _estimatedSol; // live preview

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
                  ? 'Estimated SOL: —  (set price via /market)'
                  : 'Estimated SOL: ${estimated.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ), // live SOL preview
            const SizedBox(height: 8),
            Text(
              'Based on latest forecast when model is bullish (optional note).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ), // forecast-aware hint stub
            const Spacer(),
            FilledButton(
              onPressed: () {
                // TODO: validate amount against cash + pass args to confirm page
                Navigator.of(context).pushNamed(AppRoutes.tradeConfirm);
              },
              child: const Text('Review Buy'),
            ), // go to confirm / receipt
          ],
        ),
      ),
    ); // buy scaffold

  }

}
