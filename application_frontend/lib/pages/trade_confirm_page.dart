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

import '../routes.dart'; // import named route constants
import '../theme/app_theme.dart'; // import success green glow tokens





/*##################################################*/
/*############### TRADE CONFIRM PAGE ###############*/
/*##################################################*/


/*########## TRADE CONFIRM PAGE ##########*/

class TradeConfirmPage extends StatefulWidget { // class for confirm step then success receipt

  const TradeConfirmPage({super.key}); // default const constructor

  @override
  State<TradeConfirmPage> createState() => _TradeConfirmPageState(); // create state

}


/*########## TRADE CONFIRM PAGE STATE ##########*/

class _TradeConfirmPageState extends State<TradeConfirmPage> { // class to toggle confirm vs receipt

  bool _confirmed = false; // False = review, True = receipt
  String _tradeId = 'paper-stub-0001'; // placeholder receipt id

  /*########## CONFIRM ##########*/

  Future<void> _confirm() async { // function to stub paper fill then show receipt

    // TODO: POST paper-trade buy API, then set real trade id / fill fields
    setState(() {
      _confirmed = true; // flip to receipt view
      _tradeId = 'paper-${DateTime.now().millisecondsSinceEpoch}'; // stub id
    });

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build confirm or receipt UI

    if (_confirmed) { // success receipt
      return Scaffold(
        appBar: AppBar(title: const Text('Trade Receipt')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: AppColors.green,
                shadows: [
                  Shadow(color: AppColors.green.withValues(alpha: 0.55), blurRadius: 18),
                ],
              ), // success check + glow
              const SizedBox(height: 16),
              Text(
                'Paper buy submitted',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Trade ID: $_tradeId',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tradeHistory),
                child: const Text('View History'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ); // receipt scaffold
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Buy')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const _SummaryRow(label: 'USD spent', value: '\$—'),
            const _SummaryRow(label: 'SOL bought', value: '—'),
            const _SummaryRow(label: 'Price used', value: '\$—'),
            const _SummaryRow(label: 'Timestamp', value: '—'),
            const Spacer(),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Confirm'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ); // confirm scaffold

  }

}


/*########## SUMMARY ROW ##########*/

class _SummaryRow extends StatelessWidget { // class for order summary label / value row

  const _SummaryRow({required this.label, required this.value}); // construct row

  final String label; // left label
  final String value; // right value

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build one summary row

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

  }

}
