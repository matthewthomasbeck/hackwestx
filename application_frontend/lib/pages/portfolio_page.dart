/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../config.dart'; // import paper starting USD
import '../services/app_services.dart'; // import portfolio + market stores
import '../theme/app_theme.dart'; // import P&L colors
import '../widgets/portfolio_sparkline.dart'; // import equity mini chart





/*##################################################*/
/*############### PORTFOLIO PAGE ###################*/
/*##################################################*/


/*########## PORTFOLIO PAGE ##########*/

class PortfolioPage extends StatelessWidget { // class for cash / holdings / unrealized P&L summary

  const PortfolioPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build paper portfolio layout

    return ListenableBuilder(
      listenable: Listenable.merge([portfolioStore, marketStore]), // ledger + spot
      builder: (context, _) {
        final portfolio = portfolioStore.snapshot; // live holdings
        final solPrice = marketStore.lastClose ?? 0; // mark price
        final currentValue = portfolio.marketValue(solPrice); // cash + SOL MTM
        final pnl = portfolio.unrealizedPnl(solPrice); // vs avg buy
        final avgBuy = portfolio.avgBuyPrice; // entry

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
              _StatRow(
                label: 'Cash available',
                value: '\$${portfolio.cashUsd.toStringAsFixed(2)}',
              ),
              _StatRow(
                label: 'SOL held',
                value: portfolio.solHeld.toStringAsFixed(4),
              ),
              _StatRow(
                label: 'Avg buy price',
                value: avgBuy <= 0 ? '—' : '\$${avgBuy.toStringAsFixed(2)}',
              ),
              _StatRow(
                label: 'Unrealized P&L',
                value: '\$${pnl.toStringAsFixed(2)}',
                valueColor: pnl >= 0 ? AppColors.green : AppColors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Value over time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              PortfolioSparkline(
                values: portfolioStore.valueHistory(solPrice),
              ), // start → fills → live MTM
            ],
          ),
        ); // portfolio scaffold
      },
    );

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
