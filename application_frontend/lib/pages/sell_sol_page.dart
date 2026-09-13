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

import '../models/portfolio.dart'; // import PaperOrderArgs for confirm handoff
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import market + portfolio stores
import '../theme/app_theme.dart'; // import direction colors





/*##################################################*/
/*############### SELL SOL PAGE ####################*/
/*##################################################*/


/*########## SELL SOL PAGE ##########*/

class SellSolPage extends StatefulWidget { // class for SOL amount input + estimated USD preview

  const SellSolPage({super.key}); // default const constructor

  @override
  State<SellSolPage> createState() => _SellSolPageState(); // create state

}


/*########## SELL SOL PAGE STATE ##########*/

class _SellSolPageState extends State<SellSolPage> { // class to track SOL amount text field

  final _amountController = TextEditingController(); // SOL amount input

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to dispose amount controller

    _amountController.dispose(); // free controller
    super.dispose(); // Flutter dispose

  }

  /*########## ESTIMATED USD ##########*/

  double? _estimatedUsd(double solPrice) { // function to preview USD proceeds at live price

    final sol = double.tryParse(_amountController.text); // parse field
    if (sol == null || sol <= 0 || solPrice <= 0) { // invalid / unknown price
      return null; // no preview
    }
    return sol * solPrice; // estimated proceeds

  }

  /*########## SELL MAX ##########*/

  void _sellMax(double solHeld) { // function to fill field with full holdings

    if (solHeld <= 0) { // nothing to sell
      return; // stay
    }
    _amountController.text = solHeld.toStringAsFixed(6); // full position
    setState(() {}); // refresh preview

  }

  /*########## REVIEW ##########*/

  void _reviewSell(double solPrice, double solHeld) { // function to validate then open confirm

    final sol = double.tryParse(_amountController.text.trim()); // parse size
    if (sol == null || sol <= 0) { // bad amount
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a SOL amount greater than 0')),
      ); // hint
      return; // stay
    }
    if (sol > solHeld) { // oversell
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${solHeld.toStringAsFixed(4)} SOL available')),
      ); // hint
      return; // stay
    }
    if (solPrice <= 0) { // no spot
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load market data before selling')),
      ); // hint
      return; // stay
    }

    final usdAmount = sol * solPrice; // preview proceeds
    Navigator.of(context).pushNamed(
      AppRoutes.tradeConfirm,
      arguments: PaperOrderArgs(
        side: 'sell',
        usdAmount: usdAmount,
        solAmount: sol,
        price: solPrice,
      ),
    ); // hand off to confirm

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build sell SOL form

    return ListenableBuilder(
      listenable: Listenable.merge([marketStore, portfolioStore]), // price + holdings
      builder: (context, _) {
        final solPrice = marketStore.lastClose ?? 0; // latest close
        final solHeld = portfolioStore.solHeld; // live SOL
        final estimated = _estimatedUsd(solPrice); // live preview
        final preds = marketStore.market?.predictions ?? const []; // forecasts
        final bearish = preds.isNotEmpty &&
            solPrice > 0 &&
            preds.first.predictedClose < solPrice; // Day-1 below spot
        final sol = double.tryParse(_amountController.text); // for CTA enable
        final canReview = solPrice > 0 &&
            solHeld > 0 &&
            sol != null &&
            sol > 0 &&
            sol <= solHeld; // valid paper sell

        return Scaffold(
          appBar: AppBar(title: const Text('Sell SOL')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Holdings: ${solHeld.toStringAsFixed(4)} SOL',
                  style: Theme.of(context).textTheme.titleMedium,
                ), // paper SOL balance
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
                  decoration: InputDecoration(
                    labelText: 'Amount to sell (SOL)',
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(
                      onPressed: solHeld > 0 ? () => _sellMax(solHeld) : null,
                      child: const Text('Max'),
                    ),
                  ),
                  onChanged: (_) => setState(() {}), // refresh preview
                ), // sell size
                const SizedBox(height: 16),
                Text(
                  estimated == null
                      ? 'Estimated USD: —'
                      : 'Estimated USD: \$${estimated.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ), // live USD preview
                const SizedBox(height: 8),
                Text(
                  bearish
                      ? 'Based on latest forecast — model is bearish on Day 1.'
                      : 'Based on latest forecast when model is bearish.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bearish
                            ? AppColors.red
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
                              ? () => _reviewSell(solPrice, solHeld)
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
                                'Review Sell',
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
        ); // sell scaffold
      },
    );

  }

}
