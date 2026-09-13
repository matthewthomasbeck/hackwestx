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

import '../config.dart'; // import paper starting USD
import '../theme/app_theme.dart'; // import P&L colors





/*##################################################*/
/*############### PORTFOLIO PAGE ###################*/
/*##################################################*/


/*########## PORTFOLIO PAGE ##########*/

class PortfolioPage extends StatelessWidget { // class for cash / holdings / unrealized P&L summary

  const PortfolioPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build paper portfolio layout

    // TODO: load PaperPortfolio from paper-trade API / local ledger
    const cash = AppConfig.paperStartingUsd; // stub cash
    const solHeld = 0.0; // stub holdings
    const avgBuy = 0.0; // stub avg entry
    const currentValue = cash; // stub mark-to-market
    const pnl = 0.0; // stub P&L

    return Scaffold(
      appBar: AppBar(title: const Text('Paper Portfolio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Portfolio value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '\$${currentValue.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ), // current value
          Text(
            'Started at \$${AppConfig.paperStartingUsd.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          _StatRow(label: 'Cash available', value: '\$${cash.toStringAsFixed(2)}'),
          _StatRow(label: 'SOL held', value: solHeld.toStringAsFixed(4)),
          _StatRow(label: 'Avg buy price', value: avgBuy <= 0 ? '—' : '\$${avgBuy.toStringAsFixed(2)}'),
          _StatRow(
            label: 'Unrealized P&L',
            value: '\$${pnl.toStringAsFixed(2)}',
            valueColor: pnl >= 0 ? AppColors.green : AppColors.red,
          ),
          const SizedBox(height: 24),
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: const Text('Portfolio sparkline stub'), // optional mini chart later
          ),
        ],
      ),
    ); // portfolio scaffold

  }

}


/*########## STAT ROW ##########*/

class _StatRow extends StatelessWidget { // class for label / value portfolio row

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  }); // construct row

  final String label; // left label
  final String value; // right value
  final Color? valueColor; // optional P&L color

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build one stat row

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    ); // label | value

  }

}
