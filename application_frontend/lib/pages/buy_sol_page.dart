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

import '../models/portfolio.dart'; // import BuyOrderArgs for confirm handoff
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import market + portfolio stores
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

  /*########## REVIEW ##########*/

  void _reviewBuy(double solPrice, double cashUsd) { // function to validate then open confirm

    final usd = double.tryParse(_amountController.text.trim()); // parse spend
    if (usd == null || usd <= 0) { // bad amount
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a USD amount greater than 0')),
      ); // hint
      return; // stay
    }
    if (usd > cashUsd) { // overspend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only \$${cashUsd.toStringAsFixed(2)} available')),
      ); // hint
      return; // stay
    }
    if (solPrice <= 0) { // no spot
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load market data before buying')),
      ); // hint
      return; // stay
    }

    final solAmount = usd / solPrice; // preview fill
    Navigator.of(context).pushNamed(
      AppRoutes.tradeConfirm,
      arguments: BuyOrderArgs(
        usdAmount: usd,
        solAmount: solAmount,
        price: solPrice,
      ),
    ); // hand off to confirm

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build buy SOL form

    return ListenableBuilder(
      listenable: Listenable.merge([marketStore, portfolioStore]), // price + cash
      builder: (context, _) {
        final solPrice = marketStore.lastClose ?? 0; // latest close
        final cashUsd = portfolioStore.cashUsd; // live paper cash
        final estimated = _estimatedSol(solPrice); // live preview
        final preds = marketStore.market?.predictions ?? const []; // forecasts
        final bullish = preds.isNotEmpty &&
            solPrice > 0 &&
            preds.first.predictedClose > solPrice; // Day-1 above spot
        final usd = double.tryParse(_amountController.text); // for CTA enable
        final canReview = solPrice > 0 &&
            usd != null &&
            usd > 0 &&
            usd <= cashUsd; // valid paper buy

        return Scaffold(
          appBar: AppBar(title: const Text('Buy SOL')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Available: \$${cashUsd.toStringAsFixed(2)}',
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
                Builder(
                  builder: (context) {
                    final onGradient =
                        AppColors.onSolanaGradient(Theme.of(context).brightness);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: canReview
                            ? AppColors.solanaGlow(strength: 0.7)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canReview
                              ? () => _reviewBuy(solPrice, cashUsd)
                              : null,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: canReview
                                  ? AppColors.solanaDiagonal
                                  : null,
                              color: canReview
                                  ? null
                                  : Theme.of(context).disabledColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Review Buy',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: onGradient,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ); // glowing Solana-gradient review CTA
                  },
                ),
              ],
            ),
          ),
        ); // buy scaffold
      },
    );

  }

}
